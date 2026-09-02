# 가이드 — 시니어의 흐름을 스킬로 걷는다

> `playbook` 스킬의 **참조 문서**다. `SKILL.md` 는 한 장짜리 지도이고, 여기는 **단계마다 · 상황마다 무엇을 치고 무엇이 일어나는지** 예시까지 적은 판이다.
> 근거: `mattpocock-skills` 1.2.3 의 SKILL.md 35개 전부 + 참조 파일 · Matt 의 공식 문서(aihero.dev) · 2026-08 시중 후기. 마지막에 링크.
> 원칙은 하나다 — **강제는 GitHub 벽만 한다. 이 문서는 전부 "이렇게 하면 좋아요" 다.**

## 0. 이 문서를 읽기 전에

| | |
|---|---|
| 깔려 있는 것 | `mattpocock-skills`(공식 마켓 · SHA 핀) · 우리 플러그인 `coolbress-standards`(문 둘 + 이 지도) · 벽(`coolbress/workflows`) · 상자(`coolbress/project-template`) |
| 우리가 만든 것 | `/new-project` · `/floor-check` · `playbook`. **그게 다다.** 기획·스펙·티켓·구현·리뷰는 전부 Matt 의 스킬 |
| 외울 것 | `/ask-matt`(뭘 쳐야 할지 모르겠다) · `/grill-with-docs`(새로 만들고 싶다) · `/implement #N`(티켓이 있다) |
| 사용자 전용 vs 모델 호출 | **사용자 전용**(`/` 로 당신이 친다): `grill-with-docs` `grill-me` `to-spec` `to-tickets` `implement` `wayfinder` `triage` `improve-codebase-architecture` `handoff` `wait-what` `to-questionnaire` `teach` `ask-matt` `setup-matt-pocock-skills`. **모델이 알아서 꺼낸다**: `grilling` `domain-modeling` `codebase-design` `tdd` `code-review` `prototype` `research` `diagnosing-bugs` `resolving-merge-conflicts` `wizard` `writing-for-agents` |

모델이 꺼내는 것은 **부를 필요가 없다** — 상황이 맞으면 뜬다(확률이지만, 위 스킬들은 설명문이 좋아 잘 뜬다). 사용자 전용은 **당신이 쳐야만** 돈다. 이 문서의 `>` 프롬프트는 전부 그 구분을 지킨다.

## 1. 시니어는 프로젝트를 이렇게 굴린다

Matt 가 이 스킬들을 만든 이유는 넷이다 — 에이전트가 반복해서 저지르는 실패 넷. 스킬 하나하나가 그중 하나를 막는다.

| 실패 | 어떻게 보이나 | 막는 스킬 |
|---|---|---|
| **정렬 실패** (misalignment) | 내가 원한 것과 다른 것을 자신 있게 만든다 | `grill-with-docs` · `to-spec` · `prototype` · `to-questionnaire` |
| **말이 안 통한다** (verbosity · 용어 표류) | 같은 것을 다른 이름으로 부르고, 설명이 길고 안 들어온다 | `domain-modeling`(`CONTEXT.md`) · `wait-what` |
| **깨진 코드** (피드백 루프 없음) | 돌려보지 않고 "됐다" 고 한다 | `tdd` · `diagnosing-bugs` · `code-review` |
| **구조 부패** (architectural decay) | 얕은 모듈이 늘고, 다음 변경이 점점 어려워진다 | `codebase-design` · `improve-codebase-architecture` |

그리고 원칙 다섯이 전체를 관통한다 — 전부 Matt 의 문장이다:

1. **정렬 먼저, 코드는 나중.** *"You do not need a worked-out plan to start: producing one is what the session is for."*
2. **사실은 에이전트가, 결정은 사람이.** grilling 의 규칙 — *"Finding facts is your job, never the user's. The decisions are the user's."*
3. **한 세션에 들어가게 자른다.** smart zone(~150k 토큰) 안에서만 모델이 또렷하다. 티켓 하나 = 새 세션 하나.
4. **자기 코드는 자기가 못 본다.** *"an agent that just wrote code tends to approve its own work"* — 리뷰는 별도 컨텍스트.
5. **기록은 되돌리기 어려운 것만.** ADR 은 셋이 다 참일 때만 — 되돌리기 어렵다 · 맥락 없이는 놀랍다 · 진짜 트레이드오프.

### 흐름 한 장

```
                      ┌─ 너무 커서 안개 ──────── /wayfinder ──(결정 지도가 걷히면)──┐
                      │                                                            ▼
아이디어 ──► /grill-with-docs ──► /to-spec ──► /to-tickets ──► [ /implement #N ]×N ──► PR ──► 벽 ──► 머지
   ▲             │  ▲                                              (tdd → code-review → 커밋)
   │             │  └── 말로 안 정해진다 → /prototype ─┘  남이 안다 → /to-questionnaire  조사 → /research
   │             └── 작으면 spec·tickets 건너뛰고 바로 /implement
   │
   ├── 고장났다 ──── /diagnosing-bugs ──► 회귀 시험 + 수정 ──► (티켓/PR)
   ├── 요청·버그 쌓임 ── /triage ──► agent brief ──► /implement
   └── 지저분해진다 ── /improve-codebase-architecture ──► 후보 하나 고르면 → 아이디어
```

**주 흐름은 하나**(grill → spec → tickets → implement → review)이고, **진입로 셋**(wayfinder · triage · diagnosing-bugs)이 거기로 합류하며, 나머지는 **곁길**이다. `ask-matt` 이 이 지도 그 자체다.

## 2. 단계별 — 치는 것 · 일어나는 것 · 내가 정하는 것 · 끝 · 예시

### 0 · 준비 — 저장소당 한 번

**새 프로젝트**

```
$ cd ~
$ ~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh divcal
```

벽이 선 저장소가 생기고, Matt 스킬이 전제하는 것이 같이 온다 — `docs/agents/*.md`(트래커 = GitHub · 기본 라벨 · single-context) · 트리아지 라벨 5개 · `AGENTS.md` 의 `## Agent skills` 블록. **`/setup-matt-pocock-skills` 를 돌릴 필요가 없다.** 트래커를 바꿀 때만.

**기존 저장소**

```
> /floor-check
```

읽고 · 말하고 · 안 고친다. 벽·시크릿 탐지·Dependabot·SAST 가 깔려 있는지. 그 뒤 `/setup-matt-pocock-skills` 를 **한 번** — 기존 저장소엔 `docs/agents/` 가 없다.

**내가 정하는 것**: 공개 여부(지금은 공개만) · 라이선스.

### 1 · 생각 — `/grill-with-docs`

```
> /grill-with-docs 배당금 캘린더를 CLI 로 만들고 싶다. 종목을 넣으면 다음 배당일이 나오게.
```

**일어나는 것** — 라운드 하나가 이렇게 온다:

```
❓ Q1 - 종목의 정체: "종목" 은 티커(AAPL)인가, 내가 가진 보유 목록인가?
➡️ 티커 하나씩. 보유 목록은 나중에 파일로.

❓ Q2 - 데이터 출처: 배당 일정을 어디서 가져오나? 공개 API 인가, 내가 손으로 넣나?
➡️ 공개 API 하나를 고른다. 사실 확인은 내가 서브에이전트로 하겠다 — 답하지 않아도 된다.

❓ Q3 - "다음 배당일" 의 뜻: 배당락일인가 지급일인가? 둘 다인가?
➡️ 배당락일. 지급일은 v2.
```

답하면 다음 라운드가 온다 — 앞 답에 걸려 있던 질문만. 용어가 흔들리면 잡는다: *"'배당일' 이 아까는 지급일이었는데 지금은 배당락일로 쓰고 있다 — 어느 쪽인가?"* → 정해지는 순간 `CONTEXT.md` 에 기록된다. 되돌리기 어려운 결정만 ADR 로 제안한다(대부분 세션은 ADR 0개 — 정상이다).

**내가 정하는 것**: 결정 전부. 사실(API 가 뭘 주나, 이 코드가 뭘 하나)은 에이전트가 찾는다.

**답하는 요령** — Matt 가 실패 형태를 하나 콕 집었다: *"answering 'agreed, agreed, agreed' for forty questions"*. 추천 답을 그대로 받아도 되지만 **반박이 한 번도 없으면 안 굴린 것**이다. 모르면 *"모르겠다"* — 그건 유효한 답이고, 프로토타입이 필요하다는 신호다. 46문항 4라운드가 보통 세션이다.

**끝**: *"frontier 가 비었다 — 모든 가지를 방문했고 조용히 가정된 것이 없다. shared understanding 에 도달했다"* 하고 **멈춘다. 실행하지 않는다.** 그게 규칙이다.

**옆길**

| 신호 | 치는 것 | 무엇이 나오나 |
|---|---|---|
| "이 상태 흐름이 맞는지 말로는 모르겠다" | 에이전트가 `prototype` 을 꺼낸다 (또는 *"프로토타입으로 보자"*) | 더블클릭으로 열리는 HTML 하나 — 버튼을 눌러 상태가 바뀌는 걸 **비개발자도** 본다 |
| "이 화면이 어때야 할지 모르겠다" | 같은 `prototype` · UI 갈래 | 한 라우트에 **서로 다른** 변형 3개, 하단 바로 전환 |
| "이건 세무사/디자이너가 안다" | `/to-questionnaire` | 그 사람에게 줄 설문 md — 나한테 묻지 않고 **보낼 것**을 묻는다 |
| "이 API 가 뭘 주는지 알아야 답한다" | 에이전트가 `research` 를 꺼낸다 | 백그라운드 에이전트가 1차 출처를 읽고 인용된 md 를 남긴다 |
| "무슨 말인지 모르겠다" | `/wait-what` | 쉬운 말로 · `CONTEXT.md` 용어로 다시 설명 |

**하지 말 것**: 저장소 안에서 `/grill-me` — 같은 인터뷰인데 `CONTEXT.md` 를 안 남긴다. 저장소가 있으면 항상 `-with-docs`.

### 2 · 스펙 — `/to-spec`

```
> /to-spec
```

**일어나는 것**: 인터뷰 없이 지금까지 대화 + 코드베이스 + `CONTEXT.md` 를 **합성**한다. 먼저 **seam** 을 보여준다:

```
테스트할 seam 후보:
  ① `divcal next AAPL` CLI 한 줄 — 입력에서 출력까지 전부 지난다   ← 권장 (하나면 이상적)
  ② `fetch_dividends(ticker)` 함수 경계
어느 쪽으로 갈까?
```

확인하면 이슈 하나를 만들고 `ready-for-agent` 를 단다. 내용: 문제 · 해법 · **유저 스토리(길게)** · 구현 결정 · 테스트 결정 · **범위 밖** · 메모.

**내가 정하는 것**: seam. 적을수록 좋다 — *"The ideal number across a change is one."*

**스펙에 없는 것이 맞다**: 파일 경로 · 코드. 금방 낡아서 일부러 뺀다.

**건너뛰기**: 한 세션에 들어가는 일이면 2·3 을 건너뛰고 `/implement`. 오타에 스펙을 쓰면 규칙을 우회하기 시작한다.

⚠️ **1 → 2 → 3 은 한 세션에서.** `/compact` 도 `/clear` 도 하지 말고 간다 — 스펙과 티켓이 같은 생각 위에 서야 한다. 긴 스펙이 잘려 나온 사례가 있다.

### 3 · 티켓 — `/to-tickets`

```
> /to-tickets
```

**일어나는 것**: 수직 슬라이스 목록을 보여주고 **퀴즈**를 낸다:

```
1. 티커 하나로 다음 배당락일 출력 (CLI → API → 출력 → 시험)   Blocked by: 없음
2. 날짜 없는 종목의 오류 메시지                                 Blocked by: 1
3. 보유 목록 파일(.csv)에서 여러 종목                            Blocked by: 1
4. 캐시 — 같은 종목 하루 한 번만 API                             Blocked by: 1

굵기 맞나? 막힘 관계 맞나? 합치거나 나눌 것?
```

**수직**이 핵심이다 — 각 티켓이 스키마→API→UI→시험을 **한 줄기로** 관통해 끝나면 **시연할 수 있다.** "스키마 전부 → API 전부" 식 수평 슬라이스는 시연할 게 없다. 판정 질문: *"이 티켓이 끝나면 무엇을 보여줄 수 있나?"* 답이 없으면 수평이다.

**내가 정하는 것**: 굵기 · 순서 · 합칠지. 승인하면 이슈로 올라간다 — GitHub 이면 native blocking 이라 **막힘 없는 티켓은 어느 것이든 잡을 수 있다.**

**AC 규칙**(`AGENTS.md`): 인수기준마다 그걸 증명하는 검사를 적는다. 못 적으면 `UNVERIFIABLE`. base 커밋에서 이미 통과하는 AC 는 AC 가 아니다.

**넓은 리팩터의 예외**: 이름 하나 바꾸는데 호출부가 수백 곳이면 수직 슬라이스가 안 선다 → **expand → migrate(묶음) → contract** 로 잘라 준다. 그건 스킬이 알아서 한다.

### 4 · 만들기 — `/implement` · 티켓마다 반복

```
> /clear
$ git switch -c feat/next-dividend-date         ← ①
> /implement #1
   … seam 확인 → red → green → 타입체크 → 시험 → code-review 두 축 → 커밋 …
$ gh pr create --fill --draft                    ← ②  CI 는 돈다, 제3자 리뷰는 아직
   … 빨간불 고치기 · 푸시 …
$ gh pr ready                                    ← ③  제3자가 이 커밋을 한 번 본다
```

**일어나는 것** — `implement` 는 15줄짜리 스킬이고 본체는 안에서 부르는 둘이다:

- **`tdd`** — 먼저 seam 을 확인한다(*"no test at an unconfirmed seam"*). 그 다음 **한 슬라이스씩**: 실패하는 시험 하나 → 통과할 만큼만 코드 → 반복. 첫 사이클은 **tracer bullet**(끝까지 한 줄기). 리팩터링은 루프에 없다 — 리뷰 단계의 일이다(2026-06 에 일부러 뺐다: 에이전트가 안 하더라).
- **`code-review`** — 두 축을 **별도 서브에이전트**로: **Standards**(`CONTRIBUTING.md` + Fowler 냄새 12종 — Mysterious Name · Duplicated Code · Feature Envy …) · **Spec**(이슈와 대조 — 빠진 요구 · 안 시킨 것 · 틀리게 구현). 나란히 보고하고 **합치지 않는다** — 한 축이 다른 축을 가리면 안 되니까.

그리고 커밋. **여기서 Matt 의 흐름은 끝난다.** 브랜치도 PR 도 안 만든다 — 그래서 ①②③ 세 줄이 우리 것이다.

**그 다음은 벽**: `ci / lint·typecheck·test·build·secrets·diff-size·deps` 와 `third-party / review`. 빨간불이면 머지가 안 된다. ready 뒤에 푸시하면 리뷰가 다시 돈다(2회이지 29회가 아니다). 더 손볼 게 많으면 `gh pr ready --undo`.

**내가 정하는 것**: 머지 버튼. *"봤다"* 는 벽이 보증하고 *"읽었다"* 는 당신 몫이다. 리뷰 지적은 P0·P1 만 처분 의무 — 고쳤다 / 재현 불가 / 범위 밖.

**하지 말 것**: 티켓 둘을 한 세션에서. `implement` 가 티켓을 **닫아주지는 않는다** — 머지되면 `Closes #1` 이 닫거나 손으로 닫는다.

### 5 · 다시 열 때 — "계속하자"

```
> 이 프로젝트 계속 진행해줘
```

세션 시작 훅이 정본 위치와 열린 이슈를 찍고, 에이전트가 **막힘 없는 첫 티켓**부터 잡는다. 이슈가 정본이라 `/handoff` 가 필요 없다.

**`/handoff` 는 딱 넷**: 다른 하네스(Claude → Codex) · 다른 디렉터리 · 다른 사람 · 하던 일 중간에 곁가지를 **다른 에이전트에게** 떼어줄 때. 파일은 OS 임시 폴더에 생긴다.

**단계 사이에서 뭘 할지** — Matt 의 순서대로, 위에서 첫 "예" 가 답이다:

1. **이어갈 수 있나** (다음 단계가 이 대화를 1차 자료로 쓰나 · smart zone 이 남았나) → **이어간다.** grill → implement 가 전형적 "예"
2. **지금 맥락이 다음에 무관한가** → `/clear`. 되돌릴 수 없으니 신중히
3. **옮기나** (하네스 · 디렉터리 · 사람) → `/handoff`
4. **혼자 돌 수 있나** (조종 없이) → 서브에이전트. 리뷰가 전형
5. **그 외** → `/compact` — 기본값이지만 **첫 선택은 아니다.** 요약이 결정을 납작하게 만든다

**중간에 compact 하지 않는다** — 단계 경계에서만.

## 3. 상황별 — 곁길과 진입로

### 너무 커서 안개다 — `/wayfinder`

```
> /wayfinder 배당 캘린더를 웹앱으로 — 로그인 · 포트폴리오 · 알림까지. 어디서 시작할지도 모르겠다.
```

**언제**: 기준은 프로젝트 크기가 아니라 **세션 수**다 — *"wayfinder only makes sense if the work doesn't fit into a single session."* 잘 잡힌 기능엔 쓰지 마라.

**일어나는 것**: ① 목적지를 grill 로 못 박고 ② 너비 우선으로 안개를 훑어 ③ **map 이슈**(`wayfinder:map`) 하나와 **결정 티켓**들을 만든다. 티켓은 넷 중 하나 — `grilling`(대화) · `prototype`(만들어 보고 정한다) · `research`(사실 조사 · AFK) · `task`(결정을 위한 잡일). 각 세션은 **티켓 하나만** 풀고 답을 댓글로 남기고 닫는다. 안개가 걷히면 **만들지 않고 `/to-spec` 으로 넘긴다.**

**시중이 문 것**: *"never really created any prototypes or research tasks, it mainly defaults to wayfinder/tasks … a lot more babysitting"* · 질문이 세 문단씩이라 피로하다 · 27개 티켓을 만들었다 중간에 무효가 됐다(목적지가 넓었다). **처방**: 목적지를 "에픽 하나" 로 좁힌다 · 프로토타입을 적극 시킨다 · map 안에서 코드를 짜기 시작하면 멈춘다.

### 말로 안 정해진다 — `prototype`

에이전트가 스스로 꺼내는 스킬이지만 *"프로토타입으로 보자"* 라고 말해도 된다.

| 질문 | 갈래 | 나오는 것 |
|---|---|---|
| "이 상태 흐름·데이터 모양이 맞나" | LOGIC | **HTML 파일 하나** — 상태 패널 + 액션 버튼 + 안내 탭. 비개발자용 말로. 안의 로직은 나중에 진짜 코드로 옮길 수 있게 순수 모듈 |
| "이 화면이 어때야 하나" | UI | **기존 라우트 위에** 변형 3개(`?variant=`), 하단 바로 전환. 진짜 데이터 옆에서 봐야 판단이 된다 |

끝나면 **답 한 줄**을 grill 에 돌려주고, 프로토타입은 `prototype/<이름>` 브랜치에 남긴다(머지 안 함 · 이슈에서 가리킴).

### 답을 남이 안다 — `/to-questionnaire`

```
> /to-questionnaire
  → 누구에게? (세무사 · 배당 과세를 안다)  → 무엇을 받아야 하나? (원천징수 · 이중과세 처리)
  → to-questionnaire-dividend-tax.md 생성
```

주제가 아니라 **보내는 것**을 나에게 묻는다. 돌아온 답은 `/grill-with-docs` 나 `/to-spec` 의 재료.

### 조사가 필요하다 — `research`

*"이 API 가 배당락일을 주는지 조사해줘"* → 백그라운드 에이전트가 **1차 출처**(공식 문서 · 소스)만 읽고 인용된 md 를 저장소 관례 자리에 남긴다. 결과는 **grill 의 재료**이지 결정이 아니다.

### 고장났다 — `diagnosing-bugs`

*"이거 왜 깨져?"* 라고 하면 에이전트가 꺼낸다. 여섯 단계이고 **첫 단계가 전부**다:

1. **빨간불이 켜지는 명령 하나**를 만든다 — 시험 · curl · CLI 픽스처 · 재생 트레이스 · bisect … *"Build the right feedback loop, and the bug is 90% fixed."* 이게 없으면 가설을 **세우지 않는다**
2. 재현하고 **최소화**한다 — 뭘 빼도 여전히 빨간 최소 시나리오
3. 가설 3~5개, **반증 가능하게** 순위 — 나에게 보여준다(도메인 지식으로 순위가 바뀐다)
4. 한 번에 변수 하나만 — 로그는 `[DEBUG-xxxx]` 태그로
5. 회귀 시험을 **먼저**, 고치고, 통과 확인 — 맞는 seam 이 없으면 **그게 발견**이다
6. 정리 — 태그 로그 제거 · 맞았던 가설을 커밋 메시지에

시중 평이 가장 좋은 스킬이다: *"build a tight, deterministic, fast feedback loop that can go red on this specific bug before you're allowed to theorize."*

### 요청·버그가 쌓였다 — `/triage`

```
> /triage 뭐가 내 손이 필요해?
> /triage #12 보자
> /triage #12 를 ready-for-agent 로
```

상태기계: `needs-triage` → `needs-info` | `ready-for-agent` | `ready-for-human` | `wontfix`. 티켓마다 **종류 하나(bug/enhancement) + 상태 하나.** 브리핑 전에 셋을 확인한다 — **재현**(버그면 실제로) · **중복**(이미 구현됐나 — 도메인 개념으로 검색) · **기각 이력**(`.out-of-scope/`). 그리고 `ready-for-agent` 에는 **agent brief** 를 단다 — 파일 경로·줄 번호 없이 인터페이스·행동·AC·범위 밖으로. 몇 주 뒤에 잡아도 살아 있게.

**하지 말 것**: `to-tickets` 가 만든 티켓을 트리아지 — 이미 agent-ready 다. 트리아지는 **내가 안 만든 것**(신고 · 요청 · 외부 PR)만.

### 코드가 지저분해진다 — `/improve-codebase-architecture`

```
> /improve-codebase-architecture
```

Matt 는 *"once a week or after a surge of development"*. 최근 커밋이 몰린 곳부터 훑어 **깊게 만들 후보**를 HTML 보고서로 준다(문제 · 해법 · 전후 그림 · Strong/Worth exploring/Speculative). 고르면 grill 로 들어간다 → 그게 곧 새 아이디어 → 1단계.

어휘는 `codebase-design` 이 준다 — **module · interface · depth · seam · adapter · leverage · locality.** 핵심 판정: **삭제 시험**(이 모듈을 지우면 복잡도가 사라지나, 흩어지나) · **어댑터 하나면 가상의 seam, 둘이면 진짜.**

### 충돌이 났다 — `resolving-merge-conflicts`

rebase/merge 중이면 에이전트가 꺼낸다. 양쪽의 **의도**를 1차 자료(커밋 · PR · 이슈)에서 읽고 hunk 마다 푼다. **절대 `--abort` 안 한다.** 끝나면 검사를 돌린다.

### 사람만 할 수 있다 — `wizard`

시크릿 · 대시보드 클릭 · 일회성 이전. 에이전트가 **URL 을 열고 값을 받아 `.env`·GitHub secrets 에 쓰는 bash 마법사**를 만들어 준다. 한 번 쓰고 버린다. 에이전트가 할 수 있는 일엔 안 쓴다.

### 못 알아듣겠다 — `/wait-what`

어느 스킬 도중이든. *"방금 그거 다시, 쉬운 말로."* Simplified Technical English + `CONTEXT.md` 용어로 다시 온다. 사후약이다 — 선약은 `grill-with-docs` 가 초반에 용어를 맞추는 것.

### 스킬이나 `AGENTS.md` 를 고친다 — `writing-for-agents`

모델이 꺼낸다. 핵심 셋: **포인터의 첫 단어가 발화를 정한다** · 항상 로드되는 줄은 매 턴 값을 치른다 · 완료 기준이 흐리면 에이전트가 **일찍 끝낸다.**

## 4. 스킬 전부 — 35개 한눈에

| 스킬 | 누가 부르나 | 언제 | 우리 |
|---|---|---|---|
| `ask-matt` | 사용자 | 뭘 쳐야 할지 모르겠다 | ✅ |
| `grill-with-docs` | 사용자 | 저장소 안에서 아이디어를 다듬는다 (`grilling` + `domain-modeling`) | ✅ **시작점** |
| `grill-me` | 사용자 | 저장소 **밖**에서 (글 · 사업 판단) | ✅ 저장소 밖에서만 |
| `grilling` | 모델 | 인터뷰 원시 — 라운드 · frontier · 추천 답 | (안에서 돈다) |
| `domain-modeling` | 모델 | 용어 도전 · `CONTEXT.md` · ADR | (안에서 돈다) |
| `to-spec` | 사용자 | 대화 → 스펙 이슈 (인터뷰 없음) | ✅ |
| `to-tickets` | 사용자 | 스펙 → 수직 슬라이스 티켓 + 막힘 | ✅ |
| `implement` | 사용자 | 티켓 하나를 tdd 로 짓고 리뷰하고 커밋 | ✅ 브랜치·PR 은 우리가 |
| `tdd` | 모델 | seam 합의 → red → green, 한 슬라이스씩 | (안에서 돈다) |
| `code-review` | 모델 | Standards + Spec 두 축 · 별도 서브에이전트 | (안에서 돈다) · 벽 아님 |
| `wayfinder` | 사용자 | 한 세션에 안 들어가는 안개 | ✅ 조건부 — 세션 수로 판단 |
| `prototype` | 모델 | 말로 안 정해지는 상태·화면 | ✅ |
| `research` | 모델 | 1차 출처 조사 · 백그라운드 | ✅ |
| `to-questionnaire` | 사용자 | 남이 아는 답 | ✅ |
| `diagnosing-bugs` | 모델 | 어려운 버그 · 성능 퇴행 | ✅ |
| `triage` | 사용자 | 내가 안 만든 이슈·PR 정리 | ✅ 요청이 쌓이면 |
| `improve-codebase-architecture` | 사용자 | 주 1회 · 개발 몰린 뒤 | ✅ |
| `codebase-design` | 모델 | 깊은 모듈 어휘 | (안에서 돈다) |
| `resolving-merge-conflicts` | 모델 | 충돌 중 | ✅ |
| `wizard` | 모델 | 사람만 할 수 있는 절차 | ✅ |
| `handoff` | 사용자 | 하네스·디렉터리·사람 이동 | ✅ 그 넷일 때만 |
| `wait-what` | 사용자 | 안 들어온다 | ✅ |
| `writing-for-agents` | 모델 | 스킬·`AGENTS.md` 작성 | ✅ |
| `setup-matt-pocock-skills` | 사용자 | 트래커·라벨·문서 배치 | ⚪ 새 저장소는 상자가 대신 · 기존 저장소만 |
| `teach` | 사용자 | 개념을 여러 세션에 걸쳐 배운다 | ⚪ 엔지니어링 흐름 밖 |
| `loop-me` · `claude-handoff` · `setup-ts-deep-modules` · `writing-beats` · `writing-fragments` · `writing-shape` | — | in-progress · 플러그인에 안 실린다 | ⚪ |
| `git-guardrails-claude-code` · `setup-pre-commit` | — | 훅 층 · Matt 도 *rarely use* | 🚫 `--no-verify` 로 넘어간다. 벽이 서버에서 한다 |
| `migrate-to-shoehorn` · `scaffold-exercises` | — | Matt 개인 (TS · 강의) | 🚫 해당 없음 |

## 5. 자주 하는 실수 — 문서와 시중이 같이 지적한 것

| 실수 | 왜 나쁜가 | 대신 |
|---|---|---|
| grill 에 *"네, 네, 네"* | 정렬이 안 된 채 정렬됐다고 믿는다 | 한 번은 반박한다. 모르면 "모르겠다" |
| 저장소 안에서 `/grill-me` | 기록이 안 남는다 | `/grill-with-docs` |
| `to-spec` 과 `to-tickets` 사이에 `/clear` | 티켓이 스펙과 다른 생각 위에 선다 | 한 세션에서 |
| 티켓 12개 / 코드 3줄 | 과분해 | 퀴즈에서 합친다. 한 세션이면 `/implement` 바로 |
| 수평 슬라이스 | 시연할 게 없다 | *"끝나면 뭘 보여줄 수 있나"* |
| 동어반복 시험(기대값을 코드처럼 계산) | 구성상 통과 | 기대값은 스펙·알려진 값에서 |
| 내부 모듈을 mock | 리팩터에 깨진다 | mock 은 경계에서만 — 외부 API · 시간 · 난수 |
| `to-tickets` 결과를 `/triage` | 이미 agent-ready | 트리아지는 남이 만든 것만 |
| 잘 잡힌 기능에 `/wayfinder` | 느리고 무겁다 | `grill-with-docs` |
| wayfinder 안에서 코드 짜기 | 지도가 build 가 된다 | 멈추고 `/to-spec` 으로 |
| 단계 중간에 `/compact` | 맥락을 잃는다 | 경계에서, 그리고 `/compact` 는 마지막 선택 |
| 스펙에 파일 경로·코드 | 금방 낡는다 | 인터페이스·행동으로 |
| `implement` 뒤 `main` 에 푸시 | 룰셋이 거부 | 브랜치 → draft PR → ready |
| 리뷰 지적을 안 읽고 머지 | *봤다* ≠ *읽었다* | P0·P1 처분 셋 중 하나 |

## 6. 우리 것과 맞물리는 자리

- **브랜치 · PR** — `implement` 는 커밋에서 끝난다. 4단계의 세 줄이 우리 것. `AGENTS.md` 에도 적혀 있다
- **라벨** — `ready-for-agent` 등 5개를 `new-project.sh` 가 만든다. 어느 스킬도 안 만든다
- **`CONTRIBUTING.md`** — `code-review` 의 Standards 축이 읽는다. 상자가 주고 시험이 내용을 지킨다
- **`AGENTS.md` §기획할 때** — `/kickoff` 에서 옮긴 넷(이미 있나 · 유도 질문 금지 · 안 만들 것 · 개인정보 hard-stop). grilling 이 도는 세션에 이미 로드돼 있다
- **리뷰는 PR 당 한 번** — draft 에서 고치고 ready 에서 본다. `standards` 는 advisory, 제품 저장소는 벽

## 근거

- `mattpocock-skills` 1.2.3 — SKILL.md 35개 · `PHASE-BOUNDARIES.md` · `AGENT-BRIEF.md` · `OUT-OF-SCOPE.md` · `DEEPENING.md` · `DESIGN-IT-TWICE.md` · `LOGIC.md` · `UI.md` · `tests.md` · `mocking.md` · `CONTEXT-FORMAT.md` · `ADR-FORMAT.md` · `SKILL-MECHANICS.md`
- Matt 공식 문서: [5 Agent Skills I Use Every Day](https://www.aihero.dev/5-agent-skills-i-use-every-day) · [grill-me](https://www.aihero.dev/skills-grill-me) · [grill-with-docs](https://www.aihero.dev/grill-with-docs) · [to-spec](https://www.aihero.dev/skills-to-spec) · [to-tickets](https://www.aihero.dev/skills-to-tickets) · [tdd](https://www.aihero.dev/skills-tdd) · [wayfinder](https://www.aihero.dev/skills-wayfinder) · [prototype](https://www.aihero.dev/skills-prototype) · [triage](https://www.aihero.dev/burn-through-your-backlog-with-my-triage-skill) · [handoff](https://www.aihero.dev/skills-handoff) · [domain-model](https://www.aihero.dev/skills-domain-model)
- 시중: [Alex Rusin — main flow 걸어보기](https://blog.alexrusin.com/matt-pocock-skills-main-flow/) · [Jerryskills — GSD·Superpowers 에서 갈아탄 이유](https://jerrysmd.github.io/20260812_matt-pocock-skills-vs-gsd-superpowers/) · [Kaizen Craft — 비판적 가이드](https://kaizencode.art/notepad/matt-pocock-skills-guide/) · [wayfinder 토론 #484](https://github.com/mattpocock/skills/discussions/484) · [Theo — So I tried Matt's skills](https://www.youtube.com/watch?v=0oXOOlqVu5M) · [Eric Tech](https://www.youtube.com/watch?v=8D8ewFBJfFM)
