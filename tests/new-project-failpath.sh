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
    # 실제 `gh repo create --clone` 처럼, 이름이 같은 디렉터리를 만들고 클론해 둔다.
    name=""
    for a in "$@"; do case "$a" in coolbress/*) name="${a#coolbress/}"; break ;; esac; done
    [ -n "$name" ] || { echo "mock gh: 저장소 이름을 못 읽었다" >&2; exit 1; }
    mkdir -p "$name"
    ( cd "$name"
      "$REAL_GIT" init -q -b main
      # 템플릿이 싣고 오는 것들. LICENSE 가 **추적되어 있어야** 뒤의
      # `git diff --quiet` 가 라이선스 교체를 감지한다 (실제와 같은 조건).
      printf 'MIT\n' > LICENSE
      printf 'name = "app"\n' > pyproject.toml
      cat > bootstrap.sh <<'BS'
#!/usr/bin/env bash
set -euo pipefail
# 실물과 같은 서명: <이름> [SPDX]. 2번째 인자가 안 오면 여기서 실패해야 한다.
printf 'name = "%s"\nlicense = "%s"\n' "$1" "${2:?bootstrap 이 SPDX 를 못 받았다}" > pyproject.toml
git add -A
BS
      chmod +x bootstrap.sh
      "$REAL_GIT" add -A
      "$REAL_GIT" commit -qm init )
    ;;
  license-check) printf 'MIT\n' ;;
  license)       printf 'MOCK LICENSE BODY\n' ;;
esac
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
chmod +x "$work/bin/gh" "$work/bin/git"

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
# 저장소가 생기기 *전* 실패는 지울 것이 없다.
# license-check 가 여기 있는 것이 핵심이다 — 라이선스 오타는 저장소를 만들기 전에 걸러야 한다.
run license-check err no
run create        err no
# 생긴 *뒤* 는 어느 단계에서 넘어지든 지운다.
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

printf 'RESULT %s pass=%d fail=%d\n' "$([ "$fail" = 0 ] && echo PASS || echo FAIL)" "$pass" "$fail"
[ "$fail" = 0 ]
