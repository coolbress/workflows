#!/usr/bin/env bash
# 기존 룰셋에 **규칙 종류를 더한다.** 사람이 돌린다 (관리자 권한 필요).
#
#   사용법: ./tools/add-ruleset-rule.sh [--dry-run] <저장소> <프리셋> ...
#   프리셋: linear-history · code-scanning · signed-commits
#
# 왜 도구인가: `upgrade-ruleset.sh` 는 **요구 검사**만 더한다. 규칙 *종류* 를 더하려면
# JSON 을 만져야 하는데, 손으로 붙이면 **다른 필드를 실수로 지운다** — 그러면 벽이
# 조용히 약해진다. 이 스크립트는 **더하기만** 하고, 이미 있는 규칙은 건드리지 않는다.
#
# 🔒 A-1: 에이전트 자격증명으로는 403 이다. 래퍼로 돌린다:
#   ./tools/with-admin-token.sh ./tools/add-ruleset-rule.sh <저장소> <프리셋>
set -euo pipefail

dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
repo="${1:?사용법: add-ruleset-rule.sh [--dry-run] <저장소> <프리셋> ...}"; shift
[ $# -gt 0 ] || { echo "프리셋을 하나 이상 적어라 (linear-history · code-scanning · signed-commits)" >&2; exit 2; }

# 프리셋 → 규칙 JSON. 여기 없는 것은 안 받는다 — 자유 JSON 을 받으면 이 도구의 존재 이유가 사라진다.
rule_json() {
  case "$1" in
    linear-history)
      echo '{"type":"required_linear_history"}' ;;
    code-scanning)
      # 🔴 `CodeQL` **검사가 돌았나** 와 **경보가 남았나** 는 다른 문장이다.
      # 요구 검사는 앞을 보고, 이 규칙은 뒤를 본다.
      echo '{"type":"code_scanning","parameters":{"code_scanning_tools":[{"tool":"CodeQL","security_alerts_threshold":"high_or_higher","alerts_threshold":"errors"}]}}' ;;
    signed-commits)
      echo '{"type":"required_signatures"}' ;;
    *) echo "모르는 프리셋: $1" >&2; return 1 ;;
  esac
}

# ⚠️ 되돌리기 어려운 것은 **먼저 말한다.**
for p in "$@"; do
  if [ "$p" = "signed-commits" ]; then
    echo "🔴 signed-commits 는 **서명 안 된 커밋을 전부 거부한다.**" >&2
    echo "   에이전트는 로컬 git 으로 푸시하고 그 커밋은 서명돼 있지 않다 —" >&2
    echo "   켜는 순간 에이전트가 이 저장소에 아무것도 못 넣는다." >&2
    echo "   그리고 우리가 인용하는 SLSA Source L2 는 서명을 요구하지 않는다(FFA-006)." >&2
    printf '   그래도 켜려면 yes 를 쳐라: ' >&2
    IFS= read -r ans < /dev/tty
    [ "$ans" = "yes" ] || { echo "   멈춘다." >&2; exit 1; }
  fi
done

id="$(gh api "repos/$repo/rulesets" --jq '.[0].id')"
[ -n "$id" ] || { echo "룰셋이 없다: $repo" >&2; exit 1; }
cur="$(gh api "repos/$repo/rulesets/$id")"

add="["
for p in "$@"; do
  j="$(rule_json "$p")"
  [ "$add" = "[" ] || add="$add,"
  add="$add$j"
done
add="$add]"

new="$(printf '%s' "$cur" | jq --argjson add "$add" '
  # PUT 이 받는 필드만 남긴다. 서버가 붙여주는 것(id·created_at·_links…)은 거부된다.
  {name, target, enforcement, bypass_actors, conditions, rules}
  # 🔴 **더하기만 한다.** 이미 있는 종류는 기존 것을 남긴다(unique_by 가 앞을 고른다).
  | .rules = ((.rules + $add) | unique_by(.type))
')"

echo "── $repo (ruleset $id)"
printf '%s' "$new" | jq -r '"   규칙: " + ([.rules[].type] | sort | join(" "))'
printf '%s' "$new" | jq -r '"   우회자: \(.bypass_actors|length)건 · 강제: \(.enforcement)"'

if [ "$dry" = 1 ]; then echo "   (--dry-run — 쓰지 않았다)"; exit 0; fi
printf '%s' "$new" | gh api "repos/$repo/rulesets/$id" -X PUT --input - >/dev/null
echo "   ✅ 적용됨"
