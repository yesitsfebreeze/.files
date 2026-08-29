#!/usr/bin/env bash
# C.4 — the five manual boxes of gates/manual/wave4.md, driven.
#
# 01-capsule/04-recent-workspaces was `blocked` from 2026-08-23 to 2026-08-29
# on five checks its own `## Blocked` section called "five things only a human
# at a GUI WezTerm can see". Measured 2026-08-29, that reason was true and was
# not the blocker:
#
#   home/dot_config/wezterm/wezterm.lua:1213   key "s" CTRL|SHIFT -> capsule recent
#   ~/.config/wezterm/*.lua                    no match
#   wezterm show-keys --lua | grep -c SpawnCommandInNewTab   ->  0
#   command -v capsule                         ->  nothing
#   chezmoi source-path                        ->  /Users/feb/dev/.files/home
#
# Nobody could press Ctrl+Shift+S on this machine and get a picker, human or
# not: the binding is in THIS repo and is not in the running config, because
# `just cutover` has not run. So this harness stages a HOME out of the repo
# tree and drives an isolated WezTerm against it.
#
# ── WHY EACH AWKWARD PART IS THE WAY IT IS ─────────────────────────────────
#
# 1. THE PROBE GETS ITS OWN APP BUNDLE, and that is not decoration. Measured:
#    with both instances under `com.github.wez.wezterm`, System Events'
#    `set frontmost of (process whose unix id is <probe>) to true` reports
#    success and the USER's window stays frontmost — activation resolves at
#    the bundle, not the process, and `perform action "AXRaise"` does not fix
#    it either. A copy of the wezterm-gui binary in a bundle declaring
#    CFBundleIdentifier=dev.dotfiles.c4probe makes
#    `tell application id "dev.dotfiles.c4probe" to activate` land on the
#    probe, verified by reading frontmost back.
#
# 2. EVERY KEYSTROKE IS GUARDED ON FRONTMOST, and the guard has already
#    fired for real. Before the bundle existed the probe could not be raised,
#    and an unguarded `keystroke` would have typed into the user's live
#    session. The guard is an `error`, never a warning: a keystroke sent to
#    the wrong window is not a failed check, it is damage.
#
# 3. `wezterm cli` IS PINNED TO THE PROBE'S OWN SOCKET. WEZTERM_UNIX_SOCKET is
#    inherited from whatever terminal runs this script and points at the
#    user's mux; `wezterm cli --class c4probe` does NOT override it and will
#    happily list the user's panes. Measured 2026-08-29: with the probe's
#    socket path over SUN_LEN, wezterm logged
#    `Failed to bind ... path must be shorter than SUN_LEN`, the probe came
#    up with no socket at all, and `--class c4probe list` returned the USER's
#    nine panes. Hence both the short HOME and the explicit socket.
#
# 4. HOME IS A SHORT SYMLINK. A unix socket path is capped near 104 bytes and
#    the scratch dir alone is ~90. The files still live in the scratch tree;
#    only the path used to reach them is short.
#
# 5. KEYSTROKES ARE SENT UNTIL THE SCREEN AGREES, never once with a sleep.
#    Measured: the first keystroke after tv starts is dropped often enough to
#    matter, and a fixed `sleep` turned one run into `t beibetabeta` typed at
#    a shell prompt. Every send re-reads the pane and retries.
#
# 6. THE FIXTURE PATHS ARE SHORT, and that is a correctness requirement, not
#    tidiness. tv's matcher is a fuzzy SUBSEQUENCE matcher. Staged under
#    `/private/tmp/claude-501/-Users-feb-dev-dotfiles/<uuid>/scratchpad/...`,
#    all three entries match the query `beta` — b,e,t,a occur in order inside
#    the shared prefix — so the picker shows `1 / 3` and narrowing LOOKS
#    broken. It is not; the fixture was. Under /tmp/c4h/work the same query
#    gives `1 / 1`. A narrowing assertion is only as good as a fixture whose
#    non-matches cannot match.
#
# NOT A GATE, and deliberately absent from gates/waves.tsv: it needs a GUI, a
# window server and Accessibility permission for the controlling terminal.
# `just gates` must stay headless. Run it by hand.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="${C4_SCRATCH:-/private/tmp/claude-501/c4}"
LINK="${C4_LINK:-/tmp/c4h}"
BUNDLE_ID="dev.dotfiles.c4probe"
WEZTERM_BIN="${WEZTERM_BIN:-/opt/homebrew/bin/wezterm}"
APP_SRC="${APP_SRC:-/Applications/WezTerm.app/Contents/MacOS/wezterm-gui}"

PASS=0; FAIL=0
chk() { # chk <label> <expected> <actual>
  local l="$1" e="$2" a="$3"
  if [ "$e" = "$a" ]; then PASS=$((PASS+1)); echo "PASS  $l"
  else FAIL=$((FAIL+1)); echo "FAIL  $l"; echo "        expected: $e"; echo "        actual:   $a"; fi
}
chk_has() { # chk_has <label> <needle> <haystack>
  local l="$1" n="$2" h="$3"
  case "$h" in *"$n"*) PASS=$((PASS+1)); echo "PASS  $l";;
    *) FAIL=$((FAIL+1)); echo "FAIL  $l"; echo "        missing: $n";; esac
}
chk_hasnt() {
  local l="$1" n="$2" h="$3"
  case "$h" in *"$n"*) FAIL=$((FAIL+1)); echo "FAIL  $l"; echo "        present but must not be: $n";;
    *) PASS=$((PASS+1)); echo "PASS  $l";; esac
}
die() { echo "ABORT: $*" >&2; exit 2; }

# ── the staged HOME ─────────────────────────────────────────────────────────
# The repo's chezmoi source is not a HOME: `dot_` and `create_` are chezmoi
# attributes, not filenames. Rendering them here rather than running
# `chezmoi apply` keeps the live machine untouched — this harness must never
# be the thing that performs the cutover.
stage_home() {
  rm -rf "$SCRATCH"; mkdir -p "$SCRATCH/home/.cache/capsule"
  ln -sfn "$SCRATCH/home" "$LINK"
  mkdir -p "$SCRATCH/home/.config"
  local d
  for d in nushell wezterm television capsule; do
    [ -d "$REPO/home/dot_config/$d" ] && cp -R "$REPO/home/dot_config/$d" "$SCRATCH/home/.config/$d"
  done
  python3 - "$SCRATCH/home/.config" <<'PY'
import os,sys
root=sys.argv[1]
for dp,dns,fns in os.walk(root,topdown=False):
    for n in fns+dns:
        new=n
        if new.startswith('create_'):     new=new[len('create_'):]
        if new.startswith('executable_'): new=new[len('executable_'):]
        if new.startswith('dot_'):        new='.'+new[len('dot_'):]
        if new!=n: os.rename(os.path.join(dp,n),os.path.join(dp,new))
PY
  chmod +x "$SCRATCH/home/.config/capsule/setup-credentials.sh" 2>/dev/null
  # config.nu `source`s these at PARSE time; without them nu will not start.
  HOME="$LINK" bash "$REPO/home/run_after_generate-shell-init.sh" >/dev/null 2>&1
  [ -f "$LINK/.cache/nushell/init/starship.nu" ] || die "shell-init did not generate"
  mkdir -p "$LINK/work/alpha" "$LINK/work/beta" "$LINK/work/gamma"
}

# Containers this harness created on an earlier run, and ONLY those. Matched
# on the bind-mount source being under the staged HOME, never on the name: a
# `capsule-beta-*` on the user's machine is the user's. A left-over container
# is not inert — it is what `capsule` attaches to instead of creating, so a
# stale one silently changes what the next run measures.
drop_stale_capsules() {
  local c src
  for c in $(docker ps -aq 2>/dev/null); do
    src="$(docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' "$c" 2>/dev/null)"
    case " $src " in
      *" $SCRATCH"*|*" $LINK"*) docker rm -f "$c" >/dev/null 2>&1 ;;
    esac
  done
}

seed_store() { # seed_store <dir>...
  local out="" d
  for d in "$@"; do [ -n "$out" ] && out="$out, "; out="$out\"$d\""; done
  printf '[%s]\n' "$out" > "$LINK/.cache/capsule/recents.nuon"
}
store_raw() { cat "$LINK/.cache/capsule/recents.nuon" 2>/dev/null; }

# ── the probe ───────────────────────────────────────────────────────────────
build_bundle() {
  local A="$SCRATCH/C4Probe.app"
  rm -rf "$A"; mkdir -p "$A/Contents/MacOS"
  cp "$APP_SRC" "$A/Contents/MacOS/wezterm-gui" || die "cannot copy $APP_SRC"
  cat > "$A/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>C4Probe</string>
  <key>CFBundleExecutable</key><string>wezterm-gui</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
  codesign --force --sign - "$A" >/dev/null 2>&1
  echo "$A"
}

launch_probe() {
  local A; A="$(build_bundle)"
  env -u WEZTERM_UNIX_SOCKET -u WEZTERM_PANE HOME="$LINK" TMPDIR="$LINK" \
    "$A/Contents/MacOS/wezterm-gui" \
    --config-file "$LINK/.config/wezterm/wezterm.lua" \
    start --always-new-process --class c4probe \
    > "$SCRATCH/gui.out" 2> "$SCRATCH/gui.err" &
  PROBE_PID=$!
  SOCK="$LINK/.local/share/wezterm/gui-sock-$PROBE_PID"
  local i
  for i in $(seq 1 40); do [ -S "$SOCK" ] && break; sleep 0.5; done
  [ -S "$SOCK" ] || die "probe socket never appeared: $SOCK (see $SCRATCH/gui.err)"
  # The socket is the isolation. Prove it addresses the probe and not the
  # user's mux before a single key is sent.
  local seen; seen="$(wez list --format json | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
  [ "$seen" -ge 1 ] || die "probe socket lists no panes"
}

kill_probe() {
  [ -n "${PROBE_PID:-}" ] || return 0
  kill "$PROBE_PID" 2>/dev/null
  wait "$PROBE_PID" 2>/dev/null
  sleep 2
  return 0
}

wez() { env WEZTERM_UNIX_SOCKET="$SOCK" "$WEZTERM_BIN" cli "$@"; }
text() { wez get-text --pane-id "${1:-0}" 2>/dev/null; }
panes() { wez list --format json | python3 -c 'import json,sys;print(" ".join(str(p["pane_id"]) for p in json.load(sys.stdin)))'; }
tabs()  { wez list --format json | python3 -c 'import json,sys;print(len({p["tab_id"] for p in json.load(sys.stdin)}))'; }

# key <applescript> — activate the probe, REFUSE unless it is frontmost, send.
key() {
  osascript <<OSA
tell application id "$BUNDLE_ID" to activate
delay 0.6
tell application "System Events"
  set f to unix id of (first process whose frontmost is true)
  if f is not $PROBE_PID then error "GUARD REFUSED: frontmost=" & f & " probe=$PROBE_PID"
  $1
end tell
OSA
}

# wait_for <pane> <pattern> <secs> — poll until the screen agrees.
wait_for() {
  local p="$1" pat="$2" n="${3:-20}" i
  for i in $(seq 1 "$n"); do
    text "$p" | grep -qF "$pat" && return 0
    sleep 1
  done
  return 1
}

# key_until <pane> <pattern> <secs> <applescript> — send, verify, retry.
# See note 5: the first key after tv starts is dropped often enough to matter.
key_until() {
  local p="$1" pat="$2" n="$3" script="$4" i
  for i in 1 2 3 4 5; do
    key "$script" >/dev/null 2>&1 || return 2
    wait_for "$p" "$pat" "$n" && return 0
  done
  return 1
}

# key_until_tabs <target-count> <applescript> — send until the tab count moves.
# Same reason as key_until: a single send is unreliable, and on 2026-08-29 a
# dropped Ctrl+Shift+T made C.4/4 red (expected 12 tabs, got 11) against a
# binding that was working. Retrying is honest here because the assertion is
# on the RESULT, not on how many times the key was pressed — and if the
# binding were genuinely broken, no number of retries would move the count.
key_until_tabs() {
  local want="$1" script="$2" i
  for i in 1 2 3 4 5; do
    key "$script" >/dev/null 2>&1
    local j
    for j in 1 2 3 4 5 6; do
      [ "$(tabs)" -ge "$want" ] && return 0
      sleep 1
    done
  done
  return 1
}

prompt_ready() { # settle the pane back to an idle nushell prompt
  wez send-text --pane-id "${1:-0}" --no-paste "clear
" >/dev/null 2>&1
  sleep 1
}

# ════════════════════════════════════════════════════════════════════════════
# The five boxes of gates/manual/wave4.md, in the order they are written there
# ════════════════════════════════════════════════════════════════════════════

# C.4/1 — the picker, after a restart.
#   PASS: a list titled `Recent` opens with all three, newest first; typing
#   narrows it; Enter attaches to that directory's capsule at /workspace.
c4_1_picker_after_restart() {
  echo "── C.4/1 the picker, after a restart"
  # The restart is the box's own precondition and it is the reason the store
  # is a file: seed, quit, relaunch, and only then look.
  seed_store "$LINK/work/gamma" "$LINK/work/beta" "$LINK/work/alpha"
  kill_probe
  launch_probe
  chk "restart: the probe is a different process than before" "different" \
      "$([ "$PROBE_PID" != "${PREV_PID:-none}" ] && echo different || echo same)"
  prompt_ready 0

  key_until 0 "Recent" 15 'keystroke "s" using {control down, shift down}' \
    || { echo "FAIL  C.4/1 the picker never opened"; FAIL=$((FAIL+1)); return 1; }
  local scr; scr="$(text 0)"
  chk_has "1a: the list is titled 'Recent'"      "Recent"           "$scr"
  chk_has "1b: gamma is listed"                  "/work/gamma"      "$scr"
  chk_has "1c: beta is listed"                   "/work/beta"       "$scr"
  chk_has "1d: alpha is listed"                  "/work/alpha"      "$scr"
  chk_has "1e: the count is three"               "1 / 3"            "$scr"

  # Newest first: the store's order, read off the screen rather than assumed.
  local order; order="$(printf '%s\n' "$scr" | grep -oE '/work/(alpha|beta|gamma)' | sed 's#/work/##' | tr '\n' ' ' | sed 's/ $//')"
  chk "1f: newest first — the store's order, on screen" "gamma beta alpha" "$order"

  key_until 0 "1 / 1" 10 'keystroke "beta"' \
    || { echo "FAIL  1g: typing did not narrow"; FAIL=$((FAIL+1)); }
  scr="$(text 0)"
  chk_has "1g: typing 'beta' narrows to one"     "1 / 1"            "$scr"
  chk_has "1h: the one left is beta"             "/work/beta"       "$scr"
  chk_hasnt "1i: gamma is gone from the results" "/work/gamma"      "$scr"

  # Enter attaches. The capsule prompt is the container's zsh at /workspace.
  #
  # Enter is retried like every other key, and for the same measured reason: a
  # single send left the picker open through the whole 240s window on
  # 2026-08-29 while the identical sequence driven by hand had worked. Confirm
  # by the picker going away, not by having sent the key.
  local i
  for i in 1 2 3 4 5; do
    key 'key code 36' >/dev/null 2>&1
    sleep 3
    text 0 | grep -qF "Recent" || break
  done
  if wait_for 0 "/workspace" 240; then
    scr="$(text 0)"
    chk_has "1j: Enter attached — the shell is at /workspace" "/workspace" "$scr"
  else
    echo "FAIL  1j: no /workspace prompt within 240s"; FAIL=$((FAIL+1))
    echo "        last screen:"; text 0 | grep -v '^[[:space:]]*$' | tail -6 | sed 's/^/        /'
  fi
  PREV_PID="$PROBE_PID"
}

# C.4/2 — the new-tab variant. With something running in the current pane,
#   press Ctrl+Shift+O. PASS: a new tab opens, the picker is in that tab, the
#   pick attaches there, and the pane you came from is untouched.
#   Why a human, per the box: the binding is SpawnCommandInNewTab rather than
#   spawn-then-type precisely because a pane created this instant has no shell
#   reading its pty. "Something running" is the load-bearing precondition —
#   it is what proves the picker did not land in the busy pane.
c4_2_new_tab() {
  echo "── C.4/2 the new-tab variant"
  # A FRESH pane, never pane 0. C.4/1 leaves pane 0 attached inside the
  # container, and "the pane you came from is untouched" means nothing when
  # the pane you came from is a container shell this run put there.
  key_until_tabs "$(( $(tabs) + 1 ))" 'keystroke "t" using {control down, shift down}' || true
  sleep 2
  local origin; origin="$(panes | tr ' ' '\n' | tail -1)"
  prompt_ready "$origin"

  # Something running, with a marker the ECHO of the command cannot supply.
  # Measured 2026-08-29: asserting on a literal `C4_MARKER_DONE` typed into
  # the pane fails against its own echo — get-text returns the command line
  # too, so the check went red while the behaviour was correct. Splitting the
  # marker in the SOURCE means the typed line reads `"C4_MARKER" + "_DONE"`
  # and only the OUTPUT can ever read `C4_MARKER_DONE`.
  wez send-text --pane-id "$origin" --no-paste 'sleep 400sec; print ("C4_MARKER" + "_DONE")
' >/dev/null 2>&1
  sleep 3
  local before_tabs before_panes; before_tabs="$(tabs)"; before_panes="$(panes)"

  key_until_tabs "$((before_tabs+1))" 'keystroke "o" using {control down, shift down}' || true
  sleep 3
  local after_tabs after_panes; after_tabs="$(tabs)"; after_panes="$(panes)"
  chk "2a: a new tab exists" "$((before_tabs+1))" "$after_tabs"

  # the pane the picker is in: whatever is new
  local newp=""
  local p
  for p in $after_panes; do
    case " $before_panes " in *" $p "*) ;; *) newp="$p";; esac
  done
  chk "2b: exactly one new pane" "yes" "$([ -n "$newp" ] && echo yes || echo no)"
  if [ -n "$newp" ]; then
    wait_for "$newp" "Recent" 20 || true
    chk_has "2c: the picker is in the NEW tab" "Recent" "$(text "$newp")"
    chk_hasnt "2d: the picker is NOT in the busy pane" "Recent" "$(text "$origin")"
  fi
  # the pane we came from is untouched: still running the sleep, no marker
  chk_hasnt "2e: the origin pane is untouched — its command has not finished" \
            "C4_MARKER_DONE" "$(text "$origin")"
  C4_2_NEWPANE="$newp"
}

# C.4/3 — aborting costs nothing. Press Ctrl+Shift+O, then Esc.
#   PASS: the tab stays, with a usable nushell prompt in the directory you
#   picked from. Why a human: `nu --execute` is what leaves an interactive
#   shell behind an aborted pick.
c4_3_abort_costs_nothing() {
  echo "── C.4/3 aborting costs nothing"
  local p="${C4_2_NEWPANE:-}"
  [ -n "$p" ] || { echo "SKIP  3: no picker tab from C.4/2"; return 0; }
  local tabs_before; tabs_before="$(tabs)"
  key 'key code 53' >/dev/null 2>&1
  sleep 4
  chk "3a: the tab stays after Esc" "$tabs_before" "$(tabs)"
  # a usable prompt: the pane answers a command
  wez send-text --pane-id "$p" --no-paste "print C4_ABORT_ALIVE
" >/dev/null 2>&1
  if wait_for "$p" "C4_ABORT_ALIVE" 15; then
    PASS=$((PASS+1)); echo "PASS  3b: the shell behind the aborted pick is alive and interactive"
  else
    FAIL=$((FAIL+1)); echo "FAIL  3b: no usable prompt after Esc"
    text "$p" | grep -v '^[[:space:]]*$' | tail -4 | sed 's/^/        /'
  fi
}

# C.4/4 — Ctrl+Shift+T is still a plain tab.
#   Why a human, per the box: the automated gate reads show-keys --lua and
#   sees 'T' still bound to SpawnTab; that is the declaration, not the
#   behaviour. So this asserts the BEHAVIOUR: a tab appears and no picker
#   comes with it.
c4_4_plain_tab() {
  echo "── C.4/4 Ctrl+Shift+T is still a plain tab"
  local before_tabs before_panes; before_tabs="$(tabs)"; before_panes="$(panes)"
  key_until_tabs "$((before_tabs+1))" 'keystroke "t" using {control down, shift down}' || true
  sleep 2
  chk "4a: one more tab" "$((before_tabs+1))" "$(tabs)"
  local newp="" p
  for p in $(panes); do case " $before_panes " in *" $p "*) ;; *) newp="$p";; esac; done
  if [ -n "$newp" ]; then
    chk_hasnt "4b: no picker in it" "Recent" "$(text "$newp")"
    wez send-text --pane-id "$newp" --no-paste "print C4_PLAIN_TAB_OK
" >/dev/null 2>&1
    if wait_for "$newp" "C4_PLAIN_TAB_OK" 15; then
      PASS=$((PASS+1)); echo "PASS  4c: it is a plain, usable shell"
    else
      FAIL=$((FAIL+1)); echo "FAIL  4c: the new tab has no usable shell"
    fi
  else
    FAIL=$((FAIL+1)); echo "FAIL  4b: no new pane appeared"
  fi
}

# C.4/5 — a deleted directory. Delete a directory you mounted, then open the
#   picker twice. PASS: absent the first time, and recents.nuon no longer
#   names it. Why a human: prune-on-read is proven hermetically, but only a
#   real round trip shows the rewrite surviving the pick that follows it.
c4_5_deleted_directory() {
  echo "── C.4/5 a deleted directory"
  seed_store "$LINK/work/gamma" "$LINK/work/beta" "$LINK/work/alpha"
  rm -rf "$LINK/work/beta"
  chk "5a: precondition — beta is gone from disk" "gone" \
      "$([ -d "$LINK/work/beta" ] && echo present || echo gone)"
  chk_has "5b: precondition — the store still names it" "/work/beta" "$(store_raw)"

  # a fresh pane, so nothing from an earlier check is on screen
  key_until_tabs "$(( $(tabs) + 1 ))" 'keystroke "t" using {control down, shift down}' || true
  sleep 2
  local p; p="$(panes | tr ' ' '\n' | tail -1)"
  key_until "$p" "Recent" 15 'keystroke "s" using {control down, shift down}' || true
  local scr; scr="$(text "$p")"
  chk_hasnt "5c: FIRST open — beta is absent" "/work/beta" "$scr"
  chk_has   "5d: FIRST open — gamma is still there" "/work/gamma" "$scr"
  chk_has   "5e: FIRST open — the count is two" "1 / 2" "$scr"
  chk_hasnt "5f: the store no longer names it" "/work/beta" "$(store_raw)"

  key 'key code 53' >/dev/null 2>&1; sleep 2
  key_until "$p" "Recent" 15 'keystroke "s" using {control down, shift down}' || true
  scr="$(text "$p")"
  chk_hasnt "5g: SECOND open — still absent, not listed once more" "/work/beta" "$scr"
  chk_has   "5h: SECOND open — still two" "1 / 2" "$scr"
  key 'key code 53' >/dev/null 2>&1
}

# ════════════════════════════════════════════════════════════════════════════
# --selftest — the G.1 rule: no check ships unbroken.
#
# Each counterfactual must fail for a DIFFERENT reason, or the pair proves one
# thing twice. CF1 breaks the binding (nothing opens). CF2 breaks the data
# (the picker opens and is empty). CF3 breaks the targeting (the guard must
# refuse rather than type into the wrong window) — and CF3 is the one that
# matters, because its failure mode is damage to the user's session, not a
# red line in a report.
# ════════════════════════════════════════════════════════════════════════════
selftest() {
  echo "══ --selftest: three counterfactuals, three different reasons"
  stage_home

  # CF1 — the binding removed. The picker must not open at all.
  python3 - "$LINK/.config/wezterm/wezterm.lua" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old='{ key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\\r") },'
assert s.count(old)==1, "CF1 anchor not found — the counterfactual is stale"
open(p,'w').write(s.replace(old,'-- CF1: binding removed'))
PY
  seed_store "$LINK/work/gamma" "$LINK/work/beta" "$LINK/work/alpha"
  launch_probe; prompt_ready 0
  if key_until 0 "Recent" 8 'keystroke "s" using {control down, shift down}'; then
    FAIL=$((FAIL+1)); echo "FAIL  CF1: the picker opened with the binding REMOVED — the check cannot fail"
  else
    PASS=$((PASS+1)); echo "PASS  CF1: binding removed -> no picker (the key is what opens it)"
  fi
  kill_probe

  # CF2 — the binding restored, the store emptied. The picker opens and is
  # empty: a different failure than CF1, reached through the data.
  stage_home
  seed_store
  launch_probe; prompt_ready 0
  if key_until 0 "Recent" 12 'keystroke "s" using {control down, shift down}'; then
    local scr; scr="$(text 0)"
    chk_hasnt "CF2: with an empty store the picker lists no work dir" "/work/" "$scr"
  else
    # capsule may refuse to open a picker over an empty store; that is also a
    # red for the positive check and is recorded as what it is.
    PASS=$((PASS+1)); echo "PASS  CF2: empty store -> no picker at all (also not a green)"
  fi

  # CF3 — the guard. Point it at a PID that is not frontmost and require a
  # refusal. Nothing is typed either way; a pass here is the absence of a
  # keystroke, which is exactly the property that protects the user's session.
  local real="$PROBE_PID"
  PROBE_PID=999999
  if key 'keystroke "X"' >/dev/null 2>&1; then
    FAIL=$((FAIL+1)); echo "FAIL  CF3: the guard did NOT refuse a wrong-target keystroke"
  else
    PASS=$((PASS+1)); echo "PASS  CF3: guard refuses when the probe is not frontmost"
  fi
  PROBE_PID="$real"
  chk_hasnt "CF3b: and nothing was typed into the probe" "X" "$(text 0 | tail -2)"
  kill_probe
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  command -v osascript >/dev/null || die "osascript is required"
  [ -x "$WEZTERM_BIN" ] || die "wezterm not at $WEZTERM_BIN"
  [ -f "$APP_SRC" ] || die "wezterm-gui not at $APP_SRC"
  osascript -e 'tell application "System Events" to get name of (first process whose frontmost is true)' >/dev/null 2>&1 \
    || die "System Events is not reachable — grant Accessibility to the controlling terminal"

  case "${1:-}" in
    --selftest) selftest ;;
    *)
      drop_stale_capsules
      stage_home
      launch_probe
      PREV_PID="$PROBE_PID"
      c4_1_picker_after_restart
      c4_2_new_tab
      c4_3_abort_costs_nothing
      c4_4_plain_tab
      c4_5_deleted_directory
      kill_probe
      ;;
  esac
  echo
  echo "CHECKS: $((PASS+FAIL)) run, $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] && echo "EXIT=0" || echo "EXIT=1"
  [ "$FAIL" -eq 0 ]
}
main "$@"
