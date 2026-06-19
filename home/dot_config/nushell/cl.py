#!/usr/bin/env python3
# cl.py — launch claude and auto-submit the goal + loop messages, then hand the
# terminal back to you.
#
# claude runs in-place under a pty (no tmux/zellij, no detached session, no
# attach), so its TUI renders correctly everywhere, including inside burrito.
# A background thread types the two seed messages and then control is yours.
import os, sys, pty, time, select, termios, tty, fcntl, signal, threading


def set_winsize(fd):
    """Mirror our terminal size onto the child pty so the TUI lays out right."""
    try:
        s = fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, s)
    except Exception:
        pass


def main():
    task = " ".join(sys.argv[1:]).strip()
    # CL_CMD lets tests swap in a stand-in child; default is claude.
    cmd = os.environ.get("CL_CMD", "claude --dangerously-skip-permissions").split()

    # openpty (not pty.fork) so the parent keeps the SLAVE fd: only the slave's
    # termios reflects whether claude has switched to raw mode (the master's does
    # not). We need that signal to time injection correctly.
    master, slave = pty.openpty()
    set_winsize(slave)

    pid = os.fork()
    if pid == 0:  # child: become claude on the pty slave
        os.setsid()
        os.close(master)
        for i in (0, 1, 2):
            os.dup2(slave, i)
        try:
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)
        except Exception:
            pass
        if slave > 2:
            os.close(slave)
        os.execvp(cmd[0], cmd)
        os._exit(127)

    fd = master
    signal.signal(signal.SIGWINCH, lambda *a: set_winsize(fd))

    # Background injector.
    #
    # The real gotcha: until claude switches the pty to raw mode, the kernel line
    # discipline is canonical — it buffers our text and converts CR->NL, so the
    # first Enter is mangled and both lines merge into one. A fixed sleep races
    # claude's boot. Instead we poll the SLAVE's termios and wait until ICANON is
    # cleared (claude's input is live), THEN type. After that, `\r` is a discrete
    # Enter, so each line submits on its own.
    gap = float(os.environ.get("CL_GAP", "0.3"))          # text -> Enter
    between = float(os.environ.get("CL_BETWEEN", "1.5"))  # command -> command

    def wait_until_raw(timeout=30.0):
        end = time.time() + timeout
        while time.time() < end:
            try:
                if not (termios.tcgetattr(slave)[3] & termios.ICANON):
                    return
            except Exception:
                return
            time.sleep(0.05)

    # claude enables bracketed paste (DECSET 2004) and uses input timing to guess
    # paste-vs-typing — a bare `\r` sent right after bulk text gets absorbed and
    # never submits. Wrapping the text in explicit paste markers tells claude where
    # the paste ENDS, so the following `\r` is an unambiguous Enter that submits.
    PASTE = (b"\x1b[200~", b"\x1b[201~")

    def submit(line):
        os.write(fd, PASTE[0] + line.encode() + PASTE[1])
        time.sleep(gap)
        os.write(fd, b"\r")

    def inject():
        wait_until_raw()
        # Drop the parent's slave handle now that input is live, so the master
        # read() below gets EOF when claude exits (else it would hang forever).
        try:
            os.close(slave)
        except Exception:
            pass
        time.sleep(0.3)  # small settle once input is live
        submit("/goal is the loop. Cancel loop if archived")
        time.sleep(between)  # let claude process /goal before the next command
        submit("/loop " + task)

    threading.Thread(target=inject, daemon=True).start()

    # Put our terminal in raw mode so keystrokes pass straight through to claude.
    try:
        old = termios.tcgetattr(sys.stdin)
        tty.setraw(sys.stdin.fileno())
    except Exception:
        old = None

    fds = [sys.stdin.fileno(), fd]
    try:
        while True:
            try:
                r, _, _ = select.select(fds, [], [])
            except (OSError, select.error):
                continue
            if fd in r:
                try:
                    data = os.read(fd, 65536)
                except OSError:
                    data = b""
                if not data:
                    break  # claude exited
                os.write(sys.stdout.fileno(), data)
            if sys.stdin.fileno() in r:
                data = os.read(sys.stdin.fileno(), 65536)
                if not data:
                    fds.remove(sys.stdin.fileno())  # our stdin closed; keep going
                else:
                    os.write(fd, data)
    finally:
        if old is not None:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old)
        try:
            os.waitpid(pid, 0)
        except Exception:
            pass


if __name__ == "__main__":
    main()
