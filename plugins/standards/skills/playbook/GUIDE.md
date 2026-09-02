# 가이드 — 현업 워크플로를 스킬로 걷는다

> `playbook` 스킬의 **참조 문서**다. `SKILL.md` 는 한 장 지도, 여기는 **현업 팀의 개발 워크플로**를 먼저 설명하고, **그 워크플로의 단계마다 · 상황마다** `mattpocock-skills` 의 어떤 스킬을 어떻게 치는지 예시까지 적은 판이다.
> 근거: 현업 관행은 `coolbress/standards` 의 `direction/03`·`04`·`05`(리서치 코퍼스 · claim ID 병기) · 스킬은 `mattpocock-skills` 1.2.3 실물 35개 + 참조 파일 · Matt 의 공식 문서(aihero.dev) · 2026-08 시중 후기.
> 원칙은 하나다 — **산출물의 인수 강제는 GitHub 벽만 한다. 이 문서는 전부 "이렇게 하면 좋아요" 다.** 로컬 실행 피해(비밀 읽기 · force push · `rm -rf`)는 템플릿의 `.claude/settings.json` deny 가 막는다 — 벽은 그걸 되돌려주지 못한다.
> 지원 범위(증명된 것): **공개 GitHub · Python · greenfield · 단일 소유자.** 비공개 · 웹/Node · 기존 대형 저장소 · 외부 설치자 · 시니어 인수는 미검증이다 — 구조의 실패가 아니라 성숙도 표시.

## 0. 읽기 전에

| | |
|---|---|
| 깔려 있는 것 | `mattpocock-skills`(공식 마켓 · SHA 핀) · 우리 플러그인(문 둘 + 이 지도) · 벽(`coolbress/workflows`) · 상자(`coolbress/project-template`) |
| 우리가 만든 것 | `/new-project` · `/floor-check` · `playbook` — **진입과 문만.** 기획·설계·스펙·티켓·구현·리뷰 같은 **작업 스킬은 만들지 않고 재사용**한다 |
| Matt 의 스킬은 무엇인가 | "시니어가 이미 해결했다" 가 아니라 **우리가 검토하고 핀한 외부 워크플로 의존성**이다. 판이 올라가 이름·산출물 형식이 바뀌면 이 문서와 갈릴 수 있다 — `tests/playbook-skill-names.sh` 가 이름을, 깨끗한 설치 시험이 나머지를 잡는다 |
| 외울 것 | `/ask-matt`(뭘 쳐야 하지) · `/grill-with-docs`(새로 만들자) · `/implement #N`(티켓이 있다) |
| **사용자 전용** (`/` 로 당신이 친다) | `grill-with-docs` `grill-me` `to-spec` `to-tickets` `implement` `wayfinder` `triage` `improve-codebase-architecture` `handoff` `wait-what` `to-questionnaire` `teach` `ask-matt` `setup-matt-pocock-skills` |
| **모델이 알아서 꺼낸다** | `grilling` `domain-modeling` `codebase-design` `tdd` `code-review` `prototype` `research` `diagnosing-bugs` `resolving-merge-conflicts` `wizard` `writing-for-agents` |

모델이 꺼내는 것은 부를 필요가 없다 — 상황이 맞으면 뜬다. 사용자 전용은 **당신이 쳐야만** 돈다. 아래 `>` 프롬프트는 전부 그 구분을 지킨다.

## 1. 현업 팀은 이렇게 일한다 — 워크플로

시니어 팀의 개발은 **한 바퀴**다. 아이디어가 들어오면 그것을 **검증 가능한 요구**로 바꾸고, **작은 조각**으로 잘라, 조각마다 **브랜치 → PR → 리뷰 → 자동 검사 → 머지**를 돌리고, 쌓이면 **릴리스**하고, 굴리면서 생기는 **버그·요청·부패**를 같은 바퀴로 되돌린다.

```
아이디어
  │
  ▼
① 기획 ─ 누구의 어떤 문제 · 안 만들 것 · 무엇이 되면 끝인가
  │
  ▼
② 설계 ─ 용어를 하나로 · 되돌리기 어려운 결정만 기록(ADR) · 말로 안 되면 만들어 본다
  │
  ▼
③ 스펙 ─ 결정을 한 문서로 (인터뷰 없이 합성)
  │
  ▼
④ 분해 ─ 끝까지 관통하는 작은 조각(tracer bullet)들 + 순서(막힘)
  │
  ▼
⑤ 구현 ─ 조각마다: 브랜치 → 실패하는 시험 먼저 → 통과 → 작은 PR   ─┐
  │                                                                 │ 반복
  ▼                                                                 │
⑥ 리뷰 ─ 작성자와 다른 눈 · 규약과 스펙 두 축                          │
  │                                                                 │
  ▼                                                                 │
⑦ 판정·머지 ─ CI 가 판정 · 빨간불이면 못 들어간다 · squash · 이슈 자동 종료 ─┘
  │
  ▼
⑧ 릴리스 ─ 태그 · 릴리스 노트
  │
  ▼
⑨ 운영 ─ 버그(재현부터) · 요청(트리아지) · 구조 정리(주기적) ──► 다시 ①
```

### 단계마다 시니어가 지키는 것 — 그리고 왜

| 단계 | 시니어의 관행 | 왜 (근거는 `standards`) |
|---|---|---|
| ① 기획 | **문제부터** 적는다, 해법이 아니라. **안 만들 것**을 받는다. 인수기준에 **안정 ID**(`AC-1`…)를 달고 각각을 **어떤 검사가 증명하는지** 적는다. 못 적으면 `UNVERIFIABLE` 이라고 쓴다 | 인터뷰어가 **흔한 실수 목록을 쥐고 있을 때만** 사람보다 낫다(`ELI-001` · 통제실험 2개). 이슈는 **크기 조건부** — 오타에 이슈를 요구하면 규칙을 우회하기 시작한다(`GHW-012`) |
| ② 설계 | **용어를 하나로**(같은 것을 두 이름으로 안 부른다). 결정은 **되돌리기 어렵고 · 맥락 없이는 놀랍고 · 진짜 트레이드오프**일 때만 ADR. 말로 안 정해지는 건 **버릴 코드로 만들어 본다** | 큰 선택의 이유는 ADR 에 남긴다(`06` §상태는 채팅 밖에). 대부분 세션은 ADR 0개가 정상 |
| ③ 스펙 | 결정을 **한 문서로 합성**한다. 파일 경로·코드는 안 적는다 — 금방 낡는다 | 요구 ②(*시작에서 기획이 면밀해진다*) |
| ④ 분해 | **수직으로** 자른다 — 조각 하나가 스키마→API→화면→시험을 관통해 **끝나면 시연할 수 있게.** 첫 조각은 **walking skeleton**(끝까지 한 줄기). 한 조각 = 한 브랜치 = 한 PR | Cockburn walking skeleton(`05` 테스트 묶음). 조각이 **한 세션**에 들어가야 에이전트가 또렷하다 |
| ⑤ 구현 | **짧은 브랜치**(활성 ≤3 · 매일 병합). **동작이 바뀌면 그 변화를 잡는 시험을 같은 PR 에.** 실패하는 시험 **먼저**(권고). **행동 변경과 리팩터링은 다른 커밋**. PR 은 **200줄 목표 · 400줄 상한** | DORA(`GHW-009·010`) · `TDD-001`(순서는 권고, 동반은 강제) · Fowler·Google 리팩터 분리 · Cisco `CR-001~003` |
| ⑥ 리뷰 | **작성자와 다른 눈**이 본다. 두 축 — **규약**(`CONTRIBUTING`)과 **스펙**(이슈). 리뷰는 **안전망이 아니다** — 판정은 검사가 한다 | 컨텍스트 분리가 효과의 원인(`IPW-006`). 최선 조건에도 F1 28.6%(`IPW-007`). AI PR 의 61%는 리뷰 기록이 없다(`IPW-019`) |
| ⑦ 판정·머지 | lint · typecheck · test · build 를 **각각 required** 로. **빨간불이면 아무도 못 넘는다 — 소유자도.** `main` 이 빨개지면 **다른 일보다 먼저** 고친다. CI 10분 안. squash 하나로 | 벽 4/4 실측(`--admin` 도 거부). `CIB-001`(Fowler · XP 가이드라인). `05` §머지 방법 |
| ⑧ 릴리스 | PR 제목은 `type(scope): 요약`(Conventional Commits 표준 11종). SemVer 태그. 릴리스 노트는 **왜**를 사람이 쓰고 **무엇**은 생성 | `24 issue-pr-conventions`(N=6,582) · `05` §PR 제목 · §릴리스 노트 |
| ⑨ 운영 | 버그는 **재현하는 명령**부터 — 이론은 나중. 요청은 **상태기계**로 트리아지. 개발이 몰린 뒤엔 **구조 정리** | 원칙 02(완료는 주장이 아니라 머지된 커밋) · 에이전트 리팩터에서 MI 하락 56%(`CODE-QUALITY-JUDGMENT`) |

이 표의 **오른쪽**이 왜 그 관행인지의 근거이고, **아래 §2** 가 그 관행을 어떤 스킬로 걷는지다.

### 에이전트와 일할 때 달라지는 것 넷

Matt 가 스킬을 만든 이유이자, 사람 팀엔 없던 실패 넷이다. 스킬 하나하나가 그중 하나를 막는다.

| 실패 | 어떻게 보이나 | 막는 스킬 |
|---|---|---|
| **정렬 실패** | 내가 원한 것과 다른 것을 자신 있게 만든다 | `grill-with-docs` · `to-spec` · `prototype` · `to-questionnaire` |
| **말이 안 통한다** | 같은 것을 다른 이름으로, 설명이 길고 안 들어온다 | `domain-modeling`(`CONTEXT.md`) · `wait-what` |
| **깨진 코드** | 돌려보지 않고 "됐다" 고 한다 | `tdd` · `diagnosing-bugs` · `code-review` |
| **구조 부패** | 얕은 모듈이 늘고 다음 변경이 어려워진다 | `codebase-design` · `improve-codebase-architecture` |

그리고 원칙 다섯 — 전부 Matt 의 문장: **정렬 먼저, 코드는 나중** · **사실은 에이전트가, 결정은 사람이** · **한 세션에 들어가게 자른다**(smart zone ~150k) · **자기 코드는 자기가 못 본다** · **기록은 되돌리기 어려운 것만.**

## 2. 단계별 — 시니어는 이렇게 → 우리는 이 스킬로 → 예시

### 준비 · 저장소 (한 번)

**시니어는**: 첫날에 벽을 세운다 — 브랜치 보호 · 필수 검사 · 시크릿 탐지 · 의존성 봇. 그 뒤로는 아무도(본인도) 우회 못 한다.

**우리는**: `/new-project` 하나.

```
$ cd ~
$ ~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh divcal
```

벽이 선 저장소 + Matt 스킬이 전제하는 것이 같이 온다 — `docs/agents/*.md`(트래커 = GitHub · 기본 라벨 · single-context) · 트리아지 라벨 5개 · `AGENTS.md` 의 `## Agent skills`. **`/setup-matt-pocock-skills` 를 돌릴 필요가 없다.**

기존 저장소면 `/floor-check`(읽고 · 말하고 · 안 고친다) → 필요하면 `/setup-matt-pocock-skills` 한 번.

**내가 정하는 것**: 공개 여부(지금은 공개만) · 라이선스.

### ① 기획 — `/grill-with-docs`

**시니어는**: 코드 전에 요구를 캔다. 유도 질문 없이, 과거의 구체적 행동을 묻고, "안 만들 것" 을 받는다.

**우리는**: 인터뷰를 에이전트가 한다. 사실은 에이전트가 찾고, 결정은 당신이 한다.

```
> /grill-with-docs 배당금 캘린더를 CLI 로 만들고 싶다. 종목을 넣으면 다음 배당일이 나오게.
```

라운드 하나가 이렇게 온다:

```
❓ Q1 - 종목의 정체: "종목" 은 티커(AAPL)인가, 내가 가진 보유 목록인가?
➡️ 티커 하나씩. 보유 목록은 나중에 파일로.

❓ Q2 - 데이터 출처: 배당 일정을 어디서 가져오나?
➡️ 공개 API 하나. 어떤 API 가 무엇을 주는지는 내가(서브에이전트로) 확인하겠다 — 답하지 않아도 된다.

❓ Q3 - "다음 배당일" 의 뜻: 배당락일인가 지급일인가?
➡️ 배당락일. 지급일은 v2.
```

답하면 다음 라운드 — 앞 답에 걸려 있던 질문만. 첫 라운드엔 `AGENTS.md` §기획할 때 의 넷이 섞여 온다: **같은 걸 푸는 것이 이미 있나** · 안 만들 것 · 개인정보를 다루나(다루면 멈추고 묻는다).

**답하는 요령**: 추천 답을 그대로 받아도 되지만 **반박이 한 번도 없으면 안 굴린 것**이다 — Matt: *"answering 'agreed, agreed, agreed' for forty questions"* 가 최대 실패. 모르면 *"모르겠다"* — 유효한 답이고 프로토타입이 필요하다는 신호. 46문항 4라운드가 보통이다.

**끝**: *"frontier 가 비었다 — shared understanding"* 하고 **멈춘다. 실행하지 않는다.**

**하지 말 것**: 저장소 안에서 `/grill-me` — 같은 인터뷰인데 기록이 안 남는다.

### ② 설계 — `domain-modeling`(안에서 돈다) · `prototype` · `research` · `to-questionnaire`

**시니어는**: 용어를 하나로 맞추고(ubiquitous language), 되돌리기 어려운 결정만 ADR 에 남기고, 말로 안 정해지는 건 만들어서 본다.

**우리는**: `grill-with-docs` 가 `domain-modeling` 을 안에서 돌린다 — 따로 칠 게 없다.

```
에이전트: "'배당일' 이 아까는 지급일이었는데 지금은 배당락일로 쓰고 있다 — 어느 쪽인가?"
당신:    배당락일.
에이전트: CONTEXT.md 에 기록했다 —
          **배당일**: 배당락일. 이 날 전에 보유해야 배당을 받는다. _Avoid_: 지급일, ex-date
```

ADR 은 셋이 다 참일 때만 제안한다. 대부분 세션은 **ADR 0개**가 정상이다.

말로 안 정해지면 — 에이전트가 `prototype` 을 꺼내거나 당신이 *"프로토타입으로 보자"*:

| 질문 | 나오는 것 |
|---|---|
| "이 상태 흐름·데이터 모양이 맞나" | **HTML 파일 하나** — 더블클릭으로 열리고, 버튼을 눌러 상태가 바뀌는 걸 **비개발자도** 본다. 안의 로직은 나중에 진짜 코드로 옮길 수 있게 순수 모듈 |
| "이 화면이 어때야 하나" | 기존 라우트 위에 **서로 다른 변형 3개**(`?variant=`), 하단 바로 전환 |

끝나면 답 한 줄을 인터뷰에 돌려주고, 프로토타입은 `prototype/<이름>` 브랜치에 남긴다(머지 안 함 · 이슈에서 가리킴).

사실이 필요하면 에이전트가 `research` 를 꺼낸다 — 백그라운드에서 **1차 출처**만 읽고 인용된 md 를 남긴다. 답을 **남이** 알면 `/to-questionnaire` — 그 사람에게 보낼 설문 md 를 만든다(주제가 아니라 *보내는 것*을 나에게 묻는다).

### ③ 스펙 — `/to-spec`

**시니어는**: 결정을 한 문서로 정리한다. 유저 스토리 · 구현 결정 · 테스트 결정 · 범위 밖. 파일 경로는 안 적는다.

**우리는**:

```
> /to-spec
```

인터뷰 없이 지금까지 대화 + 코드베이스 + `CONTEXT.md` 를 **합성**한다. 먼저 **seam**(테스트가 붙는 공개 경계)을 보여준다:

```
테스트할 seam 후보:
  ① `divcal next AAPL` CLI 한 줄 — 입력에서 출력까지 전부 지난다   ← 권장 (하나면 이상적)
  ② `fetch_dividends(ticker)` 함수 경계
어느 쪽으로 갈까?
```

확인하면 이슈 하나를 만들고 `ready-for-agent` 를 단다.

**내가 정하는 것**: seam. *"The ideal number across a change is one."*

**건너뛰기**: 한 세션에 들어가는 일이면 ③④ 를 건너뛰고 바로 ⑤. ⚠️ **①→③→④ 는 한 세션에서** — `/clear`·`/compact` 없이. 긴 스펙이 잘려 나온 사례가 있다.

### ④ 분해 — `/to-tickets`

**시니어는**: 끝까지 관통하는 작은 조각으로 자르고 순서를 정한다. 첫 조각은 걸어다니는 뼈대.

**우리는**:

```
> /to-tickets
```

```
1. 티커 하나로 다음 배당락일 출력 (CLI → API → 출력 → 시험)   Blocked by: 없음   ← walking skeleton
2. 날짜 없는 종목의 오류 메시지                                 Blocked by: 1
3. 보유 목록 파일(.csv)에서 여러 종목                            Blocked by: 1
4. 캐시 — 같은 종목 하루 한 번만 API                             Blocked by: 1

굵기 맞나? 막힘 관계 맞나? 합치거나 나눌 것?
```

판정 질문 하나: **"이 티켓이 끝나면 무엇을 보여줄 수 있나?"** 답이 없으면 수평 슬라이스(스키마 전부 → API 전부)다 — 잘못 잘렸다.

**내가 정하는 것**: 굵기 · 순서 · 합칠지. 승인하면 이슈로 올라간다(GitHub native blocking — 막힘 없는 티켓은 어느 것이든 잡을 수 있다). 인수기준마다 그걸 증명하는 검사를 적는다 — `AGENTS.md` 규칙. 넓은 리팩터(호출부 수백 곳)는 스킬이 알아서 expand → migrate → contract 로 자른다.

### ⑤ 구현 — `/implement` · 티켓마다 반복

**시니어는**: 브랜치를 따고, 실패하는 시험을 먼저 쓰고, 통과할 만큼만 짜고, 작은 PR 로 낸다. 리팩터링은 따로.

**우리는**:

```
> /clear
$ git switch -c feat/next-dividend-date         ← ①
> /implement #1
   … seam 확인 → red → green → 타입체크 → 시험 → code-review 두 축 → 커밋 …
$ gh pr create --fill --draft                    ← ②  CI 는 돈다, 제3자 리뷰는 아직
```

`implement` 는 15줄짜리 스킬이고 본체는 안에서 부르는 `tdd` 다:

```
에이전트: seam 은 스펙대로 `divcal next <ticker>` CLI 경계 하나. 여기서만 시험한다 — 맞나?
당신:    응.
에이전트: 🔴 test_next_prints_ex_date_for_known_ticker … FAILED (아직 구현 없음)
          🟢 최소 구현 → PASSED
          🔴 test_next_unknown_ticker_says_so … FAILED
          🟢 → PASSED
          타입체크 · 전체 시험 통과. code-review 로 넘어간다.
```

한 슬라이스씩, 첫 사이클은 tracer bullet. **리팩터링은 루프에 없다** — 리뷰 단계의 일이다(Matt: *"agents essentially never performed it"*). mock 은 경계에서만(외부 API · 시간 · 난수) — 내 모듈은 안 mock 한다. 기대값은 스펙·알려진 값에서 — 코드처럼 계산하면 동어반복.

**여기서 Matt 의 흐름은 커밋으로 끝난다.** 브랜치·PR 은 안 만든다 — ①② 가 우리 것이다.

**하지 말 것**: 티켓 둘을 한 세션에서. `main` 에 푸시 — 룰셋이 거부한다.

### ⑥ 리뷰 — `code-review`(안에서 돈다) → 제3자 벽

**시니어는**: 작성자와 다른 사람이, 규약과 스펙 두 축으로 본다. 리뷰가 통과를 보증하진 않는다.

**우리는** 두 겹이다:

| | 무엇 | 언제 |
|---|---|---|
| 로컬 `code-review` | `implement` 끝에 **별도 서브에이전트 둘**이 — **Standards**(`CONTRIBUTING.md` + Fowler 냄새 12종) · **Spec**(이슈와 대조: 빠진 요구 · 안 시킨 것 · 틀리게 구현) — 나란히 보고. 합치지 않는다 | 커밋 전 · 몇 번이든 · 고치는 자리 |
| 서버 `third-party / review` | 다른 벤더(코덱스)가 **이 커밋**을 봤다는 **기록** | `gh pr ready` 에서 **한 번** · 확인하는 자리 |

```
$ gh pr ready                                    ← ③  "다 됐다" — 제3자가 이 커밋을 한 번 본다
```

리뷰 단위는 PR 이 아니라 **ready 상태의 HEAD** 다 — draft 에서 0회, ready HEAD 마다 1회. ready 뒤 푸시하면 그 HEAD 는 새 리뷰 대상이다(보통 1~2회, 29회가 아니다). 더 손볼 게 많으면 `gh pr ready --undo`. 리뷰 지적은 **P0·P1 만 처분 의무** — 고쳤다 / 재현 불가 / 범위 밖. *"봤다"* 는 벽이 보증하고 *"읽었다"* 는 당신 몫이다.

### ⑦ 판정 · 머지 — 벽

**시니어는**: 검사가 판정한다. 빨간불이면 못 들어간다. `main` 이 빨개지면 먼저 고친다.

**우리는**: PR 을 열면 `ci / lint · typecheck · test · build · secrets · diff-size · deps`(각각 required) 와 `third-party / review` 가 돈다. **소유자 `--admin` 도 거부된다.** 초록이면 squash 머지 — 이슈는 `Closes #1` 로 자동 종료, 브랜치는 자동 삭제.

**내가 정하는 것**: 머지 버튼 — 그리고 구현 중 **범위 · 위험 · 비용 · AC 가 달라지면** 그 결정. 구현 *방법*은 에이전트가 정한다.

```
> 빨간불이야. `ci / typecheck` 가 실패했어.
에이전트: mypy 가 `fetch_dividends` 반환형을 못 잡았다 — 고치고 푸시한다.
```

`implement` 는 티켓을 **닫아주지 않는다** — 머지가 닫거나 손으로 닫는다.

### ⑧ 릴리스 — 벽과 상자가 한다

**시니어는**: 태그 · 릴리스 노트 · 규격 있는 PR 제목.

**우리는**: PR 제목 `type(scope): 요약` 은 `ci / pr-title` 이 지킨다. 릴리스는 `~/workflows/tools/make-release.sh v0.2.0 왜.md` — **왜**는 당신이 한 줄, **무엇**은 생성. 라이브러리·CLI 는 필요할 때만 — 로컬 도구에 배포를 억지로 붙이지 않는다.

### ⑨ 다음 날 — "계속하자"

**시니어는**: 상태를 사람 머리가 아니라 이슈·PR·CI 에 둔다. 다음 날 누가 와도 이어간다.

**우리는**:

```
> 이 프로젝트 계속 진행해줘
```

세션 시작 훅이 정본 위치와 열린 이슈를 찍고, 에이전트가 **막힘 없는 첫 티켓**부터 잡는다. `/handoff` 는 딱 넷 — 다른 하네스 · 다른 디렉터리 · 다른 사람 · 곁가지를 다른 에이전트에게. 같은 저장소의 다음 날은 이슈가 한다.

**단계 사이에서 뭘 할지** — Matt 의 순서, 첫 "예" 가 답: ① 이어갈 수 있나 → 이어간다 · ② 지금 맥락이 다음에 무관한가 → `/clear` · ③ 옮기나 → `/handoff` · ④ 혼자 돌 수 있나 → 서브에이전트 · ⑤ 그 외 → `/compact`(기본값이지만 첫 선택은 아니다). **단계 중간엔 안 한다.**

## 3. 운영 중 생기는 일 — 상황별

### 뭔가 고장났다 — `diagnosing-bugs`

**시니어는**: 이론보다 재현. 빨간불이 켜지는 명령 하나를 먼저 만든다.

*"이거 왜 깨져?"* 라고 하면 에이전트가 꺼낸다. 여섯 단계, **첫 단계가 전부**:

```
에이전트: 먼저 이 버그에서 빨개지는 명령을 만든다.
          $ uv run pytest tests/test_next.py::test_kr_ticker -x   → FAILED (KeyError 'exDate')   ✓ 빨갛다
          최소화: 티커 하나 · 응답 픽스처 한 줄로 줄여도 여전히 빨갛다.
          가설 (반증 가능한 순서):
            1. 한국 종목은 API 응답에 exDate 키가 없다 → 픽스처에 키를 넣으면 초록
            2. 날짜 파서가 KST 를 못 읽는다 → 미국 종목도 같은 형식이면 빨개야
            3. …
          어느 게 맞을 것 같은가? (도메인 지식으로 순위가 바뀐다)
당신:    1.
에이전트: 회귀 시험 먼저 → 고침 → 초록. [DEBUG-a4f2] 로그 제거. 맞았던 가설을 커밋 메시지에.
```

*"Build the right feedback loop, and the bug is 90% fixed."* 루프를 못 만들면 **가설을 세우지 않고** 당신에게 말한다. 시중 평이 가장 좋은 스킬이다.

### 요청 · 버그 신고가 쌓였다 — `/triage`

**시니어는**: 상태기계로 굴린다 — 평가 필요 → 정보 필요 / 에이전트가 할 수 있음 / 사람이 해야 함 / 안 함.

```
> /triage 뭐가 내 손이 필요해?
> /triage #12 보자
> /triage #12 를 ready-for-agent 로
```

브리핑 전에 셋을 확인한다 — **재현**(실제로) · **중복**(이미 구현됐나, 도메인 개념으로 검색) · **기각 이력**(`.out-of-scope/`). `ready-for-agent` 엔 **agent brief** 를 단다 — 파일 경로·줄 번호 없이 인터페이스·행동·AC·범위 밖으로, 몇 주 뒤 잡아도 살아 있게.

**하지 말 것**: `to-tickets` 가 만든 티켓을 트리아지 — 이미 agent-ready 다. 트리아지는 **내가 안 만든 것**만.

### 너무 커서 안개다 — `/wayfinder`

**시니어는**: 큰 일은 먼저 결정들을 지도로 만든다 — 만들지 않고.

```
> /wayfinder 배당 캘린더를 웹앱으로 — 로그인 · 포트폴리오 · 알림까지. 어디서 시작할지도 모르겠다.
```

기준은 크기가 아니라 **세션 수** — *"wayfinder only makes sense if the work doesn't fit into a single session."* 목적지를 못 박고 → 안개를 훑어 → **map 이슈** 하나 + **결정 티켓**(`grilling` · `prototype` · `research` · `task`)을 만든다. 세션마다 **티켓 하나**만 풀고 닫는다. 걷히면 **만들지 않고 `/to-spec` 으로**.

**시중이 문 것**: *"never really created any prototypes or research tasks, it mainly defaults to wayfinder/tasks … a lot more babysitting"* · 질문이 세 문단 · 27개 티켓이 중간에 무효. **처방**: 목적지를 에픽 하나로 좁힌다 · 프로토타입을 적극 시킨다 · map 안에서 코드를 짜면 멈춘다.

### 코드가 지저분해진다 — `/improve-codebase-architecture`

**시니어는**: 개발이 몰린 뒤 구조를 정리한다. 행동 변경과 섞지 않는다.

```
> /improve-codebase-architecture
```

Matt: *"once a week or after a surge of development."* 최근 커밋이 몰린 곳부터 훑어 **깊게 만들 후보**를 HTML 보고서로(문제 · 해법 · 전후 그림 · Strong/Worth exploring/Speculative). 고르면 인터뷰로 → 새 아이디어 → ①. 어휘는 `codebase-design` — module · interface · depth · seam · adapter · leverage · locality. 핵심 판정 둘: **삭제 시험**(지우면 복잡도가 사라지나, 흩어지나) · **어댑터 하나면 가상의 seam, 둘이면 진짜.**

### 충돌이 났다 — `resolving-merge-conflicts`

rebase/merge 중이면 에이전트가 꺼낸다. 양쪽의 **의도**를 1차 자료(커밋 · PR · 이슈)에서 읽고 hunk 마다 푼다. **`--abort` 안 한다.** 끝나면 검사를 돌린다.

### 사람만 할 수 있다 — `wizard`

시크릿 · 대시보드 클릭 · 일회성 이전. 에이전트가 **URL 을 열고 값을 받아 `.env`·GitHub secrets 에 쓰는 bash 마법사**를 만든다. 한 번 쓰고 버린다.

### 못 알아듣겠다 — `/wait-what`

어느 단계 도중이든. 쉬운 말 + `CONTEXT.md` 용어로 다시 온다. 사후약이다 — 선약은 ①에서 용어를 맞추는 것.

### 스킬이나 `AGENTS.md` 를 고친다 — `writing-for-agents`

모델이 꺼낸다. 핵심 셋: **포인터의 첫 단어가 발화를 정한다** · 항상 로드되는 줄은 매 턴 값을 치른다 · 완료 기준이 흐리면 에이전트가 **일찍 끝낸다.**

## 4. 스킬 35개 — 워크플로 단계에 붙여서

| 단계 | 스킬 | 누가 부르나 | 우리 |
|---|---|---|---|
| 길 찾기 | `ask-matt` | 사용자 | ✅ 뭘 쳐야 할지 모르겠다 |
| ① 기획 | `grill-with-docs` | 사용자 | ✅ **시작점** |
| ① 기획 (저장소 밖) | `grill-me` | 사용자 | ✅ 글 · 사업 판단 |
| ① 안 | `grilling` | 모델 | (안에서 돈다) |
| ② 설계 | `domain-modeling` | 모델 | (안에서 돈다) |
| ② 설계 | `prototype` | 모델 | ✅ 말로 안 정해지면 |
| ② 설계 | `research` | 모델 | ✅ 1차 출처 조사 |
| ② 설계 | `to-questionnaire` | 사용자 | ✅ 남이 아는 답 |
| ③ 스펙 | `to-spec` | 사용자 | ✅ |
| ④ 분해 | `to-tickets` | 사용자 | ✅ |
| ⑤ 구현 | `implement` | 사용자 | ✅ 브랜치·PR 은 우리가 |
| ⑤ 안 | `tdd` | 모델 | (안에서 돈다) |
| ⑥ 리뷰 | `code-review` | 모델 | (안에서 돈다) · 벽 아님 |
| ⑨ 다음 날 | `handoff` | 사용자 | ✅ 넷일 때만 |
| 운영 · 고장 | `diagnosing-bugs` | 모델 | ✅ |
| 운영 · 요청 | `triage` | 사용자 | ✅ 쌓이면 |
| 운영 · 큰 안개 | `wayfinder` | 사용자 | ✅ 세션 수로 판단 |
| 운영 · 정리 | `improve-codebase-architecture` | 사용자 | ✅ |
| 운영 · 정리 | `codebase-design` | 모델 | (안에서 돈다) |
| 운영 · 충돌 | `resolving-merge-conflicts` | 모델 | ✅ |
| 운영 · 사람 | `wizard` | 모델 | ✅ |
| 어디서든 | `wait-what` | 사용자 | ✅ |
| 어디서든 | `writing-for-agents` | 모델 | ✅ |
| 준비 | `setup-matt-pocock-skills` | 사용자 | ⚪ 새 저장소는 상자가 대신 · 기존 저장소만 |
| — | `teach` | 사용자 | ⚪ 엔지니어링 흐름 밖 |
| — | `loop-me` · `claude-handoff` · `setup-ts-deep-modules` · `writing-beats` · `writing-fragments` · `writing-shape` | — | ⚪ in-progress · 플러그인에 안 실린다 |
| — | `git-guardrails-claude-code` · `setup-pre-commit` | — | 🚫 훅 층 · `--no-verify` 로 넘어간다 · 벽이 서버에서 한다 · Matt 도 *rarely use* |
| — | `migrate-to-shoehorn` · `scaffold-exercises` | — | 🚫 Matt 개인(TS · 강의) |

## 5. 자주 하는 실수 — 문서와 시중이 같이 지적한 것

| 실수 | 왜 나쁜가 | 대신 |
|---|---|---|
| 인터뷰에 *"네, 네, 네"* | 정렬이 안 된 채 정렬됐다고 믿는다 | 한 번은 반박. 모르면 "모르겠다" |
| 저장소 안에서 `/grill-me` | 기록이 안 남는다 | `/grill-with-docs` |
| `to-spec` 과 `to-tickets` 사이에 `/clear` | 티켓이 스펙과 다른 생각 위에 선다 | 한 세션에서 |
| 티켓 12개 / 코드 3줄 | 과분해 | 퀴즈에서 합친다. 한 세션이면 `/implement` 바로 |
| 수평 슬라이스 | 시연할 게 없다 | *"끝나면 뭘 보여줄 수 있나"* |
| 기대값을 코드처럼 계산한 시험 | 구성상 통과 | 기대값은 스펙·알려진 값에서 |
| 내 모듈을 mock | 리팩터에 깨진다 | mock 은 경계에서만 |
| `to-tickets` 결과를 `/triage` | 이미 agent-ready | 트리아지는 남이 만든 것만 |
| 잘 잡힌 기능에 `/wayfinder` | 느리고 무겁다 | `grill-with-docs` |
| wayfinder 안에서 코드 짜기 | 지도가 build 가 된다 | 멈추고 `/to-spec` 으로 |
| 단계 중간에 `/compact` | 맥락을 잃는다 | 경계에서, 그리고 마지막 선택으로 |
| 스펙에 파일 경로·코드 | 금방 낡는다 | 인터페이스·행동으로 |
| `implement` 뒤 `main` 에 푸시 | 룰셋이 거부 | 브랜치 → draft PR → ready |
| 리뷰 지적을 안 읽고 머지 | *봤다* ≠ *읽었다* | P0·P1 처분 셋 중 하나 |

## 6. 우리 벽과 맞물리는 자리

Matt 의 스킬은 에이전트 안쪽에 살고 커밋에서 끝나며 판정을 안 한다. 우리 벽은 서버에 살고 PR 에서 시작하며 판정만 한다. 겹치는 데가 없어서 부딪힐 데도 없다 — 닿는 자리가 넷이고 전부 채워져 있다.

- **브랜치 · PR** — `implement` 는 커밋에서 끝난다. ⑤⑥ 의 세 줄이 우리 것. `AGENTS.md` 에도 적혀 있다
- **라벨** — `ready-for-agent` 등 5개를 `new-project.sh` 가 만든다. 어느 스킬도 안 만든다
- **`CONTRIBUTING.md`** — `code-review` 의 Standards 축이 읽는다. 상자가 주고 시험이 내용을 지킨다
- **`AGENTS.md` §기획할 때** — 이미 있나 · 유도 질문 금지 · 안 만들 것 · 개인정보 hard-stop. 인터뷰가 도는 세션에 이미 로드돼 있다
- **리뷰는 ready HEAD 마다 한 번** — draft 에서 고치고 ready 에서 본다. `standards` 는 advisory, 제품 저장소는 벽

## 근거

- 현업 관행: `coolbress/standards` `direction/03`(리서치) · `04`(리서치에서 나온 수치 — `CR-001~003` `TDD-001` `CIB-001` `GHW-009·010·012` `IPW-006·007·019`) · `05`(산출물 바닥 12묶음 · 머지 방법 · PR 제목 · 릴리스 노트) · `07`(원칙 넷)
- `mattpocock-skills` 1.2.3 — SKILL.md 35개 · `PHASE-BOUNDARIES` · `AGENT-BRIEF` · `OUT-OF-SCOPE` · `DEEPENING` · `DESIGN-IT-TWICE` · `LOGIC`/`UI` · `tests`/`mocking` · `CONTEXT-FORMAT`/`ADR-FORMAT` · `SKILL-MECHANICS`
- Matt 공식 문서: [5 Agent Skills I Use Every Day](https://www.aihero.dev/5-agent-skills-i-use-every-day) · [grill-me](https://www.aihero.dev/skills-grill-me) · [grill-with-docs](https://www.aihero.dev/grill-with-docs) · [to-spec](https://www.aihero.dev/skills-to-spec) · [to-tickets](https://www.aihero.dev/skills-to-tickets) · [tdd](https://www.aihero.dev/skills-tdd) · [wayfinder](https://www.aihero.dev/skills-wayfinder) · [prototype](https://www.aihero.dev/skills-prototype) · [triage](https://www.aihero.dev/burn-through-your-backlog-with-my-triage-skill) · [handoff](https://www.aihero.dev/skills-handoff) · [domain-model](https://www.aihero.dev/skills-domain-model)
- 시중: [Alex Rusin — main flow 걸어보기](https://blog.alexrusin.com/matt-pocock-skills-main-flow/) · [Jerryskills — GSD·Superpowers 에서 갈아탄 이유](https://jerrysmd.github.io/20260812_matt-pocock-skills-vs-gsd-superpowers/) · [Kaizen Craft — 비판적 가이드](https://kaizencode.art/notepad/matt-pocock-skills-guide/) · [wayfinder 토론 #484](https://github.com/mattpocock/skills/discussions/484) · [Theo](https://www.youtube.com/watch?v=0oXOOlqVu5M) · [Eric Tech](https://www.youtube.com/watch?v=8D8ewFBJfFM)
