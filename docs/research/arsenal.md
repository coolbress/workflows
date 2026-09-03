# R-ARSENAL — 무기고 축별 구성 (#137)

> 조사일 **2026-09-03** · 읽기 전용(`gh api` · skills.sh API · `claude plugin details`) · **아무것도 설치하지 않았다.**
> 기준의 정본은 `~/standards/audit/ARSENAL.ko.md` — §4 열한 문항 · §7 `cost`/`stability`/`defaultInstall` · §3 *인기 신호와 사실 판정을 가른다* · §2b 핀 규율.
>
> ⚠️ **복원본(2026-09-04).** 원본은 조사 에이전트가 커밋하기 전에 정리 단계의 실수로 지워졌다. 이 파일은 세션 기록에서 다시 쓴 것이며,
> 긴 표 칸 일부는 기록이 330자에서 잘려 **요지만** 남았다(그 칸은 `…` 로 표시). 판정과 수치는 #137 코멘트와 일치한다.

---

## 0. 먼저 — 이번에 확보한 다섯 가지 사실

**① 상시 토큰은 추정하지 않고 쟀다.** `claude plugin details` 실측(2026-09-03):

| 재직 무기 | 버전 | 스킬 | 훅 | MCP | **상시** | 호출당 최대 |
|---|---|---|---|---|---|---|
| `mattpocock-skills` | 1.2.3 | 25 | 0 | 0 | **~1,609** | `ask-matt` ~3.8k |
| `taste-skill` | 1.0.0 | 13 | 0 | 0 | **~1,697** | `taste-skill` **~33.6k** |
| `ponytail` | 4.9.0 | 6 | **3** | 0 | **~983** | `ponytail` ~2.2k |
| `last30days` | 3.21.1 | 1 | **1** | 0 | **~103** | `last30days` **~90k** |

🔴 ARSENAL §7 이 `last30days` 를 훅 ❌ 로 적어 두었는데 실제로는 `SessionStart` 훅이 하나 있다(대장 정정 대상; `details` 는 "harness-only — no model context cost" 로 표시).

**② 추정치 보정.** 하위 조사가 쓴 `(name+description 글자수)/4` 를 실측과 맞추면 비가 1.38 · 1.41 · 1.56 → **`글자수/4 × 1.4`** 가 실측 근사. 아래 표의 *추정* 칸은 전부 이 보정을 적용.

**③ `git-subdir` + `strict:false` + `skills[]` 는 실재하는 공식 패턴.** 공식 마켓(291개) verbatim — `amd-skills`: `source: git-subdir` · `path: skills` · `sha` · `strict: false` · `skills: ["./local-ai-use", …]`. 🔴 `strict` 는 `source` 안이 아니라 항목 최상위. 공식 마켓의 `strict:false` 는 14개(LSP 12 + amd-skills + learn-with-coursera) — 전부 *소스에 plugin.json 이 없고 마켓 항목이 매니페스트 노릇을 하는* 자리.

**④ `skills[]` 는 허용 목록이다(실측).** `mattpocock/skills` 에 `SKILL.md` 36개(핀 SHA 기준)인데 `plugin.json` 의 `skills` 배열은 25개, `details` 도 25개 보고. 빠진 11개에 `misc/git-guardrails-claude-code` · `misc/setup-pre-commit` · `in-progress/claude-handoff` — 저장소엔 있는데 안 켜진다.

**⑤ Anthropic 1st-party 플러그인 53개는 핀이 불가능하다.** 291개 중 238개(81.8%)가 `sha` 를 갖고, `sha` 없는 53개는 전부 `"source": "./plugins/<name>"` 로컬 경로. 로컬 경로엔 버전 손잡이가 없다 → 우리가 `git-subdir` 로 재선언해야 SHA 가 붙는다. 그래서 만든 우회 매니페스트(§3)가 `claude plugin validate --strict` 를 **통과**(exit 0, 2026-09-03). ⚠️ 스키마 통과일 뿐 설치 왕복은 미시험(§8-1).

---

## 1. 축 × 후보 (🟢 추천 · 🟡 차점 · 🔴 탈락 · `상시` 굵음 = 실측)

### ① 계획 · 빌드 · 현업 워크플로 (절차)
| | 후보 | 형태 · 훅/MCP | 상시 | 라이선스 · 최근 커밋 · 이슈 | 판정 근거 |
|---|---|---|---|---|---|
| 🟢 | **mattpocock-skills** `5b15a47f` | 플러그인 · 훅 0 · MCP 0 | **~1,609** | MIT · 2026-08-24 · 448 | 공식 마켓에 SHA 핀이 이미 걸려 있다(§2b 1행). 25 스킬이 ①⑤⑦⑧ 을 한꺼번에 덮는다. 티켓이 *교체 대상 아님* |
| 🟡 | BMAD-METHOD `891c0abb` | `plugin.json` 없음 · marketplace.json 만 · 훅 0 · MCP 0 | ~2,560 | NOASSERTION(MIT + 상표) · 2026-09-02 · 34 · 52.9MB | 비엔지니어를 향해 쓰인 유일한 후보(`bmad-walkthrough`) … 그러나 3중 툴체인 · `uv` 없으면 HALT (…) |
| 🔴 | superpowers `b36e0829` | 플러그인 · **SessionStart 훅(동기)** | ~1,575(지수 750 + 훅 주입 825) | MIT · 2026-08-12 · 354 | ARSENAL §2c 기각 유지 + 새 근거: 훅이 `using-superpowers/SKILL.md` 전문을 `<EXTREMELY_IMPORTANT>` 로 감싸 매 세션 · 매 `/clear` · 매 압축마다 주입 (…) |
| 🔴 | knowledge-work-plugins(Anthropic) | 11 플러그인 · 전부 `mcpServers` | ~390/플러그인 | Apache-2.0 · 2026-09-02 · 105 | 다른 비엔지니어(Claude Cowork 용) — Slack · Linear · Asana … 커넥터 7~10개 전제. 솔로 빌더는 하나도 없다 |

### ② 구현 자세 (코드 양)
| | 후보 | 형태 | 상시 | 라이선스 · 최근 · 이슈 | 판정 근거 |
|---|---|---|---|---|---|
| 🟢 | **ponytail** `2ed6c52c` — 모양을 바꿔서 | 플러그인 · 훅 3 · MCP 0 | **~983** | MIT · 2026-08-07 · 77 | ARSENAL §2 채택 유지. 바뀌는 건 마운트 모양: `path:"skills"` + `strict:false` + `skills[6]` 로 스킬만 기본, `hooks/` 는 서브트리 밖이라 자동으로 남는다. 실측: SKILL.md 6개가 전부 `skills/` 안 (…) |
| 🟡 | — | | | | 이 축에 진짜 경쟁자가 없다(skills.sh `yagni` 최고 253 설치) |
| 🔴 | code-simplifier(Anthropic) | 서브에이전트 1 | ~60 | Apache-2.0 · 로컬 경로 | 입장이 반대 — "Choose clarity over brevity", 남의 하우스 스타일 하드코딩, autonomous (…) |
| 🔴 | rigorpilot `minimal-run-and-audit`(449,968 설치) | 맨 SKILL.md | ~2,060 | MIT · 2026-09-03 | 🔬 이름이 속인 사례 — 실제는 딥러닝 저장소 재현 스킬(CUDA OOM · NaN loss). ponytail 과 트리거 0% |
| 🔴 | addyosmani/agent-skills `code-simplification` | 플러그인 · SessionStart 훅 | ~2,660 | MIT · 2026-09-03 · 129 | 훅이 매 세션 주입 · `jq` 의존 · 사용자 파일 재작성 (…) |

### ③ 디자인 (랜딩 · 웹앱 UI) — **재직 무기를 교체한다**
| | 후보 | 형태 | 상시 | 라이선스 · 최근 · 이슈 | 판정 근거 |
|---|---|---|---|---|---|
| 🟢 | **frontend-design**(Anthropic) | 플러그인 · 훅 0 · MCP 0 · 스크립트 0 · 계정 0 | ~71 | Apache-2.0 · 2026-09-01 | 스킬 1개 · 21.9KB 로 축 전체(랜딩 + 앱 UI)를 덮고 브리프가 모호하면 스스로 정한다 (…) |
| 🟡 | impeccable `5a7e2837` | 플러그인 · **PostToolUse + Stop(30초) 훅** · Node ≥22 | ~314 | Apache-2.0 · 2026-09-03 · 25 | 축을 가장 넓게 덮는다 — Persuade(랜딩) / Operate(대시보드 · 에디터 · 설정) … 훅 비용 때문에 옵트인 |
| 🔴 | **taste-skill** `ccbc1563` — 재직, 교체 권고 | 플러그인 · 훅 0 | **~1,697** | MIT · 🔴 스킬 내용 2026-06-12 이후 정지 · 30 | 축의 절반을 자기 입으로 거부: "Landing pages, portfolios, and redesigns. **Not dashboards, not data tables, not multi-step product UI.**" (…) 상시가 추천안의 24배 |
| 🔴 | superdesign | `npx @superdesign/cli@latest` | ~207 | MIT | 계정 로그인 + 크레딧 과금 |
| 🔴 | uizze `anti-ui-slop`(642,546 설치) | 유료 MCP | ~377 | MIT · ⭐17 | 차별점이 유료 MCP 뒤. 설치 642,546 vs ⭐17 · 포크 2 (…) |
| 🔴 | ui-ux-pro-max(⭐124,533) | `.mcp.json` 3종 `@latest` 핀 없음 · Python 검색 스크립트 | ~934 | MIT | 사용자가 CLI 질의 문법을 배워야 한다 — 비엔지니어 (…) |
| 🔴 | vercel-labs/agent-skills `web-design-guidelines`(603,397) | 맨 SKILL.md | ~1,050 | 🔴 LICENSE 파일 없음(README 산문에만 MIT) · 174 | 라이선스 요건 미충족, 껍데기 (…) |

### ④ 토큰 절약 · 출력 자세 — **기본은 비운다**
> 대상 사용자(C1: 비엔지니어 · 솔로)는 설명을 필요로 한다. 출력을 줄이는 것은 기본이 될 수 없다.

| | 후보 | 형태 | 상시 | 라이선스 · 최근 | 판정 근거 |
|---|---|---|---|---|---|
| 🟢 | **넣지 않는다** | — | 0 | — | 축약은 사용자가 켠다 |
| 🟡 | i-have-adhd `58494af5`(13,611 설치) | 플러그인 · SessionStart 훅 | ~85 | MIT · 2026-09-01 · 20 · 303KB | 구조상 이미 옵트인 — `disable-model-invocation: true` + 플래그 파일 없으면 훅 즉시 exit 0 (…) |
| 🔴 | caveman(477,898 설치 · ⭐102,878) | 훅 2 · MCP | — | 🔴 NOASSERTION(BSL-1.1 부분) · 66 | ARSENAL §2 기각 재확인 — 라이선스 · 훅 · 상태 소유 (…) |
| 🔴 | explanatory-output-style(Anthropic) — 반대 방향 | SessionStart 훅 · 로컬 경로 | ~254 무조건 | Apache-2.0 | 설명을 늘린다(우리 방향)지만 하는 일이 정적 문자열 1,018자 주입 하나 — 플러그인으로 깔 이유가 없다 (…) |

🔬 **인기 신호가 못 보는 것**: Matt 는 `caveman` 스킬을 2026-04-17 넣었다가 2026-06-17 지웠다(`245e31bb`). 오늘 HEAD 의 SKILL.md 37개 어디에도 없는데 skills.sh 는 `mattpocock/skills/caveman` 을 223,635 설치로 보여준다 → 설치 수는 누적이고 삭제를 안 따라간다.

### ⑤ 리서치 · 정보 검색
| | 후보 | 형태 | 상시 | 판정 근거 |
|---|---|---|---|---|
| 🟢 | Matt `research`(판정) + **last30days**(발견) | 훅 1(SessionStart) | **~103** | 역할 분리 유지. 🔴 호출당 ~90k — 카탈로그에 적는다 |
| ⚠️ | 핀 갱신 | | | 우리 핀 `a218edad`(3.21.1) → HEAD `56ba5ace`(3.23.0, 2026-09-02) — 13커밋 뒤처짐. HEAD 에 `mcpServers` 없음(확인) |
| 🔴 | firecrawl · tavily · exa · parallel-web | MCP + API 키 | 150~600 | PLUGIN-DESIGN §"🚫 mcpServers 없음" |

### ⑥ 보안
| | 후보 | 형태 | 상시 | 판정 근거 |
|---|---|---|---|---|
| 🟢 | **벽(CodeQL · secrets · deps) + 내장 `/security-review`** | 설치 0 | **0** | 강제는 벽만 · 내장은 사람이 부를 때만 |
| 🟡 | claude-security v0.11.0(Anthropic) | 스킬 1(`disable-model-invocation`) · 에이전트 8 · 훅 · Python | ~610 | 더 깊다(등급 선택 · 반증 · 패치). 옵트인 |
| 🔴 | security-guidance v2.0.7(Anthropic) | 훅 5종 | 0 | 🔴 기본 불가 — **fail-open**: SessionStart 훅이 네트워크로 `claude_agent_sdk` 를 pip install(180초), OOM 시 SIGKILL (…) |
| 🔴 | semgrep(MCP) | MCP | — | SAST-CODEQL-VS-SEMGREP: 겹침 · 공개는 CodeQL 하나 |

### ⑦ 디버깅 · 시험 · 리뷰
| | 후보 | 상시 | 판정 근거 |
|---|---|---|---|
| 🟢 | Matt `diagnosing-bugs` · `code-review` · `tdd` · `triage` | 0 추가 | 이미 있다(`code-review` 상시 ~160 · 호출당 ~2.1k) |
| 🟡 | anthropics/skills `webapp-testing`(149,121) | ~71 | "내 앱이 실제로 되나" — 카탈로그 후보 |
| 🔴 | pr-review-toolkit(Anthropic) | ~2,200 | 가장 비쌈 · Matt 중복 · `code-reviewer` 에이전트 이름이 `feature-dev` 와 충돌 |
| 🔴 | code-review(Anthropic 커맨드) | 0 | `/code-review` 이름이 셋이 된다(내장 · Matt · 이것) |

### ⑧ 문서 · 인계 · 스킬 저작
| | 후보 | 상시 | 판정 근거 |
|---|---|---|---|
| 🟢 | Matt `handoff`(731,479) · `writing-for-agents` · `domain-modeling` · `teach`(586,564) | 0 추가 | 이미 있다. `teach` 는 비엔지니어 축의 재직 답 |
| 🟡 | session-report(Anthropic) | ~53 | 가장 싸다 · 토큰·돈 가시화 · `.claude-plugin/` 없음 → `strict:false` 필수 · 버전 없음 |
| 🔴 | skill-creator · plugin-dev(~2,310) · claude-md-management | | 중복(바이트 동일 사본 · Matt writing-for-agents) · 사용자는 플러그인을 만들지 않는다 |

### ⑨ git / PR 위생
| | 후보 | 상시 | 판정 근거 |
|---|---|---|---|
| 🟢 | **벽** — 룰셋(force push · 삭제 금지 · PR 필수) + `ci / pr-title` | **0** | 스킬이 아니라 벽이 강제한다 |
| 🟡 | commit-commands(Anthropic, 커맨드 3) | 0 | git 은 비엔지니어가 실제로 막히는 자리 · 로컬 경로라 `git-subdir` 재선언 필요 |
| ⚠️ | Matt `misc/git-guardrails-claude-code` · `misc/setup-pre-commit` | — | 저장소엔 있는데 상류 `skills[]` 25개에서 빠져 안 켜진다(§0-④). 켜려면 Anthropic 핀을 버리고 재선언 — 그 값이 더 크다 |

### ⑩ 기타
| | 후보 | 형태 | 상시 | 판정 근거 |
|---|---|---|---|---|
| 🟡 | **addyosmani/web-quality-skills** | 훅 0 · MCP 0 · 읽기 전용 bash 1 | ~470 | 🔬 유일한 새 축 — *측정된* 웹 품질(Lighthouse · CWV · WCAG 2.2 · SEO). 취향(디자인)과 안 겹친다 (…) |
| 🟡 | project-artifact(Anthropic) | 스킬 1 | ~316 | 사람에게 보여주는 상태 페이지 — Matt handoff 와 청중이 다르다 |
| 🔴 | hookify(Anthropic) | 훅 4종 · UserPromptSubmit 매처 없음 | ~196 | 모든 도구 호출마다 python3 |
| 🔴 | code-modernization | 커맨드 10 + 에이전트 8 | ~718 | COBOL · 레거시 — 대상이 다르다 |

---

## 2. 판정 — 기본 설치 / 옵트인 / 넣지 않음

> 프로필은 둘까지만(ARSENAL §7). 세 번째 칸은 프로필이 아니라 **카탈로그** — 적기만 하고 안 깐다 = 비용 0.

**기본 프로필 (`plinth`)** — mattpocock-skills(①⑤⑦⑧⑨ · ~1,609) · **frontend-design 🆕**(③ · ~71 · taste-skill 교체) · last30days(⑤ 발견 · ~103) · **ponytail-skills 🔄**(② · ~983 · 훅 없음) · 내장 `/security-review`(⑥ · 0). 합계 **~2,766** — 오늘 3,409 대비 −643, ponytail 이 기본으로 들어오고도.

**옵트인 프로필 (`plinth-hooks`)** — 훅을 가진 것만: ponytail 전체(훅 3) · impeccable 🆕(PostToolUse + Stop 30초) · i-have-adhd 🆕(SessionStart, 플래그 없으면 no-op).

**카탈로그만** — claude-security · webapp-testing · session-report · commit-commands · web-quality-skills · project-artifact · superdesign.

**기각(카탈로그에도 안 적음)** — superpowers · BMAD · caveman · security-guidance(fail-open) · uizze · vercel-labs/agent-skills(LICENSE 없음) · ui-ux-pro-max · rigorpilot · addyosmani/agent-skills · knowledge-work-plugins · plugin-dev · pr-review-toolkit · skill-creator · claude-md-management · code-simplifier · hookify · code-modernization · semgrep · MCP 리서치 계열.

---

## 3. P1 이 그대로 쓸 마켓 항목 초안 (`claude plugin validate --strict` 통과 · 2026-09-03 · 설치 왕복은 미시험)

```json
{
  "name": "plinth",
  "description": "plinth 의 무기고 — 벽은 GitHub 에 있다.",
  "owner": { "name": "coolbress" },
  "plugins": [
    { "name": "plinth", "description": "플레이북과 문(new-project · floor-check). 훅 없음 — 기본 프로필.", "category": "workflow",
      "source": "./plugins/plinth",
      "dependencies": [ { "name": "mattpocock-skills", "marketplace": "claude-plugins-official" }, "frontend-design", "last30days", "ponytail-skills" ] },
    { "name": "plinth-hooks", "description": "기본 + 세션 훅 + ponytail(전체). 훅은 여기에만 있다 — 옵트인.", "category": "workflow",
      "source": "./plugins/plinth-hooks", "dependencies": ["plinth", "ponytail"] },
    { "name": "frontend-design", "description": "랜딩과 앱 UI 의 디자인 방향. Anthropic 1st-party 를 우리가 SHA 로 핀한다.", "category": "design",
      "source": { "source": "git-subdir", "url": "https://github.com/anthropics/claude-plugins-official.git", "path": "plugins/frontend-design", "ref": "main", "sha": "0120fb83da5d7cdaa52dd11979690f2dc5f76052" } },
    { "name": "last30days", "description": "최근 반응과 새 후보를 찾는다. 🔴 판정에는 쓰지 않는다 · 호출당 ~90k 토큰.", "category": "workflow",
      "source": { "source": "url", "url": "https://github.com/mvanhorn/last30days-skill.git", "sha": "56ba5ace27e4697aedc60aa0b1e1bfdcd592ff20" } },
    { "name": "ponytail-skills", "description": "먼저 찾고 최소한으로 구현한다. 스킬만 — 훅은 plinth-hooks 에 있다.", "category": "workflow",
      "source": { "source": "git-subdir", "url": "https://github.com/DietrichGebert/ponytail.git", "path": "skills", "ref": "main", "sha": "2ed6c52c9d7e5e56942508591085fd45dea277d3" },
      "strict": false, "skills": ["./ponytail", "./ponytail-review", "./ponytail-audit", "./ponytail-debt", "./ponytail-help", "./ponytail-gain"] },
    { "name": "ponytail", "description": "ponytail 전체 — 훅 3종 포함. 옵트인 전용.", "category": "workflow",
      "source": { "source": "url", "url": "https://github.com/DietrichGebert/ponytail.git", "sha": "2ed6c52c9d7e5e56942508591085fd45dea277d3" } },
    { "name": "impeccable", "description": "디자인 상급 — Persuade/Operate. Node ≥22 · 매 턴 30초 Stop 훅. 옵트인.", "category": "design",
      "source": { "source": "git-subdir", "url": "https://github.com/pbakaus/impeccable.git", "path": "plugin", "ref": "main", "sha": "5a7e2837d2036b2ea8386031c2cd9a539b0dab13" } },
    { "name": "i-have-adhd", "description": "출력을 짧고 단계적으로. 사람이 켜야만 켜진다 — 옵트인.", "category": "workflow",
      "source": { "source": "url", "url": "https://github.com/ayghri/i-have-adhd.git", "sha": "58494af5" } }
  ],
  "allowCrossMarketplaceDependenciesOn": ["claude-plugins-official"]
}
```

| name | source | path | sha | strict | 왜 이 모양인가 |
|---|---|---|---|---|---|
| mattpocock-skills | 재선언 안 함 | — | 상류 `5b15a47f…` | — | 핀이 이미 걸려 있으면 그대로 쓴다(§2b 1행) |
| frontend-design | git-subdir | `plugins/frontend-design` | `0120fb83…` | true | 상류가 로컬 경로라 핀이 없다 → 재선언해야 SHA 가 붙는다. `version` 도 없다 |
| last30days | url | — | `56ba5ace…`(핀 올림) | true | 13커밋 뒤처짐 |
| ponytail-skills | git-subdir | `skills` | `2ed6c52c…` | **false** | hooks/ 와 plugin.json 이 서브트리 밖 → `strict:false` 필수 |
| ponytail | url | — | `2ed6c52c…` | true | 옵트인만 |
| impeccable | git-subdir | `plugin` | `5a7e2837…` | true | 357MB → 4.80MB(하네스별 18벌 페이로드 회피) |
| i-have-adhd | url | — | `58494af5`(⚠️ 40자 필요) | true | 작고 훅이 플래그 없으면 no-op |

---

## 4. 겹침 · 충돌 위험

- 🔴 **`frontend-design` 스킬 이름 충돌** — Anthropic 1st-party ↔ `anthropics/skills` ↔ impeccable 이 같은 이름을 쓴다. 기본(1st-party)과 옵트인(impeccable)을 같이 깔면 둘이 된다 → P1 은 impeccable 을 `skills[]` 로 제한하거나 프로필을 배타로.
- 이름 겹침(무해, 둘 다 기각): `skill-creator`(바이트 동일 사본) · `code-review`(내장 · Matt · Anthropic 커맨드 · knowledge-work) · `code-reviewer` 에이전트 · `tdd`.
- 트리거 겹침: "랜딩 페이지" — taste-skill 교체로 해소 · "대시보드" — 오늘은 taste-skill 이 튀고 나서 거절한다(현재 실패 모드, 교체가 고친다) · "audit" — ponytail-audit ↔ impeccable audit ↔ web-quality-audit(카탈로그가 구분을 적는다).
- 🔴 `plinth-hooks` 를 켜면 훅 4~6종(ponytail 3 + impeccable 2 + i-have-adhd 1 + last30days 1) — impeccable Stop 훅 30초. 프로필 문서가 합을 적는다.
- ⚠️ `git-subdir` 마운트는 LICENSE 텍스트를 안 데려온다(ponytail · caveman · impeccable 모두 루트에만) → plinth 의 NOTICE/카탈로그에 원 라이선스와 SHA 를 적는다.
- ⚠️ Anthropic 1st-party 13개 중 10개가 `version` 없음 — SHA 로 핀해도 "무엇을 갖고 있나" 를 말해 줄 수 없다(이 저장소 ALWAYS 첫 줄과 같은 결함).

## 5. 재직 무기 재판정
mattpocock 🟢 유지 · ponytail 🔄 스킬 기본 / 훅 옵트인 · last30days 🟢 유지 + 핀 올림(훅 1개 있음 — 대장 정정) · taste-skill 🔴 교체 권고(보류 조건 충족: 축 절반 거부 · 6월 이후 정지 · 상시 24배) · 내장 security-review 🟢 유지.
🔴 `frontend-design` 채택은 ARSENAL §2c 기각(taste-skill 과 같은 자리 · 소유자가 고른 것)을 **바꾸는** 것 — 소유자 확인 대상.

## 6. 인기 신호가 틀린 자리 — 셋
caveman(223,635 설치 — 저장소에 없음) · uizze(642,546 설치 — ⭐17 · 유료 MCP) · rigorpilot(449,968 — 딥러닝 재현). 그리고 `skills-101/superpowers` 는 `obra/superpowers` 와 이름만 같다 — 후보는 이름이 아니라 저장소로 적는다.

## 7. 소유자 확인이 필요한 것
1. 🔴 taste-skill → frontend-design 교체 (소유자가 고른 무기를 되돌린다)
2. 🔶 ponytail 스킬을 기본으로
3. 🔶 i-have-adhd 를 옵트인에 넣을지

## 8. 미확인
1. 🔴 `git-subdir + strict:false + skills[]` 설치 왕복 — P1 스모크가 증명. 못 하면 ponytail 전체를 옵트인에 두고 ② 기본을 비운다
2. `disable-model-invocation: true` 가 상시 예산에서 설명을 빼는가
3. `git-subdir` 이 shallow clone 인가(전송량 미측정)
4. i-have-adhd 40자 SHA
5. BMAD 설치 HALT 미시험
6. skills.sh 설치 수가 무엇을 세는가(삭제 스킬 유지 · 분포 불일치)
7. 출력 품질은 재지 않았다 — frontend-design vs taste-skill 을 같은 화면 과제로 한 번 붙여 봐야 한다(ARSENAL §2 가 원래 요구한 비교)

## 부록 — 방법
공식 마켓 291 전수(카테고리: development 120 · productivity 52 · database 38 · monitoring 20 · security 18 · 미분류 14 · deployment 9 · design 8 · 나머지 12) · skills.sh API 55개 질의(설치 수는 발견용) · `claude plugin details` 는 설치된 것만 실측 · `claude plugin install` 은 한 번도 안 불렀고 검증은 임시 매니페스트의 `validate --strict` 뿐.
