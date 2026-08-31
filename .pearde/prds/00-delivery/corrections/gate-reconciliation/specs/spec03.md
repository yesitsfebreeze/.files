# spec03 — R2b: repoint `SRC` at the real source and re-express the L-12/L-13 live checks

Covers **R2b**. Est 45m. The largest piece of the ticket.

## Goal

`tests/live-bugs.sh:31` sets

    SRC="$HOME/.local/share/chezmoi/home/dot_config"

which is the **stale June clone** — two months behind, HEAD `a2544e4`, a git
ancestor of the live source's `8e99f58` — that W0.4i forbade citing as the
chezmoi source ever again. The real source is `/Users/feb/dev/.files/home`,
which is what `chezmoi source-path` reports.

Every L-12/L-13 *live* assertion therefore measures the wrong tree. They are
green today only because of that, and most of them assert the **opposite** of
the corrected record. Repoint `SRC` and re-express the block against it.

### Count correction

The PRD's R2b says "nine" live assertions. The measured count is **eleven** —
4 under L-12 (lines 199-202) and 7 under L-13 (lines 210-216); the two `doc:`
greps in those sections belong to spec02. The "seven contradictions" figure in
R2b is correct. Recording the discrepancy rather than quietly working around
it, since this ticket is about not asserting what was not checked.

### What is actually true, measured 2026-08-21

| current assertion | vs the clone | vs the real source |
|---|---|---|
| `solo-window.sh is in the chezmoi source` | PASS | **false** — no `solo-window.*` at all |
| `the SOURCE wezterm.lua does reference it` | PASS | **false** — 0 refs (the clone has 3) |
| `the DEPLOYED wezterm.lua does not reference it` | PASS | holds |
| `wsl-clip-prime.sh is not in the source at all` | PASS | holds |
| `source wezterm.lua is far shorter than the deployed one` | PASS | **false** — 1149 vs 1149, `cmp`-identical |
| `source finder.nu is LONGER` | PASS | **false** — 221 vs 221, `cmp`-identical |
| `dirstack/quicklist/overlay/opacity.nu never entered the source` | PASS x4 | **false x4** — all four are in the real source |
| `leadermode.nu never entered the source` | PASS | holds |

`wezterm.lua`, `config.nu`, `finder.nu` and `theme.nu` are all `cmp -s`
identical between `/Users/feb/dev/.files/home/dot_config` and `~/.config`.

## Files touched

- `tests/live-bugs.sh` — the `SRC` definition (line 31), the L-12 live block
  (lines 197-205) and the L-13 live block (lines 208-217).

**R4 boundary.** Do not add, remove or reword one assertion in the
backlog-table or Owner-cell routing machinery (lines ~44-130). Its current
shape is **40** `table:` assertions and **50** `routing:` assertions, 146
total in the file; those two numbers must be identical afterwards.

## Design, every predicate already run green against the real source

Repoint, keeping the file's `$HOME`-relative style:

    # The chezmoi source. This is /Users/feb/dev/.files/home — what
    # `chezmoi source-path` reports — and NOT ~/.local/share/chezmoi, which is
    # a stale June clone, two months behind and a git ancestor of this tree.
    # W0.4i established that no document may cite the clone as the source; the
    # L-12/L-13 blocks below did exactly that until W0.8.
    SRC="$HOME/dev/.files/home/dot_config"

Two new guards, so it can never quietly drift back and so a mistyped path
cannot make the "absent" assertions pass vacuously:

    command -v chezmoi >/dev/null 2>&1
    chk "source: chezmoi is installed, so source-path can be asked" $?
    [ "$SRC" = "$(chezmoi source-path 2>/dev/null)/dot_config" ]
    chk "source: \$SRC is the tree chezmoi source-path reports, not the stale clone" $?

`chezmoi source-path` is read-only and mutates nothing — it is the only
chezmoi call this file may make, and it fits the header's "reads the live
config and the chezmoi source read-only, never writes anything, anywhere".
No `init`, no `apply`, no `update`, no `HOME` or `PATH` shim.

The L-12 block becomes six assertions. The `else echo "SKIP"` arm is replaced
by a real `chk` — a silent skip is how this rotted in the first place:

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

The control is load-bearing. Three of these assert **absence**; if `$SRC` were
mistyped to an existing-but-wrong directory they would all pass for nothing.
`background.png` is L-12's one real file — the record keeps it, dropped by
decision 5(a) with the wallpaper pipeline — so it is the natural positive
control. Same idiom as the existing L-10 block's `control: add carries a
glyph, so an empty result means empty and not 'not found'`.

The L-13 block becomes nine assertions:

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

`cmp -s` rather than a line-count comparison: the record's claim is
byte-identity, and line counts are the weaker proxy that produced the original
error. All fifteen predicates plus both guards were run green against the real
source on 2026-08-21 before this spec was written.

Update the two section banners so a reader is not told the old story:
`── L-12  dead files in the chezmoi source  [half of it was stale] ───`
becomes `[five of six were phantoms of a stale clone]`, and
`── L-13  the chezmoi source and ~/.config have diverged ───` becomes
`── L-13  source vs deployed: the divergence was the clone, not the source ──`.

## Boxes

- [x] `SRC` is `$HOME/dev/.files/home/dot_config`, with the comment saying
      why the clone is not it.
- [x] `source: chezmoi is installed…` PASSes.
- [x] `source: $SRC is the tree chezmoi source-path reports, not the stale
      clone` PASSes.
- [x] Six `L-12:` assertions PASS, including the `control` one.
- [x] Nine `L-13:` assertions PASS.
- [x] Neither block can `SKIP` silently any more — the `[ -d "$SRC" ]` arm is
      a `chk`, not an `else echo SKIP`.
- [x] No non-comment line in `tests/live-bugs.sh` mentions
      `local/share/chezmoi`. Comments may, and should, explain what moved.
- [x] `table:` assertions still number 40 and `routing:` still 50 — R4.
- [x] `bash tests/live-bugs.sh` exits 0.
- [x] The file still writes nothing, anywhere, and makes no chezmoi call
      other than `source-path`.

## Verify

    bash tests/live-bugs.sh > /tmp/w08-s3.log 2>&1 && \
      [ "$(grep -v '^[[:space:]]*#' tests/live-bugs.sh | grep -c 'local/share/chezmoi')" -eq 0 ] && \
      [ "$(grep -cE '^PASS  L-12: ' /tmp/w08-s3.log)" -eq 6 ] && \
      [ "$(grep -cE '^PASS  L-13: ' /tmp/w08-s3.log)" -eq 9 ] && \
      [ "$(grep -cE '^PASS  source: ' /tmp/w08-s3.log)" -eq 2 ] && \
      [ "$(grep -cE '^(PASS|FAIL)  table: ' /tmp/w08-s3.log)" -eq 40 ] && \
      [ "$(grep -cE '^(PASS|FAIL)  routing: ' /tmp/w08-s3.log)" -eq 50 ]

**Proved RED 2026-08-21** before speccing: exit 1, non-comment clone
references 1 (want 0), `L-12:` labels 0 of 6, `L-13:` 0 of 9, `source:` 0
of 2.

R2b's "proved to fail against the clone reading" half is spec04, which does it
without reading the clone.
