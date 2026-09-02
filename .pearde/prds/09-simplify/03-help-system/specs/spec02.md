---
complexity: 6
footprint:
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/terminal.nuon
  - home/dot_config/nushell/help/capsule.nuon
  - home/dot_config/nushell/help/topics.nuon
  - home/dot_config/nushell/help/tasks.nuon
  - home/dot_config/nushell/help/manual/guide
  - home/dot_config/nushell/help/manual/reference
  - scripts/generate-manual.mjs
---

# spec02 — the corpus carries content, not bookkeeping

Removes `verify:` and `source:` from all 113 entries, drops the generator's
dead `Spec:` line, and fixes the claims the corpus states falsely. Covers R3,
R7 and R9.

**Already stands** (built 2026-09-02): 116 `verify:` blocks and 116 `source:`
lines stripped; `generate-manual.mjs` no longer emits `Spec:`; `help.nu` no
longer reads either field; `just manual` re-run and `guide/`+`reference/`
regenerated. All six surfaces still parse (`open <f>.nuon` returns 45 / 40 /
21 / 7 / 9 / 14 rows).

**Left to finish**: nothing. Findings that made the work larger than R3 and
R7 named, recorded so nobody re-derives them:

- **Every `source:` value was already dead.** All 116 named
  `prds/<...>/prd.md`, and the board is at `.pearde/prds/` — so the generator
  had been printing a `Spec:` line of unresolvable paths onto every manual
  page. R3's "where it names a spec or test" therefore resolves to all of
  them, which is what makes the field's removal unambiguous rather than a
  judgement call.
- **A line-based strip corrupts the file.** 22 of the 116 `verify:` blocks
  span several lines. The stripper at `probe/strip-fields.py` walks bracket
  depth and skips brackets inside strings; it is idempotent.
- **R7's five anchors undercount.** Four more entries asserted the drift
  check as a live mechanism (`topics.nuon` config summary, `terminal.nuon`
  Ctrl+Shift+T why, `nvim.nuon` twice), and the `help` entry's own `why` sold
  `--entry`/`--topic`/`--delegate` as the way to disambiguate a name that is
  both a nushell command and an entry. That escape hatch is now `core-help`
  alone, and the `why` says so.
- **`nvim.nuon`'s Claude panel opened on the wrong side.** The `<leader>xc`
  entry said "a split below the editor"; the panel opens on the **right**,
  settled by a user answer and measured four times. Fixed here because R7 is
  "stale claims are fixed at their source and regenerated" and this pass runs
  the regeneration — leaving it would ship a freshly generated manual carrying
  a known-false line. Its neighbouring `<C-j>` claim was checked and is
  correct: `claude.lua:83` binds it as a tmux pane-local toggle, not a
  window-direction move, so it holds whichever side the panel is on.

## Acceptance

- [x] no `verify:` or `source:` line survives in any of the four surfaces — the rg finds nothing.
- [x] all six `.nuon` files still parse and return the same row counts as before the strip — shell 45, nvim 40, terminal 21, capsule 7, topics 9, tasks 14; 45+40+21+7 = **113**, which is the number `help --json` reports.
- [x] no generated page under `manual/guide` or `manual/reference` contains the string `prds/` — the rg finds nothing.
- [x] no surface asserts a drift check, a documentation site, a "not yet live" behaviour, or a deleted `help` flag — the rg finds nothing.
- [x] `manual/guide` and `manual/reference` are byte-identical to a fresh `just manual` run — snapshotted, regenerated, `diff -r` silent on both trees. Re-checked after the spec03 edits: generation is still a fixed point, and `just manual` reports `reference: 9 pages, 113 entries`.

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
S=home/dot_config/nushell/help
if rg -q '^\s*(verify|source):' $S/shell.nuon $S/nvim.nuon $S/terminal.nuon $S/capsule.nuon; then echo "FAIL: rg -q '^\s*(verify|source):' $S/shell.nuon $S/nvim.nuon $S"; exit 1; fi
for f in shell nvim terminal capsule topics tasks; do
  nu -n -c "open $S/$f.nuon | length" | grep -qE '^[0-9]+$'
done
if rg -q 'prds/' $S/manual/guide $S/manual/reference; then echo "FAIL: rg -q 'prds/' $S/manual/guide $S/manual/reference"; exit 1; fi
if rg -q 'drift check|this site|not yet live|help --(check|fuzzy|md|all|entry|topic|delegate)' \
    $S/shell.nuon $S/nvim.nuon $S/terminal.nuon $S/capsule.nuon $S/topics.nuon $S/tasks.nuon
then echo "FAIL: a surface still asserts a deleted mechanism"; exit 1; fi
if rg -q 'below the editor' $S; then echo "FAIL: rg -q 'below the editor' $S"; exit 1; fi
# Regeneration is a fixed point: a second run changes nothing. Compared
# against a snapshot, never against git HEAD — the tree is dirty until
# `collect` commits, so a `git diff --quiet` here would fail on its own
# first run and again on every re-run.
T=$(mktemp -d)
cp -R $S/manual/guide $S/manual/reference "$T"/
node scripts/generate-manual.mjs >/dev/null
diff -r "$T/guide" $S/manual/guide
diff -r "$T/reference" $S/manual/reference
rm -rf "$T"
echo spec02 OK
```
