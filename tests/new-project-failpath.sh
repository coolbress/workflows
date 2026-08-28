#!/usr/bin/env bash
# new-project.sh 의 **실패 경로** 시험.
#
# 왜 이 시험이 있나: 이 스크립트가 지켜야 하는 단 하나의 성질은
# **"어느 단계에서 실패하든 벽 없는 원격 저장소를 남기지 않는다"** 이다.
# 성공 경로는 눈으로 보면 안다. 실패 경로는 실패시켜 보지 않으면 모른다 —
# 그리고 진짜로 실패시키려면 진짜 저장소를 만들어야 한다. 그래서 `gh` 를 목으로 바꾼다.
#
# 목은 호출을 전부 기록하고, FAIL_AT 이 가리키는 단계에서만 실패한다.
# 판정은 하나다: **`gh repo delete` 가 불렸는가.**
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
real_git="$(command -v git)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

# ── 목: gh ───────────────────────────────────────────────────
cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
printf 'gh %s\n' "$*" >> "$GH_LOG"
all="$*"
step=other
case "$all" in
  "repo create"*)           step=create ;;
  "repo delete"*)           step=delete ;;
  *"/licenses/"*.spdx_id*) step=license-check ;;
  *"/licenses/"*)           step=license ;;
  *code-scanning*)          step=codeql ;;
  *"/rulesets"*)            step=ruleset ;;
  *security_and_analysis*)  step=secret ;;
  *vulnerability-alerts*)   step=dependabot ;;
  *automated-security-fixes*) step=dependabot ;;
  *selected-actions*)       step=allowlist ;;
  *actions/permissions*)    step=actions ;;
  *allow_merge_commit*)     step=merge ;;
esac
if [ "$step" = "${FAIL_AT:-}" ]; then
  echo "mock gh: $step 단계를 의도적으로 실패시킨다" >&2
  exit 1
fi
case "$step" in
  create)
    # 실제 `gh repo create --clone` 처럼 디렉터리를 만들고 클론해 둔다.
    # 🔴 **내용은 넣지 않는다** — 이제 `--template` 이 아니라 빈 저장소이고,
    # 파일은 copier 가 넣는다. 그래서 여기는 `git init` 까지다.
    name=""
    for a in "$@"; do case "$a" in coolbress/*) name="${a#coolbress/}"; break ;; esac; done
    [ -n "$name" ] || { echo "mock gh: 저장소 이름을 못 읽었다" >&2; exit 1; }
    mkdir -p "$name"
    # 🔴 일부러 `master` 로 만든다. 실제로 `init.defaultBranch=master` 인 기계가 있고,
    # 그러면 룰셋이 거는 `~DEFAULT_BRANCH`(=main)와 어긋나 **벽이 빈 브랜치를 지킨다.**
    # new-project.sh 의 `symbolic-ref` 가 그걸 막는데, 목이 `main` 으로 만들면
    # 그 줄을 지워도 시험이 통과한다 — 아무것도 안 지키는 시험이 된다.
    ( cd "$name" && "$REAL_GIT" init -q -b master )
    ;;
  license-check) printf 'MIT\n' ;;
  license)       printf 'MOCK LICENSE BODY\n' ;;
esac
exit 0
MOCK

# ── 목: uvx (copier 만 가로챈다) ─────────────────────────────
# 실물은 `uvx copier copy … <dst>` 다. 템플릿이 싣고 오는 것을 그 자리에 만든다.
cat > "$work/bin/uvx" <<'MOCK'
#!/usr/bin/env bash
set -u
printf 'uvx %s\n' "$*" >> "$GH_LOG"
case "$*" in
  *copier*copy*) ;;
  *) exit 0 ;;
esac
if [ "${FAIL_AT:-}" = copier ]; then
  echo "mock copier: 렌더를 의도적으로 실패시킨다" >&2
  exit 1
fi
dst="${!#}"   # 마지막 인자가 목적지다
# 🔵 project-template v2.0.0 부터 **렌더가 끝이다.** 목도 그렇게 행동한다 —
# 자리표시자를 남기고 나중에 고치는 단계가 없다. `--data` 로 받은 값을 그대로 써낸다.
pname=""; plic=""
for a in "$@"; do
  case "$a" in
    project_name=*) pname="${a#project_name=}" ;;
    license=*)      plic="${a#license=}" ;;
  esac
done
: "${pname:?mock copier: --data project_name 을 못 받았다}"
: "${plic:?mock copier: --data license 를 못 받았다}"
# 🔴 `tr '.- '` 로 쓰면 안 된다 — BSD 는 세 글자로 받아주고 **GNU 는 `.`~` ` 범위로 읽는다.**
# 이건 옛 `bootstrap.sh` 주석에 적혀 있던 바로 그 사건이고, 이 목에서 **또 냈다**:
# 로컬(macOS)은 20/20 초록이었고 CI(ubuntu)만 3건 빨갰다 (2026-08-28).
# `sed` 의 대괄호 안에서 `-` 를 **맨 뒤**에 두면 어디서나 리터럴이다.
pkg="$(printf '%s' "$pname" | sed 's/[.[:space:]-]/_/g' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$dst/tests" "$dst/src/$pkg"
# LICENSE 가 **추적되어 있어야** 뒤의 `git diff --quiet` 가 라이선스 교체를 감지한다.
printf 'MIT\n' > "$dst/LICENSE"
printf 'name = "%s"\nlicense = "%s"\n' "$pkg" "$plic" > "$dst/pyproject.toml"
printf 'name = "%s"\n' "$pkg" > "$dst/uv.lock"
: > "$dst/src/$pkg/__init__.py"
printf '_commit: mock\n' > "$dst/.copier-answers.yml"
exit 0
MOCK

# ── 목: git (push 만 가로챈다) ───────────────────────────────
cat > "$work/bin/git" <<'MOCK'
#!/usr/bin/env bash
set -u
for a in "$@"; do
  if [ "$a" = push ]; then
    printf 'git %s\n' "$*" >> "$GH_LOG"
    if [ "${FAIL_AT:-}" = push ]; then
      echo "mock git: push 를 의도적으로 실패시킨다" >&2
      exit 1
    fi
    exit 0
  fi
done
exec "$REAL_GIT" "$@"
MOCK
chmod +x "$work/bin/gh" "$work/bin/git" "$work/bin/uvx"

export REAL_GIT="$real_git"
export PATH="$work/bin:$PATH"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

pass=0; fail=0
run() { # 단계 · 기대 종료(ok|err) · 지움을 기대하나(yes|no)
  local at="$1" want_exit="$2" want_del="$3" dir rc del
  dir="$work/run-$at"; mkdir -p "$dir"
  export GH_LOG="$dir/calls.log"; : > "$GH_LOG"
  ( cd "$dir" && FAIL_AT="$at" "$root/new-project.sh" probe --license=mit ) >"$dir/out" 2>&1
  rc=$?
  del=no; grep -q '^gh repo delete' "$GH_LOG" && del=yes
  local ok=1
  [ "$want_exit" = ok ] && [ "$rc" -ne 0 ] && ok=0
  [ "$want_exit" = err ] && [ "$rc" -eq 0 ] && ok=0
  [ "$del" != "$want_del" ] && ok=0
  if [ "$ok" = 1 ]; then
    printf '  ✅ %-12s 종료=%s 저장소삭제=%s\n' "$at" "$rc" "$del"; pass=$((pass+1))
  else
    printf '  🔴 %-12s 종료=%s(기대 %s) 저장소삭제=%s(기대 %s)\n' "$at" "$rc" "$want_exit" "$del" "$want_del"
    sed 's/^/       /' "$dir/out"; fail=$((fail+1))
  fi
}

echo "new-project.sh 실패 경로 — 어디서 넘어져도 벽 없는 저장소를 남기지 않는가"

# 저장소 안에서 만들면 저장소 안에 저장소가 생긴다. **만들기 전에** 멈춰야 한다.
printf '  '
export GH_LOG="$work/nested.log"; : > "$GH_LOG"
nested="$work/nested"; mkdir -p "$nested" && ( cd "$nested" && "$REAL_GIT" init -q -b main )
if out=$( cd "$nested" && "$root/new-project.sh" probe 2>&1 ); then
  printf '🔴 %-12s 저장소 안에서도 통과했다\n' "nested"; fail=$((fail+1))
elif printf '%s' "$out" | grep -q "git 저장소 안이다"; then
  printf '✅ %-12s 저장소 안에서는 멈춘다\n' "nested"; pass=$((pass+1))
else
  printf '🔴 %-12s 다른 이유로 실패했다\n' "nested"; printf '%s\n' "$out"|tail -2; fail=$((fail+1))
fi

# --private 는 지원하지 않는다. **저장소를 만들기 전에** 멈춰야 한다 —
# 받는 척하고 중간에 실패하면 만들었다 지우는 낭비가 된다.
printf '  '
if out=$( cd "$work" && "$root/new-project.sh" probe --private 2>&1 ) ; then
  printf '🔴 %-12s --private 가 통과했다
' "private"; fail=$((fail+1))
elif printf '%s' "$out" | grep -q "아직 지원하지 않는다"; then
  printf '✅ %-12s 저장소를 만들기 전에 멈춘다
' "private"; pass=$((pass+1))
else
  printf '🔴 %-12s 다른 이유로 실패했다
' "private"; printf '%s
' "$out"|tail -2; fail=$((fail+1))
fi
# 저장소가 생기기 *전* 실패는 지울 것이 없다.
# license-check 가 여기 있는 것이 핵심이다 — 라이선스 오타는 저장소를 만들기 전에 걸러야 한다.
run license-check err no
run create        err no
# 생긴 *뒤* 는 어느 단계에서 넘어지든 지운다.
# copier 는 `--template` 을 대체한 단계다 — 여기서 넘어져도 저장소를 남기면 안 된다.
run copier     err yes
run push       err yes
run license    err yes
run codeql     err yes
run ruleset    err yes
run secret     err yes
run dependabot err yes
run actions    err yes
run allowlist  err yes
run merge      err yes
# 끝까지 성공하면 지우지 않는다 — 이게 없으면 "항상 지운다"도 통과한다.
run none       ok  no

# 🔴 끝까지 성공했을 때 **기본 브랜치가 `main` 인가.**
# 룰셋은 `~DEFAULT_BRANCH` 를 지킨다. 로컬이 `master` 로 커밋하면 원격에 `master` 가 생기고
# `main` 은 비어 있게 되어 **벽이 아무것도 안 지킨다.** 목이 `master` 로 init 하므로
# 이 검사는 `symbolic-ref` 줄이 없으면 실제로 실패한다.
printf '  '
head_ref="$( "$REAL_GIT" -C "$work/run-none/probe" symbolic-ref HEAD 2>/dev/null || echo "?" )"
if [ "$head_ref" = "refs/heads/main" ]; then
  printf '✅ %-12s 기본 브랜치가 main 이다\n' "branch"; pass=$((pass+1))
else
  printf '🔴 %-12s 기본 브랜치가 %s 다 — 룰셋은 ~DEFAULT_BRANCH(main)를 지킨다\n' "branch" "$head_ref"
  fail=$((fail+1))
fi

# 🔵 **렌더가 끝이라는 것**을 판정한다 (project-template v2.0.0).
# bootstrap 단계가 사라졌으므로 생성 직후의 트리에 **이미 실제 이름**이 들어 있어야 한다.
# 안 그러면 새 저장소의 첫 PR 에서 `uv sync --locked` 가 실패한다 — 벽이 서 있어 그대로 잠긴다.
proj="$work/run-none/probe"
for want in 'pyproject.toml:probe' 'pyproject.toml:MIT' 'uv.lock:probe'; do
  f="${want%%:*}"; s="${want#*:}"
  printf '  '
  if grep -qF "$s" "$proj/$f" 2>/dev/null; then
    printf '\xe2\x9c\x85 %-12s %s 에 %s 가 이미 있다\n' "render" "$f" "$s"; pass=$((pass+1))
  else
    printf '\xf0\x9f\x94\xb4 %-12s %s 에 %s 가 없다 — 렌더가 끝이 아니다\n' "render" "$f" "$s"; fail=$((fail+1))
  fi
done
printf '  '
if [ -d "$proj/src/probe" ] && [ ! -e "$proj/bootstrap.sh" ]; then
  printf '\xe2\x9c\x85 %-12s src/probe/ 가 렌더로 생겼고 bootstrap.sh 를 안 들고 다닌다\n' "render"; pass=$((pass+1))
else
  printf '\xf0\x9f\x94\xb4 %-12s src/probe/ 가 없거나 bootstrap.sh 가 남아 있다\n' "render"; fail=$((fail+1))
fi

printf 'RESULT %s pass=%d fail=%d\n' "$([ "$fail" = 0 ] && echo PASS || echo FAIL)" "$pass" "$fail"
[ "$fail" = 0 ]
