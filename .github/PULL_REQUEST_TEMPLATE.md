<!-- 제목은 Conventional Commits 로: type(scope): 요약
     형태의 근거는 census 다 — 중앙값 3절 · 빈 체크리스트 62%(중앙값 5항목) ·
     인라인 HTML 주석 70% · "type of change" 는 11.5%뿐이라 CC 를 쓰면 뺀다.
     (coolbress/standards · corpus/aspects/24-.../issue-pr-writing-conventions.md) -->

## 무엇을 왜

<!-- 결론부터. 무엇을 바꿨고 왜 필요했는지. -->

## 어떻게 확인했나

<!-- 돌린 것과 결과. 재사용 워크플로를 고쳤다면 실제로 호출해 본 결과를 붙인다. -->

## 확인

- [ ] `actionlint` 통과 (CI `integrity`)
- [ ] Actions 를 **커밋 SHA 로 핀**했다 (태그는 가변 = 공급망 벡터)
- [ ] 워크플로마다 `permissions:` 를 최소로 뒀다
- [ ] **잡 이름을 바꾸지 않았다** — 검사 이름은 `{호출잡}/{피호출잡}` 이라 바꾸면 소비자 룰셋이 조용히 미충족된다
- [ ] `ruleset.json` 을 고쳤다면 요구 검사 이름이 실제 잡과 일치한다
