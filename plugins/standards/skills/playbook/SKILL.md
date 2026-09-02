---
name: playbook
description: 프로젝트를 어느 단계에서 무엇을 치며 진행하나 — 아이디어에서 머지까지의 지도. Use when the user says "이 프로젝트 시작하자", "계속 진행해줘", "다음은 뭐 하지", "어디까지 왔지", asks which command or skill to use next, or seems unsure what to type. Reads the map, tells the user the next command, never runs it for them.
---

# 플레이북 — 아이디어에서 머지까지

**강제는 GitHub 벽만 한다. 이 지도는 전부 "이렇게 하면 좋아요" 다.**
기획·스펙·티켓·구현·리뷰는 `mattpocock-skills` 가 한다. 우리 것은 문(`/new-project` · `/floor-check`)과 벽뿐이다.

**단계마다 · 상황마다 무엇을 치고 무엇이 일어나는지 예시까지**: [GUIDE.md](GUIDE.md) — 사용자가 "어떻게 하는 거야" · "예시 보여줘" · "이 스킬은 언제 써" 라고 물으면 그 절을 읽고 답한다.

## 이 스킬이 할 일

1. 지금 단계를 읽는다 — `gh issue list --state open` · 현재 브랜치 · 열린 PR. **상태를 파일에 쓰지 않는다.**
2. 아래 표에서 그 단계의 줄을 찾아 **다음에 칠 것 하나**를 말한다: *"다음은 `/to-tickets` 를 치시면 좋아요 — 이유 한 줄"*.
3. 다음이 사용자 전용 커맨드(`/grill-with-docs` · `/to-spec` · `/to-tickets` · `/implement` · `/new-project`)면 **실행한 척하지 않는다.** 사용자가 친다.
4. 아주 작은 수정(오타 · 한 줄)이면 인터뷰·스펙을 건너뛰고 바로 만든다 — 기준은 크기다.

## 한눈에

| # | 단계 | 사용자가 치는 것 | 일어나는 것 | 사용자가 정하는 것 | 끝났다는 신호 |
|---|---|---|---|---|---|
| 0 | 준비 (저장소당 한 번) | `/new-project 이름` | 벽 선 저장소 · `docs/agents/*.md` · 라벨 | 공개 여부 · 라이선스 | 저장소가 있다 |
| 1 | 생각 | `/grill-with-docs` + 아이디어 한 줄 | 라운드별 질문(추천 답 포함) · `CONTEXT.md` · 필요하면 ADR | **결정 전부** — 사실은 에이전트, 결정은 사람 | *frontier 가 비었다 · shared understanding* |
| 2 | 스펙 | `/to-spec` | 이슈 하나 (문제 · 해법 · 유저 스토리 · 구현·테스트 결정 · 범위 밖) | 테스트할 seam | 이슈에 `ready-for-agent` |
| 3 | 티켓 | `/to-tickets` | 수직 슬라이스 이슈들 + Blocked by | 굵기 · 순서 | 티켓들이 이슈 목록에 있다 |
| 4 | 만들기 (티켓마다) | `/clear` → 브랜치 → `/implement #N` → **draft PR** → `gh pr ready` | tdd 로 구현 · 자기 code-review · 커밋 → CI 가 돈다 → ready 에서 제3자가 **한 번** 본다 | 없음 — 머지 버튼만 | CI 초록 · 제3자 리뷰 · 머지 |
| 5 | 다시 열 때 | "계속하자" | 열린 이슈를 읽고 막힘 없는 첫 티켓부터 | 없음 | — |

**작으면 2·3 을 건너뛴다** — 한 세션에 들어가면 `/grill-with-docs` 뒤 바로 `/implement`.
**1 → 2 → 3 은 한 세션에서** 끊지 않고 간다. `/to-tickets` 끝난 뒤에야 `/clear`.

## 4단계 — Matt 의 스킬이 안 하는 두 줄

`/implement` 는 **현재 브랜치에 커밋하고 끝난다.** 우리 벽은 PR 에서 시작한다. 그 사이:

```
> /clear
$ git switch -c feat/<티켓-슬러그>      ← ①
> /implement #12
$ gh pr create --fill --draft           ← ②  CI 는 돈다, 제3자 리뷰는 아직 안 돈다
   … 빨간불 고치기 · 로컬 code-review 로 다듬기 · 푸시 …
$ gh pr ready                           ← ③  "다 됐다" — 제3자가 이 커밋을 한 번 본다
```

**고치는 자리는 draft, 확인하는 자리는 ready.** draft 동안은 몇 번 푸시해도 제3자 리뷰가 안 돈다 —
벽의 계약이 *최종 커밋을 봤다* 라서 ready 뒤에 푸시하면 다시 본다(2회이지 29회가 아니다).
더 손볼 게 많으면 `gh pr ready --undo` 로 되돌린다.
빨간불이면 머지가 안 된다. 리뷰 지적은 P0·P1 만 처분 의무(고쳤다 / 재현 불가 / 범위 밖).
**티켓 하나 = 세션 하나 = PR 하나 = 제3자 리뷰 한 번.**

## 곁길

| 상황 | 치는 것 | 메모 |
|---|---|---|
| 뭘 쳐야 할지 모르겠다 | `/ask-matt` | Matt 스킬 전체의 라우터 |
| 말로 못 정하겠다 (상태 · 로직 · 화면) | `/prototype` | 버릴 코드로 답을 본다 |
| 답을 남이 안다 | `/to-questionnaire` | 그 사람에게 줄 설문 |
| 에이전트 말이 안 들어온다 | `/wait-what` | 쉬운 말로 다시 |
| 뭔가 고장났다 | `/diagnosing-bugs` | 재현 명령이 먼저, 이론은 나중 |
| 요청·버그가 쌓였다 | `/triage` | **내가 안 만든** 이슈만 — `to-tickets` 가 만든 건 이미 agent-ready |
| 너무 커서 안개다 | `/wayfinder` | 결정 티켓 지도. 결정만 하고 안 만든다 → `/to-spec` 으로 합류 |
| 코드가 지저분해진다 | `/improve-codebase-architecture` | 후보를 보여주고 고른 것을 grill |
| 기존 저장소에 바닥이 있나 | `/floor-check` | 읽고 말하고 안 고친다 |
| 다른 하네스·디렉터리·사람에게 넘긴다 | `/handoff` | 같은 저장소에서 다음 날 이어가는 건 이슈로 — `/handoff` 가 아니다 |

## 단계 사이에서 헷갈리면 (Matt 의 순서)

① 이어갈 수 있나 → 이어간다 · ② 지금 맥락이 다음에 무관한가 → `/clear` · ③ 옮기나 → `/handoff` ·
④ 혼자 돌 수 있나 → 서브에이전트 · ⑤ 그 외 → `/compact`. **중간에 compact 하지 않는다** — 단계 경계에서만.

## 하지 말 것

- 저장소 안에서 `/grill-me` — 같은 인터뷰인데 기록을 안 남긴다. 저장소가 있으면 `-with-docs`
- `to-tickets` 가 만든 티켓을 `/triage` 하기
- 잘 잡힌 기능에 `/wayfinder` — 느리고 무겁다
- 티켓 둘을 한 세션에서
- 상태를 파일에 적기 — 정본은 `gh issue list`
