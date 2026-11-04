"""Exercise idle Escape against real Yazi/Neovim in an isolated tmux server."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib

repo = Path(__file__).resolve().parents[1]
config = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else repo / "home/.config/yazi"
keymap = tomllib.loads((config / "keymap.toml").read_text())
binding = next(row for row in keymap["mgr"]["prepend_keymap"] if row["on"] == "<Esc>")
assert binding["run"] == "plugin escape-or-quit", binding
assert all(not any(row["on"] == "<Esc>" for row in layer.get("prepend_keymap", []))
           for name, layer in keymap.items() if name != "mgr")
for tool in ("tmux", "yazi", "nvim", "lua"):
    if not shutil.which(tool):
        raise SystemExit(f"Missing required test tool: {tool}")

unit = r'''
local plugin = dofile(arg[1])
local action
ya = { emit = function(name) action = name end }
for _, state in ipairs({ "idle", "find", "visual", "filter", "selected", "search", "yank", "find-and-yank" }) do
    cx = {
        active = { mode = { is_normal = true }, selected = {},
            current = { files = {}, cwd = setmetatable({ spec = { is_search = false } }, {
                __index = function(_, key) error("Unexpected or deprecated URL field: " .. key) end,
            }) } },
        yanked = {},
    }
    if state == "find" or state == "find-and-yank" then cx.active.finder = {} end
    if state == "visual" then cx.active.mode.is_normal = false end
    if state == "filter" then cx.active.current.files.filter = {} end
    if state == "selected" then cx.active.selected = { true } end
    if state == "search" then cx.active.current.cwd.spec.is_search = true end
    if state == "yank" or state == "find-and-yank" then cx.yanked = { true } end
    action = nil
    plugin.entry()
    local expected = state == "idle" and "quit" or state == "yank" and "unyank" or "escape"
    assert(action == expected, state .. ": " .. tostring(action))
end
'''
subprocess.run(["lua", "-", str(config / "plugins/escape-or-quit.yazi/main.lua")],
               input=unit, text=True, check=True)
print("PASS Escape state decisions and manager-only binding", flush=True)

with tempfile.TemporaryDirectory(prefix="ye-", dir="/tmp") as temporary:
    root = Path(temporary)
    work = root / "work"
    work.mkdir()
    sample = work / "alpha 'quoted'.txt"
    sample.write_text("original text\n")
    (work / "beta.txt").write_text("second file\n")
    test_config = root / "yazi"
    shutil.copytree(config, test_config)
    with (test_config / "keymap.toml").open("a") as stream:
        stream.write('\n[[mgr.prepend_keymap]]\non = "<F10>"\nrun = "shell \'sleep 5\'"\n')
    env = os.environ.copy()
    for key in ("TMUX", "TMUX_PANE", "YAZI_ID", "YAZI_LEVEL"):
        env.pop(key, None)
    env.update(TMUX_TMPDIR=str(root), YAZI_CONFIG_HOME=str(test_config),
               XDG_CONFIG_HOME=str(root / "config"), XDG_DATA_HOME=str(root / "data"),
               XDG_STATE_HOME=str(root / "state"), XDG_CACHE_HOME=str(root / "cache"))
    tmux = [shutil.which("tmux"), "-L", "test", "-f", "/dev/null"]

    def call(*args, check=True):
        result = subprocess.run([*tmux, *args], env=env, capture_output=True, text=True, timeout=10)
        if check and result.returncode:
            raise AssertionError(f"tmux {args}: {result.stderr}")
        return result

    def screen():
        return call("capture-pane", "-p", "-t", "check", check=False).stdout

    def alive():
        return call("has-session", "-t", "check", check=False).returncode == 0

    def until(predicate, description):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.05)
        raise AssertionError(description + "\n" + screen()[-2200:])

    def key(*keys):
        call("send-keys", "-t", "check", *keys)
        time.sleep(0.15)

    def literal(text):
        call("send-keys", "-t", "check", "-l", text)

    def terminal_reply():
        # Detached tmux has no terminal to answer DA1; avoid Yazi's five-second probe wait.
        call("send-keys", "-t", "check", "-l", "\x1b[?1;2c")
        time.sleep(0.1)

    def start():
        call("new-session", "-d", "-s", "check", "-x", "110", "-y", "32",
             "-c", str(work), "exec yazi")
        until(lambda: sample.name in screen() and " NOR " in screen(), "Yazi did not start")
        terminal_reply()

    def border():
        rows = screen().splitlines()
        return (len(rows) >= 3 and rows[0].startswith("╭") and rows[0].endswith("╮")
                and rows[-1].startswith("╰") and rows[-1].endswith("╯")
                and all(row.startswith("│") and row.endswith("│") for row in rows[1:-1]))

    def idle_exit():
        started = time.monotonic()
        key("Escape")
        until(lambda: not alive(), "Idle Escape did not exit Yazi")
        elapsed = time.monotonic() - started
        assert elapsed < 2, f"Idle Escape delayed {elapsed:.3f}s; check for API deprecation warnings"

    def cancel_then_exit(keys, label, escapes=1):
        start()
        key(*keys)
        for _ in range(escapes):
            key("Escape")
            assert alive(), f"Escape quit instead of cancelling {label}"
        idle_exit()
        print(f"PASS {label}: cancel first, then idle Escape exits", flush=True)

    try:
        call("new-session", "-d", "-s", "keeper", "exec sleep 120")
        start()
        until(border, "Yazi is missing its complete rounded outer frame")
        for width, height in ((64, 18), (140, 40), (110, 32)):
            call("resize-window", "-t", "check", "-x", str(width), "-y", str(height))
            until(border, f"Yazi border broke at {width}x{height}")
        print("PASS rounded outer frame surrounds header and footer and survives resizing", flush=True)
        idle_exit()
        print("PASS idle Escape exits real Yazi", flush=True)
        cancel_then_exit(("Space",), "selection")
        cancel_then_exit(("v",), "visual selection", escapes=2)
        cancel_then_exit(("y",), "pending copy")
        cancel_then_exit(("x",), "pending cut")
        cancel_then_exit(("F1",), "help", escapes=2)
        cancel_then_exit(("a",), "input", escapes=2)
        for trigger, label in (("/", "find"), ("f", "filter"), ("s", "search")):
            start()
            key(trigger)
            literal("alpha")
            key("Enter")
            time.sleep(0.3)
            key("Escape")
            assert alive(), f"Escape quit instead of cancelling {label}"
            idle_exit()
            print(f"PASS {label}: cancel first, then idle Escape exits", flush=True)

        start()
        key("F10")
        time.sleep(0.2)
        key("Escape")
        until(lambda: "quit" in screen().lower() and "task" in screen().lower(),
              "Unfinished task did not trigger the native quit warning")
        assert alive(), "Escape killed unfinished work"
        key("Escape")
        assert alive(), "Escape did not cancel the quit warning"
        time.sleep(5)
        idle_exit()
        print("PASS unfinished task warning is preserved; Escape cancels it", flush=True)

        start()
        panes = call("list-panes", "-a", "-F", "#{pane_id}").stdout
        key("Enter")
        until(lambda: "1,1" in screen(), "Neovim did not open")
        key("i")
        literal("edited ")
        key("Escape")
        assert alive() and "edited original text" in screen(), "Editor Escape closed the session"
        literal(":wq")
        key("Enter")
        until(lambda: str(work) in screen() and " NOR " in screen(), "Neovim did not return to Yazi")
        until(border, "Yazi border did not return after closing Neovim")
        terminal_reply()
        assert sample.read_text() == "edited original text\n"
        assert call("list-panes", "-a", "-F", "#{pane_id}").stdout == panes
        idle_exit()
        print("PASS Neovim Escape, save/return, and idle close without a new pane", flush=True)
    finally:
        call("kill-server", check=False)
print("PASS all checks:", config, flush=True)
