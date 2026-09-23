#!/usr/bin/env python3
"""No overlay ever flickers, even while everything behind it keeps updating.

A real tmux client is attached on a pty at 168x54 (terminal-features only
apply at attach) under this repo's tmux.conf, with this repo's cockpit and
modal. The pane behind prints a line every 50 ms and a pane option changes
every 250 ms (a Claude state report), which is what repainted overlays. The
bytes are split into what a terminal paints at once — each DEC 2026 block —
and replayed one at a time into a viewer tmux pane; after each, the overlay's
top border (both corners) and its bottom-left corner must be on screen.

  F1       the cockpit popup, then `g` (a group) and Backspace
  F8       the picker popup (~/.local/bin/modal)

It fails a popup whose first row pane redraws paint over (status-position top
on 3.7c), a popup that opens as an empty box, and a client without `sync`.
"""
import fcntl, os, pty, re, select, struct, subprocess, sys, termios, time

W, H = 168, 54
repo, sock, view = os.getcwd(), f"flk{os.getpid()}", f"view{os.getpid()}"


def tm(*a, s=sock):
    return subprocess.run(["tmux", "-L", s, *a], capture_output=True, text=True).stdout


pid, fd = pty.fork()
if pid == 0:
    fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", H, W, 0, 0))
    os.environ["TERM"] = "xterm-256color"
    os.chdir("/tmp")
    os.execvp("tmux", ["tmux", "-L", sock, "-f", f"{repo}/home/dot_config/tmux/tmux.conf", "new", "-s", "t",
                       "bash -c 'while :; do date +%N; sleep 0.05; done'"])


def pump(sec, tick=False):
    out, end, nxt = [], time.time() + sec, time.time()
    while time.time() < end:
        if tick and time.time() >= nxt:
            tm("set", "-p", "@claude", f"working{nxt}")
            nxt += 0.25
        if select.select([fd], [], [], 0.005)[0]:
            try:
                out.append(os.read(fd, 65536))
            except OSError:
                break
    return b"".join(out)


bin_ = f"XDG_CONFIG_HOME={repo}/home/dot_config bash {repo}/home/dot_local/bin/executable_"
screen = pump(2.0)
# Bound once the server is up: a bind before it fails silently and the
# installed conf binding runs instead.
tm("bind", "-n", "F1", "run-shell", "-b", bin_ + "cockpit '#{client_name}' '#{pane_id}' #{client_width} #{client_height}")
tm("bind", "-n", "F8", "run-shell", "-b", bin_ + "modal '#{client_name}' '#{pane_id}' /tmp '~/.local/bin/tv-go act'")
bad = 0
if ",sync," not in "," + tm("list-clients", "-F", "#{client_termfeatures}").strip() + ",":
    print("fresh client has no sync")
    bad = 1

fifo = f"/tmp/modal-frames.{os.getpid()}"
os.mkfifo(fifo)
tm("-f", "/dev/null", "new", "-d", "-x", str(W), "-y", str(H), f"stty raw -echo; cat {fifo}", s=view)
tm("set", "-g", "status", "off", s=view)
w = open(fifo, "wb", buffering=0)
w.write(screen)
time.sleep(0.3)


def watch(name, keys):
    """Replay each key's output frame by frame; T = overlay whole, - = not."""
    hist = ""
    for k in keys:
        box = None
        os.write(fd, k)
        for f in re.split(rb"(?<=\x1b\[\?2026l)", pump(1.5 if name == "F8" else 1.0, tick=True)):
            if not f:
                continue
            w.write(f)
            time.sleep(0.02)
            r = tm("capture-pane", "-p", s=view).split("\n")
            if box is None:
                tops = [(i, l.index("╭")) for i, l in enumerate(r) if "╭" in l and "╮" in l]
                if not tops:
                    continue
                y, x = tops[-1]
                box = (y, x, r[y].rindex("╮"), max(i for i, l in enumerate(r) if len(l) > x and l[x] == "╰"))
            y, x, rx, yb = box
            ok = r[y][x:x + 1] == "╭" and r[y][rx:rx + 1] == "╮" and r[yb][x:x + 1] == "╰"
            hist += "T" if ok else "-"
    print(f"{name}: frames={len(hist)} broken={hist.count('-')}")
    return not hist or "-" in hist


bad |= watch("F1", [b"\x1bOP", b"g", b"\x7f"])
os.write(fd, b"\x1b")
w.write(pump(1.5))
os.write(fd, b"q")
w.write(pump(0.5))
bad |= watch("F8", [b"\x1b[19~"])
tm("kill-server")
tm("kill-server", s=view)
subprocess.run(["tmux", "-L", "modal", "kill-server"], capture_output=True)
os.unlink(fifo)
sys.exit(bad)
