#!/usr/bin/env bash
# 기존 저장소의 룰셋에 **요구 검사를 더한다.** 사람이 돌린다 (관리자 권한 필요).
#
#   사용법: ./tools/upgrade-ruleset.sh [--dry-run] <저장소> <컨텍스트:앱ID> ...
#   예:     ./tools/upgrade-ruleset.sh --dry-run coolbress/standards 'CodeQL:57789'
#
# 왜 도구인가: `ruleset.json` 은 **새 저장소**에만 적용된다. 기존 저장소는 API 로
# 고쳐야 하는데, 손으로 JSON 을 붙이면 **다른 필드를 실수로 지운다** —
# 그러면 벽이 조용히 약해진다. 이 스크립트는 **더하기만** 한다.
#
# 🔒 A-1: 에이전트 자격증명으로는 403 이다. 사람이 이렇게 돌린다:
#   env -u GH_TOKEN -u GITHUB_TOKEN ./tools/upgrade-ruleset.sh <저장소> ...
set -euo pipefail

dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
repo="${1:?사용법: upgrade-ruleset.sh [--dry-run] <저장소> <컨텍스트:앱ID> ...}"; shift
[ $# -gt 0 ] || { echo "더할 검사를 하나 이상 적어라 (예: 'CodeQL:57789')" >&2; exit 2; }

id="$(gh api "repos/$repo/rulesets" --jq '.[0].id')"
[ -n "$id" ] || { echo "룰셋이 없다: $repo" >&2; exit 1; }
cur="$(gh api "repos/$repo/rulesets/$id")"

add_json="$(printf '%s\n' "$@" | jq -R 'split(":") | {context: .[0], integration_id: (.[1]|tonumber)}' | jq -s .)"

new="$(printf '%s' "$cur" | jq --argjson add "$add_json" '
  # PUT 이 받는 필드만 남긴다. 서버가 붙여주는 것(id·created_at·_links…)을 되돌려 보내면 거부된다.
  {name, target, enforcement, bypass_actors, conditions, rules}
  | .rules |= map(
      if .type == "required_status_checks" then
        # 🔴 더하기만 한다. 이미 있는 것은 건드리지 않는다 (unique_by 로 중복만 제거).
        .parameters.required_status_checks =
          ((.parameters.required_status_checks + $add) | unique_by(.context))
      else . end)
')"

echo "── $repo (ruleset $id)"
printf '%s' "$new" | jq -r '
  .rules[] | select(.type=="required_status_checks")
  | .parameters.required_status_checks[] | "   요구: \(.context)  (app \(.integration_id))"'
printf '%s' "$new" | jq -r '"   우회자: \(.bypass_actors|length)건 · 강제: \(.enforcement)"'

if [ "$dry" = 1 ]; then echo "   (--dry-run — 쓰지 않았다)"; exit 0; fi
printf '%s' "$new" | gh api "repos/$repo/rulesets/$id" -X PUT --input - >/dev/null
echo "   ✅ 적용됨"
