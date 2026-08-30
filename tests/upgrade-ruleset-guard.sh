#!/usr/bin/env bash
# `upgrade-ruleset.sh` 의 **이름 가드** 시험. 네트워크는 안 탄다 — `gh` 를 목으로 바꾼다.
#
# 지켜야 하는 성질은 하나다: **보고된 적 없는 이름은 요구하지 않는다.**
# 왜 이게 벽이어야 하나: 요구한 검사 이름이 영원히 안 오면 그 저장소는 **아무것도 못 머지한다.**
# 실측 사고(2026-08-30): `coolbress/workflows` 는 자기 CI 를 `canary` job 으로 불러서
# 검사 이름이 `canary / deps` 인데, 다른 두 저장소와 같은 `ci / deps` 를 쓸 뻔했다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

# 목: 이 저장소는 `canary / deps` 만 낸다. `ci / deps` 는 존재하지 않는다.
cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
case "$*" in
  *"/rulesets/1"*)      echo '{"name":"r","target":"branch","enforcement":"active","bypass_actors":[],"conditions":{},"rules":[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"canary / test","integration_id":15368}]}}]}' ;;
  *"/rulesets"*)        echo 1 ;;   # `--jq '.[0].id'` 를 거친 뒤의 값
  *"/commits?per_page"*) echo "sha1" ;;
  *"/pulls?state"*)      echo "sha1" ;;
  *"check-runs"*)        printf 'canary / deps\ncanary / test\n' ;;
  *"/status"*)           printf 'CodeQL\n' ;;
esac
exit 0
MOCK
chmod +x "$work/bin/gh"
export PATH="$work/bin:$PATH"

pass=0; fail=0
check() { # <이름> <기대(ok|no)> <실제 종료코드>
  if { [ "$2" = ok ] && [ "$3" = 0 ]; } || { [ "$2" = no ] && [ "$3" != 0 ]; }
  then pass=$((pass+1)); echo "  PASS  $1"
  else fail=$((fail+1)); echo "  FAIL  $1 (종료코드 $3, 기대 $2)"; fi
}

run() { "$root/tools/upgrade-ruleset.sh" "$@" >"$work/out" 2>&1; }

run --dry-run r/r 'ci / deps:15368'
check "안 온 이름은 막는다" no $?
if grep -q "canary / deps" "$work/out"; then
  pass=$((pass+1)); echo "  PASS  막을 때 맞는 이름을 보여준다"
else
  fail=$((fail+1)); echo "  FAIL  실제로 온 이름을 안 보여준다 — 사람이 고칠 수 없다"
fi

run --dry-run r/r 'canary / deps:15368'
check "온 이름은 통과한다" ok $?

run --dry-run r/r 'CodeQL:57789'
check "커밋 상태(PR 에만 뜨는 것)도 본다" ok $?

run --dry-run --force r/r 'ci / deps:15368'
check "--force 는 확인을 넘긴다" ok $?

run --dry-run r/r 'canary / deps:15368' 'ci / deps:15368'
check "여럿 중 하나만 틀려도 막는다" no $?

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
