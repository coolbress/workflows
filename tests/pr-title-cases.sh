#!/usr/bin/env bash
# `ci / pr-title` 의 판정 규칙 시험.
#
# 🔴 규칙을 여기 옮겨 적지 않는다. **워크플로에서 뽑아 쓴다** —
# 옮겨 적으면 두 곳이 되고, 두 곳이 되면 갈린다. 그게 `standards` R5-30 정정을 부른 결함이다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wf="$root/.github/workflows/python-ci.yml"

# 워크플로에서 타입 목록과 정규식을 그대로 꺼낸다.
types="$(sed -nE "s/^[[:space:]]*types='([^']+)'.*/\1/p" "$wf" | head -1)"
[ -n "$types" ] || { echo "🔴 python-ci.yml 에서 types= 를 못 찾았다"; exit 1; }
re="^($types)(\([a-zA-Z0-9_.,/ -]+\))?!?: .+"

pass=0; fail=0
check() { # <기대(ok|no)> <제목>
  if printf '%s' "$2" | grep -qE "$re"; then got=ok; else got=no; fi
  if [ "$got" = "$1" ]; then pass=$((pass+1)); printf '  ✅ %-3s %s\n' "$1" "$2"
  else fail=$((fail+1)); printf '  🔴 %-3s %s  (판정 %s)\n' "$1" "$2" "$got"; fi
}

echo "ci / pr-title 판정 — 규칙은 python-ci.yml 에서 뽑았다"
echo "  타입: $types"
echo
echo "── 통과해야 하는 것"
check ok "feat: 새 기능을 넣는다"
check ok "fix(cli): 종료 코드를 고친다"
check ok "docs(research): 코퍼스 문서를 더한다"
check ok "docs(decision): 결정을 적는다"
check ok "refactor(layout): 파일을 옮긴다"
check ok "build(deps): 의존성을 올린다"
check ok "fix(security): 취약점을 막는다"
check ok "feat!: 호출부가 고쳐야 한다"
check ok "feat(api)!: 범위 변경"

echo "── 막아야 하는 것 — 접은 타입 (R5-30 정정)"
check no "research: 코퍼스 문서를 더한다"
check no "decide: 결정을 적는다"
check no "decision: 결정을 적는다"
check no "record: 기록한다"
check no "anchor: 앵커를 붙인다"
check no "audit: 감사한다"
check no "move: 파일을 옮긴다"

echo "── 막아야 하는 것 — 형식"
check no "제목만 있다"
check no "feat:"
check no "feat 새 기능"
check no "Feat: 대문자"
check no "feat(scope) 콜론이 없다"

echo
echo "결과: $pass PASS · $fail FAIL"
[ "$fail" = 0 ]
