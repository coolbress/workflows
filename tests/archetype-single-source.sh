#!/usr/bin/env bash
# 아키타입 목록이 **한 곳에서만 온다.** 네트워크는 안 탄다 — `gh` 를 목으로 바꾼다.
#
# 🔴 왜 필요했나 (2026-08-30 실측): `new-project.sh` 에 `cli|library|service|data-ml` 이
# **박혀 있었다.** 템플릿은 진작 `service` → `backend` 로 바꿨는데 여기만 안 따라왔다.
# 결과: **맞는 값(`backend`)이 거부되고**, 없는 값(`service`)은 **저장소를 만든 뒤에야**
# copier 가 거부해 trap 이 지웠다. fail-closed 는 성립했지만 왕복 한 번을 버렸다.
#
# **정본이 둘이 되면 갈린다.** 목록은 템플릿의 `copier.yml` 에서 읽어와야 한다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

# ① 목록이 스크립트에 박혀 있지 않다
if grep -qE '^\s*cli\|library\|[a-z-]+\|data-ml\)' "$root/new-project.sh"
then bad "🔴 아키타입 목록이 스크립트에 박혀 있다 — 템플릿과 갈린다"
else ok "목록이 박혀 있지 않다"; fi

# ② 템플릿에서 읽어온다
if grep -q "project-template/contents/copier.yml" "$root/new-project.sh"
then ok "템플릿의 copier.yml 에서 읽어온다"
else bad "🔴 정본에서 안 읽어온다"; fi

# ③ 못 읽으면 막지 않는다 — 여기가 판정자가 아니다. copier 가 거부하고 trap 이 지운다.
if grep -q "copier 가 판정한다" "$root/new-project.sh"
then ok "못 읽으면 넘긴다 (여기가 판정자가 아니다)"
else bad "못 읽을 때의 처리가 없다"; fi

# ④ 파싱이 실제로 도는가 — 목을 세워 확인한다
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT; mkdir -p "$work/bin"
cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
printf 'archetype:\n  type: str\n  choices:\n    CLI: cli\n    라이브러리: library\n    백엔드: backend\n    데이터: data-ml\nlicense:\n' | base64
MOCK
chmod +x "$work/bin/gh"
got="$(PATH="$work/bin:$PATH" bash -c '
  gh api x --jq .content | base64 -d \
    | sed -n "/^archetype:/,/^[a-z_]/p" \
    | sed -n "s/^    [^:]*: \([a-z][a-z0-9-]*\)$/\1/p"' | tr '\n' ' ')"
if [ "$got" = "cli library backend data-ml " ]
then ok "파싱이 네 값을 정확히 뽑는다"
else bad "파싱 결과가 다르다: '$got'"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
