#!/bin/bash
# Covers: the `L-*` live-config bugs of the 2026-08-20 audit — both halves.
#   1. the backlog table in
#      prds/00-delivery/corrections/prd.md — that every id L-1..L-12 is
#      present exactly once, that its Owner and Finding cells are non-empty,
#      that no id outside that range has been smuggled in, and that every
#      node and requirement an Owner cell names actually resolves; and
#   2. the bug itself, re-measured against the live config, for all twelve.
# Routing is checked because a bug nobody owns is a bug that comes back.
#
# A FAIL is not a broken build. It means one of three things, and the label
# says which:
#   - "table:"   -> the backlog table lost a row, an id, or a cell.
#   - "routing:" -> an Owner cell points at a node or requirement that is gone.
#   - a live-config check -> the live config changed under the record; the
#     inventory is now stale and the record must be re-measured.
#   - a "doc:" check -> the record was edited away or renamed.
# That is the whole point: this repo's original failure was specs drifting
# from the config they described, discovered only by a four-agent audit.
#
# Reads the live config and the chezmoi source read-only. Never writes
# anything, anywhere.
# Usage: bash tests/live-bugs.sh

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$REPO/docs"
BACKLOG="$REPO/prds/00-delivery/corrections/prd.md"
CORR="$REPO/prds/00-delivery/corrections"
LIVE="$HOME/.config"
# The chezmoi source. This is /Users/feb/dev/.files/home — what
# `chezmoi source-path` reports — and NOT ~/.local/share/chezmoi, which is
# a stale June clone, two months behind and a git ancestor of this tree.
# W0.4i established that no document may cite the clone as the source; the
# L-12/L-13 blocks below did exactly that until W0.8.
SRC="$HOME/dev/.files/home/dot_config"
rc=0
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

if [ ! -d "$LIVE/nushell" ]; then
  echo "FAIL  precondition: $LIVE/nushell is not present — nothing to check against"
  exit 1
fi

echo "── the source under test: the real one, not the stale clone ─────────"
# Two guards so $SRC can never quietly drift back to ~/.local/share/chezmoi.
# `chezmoi source-path` is read-only and mutates nothing — it is the only
# chezmoi call this file makes, and it fits the header's "reads the live
# config and the chezmoi source read-only". No init, no apply, no update, no
# HOME or PATH shim.
command -v chezmoi >/dev/null 2>&1
chk "source: chezmoi is installed, so source-path can be asked" $?
[ "$SRC" = "$(chezmoi source-path 2>/dev/null)/dot_config" ]
chk "source: \$SRC is the tree chezmoi source-path reports, not the stale clone" $?

# The row for one id, or empty. Rows live in the S2 live-bug table; no other
# table in the file uses an `L-` id.
row_of() { grep -E "^\| *$1 *\|" "$BACKLOG"; }
# Cell 2 (Owner) and cell 3..last-1 (Finding), whitespace-stripped, backticks
# dropped so paths can be matched as plain text.
cell() { awk -F'|' -v n="$2" '{
    if (n == 3) { s = $3 }
    else { s = ""; for (i = 4; i < NF; i++) s = s (i > 4 ? "|" : "") $i }
    gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/`/, "", s); print s
  }' <<<"$1"; }

echo "── the backlog table: every id, both cells ──────────────────────────"
for i in $(seq 1 12); do
  id="L-$i"
  cnt=$(grep -cE "^\| *$id *\|" "$BACKLOG")
  [ "$cnt" -eq 1 ]; chk "table: $id occurs exactly once as a row id (got $cnt)" $?
  [ "$cnt" -eq 1 ] || continue
  row=$(row_of "$id")
  owner=$(cell "$row" 3)
  finding=$(cell "$row" 4)
  [ -n "$owner" ];   chk "table: $id has a non-empty Owner cell" $?
  [ -n "$finding" ]; chk "table: $id has a non-empty Finding cell" $?
done
extra=$(grep -oE '^\| *L-[0-9]+' "$BACKLOG" | grep -oE 'L-[0-9]+' | sort -u \
        | grep -vxE 'L-([1-9]|1[0-2])' | tr '\n' ' ')
[ -z "$extra" ]; chk "table: no row id outside L-1..L-12 (unaccounted: ${extra:-none})" $?
q=$(grep -E '^\| *L-[0-9]+' "$BACKLOG" \
    | grep -cE 'Intentional\?|Port one or the other|Record it either way')
[ "$q" -eq 0 ]; chk "table: no row is still an open question addressed to the reader (got $q)" $?

echo "── the routing: every Owner cell resolves ───────────────────────────"
for i in $(seq 1 12); do
  id="L-$i"
  row=$(row_of "$id")
  [ -n "$row" ] || continue
  owner=$(cell "$row" 3)

  # Every `NN-epic/NN-node[/child]` path must be a real board node.
  for np in $(grep -oE '[0-9]{2}-[a-z0-9-]+/[0-9]{2}-[a-z0-9-]+(/[a-z0-9-]+)?' <<<"$owner"); do
    [ -f "$REPO/prds/$np/prd.md" ]; chk "routing: $id -> board node $np has a prd.md" $?
  done

  # Every `w0-4-s2-corrections/<child> R<n>` must be a real requirement that
  # names this same id — the reference is only useful if it lands on the line
  # that carries the bug.
  while read -r ref; do
    [ -n "$ref" ] || continue
    child=${ref#w0-4-s2-corrections/}; child=${child%% R*}
    rn=${ref##* R}
    cprd="$CORR/w0-4-s2-corrections/$child/prd.md"
    [ -f "$cprd" ]; chk "routing: $id -> w0-4-s2-corrections/$child/prd.md exists" $?
    [ -f "$cprd" ] || continue
    rline=$(grep -E "\*\*R$rn\*\*" "$cprd")
    [ -n "$rline" ]; chk "routing: $id -> $child carries an R$rn line" $?
    grep -qE "$id([^0-9]|$)" <<<"$rline"; chk "routing: $id -> $child R$rn names $id" $?
  done < <(grep -oE 'w0-4-s2-corrections/[a-z0-9-]+ R[0-9]+' <<<"$owner")

  # A row owned by nobody must say so, and must name an inventory that carries
  # the accepted-with-reason record instead.
  case "$owner" in
    none*)
      inv=$(grep -oE 'docs/capabilities-[a-z-]+\.md' <<<"$owner" | head -1)
      [ -n "$inv" ] && [ -f "$REPO/$inv" ]; chk "routing: $id owner is 'none' and names an existing inventory (${inv:-<none named>})" $?
      if [ -n "$inv" ] && [ -f "$REPO/$inv" ]; then
        grep -qE "$id([^0-9]|$)" "$REPO/$inv"; chk "routing: $inv carries the $id record" $?
      fi
      ;;
  esac
done
# L-11's owning node has not run yet (W0.2 is open and lists this node in its
# deps), so there is no requirement number to resolve — only the node
# directory and the inventory record, which is the second path to the bug.
[ -d "$CORR/w0-2-terminal-respec" ]; chk "routing: L-11 -> w0-2-terminal-respec exists (no R yet; W0.2 has not run)" $?

echo "── L-1  ls -D runs du -sb, which macOS du does not support ──────────"
grep -q '\^du -sb' "$LIVE/nushell/config.nu"; chk "config.nu still calls ^du -sb" $?
grep -E '\^du -sb' "$LIVE/nushell/config.nu" | grep -q 'e>'; chk "the call still discards stderr with e>, so the failure is silent" $?
if /usr/bin/du -sb "$REPO" >/dev/null 2>&1; then false; else true; fi
chk "/usr/bin/du -sb exits non-zero on this host — -b is unsupported (absolute path, so a GNU du on PATH cannot mask it)" $?

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
row_of L-6 | grep -q 'Decided 2026-08-21'; chk "table: the L-6 row carries the decision, not the question" $?

echo "── L-7  oil does not replace netrw for :e some/dir ──────────────────"
grep -rq 'oil' "$LIVE/nvim/lua/plugins/"; chk "an oil spec exists under plugins/" $?
grep -rq 'netrw' "$LIVE/nvim/lua/"; chk "netrw is disabled in the config" $?
grep -q 'Live bug L-7' "$DOCS/capabilities-nvim.md"; chk "doc: L-7 recorded" $?

echo "── L-8  two autocmds are ungrouped, so a reload stacks duplicates ───"
ungrouped() { # file, autocmd event — no `group =` in the option table
  local f="$1" ev="$2" ln
  ln=$(grep -n "nvim_create_autocmd(\"$ev\"" "$f" | head -1 | cut -d: -f1)
  [ -n "$ln" ] || return 2
  [ "$(sed -n "${ln},$((ln + 6))p" "$f" | grep -c 'group *=')" -eq 0 ]
}
ungrouped "$LIVE/nvim/lua/plugins/treesitter.lua" FileType
chk "treesitter.lua's FileType autocmd has no group = in its option table" $?
ungrouped "$LIVE/nvim/lua/config/keymaps.lua" ModeChanged
chk "keymaps.lua's shift-select ModeChanged autocmd has no group = either" $?
[ "$(grep -c 'group = augroup(' "$LIVE/nvim/lua/config/autocmds.lua")" -gt 0 ]
chk "control: config/autocmds.lua DOES group all of its autocmds — the grep finds a group when there is one" $?

echo "── L-9  <C-v> shadows blockwise-visual  [DECIDED: intentional] ──────"
grep -q 'map("v", "<C-v>"' "$LIVE/nvim/lua/config/keymaps.lua"; chk "<C-v> is bound in visual mode only, so normal mode is untouched" $?
grep -q 'map("v", "<C-c>"' "$LIVE/nvim/lua/config/keymaps.lua"; chk "<C-c> is bound alongside it — the pair is the reason to keep it" $?
[ "$(grep -r 'C-q' "$LIVE/nvim/lua/" | wc -l | tr -d ' ')" -eq 0 ]; chk "<C-q> is unbound, so blockwise-visual keeps its built-in synonym" $?
grep -q 'L-9, resolved' "$DOCS/capabilities-nvim.md"; chk "doc: the L-9 decision and its rejected alternative are recorded" $?
row_of L-9 | grep -q 'Decided 2026-08-21'; chk "table: the L-9 row carries the decision, not the question" $?

echo "── L-10  gitsigns delete/topdelete are empty strings ────────────────"
sign_text() { # the text= value of one gitsigns sign, or empty if absent
  grep -rhoE "(^|[[:space:]])$1 = \{ text = \"[^\"]*\"" "$LIVE/nvim/lua/plugins/" \
    | head -1 | sed -E 's/.*text = "([^"]*)"/\1/'
}
for s in delete topdelete add change; do
  grep -rqE "(^|[[:space:]])$s = \{ text = \"" "$LIVE/nvim/lua/plugins/"
  chk "gitsigns defines a $s sign" $?
done
d=$(sign_text delete); td=$(sign_text topdelete)
a=$(sign_text add);    c=$(sign_text change)
[ "${#d}"  -eq 0 ]; chk "delete's sign text is the empty string (${#d} bytes)" $?
[ "${#td}" -eq 0 ]; chk "topdelete's sign text is the empty string (${#td} bytes)" $?
[ "${#a}"  -gt 0 ]; chk "control: add carries a glyph (${#a} bytes), so an empty result means empty and not 'not found'" $?
[ "${#c}"  -gt 0 ]; chk "control: change carries a glyph (${#c} bytes)" $?

echo "── L-11  the F5 miss gives no feedback at all ───────────────────────"
grep -q 'audible_bell = "Disabled"' "$LIVE/wezterm/wezterm.lua"; chk "audible_bell is Disabled" $?
[ "$(grep 'visual_bell' "$LIVE/wezterm/wezterm.lua" | grep -vc '^ *--')" -eq 0 ]; chk "visual_bell appears only in a comment, never as a setting" $?
grep -q 'Live bug L-11' "$DOCS/capabilities-terminal.md"; chk "doc: L-11 recorded" $?

echo "── L-12  dead files in the chezmoi source  [five of six were phantoms of a stale clone] ───"
# The `[ -d "$SRC" ]` arm is a chk, not a silent `else echo SKIP` — a silent
# skip is how this block rotted: it measured the clone for two months and
# nothing said so. `control:` below is load-bearing: three of these assert
# ABSENCE, and a mistyped $SRC would pass all three for nothing.
[ -d "$SRC" ]; chk "L-12: the real chezmoi source is present at \$SRC" $?
[ -z "$(find "$SRC" -name 'solo-window.*')" ]
chk "L-12: no solo-window.* file is in the real source — five of six were phantoms" $?
[ "$(grep -c 'solo_window' "$SRC/wezterm/wezterm.lua")" -eq 0 ]
chk "L-12: the SOURCE wezterm.lua has zero solo_window references" $?
[ "$(grep -c 'solo-window' "$LIVE/wezterm/wezterm.lua")" -eq 0 ]
chk "L-12: the DEPLOYED wezterm.lua does not reference it either" $?
[ -z "$(find "$SRC" -name 'wsl-clip-prime.sh')" ]
chk "L-12: wsl-clip-prime.sh is in neither tree" $?
[ -f "$SRC/wezterm/background.png" ]
chk "L-12: control — background.png IS in the real source, so absent means absent" $?
grep -qF 'Live bug L-12 is corrected, not confirmed' "$DOCS/capabilities-provisioning.md"; chk "doc: the L-12 correction is recorded" $?

echo "── L-13  source vs deployed: the divergence was the clone, not the source ──"
# `cmp -s`, not a line-count comparison: the record's claim is byte-identity,
# and line counts are the weaker proxy that produced the original error.
for f in wezterm/wezterm.lua nushell/config.nu nushell/finder.nu nushell/theme.nu; do
  cmp -s "$SRC/$f" "$LIVE/$f"
  chk "L-13: $f is byte-identical, source vs deployed" $?
done
for f in dirstack.nu quicklist.nu overlay.nu opacity.nu; do
  [ -f "$SRC/nushell/$f" ]
  chk "L-13: $f IS in the real source — the 'only under ~/.config' reading was the clone" $?
done
[ ! -f "$SRC/nushell/leadermode.nu" ]
chk "L-13: leadermode.nu exists only under ~/.config, never entered the source" $?
grep -qF 'L-13 is corrected too' "$DOCS/capabilities-provisioning.md"; chk "doc: L-13 recorded" $?

echo "── goalposts: what moved, and proof it moved rather than vanished ───"
# R3: a repaired gate must be a MOVED goalpost, not a deleted one. The
# excerpt below is verbatim pre-correction record — `git show
# HEAD:.mi/docs/capabilities-provisioning.md` lines 82-86, 93-94 and 96-102,
# two elisions marked […] — carried inline rather than read from git, because
# HEAD stops being the pre-correction text the moment W0.4i's rewrite is
# committed, and because this file's header promises it only reads the live
# config.
#
# HONEST LIMIT, stated rather than oversold: the last three assertions prove
# the re-expressed live checks contradict the OLD RECORD. They do not re-run
# those checks against the stale clone tree — deliberately: no assertion in
# this file may measure ~/.local/share/chezmoi, and reading it would make the
# gate depend on a tree that ought to be deleted. What carries the rest of
# the weight for R2b is the `source: $SRC is the tree chezmoi source-path
# reports` guard above — the goalpost cannot move back.
PRE_CORRECTION="$(cat <<'PRE'
- **Live bug L-12, corrected and do not reproduce:** the source tree ships
  `solo-window.{applescript,sh,ps1,vbs}`. The audit called them unreferenced;
  measured, that is only half right — the *deployed*
  `~/.config/wezterm/wezterm.lua` never mentions solo-window, but the
  *source* `home/dot_config/wezterm/wezterm.lua` defines `solo_window()` and
  […]
- **New finding (L-13), the ground the corrections epic stands on:** the
  chezmoi source and `~/.config` have diverged, in both directions, and
  […]
  inventory in this repo was written from. Measured 2026-08-20, source vs
  deployed line counts: `wezterm/wezterm.lua` 339 vs 1149 · `nushell/config.nu`
  380 vs 715 · `nushell/finder.nu` 345 vs 221 (the source one is a different,
  stack-and-resume design) · `television/config.toml` 16 vs 15 ·
  `nvim/lua/config/keymaps.lua` identical. `leadermode.nu`, `dirstack.nu`,
  `quicklist.nu`, `overlay.nu` and `opacity.nu` exist only under `~/.config`
  and are not in the source at all. So "chezmoi-managed", written at the head
PRE
)"
# Fixture-is-real, FIRST. Without these, an empty string would "prove"
# everything below — gates/selftest.sh's "a claimed mutation is not a made one".
grep -qF 'Live bug L-12, corrected' <<<"$PRE_CORRECTION"
chk "goalpost: the excerpt is genuinely the pre-correction text (old L-12 wording present)" $?
grep -qF 'New finding (L-13)' <<<"$PRE_CORRECTION"
chk "goalpost: the excerpt is genuinely the pre-correction text (old L-13 wording present)" $?
# The repointed doc greps are red against the old record.
! grep -qF 'Live bug L-12 is corrected, not confirmed' <<<"$PRE_CORRECTION"
chk "goalpost: the new L-12 pattern does NOT match the pre-correction text" $?
! grep -qF 'L-13 is corrected too' <<<"$PRE_CORRECTION"
chk "goalpost: the new L-13 pattern does NOT match the pre-correction text" $?
# The re-expressed live checks are red against the old reading, read out of
# the old record itself rather than hand-typed.
grep -qF 'the source tree ships' <<<"$PRE_CORRECTION"
chk "goalpost: the old record says the source SHIPS solo-window.* — the re-expressed L-12 absence check is red there" $?
grep -qF '339 vs 1149' <<<"$PRE_CORRECTION"
chk "goalpost: the old record says 339 vs 1149 — the byte-identity check is red there" $?
grep -qF 'and are not in the source at all' <<<"$PRE_CORRECTION"
chk "goalpost: the old record says those five files are not in the source — the re-expressed L-13 presence check is red there" $?

echo
if [ "$rc" -eq 0 ]; then echo "OK — every live-bug record still matches the config it describes, and every row is owned"
else echo "STALE — a check above no longer holds; re-measure before trusting the inventory"; fi
exit $rc
