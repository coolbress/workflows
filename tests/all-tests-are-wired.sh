#!/usr/bin/env bash
# **모든 `tests/*.sh` 가 CI 에서 실제로 도는가.**
#
# 🔴 왜 필요했나 (2026-08-30 실측): `security-setting.sh` 를 만들고 CI 에 붙이는 단계가
# `&&` 사슬이 끊기면서 **실행되지 않았다.** 시험 파일은 커밋됐고 **CI 는 초록이었다** —
# 그 시험이 한 번도 안 돌았다는 걸 아무도 몰랐다.
#
# **시험이 있는 것과 도는 것은 다른 문장이다.** `presence ≠ adequacy` 의 시험판이다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ci="$root/.github/workflows/ci.yml"
self="$(basename "${BASH_SOURCE[0]}")"

missing=""
for f in "$root"/tests/*.sh; do
  name="$(basename "$f")"
  grep -q "tests/$name" "$ci" || missing="$missing  $name"$'\n'
done

if [ -n "$missing" ]; then
  echo "🔴 CI 에 배선되지 않은 시험이 있다 — 이 파일들은 **한 번도 안 돈다**:" >&2
  printf '%s' "$missing" >&2
  echo "   .github/workflows/ci.yml 에 스텝을 추가해라." >&2
  exit 1
fi

n="$(find "$root/tests" -maxdepth 1 -name '*.sh' | wc -l | tr -d ' ')"
echo "  PASS  시험 ${n}개가 전부 CI 에 배선돼 있다 (자기 자신 $self 포함)"
