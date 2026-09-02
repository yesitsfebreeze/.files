#!/usr/bin/env python3
"""R7 probe, round 2: isolate the two things round 1 showed wrong —
`%1` arriving empty, and `#{pane_id}` arriving LITERAL."""
import os, pty, subprocess, sys, time, shutil, select

SOCK="probeF3b"; CONF="/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"; TMUX=shutil.which("tmux")
def t(*a): return subprocess.run([TMUX,"-L",SOCK,*a],capture_output=True,text=True)
t("kill-server"); time.sleep(0.3)
stub="/tmp/f3probe-bin"; os.makedirs(stub,exist_ok=True)
open(stub+"/tv-all","w").write('#!/bin/sh\nprintf "%s\\n" "RAN argv=[$*] origin=[$TV_ALL_ORIGIN] cwd=[$PWD]" >> /tmp/f3probe2.log\n')
os.chmod(stub+"/tv-all",0o755)
try: os.remove("/tmp/f3probe2.log")
except FileNotFoundError: pass

pid,fd=pty.fork()
if pid==0:
    os.environ["TERM"]="xterm-256color"; os.environ["PATH"]=stub+":"+os.environ["PATH"]
    os.execv(TMUX,[TMUX,"-L",SOCK,"-f",CONF,"new-session","-x","120","-y","40"])
time.sleep(1.5)
def drain():
    o=b""
    while select.select([fd],[],[],0.4)[0]:
        try: c=os.read(fd,65536)
        except OSError: break
        if not c: break
        o+=c
    return o.decode("utf8","replace")
def key(s,w=0.8): os.write(fd,s); time.sleep(w); return drain()
def pane(): return t("capture-pane","-p","-t","0").stdout
drain()

print("### A. display-popup DIRECT (no command-prompt) — does it expand #{pane_id} in -e?")
t("run-shell","-b","tmux display-popup -E -B -w 40 -h 5 -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all DIRECT'")
time.sleep(1.5)
print("   ", (open("/tmp/f3probe2.log").read().strip() if os.path.exists("/tmp/f3probe2.log") else "(nothing)"))
open("/tmp/f3probe2.log","w").close()

print("### B. the real F3 binding, watching the prompt line as we type")
t("bind-key","-n","F3","command-prompt","-p","search",
  "display-popup -E -B -w 90% -h 85% -x C -y C -d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %1'")
key(b"\x1bOR")
scr=t("capture-pane","-p","-t","0","-S","-").stdout
print("    status/prompt row after F3:", repr(t("display-message","-t","0","-p","#{client_prompt}").stdout.strip()))
key(b"needle")
print("    prompt after typing:", repr(t("display-message","-t","0","-p","#{client_prompt}").stdout.strip()))
key(b"\r",1.5); time.sleep(1.0)
print("    ", (open("/tmp/f3probe2.log").read().strip() if os.path.getsize("/tmp/f3probe2.log") else "(tv-all never ran)"))
open("/tmp/f3probe2.log","w").close()

print("### C. Escape at the prompt — silent cancel?")
key(b"\x1bOR"); time.sleep(0.3)
before=t("display-message","-t","0","-p","#{client_prompt}").stdout.strip()
key(b"\x1b",1.0)
after=t("display-message","-t","0","-p","#{client_prompt}").stdout.strip()
print("    prompt before Escape:",repr(before)," after:",repr(after))
print("    tv-all ran on cancel:", os.path.getsize("/tmp/f3probe2.log")>0)
print("    visible message line:", repr([l for l in pane().splitlines() if l.strip()][-1:]))

print("### D. does #{E:@cwd} / #{pane_id} survive if the popup is the DIRECT arg of the binding?")
t("set","-g","@cwd","/tmp")
t("bind-key","-n","F4","display-popup","-E","-B","-w","40","-h","5","-d","#{E:@cwd}","-e","TV_ALL_ORIGIN=#{pane_id}","tv-all DIRECTBIND")
key(b"\x1bOS",1.5); time.sleep(0.8)
print("    ", (open("/tmp/f3probe2.log").read().strip() if os.path.getsize("/tmp/f3probe2.log") else "(never ran)"))

t("kill-server"); os.close(fd)
