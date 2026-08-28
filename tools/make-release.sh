#!/usr/bin/env bash
# 릴리스를 만든다 — **왜**는 사람이 쓰고 **무엇**은 GitHub 이 만든다.
#
#   사용법: tools/make-release.sh <태그> <노트파일>
#   예:     tools/make-release.sh v3.4.0 /tmp/why.md
#
# 왜 둘 다인가 (2026-08-28 실측, `standards` R5-31):
# `generate_release_notes` 를 v3.2.0 → v3.3.0 에 돌려봤더니 나온 것은 이게 전부다 —
#   ## What's Changed
#   * feat(ruleset): ci / diff-size 를 요구 검사로 만든다 by @coolbress in .../pull/26
#   **Full Changelog**: .../compare/v3.2.0...v3.3.0
# 손으로 쓴 같은 릴리스의 노트는 이렇게 적혀 있다 —
#   "빨간 X 가 보이는 것과 머지가 막히는 것은 다른 문장이다"
#   "`uses:` 로 이 저장소를 부르는 쪽은 핀을 올릴 이유가 없다 — v3.2.0 이면 충분하다"
# 🔴 **소비자가 뭘 해야 하는가는 커밋 로그에 없다.** 생성기는 우리 노트의 열등한 판이 아니라
# **다른 물건**이다 — 설명이 아니라 색인이다. 그래서 대체하지 않고 **겹쳐 쓴다.**
# `gh` 문서: *"Additional release notes can be prepended to the automatically generated notes."*
#
# ⚠️ 라벨을 안 쓰면 생성 노트는 한 덩어리다. 2026-08-28 실측: 머지된 PR 68건 중
# 라벨이 붙은 것 **0건**. `.github/release.yml` 의 분류는 **라벨로** 하므로 지금은 무의미하다.
# 색인으로는 그대로 쓸모 있다 — 분류를 원하면 라벨부터 붙여야 한다.
set -euo pipefail

tag="${1:?사용법: tools/make-release.sh <태그> <노트파일>}"
notes="${2:?노트파일이 필요하다 — '왜' 는 사람이 쓴다. 생성기는 '무엇' 만 안다}"

[ -f "$notes" ] || { echo "🔴 노트파일이 없다: $notes" >&2; exit 1; }
# 🔴 빈 파일을 받아주면 이 스크립트는 `--generate-notes` 의 별칭이 된다.
# 그러면 릴리스마다 '왜' 가 사라지고, 그게 정확히 이 스크립트가 막으려는 것이다.
[ -s "$notes" ] || { echo "🔴 노트파일이 비어 있다: $notes — 왜 이 릴리스를 내는지 한 줄이라도 써라" >&2; exit 1; }

if gh release view "$tag" >/dev/null 2>&1; then
  echo "🔴 릴리스 $tag 가 이미 있다. 고치려면 'gh release edit $tag' 를 써라" >&2
  exit 1
fi

# --verify-tag: 태그가 원격에 없으면 gh 는 **조용히 만들어 버린다.**
# 그러면 잘못 친 태그가 릴리스와 함께 박힌다. 여기서 멈추는 편이 낫다.
gh release create "$tag" --verify-tag --notes-file "$notes" --generate-notes

echo "완료 — $tag · 손으로 쓴 '왜' 위에 생성된 '무엇' 이 붙었다"
