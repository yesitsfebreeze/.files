#!/usr/bin/env python3
"""Behavioral tests using real PTYs, Neovim and Git; no extra packages."""
import fcntl
import json
import os
from pathlib import Path
import pty
import runpy
import select
import shutil
import subprocess
import sys
import tempfile
import termios
import time
import tty
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
BIN = ROOT / "home/.local/bin"
NU = ROOT / "home/.config/nushell/cockpit.nu"
NVIM = ROOT / "home/.config/nvim/lua"


def run(args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=10, **kwargs).stdout.strip()


class Terminal:
    def __init__(self, args, env=None):
        self.master, self.slave = pty.openpty()
        tty.setraw(self.slave)
        termios.tcsetwinsize(self.slave, (30, 120))
        self.process = subprocess.Popen(args, stdin=self.slave, stdout=self.slave, stderr=self.slave, env=env, preexec_fn=lambda: os.login_tty(0))
        self.output = b""
        self.query_tail = b""

    def pump(self, duration=0.03):
        end = time.monotonic() + duration
        while time.monotonic() < end:
            if select.select([self.master], [], [], min(0.01, max(0, end - time.monotonic())))[0]:
                try:
                    data = os.read(self.master, 65536)
                except OSError:
                    return
                if not data:
                    return
                self.output += data
                queries = self.query_tail + data
                self.query_tail = queries[-3:]
                for _ in range(queries.count(b"\x1b[6n")):
                    self.send(b"\x1b[1;1R")

    def send(self, data):
        os.write(self.master, data.encode() if isinstance(data, str) else data)

    def wait_for(self, text, timeout=4):
        until = time.monotonic() + timeout
        while text not in self.output and time.monotonic() < until:
            self.pump()
        if text not in self.output:
            raise AssertionError(f"Terminal did not emit {text!r}: {self.output[-2000:]!r}")

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
        os.close(self.master)
        os.close(self.slave)
        try:
            self.process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=2)


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-latency-test-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.env = dict(os.environ, HOME=str(self.home), TMUX_PANE="%test", TERM="xterm-256color")
        for key in ("TMUX", "NVIM", "NVIM_LISTEN_ADDRESS"):
            self.env.pop(key, None)
        for kind in ("CONFIG", "CACHE", "DATA", "STATE"):
            self.env[f"XDG_{kind}_HOME"] = str(self.home / kind.lower())
        self.log = self.home / "opened"
        self.spy = self.home / ".local/bin/cockpit"
        self.spy.parent.mkdir(parents=True)
        self.spy.write_text(f"#!/bin/sh\nprintf 'open\\n' >> '{self.log}'\nexit 0\n")
        self.spy.chmod(0o755)

    def opens(self):
        return len(self.log.read_text().splitlines()) if self.log.exists() else 0

    def assert_opened(self):
        deadline = time.monotonic() + 2
        while self.opens() == 0 and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertEqual(self.opens(), 1)


class ReaderTests(Fixture):
    def reader(self, chunks, expected, leftover=None):
        frames = self.home / "frames"
        frames.mkdir()
        (frames / ".f").write_text("READY")
        (frames / "s.f").write_text("SUBMENU")
        (frames / "sf.a").write_text("action")
        out = self.home / "choice"
        remainder = self.home / "remainder"
        runner = "import os,select,subprocess,sys; subprocess.run(sys.argv[1:5], check=True); "
        if leftover is not None:
            runner += "open(sys.argv[5], 'wb').write(os.read(0, 32) if select.select([0], [], [], .1)[0] else b'')"
        terminal = Terminal([sys.executable, "-c", runner, "/bin/zsh", str(BIN / "cockpit-keys"), str(frames), str(out), str(remainder)])
        self.addCleanup(terminal.close)
        terminal.wait_for(b"READY")
        start = time.monotonic()
        for delay, text in chunks:
            time.sleep(delay)
            terminal.send(text)
        deadline = time.monotonic() + 2
        while terminal.process.poll() is None and time.monotonic() < deadline:
            terminal.pump(0.002)
        self.assertEqual(terminal.process.poll(), 0, repr(terminal.output[-2000:]))
        elapsed = (time.monotonic() - start) * 1000
        self.assertEqual(out.read_text() if out.exists() else "", expected)
        if leftover is not None:
            self.assertEqual(remainder.read_bytes(), leftover)
        return elapsed

    def test_escape(self):
        elapsed = self.reader([(0, b"\x1b")], "")
        print(f"Escape response: {elapsed:.1f} ms", flush=True)
        self.assertLess(elapsed, 100)

    def test_arrow_does_not_eat_next_key(self):
        self.reader([(0, b"\x1b[Ax")], "U", b"x")

    def test_fragmented_arrow(self):
        self.reader([(0, b"\x1b"), (0.005, b"["), (0.005, b"D")], "L")

    def test_modified_arrow(self):
        self.reader([(0, b"\x1b[1;2C")], "fh")

    def test_menu_backspace(self):
        self.reader([(0, b"s\x7fsf")], "sf")


class GitTests(Fixture):
    def test_parser(self):
        segment = runpy.run_path(str(BIN / "prompt-git"))["segment"]
        self.assertEqual(segment(b"# branch.head main\n"), "  main ")
        self.assertEqual(segment(b"# branch.head main\n1 M. file\n1 .M file\n? new\n"), "  main $!? ")
        self.assertEqual(segment(b"# branch.head (detached)\n"), "")
        self.assertEqual(segment(b"# branch.head main\nu UU conflict\n"), "  main $! ")

    def test_concurrent_refresh_and_lock_recovery(self):
        fakebin = self.home / "bin"
        fakebin.mkdir()
        calls = self.home / "git-calls"
        fakegit = fakebin / "git"
        fakegit.write_text(f"#!{sys.executable}\nimport time,os\nwith open({str(calls)!r},'a') as f: f.write('probe\\n')\ntime.sleep(.2)\nprint('# branch.head main')\n")
        fakegit.chmod(0o755)
        env = dict(self.env, PATH=str(fakebin) + os.pathsep + os.environ["PATH"])
        cache = self.home / "cache"
        command = [sys.executable, str(BIN / "prompt-git"), str(self.home), str(cache)]
        workers = [subprocess.Popen(command, env=env) for _ in range(12)]
        for worker in workers:
            self.assertEqual(worker.wait(timeout=4), 0)
        self.assertEqual(calls.read_text().splitlines(), ["probe"])
        self.assertEqual(cache.read_text(), "  main ")
        os.utime(cache, (0, 0))
        with open(str(cache) + ".lock", "a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            run(command, env=env)
            self.assertEqual(calls.read_text().splitlines(), ["probe"])
        run(command, env=env)
        self.assertEqual(calls.read_text().splitlines(), ["probe", "probe"])

    def test_failed_refresh_preserves_cache(self):
        refresh = runpy.run_path(str(BIN / "prompt-git"))["refresh"]
        cache = self.home / "cache"
        cache.write_text("  main ! ")
        os.utime(cache, (0, 0))
        with patch("subprocess.run", side_effect=subprocess.TimeoutExpired("git", 10)):
            with self.assertRaises(subprocess.TimeoutExpired):
                refresh(str(self.home), cache)
        self.assertEqual(cache.read_text(), "  main ! ")
        with patch("subprocess.run", return_value=subprocess.CompletedProcess([], 0, b"# branch.head main\n")):
            self.assertTrue(refresh(str(self.home), cache))

    def test_real_repository(self):
        repo = self.home / "repo"
        run(["git", "init", "-qb", "main", str(repo)])
        (repo / "file").write_text("first\n")
        run(["git", "-C", str(repo), "add", "."])
        run(["git", "-C", str(repo), "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "init"])
        (repo / "file").write_text("second\n")
        (repo / "new").write_text("untracked\n")
        cache = self.home / "cache"
        self.assertTrue(runpy.run_path(str(BIN / "prompt-git"))["refresh"](str(repo), cache))
        self.assertEqual(cache.read_text(), "  main !? ")


class NushellTests(Fixture):
    def shell(self, supported=True):
        snapshot = self.home / "snapshot.json"
        config = self.home / "test.nu"
        config.write_text(f'''$env.config.show_banner = false
$env.config.edit_mode = "emacs"
$env.PROMPT_COMMAND = {{|| "READY> "}}
$env.PROMPT_COMMAND_RIGHT = {{|| ""}}
$env.PROMPT_INDICATOR = ""
source '{NU}'
$env.config.keybindings = ($env.config.keybindings | append {{name: snapshot, modifier: none, keycode: f12, mode: emacs, event: {{send: executehostcommand, cmd: "{{text: (commandline), cursor: (commandline get-cursor)}} | to json | save -f '{snapshot}'"}}}})
''')
        env = dict(self.env)
        args = ["nu", "-n", "--no-history", "-e", f"source '{config}'"]
        if supported:
            self.tmux = ["tmux", "-L", "cockpit-test-" + self.home.name]
            self.addCleanup(lambda: subprocess.run(self.tmux + ["kill-server"], capture_output=True, timeout=3))
            run(self.tmux + ["-f", "/dev/null", "new-session", "-d", "-s", "test", "-x", "120", "-y", "30"] + args, env=env)
            run(self.tmux + ["set", "-g", "status", "off"], env=env)
            run(self.tmux + ["set", "-s", "escape-time", "10"], env=env)
            run(self.tmux + ["source-file", str(ROOT / "home/.config/tmux/cockpit-space.conf")], env=env)
            args = self.tmux + ["attach-session", "-t", "test"]
        else:
            env.pop("TMUX_PANE", None)
        self.term = Terminal(args, env)
        self.addCleanup(self.term.close)
        self.term.wait_for(b"READY>")
        self.snapshot = snapshot

    def text(self):
        self.term.pump(0.05)
        self.snapshot.unlink(missing_ok=True)
        end = time.monotonic() + 3
        while not self.snapshot.exists() and time.monotonic() < end:
            self.term.send(b"\x1b[24~")
            self.term.pump(0.05)
        self.assertTrue(self.snapshot.exists(), repr(self.term.output[-2000:]))
        return json.loads(self.snapshot.read_text())["text"]

    def seed(self, value):
        self.term.send(b"\x1b[200~" + value.encode() + b"\x1b[201~")
        self.term.pump(0.06)

    def spaces(self, gap):
        self.term.send(" ")
        self.term.pump(gap)
        self.term.send(" ")
        self.term.pump(0.05)

    def test_single_space_immediate(self):
        self.shell()
        self.seed("abc")
        self.term.send(" ")
        self.assertEqual(self.text(), "abc ")
        self.assertEqual(self.opens(), 0)

    def test_fast_spaces_restore_input(self):
        self.shell()
        self.seed("abc")
        self.spaces(0.10)
        self.assertEqual(self.text(), "abc")
        self.assert_opened()

    def test_slow_spaces_are_literal(self):
        self.shell()
        self.seed("abc")
        self.spaces(0.30)
        self.assertEqual(self.text(), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_paste_is_literal(self):
        self.shell()
        self.seed("abc  def")
        self.assertEqual(self.text(), "abc  def")
        self.assertEqual(self.opens(), 0)

    def test_unicode_and_midline(self):
        self.shell()
        self.seed("ä猫xyz")
        self.term.send(b"\x1b[D\x1b[D\x1b[D")
        self.term.pump(0.05)
        self.spaces(0.10)
        self.assertEqual(self.text(), "ä猫xyz")
        self.assert_opened()

    def test_intervening_typing(self):
        self.shell()
        self.seed("abc")
        self.term.send(" x")
        self.term.pump(0.10)
        self.term.send(" ")
        self.assertEqual(self.text(), "abc x ")
        self.assertEqual(self.opens(), 0)

    def test_cursor_round_trip_cancels(self):
        self.shell()
        self.seed("abc")
        self.term.send(" ")
        self.term.pump(0.07)
        self.term.send(b"\x1b[D\x1b[C ")
        self.assertEqual(self.text(), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_real_popup_closes_without_changing_input(self):
        shutil.copy2(BIN / "cockpit", self.spy)
        shutil.copy2(BIN / "cockpit-keys", self.spy.with_name("cockpit-keys"))
        config_dir = Path(self.env["XDG_CONFIG_HOME"]) / "tmux"
        config_dir.mkdir(parents=True)
        shutil.copy2(ROOT / "home/.config/tmux/cockpit.json", config_dir / "cockpit.json")
        self.shell()
        self.seed("abc")
        self.spaces(0.10)
        self.term.wait_for(b"esc close")
        self.term.send(b"\x1b")
        deadline = time.monotonic() + 2
        while run(self.tmux + ["show-option", "-gqv", "@cockpit"], env=self.env) == "1" and time.monotonic() < deadline:
            self.term.pump(0.01)
        self.assertEqual(run(self.tmux + ["show-option", "-gqv", "@cockpit"], env=self.env), "")
        self.assertEqual(self.text(), "abc")

    def test_batched_typing_preserves_all_characters(self):
        self.shell()
        self.term.send("echo abc def ghi")
        self.assertEqual(self.text(), "echo abc def ghi")
        self.assertEqual(self.opens(), 0)

    def test_paste_after_first_space_cancels(self):
        self.shell()
        self.seed("abc")
        self.term.send(" ")
        self.term.pump(0.07)
        self.seed("x ")
        self.term.send(" ")
        self.assertEqual(self.text(), "abc x  ")
        self.assertEqual(self.opens(), 0)

    def test_home_end_round_trip_cancels(self):
        self.shell()
        self.seed("abc")
        self.term.send(" ")
        self.term.pump(0.07)
        self.term.send(b"\x1b[H\x1b[F ")
        self.assertEqual(self.text(), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_repeat_train_is_literal(self):
        self.shell()
        self.seed("abc")
        self.term.send(" ")
        for delay in (0.3, 0.03, 0.03, 0.03):
            self.term.pump(delay)
            self.term.send(" ")
        self.assertEqual(self.text(), "abc     ")
        self.assertEqual(self.opens(), 0)

    def test_unsupported_and_failed_open_preserve_spaces(self):
        self.shell(supported=False)
        self.seed("abc")
        self.spaces(0.10)
        self.assertEqual(self.text(), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_failed_open_preserves_spaces(self):
        self.spy.write_text("#!/bin/sh\nexit 1\n")
        self.shell()
        self.seed("abc")
        self.spaces(0.10)
        self.assertEqual(self.text(), "abc  ")


class NeovimTests(Fixture):
    def editor(self):
        self.socket = str(self.home / "nvim.sock")
        init = self.home / "init.lua"
        init.write_text(f'''package.path = {json.dumps(str(NVIM / "?.lua"))} .. ";" .. package.path
vim.g.mapleader = " "
vim.opt.swapfile = false
vim.opt.softtabstop = 4
vim.opt.expandtab = true
require("config.cockpit")
''')
        self.nvim = subprocess.Popen(["nvim", "--headless", "-u", str(init), "-i", "NONE", "--listen", self.socket], env=self.env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        self.addCleanup(self.close_editor)
        end = time.monotonic() + 3
        while not Path(self.socket).exists() and time.monotonic() < end:
            time.sleep(0.01)
        self.assertTrue(Path(self.socket).exists())

    def close_editor(self):
        if self.nvim.poll() is None:
            self.nvim.terminate()
            try:
                self.nvim.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.nvim.kill()
                self.nvim.wait()
        self.nvim.stderr.close()

    def expr(self, expression):
        return run(["nvim", "--headless", "-u", "NONE", "-i", "NONE", "--server", self.socket, "--remote-expr", expression], env=self.env)

    def send(self, keys):
        run(["nvim", "--headless", "-u", "NONE", "-i", "NONE", "--server", self.socket, "--remote-send", keys], env=self.env)
        time.sleep(0.01)

    def test_insert_fast(self):
        self.editor()
        self.send("iabc ")
        time.sleep(0.09)
        self.send(" ")
        self.assertEqual(json.loads(self.expr("json_encode(getline('.'))")), "abc")
        self.assert_opened()

    def test_insert_slow(self):
        self.editor()
        self.send("iabc ")
        time.sleep(0.30)
        self.send(" ")
        self.assertEqual(json.loads(self.expr("json_encode(getline('.'))")), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_failed_open_preserves_input(self):
        self.spy.write_text("#!/bin/sh\nexit 1\n")
        self.editor()
        self.send("iabc ")
        time.sleep(0.09)
        self.send(" ")
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            if json.loads(self.expr("json_encode(getline('.'))")) == "abc  ":
                break
            time.sleep(0.01)
        self.assertEqual(json.loads(self.expr("json_encode(getline('.'))")), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_preserves_indentation(self):
        self.editor()
        self.send("i    ")
        time.sleep(0.6)
        self.send(" ")
        time.sleep(0.09)
        self.send(" ")
        self.assertEqual(json.loads(self.expr("json_encode(getline('.'))")), "    ")
        self.assert_opened()

    def test_commandline_fast(self):
        self.editor()
        self.send(":echo ")
        time.sleep(0.09)
        self.send(" ")
        self.assertEqual(json.loads(self.expr("json_encode(getcmdline())")), "echo")
        self.assert_opened()

    def test_cursor_round_trip(self):
        self.editor()
        self.send("iabc ")
        time.sleep(0.07)
        self.send("<Left><Right> ")
        self.assertEqual(json.loads(self.expr("json_encode(getline('.'))")), "abc  ")
        self.assertEqual(self.opens(), 0)

    def test_normal_mode_leader(self):
        self.editor()
        self.send("  ")
        self.assert_opened()
        self.assertEqual(self.expr("getline('.')"), "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
