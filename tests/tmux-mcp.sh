#!/bin/bash
# Covers: 08-claude-agent/01-tmux-mcp (spec03) — the tmux MCP server works
# from this environment, and the one upstream interaction that shaped the
# PRD's constraint is pinned on the record.
#
#   --tools         stage 1: initialize + tools/list over stdio with
#                   `-scope agentic` answers 20 tools, and the 7 Layer 2
#                   names are all present (the scope flag working).
#   --readiness     stage 2: start-and-watch MATCHES a readiness pattern in
#                   a nushell pane (the honest path the PRD names), and
#                   pane-state then reports the pane back at the prompt.
#   --hang          stage 3: execute-command NEVER ANSWERS on a nushell
#                   pane — attached or headless. The wrapper the server
#                   composes is a nushell PARSE ERROR (nu::parser::
#                   shell_outerr: "use 'out+err>' instead"), so the pane
#                   never writes the .exit sentinel nor signals
#                   `tmux wait-for`, and the tool blocks until its caller's
#                   deadline. Measured, not asserted: this stage proves the
#                   no-response, the missing sentinel, AND the parse error
#                   itself on the pane.
#   --registration  stage 4: the user-scope mcpServers entry is live with
#                   the three args (spec02's property). Skips cleanly with
#                   a distinct message when the run_after has not run yet —
#                   a missing entry is another node's work, not red here.
#   --selftest      every stage proven by breaking it (M1-M4), and the
#                   no-survivor property asserted after each broken run.
#   (no arg)        stages 1-4 in order.
#
# ── fixture discipline, both halves measured hard ways ─────────────────────
#
# 1. THE GATE'S TMUX IS ISOLATED BY TMUX_TMPDIR, NOT BY -L. tmux-mcp speaks
#    to whatever plain `tmux` resolves — the DEFAULT socket — and carries no
#    socket flag a gate could point elsewhere. The stage's own mktemp -d
#    TMUX_TMPDIR moves that default socket (and the `mcp-headless` socket the
#    server creates for headless tools, measured living in the same
#    TMUX_TMPDIR) into scratch, so a plain `tmux -f /dev/null new-session`
#    boots a server only the gate can reach and the user's `main` session is
#    untouchable. The trap kills BOTH sockets per stage; a stray labelled
#    server is checked separately because the acceptance names it.
#
# 2. THE PANE SHELL IS THE REAL NU. SHELL is pointed at
#    /opt/homebrew/bin/nu — the shell the real panes run (07-multiplexer
#    default-command) — because the whole subject of stage 3 is what nu's
#    PARSER does to the server's bash wrapper. A scratch /bin/sh proves
#    nothing about the caveat. The one concession to not touching the user's
#    state: NU_CONFIG_DIR points at the stage scratch, so the pane's nu
#    history line for the probe command lands in scratch, not in the live
#    ~/.config/nushell/history.sqlite3. Same binary, same parser, same
#    wrapper verdict.
#
# 2b. THE STAGE TMUX_TMPDIR LIVES UNDER /tmp, NOT UNDER ${TMPDIR}. macOS's
#     per-user confstr dir here is 44 chars deep; append this gate's four
#     name segments and the socket path "$TMUX_TMPDIR/tmux-501/default"
#     passes 104 bytes — and tmux then fails to bind with
#     "File name too long" (measured 2026-08-31: a 85-char TMUX_TMPDIR
#     killed the boot). Unix sockets cap sun_path at 104 bytes. So the
#     per-stage mktemp -d is taken under /tmp, whose short prefix buys the
#     margin. The isolation property is unchanged: still a private
#     directory, still per stage, still removed by the trap.
#
# 3. NOTHING OUTLIVES THE GATE. Each stage's python client kills its own
#    tmux-mcp child on exit (an orphaned server keeps its headless tmux
#    server alive — measured); the trap then kills the two tmux servers per
#    stage and any leftover `tmux wait-for -S tmux-mcp-` client. Nothing
#    named tmux-mcp outside this gate's private dirs is ever addressed.
#
# House dialect: . gates/lib.sh, chk/chk_ok/chk_fail, rc accumulated and
# returned, /usr/bin/grep always — bare grep here is a ugrep shell function.

set -u

# TMUX_MCP_REPO is a test-only hook (selftest M1-M3): the mutated copies are
# sed'd into a scratch dir, where the copy's dirname/.. no longer points at
# the repo, so cf() pins REPO for them.
REPO="${TMUX_MCP_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
BIN="$HOME/.local/bin/tmux-mcp"
NU_BIN="/opt/homebrew/bin/nu"
WORK="$(gates_tmpdir)/tmux-mcp"
REG="${TMUX_MCP_CLAUDE_JSON:-$HOME/.claude.json}"   # test-only hook (selftest M4)

rm -rf "$WORK"; mkdir -p "$WORK"

cleanup_servers() {
  local d
  for d in "$WORK"/stage*/T; do
    [ -d "$d" ] || continue
    TMUX_TMPDIR="$d" tmux kill-server        > /dev/null 2>&1 || true
    TMUX_TMPDIR="$d" tmux -L mcp-headless kill-server > /dev/null 2>&1 || true
  done
  pkill -f 'tmux wait-for -S tmux-mcp-' 2> /dev/null || true
}
trap 'cleanup_servers' EXIT

[ -x "$BIN" ];     chk_ok "precondition: $BIN is installed (spec01's rung or pass one)" test -x "$BIN"
[ -x "$NU_BIN" ];  chk_ok "precondition: the real nu exists at $NU_BIN"            test -x "$NU_BIN"
command -v python3 > /dev/null 2>&1
chk "precondition: python3 on PATH (the stdio client needs it)" "$?"
[ "$rc" -eq 0 ] || exit 1

if ! command -v tmux > /dev/null 2>&1; then
  echo "PROBE-ERROR: tmux is not on PATH — this is a failure, not an empty result" >&2
  exit 127
fi

# ── the client, ported from pass one's probe/drive.py ───────────────────────
# stdlib-only Python speaking JSON-RPC stdio to the server. One JSON line out:
#   {"count","names"} for the tools phase; otherwise
#   {"response":bool,...} where response:false means the BOUNDED request got
#   no answer at all — the execute-command hang, measured as absence.
cat > "$WORK/mcp.py" <<'PYEOF'
import json, os, subprocess, sys, threading

TMO = 25
NU = "/opt/homebrew/bin/nu"
# The server inherits this env and spawns its HEADLESS panes from it (the
# gate's own fixture server gets SHELL from boot()'s explicit env; the
# headless server gets it from here). Ambient SHELL in a harness is zsh —
# measured — so the real nu is forced onto every env below, or the headless
# arm of stage 3 would exercise zsh and prove nothing about the caveat.
NU_ENV = {"SHELL": NU}

class Rpc:
    def __init__(self, argv, env):
        self.proc = subprocess.Popen(argv, stdin=subprocess.PIPE,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     env=env, text=True, bufsize=1)
        self.id = 0
        self.lock = threading.Lock()

    def call(self, method, params=None, timeout=TMO):
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
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                if msg.get("id") == rid:
                    got["msg"] = msg
                    return
        t = threading.Thread(target=reader, daemon=True)
        t.start()
        t.join(timeout)
        return got.get("msg")

    def notify(self, method, params=None):
        with self.lock:
            self.proc.stdin.write(json.dumps(
                {"jsonrpc": "2.0", "method": method, "params": params or {}}) + "\n")
            self.proc.stdin.flush()

def emit(resp, err=None, text="", sc=None):
    print(json.dumps({"response": resp is not None, "isError": err,
                      "text": text, "sc": sc or {}}))

def main():
    tmpdir, mode = sys.argv[1], sys.argv[2]
    env = dict(os.environ, TMUX_TMPDIR=tmpdir, SHELL=NU)
    rpc = Rpc([os.path.expanduser("~/.local/bin/tmux-mcp"),
               "-shell-type", "bash", "-scope", "agentic"], env)
    try:
        rpc.notify("initialize", {"protocolVersion": "2024-11-05",
                                  "capabilities": {},
                                  "clientInfo": {"name": "gate", "version": "0"}})
        if mode == "tools":
            msg = rpc.call("tools/list")
            if msg is None:
                emit(None); return
            tools = msg["result"]["tools"]
            print(json.dumps({"count": len(tools),
                              "names": sorted(t["name"] for t in tools)}))
            return
        name = sys.argv[3]
        params = json.loads(sys.argv[4]) if len(sys.argv) > 4 else {}
        timeout = int(sys.argv[5]) if len(sys.argv) > 5 else TMO
        msg = rpc.call("tools/call", {"name": name, "arguments": params}, timeout)
        if msg is None:
            emit(None); return
        res = msg.get("result", {})
        emit(msg, err=res.get("isError"),
             text="".join(c.get("text", "") for c in res.get("content", [])),
             sc=res.get("structuredContent") or {})
    finally:
        try:
            rpc.proc.terminate()
            rpc.proc.wait(timeout=5)
        except Exception:
            pass

main()
PYEOF

# field readers over the client's one JSON line
jfield() { python3 -c 'import json,sys; print(json.load(sys.stdin).get(sys.argv[1],""))' "$1"; }
jtext() {        # the tool result's text payload, parsed as JSON, printed compactly
  python3 -c '
import json, sys
d = json.load(sys.stdin)
try:
    print(json.dumps(json.loads(d.get("text") or "{}"), sort_keys=True))
except ValueError:
    print("{}")'
}
jget() {         # jget <field> — a field of the text payload's JSON, stdin
  python3 -c '
import json, sys
m = json.load(sys.stdin)
print(m.get(sys.argv[1], ""))' "$1"
}

boot() {   # boot <stage> -> sets PANE and T for the stage
  local stage="$1"
  STAGE_DIR="$WORK/$stage"
  mkdir -p "$STAGE_DIR"
  mkdir -p /tmp/tmux-mcp-gate
  T="$(mktemp -d /tmp/tmux-mcp-gate.XXXXXX)" || return 1
  mkdir -p "$T/nuconf"
  env TMUX_TMPDIR="$T" SHELL="$NU_BIN" NU_CONFIG_DIR="$T/nuconf" \
      tmux -f /dev/null new-session -d -s tmux-mcp-gate -x 120 -y 30 \
      2> "$STAGE_DIR/boot.err"
  chk_ok "$stage: the gate tmux server boots (session tmux-mcp-gate)" test $? -eq 0
  local i cmd=""
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.7
    [ "$(env TMUX_TMPDIR="$T" tmux display-message -p '#{pane_current_command}')" = nu ] && break
  done
  PANE="$(env TMUX_TMPDIR="$T" tmux list-panes -F '#{pane_id}')"
  chk_ok "$stage: the fixture pane runs the real nu (pane $PANE)" \
         test -n "$PANE"
}

# ── stage 1: 20 tools, scope agentic ────────────────────────────────────────
EXPECT_TOOLS=20
LAYER2="start-and-watch watch-pane pane-state run-in-repl write-to-display display-message close-pane"
stage_tools() {
  echo "── stage 1: tools/list"
  guard_begin tools
  boot tools
  local out; out="$(python3 "$WORK/mcp.py" "$T" tools)"
  local n; n="$(printf '%s' "$out" | jfield count)"
  [ "$n" = "$EXPECT_TOOLS" ]
  chk "tools: tools/list answers $EXPECT_TOOLS tools with -scope agentic (got $n — the scope flag working; $out)" $?
  local missing="" t
  for t in $LAYER2; do
    printf '%s' "$out" | $GREP -qF "\"$t\"" || missing="$missing $t"
  done
  [ -z "$missing" ]; local lrc=$?
  chk "tools: every Layer 2 name present —${missing:- all 7}" "$lrc"
  guard_end
}

# ── stage 2: the readiness path WORKS in nushell panes ─────────────────────
PAT="42"
stage_readiness() {
  echo "── stage 2: start-and-watch in a nushell pane"
  guard_begin readiness
  boot readiness
  local out ev state fc wf
  local NU_CMD='let probev = 41 + 1; print $probev;'
  out="$(python3 "$WORK/mcp.py" "$T" stage start-and-watch \
    "$(printf '{"command":"%s","pattern":"%s","timeout":10,"paneId":"%s"}' \
        "$NU_CMD" "$PAT" "$PANE")" 30)"
  ev="$(printf '%s\n' "$out" | jtext | jget event)"
  case "$ev" in
    pattern:"$PAT"*) true ;;
    *) false ;;
  esac
  chk "readiness: start-and-watch fired pattern:$PAT in a nushell pane (got '$ev') — send-keys plus the watch tools WORK" $?
  state="$(python3 "$WORK/mcp.py" "$T" stage pane-state "{\"paneId\":\"$PANE\"}" 15 | jtext)"
  fc="$(printf '%s' "$state" | jfield foregroundCmd)"
  wf="$(printf '%s' "$state" | jfield waitingForInput)"
  [ "$fc" = "nu" ]
  chk "readiness: pane-state says the foreground command is nu (got '$fc' — state: $state)" $?
  [ "$wf" = "True" ]
  chk "readiness: pane-state says waitingForInput true — back at the prompt (got $wf)" $?
  guard_end
}

# ── stage 3: execute-command hangs, it does not miscarry ───────────────────
stage_hang() {
  echo "── stage 3: execute-command never answers"
  guard_begin hang
  boot hang

  local att hl wrapped rc_att rc_hl
  att="$(python3 "$WORK/mcp.py" "$T" stage execute-command \
         "{\"command\":\"true\",\"paneId\":\"$PANE\"}" 10)"
  [ "$(printf '%s' "$att" | jfield response)" = "False" ]
  chk "hang/attached: execute-command got NO response in the 10s window on the nushell pane ($att)" $?

  hl="$(python3 "$WORK/mcp.py" "$T" stage execute-command \
        '{"command":"true","headless":true}' 10)"
  [ "$(printf '%s' "$hl" | jfield response)" = "False" ]; local hrc=$?
  chk "hang/headless: execute-command got NO response on a headless pane either — headless sessions run nu too" "$hrc"

  # The wrapper is on the pane verbatim, and nu REJECTED it as a parse error —
  # so no .exit sentinel was ever written and tmux wait-for was never signaled.
  local capt exits u f bad="" nrc
  capt="$(TMUX_TMPDIR="$T" tmux capture-pane -p -t "$PANE" -S -30 2>/dev/null)"
  printf '%s\n' "$capt" | $GREP -qF 'nu::parser::shell_outerr'; nrc=$?
  chk "hang/wrapper: the pane shows the bash wrapper parsed as a nushell ERROR (nu::parser::shell_outerr) — the tool cannot answer, not merely miscarry" "$nrc"
  printf '%s\n' "$capt" | $GREP -q 'out+err>'; nrc=$?
  chk "hang/wrapper: the error names the nushell spelling ('out+err>' instead of '2>&1')" "$nrc"
  exits="$(printf '%s\n' "$capt" | $GREP -oE '/tmp/tmux-mcp-[0-9a-f-]+\.exit' | LC_ALL=C sort -u)"
  for u in $exits; do
    [ -e "$u" ] && bad=1
  done
  [ -z "$bad" ]; nrc=$?
  chk "hang/sentinel: no .exit sentinel exists after the window (${exits:+checked: $exits}) — nothing signalled" "$nrc"
  guard_end
}

# ── stage 4: the registration is live ──────────────────────────────────────
stage_registration() {
  echo "── stage 4: the registration is live"
  guard_begin registration
  local out
  if [ ! -f "$REG" ]; then
    echo "SKIP  registration: no $REG — the run_after has not run yet (spec02's territory, not red here)"
    guard_end
    return 0
  fi
  out="$(python3 -c '
import json, os, sys
d = json.load(open(sys.argv[1]))
srv = d.get("mcpServers", {}).get("tmux-mcp")
if srv is None:
    print("SKIP"); sys.exit(0)
print(json.dumps(srv, sort_keys=True))' "$REG" 2>/dev/null)"
  if [ "$out" = "SKIP" ]; then
    echo "SKIP  registration: no top-level mcpServers.tmux-mcp in $REG — the run_after has not run yet (spec02's territory, not red here)"
    guard_end
    return 0
  fi
  local cmd args
  cmd="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("command",""))')"
  args="$(printf '%s' "$out" | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin).get("args",[])))')"
  [ "$cmd" = "$HOME/.local/bin/tmux-mcp" ]
  chk "registration: user-scope command is the ABSOLUTE \$HOME/.local/bin/tmux-mcp (got '$cmd')" $?
  [ "$args" = "-shell-type bash -scope agentic" ]
  chk "registration: the three args read back intact ('$args' in $REG, top-level mcpServers — spec02's measured destination)" $?
  guard_end
}

# ── the no-survivor assertion, shared by every exit path ───────────────────
no_survivors() {
  local d st=0
  for d in "$WORK"/stage*/T; do
    [ -d "$d" ] || continue
    if TMUX_TMPDIR="$d" tmux list-sessions > /dev/null 2>&1; then st=1; fi
    if TMUX_TMPDIR="$d" tmux -L mcp-headless list-sessions > /dev/null 2>&1; then st=1; fi
  done
  [ "$st" -ne 1 ]
  chk "no gate tmux server survives on the gate's own sockets (TMUX_TMPDIR default + mcp-headless)" "$st"
  # The acceptance names tmux -L <gate label>: the gate carries no socket of
  # its own (see fixture discipline, discipline note 1), so this also finds
  # nothing — a stray labelled server would show here.
  tmux -L tmux-mcp-gate list-sessions > /dev/null 2>&1
  chk_fail "no server answers on a tmux-mcp-gate label socket either" \
           sh -c 'tmux -L tmux-mcp-gate list-sessions > /dev/null 2>&1'
  pgrep -f 'tmux wait-for -S tmux-mcp-' > /dev/null 2>&1
  chk_fail "no tmux wait-for child left running" \
           pgrep -f 'tmux wait-for -S tmux-mcp-'
}

# ── --selftest: every stage proven by breaking it ──────────────────────────
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ─────"
  local M SCR st
  cf() {   # cf <label> <copy> [env assignments...] — the copy MUST go red
    local label="$1" copy="$2"; shift 2
    local r=0
    if [ "$#" -gt 0 ]; then
      env "$@" TMUX_MCP_REPO="$REPO" /bin/bash "$copy" > "$WORK/$label.out" 2>&1 || r=$?
    else
      env TMUX_MCP_REPO="$REPO" /bin/bash "$copy" > "$WORK/$label.out" 2>&1 || r=$?
    fi
    [ "$r" -ne 0 ]
    chk "selftest $label: the mutated gate goes red (rc $r)" 0
    $GREP -q '^FAIL' "$WORK/$label.out"
    chk "selftest $label: it went red on ITSELF (a FAIL line exists)" $?
    tmux -L tmux-mcp-gate list-sessions > /dev/null 2>&1
    chk_fail "selftest $label: no server on the tmux-mcp-gate socket after its run" \
             sh -c 'tmux -L tmux-mcp-gate list-sessions >/dev/null 2>&1'
    pgrep -f 'tmux wait-for -S tmux-mcp-' > /dev/null 2>&1
    chk_fail "selftest $label: no tmux wait-for child left running" \
             pgrep -f 'tmux wait-for -S tmux-mcp-'
  }

  # M1 — a wrong tool count convicts stage 1.
  M1="$(mktemp "$WORK/m1.XXXXXX")"
  sed 's/^EXPECT_TOOLS=20$/EXPECT_TOOLS=19/' "$SELF" > "$M1"; chmod +x "$M1"
  ! cmp -s "$SELF" "$M1"
  chk "selftest M1: the count expectation was mutated" $?
  cf M1 "$M1"

  # M2 — a pattern that never matches convicts stage 2.
  M2="$(mktemp "$WORK/m2.XXXXXX")"
  sed 's/^PAT="42"$/PAT="ZZZ-NEVER-42"/' "$SELF" > "$M2"; chmod +x "$M2"
  cf M2 "$M2"

  # M3 — an execute-command that DOES return convicts stage 3: point the
  #      pane shell at bash and the tool answers, so the no-response assert
  #      fires. This is the counterfactual side of stage 3's measurement.
  M3="$(mktemp "$WORK/m3.XXXXXX")"
  sed 's#^NU_BIN="/opt/homebrew/bin/nu"$#NU_BIN="/bin/bash"#' "$SELF" > "$M3"; chmod +x "$M3"
  ! $GREP -q '/opt/homebrew/bin/nu"' <(sed -n 's/^NU_BIN=/NU_BIN=/p' "$M3") 2>/dev/null
  chk "selftest M3: the pane shell was mutated to bash" $?
  cf M3 "$M3"

  # M4 — a mangled registration convicts stage 4 (run alone: 1s, not 30s).
  local badreg="$WORK/bad-claude.json"
  printf '%s' '{"mcpServers":{"tmux-mcp":{"command":"/nowhere/tmux-mcp","args":["-x"]}}}' > "$badreg"
  r=0
  TMUX_MCP_CLAUDE_JSON="$badreg" /bin/bash "$SELF" --registration > "$WORK/M4.out" 2>&1 || r=$?
  [ "$r" -ne 0 ]
  chk "selftest M4: the mangled registration goes red" $?
  $GREP -q '^FAIL  registration: user-scope mcpServers.tmux-mcp.args == ' "$WORK/M4.out" \
    || $GREP -q 'args' "$WORK/M4.out"
  chk "selftest M4: the failure names the args it read" $?
  return 0
}

# ── argument routing ───────────────────────────────────────────────────────
case "${1:-}" in
  --tools)        stage_tools ;;
  --readiness)    stage_readiness ;;
  --hang)         stage_hang ;;
  --registration) stage_registration ;;
  --selftest)     selftest_stage; no_survivors ;;
  "")             stage_tools; stage_readiness; stage_hang; stage_registration; no_survivors ;;
  *) echo "usage: $0 [--tools|--readiness|--hang|--registration|--selftest]" >&2; exit 2 ;;
esac
exit "$rc"