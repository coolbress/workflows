#!/usr/bin/env bash
# 세션이 열릴 때 **정본이 어디 있는지**를 컨텍스트에 밀어 넣는다. 딱 그것만.
#
# 🔴 왜 훅인가 — 실측(divcal 완주 회고): 차가운 세션이 `AGENTS.md` 가 **명시한** 저장소를
#   **하나도 열지 않았다.** 산문 속 포인터는 안 따라간다. 훅의 stdout 은 무시할 수 없다.
#
# 🔴 **프로젝트 상태는 여기서 안 읽는다.** 열린 이슈·검사 명령은 **프로젝트 쪽 훅**의 일이다
#   (`project-template` 의 `.claude/settings.json`). 둘이 겹치면 같은 것을 두 번 찍는다.
#   여기는 **운영자 관례**, 저기는 **프로젝트 관례** — 축이 다르다.
#
# 🔴 **네트워크를 안 탄다.** 세션 시작이 굼뜨면 그것만으로 값을 잃는다.
# 🔴 **fail-open.** 무엇이 실패해도 세션은 그대로 간다.
set -u

cat <<'TXT'
## 정본이 어디 있나 (SessionStart)

- **왜** 이 규칙이 있나 → `coolbress/standards` (`direction/` · `corpus/` · `audit/`)
- **벽과 생성기** → `coolbress/workflows` · **새 프로젝트가 받는 것** → `coolbress/project-template`
- 자세한 것은 `where-is-the-truth` 스킬

**바깥을 열기 전에 발밑을 본다** — 가변 상태의 정본은 파일이 아니라 `gh issue list` 다.

## 무기고 — 🔴 **기억에서 답하기 전에 여기를 본다**

도구는 다 있는데 **쓰라는 말이 없어서** 안 쓰는 것이 실패 형태다.

- 계획·명세·제약 → `mattpocock-skills` · 프론트엔드 anti-slop → `taste-skill`(랜딩·리디자인만)
- 최근 반응·새 후보 → `last30days` 🔴 **발견용이지 판정용이 아니다**

⚠️ **고르는 것은 너다** — 있다는 사실이지 쓰라는 명령이 아니다.
TXT

exit 0
