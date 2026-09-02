#!/usr/bin/env python3
"""R7 probe, round 3: three candidate fixes for `#{pane_id}` arriving LITERAL
through a command-prompt template.  A command-prompt callback runs with no
pane target, so display-popup's -e/-d are never format-expanded there."""
import os, pty, subprocess, time, shutil, select
SOCK="probeF3c"; CONF="/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"; TMUX=shutil.which("tmux")
def t(*a): return subprocess.run([TMUX,"-L",SOCK,*a],capture_output=True,text=True)
t("kill-server"); time.sleep(0.3)
stub="/tmp/f3probe-bin"; os.makedirs(stub,exist_ok=True)
open(stub+"/tv-all","w").write('#!/bin/sh\nprintf "%s\\n" "RAN argv=[$*] origin=[${TV_ALL_ORIGIN:-UNSET}] cwd=[$PWD]" >> /tmp/f3probe3.log\n')
os.chmod(stub+"/tv-all",0o755)
open("/tmp/f3probe3.log","w").close()
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
    return o
def key(s,w=0.8): os.write(fd,s); time.sleep(w); drain()
drain()
t("split-window","-h")            # 2 panes so the origin id is not just %0
t("select-pane","-t","1")
t("set","-g","@cwd","/tmp")
active=t("display-message","-t","1","-p","#{pane_id}").stdout.strip()
print("origin pane should be:",active,"  @cwd should be: /tmp\n")

def trial(name, bind_argv):
    open("/tmp/f3probe3.log","w").close()
    t("bind-key","-n","F3",*bind_argv)
    key(b"\x1bOR"); key(b"needle"); key(b"\r",1.6); time.sleep(0.8)
    got=open("/tmp/f3probe3.log").read().strip() or "(never ran)"
    ok = active in got and "/tmp" in got and "needle" in got
    print(("PASS " if ok else "FAIL ")+name+"\n      "+got)

POP="display-popup -E -B -w 90% -h 85% -x C -y C -d '{CWD}' -e 'TV_ALL_ORIGIN={PID}' 'tv-all here %1'"

trial("current build (formats inside the template)",
      ["command-prompt","-p","search", POP.replace("{CWD}","#{E:@cwd}").replace("{PID}","#{pane_id}")])

trial("(a) template runs run-shell, which format-expands",
      ["command-prompt","-p","search",
       "run-shell \"tmux display-popup -E -B -w 90% -h 85% -x C -y C "
       "-d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %1'\""])

trial("(b) popup shell resolves the origin itself",
      ["command-prompt","-p","search",
       "display-popup -E -B -w 90% -h 85% -x C -y C "
       "'cd \"$(tmux display -p \"##{E:@cwd}\")\" && TV_ALL_ORIGIN=$(tmux display -p \"##{pane_id}\") tv-all here %1'"])

trial("(f) run-shell wraps command-prompt, so the id is baked in at press time",
      ["run-shell",
       "tmux command-prompt -p search \\\"display-popup -E -B -w 90% -h 85% -x C -y C "
       "-d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %%1'\\\""])

t("kill-server"); os.close(fd)
