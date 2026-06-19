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
    # Two timing gotchas, both about typing before claude is ready:
    #
    # 1. Raw mode. Until claude switches the pty to raw mode the kernel line
    #    discipline is canonical — it buffers our text and converts CR->NL, so the
    #    first Enter is mangled and both seeds merge into one. We poll the SLAVE's
    #    termios and wait until ICANON is cleared before typing anything.
    #
    # 2. Busy claude. Raw mode is reached early — long before claude is actually
    #    idle at the prompt. claude runs a SessionStart turn (loads skills, runs
    #    hooks) and then processes the first seed (`/goal`), staying busy for tens
    #    of seconds. A fixed sleep between the two seeds (the old CL_BETWEEN) fires
    #    the second one straight into that busy window, where its Enter does NOT
    #    submit — so `/goal` lands but `/loop` is silently dropped. The fix is to
    #    gate every submit on output QUIESCENCE: claude streams spinner frames
    #    continuously while it works, so "no pty output for `quiet` seconds" is a
    #    reliable "idle at prompt, safe to type" signal. We wait for that before
    #    each seed instead of guessing a delay.
    gap = float(os.environ.get("CL_GAP", "0.3"))           # text -> Enter
    quiet = float(os.environ.get("CL_QUIET", "1.2"))       # silence => idle
    settle_to = float(os.environ.get("CL_SETTLE", "120"))  # max wait for idle
    react = float(os.environ.get("CL_REACT", "0.4"))       # let a submit register

    # last_rx[0] is bumped by the main loop on every chunk read from claude; the
    # injector reads it to tell whether output has gone silent. A lock keeps the
    # float read/write coherent across the two threads.
    last_rx = [time.time()]
    rx_lock = threading.Lock()

    def bump_rx():
        with rx_lock:
            last_rx[0] = time.time()

    def idle_for():
        with rx_lock:
            return time.time() - last_rx[0]

    def wait_until_raw(timeout=30.0):
        end = time.time() + timeout
        while time.time() < end:
            try:
                if not (termios.tcgetattr(slave)[3] & termios.ICANON):
                    return
            except Exception:
                return
            time.sleep(0.05)

    # Block until claude's output has been silent for `quiet` seconds (idle at the
    # prompt), or until `timeout` elapses — in which case we submit anyway as a
    # best effort rather than dropping the seed.
    def wait_idle(timeout):
        end = time.time() + timeout
        while time.time() < end:
            if idle_for() >= quiet:
                return True
            time.sleep(0.05)
        return False

    # Type the line, pause, then send Enter. No bracketed-paste markers: claude
    # treats input right after a paste-end as still-pasting and swallows the
    # following `\r`. Once the pty is raw AND claude is idle, a plain `\r` is a
    # clean Enter that submits on its own.
    def submit(line):
        os.write(fd, line.encode())
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
        wait_idle(settle_to)               # wait out boot / SessionStart
        # No waiting for claude to become responsive again between seeds: just
        # fire both lines back to back — first line + Enter, second line + Enter.
        submit("/goal is the loop. Cancel loop if archived")
        time.sleep(react)                  # let the first submit register
        os.write(fd, b"\x1b")              # ESC between submits
        time.sleep(react)                  # let the ESC register
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
                bump_rx()  # output seen => claude busy; resets the idle timer
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
