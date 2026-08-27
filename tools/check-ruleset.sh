#!/usr/bin/env bash
# ruleset.json 의 불변식 검사.
#
# 이 파일은 설정이 아니라 **실행 코드**다 — 새 저장소의 벽이 여기서 나온다.
# 한 줄이 조용히 뒤집히면(우회자 추가·검사 삭제·머지 방법 확대) 만들어지는
# 모든 저장소의 벽이 같이 뒤집힌다. 그래서 사람 눈이 아니라 검사로 잡는다.
#
# 검사하는 것은 "문법이 맞나"(그건 jq empty)가 아니라
# **"벽이 벽인가"** 다. 기대값은 감사에서 확정한 값이다.
set -euo pipefail

f="${1:-ruleset.json}"
fail=0

jq empty "$f" 2>/dev/null || { echo "🔴 $f 는 올바른 JSON 이 아니다"; exit 1; }

chk() { # 설명 · jq 식 · 기대값
  local got
  got="$(jq -c "$2" "$f")"
  if [ "$got" = "$3" ]; then
    printf '  ✅ %s\n' "$1"
  else
    printf '  🔴 %s\n     기대: %s\n     실제: %s\n' "$1" "$3" "$got"
    fail=1
  fi
}

echo "룰셋 불변식 — $f"

# ── 벽의 정의 ────────────────────────────────────────────────
chk '우회자가 없다 (에이전트도 사람도 빠져나갈 구멍 없음)' \
    '.bypass_actors' '[]'
chk '경고가 아니라 강제다' \
    '.enforcement' '"active"'
chk '대상은 기본 브랜치다' \
    '.conditions.ref_name.include' '["~DEFAULT_BRANCH"]'
chk '기본 브랜치 삭제 금지' \
    '[.rules[].type]|index("deletion")!=null' 'true'
chk '강제 푸시 금지' \
    '[.rules[].type]|index("non_fast_forward")!=null' 'true'
chk 'PR 을 거치지 않고는 못 들어간다' \
    '[.rules[].type]|index("pull_request")!=null' 'true'

# ── 머지 정합 ────────────────────────────────────────────────
# 서버 설정(allow_merge_commit=false 등)과 룰셋이 어긋나면
# "머지 버튼이 없는" 저장소가 된다. new-project.sh 가 둘을 같이 건다.
chk '머지는 squash 뿐' \
    '.rules[]|select(.type=="pull_request").parameters.allowed_merge_methods' '["squash"]'

# ── 기계 판정 ────────────────────────────────────────────────
# 이름은 {호출잡}/{피호출잡} 이다. 호출부 잡 이름 `ci` + 재사용 워크플로의 4잡.
# 여기와 project-template/.github/workflows/ci.yml 과 python-ci.yml 이
# 셋 다 맞아야 성립한다 — 하나만 이름이 바뀌면 저장소가 머지 불가로 잠긴다.
chk '요구하는 검사는 lint·typecheck·test·build·secrets·CodeQL' \
    '[.rules[]|select(.type=="required_status_checks").parameters.required_status_checks[].context]' \
    '["ci / lint","ci / typecheck","ci / test","ci / build","ci / secrets","CodeQL"]'
# 이름만 요구하면 아무나 그 이름으로 초록을 올릴 수 있다. 출처를 고정한다.
# 🔴 출처가 **둘**이다 — `ci / *` 는 GitHub Actions(15368), `CodeQL` 은
# code scanning(57789 · github-advanced-security). 하나로 뭉뚱그리면 안 된다.
chk 'Actions 검사의 출처는 GitHub Actions App(15368)' \
    '[.rules[]|select(.type=="required_status_checks").parameters.required_status_checks[]|select(.context|startswith("ci / ")).integration_id]|unique' \
    '[15368]'
chk 'CodeQL 의 출처는 code scanning App(57789)' \
    '[.rules[]|select(.type=="required_status_checks").parameters.required_status_checks[]|select(.context=="CodeQL").integration_id]|unique' \
    '[57789]'
# ⚠️ 언어별 잡(`Analyze (python)` 등)은 **요구하지 않는다** — 저장소마다 언어가 달라서
# 없는 언어를 요구하면 그 이름이 영원히 보고되지 않아 저장소가 잠긴다. 집계 검사 하나만 쓴다.
chk '언어별 Analyze 잡은 요구하지 않는다' \
    '[.rules[]|select(.type=="required_status_checks").parameters.required_status_checks[].context|select(startswith("Analyze"))]|length' \
    '0'
chk '낡은 main 위의 초록은 인정하지 않는다 (strict)' \
    '.rules[]|select(.type=="required_status_checks").parameters.strict_required_status_checks_policy' 'true'

[ "$fail" = 0 ] && { echo "RESULT PASS"; exit 0; }
echo "RESULT FAIL"; exit 1
