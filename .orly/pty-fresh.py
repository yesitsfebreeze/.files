# A fresh tmux server on socket argv[1], attached through a real pty with the
# live tmux.conf; reports whether the palette (OSC 4) and background (OSC 11)
# reached the terminal.
import os, pty, time, select, sys
sock = sys.argv[1]; mode = sys.argv[2]
pid, fd = pty.fork()
if pid == 0:
    os.environ.pop("TMUX", None)
    os.environ["TERM"]="xterm-256color"
    os.execvp("tmux", ["tmux","-L",sock,"-f",os.path.expanduser("~/.config/tmux/tmux.conf"),"new-session","-A","-s","main"])
out=b""; end=time.time()+15
while time.time()<end:
    r,_,_=select.select([fd],[],[],0.2)
    if r:
        try: out+=os.read(fd,65536)
        except OSError: break
print(mode, "OSC4 seen:", b"\x1b]4;0;" in out, "OSC11:", b"\x1b]11;" in out, "bytes", len(out))
