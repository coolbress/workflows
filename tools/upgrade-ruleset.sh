#!/usr/bin/env bash
# 기존 저장소의 룰셋에 **요구 검사를 더한다.** 사람이 돌린다 (관리자 권한 필요).
#
#   사용법: ./tools/upgrade-ruleset.sh [--dry-run] [--force] <저장소> <컨텍스트:앱ID> ...
#   예:     ./tools/upgrade-ruleset.sh --dry-run coolbress/standards 'CodeQL:57789'
#
# 🔴 **오지 않을 이름을 요구하면 저장소가 머지 불가가 된다.** 그래서 쓰기 전에
# 그 이름이 **실제로 보고된 적 있는지** 확인하고, 없으면 멈춘다(fail-closed).
# 실측 사고: `coolbress/workflows` 는 자기 CI 를 `canary` 라는 job 이름으로 불러서
# 검사 이름이 `ci / deps` 가 아니라 **`canary / deps`** 다. 다른 두 저장소와 같은
# 명령을 그대로 쓸 뻔했다 — 그러면 그 저장소는 아무것도 못 머지한다.
# 아직 안 돌아본 새 검사를 미리 걸어야 하면 `--force`.
#
# 왜 도구인가: `ruleset.json` 은 **새 저장소**에만 적용된다. 기존 저장소는 API 로
# 고쳐야 하는데, 손으로 JSON 을 붙이면 **다른 필드를 실수로 지운다** —
# 그러면 벽이 조용히 약해진다. 이 스크립트는 **더하기만** 한다.
#
# 🔒 A-1: 에이전트 자격증명으로는 403 이다. 관리자 열쇠는 이 컴퓨터에 저장돼 있지 않으므로
# 사람이 토큰을 **물어보는 래퍼**로 돌린다 (토큰이 명령줄·히스토리에 안 남는다):
#   ./tools/with-admin-token.sh ./tools/upgrade-ruleset.sh <저장소> ...
set -euo pipefail

dry=0; force=0
while :; do
  case "${1:-}" in
    --dry-run) dry=1; shift ;;
    --force)   force=1; shift ;;
    *) break ;;
  esac
done
repo="${1:?사용법: upgrade-ruleset.sh [--dry-run] <저장소> <컨텍스트:앱ID> ...}"; shift
[ $# -gt 0 ] || { echo "더할 검사를 하나 이상 적어라 (예: 'CodeQL:57789')" >&2; exit 2; }

id="$(gh api "repos/$repo/rulesets" --jq '.[0].id')"
[ -n "$id" ] || { echo "룰셋이 없다: $repo" >&2; exit 1; }
cur="$(gh api "repos/$repo/rulesets/$id")"

# ── 🔴 fail-closed: 요구하려는 이름이 **실제로 보고된 적 있나**
# 기본 브랜치에는 안 뜨고 PR 에만 뜨는 검사가 있다(`CodeQL` 이 그렇다). 그래서 둘 다 본다.
seen="$( {
  gh api "repos/$repo/commits?per_page=3" --jq '.[].sha' 2>/dev/null
  gh api "repos/$repo/pulls?state=all&per_page=5" --jq '.[].head.sha' 2>/dev/null
} | sort -u | while read -r sha; do
  [ -n "$sha" ] || continue
  gh api "repos/$repo/commits/$sha/check-runs?per_page=100" --jq '.check_runs[].name' 2>/dev/null
  gh api "repos/$repo/commits/$sha/status" --jq '.statuses[].context' 2>/dev/null
done | sort -u )"

if [ -z "$seen" ]; then
  echo "🔴 검사 이름을 하나도 못 읽었다 — 요구할 이름이 맞는지 확인할 수 없다." >&2
  echo "   확인 없이 걸면 저장소가 머지 불가가 된다. 강행하려면 --force." >&2
  [ "$force" = 1 ] || exit 1
fi

unseen=""
for spec in "$@"; do
  ctx="${spec%%:*}"
  printf '%s\n' "$seen" | grep -qxF "$ctx" || unseen="$unseen$ctx"$'\n'
done

if [ -n "$unseen" ]; then
  echo "🔴 이 이름들은 이 저장소에서 **보고된 적이 없다**:" >&2
  printf '%s' "$unseen" | sed 's/^/     /' >&2
  echo "   실제로 온 이름은 이것들이다:" >&2
  printf '%s\n' "$seen" | sed 's/^/     /' >&2
  echo "   요구한 이름이 안 오면 그 저장소는 아무것도 못 머지한다." >&2
  echo "   이름을 고치거나, 아직 안 돌아본 새 검사라면 --force." >&2
  [ "$force" = 1 ] || exit 1
  echo "   ⚠️ --force — 확인 없이 건다." >&2
fi

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
