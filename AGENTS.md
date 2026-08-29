# 이 저장소에서 일하는 법

**재사용 CI 워크플로와 새 프로젝트 생성기다.** 남이 `uses: …@<SHA>` 로 부른다.
`CLAUDE.md` 는 이 파일을 가리키는 심볼릭 링크다 — **정본은 `AGENTS.md`.**

## 검사

```bash
bash -n new-project.sh tools/*.sh tests/*.sh
shellcheck new-project.sh tools/*.sh tests/*.sh
actionlint .github/workflows/*.yml
./tools/check-ruleset.sh ruleset.json     # 벽이 벽인가
./tests/new-project-failpath.sh           # gh 를 목으로 바꿔 전 단계에서 실패시킨다
./tests/make-release-guards.sh
./tests/pr-title-cases.sh                 # 규칙은 python-ci.yml 에서 뽑아 쓴다
./tests/plugin-hooks.sh                   # 훅이 세션을 막지 않는가
claude plugin validate . && claude plugin validate plugins/*  # 마켓·플러그인
```

## 🔴 ALWAYS

- 🔴 **플러그인을 고쳤으면 `version` 을 올린다.** `plugin.json` **과** 마켓 항목 **둘 다** —
  `claude plugin tag` 가 둘이 일치하는지 본다. **2026-08-30 에 이걸 안 지켜서** PR 셋이 지나가는 동안
  `0.1.0` 이 그대로였고, **깔린 사람은 자기가 무엇을 갖고 있는지 알 수 없었다**
  (그 사이 `/new-project` 가 **모델이 부를 수 있는 상태**로 배포돼 있었다)
- **잡 이름 `ci` 를 그대로 둔다.** 검사 이름이 `{호출잡}/{피호출잡}` 이라 룰셋과 묶여 있다 —
  바꾸면 **요구된 이름이 영원히 보고되지 않아 소비자 저장소가 조용히 머지 불가로 잠긴다**
- **새 검사를 룰셋에 넣기 전에 소비자 핀을 먼저 올린다.** 순서는 언제나 **핀 → 룰셋**
- **Action 핀은 커밋 SHA.** 태그는 가변이라 공급망 벡터다 (`GHW-005`)
- **`if:` 로 잡을 건너뛰지 않는다.** PR 이 아닐 때도 **통과로 보고**한다 — 건너뛰면
  검사 이름이 안 나오는 경로가 생긴다 (`diff-size`·`pr-title` 이 그 형태다)

## ⚠️ ASK FIRST

- 룰셋 변경 — **관리자 토큰이 필요하고 이 기계에 없다.** `decision:escalation` 으로 회부한다
- `python-ci.yml` 의 잡 추가/이름 변경 — 소비자 전원에게 전파된다

## 🚫 NEVER

- `main` 직접 푸시 · `--admin` 강제 머지 (룰셋이 소유자도 막는다)
- 릴리스 노트를 `--generate-notes` **만으로** 만들기 — *왜* 는 사람이 쓴다
  (`tools/make-release.sh` 가 빈 노트파일을 거부한다)

## 규율

- **PR 제목은 `type(scope): 요약`** — 표준 11종뿐. **새 타입을 만들지 마라**
- 릴리스: `tools/make-release.sh <태그> <노트파일>` · SemVer 기준은 README §버전
- CI 로직의 정본은 `python-ci.yml`, 요구 검사의 정본은 `ruleset.json` 하나다
