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
ci / lint    ci / typecheck    ci / test    ci / build    ci / secrets    ci / diff-size
```

`lint` 가 아니라 **`ci / lint`** 다. 그래서 [`ruleset.json`](ruleset.json) 의
`required_status_checks` 도 **그 이름을 그대로** 요구한다. **무엇을 몇 개 요구하는지의 정본은
그 파일 하나다** — 여기 나열하지 않는다(그러다 문서마다 숫자가 달라진 적이 있다).

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
| `python-ci.yml` | `lint` · `typecheck` · `test` · `build` · `secrets` · `diff-size` · `pr-title` — **각각 별도 검사** | uv 프로젝트 · `uv.lock` 커밋됨 · ruff · mypy · pytest |
| `pr-label.yml` | *(검사 아님)* PR 제목의 타입을 **라벨로** 옮긴다 | 호출부가 `pull-requests: write` 를 준다 |

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

### 📏 `diff-size` — **문서에만 있는 규칙은 발화하지 않는다**

`coolbress/divcal` #1 이 이 잡을 만들었다. 이슈 본문에 *"PR diff 400줄 이하"* 라고 **직접 써놓고
436줄을 냈는데 룰셋도 CI 도 아무것도 막지 않았다.** 작성자가 자진 신고해서 알았을 뿐이다.

왜 지금 필요한가 — 실측(2026):

| | |
|---|---|
| AI 보조 PR 의 크기 | 사람 PR 의 **2.6배** (p75 408줄 대 157줄) |
| 에이전트가 연 PR 의 리뷰어 픽업 대기 | **5.3배** (1,055분 대 201분) |
| 리뷰 공수를 예측하는 것 | **diff 크기.** PR 본문 텍스트는 AUC 0.57 로 사실상 무의미 (arXiv 2601.00753) |

**계량기가 규칙만큼 중요하다.** 같은 PR 을 이 잡으로 다시 재봤다:

```
전부 세면          452줄 (+436 / -16)   → 초과
문서·락파일 제외    385줄 (+375 / -10)   → 통과
```

**규칙이 틀린 게 아니라 계량기가 틀렸었다.** README 산문 한 줄이 `mypy --strict` 를 통과해야
하는 코드 한 줄과 같은 무게로 세어지고 있었다. 그래서 기본 제외가
`*.md *.lock *lock.json *lock.yaml *lock.yml LICENSE` 다.

🔴 **PR 이 아닐 때도 잡을 건너뛰지 않는다.** `if:` 로 잡을 통째로 건너뛰면 검사 이름이
보고되지 않는 경로가 생기고, 룰셋이 언젠가 그 이름을 요구하는 순간 저장소가 조용히
머지 불가로 잠긴다. 조건은 **스텝 안**에 있고 통과로 보고한다.

✅ **`ruleset.json` 에 들어 있다 — 이제 새 저장소는 처음부터 강제된다.**
순서를 지켜서 넣었다. 소비자는 이 저장소를 **SHA 로 핀**하므로, 룰셋이 `ci / diff-size` 를
요구하는데 **옛 SHA 를 핀한 저장소는 그 이름을 영원히 보고하지 못하고 잠긴다.**

```
① 잡 머지 (v3.2.0)  →  ② project-template 이 v3.2.0 핀  →  ③ ruleset.json 에 추가 ← 지금
```

🔴 **기존 저장소는 자동으로 안 바뀐다.** `ruleset.json` 은 **새 저장소**에만 적용된다.
올리기 전에 그 저장소가 **v3.2.0 이상을 핀했는지 먼저 확인해라** — 안 그러면 잠근다:

```bash
./tools/upgrade-ruleset.sh --dry-run coolbress/<repo> 'ci / diff-size:15368'
```

⚠️ **이 저장소 자신은 context 이름이 다르다.** 여기 호출잡 이름은 `ci` 가 아니라 `canary` 라
검사가 **`canary / diff-size`** 로 보고된다. `ci / diff-size` 를 요구하면 그 이름이 영원히
보고되지 않아 **자기잠금**이다.

**선택 입력** — `working-directory`(기본 `.`). 프로젝트 루트가 저장소 루트가 아닐 때만 쓴다.
이 저장소의 canary 잡이 이걸로 자기 자신을 호출한다.
`max-diff-lines`(기본 `400` · `0` 이면 재기만 한다) · `diff-size-exclude`(계수에서 뺄 pathspec).

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
~/workflows/tools/with-admin-token.sh ~/workflows/new-project.sh <이름> --archetype=service
```

🔴 **저장소 안에서 돌리면 멈춘다.** `gh repo create --clone` 은 **현재 폴더**에 복제하므로
`~/workflows` 에서 돌리면 `~/workflows/<이름>` — **저장소 안에 저장소**가 된다.
문서로 당부하는 대신 **스크립트가 막는다.**

⚠️ **기본은 공개 · MIT · `cli` 다.** 다른 라이선스면 `--license=<spdx>`, 다른 종류면
`--archetype=<cli|library|service|data-ml>` 를 준다.

🔵 **아키타입이 조건부 산출물을 정한다** — 바닥(`standards` `direction/05`)이 아키타입으로
조건을 건다(`.env.example` 은 *12-Factor 는 service 맥락* 이다). copier 의 `_exclude` 가
그 조건을 집행하므로 **파일을 지우는 게 아니라 애초에 안 만든다** — 스텁이 안 남는다.
**모르겠으면 가장 좁은 것(`cli`)** 을 고른다: 넓히는 것은 파일을 더하는 일이고,
좁히는 것은 안 쓰는 파일을 지우는 일이라 스텁으로 남는다.

### 🔴 `--template` 이 아니라 **빈 저장소 + copier** 다

`gh repo create --template` 은 **시점 복사**라 복사가 끝나면 원본과 **연결이 끊긴다** —
템플릿을 고쳐도 인스턴스는 그대로다. 2026-08-28 하루에만 *"기존 인스턴스는 자동으로
안 바뀐다"* 를 **세 번** 적었다.

copier 는 인스턴스에 **`.copier-answers.yml`** 을 남겨 *어느 판에서 태어났는지* 기억하고,
나중에 **`copier update`** 로 그 뒤의 템플릿 변경만 골라 **병합**한다.

⚠️ **빈 저장소를 클론하면 로컬 HEAD 가 `init.defaultBranch` 를 따른다.** 그게 `master` 면
룰셋이 거는 `~DEFAULT_BRANCH`(=`main`)와 어긋나 **벽이 빈 브랜치를 지키게 된다.**
그래서 클론 직후 `symbolic-ref HEAD refs/heads/main` 으로 못박는다.

🔵 **fail-closed 는 그대로다** — 보증은 `trap cleanup EXIT` 하나이고 **콘텐츠가 어떻게
들어오는지와 무관**하다. 실패경로 시험에 `copier` 단계를 더해 **15/15** 로 확인했다.

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

🔵 **이름 치환은 렌더에서 끝난다** (`project-template` **v2.0.0** 부터).
이름·라이선스·패키지 디렉터리·`uv.lock` 이 전부 copier 의 jinja 로 정해져 나오므로
**뒤에 고칠 것도, 지울 생성기도 없다.** 이전 판은 `bootstrap.sh` 78줄을 인스턴스에 실어 보내
치환한 뒤 스스로를 지우게 했다 — 그건 **파일을 만든 뒤에 고치는** 방식이라
틀린 이름이 트리를 반쯤 바꿔놓은 뒤에야 걸렸다.
⚠️ 못 만들 이름(`9lives`·`class`·`my+app`)은 이제 **copier 의 `validator` 가
파일을 하나도 만들기 전에** 거절하고, 그러면 아래 fail-closed 가 저장소를 지운다.

이 스크립트의 **책임은 둘뿐이다** — 저장소 생성과 **서버 바닥 설치**(벽 · 시크릿 탐지 · Dependabot · Actions SHA 강제 · 머지 방법).
그 이상은 하지 않는다. ⚠️ **이전 판의 *"로직은 9줄"* 은 지웠다** — 줄 수는 책임 경계를 재는 자가 아니고,
실제로도 맞지 않았다. 판정 기준은 **이 두 책임 밖의 일이 들어왔는가**다.

**fail-closed**: 어느 단계에서 실패하든 **원격 저장소를 남기지 않는다.** 벽 없는 저장소가 남는 것이
이 프로젝트가 죽는 방식이기 때문이다.

### 라이선스는 인자로 받는다

라이선스는 **GitHub 공식 라이선스 API 의 본문**을 그대로 쓴다(`/licenses/<spdx>`).
교체는 **룰셋을 걸기 전에** 한다 — 건 뒤에는 `main` 직접 푸시가 막혀 PR 없이 못 바꾼다.

## 플러그인 — `/kickoff` 과 `/new-project`

**이 저장소가 마켓플레이스다.** 커맨드와 스킬은 플러그인으로 배포한다:

```bash
claude plugin marketplace add coolbress/workflows
claude plugin install coolbress-standards@coolbress
```

담는 것: `/kickoff`(아이디어 → 과제) · `/new-project`(벽이 선 저장소) ·
`where-is-the-truth` 스킬(정본이 어디 있나). **훅 없음** — 기본 프로필이다.

🔴 **벽은 플러그인에 안 들어간다.** 들어가는 순간 에이전트가 끌 수 있고, 그러면 벽이 아니다.
플러그인은 **벽을 세우는 도구**를 담을 뿐이고 벽 자체는 GitHub 에 남는다.

### 프로필 둘 — **플러그인 둘이다**

| | 담는 것 |
|---|---|
| `coolbress-standards` | 커맨드·스킬. **훅 없음** |
| `coolbress-standards-hooks` | 위 + **세션 시작 훅** + `ponytail`. **훅은 여기에만** |

```bash
claude plugin install coolbress-standards-hooks@coolbress   # +훅
```

🔴 **Claude Code 에는 프로필 개념이 없다.** ECC 는 그걸 **자체 설치 스크립트**로 만드는데,
**설치기는 하네스의 시작이다.** 우리는 네이티브 `dependencies` 로 같은 것을 얻는다.

### 의존성이 사는 마켓플레이스

`mattpocock-skills` 는 **공식 마켓**에 있어 그냥 잡힌다. 나머지는 마켓을 먼저 더한다:

```bash
claude plugin marketplace add Leonxlnx/taste-skill
claude plugin marketplace add mvanhorn/last30days-skill
claude plugin marketplace add DietrichGebert/ponytail   # +훅 쪽만 필요
```

⚠️ **미검증 가정 하나** — 다른 마켓의 플러그인을 `dependencies` 로 거는 것이
**마켓을 먼저 더하지 않아도** 풀리는지 확인하지 않았다. 안 풀리면 위 세 줄이 **선행 조건**이다.

> 🔵 **왜 심볼릭 링크에서 플러그인으로 옮겼나** (2026-08-29)
> 옛 방식은 `ln -s ~/workflows/commands/kickoff.md ~/.claude/commands/` 였다 — **사람이 매 기계에서
> 손으로** 걸어야 했고, 새 커맨드가 늘 때마다 한 줄씩 늘었다. 플러그인은 **버전과 핀이 공짜**로 따라오고
> 의존성(`mattpocock-skills` 등)까지 **전이적으로** 켜준다.
> ⚠️ 옛 경로(`commands/`)는 **심볼릭 링크로 남겨** 이미 걸어둔 링크가 안 깨진다.

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
프로젝트용**이고, 그래서 `ci / *` 를 요구한다.

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

**`project-template` 도 이제 릴리스한다** (2026-08-28 · `standards` R5-33). 규칙은 안 바뀌었고
사실이 바뀌었다 — copier 로 넘어가면서 인스턴스의 `.copier-answers.yml` 이 템플릿을 참조한다.

### 🏷️ PR 제목 · 라벨 · 릴리스 노트는 **한 줄기**다

```
PR 제목  ──ci / pr-title 이 강제──→  타입이 표준 11종인가
   │
   └──label.yml 이 파생──→  라벨  ──.github/release.yml 이 묶음──→  분류된 색인
```

🔵 **제목이 유일한 출처다.** `actions/labeler` 처럼 파일 경로나 브랜치 이름으로 붙이면
규칙이 **두 곳**(제목 규약 + 라벨러 설정)에 생기고 조용히 갈린다. 사람이 붙이는 일은 **없다.**

**타입은 `@commitlint/config-conventional` 과 같은 11종뿐이다.**
지역 의미는 **scope** 로 쓴다 — `docs(research):` · `docs(decision):` · `refactor(layout):`.
근거는 `standards` [`direction/05`](https://github.com/coolbress/standards/blob/main/direction/05-the-output-floor.md) §정정
(2026-08-28): 확장 어휘를 문서에 적어두는 방식이 **하루를 못 버텼다.**

✅ **`ci / pr-title` 은 `ruleset.json` 에 들어갔다** (v3.6.0) — **새 저장소는 처음부터 벽이다.**
순서를 지켜서 넣었다: v3.5.0 배포 → 모든 소비자 핀 갱신 → **그다음** 룰셋.

⚠️ **기존 저장소는 소유자가 올려야 한다** — 옛 SHA 에 핀된 저장소에 이 검사를 요구하면
그 잡이 없어 **검사 이름이 영원히 보고되지 않아 저장소가 잠긴다.** 순서는 언제나 **핀 → 룰셋**이다.

```bash
./tools/upgrade-ruleset.sh --dry-run coolbress/<repo> 'ci / pr-title:15368'   # 읽기만
cd ~ && ~/workflows/tools/with-admin-token.sh \
  ~/workflows/tools/upgrade-ruleset.sh coolbress/<repo> 'ci / pr-title:15368'
```

### 어떻게 만드나 — **왜**는 사람이 쓰고 **무엇**은 GitHub 이 만든다

```bash
tools/make-release.sh v3.4.0 /tmp/why.md      # 태그는 미리 밀어둔다
```

`--notes-file` 로 손으로 쓴 *왜* 를 얹고 `--generate-notes` 로 *무엇* 을 붙인다
(`gh` 문서: *"Additional release notes can be **prepended** to the automatically generated notes"*).
🔴 **빈 노트파일은 거부한다** — 받아주면 이 도구는 `--generate-notes` 의 별칭이 되고,
그러면 릴리스마다 *왜* 가 사라진다. `tests/make-release-guards.sh` 가 그 성질을 지킨다.

🔬 **왜 생성기만으로는 안 되나** (2026-08-28 실측). v3.2.0 → v3.3.0 에 돌린 결과는 전부 이것이다 —

```
## What's Changed
* feat(ruleset): ci / diff-size 를 요구 검사로 만든다 by @coolbress in .../pull/26
**Full Changelog**: .../compare/v3.2.0...v3.3.0
```

손으로 쓴 같은 릴리스의 노트에는 *"빨간 X 가 보이는 것과 머지가 막히는 것은 다른 문장이다"* 와
*"`uses:` 로 부르는 쪽은 핀을 올릴 이유가 없다"* 가 있다. **소비자가 뭘 해야 하는가는 커밋 로그에 없다.**
생성기는 우리 노트의 열등한 판이 아니라 **다른 물건**이다 — 설명이 아니라 **색인**이다.

✅ **라벨은 이제 자동이다** (2026-08-28). `label.yml` 이 제목의 타입에서 파생시키고
`.github/release.yml` 이 그 라벨로 묶는다. **사람이 붙이는 일은 없다.**
🔴 `release.yml` 에 `labels: ["*"]` catch-all 을 반드시 남긴다 — 라벨링은 벽이 아니라 편의라
실패할 수 있고, 그때 그 PR 이 노트에서 **조용히 사라지면 안 된다.**

## 근거

설계 근거는 [`coolbress/standards`](https://github.com/coolbress/standards) 가 갖는다:
`corpus/aspects/04-build-ci-engineering/` (재사용 층의 경계 · 바닥 체크리스트) ·
`direction/04-the-plan.md` (만들 것 ②) · `direction/05-the-output-floor.md` (산출물 바닥 12묶음).
