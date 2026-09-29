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
On a tmux that draws popups as floating panes the box is square; the pane
border behind (column 0, rounded when `pane-border-type` exists) is never
the box, or an unopened popup passes.
"""
import fcntl, os, pty, re, select, shutil, struct, subprocess, sys, tempfile, termios, time

W, H = 168, 54
repo, sock, view = os.getcwd(), f"flk{os.getpid()}", f"view{os.getpid()}"
ME, tmp = os.getpid(), tempfile.mkdtemp()
# Every tmux server of this run, the nested -L modal one included, lives here: never the user's.
os.environ["TMUX_TMPDIR"] = tmp


def tm(*a, s=sock):
    return subprocess.run(["tmux", "-L", s, *a], capture_output=True, text=True).stdout


pid, fd = pty.fork()
if pid == 0:
    fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", H, W, 0, 0))
    os.environ["TERM"] = "xterm-256color"
    os.chdir("/tmp")
    os.execvp("tmux", ["tmux", "-L", sock, "-f", f"{repo}/home/dot_config/tmux/tmux.conf", "new", "-s", "t",
                       # The loop is also the watchdog: orly SIGKILLs a check past its budget, and a
                       # tmux server has left that process group, so the pane ends both servers itself.
                       f"bash -c 'while kill -0 {ME}; do date +%N; sleep 0.05; done; tmux -L modal kill-server; tmux -L {sock} kill-server'"])


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


bin_ = f"XDG_CONFIG_HOME={repo}/home/dot_config XDG_CACHE_HOME=/tmp/modal-frames-cache.{os.getpid()} bash {repo}/home/dot_local/bin/executable_"
# Wait for the client, not a fixed 2 s: under load it attaches later, and a
# check before then sees no client, no sync and no frames.
screen, end = b"", time.time() + 15
while time.time() < end and not tm("list-clients"):
    screen += pump(0.25)
screen += pump(1.0)
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


def first(l, chars):
    """Column of the first of CHARS in L, -1 when none."""
    return min((l.index(c) for c in chars if c in l), default=-1)

def watch(name, keys):
    """Replay each key's output frame by frame; T = overlay whole, - = not."""
    hist = ""
    for k in keys:
        box = None
        os.write(fd, k)
        # The picker forks tv and fzf; when the gate runs thirty checks at once
        # its first frame can take over 1.5 s, and no frame at all reads as broken.
        for f in re.split(rb"(?<=\x1b\[\?2026l)", pump(3.0 if name == "F8" else 1.0, tick=True)):
            if not f:
                continue
            w.write(f)
            time.sleep(0.02)
            r = tm("capture-pane", "-p", s=view).split("\n")
            if box is None:
                # The overlay's box, rounded or (a floating-pane popup) square; never the
                # pane border, which starts in column 0. A box found once is held for the key.
                tops = [(i, first(l, "╭┌")) for i, l in enumerate(r) if first(l, "╭┌") > 0 and any(c in l for c in "╮┐")]
                if not tops:
                    continue
                y, x = tops[-1]
                box = (y, x, max(r[y].rindex(c) for c in "╮┐" if c in r[y]),
                       max(i for i, l in enumerate(r) if len(l) > x and l[x] in "╰└"))
            y, x, rx, yb = box
            ok = r[y][x:x + 1] in ("╭", "┌") and r[y][rx:rx + 1] in ("╮", "┐") and r[yb][x:x + 1] in ("╰", "└")
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
shutil.rmtree(tmp, ignore_errors=True)
sys.exit(bad)
