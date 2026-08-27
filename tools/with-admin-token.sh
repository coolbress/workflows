#!/usr/bin/env bash
# 관리자 토큰을 **묻고** 명령을 실행한다. 토큰은 명령줄에도 히스토리에도 안 남는다.
#
#   사용법: ./tools/with-admin-token.sh <명령> [인자...]
#   예:     ./tools/with-admin-token.sh ./new-project.sh myapp
#           ./tools/with-admin-token.sh ./tools/upgrade-ruleset.sh coolbress/x 'CodeQL:57789'
#
# 🔴 왜 이게 필요한가: 이전 안내는 `GH_TOKEN='<붙여넣기>' ./new-project.sh` 였다.
# 그러면 **토큰이 `~/.zsh_history` 에 그대로 저장된다** — `histignorespace` 가 켜져 있어도
# 앞에 공백을 안 붙이면 남는다. 즉 *"파일에도 안 남는다"* 는 주장이 사실이 아니었다.
# 여기서는 입력을 **읽어서 환경으로만** 넘기므로 명령줄에 나타나지 않는다.
#
# 관리자 토큰: classic `repo`·`workflow`·`delete_repo`·`security_events` · 짧은 만료.
# `delete_repo` 가 있어야 실패 시 저장소를 지우는 fail-closed 가 성립한다.
set -euo pipefail

[ $# -gt 0 ] || { echo "사용법: with-admin-token.sh <명령> [인자...]" >&2; exit 2; }

printf '관리자 토큰 (입력은 화면에 안 보인다): ' >&2
IFS= read -rs GH_TOKEN
printf '\n' >&2
[ -n "$GH_TOKEN" ] || { echo "🔴 빈 토큰. 멈춘다." >&2; exit 2; }
export GH_TOKEN

# 에이전트용 제한 토큰이 섞이지 않게 한다 — gh 는 GH_TOKEN 을 먼저 보지만 명시적으로 지운다.
unset GITHUB_TOKEN

# exec 로 넘긴다: 이 셸이 남아 토큰을 들고 있지 않는다.
exec "$@"
