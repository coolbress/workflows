#!/usr/bin/env bash
# 플러그인 매니페스트와 커맨드 frontmatter 시험. 네트워크는 안 탄다.
#
# 🔴 왜 생겼나 (2026-08-30): `floor-check` 는 제목이 *"읽고, 말하고, **안 고친다**"* 인데
# **아무것도 그걸 집행하지 않았다.** `review` 는 자기 본문이 *"고치면 그 수정이 다시 리뷰를
# 부르고…"* 라고 경고하면서 **그 루프를 막지 않았다.** 둘 다 **산문으로만 약속**했다.
#
# ⚠️ **`allowed-tools` 가 아니라 `disallowed-tools` 다.** 1차 문서:
#   allowed-tools    → "Tools Claude can use **without asking permission**"  (푸는 것)
#   disallowed-tools → "Tools **removed** from Claude's available pool"      (잠그는 것)
# 웹 요약 여러 곳이 이걸 반대로 적는다. 이 시험이 그 혼동이 들어오는 것도 막는다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

fm() { sed -n '2,/^---$/p' "$1"; }   # frontmatter 본문

# ── ① 고치지 않겠다고 적은 커맨드는 쓰기 도구를 실제로 뺀다
for c in floor-check review; do
  f="$root/plugins/standards/commands/$c.md"
  if fm "$f" | grep -q "^disallowed-tools:.*Edit"; then
    ok "$c: 쓰기 도구가 실제로 빠진다"
  else
    bad "🔴 $c: '안 고친다' 가 산문뿐이다 — disallowed-tools 가 없다"
  fi
  if fm "$f" | grep -q "^allowed-tools:"; then
    bad "🔴 $c: allowed-tools 는 **푸는 것**이다. 잠그려면 disallowed-tools 다"
  else
    ok "$c: allowed-tools 를 잠금으로 착각하지 않았다"
  fi
done

# ── ② 되돌리기 어려운 커맨드는 모델이 못 부른다
for c in new-project review; do
  if fm "$root/plugins/standards/commands/$c.md" | grep -q "^disable-model-invocation: true"; then
    ok "$c: 사용자 전용이다"
  else
    bad "🔴 $c: 부작용이 있는데 모델이 부를 수 있다"
  fi
done

# ── ③ 버전이 매니페스트 셋에서 같다 — 갈리면 소비자가 무엇을 가졌는지 모른다
vs="$(grep -ho '"version": "[^"]*"' \
      "$root/plugins/standards/.claude-plugin/plugin.json" \
      "$root/plugins/standards-hooks/.claude-plugin/plugin.json" \
      "$root/.claude-plugin/marketplace.json" | sort -u | wc -l | tr -d ' ')"
if [ "$vs" = 1 ]; then ok "버전이 세 매니페스트에서 하나다"; else bad "🔴 버전이 $vs 종류다 — 소비자가 무엇을 가졌는지 모른다"; fi

# ── ④ 외부 아스날은 SHA 로 핀돼 있다. 태그는 가변이라 공급망 벡터다
if python3 - "$root/.claude-plugin/marketplace.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
bad = [p["name"] for p in d["plugins"]
       if isinstance(p.get("source"), dict) and not p["source"].get("sha")]
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
then ok "외부 항목이 전부 SHA 로 핀돼 있다"; else bad "🔴 SHA 없이 등재된 외부 항목이 있다"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
