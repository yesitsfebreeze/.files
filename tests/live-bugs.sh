#!/bin/bash
# Covers: the live-config bug records in .mi/docs/capabilities-*.md — the
# `L-*` findings of the 2026-08-20 audit, as routed by
# .mi/prd/00-delivery/corrections/w0-6-live-bugs.
#
# Each record in those inventories says "the live config does X, do not
# reproduce it". This re-checks every one of those claims against the live
# config itself, and checks that the record is still in the document.
#
# A FAIL is not a broken build. It means one of two things, and the label says
# which half failed:
#   - a live-config check failed  -> the live config changed under the record;
#     the inventory is now stale and the record must be re-measured.
#   - a doc check failed          -> the record was edited away or renamed.
# That is the whole point: this repo's original failure was specs drifting
# from the config they described, discovered only by a four-agent audit.
#
# Reads the live config read-only. Never writes anything.
# Usage: bash tests/live-bugs.sh

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$REPO/.mi/docs"
LIVE="$HOME/.config"
SRC="$HOME/.local/share/chezmoi/home/dot_config"
rc=0
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

if [ ! -d "$LIVE/nushell" ]; then
  echo "FAIL  precondition: $LIVE/nushell is not present — nothing to check against"
  exit 1
fi

echo "── the backlog table ────────────────────────────────────────────────"
n=$(grep -cE '^\| *L-[0-9]+' "$REPO/.mi/prd/00-delivery/corrections/prd.md")
[ "$n" = 12 ]; chk "backlog holds 12 L-rows (got $n)" $?

echo "── L-2  git-log commit decode is dead ───────────────────────────────"
grep -q 'output = "{strip_ansi|split: :1}"' "$LIVE/television/cable/git-log.toml"; chk "git-log.toml already splits the hash out, so tv emits a bare hash" $?
grep -q 'hash: ($fields | get -o 1' "$LIVE/nushell/finder.nu"; chk "the decoder then reads index 1 of that bare hash, which is empty" $?
grep -q 'Live bug L-2' "$DOCS/capabilities-nushell.md"; chk "doc: L-2 recorded" $?

echo "── L-3  the channel is recent-dirs, the decoder types rcwd ──────────"
[ -f "$LIVE/television/cable/recent-dirs.toml" ]; chk "recent-dirs.toml exists" $?
[ ! -f "$LIVE/television/cable/rcwd.toml" ]; chk "no rcwd cable file exists" $?
grep -q '"files" | "dirs" | "rcwd" => "FileList"' "$LIVE/nushell/finder.nu"; chk "_finder_type still types the name no channel has" $?
[ "$(grep -c 'feeds the `rcwd`' "$DOCS/capabilities-nushell.md")" -eq 0 ]; chk "doc: the inventory no longer calls rcwd a channel" $?
grep -q 'Live bug L-3' "$DOCS/capabilities-nushell.md"; chk "doc: L-3 recorded" $?

echo "── L-4  finder picks never reach the quicklist ──────────────────────"
[ "$(grep -c '_recents_add "' "$LIVE/nushell/config.nu")" -gt 0 ]; chk "config.nu calls _recents_add" $?
[ "$(grep -c '_recents_add "' "$LIVE/nushell/finder.nu")" -eq 0 ]; chk "finder.nu, which defines it, never calls it" $?
[ "$(grep -o '_recents_add "[A-Za-z]*" [^ ]* "[a-z]*"' "$LIVE/nushell/config.nu" | grep -cv '"zoxide"')" -eq 0 ]; chk "every logged entry is tagged channel zoxide, so ctrl-r replay is moot" $?
grep -q 'Live bug L-4' "$DOCS/capabilities-nushell.md"; chk "doc: L-4 recorded" $?

echo "── L-5  leadermode.nu is dead code ──────────────────────────────────"
[ "$(grep -c 'source .*leadermode' "$LIVE/nushell/config.nu")" -eq 0 ]; chk "config.nu never sources leadermode.nu" $?
grep -q 'finder --resume' "$LIVE/nushell/leadermode.nu"; chk "leadermode calls finder --resume" $?
[ "$(grep -c '\-\-resume' "$LIVE/nushell/finder.nu")" -eq 0 ]; chk "the DEPLOYED finder defines no --resume flag" $?
grep -q 'Dead code, not live behaviour (L-5)' "$DOCS/capabilities-nushell.md"; chk "doc: L-5 recorded as dead code, not as live behaviour" $?

echo "── L-6  <Esc> -> nohlsearch is inert  [DECIDED: keep hlsearch=false] ─"
grep -q 'map("n", "<Esc>", "<cmd>nohlsearch<CR>"' "$LIVE/nvim/lua/config/keymaps.lua"; chk "the map exists" $?
grep -q 'opt.hlsearch = false' "$LIVE/nvim/lua/config/options.lua"; chk "hlsearch is false, so it can never do anything" $?
grep -q 'Live bug L-6, resolved' "$DOCS/capabilities-nvim.md"; chk "doc: the L-6 decision and its rejected alternative are recorded" $?

echo "── L-7  oil does not replace netrw for :e some/dir ──────────────────"
grep -rq 'oil' "$LIVE/nvim/lua/plugins/"; chk "an oil spec exists under plugins/" $?
grep -rq 'netrw' "$LIVE/nvim/lua/"; chk "netrw is disabled in the config" $?
grep -q 'Live bug L-7' "$DOCS/capabilities-nvim.md"; chk "doc: L-7 recorded" $?

echo "── L-9  <C-v> shadows blockwise-visual  [DECIDED: intentional] ──────"
grep -q 'map("v", "<C-v>"' "$LIVE/nvim/lua/config/keymaps.lua"; chk "<C-v> is bound in visual mode only, so normal mode is untouched" $?
grep -q 'map("v", "<C-c>"' "$LIVE/nvim/lua/config/keymaps.lua"; chk "<C-c> is bound alongside it — the pair is the reason to keep it" $?
[ "$(grep -r 'C-q' "$LIVE/nvim/lua/" | wc -l | tr -d ' ')" -eq 0 ]; chk "<C-q> is unbound, so blockwise-visual keeps its built-in synonym" $?
grep -q 'L-9, resolved' "$DOCS/capabilities-nvim.md"; chk "doc: the L-9 decision and its rejected alternative are recorded" $?

echo "── L-11  the F5 miss gives no feedback at all ───────────────────────"
grep -q 'audible_bell = "Disabled"' "$LIVE/wezterm/wezterm.lua"; chk "audible_bell is Disabled" $?
[ "$(grep 'visual_bell' "$LIVE/wezterm/wezterm.lua" | grep -vc '^ *--')" -eq 0 ]; chk "visual_bell appears only in a comment, never as a setting" $?
grep -q 'Live bug L-11' "$DOCS/capabilities-terminal.md"; chk "doc: L-11 recorded" $?

echo "── L-12  dead files in the chezmoi source  [half of it was stale] ───"
if [ -d "$SRC" ]; then
  [ -f "$SRC/wezterm/solo-window.sh" ]; chk "solo-window.sh is in the chezmoi source" $?
  grep -q 'solo_window' "$SRC/wezterm/wezterm.lua"; chk "the SOURCE wezterm.lua does reference it — the audit said nothing does" $?
  [ "$(grep -c 'solo-window' "$LIVE/wezterm/wezterm.lua")" -eq 0 ]; chk "the DEPLOYED wezterm.lua does not reference it" $?
  [ -z "$(find "$SRC" -name 'wsl-clip-prime.sh')" ]; chk "wsl-clip-prime.sh is not in the source at all — that half of L-12 is stale" $?
else
  echo "SKIP  L-12: no chezmoi source at $SRC"
fi
grep -q 'Live bug L-12, corrected' "$DOCS/capabilities-provisioning.md"; chk "doc: the L-12 correction is recorded" $?

echo "── L-13  the chezmoi source and ~/.config have diverged ─────────────"
if [ -d "$SRC" ]; then
  [ "$(wc -l < "$SRC/wezterm/wezterm.lua")" -lt "$(wc -l < "$LIVE/wezterm/wezterm.lua")" ]; chk "source wezterm.lua is far shorter than the deployed one" $?
  [ "$(wc -l < "$SRC/nushell/finder.nu")" -gt "$(wc -l < "$LIVE/nushell/finder.nu")" ]; chk "source finder.nu is LONGER — the drift runs both directions" $?
  for f in dirstack.nu quicklist.nu overlay.nu opacity.nu leadermode.nu; do
    [ ! -f "$SRC/nushell/$f" ]; chk "$f exists only under ~/.config, never entered the source" $?
  done
else
  echo "SKIP  L-13: no chezmoi source at $SRC"
fi
grep -q 'New finding (L-13)' "$DOCS/capabilities-provisioning.md"; chk "doc: L-13 recorded" $?

echo
if [ "$rc" -eq 0 ]; then echo "OK — every live-bug record still matches the config it describes"
else echo "STALE — a record above no longer matches; re-measure before trusting the inventory"; fi
exit $rc
