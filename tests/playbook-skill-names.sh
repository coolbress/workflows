#!/usr/bin/env bash
# 플레이북·커맨드가 가리키는 스킬 이름이 **실제로 있는가.**
#
# 🔴 왜 생겼나 (2026-09-02): `mattpocock-skills` 는 우리 플러그인의 의존성이고 **공식 마켓이 판을 올린다.**
# Matt 는 이름을 바꾼다 — `to-prd` → `to-spec` · `to-issues` → `to-tickets` · `writing-great-skills` → `writing-for-agents`.
# 판이 올라가서 스킬 하나가 사라지면 **플레이북이 없는 커맨드를 가리키는데 아무것도 안 빨개진다.**
# 그 침묵을 여기서 빨강으로 바꾼다. 오늘 쓴 문서의 오타도 같은 검사에 걸린다.
#
# 대조 대상(스킬 집합)은 셋이다:
#   ① mattpocock-skills — 로컬 플러그인 캐시가 있으면 그것, 없으면(CI) **공식 마켓 항목의 SHA** 로 shallow clone
#   ② 우리 플러그인의 커맨드·스킬
#   ③ Claude Code 내장 커맨드 + 스킬이 아닌 하이픈 이름(라벨 · 매니페스트 키 · 플러그인 이름) — 아래 목록
#
# 🔴 못 읽으면 통과가 아니다 — 캐시도 clone 도 없으면 실패한다.
# 🔴 검사가 헛돌지 않게 둘을 더 본다 — 참조를 실제로 몇 개 봤나 · 가짜 이름을 실제로 잡나.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  PASS  $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
names="$work/names"
: > "$names"

# ── ① mattpocock-skills 의 스킬 이름 (SKILL.md frontmatter 의 name:)
matt_root=""
if [ "${PLAYBOOK_SKILLS_SOURCE:-auto}" != clone ]; then
  matt_root="$(find "$HOME/.claude/plugins/cache/claude-plugins-official/mattpocock-skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)"
fi
if [ -n "$matt_root" ] && [ -d "$matt_root/skills" ]; then
  echo "  (스킬 집합: 로컬 캐시 $(basename "$matt_root"))"
else
  sha="${MATT_SKILLS_SHA:-}"
  if [ -z "$sha" ]; then
    sha="$(curl -fsSL https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json 2>/dev/null \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(p["source"]["sha"] for p in d["plugins"] if p["name"]=="mattpocock-skills"))' 2>/dev/null || true)"
  fi
  if [ -z "$sha" ]; then
    bad "공식 마켓의 mattpocock-skills 핀을 못 읽었다 — 못 읽으면 통과가 아니다"
    echo "── $pass 통과 · $fail 실패"; exit 1
  fi
  matt_root="$work/matt"
  if ! { git init -q "$matt_root" \
      && git -C "$matt_root" fetch -q --depth 1 https://github.com/mattpocock/skills.git "$sha" \
      && git -C "$matt_root" checkout -q FETCH_HEAD; }; then
    bad "mattpocock/skills 를 ${sha:0:7} 로 못 받았다 — 못 읽으면 통과가 아니다"
    echo "── $pass 통과 · $fail 실패"; exit 1
  fi
  echo "  (스킬 집합: 공식 마켓 핀 ${sha:0:7} 로 clone)"
fi
# shellcheck disable=SC2016  # awk 프로그램 — 셸 확장이 아니다
find "$matt_root/skills" -name SKILL.md -print0 \
  | xargs -0 -n1 awk '/^name:/{print $2; exit}' >> "$names"

# ── ② 우리 플러그인의 커맨드·스킬
for f in "$root"/plugins/standards/commands/*.md; do basename "$f" .md >> "$names"; done
for d in "$root"/plugins/standards/skills/*/; do basename "$d" >> "$names"; done

# ── ③ 내장 커맨드 · 스킬이 아닌 하이픈 이름 (여기만 손으로 관리한다 — 늘리면 이유를 적어라)
printf '%s\n' \
  clear compact plugin help doctor context \
  needs-triage needs-info ready-for-agent ready-for-human wontfix needs-simpler \
  mattpocock-skills coolbress-standards taste-skill \
  allowed-tools disallowed-tools disable-model-invocation user-invocable \
  >> "$names"

n_names="$(grep -c . "$names")"
if [ "$n_names" -ge 40 ]; then ok "스킬 집합 ${n_names}개"; else bad "스킬 집합이 ${n_names}개뿐이다 — 캐시나 clone 이 비었다"; fi

# ── 문서에서 참조 뽑기: 백틱 안의 `/name` 또는 `name`. 하이픈이 있거나 슬래시로 시작하는 것만 스킬 참조로 본다.
#    (`main`·`gh` 같은 한 단어는 스킬이 아니므로 안 본다. 점·공백·콜론이 섞인 것은 파일·잡·라벨 접두라 정규식이 거른다.)
refs_in() {  # <files…> → "file:이름" 줄들 (중복 제거)
  # shellcheck disable=SC2016  # 백틱은 마크다운 인용 부호다 — 셸 확장이 아니다
  grep -oHE '`/?[a-z][a-z0-9-]*`' "$@" 2>/dev/null \
    | sed -E 's/`//g' \
    | awk -F: '{ f=$1; t=$2; sub(/^\//,"",t); if (index($2,"/")==1 || index(t,"-")>0) print f ":" t }' \
    | sort -u
}
missing_in() {  # <files…> → 스킬 집합에 없는 참조 줄들
  refs_in "$@" | while IFS=: read -r f t; do
    grep -qxF "$t" "$names" || echo "$f:$t"
  done
}

docs=( "$root"/plugins/standards/skills/playbook/*.md "$root"/plugins/standards/commands/*.md )

n_refs="$(refs_in "${docs[@]}" | wc -l | tr -d ' ')"
if [ "$n_refs" -ge 20 ]; then ok "참조 ${n_refs}개를 실제로 봤다"; else bad "참조가 ${n_refs}개뿐이다 — 검사가 헛돈다"; fi

missing="$(missing_in "${docs[@]}")"
if [ -z "$missing" ]; then
  ok "플레이북·커맨드가 가리키는 이름이 전부 있다"
else
  bad "없는 스킬을 가리킨다 — Matt 가 이름을 바꿨거나 오타다:"
  printf '%s\n' "$missing" | sed 's/^/          /'
fi

# ── 음성: 가짜 이름을 실제로 잡나. 안 잡으면 위 PASS 는 장식이다.
fake="$work/fake.md"
# shellcheck disable=SC2016  # 백틱은 마크다운 인용 부호다
printf 'Use `/to-prd` then `to-issues`, and `/grill-with-docs` is real.\n' > "$fake"
caught="$(missing_in "$fake" | wc -l | tr -d ' ')"
if [ "$caught" = 2 ]; then ok "가짜 이름 둘을 잡고 진짜 하나는 통과시킨다"; else bad "음성 시험 실패 — 가짜 이름을 ${caught}개 잡았다 (2 여야 한다)"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
