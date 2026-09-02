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
# 🔴 템플릿 판을 **하나로** 본다. 전판은 아키타입 목록을 `main` 에서 읽고 copier 는 **최신 태그**를
# 썼다 — 한 실행이 템플릿을 두 시점으로 보는 창이 있었다(제3자 지적 2026-09-02).
# 올릴 때는 이 값 하나만 바꾼다.
template_ref="${TEMPLATE_REF:-v2.18.0}"
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
  --archetype=*) arch="${a#*=}" ;;
  *) echo "모르는 인자: $a" >&2; exit 2 ;;
esac; done

# 🔴 저장소 안에서 만들면 **저장소 안에 저장소**가 생긴다.
# `gh repo create --clone` 은 **현재 폴더**에 복제한다 — `~/workflows` 에서 돌리면
# `~/workflows/divcal` 이 되고, 바깥 저장소가 그걸 추적하려 든다.
# 문서로 *"홈에서 돌리세요"* 라고 적는 대신 **여기서 막는다.**
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  root="$(git rev-parse --show-toplevel)"
  cat >&2 <<EOF
🔴 여기는 git 저장소 안이다: $root

  \`gh repo create --clone\` 은 **현재 폴더**에 복제하므로 저장소 안에 저장소가 생긴다.
  프로젝트를 둘 폴더에서 다시 돌려라. 예:

    cd ~ && $here/tools/with-admin-token.sh $here/new-project.sh $name${*:+ $*}
EOF
  exit 2
fi

# 라이선스는 **저장소를 만들기 전에** 확인한다 — 오타 하나로 저장소를 만들었다 지우지 않는다.
# 그리고 SPDX 식별자(MIT · Apache-2.0)를 여기서 얻어 copier 에 넘긴다.
if ! spdx="$(gh api "/licenses/$lic" --jq .spdx_id 2>/dev/null)"; then
  echo "모르는 라이선스: $lic  (예: mit · apache-2.0 · gpl-3.0 — https://api.github.com/licenses)" >&2
  exit 2
fi

# 아키타입 — 바닥(`standards` direction/05)의 조건부 항목이 이 값으로 정해진다.
# 기본은 가장 좁은 것이다: 넓히는 것은 파일을 더하는 일이고, 좁히는 것은
# 안 쓰는 파일을 지우는 일이라 스텁으로 남는다.
arch="${arch:-cli}"

# 🔴 **아키타입 목록의 정본은 템플릿의 `copier.yml` 이다.** 여기 베껴두면 갈린다 —
# 실측(2026-08-30): 이 줄에 `service` 가 박혀 있었다. 템플릿은 진작 `backend` 로 바꿨는데
# 여기만 안 따라와서 **맞는 값(`backend`)이 거부되고 없는 값(`service`)은 저장소를 만든
# 뒤에야 죽었다**(copier 가 거부 → trap 이 지운다). fail-closed 는 성립했지만
# **사용자는 왕복 한 번을 버렸고 엉뚱한 오류를 봤다.**
#
# 그래서 **템플릿에서 읽어온다.** 못 읽으면 막지 않고 넘긴다 — copier 가 어차피 거부하고
# trap 이 지운다. **여기서 죽이는 값을 여기가 정하지 않는다.**
choices="$(
  gh api "repos/coolbress/project-template/contents/copier.yml?ref=$template_ref" --jq .content 2>/dev/null \
    | base64 -d 2>/dev/null \
    | sed -n '/^archetype:/,/^[a-z_]/p' \
    | sed -n 's/^    [^:]*: \([a-z][a-z0-9-]*\)$/\1/p'
)" || choices=""

if [ -n "$choices" ]; then
  if ! printf '%s\n' "$choices" | grep -qxF "$arch"; then
    echo "모르는 아키타입: $arch" >&2
    echo "  템플릿이 받는 것: $(printf '%s' "$choices" | tr '\n' ' ')" >&2
    exit 2
  fi
else
  echo "⚠️ 템플릿의 아키타입 목록을 못 읽었다 — copier 가 판정한다(틀리면 trap 이 지운다)." >&2
fi

created=0
cleanup() {
  [ "$created" = 1 ] || return 0
  echo "🔴 바닥을 다 세우지 못했다 — 방금 만든 원격 저장소를 지운다 (로컬 사본 ./$name 은 남는다)." >&2
  gh repo delete "coolbress/$name" --yes || true
}
trap cleanup EXIT

# 🔴 `--template` 이 아니라 **빈 저장소 + copier** 다.
# `--template` 은 시점 복사라 복사가 끝나면 원본과 연결이 끊긴다 — 템플릿을 고쳐도
# 인스턴스는 그대로다. copier 는 `.copier-answers.yml` 을 남겨 어느 판에서 태어났는지
# 기억하고 `copier update` 로 그 뒤 변경을 병합한다.
gh repo create "coolbress/$name" "$vis" --clone
created=1

# 🔴 빈 저장소를 클론하면 로컬 HEAD 가 `init.defaultBranch` 를 따른다 — 그게 `master` 면
# 룰셋이 거는 `~DEFAULT_BRANCH`(=`main`)와 어긋나 **벽이 빈 브랜치를 지키게 된다.**
git -C "$name" symbolic-ref HEAD refs/heads/main

# 템플릿을 렌더한다. `--defaults` + `--data` 로 물어보지 않는다.
#
# 🔵 **이름 치환은 여기서 끝난다** (project-template v2.0.0 부터). 이름·라이선스·패키지
# 디렉터리·`uv.lock` 이 전부 렌더 시점에 정해져 나온다 — 뒤에 고칠 것이 없다.
# ⚠️ **못 만들 이름은 여기서 죽는다.** `copier.yml` 의 `validator` 가 `9lives`·`class`·`my+app`
# 같은 것을 **파일을 하나도 만들기 전에** 거절한다. 그러면 아래 `trap` 이 저장소를 지운다.
# (v1.0.0 은 `bootstrap.sh` 로 **만든 뒤에** 고쳤고, 그래서 틀린 이름은 트리를 반쯤
#  바꿔놓은 뒤에야 걸렸다.)
uvx --quiet copier copy --defaults --quiet \
  --data "project_name=$name" --data "license=$spdx" --data "archetype=$arch" \
  --vcs-ref "$template_ref" "gh:coolbress/project-template" "$name" < /dev/null
( cd "$name" && git add -A && git commit -qm "chore: copier 로 템플릿에서 생성 ($arch)" )

# 🔴 **푸시가 되는지 앞에서 확인한다.** 나머지를 다 하고 나서 알면 늦다 — 실제로 두 번 그렇게 실패했다(2026-08-27: 붙여넣기에 딸려온 공백 한 칸.
# API 는 헤더라 서버가 잘라내서 통과했고, git push 는 HTTP Basic 이라 base64 안에 남아 거부됐다).
probe="__push-probe"
if ! err="$( cd "$name" && git push -q origin "HEAD:refs/heads/$probe" 2>&1 )"; then
  cat >&2 <<EOF
🔴 푸시 권한이 없다. 저장소는 만들었지만 아무것도 올릴 수 없다.

$err

확인할 것:
  · 관리자 토큰에 **repo** 스코프가 있나
  · 붙여넣을 때 **공백이 딸려오지 않았나** — 래퍼가 길이를 찍는다 (classic 은 40)
EOF
  exit 1
fi
( cd "$name" && git push -q origin --delete "$probe" ) || true

( cd "$name" && git push -q )

# PR 제목 타입 라벨. `label.yml` 이 제목에서 파생시켜 붙이고 `.github/release.yml` 이
# 그 라벨로 릴리스 노트를 묶는다. 🔴 **라벨이 없으면 붙이기가 실패한다** — 여기서 만든다.
# (라벨 워크플로에 생성 권한을 주지 않으려는 것이다. 그건 벽이 아니라 편의라 권한을 최소로 둔다.)
for lbl in feat fix docs style refactor perf test build ci chore revert breaking; do
  gh label create "$lbl" --repo "coolbress/$name" --color ededed \
    --description "PR 제목 타입 (자동)" >/dev/null 2>&1 || true
done

# `task` 라벨. 🔴 **`bug`·`enhancement` 는 GitHub 기본 라벨이라 있는데 `task` 는 없다** —
# 그래서 `task.yml` 폼만 라벨이 비어 있었다(2026-08-30 실측). 기획이 만드는 과제가
# 버그 신고와 안 갈려서 `gh issue list` 로 *다음 할 일* 을 못 추린다.
gh label create "task" --repo "coolbress/$name" --color 0052cc \
  --description "만들 것 하나 (인수기준이 검사에 매핑된다)" >/dev/null 2>&1 || true

# 🔴 회부(HITL) 라벨. 없으면 새 저장소에서 **결정을 이슈로 남길 수가 없다** —
# `standards` 의 `check_decision_referrals.py` 가 이 라벨로 분모를 센다.
# 종류를 셋으로 가르는 이유: Approval·Input·Escalation 은 **트리거도 대기 방식도 다르다**
# (12-Factor Agents Factor 7 계열 · `standards` direction/06 §회부 규율).
gh label create "decision" --repo "coolbress/$name" --color 0e8a16 \
  --description "소유자에게 회부한 결정" >/dev/null 2>&1 || true
gh label create "decision:approval" --repo "coolbress/$name" --color d93f0b \
  --description "되돌리기 어려운 행동의 가부" >/dev/null 2>&1 || true
gh label create "decision:input" --repo "coolbress/$name" --color 1d76db \
  --description "에이전트에게 없는 정보·취향" >/dev/null 2>&1 || true
gh label create "decision:escalation" --repo "coolbress/$name" --color b60205 \
  --description "막혔다 — 권한 없음 · 반복 실패" >/dev/null 2>&1 || true
gh label create "needs-simpler" --repo "coolbress/$name" --color fbca04 \
  --description "다시 쉽게 설명해달라" >/dev/null 2>&1 || true

# 🔴 mattpocock-skills 의 트리아지 라벨 다섯. `/to-spec` 이 `ready-for-agent` 를 다는데
# **어느 스킬도 라벨을 만들지는 않는다** — 없으면 `gh issue create --label` 에서 죽는다
# (실물 확인 2026-09-02 · 이름은 `docs/agents/triage-labels.md` 의 기본값과 같다).
for lbl in needs-triage needs-info ready-for-agent ready-for-human wontfix; do
  gh label create "$lbl" --repo "coolbress/$name" --color c5def5 \
    --description "트리아지 (mattpocock-skills)" >/dev/null 2>&1 || true
done

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
cat <<EOF
완료 → https://github.com/coolbress/$name  (${vis#--} · $lic)

🔴 남은 한 단계 — **사람만 할 수 있다** (토큰 편집 API 가 없다)
   에이전트 토큰(agent-daily)의 저장소 목록에 **$name 을 추가**해야 한다.
   안 하면 에이전트가 브랜치도 PR 도 못 만든다 — 403 만 조용히 난다.

     https://github.com/settings/personal-access-tokens
     → agent-daily → Repository access → Select repositories → $name 추가 → Update token

   (토큰 값은 안 바뀐다. 세션 재시작도 필요 없다.)

📌 그리고 감사 대상에 넣는다 — standards 의 tools/repo_audit.py 의 REPOS 에
   "coolbress/$name" 한 줄. 안 넣으면 이 저장소의 벽이 무너져도 아무도 안 본다.
   **이건 에이전트가 PR 로 하면 된다** — 위 토큰 단계를 끝낸 뒤 시키면 된다.
EOF
