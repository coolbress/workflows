#!/usr/bin/env bash
# `with-admin-token.sh` 가 토큰을 **터미널에서** 읽는지 본다. 네트워크는 안 탄다.
#
# 지켜야 하는 성질: **stdin 을 먹지 않는다.**
# 왜 벽이어야 하나 — 관리자 명령을 여러 줄 붙여넣으면 셸이 나머지 줄을 버퍼에 들고 있다가
# 스크립트의 `read` 에 넘긴다. 그러면 **다음 명령줄이 토큰으로 삼켜지고 그 명령은 조용히
# 사라진다.** 실측(2026-08-30): 룰셋 갱신 세 줄을 한 번에 붙여넣었다.
#
# pty 를 실제로 띄운다 — `/dev/tty` 가 없으면 이 성질 자체를 확인할 수 없기 때문이다.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  PASS  $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1"; }

# ── ① 실물: pty 를 controlling terminal 로 주고, stdin 은 **파이프**로 따로 준다.
out="$(python3 - "$root/tools/with-admin-token.sh" <<'PY' 2>&1
import os, pty, sys, select, time

script = sys.argv[1]
r, w = os.pipe()
os.write(w, b"LINE_FROM_PASTE\n"); os.close(w)

pid, master = pty.fork()          # slave 가 자식의 controlling terminal 이 된다
if pid == 0:
    os.dup2(r, 0)                 # 🔴 stdin 만 파이프로 바꾼다 — /dev/tty 는 그대로 pty
    # exec 되는 명령은 남은 stdin 을 그대로 뱉는다. 먹혔으면 아무것도 안 나온다.
    # 🔴 셔뱅으로 실행한다. `/bin/sh script` 로 부르면 우분투에선 dash 가 받아
    # `set -o pipefail` 에서 죽는다 — macOS 는 /bin/sh 가 bash 라 안 보인다(CI 가 잡았다).
    os.execv(script, [script, "/bin/sh", "-c", "cat"])
    os._exit(127)

os.write(master, b"ghp_" + b"x" * 36 + b"\n")
buf, deadline = b"", time.time() + 15
while time.time() < deadline:
    if not select.select([master], [], [], 0.5)[0]:
        if os.waitpid(pid, os.WNOHANG)[0]: break
        continue
    try:
        chunk = os.read(master, 4096)
    except OSError:
        break
    if not chunk: break
    buf += chunk
    if b"LINE_FROM_PASTE" in buf: break
sys.stdout.write(buf.decode("utf-8", "replace"))
PY
)"

case "$out" in
  *LINE_FROM_PASTE*) ok "붙여넣은 다음 줄이 stdin 에 남아 있다 (삼켜지지 않았다)" ;;
  *) bad "stdin 이 먹혔다 — 다음 명령줄이 토큰으로 사라진다"; printf '%s\n' "$out" | sed 's/^/        /' ;;
esac
case "$out" in
  *"길이 40"*) ok "토큰은 터미널에서 읽혔다 (모양 확인 줄이 나온다)" ;;
  *) bad "터미널 입력을 못 읽었다" ;;
esac

# ── ② tty 가 없는 환경(CI 스텝·파이프)에서는 stdin 으로 되돌아간다. 안 그러면 자동화가 막힌다.
if printf 'ghp_%036d\n' 0 | "$root/tools/with-admin-token.sh" /bin/sh -c 'exit 0' >/dev/null 2>&1 </dev/null
then bad "빈 stdin 인데 통과했다"
else ok "빈 입력은 거부한다"; fi

echo "── $pass 통과 · $fail 실패"
[ "$fail" = 0 ]
