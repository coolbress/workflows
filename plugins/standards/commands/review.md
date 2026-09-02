---
description: PR 을 열기 전에 diff 를 제3자에게 리뷰시킨다. 외부 모델을 먼저 쓴다.
argument-hint: "[--base <ref>]"
disable-model-invocation: true
disallowed-tools: Edit, Write, NotebookEdit
---

<!-- 사용자 전용 · 쓰기 도구 없음. 리뷰와 수정 사이에 사람 턴 하나가 강제로 들어간다(원칙 04).
     `Bash` 는 남긴다 — 본체가 `codex review` 실행이다. 집행은 벽(GitHub)이 하고 여기는 규율이다. -->

# diff 리뷰 — 제3자에게 맡긴다

설정된 리뷰어: **`${user_config.reviewer}`** (바꾸려면 `/plugin` → `coolbress-standards`)

| 설정값 | 할 일 |
|---|---|
| `auto` (기본) | `claude plugin list` 로 설치된 것을 본다. `codex` 가 있으면 그것, 없으면 `none` |
| `codex` | `codex review --base main` — 🔴 CLI 로 부른다. `/codex:review` 는 사용자 전용이라 **내가 부르면 아무 일도 안 일어난다** |
| 그 밖의 이름 | 그 도구의 리뷰 명령에 diff 를 주고 두 축으로 묻는다 — **Standards**(`CONTRIBUTING.md`) · **Spec**(이슈의 `AC-n`) |
| `none` | 🔶 내부로 떨어진다. **사용자에게 말한다**: *"외부 리뷰어가 없어 같은 모델이 봅니다 — 제3자성이 없습니다"* — 그리고 `mattpocock` 의 `code-review`(2축 · 병렬 서브에이전트)를 쓴다 |

설정된 리뷰어가 설치돼 있지 않으면 조용히 넘어가지 말고 한 줄로 말한다.

🔴 **어느 쪽이든 리뷰는 안전망이 아니다** (`standards` `IPW-007`). **판정은 벽이 한다** —
`ci / *` 와 `third-party / review` 가 빨간불이면 리뷰가 뭐라 하든 머지는 안 된다.
Stop 게이트(`codex` 의 `--enable-review-gate`)는 켜지 않는다 — 수정 → 재리뷰 → 재수정 루프가 실사용에서 보고된 위험이다.
