#!/usr/bin/env python3
"""R7 verify against the real tmux.conf, driving a real attached client on a
pty (a display-popup is refused with no attached client, which is why a
`new-session -d` server cannot test this at all)."""
import os, pty, subprocess, time, shutil, select, sys
SOCK="probeF3v"; CONF="/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"; TMUX=shutil.which("tmux")
def t(*a): return subprocess.run([TMUX,"-L",SOCK,*a],capture_output=True,text=True)
t("kill-server"); time.sleep(0.3)
stub="/tmp/f3probe-bin"; os.makedirs(stub,exist_ok=True)
# stand in for ~/.local/bin/tv-all so the verify never launches television
os.makedirs("/tmp/f3home/.local/bin",exist_ok=True)
open("/tmp/f3home/.local/bin/tv-all","w").write(
  '#!/bin/sh\nprintf "%s\\n" "RAN argv=[$*] origin=[${TV_ALL_ORIGIN:-UNSET}] cwd=[$PWD]" >> /tmp/f3verify.log\n')
os.chmod("/tmp/f3home/.local/bin/tv-all",0o755); open("/tmp/f3verify.log","w").close()
pid,fd=pty.fork()
if pid==0:
    os.environ.update(TERM="xterm-256color", HOME="/tmp/f3home")
    os.execv(TMUX,[TMUX,"-L",SOCK,"-f",CONF,"new-session","-x","120","-y","40"])
time.sleep(1.6)
def drain():
    o=b""
    while select.select([fd],[],[],0.4)[0]:
        try: c=os.read(fd,65536)
        except OSError: break
        if not c: break
        o+=c
    return o.decode("utf8","replace")
def key(s,w=0.9): os.write(fd,s); time.sleep(w); return drain()
drain()
t("set","-g","@cwd","/tmp"); t("split-window","-h"); t("select-pane","-t","1")
origin=t("display-message","-t","1","-p","#{pane_id}").stdout.strip()
def log():
    s=open("/tmp/f3verify.log").read().strip(); open("/tmp/f3verify.log","w").close(); return s
fails=0
def check(name, ok, detail=""):
    global fails
    print(("  ok   " if ok else "  FAIL ")+name+("   "+detail if detail else ""))
    if not ok: fails+=1

print("R7 — F3 / Shift+F3 through tmux command-prompt (origin pane %s, @cwd /tmp)"%origin)
key(b"\x1bOR"); key(b"needle"); key(b"\r",1.8); g=log()
check("F3, a query, Enter opens the picker", "RAN" in g, g or "(never ran)")
check("  the typed query reaches tv-all",    "argv=[here needle]" in g)
check("  the origin pane id is real",        "origin=[%s]"%origin in g)
check("  the popup starts in the pane cwd",  "cwd=[/tmp]" in g)
time.sleep(1.0); drain()
key(b"\x1b[1;2R", 1.2); key(b"q"); key(b"\r",1.8); g=log()
check("Shift+F3 reaches the everywhere lane","argv=[everywhere q]" in g and "origin=[%s]"%origin in g, g or "(never ran)")
key(b"\x1bOR"); key(b"\x1b",1.4)
check("F3 then Escape runs nothing",         log()=="")
tail=[l for l in t("capture-pane","-p","-t","1").stdout.splitlines() if l.strip()]
check("  and leaves no message behind",      not any("tv-all" in l or "search" in l for l in tail[-2:]), repr(tail[-1:]))
t("kill-server"); os.close(fd)
print(("VERIFY OK" if not fails else "VERIFY FAILED (%d)"%fails)); sys.exit(1 if fails else 0)
