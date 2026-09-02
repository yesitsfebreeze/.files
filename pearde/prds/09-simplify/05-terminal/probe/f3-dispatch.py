#!/usr/bin/env python3
"""R7 probe: does the F3 `command-prompt -p search "display-popup ... %1"` root
binding actually dispatch?  A display-popup needs an ATTACHED client, so this
drives a real client on a pty rather than a detached `new-session -d` server."""
import os, pty, subprocess, sys, time, shutil

SOCK = "probeF3"
CONF = "/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"
TMUX = shutil.which("tmux")

def t(*a, **kw):
    return subprocess.run([TMUX, "-L", SOCK, *a], capture_output=True, text=True, **kw)

t("kill-server")
time.sleep(0.3)
# a stub tv-all so nothing real is launched; it just records that it ran
stub = "/tmp/f3probe-bin"
os.makedirs(stub, exist_ok=True)
open(stub + "/tv-all", "w").write(
    '#!/bin/sh\nprintf "%s\\n" "TVALL-RAN argv=[$*] origin=$TV_ALL_ORIGIN cwd=$PWD" >> /tmp/f3probe.log\nsleep 2\n')
os.chmod(stub + "/tv-all", 0o755)
try: os.remove("/tmp/f3probe.log")
except FileNotFoundError: pass

pid, fd = pty.fork()
if pid == 0:
    os.environ["TERM"] = "xterm-256color"
    os.environ["PATH"] = stub + ":" + os.environ["PATH"]
    os.execv(TMUX, [TMUX, "-L", SOCK, "-f", CONF, "new-session", "-x", "120", "-y", "40"])
time.sleep(1.5)

# rebind F3 at the same shape but pointing at the stub on PATH
t("bind-key", "-n", "F3", "command-prompt", "-p", "search",
  "display-popup -E -B -w 90% -h 85% -x C -y C -d '#{E:@cwd}' "
  "-e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %1'")

print("clients:", t("list-clients", "-F", "#{client_tty} #{client_name}").stdout.strip() or "NONE")

def drain():
    import select
    out = b""
    while select.select([fd], [], [], 0.4)[0]:
        try: c = os.read(fd, 65536)
        except OSError: break
        if not c: break
        out += c
    return out.decode("utf8", "replace")

def key(seq, wait=0.8):
    os.write(fd, seq); time.sleep(wait); return drain()

drain()
print("=== 1. press F3 ===")
key(b"\x1bOR")
print("prompt visible:", "search" in t("display-message", "-p", "#{client_prompt}").stdout)
print("client_prompt =", repr(t("display-message", "-p", "#{client_prompt}").stdout.strip()))

print("=== 2. Escape cancels ===")
key(b"\x1b")
print("prompt after Escape =", repr(t("display-message", "-p", "#{client_prompt}").stdout.strip()))
print("popup open after Escape:", t("display-message", "-p", "#{?client_flags,#{client_flags},-}").stdout.strip())
print("tv-all ran:", os.path.exists("/tmp/f3probe.log"))

print("=== 3. F3 then a query then Enter ===")
key(b"\x1bOR")
key(b"needle")
scr = key(b"\r", wait=2.0)
time.sleep(1.0)
try: log = open("/tmp/f3probe.log").read()
except FileNotFoundError: log = "(no log — tv-all never ran)"
print("tv-all log:", log.strip() or "(empty)")
print("--- last of client screen ---")
print("\n".join(l for l in scr.splitlines() if "unknown command" in l or "invalid" in l or "error" in l.lower()) or "(no error lines on the client)")

t("kill-server")
os.close(fd)
