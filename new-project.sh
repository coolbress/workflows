#!/usr/bin/env bash
# 새 프로젝트 하나 만든다. 사람이 손으로 하면 빠뜨리는 것만 한다.
#   사용법: ./new-project.sh <이름> [--license=<spdx>]        (--private 는 미지원)
#   예:     ./new-project.sh myapp --license=apache-2.0
#
# 이 스크립트의 책임: 저장소 생성 + 서버 바닥(벽·시크릿 탐지) 설치. 그 이상은 하지 않는다.
# fail-closed: 어느 단계에서 실패하든 원격 저장소를 남기지 않는다.
#   벽 없는 저장소가 남는 것이 이 프로젝트가 죽는 방식이기 때문이다.
# 순서 주의: 라이선스 교체는 룰셋을 걸기 *전*에 한다 (건 뒤엔 main 직접 푸시가 막힌다).
set -euo pipefail

name="${1:?사용법: new-project.sh <이름> [--license=<spdx>]  (--private 는 미지원)}"; shift
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; vis=--public; lic=mit
for a in "$@"; do case "$a" in
  # 🔴 --private 는 **지금 지원하지 않는다.** 받는 척하면 안 된다.
  # 이유 둘: ① GitHub Free 는 비공개에 룰셋을 못 건다(Pro 필요)
  #          ② 룰셋이 `CodeQL` 을 요구하는데 비공개 CodeQL 은
  #             `GitHub Code Security` 라이선스가 필요하다(`FFA-008`).
  # 정본의 결정은 "비공개 → Semgrep OSS" 인데 **그 경로가 아직 구현돼 있지 않다.**
  # 구현하기 전까지는 **여기서 막는다** — 만들다 실패해 저장소를 지우는 것보다
  # 시작 전에 이유를 말하는 것이 낫다.
  --private)
    cat >&2 <<'EOF'
🔴 --private 는 아직 지원하지 않는다.

  ① GitHub Free 는 비공개 저장소에 룰셋을 걸 수 없다 (Pro 필요)
  ② 룰셋이 `CodeQL` 을 요구하는데, 비공개 CodeQL 은
     `GitHub Code Security` 라이선스가 필요하다

정본의 결정은 "공개 → CodeQL · 비공개 → Semgrep OSS" 지만
**비공개 경로(Semgrep 잡 + 별도 required context)가 아직 구현되지 않았다.**
받는 척하고 중간에 실패하느니 여기서 멈춘다.

지금 할 수 있는 것: 공개로 만든다 (`--private` 를 빼고 다시 실행)
EOF
    exit 2 ;;
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
# 치환이 끝나면 **생성기 자신을 지운다.** 남겨 두면 모든 프로젝트가
# 앞으로 쓰지 않을 일회용 스크립트와 그 시험을 영원히 들고 다닌다
# (그리고 CI 가 매번 그 시험을 돈다). 대전제 2 — 작고 가볍게.
( cd "$name" \
  && ./bootstrap.sh "$name" "$spdx" \
  && git rm -q bootstrap.sh tests/test_bootstrap_name.py \
  && git commit -qm "chore: 템플릿 자리표시자를 $name 로 치환 (생성기 제거)" \
  && git push -q )

# 템플릿은 MIT 본문을 싣고 온다. 고른 게 다르면 GitHub 공식 본문으로 바꾼다 (같으면 diff 가 없어 넘어간다).
gh api "/licenses/$lic" --jq .body > "$name/LICENSE"
git -C "$name" diff --quiet || { git -C "$name" commit -qam "chore: 라이선스를 $lic 로 설정"; git -C "$name" push -q; }

# 🔴 CodeQL 을 **벽을 걸기 전에** 켠다.
# 룰셋이 `CodeQL` 검사를 요구하는데 default setup 이 꺼져 있으면 그 이름이
# **영원히 보고되지 않아 저장소가 첫 PR 부터 잠긴다** — `uv sync --locked` 로 이미 겪은 형태다.
# 실패하면 trap 이 저장소를 지운다. 벽 없는 저장소도, 잠긴 저장소도 남기지 않는다.
gh api -X PATCH "repos/coolbress/$name/code-scanning/default-setup" \
  -f state=configured -f query_suite=default >/dev/null

# 벽.
if ! err="$(gh api "repos/coolbress/$name/rulesets" -X POST --input "$here/ruleset.json" 2>&1 >/dev/null)"; then
  echo "$err" >&2; cat >&2 <<'EOF'

벽을 걸지 못했다. 방금 만든 원격 저장소는 지운다 — 벽 없는 저장소를 남기지 않는다.
EOF
  exit 1
fi

# 시크릿 탐지 + 푸시 보호 · Dependabot 경보/보안 업데이트. 켜지 않으면 기본이 꺼짐이다.
gh api "repos/coolbress/$name" -X PATCH \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null
gh api -X PUT "repos/coolbress/$name/vulnerability-alerts"
gh api -X PUT "repos/coolbress/$name/automated-security-fixes"
# Actions: 서버가 **두 가지를 따로** 강제한다 — 무엇이 바뀌지 않는가(SHA 핀)와
# 무엇이 돌 수 있는가(allowlist). 파일 습관만으로는 둘 다 부족하다.
# 🔴 이전 판은 `allowed_actions=all` 이었다 — 새 저장소만 allowlist 없이 태어나서
# `repo_audit` 이 즉시 drift 로 잡았다. **생성기와 감사기의 기대값이 달랐다.**
gh api -X PUT "repos/coolbress/$name/actions/permissions" -F enabled=true -f allowed_actions=selected -F sha_pinning_required=true
# 허용 목록: GitHub 소유(actions/*, github/*) + 재사용 워크플로가 쓰는 setup-uv
# + 🔴 **재사용 워크플로 자신**(coolbress/workflows/*).
# 마지막 것을 빠뜨리면 `uses: coolbress/workflows/...` 가 allowlist 에 걸려
# **첫 CI 가 startup_failure 로 죽는다** — 검사가 아예 보고되지 않으니 저장소가 잠긴다.
# 실측으로 잡았다: project-template 은 이 패턴을 갖고 있는데 생성기는 안 걸고 있었다.
gh api -X PUT "repos/coolbress/$name/actions/permissions/selected-actions" \
  -F github_owned_allowed=true -F verified_allowed=false \
  -f 'patterns_allowed[]=astral-sh/setup-uv@*' \
  -f 'patterns_allowed[]=coolbress/workflows/*' 
# 머지 방법을 룰셋 의도와 맞춘다.
gh api -X PATCH "repos/coolbress/$name" -F allow_merge_commit=false -F allow_rebase_merge=false -F delete_branch_on_merge=true >/dev/null

created=0; trap - EXIT
echo "완료 → https://github.com/coolbress/$name  (${vis#--} · $lic)"
