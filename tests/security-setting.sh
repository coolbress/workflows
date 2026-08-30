#!/usr/bin/env bash
# `set-security-setting.sh` 시험. 네트워크는 안 탄다 — `gh` 를 목으로 바꾼다.
#
# 지켜야 하는 성질: **쓰고 나서 다시 읽어 대조한다.**
# 실측(2026-08-30): 확인 없는 명령이 200 을 받고 아무것도 안 바꿨다.
# `-f "a[b][c]=v"` 는 폼 필드고 이 엔드포인트는 중첩 JSON 을 받는다 — 서버는 조용히 무시한다.
# **200 을 받아도 걸린 게 아니다.**
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

# 목: PATCH 를 받아도 상태가 안 바뀌는 서버 — 실제로 일어난 일 그대로.
cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
case "$*" in
  # 🔴 stdin 을 반드시 비운다. 안 읽으면 앞의 `jq` 가 SIGPIPE 로 죽고 `pipefail` 이
  # 메시지 출력 **전에** 스크립트를 끊는다 — 시험이 타이밍에 따라 흔들린다(실측).
  # 진짜 `gh` 는 `--input -` 를 읽는다.
  *"-X PATCH"*) cat >/dev/null; exit 0 ;;   # 200 을 준다. 그런데 아무것도 안 바뀐다
  *) echo "${MOCK_STATUS:-disabled}" ;;    # 읽으면 여전히 disabled
esac
MOCK
chmod +x "$work/bin/gh"; export PATH="$work/bin:$PATH"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

"$root/tools/set-security-setting.sh" non-provider-patterns r/r >"$work/out" 2>&1
rc=$?
if [ "$rc" != 0 ]; then ok "안 걸렸는데 200 이면 실패로 끝난다"; else bad "🔴 조용한 no-op 이 성공으로 통과했다"; fi
if grep -q "안 걸렸다" "$work/out"; then ok "무엇이 안 걸렸는지 말한다"; else bad "이유를 안 말한다"; fi

MOCK_STATUS=enabled "$root/tools/set-security-setting.sh" non-provider-patterns r/r >"$work/out" 2>&1
rc=$?
if [ "$rc" = 0 ]; then ok "실제로 걸리면 통과한다"; else bad "걸렸는데 실패했다"; fi

if ! "$root/tools/set-security-setting.sh" 모르는설정 r/r >/dev/null 2>&1
then ok "모르는 설정은 거부한다"; else bad "모르는 설정이 통과했다"; fi

if ! "$root/tools/set-security-setting.sh" non-provider-patterns >/dev/null 2>&1
then ok "저장소 없이 부르면 거부한다"; else bad "빈 호출이 통과했다"; fi

# 🔴 폼 필드 형태가 다시 들어오는 것을 막는다 — 그게 이 사고의 원인이었다.
# ⚠️ **주석은 빼고 본다.** 그 스크립트의 주석이 *하지 말 것* 으로 그 문법을 인용한다 —
# 안 빼면 시험이 자기 오탐을 낸다(`check_template_drift` 의 `--jq` 검사가 겪은 그 형태다).
if grep -v '^\s*#' "$root/tools/set-security-setting.sh" | grep -q 'security_and_analysis\['
then bad "🔴 폼 필드 대괄호 문법이 있다 — 서버가 조용히 무시한다"
else ok "중첩 JSON 으로 보낸다 (폼 필드 문법 없음)"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
