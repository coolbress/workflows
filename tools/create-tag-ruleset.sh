#!/usr/bin/env bash
# 저장소에 **태그 룰셋**을 만든다. 사람이 돌린다 (관리자 권한 필요).
#
#   사용법: ./tools/create-tag-ruleset.sh [--dry-run] <저장소> ...
#
# 🔴 **왜 태그인가 — 태그가 핀 주석의 근거다.**
# 소비자는 `uses: coolbress/workflows/...@<SHA> # v3.8.0` 로 부른다. 실행은 SHA 로 도니
# 태그를 옮겨도 **돌아가는 코드는 안 바뀐다.** 바뀌는 것은 **그 주석이 참인가**다 —
# `v3.8.0` 이 다른 커밋을 가리키게 되면 릴리스 노트·핀 주석·`make-release.sh` 가 전부 거짓이 된다.
# 그리고 릴리스가 통째로 사라지는 것(태그 삭제)은 되돌리기 어렵다.
#
# 막는 것은 둘이다: **삭제**와 **이동**(non-fast-forward). **생성은 막지 않는다** —
# 막으면 릴리스를 못 낸다.
#
# ⚠️ `upgrade-ruleset.sh`·`add-ruleset-rule.sh` 는 **기존 브랜치 룰셋을 고친다.**
# 이건 **새 룰셋을 만든다** — 대상(target)이 달라 같은 룰셋에 못 얹는다.
#
# 🔒 A-1: 에이전트 자격증명으로는 403 이다. 래퍼로 돌린다.
set -euo pipefail

dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
[ $# -gt 0 ] || { echo "사용법: create-tag-ruleset.sh [--dry-run] <저장소> ..." >&2; exit 2; }

NAME="tags — 삭제·이동 금지"

body() {
  jq -n --arg name "$NAME" '{
    name: $name,
    target: "tag",
    enforcement: "active",
    bypass_actors: [],                      # 🔴 0 이다. 소유자도 못 넘는다 — 브랜치 룰셋과 같은 규율.
    conditions: { ref_name: { include: ["~ALL"], exclude: [] } },
    rules: [ { type: "deletion" }, { type: "non_fast_forward" } ]
  }'
}

fail=0
for repo in "$@"; do
  # 🔴 **이미 있으면 안 만든다.** 두 번 만들면 같은 이름의 룰셋이 둘이 되고
  # 어느 쪽이 실제로 거는지 사람이 헷갈린다.
  if gh api "repos/$repo/rulesets" --jq '.[] | select(.target == "tag") | .id' | grep -q .; then
    echo "── $repo: 태그 룰셋이 이미 있다 — 건너뛴다"
    continue
  fi

  if [ "$dry" = 1 ]; then
    echo "── $repo: 태그 룰셋을 만든다 (deletion · non_fast_forward · bypass 0)  (--dry-run — 쓰지 않았다)"
    continue
  fi

  body | gh api "repos/$repo/rulesets" -X POST --input - >/dev/null

  # 🔴 **쓰고 나서 대조한다.** 200 을 받아도 걸린 게 아니다 — 실측으로 겪었다.
  got="$(gh api "repos/$repo/rulesets" --jq '[.[] | select(.target == "tag")] | length')"
  if [ "$got" = "1" ]; then
    echo "── $repo: 태그 룰셋 ✅"
  else
    echo "── $repo: 태그 룰셋이 $got 개다 🔴" >&2
    fail=1
  fi
done

[ "$fail" = 0 ] || { echo "🔴 하나 이상이 안 걸렸다." >&2; exit 1; }
