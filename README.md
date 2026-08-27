# workflows — 재사용 CI 워크플로

프로젝트마다 CI 로직을 복사하지 않는다. 여기 한 벌을 두고 **각 저장소는 5줄로 호출**한다.
로직을 고치면 `@ref` 갱신으로 전파된다 — 템플릿 복사와 달리 시점에 고정되지 않는다.

## 쓰는 법

저장소의 `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  ci:
    uses: coolbress/workflows/.github/workflows/python-ci.yml@<commit-sha>
```

`@<commit-sha>` — **브랜치가 아니라 커밋 SHA로 핀한다.** 태그·브랜치는 가변이라
남이 고친 CI 가 조용히 내 저장소에서 도는 경로가 된다.

## ⚠️ 잡 이름 `ci` 를 바꾸지 마라 — 룰셋과 묶여 있다

**실측 2026-08-24**: 재사용 워크플로를 부르면 체크 이름이 `{호출잡}/{피호출잡}` 이 된다.
위처럼 호출잡을 `ci` 로 두면 체크는 이렇게 보고된다:

```
ci / lint        ci / typecheck        ci / test        ci / build
```

`lint` 가 아니라 **`ci / lint`** 다. 그래서 [`ruleset.json`](ruleset.json) 의
`required_status_checks` 도 그 이름을 그대로 요구한다 — 넷 + `ci / secrets` + **`CodeQL`**.

🔴 **`CodeQL` 의 출처는 다르다** — `ci / *` 는 GitHub Actions App(`15368`)이고
`CodeQL` 은 code scanning App(**`57789`** · `github-advanced-security`)이다.
그래서 `new-project.sh` 가 **벽을 걸기 전에** CodeQL default setup 을 켠다 —
안 켜면 그 이름이 영원히 보고되지 않아 **저장소가 첫 PR 부터 잠긴다.**

⚠️ **언어별 잡(`Analyze (python)` 등)은 요구하지 않는다.** 저장소마다 언어가 달라서
없는 언어를 요구하면 같은 형태로 잠긴다. **집계 검사 하나만** 쓴다.

**호출잡 이름을 바꾸면 `ci / *` 검사가 전부 다른 이름으로 보고되고, 룰셋이 요구하는 이름은
영원히 보고되지 않는다 — 저장소가 머지 불가 상태로 조용히 잠긴다.** 검사는 초록인데
머지 버튼은 막혀 있는 형태라 원인을 찾기 어렵다.

바꾸려면 [`ruleset.json`](ruleset.json) 의 `ci / *` context 를 같이 바꾼다. **개수는 여기 적지 않는다** — 그 파일이 정본이다.

## 있는 것

| 워크플로 | 검사 | 전제 |
|---|---|---|
| `python-ci.yml` | `lint` · `typecheck` · `test` · `build` · `secrets` — **각각 별도 검사** | uv 프로젝트 · `uv.lock` 커밋됨 · ruff · mypy · pytest |

> ⚠️ **개수를 문장에 반복하지 않는다.** 요구되는 검사의 정본은 [`ruleset.json`](ruleset.json) 하나이고,
> `tools/check-ruleset.sh` 가 그 목록을 불변식으로 지킨다. 예전에 *"네 검사"* 가 문서 여러 곳에
> 박혀 있다가 다섯이 되면서 **문서마다 숫자가 달라졌다.**

### 🔍 `secrets` — 푸시 보호와 **겹치는 게 아니라 다른 것을 잡는다**

| 부류 | GitHub 푸시 보호 | gitleaks |
|---|---|---|
| 공급자 형식(AWS·GH PAT·Slack·Stripe…) | 🔒 **차단** | ✅ 6/6 |
| **개인키 PEM** | 🔴 **통과시킨다** | ✅ 1/1 |
| 일반 시크릿(패스프레이즈·JWT·basic-auth URL) | 🔴 **통과시킨다** | 🟡 2/5 |

실측은 `coolbress/standards` 의 `audit/SECRET-DETECTION-OVERLAP.ko.md` 에 있다.

⚠️ **이건 벽이 아니라 검사다.** 여기까지 왔다는 것은 시크릿이 **이미 GitHub 에 올라갔다**는 뜻이다 —
**막는 것은 푸시 보호**이고, 이 잡은 **머지를 막고 알린다.** 둘 다 있어야 하는 이유가 그것이다.

**선택 입력** — `working-directory`(기본 `.`). 프로젝트 루트가 저장소 루트가 아닐 때만 쓴다.
이 저장소의 canary 잡이 이걸로 자기 자신을 호출한다.

### `build` 는 빌드에서 끝나지 않는다 — **설치까지 해 본다**

`uv build` 가 통과했다는 것은 **파일이 만들어졌다**는 말이지 **쓸 수 있다**는 말이 아니다.
그래서 wheel 과 sdist 를 **깨끗한 venv 에 각각 설치하고 import 까지** 해 본다.
빠진 패키지 데이터 · 잘못된 패키지 이름 · 깨진 메타데이터는 여기서만 잡힌다.

### 왜 4개로 쪼갰나

산출물 바닥이 *"lint·typecheck·test·build를 **각각 별도 required check**로"* 를 MUST 로 요구한다.
한 잡에 4스텝으로 넣으면 첫 실패에서 멈춰 나머지 3개의 상태를 알 수 없고,
브랜치 룰셋이 개별 검사를 요구할 수도 없다.

### 전제가 강하다

`uv sync --locked` 는 **락파일이 없거나 `pyproject.toml` 과 어긋나면 실패한다.**
검사 항목이 아니라 **전제**로 둔 것이다 — 락파일 커밋은 바닥의 MUST 이므로
"없으면 통과"가 될 자리가 없다.

## 기존 저장소의 룰셋 올리기

`ruleset.json` 은 **새 저장소**에만 적용된다. 기존 저장소는 API 로 고쳐야 하는데,
손으로 JSON 을 붙이면 **다른 필드를 실수로 지운다** — 그러면 벽이 조용히 약해진다.

```bash
./tools/upgrade-ruleset.sh --dry-run coolbress/<repo> 'CodeQL:57789'          # 읽기만 — 제한 토큰으로 된다
./tools/with-admin-token.sh ./tools/upgrade-ruleset.sh coolbress/<repo> 'CodeQL:57789'
```

**더하기만 한다.** 기존 요구 검사·우회자·강제 설정은 그대로 둔다.

🔒 **관리자 토큰은 이 컴퓨터에 저장돼 있지 않다**([`with-admin-token.sh`](tools/with-admin-token.sh) 가 물어본다).
🔴 **토큰을 명령줄에 쓰지 마라** — `GH_TOKEN=... 명령` 형태는 **`~/.zsh_history` 에 그대로 남는다.**

## 새 프로젝트 만들기

```bash
cd ~                                    # 🔴 저장소 밖에서. 아래 참조
~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh <이름>
~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh <이름> --license=apache-2.0
```

🔴 **저장소 안에서 돌리면 멈춘다.** `gh repo create --clone` 은 **현재 폴더**에 복제하므로
`~/workflows` 에서 돌리면 `~/workflows/<이름>` — **저장소 안에 저장소**가 된다.
문서로 당부하는 대신 **스크립트가 막는다.**

⚠️ **기본은 공개 · MIT 다.** 다른 라이선스면 `--license=<spdx>` 를 준다.

🔒 관리자 권한이 필요하고 **관리자 토큰은 이 컴퓨터에 저장돼 있지 않다.** 래퍼가 물어본다 —
🔴 **`GH_TOKEN=... ./new-project.sh` 처럼 명령줄에 쓰지 마라. 히스토리에 남는다.**

🔴 **`--private` 는 아직 지원하지 않는다.** 받는 척하지 않고 **시작 전에 멈춘다** —
① Free 는 비공개에 룰셋을 못 걸고 ② 룰셋이 요구하는 `CodeQL` 은 비공개에서
`GitHub Code Security` 라이선스가 필요하다. 정본의 결정(*비공개 → Semgrep OSS*)은
**아직 구현되지 않았다.**

세 가지를 한다 — **손으로 하면 빠뜨리는 것만**:

1. `coolbress/project-template` 에서 저장소를 뜬다
2. `ruleset.json` 으로 **벽을 건다** — 템플릿은 파일만 옮기고 룰셋은 안 옮긴다(CPR-001)
3. **시크릿 탐지 + 푸시 보호**를 켠다 — 기본이 꺼짐이다

생성이 끝나면 **생성기 자신을 지운다**(`bootstrap.sh` · 그 시험). 남겨 두면 모든 프로젝트가
앞으로 쓰지 않을 일회용 스크립트를 들고 다니고 **CI 가 매번 그 시험을 돈다**.

이 스크립트의 **책임은 둘뿐이다** — 저장소 생성과 **서버 바닥 설치**(벽 · 시크릿 탐지 · Dependabot · Actions SHA 강제 · 머지 방법).
그 이상은 하지 않는다. ⚠️ **이전 판의 *"로직은 9줄"* 은 지웠다** — 줄 수는 책임 경계를 재는 자가 아니고,
실제로도 맞지 않았다. 판정 기준은 **이 두 책임 밖의 일이 들어왔는가**다.

**fail-closed**: 어느 단계에서 실패하든 **원격 저장소를 남기지 않는다.** 벽 없는 저장소가 남는 것이
이 프로젝트가 죽는 방식이기 때문이다.

### 라이선스는 인자로 받는다

라이선스는 **GitHub 공식 라이선스 API 의 본문**을 그대로 쓴다(`/licenses/<spdx>`).
교체는 **룰셋을 걸기 전에** 한다 — 건 뒤에는 `main` 직접 푸시가 막혀 PR 없이 못 바꾼다.

## `/kickoff` — 아이디어를 과제로

`commands/kickoff.md` 는 Claude Code 슬래시 커맨드다. 한 번 걸어둔다:

```bash
mkdir -p ~/.claude/commands
ln -s ~/workflows/commands/kickoff.md ~/.claude/commands/kickoff.md
```

**심볼릭 링크인 이유**: 커맨드 본문이 이 저장소에 살아야 벽 안에서 버전 관리되고,
`git pull` 만으로 갱신이 전파된다. `~/.claude/` 에 사본을 두면 어느 쪽이 최신인지 모르게 된다.

인터뷰는 아이디어를 **인수기준이 검사에 매핑된 GitHub 이슈**로 바꾼다.
근거는 `coolbress/standards` 의 `corpus/aspects/01-requirements-planning/elicitation-interview-build-standard.md`
(Mom Test · 정보이득 질문 선택 · EARS · 위험 비례 깊이 8/12/18 · **흔한 실수 목록**).

마지막 항목이 핵심이다 — 실증(RE'25)은 LLM 인터뷰어가 **실수 목록을 쥐고 있을 때만**
사람보다 나은 후속 질문을 한다는 것을 보였다. 그래서 그 표가 커맨드 안에 들어 있다.

## 이 저장소 자신 — **YAML 만 검사하면 절반이다**

여기가 깨지면 부르는 쪽이 **전부** 깨진다. 그런데 이 저장소에서 실행되는 것은 워크플로만이 아니다 —
`new-project.sh` 는 저장소를 **만들고 지우고**, `ruleset.json` 은 새 저장소의 **벽 그 자체**가 된다.
`integrity` 잡이 다섯 가지를 본다:

| 검사 | 무엇을 막나 |
|---|---|
| `actionlint` | 워크플로 문법·사용법 — **공식 릴리스 바이너리 + SHA256 검증**(아래) |
| `bash -n` | 셸 문법 |
| `shellcheck` | 셸 정적 결함 |
| **`tools/check-ruleset.sh`** | **벽이 벽인가** — 우회자 0 · 강제 적용 · squash 전용 · 검사 4종과 **출처(App 15368)** · strict |
| **`tests/new-project-failpath.sh`** | **fail-closed** — `gh` 를 목으로 바꿔 **모든 단계에서 실패시켜 보고**, 어디서 넘어지든 원격 저장소가 남지 않는지 확인한다. **개수는 여기 적지 않는다** — 시험 파일이 정본이다 |

### 🔴 actionlint 를 `docker://` 로 쓰지 않는 이유

그 형태가 **두 번 값을 치렀다**:

| 층 | 무엇이 안 됐나 |
|---|---|
| **Actions allowlist** | 패턴에 `docker://` 가 안 들어가 **이 저장소만 allowlist 를 못 걸었다**(`startup_failure`) |
| **의존성 그래프** | SBOM 에 안 잡혀 **경보도 Dependabot 갱신 PR 도 오지 않았다** |

`rhysd/actionlint` 에는 **공식 Action 이 없다**(Docker 이미지뿐이다).
제3자 래퍼를 **중앙 저장소**에 들이는 대신 **공식 릴리스 바이너리를 SHA256 으로 검증해** 쓴다 —
다이제스트 핀과 같은 보장(바뀌면 실패)을 주면서 allowlist 를 막지 않는다.

⚠️ **의존성 그래프는 여전히 못 본다.** 감수한다 — 린터는 **CI 안에서만 돌고 산출물에 섞이지 않는다.**
대신 **버전과 체크섬을 한 줄에 같이 둬서** 올릴 때 둘을 함께 바꾸게 만들었다.

그리고 **`canary` 잡이 `python-ci.yml` 을 실제로 호출한다.**
`actionlint` 가 통과한 것과 **워크플로가 도는 것**은 다른 문장이라서다 —
소비자가 깨지기 전에 [`canary/`](canary/) 의 최소 프로젝트에서 먼저 깨진다.

**이 저장소의 룰셋은 `ruleset.json` 과 다르다.** 여기 `integrity` 잡은 재사용 호출이 아니라
평범한 잡이라 체크 이름이 그냥 `integrity` 다. `ruleset.json` 은 **재사용 워크플로를 부르는
프로젝트용**이고, 그래서 `ci / *` 네 개를 요구한다.

## 규율

- **Actions 는 커밋 SHA 로 핀한다.** 태그는 가변이라 공급망 벡터다
- **`permissions:` 는 최소로.** 기본 토큰은 write-broad 다
- `main` 은 보호돼 있다 — 브랜치 → PR → CI 초록 → 머지

## 버전 — SemVer 로 태그한다

**이 저장소만 릴리스를 한다** (소유자 결정 2026-08-26 · `standards` 의 `direction/05` §릴리스).
이유는 하나다 — **여기만 남이 참조하는 쪽**이다:

```yaml
uses: coolbress/workflows/.github/workflows/python-ci.yml@<SHA>  # v1.0.0
```

**핀은 반드시 커밋 SHA 로 한다** — 태그는 가변이라 공급망 벡터다(GitHub 자신이 *"only a full-length
commit SHA is immutable"* 이라 규정한다). **태그는 그 SHA 가 무엇인지 읽기 위한 것**이지 핀 대상이 아니다.
그래서 위처럼 **SHA 로 핀하고 옆에 버전을 주석으로 적는다.**

| 무엇이 바뀌면 | 올린다 |
|---|---|
| **MAJOR** | 호출부가 고쳐야 하는 변경 — **잡 이름**, 필수 입력 추가/제거, 검사 이름(`ci / *`) |
| **MINOR** | 호환되는 추가 — 새 선택 입력, 새 잡(요구 검사에 안 들어가는), 새 워크플로 파일 |
| **PATCH** | 동작이 같은 수정 — Action SHA 갱신, 버그 수정, 문서 |

🔴 **잡 이름 변경은 언제나 MAJOR 다.** 검사 이름이 `{호출잡}/{피호출잡}` 이라, 바뀌는 순간
**소비자의 룰셋이 요구하는 이름이 영원히 보고되지 않고 저장소가 조용히 머지 불가로 잠긴다.**
위 *"잡 이름 `ci` 를 바꾸지 마라"* 절과 같은 이야기다.

릴리스마다 **GitHub Release 에 변경 요약**을 적는다 — 호출부가 올릴지 말지를 그것만 보고 판단할 수 있게.

## 근거

설계 근거는 [`coolbress/standards`](https://github.com/coolbress/standards) 가 갖는다:
`corpus/aspects/04-build-ci-engineering/` (재사용 층의 경계 · 바닥 체크리스트) ·
`direction/04-the-plan.md` (만들 것 ②) · `direction/05-the-output-floor.md` (산출물 바닥 12묶음).
