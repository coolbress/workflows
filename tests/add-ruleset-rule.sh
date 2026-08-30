#!/usr/bin/env bash
# `add-ruleset-rule.sh` 시험. 네트워크는 안 탄다 — `gh` 를 목으로 바꾼다.
#
# 지켜야 하는 성질 둘:
#   ① **더하기만 한다** — 기존 규칙과 `bypass_actors`·`enforcement` 가 그대로 남는다.
#      손으로 JSON 을 붙이면 다른 필드가 날아가고 **벽이 조용히 약해진다.** 그게 이 도구의 존재 이유다.
#   ② **모르는 프리셋은 안 받는다** — 자유 JSON 을 받으면 ①의 보장이 사라진다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
case "$*" in
  *"/rulesets/1"*) echo '{"id":1,"created_at":"x","_links":{},"name":"r","target":"branch","enforcement":"active","bypass_actors":[],"conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"deletion"},{"type":"pull_request","parameters":{"required_approving_review_count":0}}]}' ;;
  *"/rulesets"*)   echo 1 ;;
esac
exit 0
MOCK
chmod +x "$work/bin/gh"; export PATH="$work/bin:$PATH"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
run() { "$root/tools/add-ruleset-rule.sh" "$@" >"$work/out" 2>&1; echo $?; }

rc=$(run --dry-run r/r linear-history)
if [ "$rc" = 0 ]; then ok "알려진 프리셋은 통과한다"; else bad "종료코드 $rc"; fi
if grep -q "required_linear_history" "$work/out"; then ok "규칙이 더해진다"; else bad "규칙이 안 더해졌다"; fi
if grep -q "deletion" "$work/out"; then ok "기존 규칙이 남는다"; else bad "🔴 기존 규칙이 사라졌다"; fi
if grep -q "pull_request" "$work/out"; then ok "기존 규칙이 남는다 (둘째)"; else bad "🔴 기존 규칙이 사라졌다"; fi
if grep -q "우회자: 0건 · 강제: active" "$work/out"; then ok "우회자·강제가 그대로다"; else bad "🔴 벽이 약해졌다"; fi

rc=$(run --dry-run r/r 그런프리셋없음)
if [ "$rc" != 0 ]; then ok "모르는 프리셋은 거부한다"; else bad "모르는 프리셋이 통과했다"; fi

rc=$(run --dry-run r/r)
if [ "$rc" != 0 ]; then ok "프리셋 없이 부르면 거부한다"; else bad "빈 호출이 통과했다"; fi

# ③ 같은 종류를 두 번 넣어도 하나다 — 서버가 중복을 거부한다.
rc=$(run --dry-run r/r linear-history linear-history)
n=$(grep -o "required_linear_history" "$work/out" | wc -l | tr -d ' ')
if [ "$n" = 1 ]; then ok "중복은 하나로 접힌다"; else bad "중복이 $n 개 남았다"; fi

# ④ 되돌리기 어려운 것은 묻는다 — tty 가 없으면 진행되면 안 된다.
rc=$("$root/tools/add-ruleset-rule.sh" --dry-run r/r signed-commits </dev/null >"$work/out" 2>&1; echo $?)
if [ "$rc" != 0 ] || grep -q "에이전트가 이 저장소에 아무것도 못 넣는다" "$work/out"
then ok "signed-commits 는 경고하고 확인을 받는다"
else bad "🔴 되돌리기 어려운 것이 조용히 지나갔다"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
