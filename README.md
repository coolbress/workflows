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

## 이 저장소 자신

`ci.yml` 이 actionlint 로 자기 워크플로를 검사한다. 여기가 깨지면 부르는 쪽이 전부 깨진다.

## 규율

- **Actions 는 커밋 SHA 로 핀한다.** 태그는 가변이라 공급망 벡터다
- **`permissions:` 는 최소로.** 기본 토큰은 write-broad 다
- `main` 은 보호돼 있다 — 브랜치 → PR → CI 초록 → 머지

## 근거

설계 근거는 [`coolbress/standards`](https://github.com/coolbress/standards) 가 갖는다:
`corpus/aspects/04-build-ci-engineering/` (재사용 층의 경계 · 바닥 체크리스트) ·
`direction/04-the-plan.md` (만들 것 ②) · `direction/05-the-output-floor.md` (MUST 49).
