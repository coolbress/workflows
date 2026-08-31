#!/usr/bin/env bash
# **제3자 리뷰 벽이 무엇을 막고 무엇을 안 막는가.**
#
# 판정은 `pr-review.yml` 의 `run:` 안에 박힌 파이썬 한 토막이다. 워크플로 안에만 있으면
# **아무도 안 돌려본다** — 첫 실행이 곧 시험이 되고, 그때는 이미 PR 이 빨갛다.
#
# 🔴 **이 벽의 계약은 좁다.** 보증하는 것은 *"제3자가 **이 커밋** 을 봤다"* 뿐이고
# **리뷰의 판정(approve/changes)으로는 막지 않는다** — MSR '26 이 리뷰 에이전트 13종 중
# **12종의 signal ratio 가 60% 미만**이라 하므로 그걸로 막으면 **소음으로 막는 것**이다.
# **두 방향을 다 시험한다** — 통과만 보는 시험은 증명이 약하다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wf="$root/.github/workflows/pr-review.yml"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

python3 - "$wf" "$tmp/attest.py" <<'PY'
import sys, pathlib, textwrap
lines = pathlib.Path(sys.argv[1]).read_text().splitlines()
start = next(i for i, ln in enumerate(lines) if ln.rstrip().endswith("<<'PY'"))
end = next(i for i in range(start + 1, len(lines)) if lines[i].strip() == "PY")
body = textwrap.dedent("\n".join(lines[start + 1:end]))
assert "commit_id" in body, "판정 토막을 못 찾았다 — 워크플로 모양이 바뀌었다"
pathlib.Path(sys.argv[2]).write_text(body + "\n")
PY
[ -s "$tmp/attest.py" ] || { echo "🔴 판정 토막을 못 뽑았다" >&2; exit 1; }

HEAD=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OLD=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
BOT='chatgpt-codex-connector[bot]'

fails=0
run() {  # 이름 · reviews JSON · comments JSON · 기대 종료코드
  printf '%s' "$2" > "$tmp/r.json"
  printf '%s' "$3" > "$tmp/c.json"
  python3 "$tmp/attest.py" "$HEAD" "$BOT" "$tmp/r.json" "$tmp/c.json" >"$tmp/log" 2>&1
  got=$?
  if [ "$got" -ne "$4" ]; then
    echo "🔴 $1 — 기대 exit=$4 인데 $got" >&2
    sed 's/^/     /' "$tmp/log" >&2
    fails=$((fails + 1))
  else
    echo "  ✅ $1"
  fi
}

rv() { printf '[{"user":{"login":"%s"},"commit_id":"%s","state":"%s","body":"%s"}]' "$1" "$2" "$3" "${4:-말}"; }

echo "── 🔴 막아야 한다 (제3자가 이 커밋을 안 봤다)"
run "아무 리뷰도 없다"              '[]'                        '[]' 1
run "사람 리뷰만 있다"              "$(rv me "$HEAD" APPROVED)" '[]' 1
run "🔴 인정된 봇인데 **옛 커밋**"   "$(rv "$BOT" "$OLD" COMMENTED)" '[]' 1
run "다른 봇이 이 커밋을 봤다"       "$(rv 'copilot-pull-request-reviewer[bot]' "$HEAD" COMMENTED)" '[]' 1
run "JSON 이 깨졌다"                'not json'                  '[]' 1

echo "── ✅ 통과해야 한다"
run "봇 리뷰가 이 커밋에 있다"       "$(rv "$BOT" "$HEAD" COMMENTED)" '[]' 0
run "리뷰 코멘트로만 왔다"           '[]' "$(rv "$BOT" "$HEAD" '')"    0
run "로그인 대소문자가 다르다"       "$(rv 'ChatGPT-Codex-Connector[bot]' "$HEAD" COMMENTED)" '[]' 0

echo "── 🔴 판정은 위임하지 않는다 (막으면 **안 되는** 것)"
run "CHANGES_REQUESTED 여도 통과"    "$(rv "$BOT" "$HEAD" CHANGES_REQUESTED)" '[]' 0
run "APPROVED 여도 통과"             "$(rv "$BOT" "$HEAD" APPROVED)"          '[]' 0

echo "── 못 찾았을 때 **본 작성자를 찍는가** (이름이 틀렸을 때 한 번에 고치라고)"
printf '%s' "$(rv 'some-other-bot[bot]' "$HEAD" COMMENTED)" > "$tmp/r.json"
echo '[]' > "$tmp/c.json"
python3 "$tmp/attest.py" "$HEAD" "$BOT" "$tmp/r.json" "$tmp/c.json" >"$tmp/log" 2>&1 || true
if grep -q "some-other-bot" "$tmp/log"; then
  echo "  ✅ 본 작성자를 찍는다"
else
  echo "🔴 작성자를 안 찍는다 — 이름이 틀렸을 때 고칠 단서가 없다" >&2
  cat "$tmp/log" >&2; fails=$((fails + 1))
fi

if [ "$fails" -ne 0 ]; then
  echo "🔴 $fails 건 실패" >&2
  exit 1
fi
echo "✅ 이 커밋을 봤는지만 막고, 리뷰의 판정으로는 안 막는다"
