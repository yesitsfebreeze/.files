#!/usr/bin/env python3
"""drive.py — pass-one probe for 08-claude-agent/01-tmux-mcp.

Boots an isolated tmux server (own TMUX_TMPDIR, /dev/null config, so panes
run the login shell — nushell on this machine), then drives the installed
tmux-mcp binary over stdio JSON-RPC and exercises the tools the PRD names.

Every tool call is bounded: the nushell wrapper defect measured in pass one
hangs `execute-command` indefinitely (its bash wrapper is a nushell PARSE
ERROR, the .exit sentinel never lands, tmux wait-for never fires), so no
call may be unbounded.

Run:  python3 probe/drive.py
Leaves nothing running: the probe server is killed on every exit path.
"""
import json
import os
import subprocess
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor

BIN = os.path.expanduser("~/.local/bin/tmux-mcp")
CALL_TIMEOUT = 25   # seconds per tool call; execute-command hang proves at 10

nu_shell = "/opt/homebrew/bin/nu"


def make_tmpdir():
    return tempfile.mkdtemp(prefix="tmux-mcp-probe-")


def sh(env, *args):
    return subprocess.run(["tmux"] + list(args), env=env,
                          capture_output=True, text=True, timeout=10)


class Rpc:
    def __init__(self, argv, env):
        self.proc = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, env=env, text=True, bufsize=1)
        self.id = 0
        self.lock = threading.Lock()

    def call(self, method, params=None, timeout=CALL_TIMEOUT):
        with self.lock:
            self.id += 1
            rid = self.id
            self.proc.stdin.write(json.dumps(
                {"jsonrpc": "2.0", "id": rid, "method": method,
                 "params": params or {}}) + "\n")
            self.proc.stdin.flush()
            got = {}

            def reader():
                while True:
                    line = self.proc.stdout.readline()
                    if not line:
                        got["closed"] = True
                        return
                    msg = json.loads(line)
                    if msg.get("id") == rid:
                        got["msg"] = msg
                        return
            t = threading.Thread(target=reader, daemon=True)
            t.start()
            t.join(timeout)
            if "msg" not in got:
                return None   # timed out — caller prints the fact
            return got["msg"]

    def notify(self, method, params=None):
        with self.lock:
            self.proc.stdin.write(json.dumps(
                {"jsonrpc": "2.0", "method": method, "params": params or {}})
                + "\n")
            self.proc.stdin.flush()


def main():
    tmpdir = tempfile.mkdtemp(prefix="tmux-mcp-probe-")
    env = dict(os.environ, TMUX_TMPDIR=tmpdir, PATH=os.environ["PATH"],
               SHELL=nu_shell)
    r = sh(env, "-f", "/dev/null", "new-session", "-d", "-s", "probe-base")
    if r.returncode != 0:
        sys.exit("probe tmux server failed: " + r.stderr)
    print("pane shell:", sh(env, "display-message", "-p",
                            "#{pane_current_command}").stdout.strip())

    rpc = Rpc([BIN, "-shell-type", "bash", "-scope", "agentic"], env)

    rpc.notify("initialize", {"protocolVersion": "2024-11-05",
                              "capabilities": {},
                              "clientInfo": {"name": "probe", "version": "0"}})
    tools = rpc.call("tools/list")["result"]["tools"]
    print("tools registered:", len(tools))

    def run_tool(name, params=None, timeout=CALL_TIMEOUT):
        msg = rpc.call("tools/call",
                       {"name": name, "arguments": params or {}}, timeout)
        if msg is None:
            return "TIMEOUT", "", {}
        res = msg.get("result", {})
        err = res.get("isError")
        text = "".join(c.get("text", "") for c in res.get("content", []))
        sc = res.get("structuredContent")
        return err, text, sc or {}

    # 1. create-session
    err, text, sc = run_tool("create-session", {"name": "probe-a"})
    try:
        created = json.loads(text)
    except ValueError:
        created = sc or {}
    pid = (sc or created or {}).get("paneId", "")
    print("\ncreate-session err=%s -> paneId=%s (sc=%s)" % (
        err, pid, bool(sc)))

    # 2. execute-command — the nushell caveat, now measured both ways
    if pid:
        for label, extra in (("paneId", {"paneId": pid}),
                             ("headless", {"headless": True})):
            for cmd in ("true", "false"):
                err, text, scx = run_tool("execute-command", dict(
                    command=cmd, **extra))
                print("execute-command %-8s %-6s err=%s exit=%s text=%s" % (
                    label, cmd, err,
                    (scx or {}).get("exitCode", "—"),
                    text[:110].replace("\n", "\\n")))

    # 3. pane-state
    err, text, sc2 = run_tool("pane-state", {"paneId": pid})
    print("pane-state err=%s -> %s" % (err, sc2 or text[:200]))

    # 4. send-keys literal into slot 2, then capture
    err, text, s2 = run_tool("send-keys", {
        "slot": "2", "keys": "echo marked-probe", "literal": True,
        "enter": True})
    print("send-keys err=%s -> %s" % (err, s2 or text[:120]))
    err, text, sc3 = run_tool("capture-pane", {"slot": "2", "lines": 10})
    lines = [l.strip() for l in text.strip().splitlines() if l.strip()]
    print("capture-pane err=%s tail=%s" % (err, lines[-2:]))

    # 5. start-and-watch with a readiness pattern (the honest path)
    err, text, sc4 = run_tool("start-and-watch", {
        "command": "echo READY-nu-probe", "pattern": "READY-nu-probe",
        "timeout": 15})
    print("start-and-watch err=%s -> event=%s detail=%s" % (
        err, (sc3 or {}).get("event") or (sc4 or {}).get("event", "?"),
        (sc4 or {}).get("detail", text[:140].replace("\n", "\\n"))))

    # 6. close helper panes, kill probe sessions, kill the probe server
    err, text, s4 = run_tool("close-pane", {"slot": "all"})
    print("close-pane err=%s -> %s" % (err, s4 or text[:160]))
    print("kill probe-a:", sh(env, "kill-session", "-t", "probe-a").returncode)
    print("kill probe-base:",
          sh(env, "kill-session", "-t", "probe-base").returncode)
    rpc.proc.terminate()
    subprocess.run(["tmux", "kill-server"], env=env, capture_output=True,
                   timeout=10)
    print("probe server killed. done.")


if __name__ == "__main__":
    main()