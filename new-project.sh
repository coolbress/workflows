#!/usr/bin/env bash
# 새 프로젝트 하나 만든다. 사람이 손으로 하면 빠뜨리는 것만 한다.
#   사용법: ./new-project.sh <이름>
set -euo pipefail

name="${1:?사용법: new-project.sh <이름>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

gh repo create "coolbress/$name" --public --template coolbress/project-template --clone

# 벽. 템플릿은 파일만 옮기고 룰셋은 안 옮긴다 (CPR-001).
gh api "repos/coolbress/$name/rulesets" -X POST --input "$here/ruleset.json" >/dev/null

# 시크릿 탐지 + 푸시 보호. 켜지 않으면 기본이 꺼짐이다.
gh api "repos/coolbress/$name" -X PATCH \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null

echo "완료 → https://github.com/coolbress/$name"
