#!/usr/bin/env bash
# `create-tag-ruleset.sh` 시험. 네트워크는 안 탄다 — `gh` 를 목으로 바꾼다.
#
# 지켜야 하는 성질 넷:
#   ① **생성은 막지 않는다** — 막으면 릴리스를 못 낸다. 막는 것은 삭제와 이동뿐이다.
#   ② **우회자 0** — 브랜치 룰셋과 같은 규율. 소유자도 못 넘는다.
#   ③ **두 번 만들지 않는다** — 같은 대상의 룰셋이 둘이면 어느 쪽이 거는지 사람이 헷갈린다.
#   ④ **쓰고 나서 대조한다** — 200 을 받아도 걸린 게 아니다(실측으로 겪었다).
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
case "$*" in
  *"-X POST"*)  cat >/dev/null; printf '%s\n' "$POST_BODY_SINK" >/dev/null 2>&1 || true; exit 0 ;;
  *"length"*)   echo "${AFTER_COUNT:-1}" ;;              # 만든 뒤 몇 개로 보이나
  *".id"*)      [ "${ALREADY:-0}" = 1 ] && echo 7 || true ;;  # 이미 있나
esac
exit 0
MOCK
chmod +x "$work/bin/gh"; export PATH="$work/bin:$PATH" POST_BODY_SINK=""

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# ── 본문이 옳은가. 스크립트에서 직접 뽑아 검사한다.
BODY="$(sed -n '/^body() {/,/^}/p' "$root/tools/create-tag-ruleset.sh" | sed '1d;$d' | bash)"
if echo "$BODY" | jq -e '.target == "tag"' >/dev/null; then ok "대상이 tag 다"; else bad "대상이 tag 가 아니다"; fi
if echo "$BODY" | jq -e '(.bypass_actors | length) == 0' >/dev/null; then ok "우회자 0"; else bad "🔴 우회자가 있다 — 브랜치 룰셋과 규율이 갈린다"; fi
if echo "$BODY" | jq -e '[.rules[].type] | sort == ["deletion","non_fast_forward"]' >/dev/null; then ok "삭제와 이동만 막는다"; else bad "규칙이 다르다"; fi
if echo "$BODY" | jq -e '[.rules[].type] | index("creation") == null' >/dev/null; then ok "🔴 생성은 안 막는다 (막으면 릴리스를 못 낸다)"; else bad "생성을 막고 있다"; fi
if echo "$BODY" | jq -e '.enforcement == "active"' >/dev/null; then ok "강제가 active 다"; else bad "강제가 active 가 아니다"; fi

# ── 이미 있으면 안 만든다
ALREADY=1 "$root/tools/create-tag-ruleset.sh" r/r >"$work/out" 2>&1
if grep -q "이미 있다" "$work/out"; then ok "이미 있으면 건너뛴다"; else bad "🔴 두 번 만든다"; fi

# ── 쓰고 나서 대조한다
if AFTER_COUNT=0 "$root/tools/create-tag-ruleset.sh" r/r >"$work/out" 2>&1
then bad "🔴 조용한 no-op 이 통과했다"
elif grep -q "🔴" "$work/out"; then ok "안 걸리면 실패로 끝나고 이유를 말한다"
else bad "실패했지만 이유를 안 말한다"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
