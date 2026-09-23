#!/usr/bin/env python3
"""The theme behaviour invariants, as one isolated, deterministic probe.

Private tmux server on the repo's own tmux.conf, a temp XDG tree holding a
copy of tinty's state, a pty standing in for the terminal. Nothing touches
the user's real scheme, tmux or cache. Prints one `name=ok|FAIL detail` line
per invariant; exits non-zero if any fails.
"""
import os, pty, select, shutil, subprocess, sys, tempfile, time

HOME = os.path.expanduser("~")
REPO = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
THEME = f"{HOME}/.config/tinted-theming/tinty/theme.sh"
tmp = tempfile.mkdtemp()
sock = f"beh{os.getpid()}"
env = dict(os.environ, XDG_DATA_HOME=f"{tmp}/data", XDG_STATE_HOME=f"{tmp}/state",
           XDG_CONFIG_HOME=f"{tmp}/config", TMPDIR=f"{tmp}/", TERM="xterm-256color")
env.pop("TMUX", None)
# symlinks=False: current_scheme is an absolute symlink into the real tree,
# and copying the link would send every test write to the user's scheme.
shutil.copytree(f"{HOME}/.local/share/tinted-theming/tinty", f"{tmp}/data/tinted-theming/tinty", symlinks=False, ignore=shutil.ignore_patterns("repos", "gogh-src"))
os.symlink(f"{HOME}/.local/share/tinted-theming/tinty/repos", f"{tmp}/data/tinted-theming/tinty/repos")
shutil.copytree(f"{HOME}/.config/tinted-theming", f"{tmp}/config/tinted-theming", symlinks=True)
os.makedirs(f"{tmp}/config/tmux"); os.makedirs(f"{tmp}/state")
CUR = f"{tmp}/data/tinted-theming/tinty/current_scheme"
CONF = f"{tmp}/config/tmux/colors.conf"
results, failed = [], False

def report(name, ok, detail=""):
    global failed
    failed |= not ok
    results.append(f"{name}={'ok' if ok else 'FAIL'} {detail}".rstrip())

def tmux(*a):
    return subprocess.run(["tmux", "-L", sock, *a], env=env, capture_output=True, text=True).stdout.strip()

def scheme():
    return open(CUR).read().strip()

def status():
    return tmux("show", "-gv", "status-style")

def sh(*a):
    subprocess.run([THEME, *a], env=env, capture_output=True, timeout=15)

try:
    # new_terminal: a fresh server + first attach gets the palette on its wire.
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("tmux", ["tmux", "-L", sock, "-f", f"{REPO}/home/dot_config/tmux/tmux.conf",
                            "new-session", "-A", "-s", "main"], env)
    out, end = b"", time.time() + 10
    while time.time() < end and b"\x1b]4;0;" not in out:
        if select.select([fd], [], [], 0.2)[0]:
            try: out += os.read(fd, 65536)
            except OSError: break
    report("new_terminal", b"\x1b]4;0;" in out and b"\x1b]11;" in out)
    env["TMUX"] = tmux("display", "-p", "#{socket_path},0,0")

    # f6: two toggles return to the start, each painting within 300 ms.
    start, times = scheme(), []
    for _ in range(2):
        before = open(CONF).read() if os.path.exists(CONF) else ""
        t0 = time.time()
        subprocess.Popen([THEME, "--toggle"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while time.time() - t0 < 3 and (open(CONF).read() if os.path.exists(CONF) else "") == before:
            time.sleep(0.002)
        times.append(int((time.time() - t0) * 1000))
        time.sleep(1.5)
    report("f6_roundtrip", scheme() == start, f"start={start} end={scheme()}")
    report("f6_speed", max(times) <= 300, f"painted_ms={times}")

    # preview retints without recording; Esc (plain theme.sh) restores exactly.
    sh(); s0, c0 = status(), scheme()
    # Preview retints the terminal palette only (OSC 11 reaches the client),
    # never tmux's own styles: a restyle redraws every popup, which flickered.
    while select.select([fd], [], [], 0.2)[0]:
        try: os.read(fd, 65536)
        except OSError: break
    sh("--preview", "base16-nord"); s1 = status(); got = b""
    end = time.time() + 3
    while time.time() < end and b"]11;#2e3440" not in got.lower():
        if select.select([fd], [], [], 0.1)[0]:
            try: got += os.read(fd, 65536)
            except OSError: break
    osc = b"]11;#2e3440" in got.lower()
    report("preview_retint", osc and s1 == s0 and scheme() == c0, f"osc11_nord={osc} status_kept={s1 == s0}")
    sh(); s2 = status()
    report("esc_restores", s2 == s0, f"{s2} vs {s0}")

    # Enter: --apply records the pick as current.
    sh("--apply", "base16-caroline")
    report("enter_applies", scheme() == "base16-caroline", scheme())
finally:
    subprocess.run(["tmux", "-L", sock, "kill-server"], env=env, capture_output=True)
    shutil.rmtree(tmp, ignore_errors=True)

print("\n".join(results))
sys.exit(1 if failed else 0)
