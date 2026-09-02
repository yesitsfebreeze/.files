#!/usr/bin/env python3
"""R7 probe, round 4: (1) was HEAD's direct `display-popup -e ...#{pane_id}`
key binding expanded?  (2) does fix (a), written the way it would appear in
tmux.conf and SOURCED from a file, dispatch, cancel silently, and carry the
origin?"""
import os, pty, subprocess, time, shutil, select
SOCK="probeF3d"; CONF="/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"; TMUX=shutil.which("tmux")
def t(*a): return subprocess.run([TMUX,"-L",SOCK,*a],capture_output=True,text=True)
t("kill-server"); time.sleep(0.3)
stub="/tmp/f3probe-bin"; os.makedirs(stub,exist_ok=True)
open(stub+"/tv-all","w").write('#!/bin/sh\nprintf "%s\\n" "RAN argv=[$*] origin=[${TV_ALL_ORIGIN:-UNSET}] cwd=[$PWD]" >> /tmp/f3probe4.log\n')
os.chmod(stub+"/tv-all",0o755)
open("/tmp/f3probe4.log","w").close()

FRAG = r"""
set -g @cwd /tmp

# HEAD's shape: display-popup as the DIRECT argument of a key binding.
bind -n F1 display-popup -E -B -w 40 -h 5 -d '#{E:@cwd}' -e "TV_ALL_ORIGIN=#{pane_id}" "tv-all headshape"

# fix (a): the command-prompt template runs run-shell, and run-shell's argument
# IS format-expanded before the shell sees it (same trap R2's generator uses).
bind -n F3 command-prompt -p 'search' \
    "run-shell \"tmux display-popup -E -B -w 90%% -h 85%% -x C -y C -d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all here %1'\""
bind -n S-F3 command-prompt -p 'search everywhere' \
    "run-shell \"tmux display-popup -E -B -w 90%% -h 85%% -x C -y C -d '#{E:@cwd}' -e 'TV_ALL_ORIGIN=#{pane_id}' 'tv-all everywhere %1'\""
"""
open("/tmp/f3frag.conf","w").write(FRAG)

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
def key(s,w=0.9): os.write(fd,s); time.sleep(w); return drain()
drain()
print("source-file:", (t("source-file","/tmp/f3frag.conf").stderr.strip() or "ok"))
t("split-window","-h"); t("select-pane","-t","1")
active=t("display-message","-t","1","-p","#{pane_id}").stdout.strip()
print("origin pane is",active,"; @cwd is /tmp\n")
def log():
    s=open("/tmp/f3probe4.log").read().strip(); open("/tmp/f3probe4.log","w").close(); return s or "(never ran)"

print("1. HEAD shape, direct key binding (F1):"); key(b"\x1bOP",1.6); print("   ",log())
print("2. fix (a), F3 + 'needle' + Enter:"); key(b"\x1bOR"); key(b"needle"); key(b"\r",1.8); print("   ",log())
print("3. fix (a), F3 + Escape:"); key(b"\x1bOR"); scr=key(b"\x1b",1.4)
print("    tv-all ran:", log()!="(never ran)")
print("    anything on screen after cancel:", repr([l for l in t("capture-pane","-p","-t","1").stdout.splitlines() if l.strip()][-1:]))
print("4. fix (a), Shift+F3 + 'q' + Enter:"); key(b"\x1b[1;2R"); key(b"q"); key(b"\r",1.8); print("   ",log())
t("kill-server"); os.close(fd)
