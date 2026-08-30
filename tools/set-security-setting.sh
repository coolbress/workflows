#!/usr/bin/env bash
# 저장소의 **보안 설정**을 켜고 **켜졌는지 확인한다.** 사람이 돌린다 (관리자 권한 필요).
#
#   사용법: ./tools/set-security-setting.sh [--dry-run] <설정> <저장소> ...
#   설정:   non-provider-patterns · validity-checks
#
# 🔴 **왜 도구인가 — 확인 없이 치면 조용히 안 걸린다.**
# 실측(2026-08-30): `gh api -X PATCH repos/O/R -f "security_and_analysis[x][status]=enabled"` 는
# **200 을 주고 아무것도 안 바꿨다.** `-f` 는 폼 필드를 보내는데 이 엔드포인트는 **중첩 JSON** 을
# 받는다. 서버는 모르는 필드를 조용히 무시한다. 응답 본문에 `disabled` 가 그대로 있었는데
# 성공으로 읽었다. **그래서 이 스크립트는 쓰고 나서 다시 읽어 대조한다.**
#
# 🔒 A-1: 에이전트 자격증명으로는 403 이다. 래퍼로 돌린다:
#   ./tools/with-admin-token.sh ./tools/set-security-setting.sh non-provider-patterns coolbress/x ...
set -euo pipefail

dry=0
[ "${1:-}" = "--dry-run" ] && { dry=1; shift; }
setting="${1:?사용법: set-security-setting.sh [--dry-run] <설정> <저장소> ...}"; shift
[ $# -gt 0 ] || { echo "저장소를 하나 이상 적어라" >&2; exit 2; }

case "$setting" in
  non-provider-patterns) key=secret_scanning_non_provider_patterns ;;
  validity-checks)       key=secret_scanning_validity_checks ;;
  *) echo "모르는 설정: $setting (non-provider-patterns · validity-checks)" >&2; exit 2 ;;
esac

fail=0
for repo in "$@"; do
  before="$(gh api "repos/$repo" --jq ".security_and_analysis.$key.status // \"없음\"")"
  if [ "$dry" = 1 ]; then
    echo "── $repo: $key = $before  (--dry-run — 쓰지 않았다)"
    continue
  fi

  # 🔴 중첩 JSON 으로 보낸다. `-f a[b][c]=v` 는 폼 필드라 서버가 조용히 무시한다.
  jq -n --arg k "$key" '{security_and_analysis: {($k): {status: "enabled"}}}' \
    | gh api "repos/$repo" -X PATCH --input - >/dev/null

  after="$(gh api "repos/$repo" --jq ".security_and_analysis.$key.status // \"없음\"")"
  if [ "$after" = "enabled" ]; then
    echo "── $repo: $key  $before → $after  ✅"
  else
    echo "── $repo: $key  $before → $after  🔴 안 걸렸다" >&2
    fail=1
  fi
done

[ "$fail" = 0 ] || { echo "🔴 하나 이상이 안 걸렸다. 200 을 받아도 걸린 게 아니다." >&2; exit 1; }
