#!/usr/bin/env bash
# C-2 코퍼스 생성기 — **취약 코드를 저장소에 커밋하지 않기 위해** 런타임에 만든다.
#   사용법: ./research/make-c2-corpus.sh <출력디렉터리>
#
# 심는 것 9종(전부 Python) + **같은 일을 안전하게 한 쌍둥이 파일** 하나.
#   vulnerable.py → 탐지되면 TP
#   safe.py       → 탐지되면 FP
#
# ⚠️ 이건 마이크로 벤치마크다(n=9). "어느 도구가 낫나" 가 아니라
#    **"뻔한 부류를 잡나"** 에만 답한다. 한정은 결과 문서에 적는다.
set -euo pipefail
out="${1:?사용법: make-c2-corpus.sh <출력디렉터리>}"
mkdir -p "$out"

cat > "$out/vulnerable.py" <<'PY'
"""심은 취약점 9종. 각 함수 하나가 하나의 부류다."""
import hashlib
import os
import pickle
import sqlite3
import subprocess

import requests
import yaml

DB_PASSWORD = "correct-horse-battery-staple"  # 6. 하드코딩 자격증명
# ⚠️ 공급자 형식(sk_live_… 등)을 쓰지 않는다 — 이 저장소의 **푸시 보호가 실제로 막았다**.
# 그 자체가 C-3 의 실측이라 결과 문서에 적었다. 여기서는 일반 하드코딩 자격증명만 심는다.


def v1_sql_injection(conn: sqlite3.Connection, user: str):        # 1. SQL 주입
    return conn.execute("SELECT * FROM users WHERE name = '%s'" % user).fetchall()


def v2_command_injection(host: str):                              # 2. 명령 주입
    return subprocess.check_output("ping -c1 " + host, shell=True)


def v3_unsafe_deserialization(blob: bytes):                       # 3. 안전하지 않은 역직렬화
    return pickle.loads(blob)


def v4_path_traversal(name: str):                                 # 4. 경로 순회
    with open(os.path.join("/var/data", name)) as f:
        return f.read()


def v5_weak_crypto(password: str) -> str:                          # 5. 약한 해시
    return hashlib.md5(password.encode()).hexdigest()


def v7_ssrf(url: str):                                            # 7. SSRF
    return requests.get(url, timeout=5).text


def v8_unsafe_yaml(text: str):                                    # 8. 안전하지 않은 YAML
    return yaml.load(text, Loader=yaml.Loader)


def v9_eval(expr: str):                                           # 9. eval
    return eval(expr)
PY

cat > "$out/safe.py" <<'PY'
"""쌍둥이 — 같은 일을 안전하게. 여기서 나온 경보는 전부 오탐이다."""
import ast
import hashlib
import os
import subprocess
from pathlib import Path

import requests
import yaml

DB_PASSWORD = os.environ["DB_PASSWORD"]                           # 6'. 환경에서
ALLOWED_HOSTS = {"api.example.com"}


def s1_sql(conn, user: str):                                      # 1'. 파라미터 바인딩
    return conn.execute("SELECT * FROM users WHERE name = ?", (user,)).fetchall()


def s2_command(host: str):                                        # 2'. 리스트 인자, shell 없음
    return subprocess.check_output(["ping", "-c1", host], shell=False)


def s3_deserialization(blob: bytes):                              # 3'. json
    import json

    return json.loads(blob)


def s4_path(name: str):                                           # 4'. 경계 확인
    base = Path("/var/data").resolve()
    target = (base / name).resolve()
    if not target.is_relative_to(base):
        raise ValueError("경계 밖")
    return target.read_text()


def s5_crypto(password: str, salt: bytes) -> bytes:               # 5'. PBKDF2
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 600_000)


def s7_fetch(host: str, path: str):                               # 7'. 허용 목록
    if host not in ALLOWED_HOSTS:
        raise ValueError("허용되지 않은 host")
    return requests.get(f"https://{host}/{path}", timeout=5).text


def s8_yaml(text: str):                                           # 8'. safe_load
    return yaml.safe_load(text)


def s9_literal(expr: str):                                        # 9'. literal_eval
    return ast.literal_eval(expr)
PY

echo "코퍼스 생성: $out (vulnerable.py · safe.py)"
