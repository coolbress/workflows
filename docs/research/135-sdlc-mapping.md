# R-SDLC — Anthropic AI-native SDLC 6단계 × mattpocock 스킬 × plinth 구성요소 × 코퍼스 근거

> 티켓 [#135](https://github.com/coolbress/workflows/issues/135) · 부모 스펙 [#99](https://github.com/coolbress/workflows/issues/99) · 지도 [#82](https://github.com/coolbress/workflows/issues/82)
> 조사일 2026-09-03 · 1차 출처 직접 열람
>
> 🔴 **벤더 처방이지 표준이 아니다.** 아티클은 **뼈대**로만 쓰고, *왜* 그 관행인지는 코퍼스를 인용한다.
> 🔴 **이름을 베끼지 않는다.** `intent.md` · `spec.md` · `plan.md` · `REVIEW.md` · `bands.yaml` 은
> 우리 스택의 **기존 자리에 매핑**할 뿐, 그 파일들을 만들지 않는다. 우리 아티팩트 사슬은
> **아이디어 → 그릴링(`CONTEXT.md` · ADR) → 스펙 이슈 → 티켓 이슈 → PR → 릴리스** 하나다.

## 출처

| 표기 | 무엇 |
|---|---|
| **A** | Anthropic, [The AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (2026-08-21) — 영어 원문 인용 |
| **S** | `mattpocock-skills` **1.2.3** (공식 마켓 · 로컬 캐시) — `README.md` · `skills/*/*/SKILL.md` frontmatter |
| **P** | plinth 전신 셋 — `~/workflows`(`ruleset.json` · `python-ci.yml` · `pr-review.yml` · `new-project.sh` · `tools/make-release.sh` · `plugins/`) · `~/project-template` |
| **C** | `~/standards/corpus/aspects/` — `27-ai-harness-archetype` · `28-implementation-process-workflow` · `05-scm-workflow/github-workflow-current` · `24-governance-collaboration-compliance` |
| **V** | 영상 두 편 자막 요지 — #135 코멘트(Matt Pocock end-to-end · Switch Dimension INTENT.MD 해설) |

---

## 1. 매핑표 — 6단계 × 6열

열: **(a)** 아티클의 처방(아티팩트 · 사람/에이전트 · 게이트) **(b)** 우리 자리의 그 아티팩트
**(c)** mattpocock 스킬(**U**=user-invoked · **M**=model-invoked) **(d)** plinth 구성요소
**(e)** 코퍼스 근거 **(f)** 격차 + 판정

| 단계 | (a) 아티클 | (b) 우리 아티팩트 | (c) 스킬 U / M | (d) plinth | (e) 코퍼스 | (f) 격차 · 판정 |
|---|---|---|---|---|---|---|
| **Plan** | `intent.md`(발의자의 말 그대로, 버전 관리). 발의자 ↔ Claude 브레인스토밍 → Claude 초안 → **PO 가 커밋 전에 고친다**. 게이트 = PO 승인 + 백로그 트리아지.<br>*"Intent is captured once, in the originator's own words"* · *"the product owner reviews and corrects the agent-written `intent.md` before it is committed"* | **파일 없음.** intent 는 `/grill-with-docs` 대화 + 그 산물(`CONTEXT.md`, 드물게 ADR). **커밋되는 intent 의 자리 = GitHub 이슈**. 🔴 가변 상태의 정본은 파일이 아니라 `gh issue list` | **U** `grill-with-docs`(*"A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go."*) · `grill-me`(저장소 밖) · `wayfinder`(*"more than one agent session"*) · `triage`(남이 만든 것만) · `to-questionnaire`<br>**M** `grilling` · `research` | 문 `new-project` 가 **트래커·라벨 5개·`docs/agents/*.md` 를 미리 채운다** → `/setup-matt-pocock-skills` 불필요 · 상자의 이슈 폼(bug·feature·task) · 훅 프로필 `plinth-hooks` SessionStart 가 *"정본은 `gh issue list`"* 를 찍는다 | **28** *"Plan before acting — and the plan is an artifact … persist it (file/state), don't keep it only in context"* · **24** self-contained remote artifacts(원격 산출물은 로컬 문서를 인용하지 않는다) · **05** `GHW-012` 이슈 우선은 **크기 조건부**(*"size-conditional, NOT universal"*) | 발의자(비개발자 · 고객 · PM)가 채널·폼으로 인터뷰에 들어오는 경로 없음 → **범위 밖** (지원 범위 = 단일 소유자 · 설치자 1인, #87) |
| **Design** | `spec.md`. Claude 가 승인된 intent 에서 스펙 생성, **조직 스킬(브랜드·보안)이 스펙 작성 중에 정책을 적용**. PO 승인, 위험 항목은 정책 담당·테크리드로 escalate.<br>*"Policy is applied while the spec is written, not discovered in a review weeks later"* · *"The product owner decides whether the spec and intent progress to build"* | **`spec.md` 없음.** 스펙 = **`ready-for-agent` 라벨이 붙은 이슈 하나**(문제 · 해법 · 유저 스토리 · 구현/테스트 결정 · 범위 밖). 되돌리기 어려운 결정 = `docs/adr/` · 용어 = `CONTEXT.md`. 스펙에 파일 경로·코드를 안 적는다 | **U** `to-spec`(*"Turn the current conversation into a spec and publish it to the project issue tracker: no interview, just synthesis"*)<br>**M** `domain-modeling` · `prototype` · `research` · `codebase-design` | 정책이 스펙 작성 중에 적용되는 자리 = **`AGENTS.md` §기획할 때**(이미 있나 · 유도질문 금지 · 안 만들 것 · 개인정보 hard-stop) + `CONTRIBUTING.md` — **상자가 인스턴스마다 심는다**. 벽은 여기 없다 | **24** *"Decision rights are recorded, not tribal"* · ADR 은 **진짜 결정만**(ADR-for-everything ruled out · census 2–4%) · **27** agent constitution(`AGENTS.md`/`CLAUDE.md`, canonical 75%) · **28** plan-as-artifact | 정책이 **산문**(`AGENTS.md`)이지 스킬로 강제되지 않는다 → **한다** (새 스킬이 아니라 #99 §7 의 `docs/reference` 한 자리로 규칙을 모으는 일. 이미 스펙에 있다) |
| **Build** | `plan.md`(바꿀 파일 · 순서 · 시험 · 위험) + `CLAUDE.md` + 스킬. 엔지니어가 **plan mode** 로 시작 → Claude 가 인터뷰 → **엔지니어가 코드 전에 승인** → 구현. 훅이 결정적 층, permission 이 도구 접근, worktree 병렬, 서브에이전트.<br>*"The engineer corrects the plan before code is written, and the approved version is committed as `plan.md`"* · *"One engineer runs several Claude sessions at once, each in its own worktree"* · hooks *"can block edits to protected paths"* | **`plan.md` 없음 — 둘로 갈린다.** 경로 = `/to-tickets` 가 만든 **티켓 이슈**(수직 슬라이스 + Blocked by), 그 안의 계획 = `/implement` 가 세션에서 세운다. *"증명 = 성공 기준"* = **AC 마다 그것을 증명하는 검사를 적는다**(`AGENTS.md` 규칙). 산출물 = 브랜치 → **draft PR**.<br>⚠️ **V**: Matt 는 plan mode 대신 **그릴링**으로 계획을 심문한다 — 같은 기능, 다른 도구 | **U** `to-tickets` · `implement` (둘 다 `disable-model-invocation: true`) · `handoff`<br>**M** `tdd` · `codebase-design` · `diagnosing-bugs` · `resolving-merge-conflicts` · `wizard`(*"steps only they can perform"*) | 인스턴스 `.claude/settings.json` 의 **deny**(비밀 읽기 · force push · `rm -rf`) = 아티클의 permissions 대응 · 훅 프로필 `plinth-hooks`(SessionStart, **옵트인**) · 상자의 `CONTRIBUTING`. **벽은 아직 안 닿는다** — 커밋까지는 전부 로컬 | **28** *"Coordinator + context-isolated workers"*(worktree · CAID +26.7pp · Lost-in-the-Middle) · *"Human-in-the-loop before irreversible/outward actions"* · DORA small batches · **27** skills/hooks 패키징 | 아티클은 훅을 **Build 의 결정적 층**(보호 경로 편집 차단 · 완료 시 plan 갱신)으로 쓴다. 우리 훅은 SessionStart 문구 하나 → **범위 밖** — 집행은 **에이전트 밖(서버)** 에서 한다는 게 설계이고 로컬 훅은 `--no-verify`·설정 편집으로 넘어간다. 실행 피해 차단은 deny 로 이미 있다 |
| **Test** | 에이전트가 **사람 전에** 자기 일을 검사하고 고친다(테스트 · 빌드 · 스크린샷 diff) · verifier 서브에이전트 · **eval 스위트**를 플랫폼 팀이 유지, **`CLAUDE.md`·스킬·훅이 바뀌면 CI 에서 돈다**.<br>*"Always give Claude a way to verify its own work, whether tests, a build, or a screenshot diff"* · *"The suite runs non-interactively in CI on a schedule and on any change to `CLAUDE.md`, skills or hooks"* · *"Each production incident gets an eval"* | 두 겹. 세션 안 = `tdd` 의 red→green + 타입체크 + 로컬 `code-review`. 서버 = **PR 의 검사 결과 자체가 아티팩트**. 회귀 세트 = `tests/*.sh` 16종 + `canary/` | **M** `tdd`(*"red-green-refactor"*) · `diagnosing-bugs` · `code-review`(Standards 축)<br>**U** 없음 — `/implement` 안에서 돈다 | **벽 = `ruleset.json` 의 9 required checks**: `ci / pr-title` · `lint` · `typecheck` · `test` · `build` · `secrets` · `deps` · `diff-size` + `CodeQL`. 재사용 `python-ci.yml`(잡 이름 = 검사 이름) · `all-tests-are-wired` 가 배선을 강제 | **28** *"Verify against objective signals, not self-assessment"*(Reflexion · 내재적 자기교정 불신) · **27** *"Gate behavior with a reproducible eval suite, not vibes"* · **05** *"A green check is not proof that requirements are satisfied"* | **스킬·훅·`AGENTS.md` 가 바뀔 때 도는 eval 이 없다** → **한다 · 대기(P7)** — #99 §Testing 에 `ci / evals`(playbook · floor-check 각 3~5 케이스)로 이미 들어가 있고, `claude plugin eval` 케이스 형식은 **공개 문서가 없어 손 확인 항목 ③** 이다 |
| **Deploy** | PR + 다중 패스 리뷰(버그 · 보안 · 스펙 준수) · **`REVIEW.md`** 가 리뷰 정책 · 코드오너 승인 · 배포 승인 훅 · **managed settings**(org 전역, 엔지니어가 못 고침).<br>*"the agent that wrote the code has no way to approve it"* · *"Anything the agent writes arrives as a PR through branch protection, and the agent has no route to push to main"* · *"The tech lead writes the review policy as `REVIEW.md` at the repo root"* · *"Managed settings… engineers cannot edit or override any of it"* | **`REVIEW.md` 없음** — 그 자리는 **`AGENTS.md` §Code Review Rules**(제3자 리뷰어가 실제로 읽는 절: 보고하지 마라 / 보고해라 / 규율)와 `CONTRIBUTING.md`(Standards 축). 완료 = **머지된 커밋**. 릴리스 = 태그 + 사람이 쓴 *왜* | **M** `code-review`(*"two axes: Standards … and Spec … in parallel sub-agents"*)<br>**U** 없음 | 벽: `main` 직접 푸시 금지 · `--admin` 도 거부(`bypass_actors: []`) · 9 검사 · **`third-party / review`**(`pr-review.yml` · `userConfig.reviewer` = auto·codex·none) · `ci / pr-title` 11종 · `tools/make-release.sh`(**빈 노트파일 거부**) | **28** *"Gate merges behind adversarial, cross-vendor review"* — self-preference bias(NeurIPS'24 oral) · PoLL 다양성 · cross-context review **+16% F1** · **24** *"Ownership + review are enforced by the platform, not by hope"*(branch-protection **13% strong** = 야생에서 가장 약한 통제) · **05** `GHW-013` `--match-head-commit` | ① **managed settings** → **범위 밖**(org/MDM 전용 · 설치자 1인 · #99 Out of Scope 의 org 전용 항목과 같은 이유) ② **배포 승인 훅 / production gate** → **범위 밖**(우리 배포 단위는 git 자체, #99 §8) |
| **Maintain** | **결정적 감지**(모델 없음)가 control band 를 본다 → 2σ 진단(읽기 전용) · 3σ 제안(PR 또는 runbook) → 에이전트가 **`intent.md` 를 써서 Plan 으로 되돌린다**. 온콜이 트리아지. Claude Tag 가 채널의 1차 대응.<br>*"The loop closes. A trigger invokes Claude with no person in the invocation path"* · *"Detection stays entirely deterministic, with no model involved"* · *"The agent writes its diagnosis as `intent.md` in the Stage 1: Plan format"* | **루프를 사람이 연다.** 버그는 사람이 알아채 `/diagnosing-bugs`, 요청은 `/triage`, 부패는 `/improve-codebase-architecture` → 결과가 다시 이슈(=Plan). 자동 기동 없음 | **U** `triage` · `wayfinder` · `improve-codebase-architecture`<br>**M** `diagnosing-bugs`(*"reports something broken/throwing/failing/slow"*) · `research` | `/floor-check`(**읽기 전용을 장치로 집행** — `disallowed-tools: Edit, Write, NotebookEdit`) · Dependabot(재사용 워크플로 SHA) · `measure-ci-shape.yml`. **결정적 감지는 없다** | **28** *"Bound failure: circuit-breakers + oscillation detection"* · **24** *"the PR + review trail **is** the change-management artifact"* · **05** `GHW-004` revert 는 새 PR · **27** 하네스 자신이 ③을 도는 기계 | ① **결정적 감지 → 헤드리스 기동 → intent 생성** → **범위 밖**(우리는 배포도 런타임도 소유하지 않는다 — 관측 대상이 없으면 control band 도 없다) ② **DORA 용 아티팩트 버전·이력** → **부분적으로 한다**(태그 · CHANGELOG · PR 이력 · 플러그인 `version`+마켓 항목은 이미 있다. **지표 산출은 범위 밖**) |

### 격차 판정 — 모아서

| # | 아티클이 처방하는데 우리에게 없는 것 | 판정 | 한 줄 이유 |
|---|---|---|---|
| 1 | 스킬·훅·`AGENTS.md` 변경 시 도는 **CI eval** | **한다 (대기)** | #99 §Testing 의 `ci / evals` 로 이미 스펙에 있다. `claude plugin eval` 케이스 형식이 공개 문서에 없어 **P7 손 확인** 뒤에 배선한다 |
| 2 | 정책(브랜드·보안)이 **스펙 작성 중에** 적용 | **한다** | 새 스킬을 만들지 않는다 — 규칙 본문을 `docs/reference` 한 자리로 모으고 `AGENTS.md` 가 가리킨다(#99 §7 *"규칙은 한 자리"*) |
| 3 | **managed settings**(org 전역 · 우회 불가) | **범위 밖** | org/MDM 이 있어야 성립한다. 설치자 1인·개인 계정이라 걸 자리가 없다 — required workflows·SHA 핀 강제와 같은 이유(#99 Out of Scope) |
| 4 | **Build 의 훅**(보호 경로 차단 · 완료 시 plan 갱신) | **범위 밖** | 집행은 에이전트 밖(서버)에서 한다는 설계 원칙. 로컬 훅은 `--no-verify`·설정 편집으로 넘어간다. 실행 피해는 인스턴스 `settings.json` **deny** 가 이미 막는다 |
| 5 | **Maintain 의 결정적 감지**(band → 헤드리스 → `intent.md`) | **범위 밖** | 배포도 런타임도 우리 것이 아니다. 관측 대상이 없으면 control band 가 성립하지 않는다 |
| 6 | 배포 승인 훅 / production gate | **범위 밖** | 배포 단위가 git 자체다(#99 §8) — 승인할 배포가 없다 |
| 7 | **DORA 용 아티팩트 버전·이력** | **부분적으로 한다** | 버전·이력은 이미 있다(SemVer 태그 · CHANGELOG · PR · `plugin.json`+마켓 동시 상승). **지표 산출·대시보드는 범위 밖** |
| 8 | 발의자(비개발자) 인터뷰 진입로 | **범위 밖** | 지원 범위가 단일 소유자다(#87). PO·테크리드·릴리스 매니저 역할이 전부 한 사람이다 |

### 사람이 "예" 하는 자리 vs 검사가 "아니오" 하는 자리

> **A**: *"Humans remain accountable for every decision that requires judgment."* · *"The loop keeps running. Human judgement stays above it."*

| 단계 | 사람이 승인하는 것 | 벽이 막는 것 |
|---|---|---|
| Plan | 인터뷰의 **결정 전부**(사실은 에이전트) · 안 만들 것 · 이슈를 열지 말지 | — |
| Design | seam · ADR 을 남길지 · `ready-for-agent` 를 달지 | — |
| Build | 범위 · 위험 · 비용 · AC 가 달라지는 순간 · draft → `gh pr ready` | 인스턴스 `settings.json` **deny**(비밀 읽기 · force push · `rm -rf`) — 로컬, 우회 가능 |
| Test | 없음 — **판정은 사람이 하지 않는다** | `ci / lint` · `typecheck` · `test` · `build` · `secrets` · `deps` · `diff-size` |
| Deploy | 머지 버튼 · 리뷰 지적 P0·P1 처분 · 릴리스 노트의 *왜* | `ci / pr-title` · `CodeQL` · `third-party / review` · `main` 직접 푸시 금지 · `--admin` 거부 · `make-release.sh` 의 빈 노트 거부 |
| Maintain | **루프를 여는 것 자체**(감지가 사람이다) | — (Dependabot PR 도 같은 벽을 지난다) |

**모양이 아티클과 같다** — 게이트는 사람 승인, 집행은 Test·Deploy 에 몰린다. 다른 곳은 딱 둘: 아티클은 **Build 에 훅**이 있고 **Maintain 에 결정적 감지**가 있다(격차 4·5).

⚠️ **`third-party / review` 는 `ruleset.json` 의 9 검사에 없다** — 별도 검사로 돌고 룰셋이 요구하지 않는다(2026-09-03 `ruleset.json` 확인). GUIDE 의 *"제3자 벽"* 표현은 **요구 검사**를 뜻하지 않는다. 문서로 옮길 때 이 문장을 그대로 옮기면 안 된다.

---

## 2. 9단계 → 6단계 접기

### 지금 GUIDE 의 ①–⑨ (+ 0단계)

| 지금 | 6단계 | 무엇이 옮겨지나 |
|---|---|---|
| **0 준비** `/new-project` | **없음 (stage 0)** | 🔴 아티클엔 **자리가 없다** — 저장소가 이미 있다고 가정한다. 우리 문·상자·벽은 여섯 단계 **앞**에 선다 |
| ① 기획 | **Plan** | 그대로 |
| ② 설계 | **Design** | 그대로 (용어 · ADR · 프로토타입) |
| ③ 스펙 | **Design** | 🔴 **올라간다.** 아티클에서 spec 은 Design 의 산물이다 — 우리 ②③ 이 한 단계로 합쳐진다 |
| ④ 분해 | **Build** | 🔴 **내려간다.** 티켓 = 아티클 `plan.md` 의 *경로* 절반 |
| ⑤ 구현 | **Build** | 그대로. `plan.md` 의 나머지 절반은 `/implement` 세션 안 |
| ⑥ 리뷰 | **Build + Deploy** | 🔴 **갈린다.** 로컬 `code-review`(작성자 자신의 루프) = Build · `third-party / review`(다른 벤더가 이 커밋을 봤다) = Deploy |
| ⑦ 판정·머지 | **Test + Deploy** | 🔴 **갈린다.** `ci / *` 가 도는 것 = Test(에이전트가 사람 전에 검사) · 머지 버튼과 벽 = Deploy |
| ⑧ 릴리스 | **Deploy** | 그대로 |
| ⑨ 다음 날 · 운영 | **Maintain → Plan** | 아티클 Maintain 과 **다르다** — 우리 루프는 **사람이 연다**(격차 5) |

### §3 상황별 → 6단계

| 상황 | 치는 것 | 단계 |
|---|---|---|
| 뭘 쳐야 할지 모르겠다 | `/ask-matt` | 전 단계 (라우터) |
| 말로 못 정하겠다 | `/prototype` | Design |
| 답을 남이 안다 | `/to-questionnaire` | Plan / Design |
| 못 알아듣겠다 | `/wait-what` | 전 단계 |
| 뭔가 고장났다 | `/diagnosing-bugs` | **Maintain → Plan** |
| 요청·버그가 쌓였다 | `/triage` | **Maintain → Plan** |
| 너무 커서 안개다 | `/wayfinder` | **Plan** (결정만 하고 안 만든다 → `/to-spec` 으로 합류) |
| 코드가 지저분해진다 | `/improve-codebase-architecture` | **Maintain → Plan** |
| 충돌이 났다 | `resolving-merge-conflicts` | Build |
| 사람만 할 수 있다 | `wizard` | 전 단계 (전형은 Deploy 의 시크릿 등록) |
| 기존 저장소에 바닥이 있나 | `/floor-check` | **stage 0** (또는 인수 시 Maintain) |
| 넘긴다 | `/handoff` | 단계 **경계** |

### 갈림길과 clear 규율 (**V** + `ask-matt/SKILL.md`)

```
/grill-with-docs  (auto 모드 — 그릴링이 곧 계획 심문. plan mode 아님)
        │
        ├─ 남은 예산이 smart zone 안 · 한 세션에 들어간다
        │       └─▶ /implement 바로 — 같은 컨텍스트 창에서
        │
        └─ 여러 세션이 필요하다
                └─▶ 같은 세션에서 /to-spec → /to-tickets   ← 여기까지 끊지 않는다
                        └─▶ /clear → 티켓마다 /implement @ticket → 티켓 사이마다 /clear
                                └─▶ 끝에 code-review 로 스펙 대조
```

- **판정 기준은 크기가 아니라 세션 수** — *"is this a multi-session build?"* (`ask-matt/SKILL.md`)
- **한 컨텍스트 창** — *"Keep steps 1–3 in one unbroken context window (don't compact or clear until after `/to-tickets`)"*
- **smart zone** — `ask-matt/SKILL.md` 는 *"~150k tokens on state-of-the-art models"*, **V**(영상)는 **≈140k**. ⚠️ **두 숫자가 다르다 — 파일이 정본이다.** 닿으면 *"don't push on degraded; `/compact` at the nearest phase boundary"*
- **스펙 = 목적지, 티켓 = 경로, 티켓 하나 = 컨텍스트 창 하나** (**V**). 티켓 AC 는 대부분 스펙에 있고 티켓은 *"이 세션에서 무엇을 만드나"* 만 적는다

---

## 3. `playbook` 스킬 · GUIDE → 어디로 (처분표)

> 🔴 **전제 변경**: 소유자가 [#136](https://github.com/coolbress/workflows/issues/136) 에서 **`playbook` 스킬을 없애기로** 결정했다.
> 라우팅의 원본은 `/ask-matt` 이고, 우리만의 줄은 스킬이 아닌 자리로 간다.
> 아래는 #136 의 AC *"어느 줄이 어디로 갔는지 표로 남긴다"* 를 채우는 표다. **작성 자체는 D1/D2/D3.**

**행선지 코드**

| 코드 | 어디 |
|---|---|
| **(a)** | `/ask-matt` 가 이미 답한다 → **버린다** (사본을 두면 Matt 가 바꿀 때 우리 것만 썩는다) |
| **(b)** | **`AGENTS.md` "다음 한 수" 세 줄** — plinth 자신 + 템플릿이 인스턴스에 심는 `AGENTS.md`(둘 다 ≤60줄) |
| **(c)** | 인스턴스 **`CONTRIBUTING` PR 흐름 절** — draft → ready → ready HEAD 마다 제3자 리뷰 · 티켓 = 세션 = PR |
| **(d)** | **docs 페이지**(#99 §7 목록에서 이름을 지정) |
| **(e)** | **삭제** |

### 3-1. `playbook/SKILL.md`

| # | 줄 · 규칙 | 행선지 | 메모 |
|---|---|---|---|
| 1 | frontmatter `description` — 한국어 트리거(*"다음은 뭐 하지" · "어디까지 왔지"*) + *"Reads the map, tells the user the next command, never runs it for them"* | **(b)** | 트리거는 영어로 옮긴다. 스킬이 사라지므로 **모델이 헤매는 사용자를 잡는 구멍**을 `AGENTS.md` 가 맡는다 |
| 2 | *"산출물의 인수 강제는 GitHub 벽만 한다 — 이 지도는 전부 '이렇게 하면 좋아요'"* | **(d)** | explanation **`what-the-wall-does-and-does-not-do`** |
| 3 | *"로컬 실행 피해(비밀 읽기·force push·`rm -rf`)는 템플릿 `.claude/settings.json` deny 가 막는다. 벽은 그걸 되돌려주지 못한다"* | **(d)** | explanation **`what-plinth-installs`** (+ `what-the-wall-does-and-does-not-do` 교차) |
| 4 | *"작업 스킬은 `mattpocock-skills` 를 재사용 — 우리가 만든 건 진입과 문뿐"* | **(d)** | explanation **`why-this-exists`** |
| 5 | `GUIDE.md` 포인터(*"그 절을 읽고 답한다"*) | **(e)** | GUIDE 가 사라진다 |
| 6 | 할 일 1 — 상태를 읽는다(`gh issue list` · 브랜치 · 열린 PR) · **상태를 파일에 쓰지 않는다** | **(b)** | 세 줄의 1행 |
| 7 | 할 일 2 — 표에서 **다음 한 수 하나**를 말한다 | **(b)** | 세 줄의 2행 |
| 8 | 할 일 3 — 사용자 전용 커맨드는 **실행한 척하지 않는다** | **(b)** | 세 줄의 3행 |
| 9 | 할 일 4 — 아주 작은 수정이면 인터뷰·스펙을 건너뛴다(**기준은 크기**) | **(d)** | explanation **`working-with-agents`**. ⚠️ `ask-matt` 의 기준은 **세션 수**, 우리 기준은 **크기**(`05` `GHW-012`) — 두 문장이 다르다. 문서에 둘 다 적는다 |
| 10 | 한눈에 표 **0행** — `/new-project` · 벽 선 저장소 · `docs/agents/*.md` · 라벨 · 공개 여부·라이선스 | **(d)** | tutorial **`getting-started`** + how-to **`create-a-new-project`** |
| 11 | 1행 생각 `/grill-with-docs` · 3행 티켓 `/to-tickets` · *"작으면 2·3 을 건너뛴다"* · *"1→2→3 은 한 세션에서"* | **(a)** | `ask-matt` §main flow + §Context hygiene 이 원본 |
| 12 | 2행 스펙 — **`ready-for-agent` 라벨**이 끝났다는 신호 | **(d)** | 라벨 이름은 우리 것 → explanation **`what-plinth-installs`** |
| 13 | 4행 만들기 — `/clear` → 브랜치 → `/implement #N` → **draft PR** → `gh pr ready` | **(c)** | |
| 14 | 4행 — *"사람이 정하는 것: 범위·위험·비용·AC 가 달라지면. 그리고 머지 버튼"* | **(c)** | |
| 15 | 5행 다시 열 때 — *"계속하자"* → 막힘 없는 첫 티켓 | **(b)** | |
| 16 | §4단계 3줄 블록 — *"`implement` 는 현재 브랜치에 커밋하고 끝난다. 우리 벽은 PR 에서 시작한다"* | **(c)** | 이 문단이 **(c)** 절의 뼈대다 |
| 17 | *"고치는 자리는 draft, 확인하는 자리는 ready"* · **리뷰 단위 = ready HEAD**(draft 0회 · ready HEAD 마다 1회) · `gh pr ready --undo` | **(c)** | |
| 18 | *"빨간불이면 머지가 안 된다"* · 리뷰 지적은 **P0·P1 만 처분 의무**(고쳤다/재현 불가/범위 밖) | **(c)** | 검사 이름 목록 자체는 reference **`required-checks`** 가 정본 |
| 19 | **티켓 하나 = 세션 하나 = PR 하나** | **(c)** | `AGENTS.md` 에도 한 줄 |
| 20 | §곁길 표 — `ask-matt` · `prototype` · `to-questionnaire` · `wait-what` · `diagnosing-bugs` · `triage` · `wayfinder` · `improve-codebase-architecture` · `handoff` 행 | **(a)** | 전부 `ask-matt` 에 있다 |
| 21 | §곁길 표 — **`/floor-check` 행** | **(d)** | how-to **`check-an-existing-repo`** |
| 22 | §단계 사이에서 헷갈리면 (5택 ①–⑤) | **(a)** | `ask-matt` §Phase boundaries + `PHASE-BOUNDARIES.md` 가 원본이고 **이유까지 적혀 있다** |
| 23 | §하지 말 것 — 저장소 안 `/grill-me` · `to-tickets` 결과를 `/triage` · 잘 잡힌 기능에 `/wayfinder` · 티켓 둘을 한 세션에서 | **(a)** | |
| 24 | §하지 말 것 — **상태를 파일에 적기. 정본은 `gh issue list`** | **(b)** | 우리 규칙이다 |

### 3-2. `GUIDE.md` — plinth 고유 절

| # | 절 · 내용 | 행선지 | 메모 |
|---|---|---|---|
| 25 | §0 표 *"깔려 있는 것 / 우리가 만든 것"* | **(d)** | explanation **`what-plinth-installs`** |
| 26 | §0 *"Matt 의 스킬은 검토하고 핀한 외부 워크플로 의존성이다 — 판이 올라가면 갈릴 수 있다"* + 드리프트 시험 | **(d)** | explanation **`design-rules`** (+ reference `commands-and-skills`) |
| 27 | §0 **사용자 전용 / 모델 호출 스킬 목록** | **(e)** | 🔴 사본을 두지 않는다 — 정본은 `mattpocock-skills` README + frontmatter. 드리프트 시험이 **문서를 대상으로** 이름만 본다(#136 AC) |
| 28 | §0 *"외울 것 셋"*(`/ask-matt` · `/grill-with-docs` · `/implement #N`) | **(b)** | |
| 29 | §1 현업 워크플로 9단계 그림 + **단계마다 시니어가 지키는 것 · 왜**(근거 열) | **(d)** | explanation **`working-with-agents`** (≤150줄 — #99 §7). *왜* 만 남기고 근거는 lab 링크 |
| 30 | §1 *"에이전트와 일할 때 달라지는 것 넷"* + 원칙 다섯 | **(d)** | explanation **`working-with-agents`** |
| 31 | §2 준비 — `with-admin-token.sh` + `new-project.sh` 실행 예 | **(d)** | how-to **`create-a-new-project`** + how-to **`use-an-admin-token`** |
| 32 | §2 준비 — *"`/setup-matt-pocock-skills` 를 돌릴 필요가 없다"*(상자가 `docs/agents/*.md`·라벨을 미리 채운다) | **(d)** | explanation **`what-plinth-installs`** |
| 33 | §2 ①–④ 의 대화 예시(그릴링 라운드 · `CONTEXT.md` 기록 · seam 질문 · 티켓 굵기 퀴즈) | **(a)** | 스킬 자신이 하는 일이다. **단** 인수기준마다 검사를 적는 규칙과 `ready-for-agent` 는 tutorial **`your-first-feature-with-agents`** 로 |
| 34 | §2 ⑤ — *"Matt 흐름은 커밋에서 끝난다. ①② 가 우리 것"* | **(c)** | 16번과 같은 문단 |
| 35 | §2 ⑥ 리뷰 **두 겹 표**(로컬 `code-review` vs 서버 `third-party / review`) | **(d)** | how-to **`configure-the-third-party-reviewer`** + explanation **`what-the-wall-does-and-does-not-do`**. ⚠️ *"제3자 **벽**"* 표현은 고친다 — 룰셋의 요구 검사가 아니다(§1 각주) |
| 36 | §2 ⑦ — 검사 이름 열거 · `--admin` 도 거부 · squash · `Closes #N` · *"`implement` 는 티켓을 안 닫는다"* | **(d)** | reference **`required-checks`** (이름의 정본은 `ruleset.json`) + 절차는 **(c)** |
| 37 | §2 ⑧ — `make-release.sh v0.2.0 왜.md` · *왜*는 사람 · PR 제목 11종 | **(d)** | how-to **`cut-a-release`** + reference **`required-checks`** |
| 38 | §2 ⑨ — 세션 시작 훅이 정본 위치를 찍는다 · 막힘 없는 첫 티켓 · *"`/handoff` 는 딱 넷"* | **(b)** | `handoff` 판단 기준 자체는 **(a)** |
| 39 | §3 상황별 8절(진단 · 트리아지 · wayfinder · 아키텍처 · 충돌 · wizard · wait-what · writing-for-agents) | **(a)** | 시중 후기 기반 **처방**(wayfinder babysitting 등)만 explanation **`working-with-agents`** 로 |
| 40 | §4 **스킬 35개 표** | **(e)** | 🔴 최대 드리프트 원천. 27번과 같은 이유. 우리 **판정**(🚫 훅 층은 `--no-verify` 로 넘어간다 · Matt 개인 스킬)만 explanation **`design-rules`** 로 |
| 41 | §5 자주 하는 실수 표 — Matt 쪽 12줄 | **(a)** | |
| 42 | §5 실수 표 — 우리 것 2줄(*"`implement` 뒤 `main` 에 푸시 → 룰셋이 거부"* · *"리뷰 지적을 안 읽고 머지"*) | **(c)** | |
| 43 | §6 *"우리 벽과 맞물리는 자리"* 넷(브랜치·PR · 라벨 · `CONTRIBUTING` · `AGENTS.md §기획할 때` · ready HEAD) | **(d)** | explanation **`what-plinth-installs`** + **`what-the-wall-does-and-does-not-do`** |
| 44 | 머리말 **지원 범위 문장**(공개 GitHub · Python · greenfield · 단일 소유자 / 미검증 목록) | **(d)** | reference **`support-scope`** |
| 45 | §근거 — `standards` direction 03·04·05·07 · Matt 공식 문서 · 시중 후기 링크 | **(d)** | explanation **`working-with-agents`** 의 *Further reading* (lab 링크로만 — 제품은 self-contained, `24`) |

### (b) 가 받는 세 줄 — 초안

`AGENTS.md`(plinth 자신 + 템플릿 인스턴스, 영어, ≤60줄 안):

```markdown
## Next move
- State lives in the tracker, never in a file: read `gh issue list --state open`, the current branch, and open PRs before answering "what's next".
- Name exactly one next command and why, in one line. Never run a user-invoked skill (`/grill-with-docs`, `/to-spec`, `/to-tickets`, `/implement`, `/new-project`) or pretend you did — the human types it.
- For "which flow fits my situation", hand off to `/ask-matt`. One ticket = one session = one PR.
```

---

## 4. 영상 두 편 대조 — 확인한 것 · 갈리는 것

> 요지 전문은 #135 의 코멘트에 있다. 여기는 **1차 자료로 확인·정정한 것**만.

| # | 영상이 말한 것 | 1차 확인 결과 |
|---|---|---|
| 1 | *"갈림길과 clear 규율(smart zone)이 README 엔 없다"* | **부분 정정.** `README.md` 엔 없지만 **`ask-matt/SKILL.md` 에는 있다** — 갈림길(*"is this a multi-session build?"*) · *"one unbroken context window"* · smart zone 링크까지. 우리가 새로 쓸 게 아니라 **가리키면 된다** |
| 2 | smart zone **≈140k** | **`ask-matt/SKILL.md` 는 "~150k tokens"**. 두 숫자가 다르다 — 문서를 정본으로 쓴다 |
| 3 | *"38개 깔아도 컨텍스트 660 토큰"* | 1.2.3 실물은 **`skills/*/*` 35개** — `engineering` 18 · `productivity` 7 · `in-progress` 6 · `misc` 4(+`deprecated`). **플러그인이 노출하는 것은 25개**(engineering+productivity). 토큰 수는 확인하지 않았다 |
| 4 | 설치는 `npx skills@latest add mattpocock/skills` | README 는 **두 경로**를 나눠 적는다 — 공식 마켓 플러그인(*"subscribe rather than fork"*) vs skills.sh(편집 가능). *"installing both leaves you with every skill twice."* 우리는 **플러그인 경로**다 |
| 5 | *"설정 스킬이 트래커·트리아지 라벨·도메인 문서를 잡는다"* | 맞다(`setup-matt-pocock-skills`, `disable-model-invocation: true`). **우리 상자가 그 셋을 미리 채우므로 새 저장소엔 불필요** — 기존 저장소에서만 |
| 6 | *"리뷰는 서브에이전트로 — 쓴 에이전트는 자기 코드를 못 본다"* | `code-review` frontmatter 확인(*"Runs both reviews in parallel sub-agents"*). 코퍼스 **28** 의 self-preference bias·cross-context +16% F1 이 같은 말을 1차 문헌으로 한다 |
| 7 | *"`ask-matt` 가 우리 `playbook` 과 겹친다"* | 맞다 — 그리고 소유자가 **#136 에서 `playbook` 제거를 결정**했다. §3 이 그 처분표다 |
| 8 | Matt 는 plan mode 대신 **그릴링**으로 계획을 심문한다 | `grill-with-docs` frontmatter 와 `ask-matt` 의 main flow 1번이 일치. 아티클의 plan mode 와 **같은 기능, 다른 도구** |
| 9 | 발표자 경고 — *"one-size-fits-all 없음 · 표준화하고 자주 바꾸지 말 것"* | 코퍼스 **28** 과 일치: *"no dominant agent architecture … don't over-fit to one shape; the principles are the durable part"* |

## 5. 확인하지 못한 것

- 아티클 원문의 **줄 단위 구조**(절 제목·순서)는 WebFetch 가 요약한 형태로 읽었다. **인용문은 원문 그대로**지만, 인용이 어느 절에 붙어 있는지의 배치는 재확인이 필요할 수 있다.
- `claude plugin eval` 의 **케이스 파일 형식** — 공개 문서가 없다(#99 손 확인 항목 ③). 격차 1의 배선은 그 확인 뒤다.
- 영상 A 의 *"컨텍스트 660 토큰"* — 실측하지 않았다.
- 아티클의 `bands.yaml` · Claude Tag 채널 루프는 **우리 범위 밖**이라 대응 자리를 찾지 않았다.
