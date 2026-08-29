#!/usr/bin/env bash
# 플러그인 훅이 **세션을 막지 않는가**, 그리고 **짧게 유지되는가.**
#
# 🔴 실패하는 훅은 세션을 막는다. 보여주는 훅이 일을 막으면 그건 벽 흉내이고,
# 벽은 GitHub 에 있다 (`standards` direction/04 §원칙 03 시행 기준 판별식 ①②).
# 🔴 매 세션 지불하는 컨텍스트라 길이에 상한을 둔다 — 늘리려면 근거를 적어라.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook="$root/plugins/standards-hooks/hooks/session-start.sh"
max_lines=20

pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ✅ %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  🔴 %s\n' "$1"; }
want() { if [ "$1" = yes ]; then ok "$2"; else bad "$3"; fi; }

echo "플러그인 훅 — 막지 않는가 · 짧은가"

if [ -x "$hook" ]; then t=yes; else t=no; fi
want "$t" "실행 권한이 있다" "실행 권한이 없다 — 훅이 조용히 실패한다"

# 🔴 fail-open: 환경을 통째로 비우고 PATH 만 남겨 아무것도 없는 상태를 흉내낸다.
out="$(env -i PATH=/usr/bin:/bin bash "$hook" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ]; then t=yes; else t=no; fi
want "$t" "빈 환경에서도 종료코드 0 (fail-open)" "빈 환경에서 종료코드 $rc — 세션을 막는다"

if [ -n "$out" ]; then t=yes; else t=no; fi
want "$t" "출력이 있다" "출력이 비었다 — 아무것도 안 알려준다"

n="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
if [ "$n" -le "$max_lines" ]; then t=yes; else t=no; fi
want "$t" "출력 ${n}줄 (상한 ${max_lines})" "출력 ${n}줄 — 상한 ${max_lines} 을 넘었다"

# 🔴 이 훅은 네트워크를 타면 안 된다. 세션 시작이 굼뜨면 그것만으로 값을 잃는다.
# ⚠️ **히어독 본문은 빼고 본다** — 훅이 *출력하는 글* 속 `gh issue list` 를
# 호출로 세면 시험이 자기 오탐을 낸다(실제로 한 번 그랬다).
code="$(awk '/<<.?TXT.?$/{skip=1;next} skip&&/^TXT$/{skip=0;next} !skip' "$hook")"
if printf '%s' "$code" | grep -qE '(^|[|&;( ])(gh|curl|wget)([[:space:]]|$)'; then t=no; else t=yes; fi
want "$t" "네트워크를 안 탄다" "네트워크 호출이 있다 — 세션 시작을 늦춘다"

echo
echo "결과: $pass PASS · $fail FAIL"
[ "$fail" -eq 0 ]
