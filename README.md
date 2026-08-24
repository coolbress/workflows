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
`required_status_checks` 도 그 이름을 그대로 요구한다.

**호출잡 이름을 바꾸면 네 검사가 전부 다른 이름으로 보고되고, 룰셋이 요구하는 이름은
영원히 보고되지 않는다 — 저장소가 머지 불가 상태로 조용히 잠긴다.** 검사는 초록인데
머지 버튼은 막혀 있는 형태라 원인을 찾기 어렵다.

바꾸려면 `ruleset.json` 의 네 context 를 같이 바꾼다.

## 있는 것

| 워크플로 | 검사 | 전제 |
|---|---|---|
| `python-ci.yml` | `lint` · `typecheck` · `test` · `build` **4개 별도 검사** | uv 프로젝트 · `uv.lock` 커밋됨 · ruff · mypy · pytest |

### 왜 4개로 쪼갰나

산출물 바닥이 *"lint·typecheck·test·build를 **각각 별도 required check**로"* 를 MUST 로 요구한다.
한 잡에 4스텝으로 넣으면 첫 실패에서 멈춰 나머지 3개의 상태를 알 수 없고,
브랜치 룰셋이 개별 검사를 요구할 수도 없다.

### 전제가 강하다

`uv sync --locked` 는 **락파일이 없거나 `pyproject.toml` 과 어긋나면 실패한다.**
검사 항목이 아니라 **전제**로 둔 것이다 — 락파일 커밋은 바닥의 MUST 이므로
"없으면 통과"가 될 자리가 없다.

## 새 프로젝트 만들기

```bash
./new-project.sh <이름>
```

세 가지를 한다 — **손으로 하면 빠뜨리는 것만**:

1. `coolbress/project-template` 에서 저장소를 뜬다
2. `ruleset.json` 으로 **벽을 건다** — 템플릿은 파일만 옮기고 룰셋은 안 옮긴다(CPR-001)
3. **시크릿 탐지 + 푸시 보호**를 켠다 — 기본이 꺼짐이다

로직은 9줄이다. 늘어나면 설정 층에 로직이 새고 있다는 신호다.

## 이 저장소 자신

`ci.yml` 이 actionlint 로 자기 워크플로를 검사한다. 여기가 깨지면 부르는 쪽이 전부 깨진다.

**이 저장소의 룰셋은 `ruleset.json` 과 다르다.** 여기 `integrity` 잡은 재사용 호출이 아니라
평범한 잡이라 체크 이름이 그냥 `integrity` 다. `ruleset.json` 은 **재사용 워크플로를 부르는
프로젝트용**이고, 그래서 `ci / *` 네 개를 요구한다.

## 규율

- **Actions 는 커밋 SHA 로 핀한다.** 태그는 가변이라 공급망 벡터다
- **`permissions:` 는 최소로.** 기본 토큰은 write-broad 다
- `main` 은 보호돼 있다 — 브랜치 → PR → CI 초록 → 머지

## 근거

설계 근거는 [`coolbress/standards`](https://github.com/coolbress/standards) 가 갖는다:
`corpus/aspects/04-build-ci-engineering/` (재사용 층의 경계 · 바닥 체크리스트) ·
`direction/04-the-plan.md` (만들 것 ②) · `direction/05-the-output-floor.md` (MUST 49).
