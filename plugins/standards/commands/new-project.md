---
description: 벽이 선 새 저장소를 만든다 — 생성 + 서버 바닥(브랜치 보호·시크릿 탐지·SHA 강제·Dependabot). fail-closed.
argument-hint: "<이름> [--license=<spdx>]"
disable-model-invocation: true
---

<!-- 🔴 **사용자 전용이다.** 공식 문서가 이 자리를 정확히 말한다 —
     "부작용이 있거나 타이밍을 통제하고 싶은 워크플로에 쓴다. 코드가 준비된 것 같다고
     Claude 가 배포를 결정하는 걸 원치 않는다."
     이 커맨드는 **원격 저장소를 만들고 관리자 토큰을 요구하며 실패하면 지운다.**
     되돌리기 어려운 것은 사람이 시작한다. -->

# 새 프로젝트

🔴 **이 명령은 저장소를 만들고 *벽을 세운다*. 벽 자체는 GitHub 에 남는다** — 플러그인이 아니다.

## 돌리는 법

스크립트는 `coolbress/workflows` 에 산다. 없으면 먼저 받는다:

```bash
[ -d ~/workflows ] || gh repo clone coolbress/workflows ~/workflows   # 한 번만
```
<!-- ponytail: 플러그인이 스크립트를 안 싣는다 — new-project.sh 는 ruleset.json · tools/ 와 한 묶음이라
     옮기면 넷이 같이 가야 한다. 설치자가 clone 한 줄이면 되므로 그걸로 둔다. 외부 설치자가 여기서 걸리면 그때 싣는다. -->

```bash
cd ~   # 🔴 저장소 밖에서. 스크립트가 저장소 안이면 멈춘다
~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh <이름> [--license=<spdx>]
```

⚠️ **`--private` 는 미지원**이다 — 비공개는 룰셋에 GitHub Pro 가 필요하고, 비공개 SAST 경로가 미구현이라
`new-project.sh` 가 **시작 전에 거부한다.**

## 🔴 토큰은 내가 다루지 않는다

관리자 토큰은 **이 기계에 저장돼 있지 않다.** 래퍼가 **물어보고**, 그 프로세스가 사는 몇 초 동안만 존재한다.

🔴 **토큰을 명령줄에 쓰지 마라** — `GH_TOKEN=... 명령` 은 `~/.zsh_history` 에 그대로 남는다.
`histignorespace` 는 앞에 공백이 있을 때만 듣는다.

**에이전트가 할 일은 명령을 만들어 사람에게 넘기는 것이다.** 실행은 사람이 한다.

## 만들어진 뒤

1. 그 저장소에서 **`/grill-with-docs` + 아이디어 한 줄** — 인터뷰가 `CONTEXT.md` 와 이슈를 남긴다.
   다음 단계는 `playbook` 스킬이 안내한다(`/to-spec` → `/to-tickets` → `/implement`)
2. 첫 PR 은 **작게**. 첫 조각은 walking skeleton — end-to-end 한 줄기
3. 🔴 **새 저장소를 토큰 목록에 추가해야 한다** — 안 하면 저장소는 완벽한데 **라벨 하나 못 만든다**(403).
   스크립트가 끝에 알려준다

## fail-closed 인 이유

어느 단계에서 실패하든 **원격 저장소를 남기지 않는다.**
**벽 없는 저장소가 남는 것이 이 프로젝트가 죽는 방식이기 때문이다** —
실사용에서 두 번 발화했고 두 번 다 정확했다(저장소를 만들고, 실패하고, 지웠다).
