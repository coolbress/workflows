#!/usr/bin/env bash
# 새 프로젝트 하나 만든다. 사람이 손으로 하면 빠뜨리는 것만 한다.
#   사용법: ./new-project.sh <이름> [--private] [--license=<spdx>]
#   예:     ./new-project.sh myapp --private --license=apache-2.0
#
# 이 스크립트의 책임: 저장소 생성 + 서버 바닥(벽·시크릿 탐지) 설치. 그 이상은 하지 않는다.
# fail-closed: 어느 단계에서 실패하든 원격 저장소를 남기지 않는다.
#   벽 없는 저장소가 남는 것이 이 프로젝트가 죽는 방식이기 때문이다.
# 순서 주의: 라이선스 교체는 룰셋을 걸기 *전*에 한다 (건 뒤엔 main 직접 푸시가 막힌다).
set -euo pipefail

name="${1:?사용법: new-project.sh <이름> [--private] [--license=<spdx>]}"; shift
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; vis=--public; lic=mit
for a in "$@"; do case "$a" in
  --private) vis=--private ;;
  --license=*) lic="${a#*=}" ;;
  *) echo "모르는 인자: $a" >&2; exit 2 ;;
esac; done

# 라이선스는 **저장소를 만들기 전에** 확인한다 — 오타 하나로 저장소를 만들었다 지우지 않는다.
# 그리고 SPDX 식별자(MIT · Apache-2.0)를 여기서 얻어 bootstrap 에 넘긴다.
if ! spdx="$(gh api "/licenses/$lic" --jq .spdx_id 2>/dev/null)"; then
  echo "모르는 라이선스: $lic  (예: mit · apache-2.0 · gpl-3.0 — https://api.github.com/licenses)" >&2
  exit 2
fi

created=0
cleanup() {
  [ "$created" = 1 ] || return 0
  echo "🔴 바닥을 다 세우지 못했다 — 방금 만든 원격 저장소를 지운다 (로컬 사본 ./$name 은 남는다)." >&2
  gh repo delete "coolbress/$name" --yes || true
}
trap cleanup EXIT

gh repo create "coolbress/$name" "$vis" --template coolbress/project-template --clone
created=1

# 템플릿 자리표시자(app)를 실제 이름·라이선스로. 치환 로직은 템플릿이 소유한다 (감사 §생성 방식).
# bootstrap 은 uv.lock 도 다시 잠근다 — 안 하면 CI 의 `uv sync --locked` 가 첫 PR 부터 실패한다.
( cd "$name" && ./bootstrap.sh "$name" "$spdx" && git commit -qm "chore: 템플릿 자리표시자를 $name 로 치환" && git push -q )

# 템플릿은 MIT 본문을 싣고 온다. 고른 게 다르면 GitHub 공식 본문으로 바꾼다 (같으면 diff 가 없어 넘어간다).
gh api "/licenses/$lic" --jq .body > "$name/LICENSE"
git -C "$name" diff --quiet || { git -C "$name" commit -qam "chore: 라이선스를 $lic 로 설정"; git -C "$name" push -q; }

# 벽.
if ! err="$(gh api "repos/coolbress/$name/rulesets" -X POST --input "$here/ruleset.json" 2>&1 >/dev/null)"; then
  echo "$err" >&2; cat >&2 <<EOF

비공개 + GitHub Free 면 룰셋이 걸리지 않는다. GitHub 이 직접 그렇게 답한다 —
  "Upgrade to GitHub Pro or make this repository public to enable this feature."
길은 둘뿐이다: 1) GitHub Pro 로 올리고 다시 실행  2) --private 없이 다시 실행
EOF
  exit 1
fi

# 시크릿 탐지 + 푸시 보호 · Dependabot 경보/보안 업데이트. 켜지 않으면 기본이 꺼짐이다.
gh api "repos/coolbress/$name" -X PATCH \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null
gh api -X PUT "repos/coolbress/$name/vulnerability-alerts"
gh api -X PUT "repos/coolbress/$name/automated-security-fixes"
# Actions: 서버에서도 커밋 SHA 핀을 강제한다 (파일 습관만으로는 부족하다).
gh api -X PUT "repos/coolbress/$name/actions/permissions" -F enabled=true -f allowed_actions=all -F sha_pinning_required=true
# 머지 방법을 룰셋 의도와 맞춘다.
gh api -X PATCH "repos/coolbress/$name" -F allow_merge_commit=false -F allow_rebase_merge=false -F delete_branch_on_merge=true >/dev/null

created=0; trap - EXIT
echo "완료 → https://github.com/coolbress/$name  (${vis#--} · $lic)"
