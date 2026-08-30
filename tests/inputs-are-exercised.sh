#!/usr/bin/env bash
# 재사용 워크플로의 **입력이 실제로 넘겨지는가.**
#
# 🔴 왜 필요했나 (2026-08-30 실측): `extra-python-versions` 를 만들었는데 **아무도 안 넘겼다.**
# 그 입력은 `if: inputs.extra-python-versions != ''` 로 막힌 스텝을 켠다 — 안 넘기면
# **그 코드 경로가 아무 데서도 안 돈다.** 그리고 CI 는 초록이다.
#
# **선언한 것과 도는 것은 다른 문장이다** — `all-tests-are-wired.sh` 와 같은 병이다.
#
# ⚠️ **`if:` 로 막힌 입력만 막는다.** 기본값으로도 경로가 도는 입력(예: `max-diff-lines`)은
# 안 넘겨도 그 코드가 실행된다 — 그것까지 요구하면 오탐이 신호를 묻는다.
# 그런 것은 아래에 INFO 로 적기만 한다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$root" <<'PY'
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
wf = root / ".github" / "workflows"
files = sorted(wf.glob("*.yml"))


def declared(text: str) -> list[str]:
    if "workflow_call" not in text:
        return []
    block = text.split("workflow_call", 1)[1].split("\njobs:", 1)[0]
    return re.findall(r"^      ([a-z][a-z0-9-]*):\s*$", block, re.M)


def gated(text: str, name: str) -> bool:
    """그 입력이 `if:` 조건에 쓰이는가 — 쓰이면 안 넘길 때 경로가 통째로 안 돈다."""
    return any(
        f"inputs.{name}" in line
        for line in text.splitlines()
        if re.match(r"^\s*if:", line)
    )


def passed_keys(text: str) -> set[str]:
    """`with:` 블록 안의 키만 모은다 — 선언부(`inputs:`)를 세면 항상 통과한다."""
    out: set[str] = set()
    indent = None
    for line in text.splitlines():
        if indent is not None:
            m = re.match(r"^(\s+)([a-z][a-z0-9-]*):", line)
            if m and len(m.group(1)) > indent:
                out.add(m.group(2))
                continue
            if line.strip() and not line.strip().startswith("#"):
                indent = None
        m = re.match(r"^(\s*)with:\s*$", line)
        if m:
            indent = len(m.group(1))
    return out


passed: set[str] = set()
for f in files:
    passed |= passed_keys(f.read_text(encoding="utf-8"))

blocking, info = [], []
for f in files:
    text = f.read_text(encoding="utf-8")
    for name in declared(text):
        if name in passed:
            continue
        (blocking if gated(text, name) else info).append(f"{f.name}: {name}")

for item in info:
    print(f"  INFO  아무도 안 넘긴다 (기본값으로 경로는 돈다) — {item}")

if blocking:
    print("🔴 `if:` 로 막힌 입력을 아무도 안 넘긴다 — 그 경로는 **아무 데서도 안 돈다**:")
    for item in blocking:
        print(f"     {item}")
    print("   카나리가 넘기게 해라. 선언한 것과 도는 것은 다른 문장이다.")
    sys.exit(1)

print("  PASS  `if:` 로 막힌 입력은 전부 실제로 넘겨진다")
PY
