#!/usr/bin/env bash
# 새 프로젝트 하나 만든다. 사람이 손으로 하면 빠뜨리는 것만 한다.
#   사용법: ./new-project.sh <이름> [--private] [--license=<spdx>]
#   예:     ./new-project.sh myapp --private --license=apache-2.0
#
# 순서가 중요하다: 라이선스 교체는 룰셋을 걸기 *전*에 한다.
# 룰셋이 걸리면 main 직접 푸시가 막혀 그 뒤엔 PR 없이 못 바꾼다.
set -euo pipefail

name="${1:?사용법: new-project.sh <이름> [--private] [--license=<spdx>]}"; shift
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; vis=--public; lic=mit
for a in "$@"; do case "$a" in
  --private) vis=--private ;;
  --license=*) lic="${a#*=}" ;;
  *) echo "모르는 인자: $a" >&2; exit 2 ;;
esac; done

gh repo create "coolbress/$name" "$vis" --template coolbress/project-template --clone

# 템플릿은 MIT 를 싣고 온다. 고른 게 다르면 GitHub 공식 본문으로 바꾼다 (같으면 diff 가 없어 넘어간다).
gh api "/licenses/$lic" --jq .body > "$name/LICENSE"
git -C "$name" diff --quiet || { git -C "$name" commit -qam "chore: 라이선스를 $lic 로 설정"; git -C "$name" push -q; }

# 벽. 이게 안 걸리면 저장소를 남기지 않는다 — 벽 없는 저장소는 만들 이유가 없다.
if ! err="$(gh api "repos/coolbress/$name/rulesets" -X POST --input "$here/ruleset.json" 2>&1 >/dev/null)"; then
  echo "$err" >&2; cat >&2 <<EOF

🔴 벽을 걸지 못했다. 방금 만든 원격 저장소를 지운다 (로컬 사본 ./$name 은 남는다).

비공개 + GitHub Free 면 룰셋이 걸리지 않는다. GitHub 이 직접 그렇게 답한다 —
  "Upgrade to GitHub Pro or make this repository public to enable this feature."

길은 둘뿐이다:
  1) GitHub Pro 로 올리고 다시 실행한다   ← 비공개를 유지하려면 이것뿐
  2) --private 없이 다시 실행한다          ← 공개로 만든다

벽 없이 진행하지 않는 이유: 이 프로젝트의 전제가 "집행은 에이전트 밖 GitHub 에 있다" 이다.
브랜치 보호가 없으면 CI 는 게이트가 아니라 그냥 지나칠 수 있는 알림이 된다.
EOF
  gh repo delete "coolbress/$name" --yes; exit 1
fi

# 시크릿 탐지 + 푸시 보호. 켜지 않으면 기본이 꺼짐이다.
gh api "repos/coolbress/$name" -X PATCH \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null

echo "완료 → https://github.com/coolbress/$name  (${vis#--} · $lic)"
