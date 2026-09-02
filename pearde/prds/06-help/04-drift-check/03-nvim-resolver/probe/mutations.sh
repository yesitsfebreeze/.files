#!/usr/bin/env bash
# 03-nvim-resolver — the mutations that prove the nvim half of the resolver can
# FAIL, one per behaviour it claims. Each is applied to a staged machine,
# measured against an EXPECTED finding, and reverted. A mutation whose result
# does not match its expectation exits non-zero, so this script is an
# assertion and not a printout.
#   usage: mutations.sh <machine-dir>
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M="${1:?machine dir}"
KM="$M/home/.config/nvim/lua/config/keymaps.lua"
CORPUS="$M/home/.config/nushell/help/nvim.nuon"
rc=0
report='let r = (_help_check --json); $r.findings | where surface == "nvim" and class in ["stale" "mismatched"] | each {|f| $"($f.class) ($f.id) — ($f.detail)"} | str join (char nl)'

# expect <label> <grep-pattern-or-EMPTY>
expect() {
  local label="$1" want="$2" out
  out="$(bash "$HERE/nu-c.sh" "$M" "$report" 2>&1)"
  if [ "$want" = "EMPTY" ]; then
    if [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then
      echo "PASS  $label — no nvim finding, as required"
    else
      echo "FAIL  $label — expected NO finding, got: $out"; rc=1
    fi
  elif printf '%s\n' "$out" | grep -qF "$want"; then
    echo "PASS  $label — $(printf '%s\n' "$out" | grep -F "$want" | head -1)"
  else
    echo "FAIL  $label — expected a finding matching '$want', got: ${out:-<nothing>}"; rc=1
  fi
}

cp "$KM" "$KM.bak"; cp "$CORPUS" "$CORPUS.bak"
restore() { cp "$KM.bak" "$KM"; cp "$CORPUS.bak" "$CORPUS"; }

expect "M0 baseline, no mutation" EMPTY

# M1 — an explicit `desc` that no longer matches the live map.
perl -i -pe 's/desc = "Save"/desc = "Write the file"/' "$KM"
expect "M1 explicit desc drifts" "mismatched"; restore

# M2 — the map itself is gone.
perl -i -ne 'print unless /"<leader>w", "<cmd>write<CR>"/' "$KM"
expect "M2 the documented map is deleted" "stale"; restore

# M3 — `desc` ABSENT from the corpus target: the entry's TITLE is what must
# match. No corpus target is in this state today (absent 0), so without this
# mutation the branch is unexercised.
perl -i -pe 's/lhs: "<C-l>", desc: "Go to right window"/lhs: "<C-l>"/' "$CORPUS"
expect "M3 desc absent -> compared against the title" "vs manual 'Move between windows'"; restore

# M4 — `desc: null` asserts existence only, so a drifted live desc is silence.
perl -i -pe 's/lhs: "<leader>w", desc: "Save"/lhs: "<leader>w", desc: null/' "$CORPUS"
perl -i -pe 's/desc = "Save"/desc = "Write the file"/' "$KM"
expect "M4 desc null + drifted live desc" EMPTY; restore

rm -f "$KM.bak" "$CORPUS.bak"
exit "$rc"
