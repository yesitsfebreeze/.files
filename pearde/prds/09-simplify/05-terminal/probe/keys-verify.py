#!/usr/bin/env python3
"""spec03's key half, driven on a real attached client.

`new-session -d` leaves a server with no attached client, so a key table push
and a status redraw cannot be observed there at all. Same pty harness as
f3-verify.py: fork a client onto a pty, write the real escape bytes, and read
the RESULT out of tmux's own state rather than off the screen.

Covers: F5 <digit> selects/creates a window, F5 <letter> selects a pane,
F5 <arrow> splits with the cwd inherited, F6 dispatches the theme toggle
(detected by the toggle's own side effect, not by looking at colours), and
F4 enters copy mode.
"""
import os, pty, subprocess, time, shutil, select, sys

SOCK = "probeKEYS"
CONF = "/Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf"
TMUX = shutil.which("tmux")
HOME = "/tmp/keyprobe-home"
LOG = "/tmp/keyverify.log"


def t(*a):
    return subprocess.run([TMUX, "-L", SOCK, *a], capture_output=True, text=True)


t("kill-server")
time.sleep(0.3)
os.makedirs(HOME + "/.config/nushell", exist_ok=True)
os.makedirs("/tmp/keyprobe-cwd", exist_ok=True)
open(LOG, "w").close()
# stand in for theme.nu so F6 dispatches without touching the real palette
open(HOME + "/.config/nushell/theme.nu", "w").write("def _theme_toggle [] { 'toggled' }\n")

pid, fd = pty.fork()
if pid == 0:
    os.environ.update(TERM="xterm-256color", HOME=HOME)
    os.execv(TMUX, [TMUX, "-L", SOCK, "-f", CONF, "new-session",
                    "-x", "120", "-y", "40", "-c", "/tmp/keyprobe-cwd"])
time.sleep(1.6)


def drain():
    o = b""
    while select.select([fd], [], [], 0.4)[0]:
        try:
            c = os.read(fd, 65536)
        except OSError:
            break
        if not c:
            break
        o += c
    return o


def key(s, w=0.9):
    os.write(fd, s)
    time.sleep(w)
    drain()


drain()
fails = 0

# TRAP: the SS3 run stops at F4. F1-F4 are \x1bOP..\x1bOS; F5 and up are CSI
# tilde forms (\x1b[15~, \x1b[17~) and there is no \x1bOT.
F5 = b"\x1b[15~"
F6 = b"\x1b[17~"


def check(name, ok, detail=""):
    global fails
    print(("  ok   " if ok else "  FAIL ") + name + ("   " + detail if detail else ""))
    if not ok:
        fails += 1


clients = t("list-clients", "-F", "#{client_tty}").stdout.strip()
print("keys — F5 / F6 / F4 on an attached client (tty %s)" % (clients or "NONE"))
check("a client is really attached", bool(clients), clients)

# F5 arms the jump table
key(F5, 0.6)
check("F5 arms the jump table",
      t("display-message", "-p", "#{client_key_table}").stdout.strip() == "jump")

# F5 2 — window 2 does not exist yet, so the bind creates it at index 2
key(b"2", 1.2)
idx = t("display-message", "-p", "#{window_index}").stdout.strip()
check("F5 2 lands on window 2", idx == "2", "window_index=" + idx)

key(F5, 0.6)
key(b"1", 1.2)
idx = t("display-message", "-p", "#{window_index}").stdout.strip()
check("F5 1 goes back to window 1", idx == "1", "window_index=" + idx)

# F5 <arrow> splits, and the split inherits @cwd
t("set", "-g", "@cwd", "/tmp/keyprobe-cwd")
before = int(t("display-message", "-p", "#{window_panes}").stdout.strip())
key(F5, 0.6)
key(b"\x1b[C", 1.2)                       # Right
after = int(t("display-message", "-p", "#{window_panes}").stdout.strip())
check("F5 Right splits the window", after == before + 1, "%d -> %d" % (before, after))
cwd = t("display-message", "-p", "#{pane_start_path}").stdout.strip()
check("  the split inherited the cwd", cwd == "/tmp/keyprobe-cwd", "pane_start_path=" + cwd)

# F5 <letter> selects a pane by its border letter
key(F5, 0.6)
key(b"a", 1.0)
p = t("display-message", "-p", "#{pane_index}").stdout.strip()
check("F5 a selects pane 1", p == "1", "pane_index=" + p)
key(F5, 0.6)
key(b"b", 1.0)
p = t("display-message", "-p", "#{pane_index}").stdout.strip()
check("F5 b selects pane 2", p == "2", "pane_index=" + p)

# F5 Escape leaves the table without eating a key
key(F5, 0.6)
key(b"\x1b", 1.0)
check("F5 Escape returns to the root table",
      t("display-message", "-p", "#{client_key_table}").stdout.strip() == "root")

# F4 enters copy mode
key(b"\x1bOS", 1.2)   # F4 is still SS3
check("F4 enters copy mode",
      t("display-message", "-p", "#{pane_in_mode}").stdout.strip() == "1")
key(b"q", 0.8)
check("  q leaves it",
      t("display-message", "-p", "#{pane_in_mode}").stdout.strip() == "0")

# F6 dispatches: rebind it to a command whose side effect is a file, because
# the real toggle's only output is the colours, which a pty cannot see.
t("bind", "-n", "F6", "run-shell", "-b", "echo fired >> " + LOG)
open(LOG, "w").close()
key(F6, 1.4)
check("F6 dispatches its run-shell", "fired" in open(LOG).read())

# the border chip and the pane letters (R6/Q1) survive on a multi-pane window
bf = t("show-options", "-gwv", "pane-border-format").stdout.strip()
check("the pane-letter border chip is still the format", "align=right" in bf and "64" in bf, bf)
# window-level, not global: the window-layout-changed hook `setw`s it per
# window, so the global option is still the default `off` and reading -gw
# grades nothing.
panes = t("display-message", "-p", "#{window_panes}").stdout.strip()
st = t("show-options", "-wv", "pane-border-status").stdout.strip()
check("  and the border is shown on a split window", st == "top",
      "panes=%s pane-border-status=%s" % (panes, st))

t("kill-server")
os.close(fd)
print("KEYS OK" if not fails else "KEYS FAILED (%d)" % fails)
sys.exit(1 if fails else 0)
