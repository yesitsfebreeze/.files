#!/bin/bash
# Covers: 02-terminal/05-tab-content-state (task T.6) — the occupied/empty tab
# tint, box by box against its specs (specs/spec01.md, specs/spec02.md).
#
# Stages:
#   --static   greps over home/dot_config/wezterm/wezterm.lua: the learned
#              baseline in wezterm.GLOBAL, the OR over a tab's panes, the one
#              format-tab-title registration and its ANSI tint, the four
#              recheck triggers, the carried reasons (OSC 133 off, launchd's
#              empty GUI environment, the missing pane events), and the
#              refused names.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME, and `strings` over the sibling wezterm-gui proves R5's
#              accessor exists on the installed build — with the
#              known-absent method as the negative control. Also re-checks
#              that nothing here regresses T.1, T.2, T.3 or T.4.
#   (no arg)   both.
#
# No GUI is launched: occupancy is a live-session property, so the
# behavioural half is the six T.6 rows in gates/manual/wave4.md.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# TWO GREP TRAPS this gate is written around, both measured:
#   - `all_panes` as a bare substring has three hits in wezterm.lua via
#     01-appearance R6's `retint_all_panes`, which is a landed line this node
#     may not touch. The refused name is `mux.all_panes`, and that is what is
#     asserted.
#   - Several refused names are also CARRIED REASONS the block must keep as
#     comments — `OSC 133`, `633`, `os.getenv("SHELL")`. A file-wide or
#     block-wide count of those cannot be 0 and asserting it anyway is the
#     unsatisfiable-clause defect T.4's `opacity` box already recorded once.
#     They are asserted on NON-COMMENT lines only, exactly the way
#     01-appearance R10's `get_current_working_directory` already is. The
#     same goes for the shell-name check: file-wide it cannot be 0, because
#     the F6 binding's `"sh", "-lc"` (01-appearance R11) is a landed line, so
#     it is scoped to this node's block.
#
# Usage: bash tests/wezterm-tab-content-state.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# This node's block, extracted between its own header and the next one. Every
# block-scoped check runs on this and not on $SRC, for the reason the header
# comment gives.
BLOCK="$SCRATCH/tab-content-block"

# Comment prose on one line. This file wraps its comments at ~78 columns, so
# a carried reason straddles lines and per-line matching produces false
# negatives; the leading `--` has to go before norm, or the join reinserts it
# mid-phrase.
block_prose() { sed -e 's/^[[:space:]]*--[[:space:]]*//' "$BLOCK" | norm; }

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R6, as greps over wezterm.lua)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  sed -n '/── 05-tab-content-state/,/── R5: the tab title/p' "$SRC" > "$BLOCK"
  local block_lines
  block_lines="$(wc -l < "$BLOCK" | tr -d ' ')"
  chk_ok "static: the 05-tab-content-state block is present and non-trivial (got $block_lines lines)" \
         test "${block_lines:-0}" -gt 40

  # ── R1 — the two functions, the tab.panes read, and the OR shape.
  chk_ok "static: pane_programs is defined (R1)" \
         $GREP -qF 'local function pane_programs()' "$BLOCK"
  chk_ok "static: tab_is_occupied is defined (R1)" \
         $GREP -qF 'local function tab_is_occupied(tab)' "$BLOCK"
  chk_ok "static: tab_is_occupied reads tab.panes — the whole tab, not just its active pane (R1)" \
         $GREP -qF 'ipairs(tab.panes or {})' "$BLOCK"
  chk_ok "static: it compares the live foreground process against the pane's baseline (R1)" \
         $GREP -qF 'if base ~= nil and fg ~= base then' "$BLOCK"
  # The OR, not an AND: `return true` sits INSIDE the loop and `return false`
  # after it. An AND would invert both, and the two look identical at a
  # glance, so the order of the two returns is what is asserted.
  local true_line false_line
  true_line="$($GREP -n 'return true' "$BLOCK" | head -1 | cut -d: -f1)"
  false_line="$($GREP -n 'return false' "$BLOCK" | tail -1 | cut -d: -f1)"
  chk_ok "static: return true (line ${true_line:-absent} of the block) precedes return false (line ${false_line:-absent}) — the OR over panes, not an AND (R1)" \
         test -n "$true_line" -a -n "$false_line" -a "${true_line:-0}" -lt "${false_line:-0}"

  # ── R2 — four recheck triggers, one registration each.
  local ev
  for ev in update-status window-config-reloaded pane-focus-changed \
            window-focus-changed; do
    chk_ok "static: learn_pane_programs registered exactly once on $ev (R2)" \
           test "$($GREP -cF "wezterm.on(\"$ev\", learn_pane_programs)" "$SRC")" -eq 1
  done

  # ── R3 — one handler, the bare label for the focused tab, the ANSI tint.
  chk_ok "static: exactly one wezterm.on(\"format-tab-title\" in the whole file (R3)" \
         test "$($GREP -cF 'wezterm.on("format-tab-title"' "$SRC")" -eq 1
  # The handler itself sits just PAST the block marker (it is 01-appearance
  # R5's, edited in place), so it is extracted on its own rather than read out
  # of $BLOCK.
  awk '/^wezterm.on\("format-tab-title"/{f=1} f{print} f&&/^end\)$/{exit}' \
      "$SRC" > "$SCRATCH/tab-title-handler"
  chk_ok "static: the handler returns the bare label for the focused tab and for an empty one (R3)" \
         $GREP -qF 'if tab.is_active or not tab_is_occupied(tab) then' "$SCRATCH/tab-title-handler"
  chk_ok "static: the lit state is an ANSI slot name, not a colour value (R3)" \
         $GREP -qF 'AnsiColor = "Silver"' "$SCRATCH/tab-title-handler"
  chk_ok "static: the label is still the digit and nothing else (R3)" \
         $GREP -qF 'local label = string.format("  %d  ", tab.tab_index + 1)' "$SCRATCH/tab-title-handler"
  # colors.tab_bar is 01-appearance R4's, and it has no occupancy state to
  # add a key to: its keys are focus and hover, and it is WezTerm-wide.
  local tb_keys tb_count
  tb_keys="$(sed -n '/local tab_bar = {/,/^    }$/p' "$SRC" \
            | $GREP -oE '^        [a-z_]+ =' | sed 's/ =//;s/^ *//' | tr '\n' ' ')"
  tb_count="$(printf '%s' "$tb_keys" | wc -w | tr -d ' ')"
  chk_ok "static: colors.tab_bar still carries exactly the six keys 01-appearance R4 wrote (got: $tb_keys) (R3)" \
         test "${tb_count:-0}" -eq 6
  chk_ok "static: colors.tab_bar carries no occupancy key (R3)" \
         sh -c "printf '%s' \"\$1\" | $GREP -q 'background active_tab inactive_tab inactive_tab_hover new_tab new_tab_hover'" \
         _ "$tb_keys"

  # ── R4 — no shell-side dependency. THE check this requirement turns on.
  chk_ok "static: no shell name anywhere in this node's block — the baseline is learned, never named (R4)" \
         test "$($GREP -cE '"(nu|zsh|bash|fish|sh)"' "$BLOCK" || true)" -eq 0
  # The environment route and the prompt-marker route, on CODE lines. Both
  # are named in the block's comments on purpose — see the header's second
  # grep trap — so a bare count here would be unsatisfiable.
  local name
  for name in 'os\.getenv' '/etc/shells' 'dscl' 'getent' 'SetUserVar' 'OSC 133' '633'; do
    chk_ok "static: $name appears on no code line of the block — comments record it, the code refuses it (R4)" \
           test "$($GREP -v '^ *--' "$BLOCK" | $GREP -cE "$name" || true)" -eq 0
  done

  # R4's reasons survive as comments. Each cost a session to measure; losing
  # the comment costs the next reader the same session.
  local prose
  prose="$(block_prose)"
  chk_ok "static: the block still records OSC 133/633 as deliberately off (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'OSC 133/633 is off on purpose'" _ "$prose"
  chk_ok "static: and points at the node that turned it off (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'prds/04-shell/01-core-config R5'" _ "$prose"
  chk_ok "static: and names the phantom blank line under starship's two-line prompt (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'phantom blank line'" _ "$prose"
  chk_ok "static: the block still records that os.getenv(\"SHELL\") is nil under launchd (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'os.getenv(\"SHELL\") is nil in a GUI-launched WezTerm'" _ "$prose"
  chk_ok "static: and names what launchd's GUI environment does export (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'exports SSH_AUTH_SOCK and nothing else'" _ "$prose"
  chk_ok "static: the block still records that the baseline is LEARNED, never named (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'is LEARNED, never named'" _ "$prose"
  chk_ok "static: the block still records that this build emits no pane-created/pane-closed event (R2, R6)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'emits no pane-created and no pane-closed event'" _ "$prose"

  # ── R5 — the accessor, called once, guarded.
  chk_ok "static: get_foreground_process_name appears exactly once in the whole file (R5)" \
         test "$($GREP -c 'get_foreground_process_name' "$SRC")" -eq 1
  chk_ok "static: and that one call sits inside learn_pane_programs (R5)" \
         sh -c "awk '/^local function learn_pane_programs\(\)/{f=1} f{print} f&&/^end\$/{exit}' '$SRC' | $GREP -q 'get_foreground_process_name'"
  # pcall on a line at or before it, in that function: a pane can die
  # mid-iteration, which is why 01-appearance R6 wraps inject_output too.
  local pcall_line fg_line
  pcall_line="$($GREP -n 'local ok, name = pcall(function()' "$BLOCK" | head -1 | cut -d: -f1)"
  fg_line="$($GREP -n 'get_foreground_process_name' "$BLOCK" | head -1 | cut -d: -f1)"
  chk_ok "static: pcall (line ${pcall_line:-absent} of the block) guards the accessor call (line ${fg_line:-absent}) (R5)" \
         test -n "$pcall_line" -a -n "$fg_line" -a "${pcall_line:-0}" -le "${fg_line:-0}"

  # ── R6 — the baseline lives in GLOBAL, and is rebuilt rather than mutated.
  chk_ok "static: wezterm.GLOBAL.tab_pane_program is assigned exactly once (R6)" \
         test "$($GREP -c 'wezterm.GLOBAL.tab_pane_program =' "$SRC")" -eq 1
  chk_ok "static: it is read only through pane_programs() (R6)" \
         test "$($GREP -c 'wezterm.GLOBAL.tab_pane_program' "$SRC")" -eq 2
  chk_ok "static: the rebuild shape is present — local out = {} inside learn_pane_programs (R6)" \
         sh -c "awk '/^local function learn_pane_programs\(\)/{f=1} f{print} f&&/^end\$/{exit}' '$SRC' | $GREP -qF 'local out = {}'"
  # A write through a GLOBAL copy is the bug set_slots' comment already paid
  # for: the read copy is never assigned into.
  chk_ok "static: nothing assigns into the read copy — no known[...] = write (R6)" \
         test "$($GREP -cE 'known\[[^]]*\] *=' "$BLOCK" || true)" -eq 0
  # And no module-local table holds the baselines, which is the multi-context
  # rule the slot map above records.
  chk_ok "static: no module-local baseline table — every table literal in the block is function-scoped (R6)" \
         test "$($GREP -cE '^local [a-z_]+ = \{' "$BLOCK" || true)" -eq 0

  # ── the refused names.
  for name in 'mux\.all_panes' 'mux\.get_pane' 'PaneSelect' 'burrito'; do
    chk_ok "static: $name appears nowhere in the file (refused name / epic I3)" \
           test "$($GREP -cE "$name" "$SRC" || true)" -eq 0
  done
  chk_ok "static: get_current_working_directory appears on no code line — R10's comment carries it twice on purpose" \
         test "$($GREP -v '^ *--' "$SRC" | $GREP -c 'get_current_working_directory' || true)" -eq 0
  chk_fail "static: no #rrggbb constant anywhere in the file (epic acceptance)" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"

  # Census: the directory holds wezterm.lua and nothing else.
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binaries load the real file)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm loads $SRC"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then
    return
  fi
  echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/tab-content-probe" prc
  rm -rf "$H"; mkdir -p "$H"

  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  chk_ok "probe: ls-fonts exits 0 — the file loads standalone (rc=$prc)" \
         test "$prc" -eq 0
  chk_fail "probe: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"

  # ── R5, as a gate rather than as a sentence. The accessor has to exist on
  # the INSTALLED build, and the negative control is what makes the positive
  # result mean anything: get_current_working_directory is the method this
  # build does NOT have (01-appearance R10), so a `strings` invocation that
  # matched everything would fail the second assertion instead of quietly
  # passing the first on any binary at all.
  local real_wez gui_bin
  real_wez="$(readlink -f "$WEZTERM" 2>/dev/null || true)"
  gui_bin="${real_wez:+$(dirname "$real_wez")/wezterm-gui}"
  if [ -z "${gui_bin:-}" ] || [ ! -x "${gui_bin:-/nonexistent}" ] \
     || ! command -v strings > /dev/null 2>&1; then
    # Skipped, not failed: this check is about the installed build, not about
    # anything in the repo.
    echo "SKIP  probe: R5 strings check — need both the strings tool and a wezterm-gui beside $WEZTERM (resolved: ${gui_bin:-none})"
  else
    local fg_hits cwd_hits
    fg_hits="$(strings "$gui_bin" | $GREP -c 'get_foreground_process_name' || true)"
    cwd_hits="$(strings "$gui_bin" | $GREP -c 'get_current_working_directory' || true)"
    chk_ok "probe: get_foreground_process_name is present in $gui_bin (got $fg_hits hits, want >0) (R5)" \
           test "${fg_hits:-0}" -gt 0
    chk_ok "probe: negative control — get_current_working_directory is absent from the same binary (got $cwd_hits hits, want 0) (R5)" \
           test "${cwd_hits:-1}" -eq 0
  fi

  # ── no regression on T.1-T.4 from the same file.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua \
    > "$H/keys.lua" 2>/dev/null

  awk '/^    copy_mode = \{/{f=1;next} f&&/^    \},/{f=0} f' "$H/keys.lua" > "$H/copy_mode"
  awk '/^    jump_mode = \{/{f=1;next} f&&/^    \},/{f=0} f' "$H/keys.lua" > "$H/jump_mode"

  local cm_rows jm_rows
  cm_rows="$($GREP -c '{ key = ' "$H/copy_mode")"
  jm_rows="$($GREP -c '{ key = ' "$H/jump_mode")"

  chk_ok "probe: jump_mode still holds 36 rows (got $jm_rows) — no regression on T.3" \
         test "$jm_rows" -eq 36
  chk_ok "probe: act.Nop still appears exactly 27 times — Escape + 26 letters (T.3 R2)" \
         test "$($GREP -cF 'act.Nop' "$H/keys.lua")" -eq 27
  chk_ok "probe: copy_mode still holds 55 rows (got $cm_rows) — no regression on T.4" \
         test "$cm_rows" -eq 55
  chk_ok "probe: the F5 row still prints — no regression on T.3" \
         $GREP -qF "'F5'" "$H/keys.lua"
  chk_ok "probe: the F6 row still prints — no regression on T.1" \
         $GREP -qF "'F6'" "$H/keys.lua"
  chk_ok "probe: the X/CTRL copy-mode entry still prints — no regression on T.4" \
         sh -c "$GREP \"'X'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  chk_ok "probe: the Q/CTRL close-window row still prints — no regression on T.2" \
         sh -c "$GREP \"'Q'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  chk_ok "probe: the v/CTRL paste row still prints — no regression on T.4" \
         $GREP -qF "key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'" "$H/keys.lua"
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-tab-content-state gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-tab-content-state.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-tab-content-state gate: ALL PASS"; else echo "wezterm-tab-content-state gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
