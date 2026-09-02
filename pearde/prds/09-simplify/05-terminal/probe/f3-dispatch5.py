#!/usr/bin/env python3
"""R7 probe, round 5: candidate spellings AS THEY WOULD BE WRITTEN IN
tmux.conf (sourced from a file, not passed as argv), for getting the origin
pane id into the popup when `display-popup -e` is never format-expanded."""
import os, pty, subprocess, time, shutil, select, sys
SOCK="probeF3e"; CONF="/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"; TMUX=shutil.which("tmux")
def t(*a): return subprocess.run([TMUX,"-L",SOCK,*a],capture_output=True,text=True)
t("kill-server"); time.sleep(0.3)
stub="/tmp/f3probe-bin"; os.makedirs(stub,exist_ok=True)
open(stub+"/tv-all","w").write('#!/bin/sh\nprintf "%s\\n" "RAN argv=[$*] origin=[${TV_ALL_ORIGIN:-UNSET}] cwd=[$PWD]" >> /tmp/f3probe5.log\n')
os.chmod(stub+"/tv-all",0o755); open("/tmp/f3probe5.log","w").close()

CANDS = {
 # A1 — command-prompt template as a tmux {} block, running run-shell
 "A1 braces + run-shell": r'''
bind -n F3 command-prompt -p 'search' {
    run-shell "tmux display-popup -E -B -w 90% -h 85% -x C -y C -d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %1'"
}''',
 # B1 — the popup's own shell asks tmux who the active pane is
 "B1 popup shell resolves origin": r'''
bind -n F3 command-prompt -p 'search' \
    "display-popup -E -B -w 90%% -h 85%% -x C -y C -d '#{E:@cwd}' 'TV_ALL_ORIGIN=$(tmux display -p \"#{pane_id}\") tv-all here %1'"''',
 "B2 same, ##{} escaped": r'''
bind -n F3 command-prompt -p 'search' \
    "display-popup -E -B -w 90%% -h 85%% -x C -y C -d '#{E:@cwd}' 'TV_ALL_ORIGIN=$(tmux display -p \"##{pane_id}\") tv-all here %1'"''',
 # C1 — set -F stamps the id into an option at press time, popup reads it back
 "C1 set -F then show -gv": r'''
bind -n F3 set -gF @f3origin "#{pane_id}" \; command-prompt -p 'search' \
    "display-popup -E -B -w 90%% -h 85%% -x C -y C -d '#{E:@cwd}' 'TV_ALL_ORIGIN=$(tmux show -gv @f3origin) tv-all here %1'"''',
}

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
def key(s,w=0.9): os.write(fd,s); time.sleep(w); drain()
drain()
t("set","-g","@cwd","/tmp"); t("split-window","-h"); t("select-pane","-t","1")
active=t("display-message","-t","1","-p","#{pane_id}").stdout.strip()
print("origin pane %s, @cwd /tmp\n"%active)
for name,frag in CANDS.items():
    open("/tmp/f3frag.conf","w").write(frag+"\n")
    err=t("source-file","/tmp/f3frag.conf").stderr.strip()
    if err: print("FAIL %-32s source-file: %s"%(name,err)); continue
    open("/tmp/f3probe5.log","w").close()
    key(b"\x1bOR"); key(b"needle"); key(b"\r",1.8); time.sleep(0.6)
    got=open("/tmp/f3probe5.log").read().strip() or "(never ran)"
    ok = ("origin=[%s]"%active) in got and "needle" in got and "cwd=[/tmp]" in got
    print(("PASS " if ok else "FAIL ")+"%-32s %s"%(name,got))
t("kill-server"); os.close(fd)
