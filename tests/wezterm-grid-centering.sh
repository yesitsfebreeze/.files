#!/bin/bash
# Covers: 02-terminal/07-grid-centering (task T.8) — the runtime owner of
# window_padding in home/dot_config/wezterm/wezterm.lua, box by box against
# its specs (specs/spec01-center-grid-lua.md,
# specs/spec02-grid-centering-gate.md).
#
# Stages:
#   --static   greps over the source file: the pure block and its sentinels,
#              the mux route to the tab, the measured cell, the reserved bar
#              with its build id, the floored total gap, the idempotency
#              guard, the three registrations, and the declarations this node
#              depends on (T.1's zeroed window_padding, the 5 s tick, the
#              tab-bar-shown floor).
#   --math     slices the pure grid_padding block out between its sentinels
#              and RUNS it against the geometries measured on the pinned
#              build. This is the point of the gate: the defect A4 settled —
#              a vertical arm that computes zero for every input — passes
#              every grep and every config-load probe, and only running the
#              arithmetic catches it.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME; the new block must not break T.1's standalone-load
#              guarantee.
#   (no arg)   all three.
#
# No GUI is launched. center_grid only fires on a live window, and
# window:set_config_overrides on a real session is exactly the disruption the
# five T.8 rows in gates/manual/wave3.md exist to avoid.
#
# There is no separate Lua interpreter on this host, and none is needed:
# `wezterm --config-file <file>` executes arbitrary Lua and a config that
# returns {} exits 0, so the pinned binary IS the interpreter. io.open and
# os.getenv are available inside it; the `debug` library is NOT (verified
# 2026-08-23), which is why grid_padding's arity is proved by its signature
# in --static rather than by reflection in --math.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. every write goes into gates_tmpdir, and HOME is pinned there for every
#      wezterm invocation. Note what is deliberately ABSENT: the sibling
#      gates snapshot the live wezterm config to prove they left it alone,
#      and this one does not name it at all. It reads exactly one file (the
#      repo source) and writes exactly one directory (the scratch dir), so
#      there is nothing to guard — spec02's own acceptance asks for the
#      stronger form, "the script never names the live config".
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# Usage: bash tests/wezterm-grid-centering.sh [--static|--math|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# Count occurrences of a reference to the padding IN FORCE, with `new_pad`
# masked out first. `new_pad.left` carries `pad.left` as a substring, so a
# bare count cannot tell the computed table from the one read back off the
# overrides — and telling them apart is the whole point of the R8 check.
pad_refs() {
  sed 's/new_pad/NEWPAD/g' "$SRC" | $GREP -c -o "pad\\.$1" | tr -d ' '
}

# The pure block, sliced between its sentinels — the same slice --math runs.
slice() { sed -n '/-- >>> grid-padding/,/-- <<< grid-padding/p' "$SRC"; }

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01, as greps over the source)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  # R1 — the pure block, its sentinels, and the handler around it.
  chk_ok "static: local function center_grid(window) present" \
         $GREP -qF 'local function center_grid(window)' "$SRC"
  chk_ok "static: local function grid_padding( present (R1)" \
         $GREP -qF 'local function grid_padding(' "$SRC"
  # -e, because a pattern that begins with `--` is otherwise read as an
  # option and grep exits 2 while looking like a clean miss.
  chk_ok "static: the opening sentinel -- >>> grid-padding is present" \
         $GREP -qF -e '-- >>> grid-padding' "$SRC"
  chk_ok "static: the closing sentinel -- <<< grid-padding is present" \
         $GREP -qF -e '-- <<< grid-padding' "$SRC"
  # The signature IS the R8 arity proof: wezterm's Lua ships no `debug`
  # library, so nothing inside --math can reflect on the parameter list.
  chk_ok "static: grid_padding takes the window and the cell and nothing else (R8)" \
         $GREP -qF 'local function grid_padding(win_w, win_h, cell_w, cell_h)' "$SRC"
  # The block must stay loadable with no wezterm module in scope: --math
  # slices it and runs it standalone. Comments are stripped first — the
  # empirical-constant note names the wezterm BUILD, and that is required.
  local code
  code="$(slice | sed -e 's/--.*$//')"
  chk_fail "static: the sliced block's CODE names no wezterm, window or config (R1)" \
           $GREP -qE 'wezterm|window|config' <<< "$code"

  # R2 — the mux route to the tab. The reason lives in the block's comment as
  # prose, so this absence check reads as a call-site check and cannot be
  # satisfied by a comment that merely mentions the pane path.
  chk_ok "static: mux_win:active_tab() present (R2)" \
         $GREP -qF 'mux_win:active_tab()' "$SRC"
  chk_fail "static: active_pane():tab() is called nowhere (R2)" \
           $GREP -qF 'active_pane():tab()' "$SRC"

  # R1, R3 — the cell is measured from the grid's own rendered pixels.
  chk_ok "static: cell_w comes from tab.pixel_width / tab.cols (R1/R3)" \
         $GREP -qF 'tab.pixel_width / tab.cols' "$SRC"
  chk_ok "static: cell_h comes from tab.pixel_height / tab.rows (R1/R3)" \
         $GREP -qF 'tab.pixel_height / tab.rows' "$SRC"

  # R4 — the bar is reserved, not measured, and the constant is dated.
  chk_fail "static: chrome_h appears nowhere — the derivation A4 removed (R4)" \
           $GREP -qF 'chrome_h' "$SRC"
  chk_ok "static: the reserve is math.ceil(cell_h) + 1 (R4)" \
         $GREP -qF 'math.ceil(cell_h) + 1' "$SRC"
  chk_ok "static: the empirical constant names the build 20240203-110809-5046fc22 (R4)" \
         $GREP -qF '20240203-110809-5046fc22' "$SRC"

  # R8 — neither axis folds the padding in force into its own arithmetic. One
  # occurrence each, and all four are the change comparison.
  local side
  for side in left right top bottom; do
    chk_ok "static: pad.$side is referenced exactly once (got $(pad_refs "$side")) (R8)" \
           test "$(pad_refs "$side")" -eq 1
  done

  # R5 — the TOTAL gap is floored before it is halved.
  chk_ok "static: tot_x floors the total horizontal gap (R5)" \
         $GREP -qF 'local tot_x = math.floor(' "$SRC"
  chk_ok "static: tot_y floors the total vertical gap (R5)" \
         $GREP -qF 'local tot_y = math.floor(' "$SRC"

  # R6 — one write, and it is inside the comparison against the padding in
  # force. The pattern carries the paren so the CALL is counted: the carried
  # reason names the same function in prose, and a bare name would count it.
  local n line
  n="$($GREP -c 'set_config_overrides(' "$SRC")"
  chk_ok "static: exactly one set_config_overrides( call site (got $n) (R6)" test "$n" -eq 1
  line="$($GREP -n 'set_config_overrides(' "$SRC" | head -1 | cut -d: -f1)"
  chk_ok "static: the write at line ${line:-absent} sits inside a comparison against pad (R6)" \
         sh -c "sed -n \"\$(( ${line:-4} - 3 )),${line:-0}p\" '$SRC' | $GREP -q '~= pad\\.'"

  # R7 — exactly three registrations, one per event.
  chk_ok "static: exactly 3 center_grid registrations (R7)" \
         test "$($GREP -c ', center_grid)' "$SRC")" -eq 3
  local ev
  for ev in window-resized window-config-reloaded update-status; do
    chk_ok "static: one registration for \"$ev\" (R7)" \
           test "$($GREP -c "wezterm.on(\"$ev\", center_grid)" "$SRC")" -eq 1
  done
  # A4's second finding: the live block said "~1s" in two places. The tick is
  # 5000 ms, so the number is 5 s and the stale one must not come over.
  chk_ok "static: status_update_interval = 5000 still present (R7)" \
         $GREP -qF 'status_update_interval = 5000' "$SRC"
  chk_fail "static: no comment claims font zoom is caught in ~1 s (A4)" \
           $GREP -qE '~1s|~1 s' "$SRC"

  # R9 and the reserve's precondition — declarations this node depends on and
  # must not have disturbed.
  chk_ok "static: T.1's zeroed window_padding declaration is intact (R9)" \
         $GREP -qF 'window_padding = { left = 0, right = 0, top = 0, bottom = 0 }' "$SRC"
  # THE RESERVE'S PRECONDITION, INVERTED 2026-08-30. This asserted
  # `hide_tab_bar_if_only_one_tab = true`, because the reserve assumed a bar
  # was shown and the nine-tab floor guaranteed it. The tmux cutover
  # (07-multiplexer/08-wezterm-reduction) removed both the floor and the
  # option and set `enable_tab_bar = false`, so the precondition is now the
  # opposite one — and this check is what CAUGHT that, on the quiet sweep,
  # before anyone looked at a window. It is inverted rather than deleted for
  # that reason: it is the only thing standing between a config change and a
  # silently off-centre grid.
  chk_ok "static: enable_tab_bar = false — there is no bar to reserve for (R4, inverted)" \
         $GREP -qF 'config.enable_tab_bar = false' "$SRC"
  # CODE, NOT COMMENTARY. The file QUOTES the old rule twice, in the note
  # explaining why the reserve moved — and that note is the valuable part. A
  # bare grep convicts the explanation of the removal, which is the same trap
  # tests/wezterm-appearance.sh records hitting on four checks the same day.
  chk_fail "static: …and no CODE line still sets hide_tab_bar_if_only_one_tab" \
         bash -c "$GREP -vE '^[[:space:]]*--' \"\$1\" | $GREP -q 'hide_tab_bar_if_only_one_tab'" _ "$SRC"
  # The reserve itself, as a byte fact: zero, and declared outside the pure
  # block so the --math slice still defaults to the measured formula.
  chk_ok "static: TAB_BAR_RESERVE = 0 is declared (R4)" \
         $GREP -qF 'local TAB_BAR_RESERVE = 0' "$SRC"
  chk_ok "static: …above the opening sentinel, not inside the pure block" \
         test "$($GREP -n 'local TAB_BAR_RESERVE = 0' "$SRC" | cut -d: -f1)" \
              -lt "$($GREP -n -- '-- >>> grid-padding' "$SRC" | cut -d: -f1)"

  # Epic acceptance: nothing below WezTerm hardcodes a palette, and the
  # directory holds one file.
  chk_fail "static: no #rrggbb constant anywhere in the file" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --math (the arithmetic, run against the measured geometries)
# ════════════════════════════════════════════════════════════════════════════
#
# The cases are the measurements in the node's Q4, taken on the pinned build
# at dpi 144, CaskaydiaCove, line_height = 1.0, retro tab bar shown. `bar` is
# the TRUE bar height, which the driver needs to model what WezTerm does with
# the padding it is handed; grid_padding never sees it.
stage_math() {
  echo "── stage --math: grid_padding, sliced out of $SRC and run"

  chk_ok "math: precondition: wezterm is on PATH (it is the Lua interpreter here)" \
         test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then return; fi
  echo "      math ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/math" P OUT
  rm -rf "$H"; mkdir -p "$H"
  P="$H/probe.lua"; OUT="$H/math.tsv"

  slice > "$P"
  chk_ok "math: the slice between the sentinels is non-empty" test -s "$P"

  cat >> "$P" <<'DRIVER'

-- ── the driver: not part of the ported block ────────────────────────────────
local cases = {
    -- label,        win_w, win_h, cell_w, cell_h, true bar, maximized,
    --                                          expected l, r, t, b
    { "f9-default",   880,  526, 11, 21, 22, false,  0,  0,  0,  0 },
    { "f12-default", 1120,  700, 14, 28, 28, false,  0,  0, 13, 14 },
    { "f14-default", 1280,  826, 16, 33, 34, false,  0,  0,  0,  0 },
    { "f17-default", 1600, 1000, 20, 40, 40, false,  0,  0, 19, 20 },
    { "f21-default", 2000, 1226, 25, 49, 50, false,  0,  0,  0,  0 },
    { "f9-max",      2992, 1756, 11, 21, 22, true,   0,  0,  6,  6 },
    { "f14-max",     2992, 1756, 16, 33, 34, true,   0,  0,  3,  3 },
    { "f21-max",     2992, 1756, 25, 49, 50, true,   8,  9, 20, 20 },
    { "f21-max2",    2472, 1694, 25, 49, 50, true,  11, 11, 13, 14 },
}

local out = {}
local function say(ok, msg)
    out[#out + 1] = (ok and "PASS" or "FAIL") .. "\t" .. msg
end

for _, c in ipairs(cases) do
    local label, win_w, win_h, cell_w, cell_h, bar, maxed =
        c[1], c[2], c[3], c[4], c[5], c[6], c[7]
    local exp_l, exp_r, exp_t, exp_b = c[8], c[9], c[10], c[11]

    local p = grid_padding(win_w, win_h, cell_w, cell_h)

    -- What grid_padding assumed, and what WezTerm actually re-fits inside the
    -- padded region once the true bar is taken off the top.
    local rows_assumed = math.floor((win_h - (math.ceil(cell_h) + 1)) / cell_h)
    local remaining = win_h - bar - p.top - p.bottom
    local rows_after = math.floor(remaining / cell_h)
    local rows_nopad = math.floor((win_h - bar) / cell_h)

    -- R5 as an inequality: over-padding below the assumed grid is what drops
    -- a column or row that the next tick adds back.
    say(remaining >= rows_assumed * cell_h,
        label .. ": no flicker — remaining " .. remaining ..
        " >= assumed grid " .. (rows_assumed * cell_h) .. " (R5)")

    -- R8, functionally: the same inputs give the same answer, and two extra
    -- arguments shaped like a padding cannot change it. The arity proof is
    -- the signature check in --static; wezterm ships no `debug` library.
    local p2 = grid_padding(win_w, win_h, cell_w, cell_h)
    local p3 = grid_padding(win_w, win_h, cell_w, cell_h, 37, 41)
    say(p2.left == p.left and p2.right == p.right
        and p2.top == p.top and p2.bottom == p.bottom
        and p3.left == p.left and p3.right == p.right
        and p3.top == p.top and p3.bottom == p.bottom,
        label .. ": pad-independent — repeated and padding-fed calls agree (R8)")

    say(p.left + p.right < math.ceil(cell_w)
        and math.abs(p.left - p.right) <= 1,
        label .. ": horizontal gap bounded — " .. p.left .. "+" .. p.right ..
        " < cell " .. math.ceil(cell_w) .. ", split within 1px (R1)")

    say(rows_nopad - rows_after <= 1,
        label .. ": row-loss bound — " .. rows_nopad .. " unpadded rows, " ..
        rows_after .. " after padding, at most 1 lost (R4)")

    if maxed then
        -- Fullscreen is the shape gui-startup actually produces.
        say(rows_after == rows_nopad,
            label .. ": maximized loses no row — " .. rows_after ..
            " == " .. rows_nopad .. " (R4)")
        -- THE Q4 REGRESSION CHECK. The live arithmetic, ported unchanged,
        -- returns 0 here for all four of these.
        say(p.top > 0,
            label .. ": the vertical arm is ALIVE — top = " .. p.top ..
            " > 0 (R4, the Q4 finding)")
    end

    say(p.left == exp_l and p.right == exp_r
        and p.top == exp_t and p.bottom == exp_b,
        label .. ": exact padding — got " .. p.left .. "/" .. p.right ..
        " x " .. p.top .. "/" .. p.bottom .. ", expected " .. exp_l .. "/" ..
        exp_r .. " x " .. exp_t .. "/" .. exp_b)
end

local f = io.open(os.getenv("OUT"), "w")
f:write(table.concat(out, "\n") .. "\n")
f:close()
return {}
DRIVER

  env HOME="$H" OUT="$OUT" "$WEZTERM" --config-file "$P" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"

  # A missing or empty result file is ONE loud failure, never a silent pass:
  # a driver that never ran would otherwise report nothing at all and the
  # stage would look green.
  if [ ! -s "$OUT" ]; then
    chk "math: the driver produced no result file — the probe never ran" 1
    $GREP -v '^$' "$H/probe.err" | head -20 | sed 's/^/      /'
    return
  fi

  local st msg
  while IFS=$'\t' read -r st msg; do
    [ -n "${st:-}" ] || continue
    if [ "$st" = "PASS" ]; then chk "math: $msg" 0; else chk "math: $msg" 1; fi
  done < "$OUT"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binary loads the real file)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm loads $SRC against a scratch HOME"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then return; fi
  echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/load" prc
  rm -rf "$H"; mkdir -p "$H"

  # The centering block must not break T.1's standalone-load guarantee.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  chk_ok "probe: ls-fonts exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_fail "probe: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-grid-centering gate — repo: $REPO"

  case "${1:-}" in
    --static) stage_static ;;
    --math)   stage_math ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_math; stage_probe ;;
    *) echo "usage: bash tests/wezterm-grid-centering.sh [--static|--math|--probe]"; exit 2 ;;
  esac

  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-grid-centering gate: ALL PASS"; else echo "wezterm-grid-centering gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
