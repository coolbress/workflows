#!/usr/bin/env bash
# make-release.sh 의 **가드** 시험.
#
# 이 스크립트가 지켜야 하는 성질은 하나다: **'왜' 없이는 릴리스가 안 나간다.**
# 나머지(태그 검증·중복 방지)는 그 성질을 지키는 벽이다.
# 진짜 릴리스를 만들 수는 없으니 `gh` 를 목으로 바꾸고 **무엇이 불렸는지**로 판정한다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin"

cat > "$work/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
printf 'gh %s\n' "$*" >> "$GH_LOG"
case "$*" in
  "release view"*)   exit "${VIEW_RC:-1}" ;;   # 기본: 릴리스 없음
  "release create"*) exit 0 ;;
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
grep_log() { # <이름> <있어야(y|n)> <패턴>
  if grep -q -- "$3" "$GH_LOG" 2>/dev/null; then got=y; else got=n; fi
  if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "  PASS  $1"
  else fail=$((fail+1)); echo "  FAIL  $1 (로그에 '$3' 가 $got)"; fi
}

run() { export GH_LOG="$work/log.$RANDOM"; : > "$GH_LOG"; "$root/tools/make-release.sh" "$@" >/dev/null 2>&1; }

echo "── 노트파일 가드"
printf '## 왜\n실제 이유.\n' > "$work/why.md"
: > "$work/empty.md"

run v9.9.9 "$work/nonexistent.md"; check "없는 노트파일은 거부한다" no $?
run v9.9.9 "$work/empty.md";      check "빈 노트파일은 거부한다"   no $?
grep_log "빈 파일일 때 release create 를 안 부른다" n "release create"

echo "── 정상 경로"
run v9.9.9 "$work/why.md";        check "왜 가 있으면 만든다"      ok $?
grep_log "--notes-file 를 넘긴다"    y -- "--notes-file"
grep_log "--generate-notes 를 넘긴다" y -- "--generate-notes"
grep_log "--verify-tag 를 넘긴다"     y -- "--verify-tag"

echo "── 중복 가드"
export VIEW_RC=0   # 릴리스가 이미 있다
run v9.9.9 "$work/why.md";        check "이미 있는 릴리스는 거부한다" no $?
grep_log "중복일 때 release create 를 안 부른다" n "release create"
unset VIEW_RC

echo
echo "결과: $pass PASS · $fail FAIL"
[ "$fail" = 0 ]
