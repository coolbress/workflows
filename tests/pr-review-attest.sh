#!/usr/bin/env bash
# **제3자 리뷰 벽이 무엇을 막고 무엇을 안 막는가.**
#
# 판정은 `pr-review.yml` 의 `run:` 안에 박힌 파이썬 한 토막이다. 워크플로 안에만 있으면
# **아무도 안 돌려본다** — 첫 실행이 곧 시험이 되고, 그때는 이미 PR 이 빨갛다.
#
# 🔬 **아래 픽스처는 지어낸 게 아니라 실측한 것**이다(2026-09-01 · `standards#211`).
# 첫 판은 `pulls/*/reviews` 를 뒤졌는데 **거기엔 아무것도 안 왔다** — 코덱스는 이슈 댓글
# 하나에 표식을 남긴다. **모양을 보고 나서 고친 자리**라 실물을 그대로 시험에 넣는다.
#
# 🔴 **이 벽의 계약은 좁다**: *"제3자가 **이 커밋** 에서 리뷰를 **끝냈다**"* 뿐이고
# **리뷰의 판정으로는 막지 않는다**(MSR '26 — 에이전트 13종 중 12종이 signal ratio 60% 미만).
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
assert "codex-security-review" in body and "DONE" in body, "판정 토막을 못 찾았다 — 워크플로 모양이 바뀌었다"
pathlib.Path(sys.argv[2]).write_text(body + "\n")
PY
[ -s "$tmp/attest.py" ] || { echo "🔴 판정 토막을 못 뽑았다" >&2; exit 1; }

HEAD=71a704cdca35f00de6e110a3d77a165d895d882a
OLD=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
BOT='chatgpt-codex-connector[bot]'
HEAD_TIME='2026-09-01T05:11:00Z'

# 🔬 지적 0건일 때 오는 **완료 댓글** — 실측 문구 그대로다(`standards#214`).
done_cmt() {
  python3 -c 'import json,sys; print(json.dumps([{"user":{"login":sys.argv[1]},"created_at":sys.argv[2],"body":sys.argv[3]}], ensure_ascii=False))' "$1" "$2" "$3"
}

# 이슈 댓글 하나를 만든다: 작성자 · 표식의 sha · 표식의 status
cmt() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
who, sha, status = sys.argv[1:4]
mark = ""
if sha:
    mark = ('<!-- codex-security-review:v1 ' + json.dumps({
        "blockingSeverityThreshold": "P0", "headSha": sha, "mergeGateEnabled": False,
        "pullRequestNumber": 211, "repository": "coolbress/standards", "status": status,
    }) + ' -->')
body = "<!-- codex-pull-request-review-summary -->\n" + mark + "\n## Codex Review Summary\n"
print(json.dumps([{"user": {"login": who}, "body": body}], ensure_ascii=False))
PY
}

fails=0
run() {  # 이름 · 이슈댓글 JSON · 기대 종료코드 · [리뷰 JSON]
  printf '%s' "$2" > "$tmp/i.json"
  printf '%s' "${4:-[]}" > "$tmp/r.json"
  echo '[]' > "$tmp/rc.json"
  python3 "$tmp/attest.py" "$HEAD" "$BOT" "$HEAD_TIME" \
    "$tmp/r.json" "$tmp/rc.json" "$tmp/i.json" >"$tmp/log" 2>&1
  got=$?
  if [ "$got" -ne "$3" ]; then
    echo "🔴 $1 — 기대 exit=$3 인데 $got" >&2
    sed 's/^/     /' "$tmp/log" >&2
    fails=$((fails + 1))
  else
    echo "  ✅ $1"
  fi
}

echo "── 🔴 막아야 한다"
run "댓글이 아예 없다"          '[]'                              1
run "표식 없는 사람 댓글만"      '[{"user":{"login":"me"},"body":"고쳤습니다"}]' 1
run "🔴 **보는 중**(running)"    "$(cmt "$BOT" "$HEAD" running)"   1
run "🔴 **옛 커밋**의 completed" "$(cmt "$BOT" "$OLD" completed)"  1
run "남의 봇이 같은 표식을 남김"  "$(cmt 'someone-else[bot]' "$HEAD" completed)" 1
run "표식 JSON 이 깨졌다"        '[{"user":{"login":"chatgpt-codex-connector[bot]"},"body":"<!-- codex-security-review:v1 {깨짐} -->"}]' 1
run "댓글 배열이 아니다"          '{"message":"Not Found"}'         1

echo "── ✅ 통과해야 한다"
run "이 커밋의 completed"        "$(cmt "$BOT" "$HEAD" completed)" 0
run "로그인 대소문자가 다르다"    "$(cmt 'ChatGPT-Codex-Connector[bot]' "$HEAD" completed)" 0

echo "── 🔴 판정은 위임하지 않는다 (막으면 **안 되는** 것)"
# 코덱스는 걸린 게 없으면 리뷰도 댓글도 안 남기고 👍 만 단다 — 그래도 **통과해야** 한다.
run "지적 0건이어도 통과"        "$(cmt "$BOT" "$HEAD" completed)" 0

echo "── 🔵 **리뷰 객체 신호** (실측: 지적 0건이어도 온다 · 표식보다 빠르다)"
rvw() { printf '[{"user":{"login":"%s"},"commit_id":"%s","state":"COMMENTED"}]' "$1" "$2"; }
run "표식은 running 인데 리뷰 객체가 왔다" "$(cmt "$BOT" "$HEAD" running)" 0 "$(rvw "$BOT" "$HEAD")"
run "🔴 리뷰 객체가 **옛 커밋**이면 안 된다" '[]' 1 "$(rvw "$BOT" "$OLD")"
run "🔴 남의 리뷰 객체는 안 쳐준다"        '[]' 1 "$(rvw "someone" "$HEAD")"

echo "── 🔵 **완료 댓글 신호** (실측: 지적 0건이면 리뷰 객체가 **안 생긴다**)"
D1="Codex Review: Didn't find any major issues. Keep it up!"   # 실측 문구 그대로
D2="Security review completed. No security issues were found in this pull request."
run "완료 댓글이 head 뒤에 왔다"          "$(done_cmt "$BOT" 2026-09-01T05:13:51Z "$D1")" 0
run "보안 검토 완료 댓글도 쳐준다"         "$(done_cmt "$BOT" 2026-09-01T05:15:52Z "$D2")" 0
run "🔴 head **이전** 완료 댓글은 안 쳐준다" "$(done_cmt "$BOT" 2026-09-01T04:00:00Z "$D1")" 1
run "🔴 남이 같은 문구를 써도 안 쳐준다"     "$(done_cmt someone 2026-09-01T05:13:51Z "$D1")" 1

echo "── 못 찾았을 때 **단서를 찍는가** (이름·커밋이 틀렸을 때 한 번에 고치라고)"
printf '%s' "$(cmt "$BOT" "$OLD" completed)" > "$tmp/i.json"
echo '[]' > "$tmp/r.json"; echo '[]' > "$tmp/rc.json"
python3 "$tmp/attest.py" "$HEAD" "$BOT" "$HEAD_TIME" "$tmp/r.json" "$tmp/rc.json" "$tmp/i.json" >"$tmp/log" 2>&1 || true
for want in "${OLD:0:8}" "codex"; do
  if grep -qF "$want" "$tmp/log"; then
    echo "  ✅ 로그에 있다: $want"
  else
    echo "🔴 로그에 '$want' 가 없다 — 고칠 단서가 없다" >&2; cat "$tmp/log" >&2; fails=$((fails+1))
  fi
done

if [ "$fails" -ne 0 ]; then
  echo "🔴 $fails 건 실패" >&2
  exit 1
fi
echo "✅ 이 커밋에서 끝났는지만 막고, 리뷰의 판정으로는 안 막는다"
