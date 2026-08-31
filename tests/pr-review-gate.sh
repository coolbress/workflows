#!/usr/bin/env bash
# **제3자 리뷰의 벽이 무엇을 막고 무엇을 안 막는가.**
#
# `pr-review.yml` 의 판정은 `run:` 안에 박힌 파이썬 한 토막이다. 그 토막이
# 워크플로 안에 있으면 **아무도 안 돌려본다** — 첫 실행이 곧 시험이 되고,
# 그때는 이미 남의 PR 이 빨갛다.
#
# 🔴 **이 벽의 계약은 좁다.** 막는 것은 *"리뷰가 실제로 돌았고 형식이 맞는가"* 뿐이고,
# **findings 로는 막지 않는다** — `standards` 설계원칙 04(*판단은 위임하지 않는다*)와
# 등재 실측(LLM 리뷰 F1 **28.6%** · `IPW-007`) 때문이다.
# **그 두 방향을 다 시험한다** — 통과만 보는 시험은 증명이 약하다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wf="$root/.github/workflows/pr-review.yml"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 워크플로에서 판정 토막을 **텍스트로** 뽑는다 — YAML 파서를 안 쓴다.
# 러너에 `pyyaml` 이 있다는 보장이 없고, 없으면 이 시험이 조용히 안 돈다.
python3 - "$wf" "$tmp/gate.py" <<'PY'
import sys, pathlib, textwrap

lines = pathlib.Path(sys.argv[1]).read_text().splitlines()
start = next(i for i, ln in enumerate(lines) if ln.rstrip().endswith("<<'PY'"))
end = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "PY")
body = textwrap.dedent("\n".join(lines[start + 1:end]))
assert "json.loads" in body, "판정 토막을 못 찾았다 — 워크플로 모양이 바뀌었다"
pathlib.Path(sys.argv[2]).write_text(body + "\n")
PY
[ -s "$tmp/gate.py" ] || { echo "🔴 판정 토막을 못 뽑았다" >&2; exit 1; }

fails=0
ok() {  # 이름 · 입력 · 기대 종료코드
  printf '%s' "$2" > "$tmp/in.json"
  python3 "$tmp/gate.py" "$tmp/in.json" "$tmp/out.md" >"$tmp/log" 2>&1
  got=$?
  if [ "$got" -ne "$3" ]; then
    echo "🔴 $1 — 기대 exit=$3 인데 $got" >&2
    sed 's/^/     /' "$tmp/log" >&2
    fails=$((fails + 1))
  else
    echo "  ✅ $1 (exit=$got)"
  fi
}

good='{"verdict":"needs-attention","summary":"요약","findings":[{"severity":"critical","title":"제목","body":"본문","file":"a.py","line_start":1,"line_end":2,"confidence":0.9,"recommendation":"제안"}],"next_steps":["다음"]}'

echo "── 막아야 하는 것 (리뷰가 안 돌았거나 형식이 틀렸다)"
ok "빈 출력"            ""                                                          1
ok "JSON 이 아님"        "리뷰어가 산문을 뱉었다"                                      1
ok "verdict 오타"        '{"verdict":"ok","summary":"s","findings":[],"next_steps":[]}' 1
ok "summary 비었음"      '{"verdict":"approve","summary":"","findings":[],"next_steps":[]}' 1
ok "findings 가 배열 아님" '{"verdict":"approve","summary":"s","findings":{},"next_steps":[]}' 1
ok "finding 에 열쇠 없음"  '{"verdict":"approve","summary":"s","findings":[{"title":"t"}],"next_steps":[]}' 1

echo "── 🔴 막으면 **안 되는** 것 (판정은 위임하지 않는다)"
ok "critical 이 있어도 통과" "$good"                                                  0
ok "찾은 게 없어도 통과"    '{"verdict":"approve","summary":"s","findings":[],"next_steps":[]}' 0

echo "── 댓글이 실제로 만들어지는가"
printf '%s' "$good" > "$tmp/in.json"
python3 "$tmp/gate.py" "$tmp/in.json" "$tmp/out.md" >/dev/null 2>&1
for want in "third-party / review" "제목" "critical" "F1" "안전망이 아니다"; do
  if grep -qF "$want" "$tmp/out.md"; then
    echo "  ✅ 댓글에 있다: $want"
  else
    echo "🔴 댓글에 없다: $want" >&2; fails=$((fails + 1))
  fi
done

if [ "$fails" -ne 0 ]; then
  echo "🔴 $fails 건 실패" >&2
  exit 1
fi
echo "✅ 벽이 막을 것만 막고 판정은 사람에게 남긴다"
