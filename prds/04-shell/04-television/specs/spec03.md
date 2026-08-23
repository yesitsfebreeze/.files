# spec03 — wiring: config.nu entry points, keybindings, gate staging, manual

Wire finder.nu into the shell: the MODULES source line, the two entry-point
defs (`tv_finder`, `tv_remote`), the three keybinding records, the staging
`cp` line in all six shell gates, and the manual reconciliation. Everything
in this spec that touches `config.nu` is **serial-after-C.2** — the C.2 lane
holds that file; do not start this spec while C.2 is in flight.

**Est:** 1.5h

**Footprint:** `home/dot_config/nushell/config.nu` (serial-after-C.2),
`tests/nushell-core.sh`, `tests/nushell-aliases.sh`,
`tests/shell-listing.sh`, `tests/shell-claude.sh`, `tests/shell-zoxide.sh`,
`tests/shell-history.sh`, `home/dot_config/nushell/help/shell.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`

## config.nu

**MODULES** — add `source ~/.config/nushell/finder.nu` and update the anchor
comment (finder.nu is no longer "still to come"; quicklist.nu still is).
The module and its line land in one change: a `source` of a missing file is
a parse error that discards the whole of `config.nu` — the definitions
above the failing line as well as those below. Interactively the shell
still reaches a prompt, so the result is a working but naked REPL; `nu -c`
prints the error, never runs the command, and exits 1. The GENERATED anchor
in `config.nu` carries the measurement.

**Entry points** — a commented section directly AFTER the THEME anchor's
`source ~/.config/nushell/theme.nu` line and BEFORE the KEYBINDINGS anchor.
They live in config.nu, not finder.nu, for a parse-order reason the comment
states: nushell binds a def body's calls at parse time, and `tv_remote`
dispatches to `theme` (defined at THEME) — and, when 04-shell/07 lands, to
`quicklist`. A def in finder.nu (sourced at MODULES, earlier) could bind
neither. This is the live config's own layout. No new `# ── … ──` anchor
line: the six gates grep the ten-anchor set and this section is content
between anchors, not an eleventh.

- `tv_finder` (R4, Ctrl-T): run `finder` (channel remote first — same first
  step as Ctrl-Space, the manual already says so); empty/aborted pick
  leaves the line untouched; insert the selection at the cursor with
  `commandline edit --insert`, each item reduced to its payload (`file`,
  `hash` or `sheet` field for records, the string otherwise) and quoted
  through `_finder_shquote`, joined by spaces.
- `tv_remote` (`--env`, R4, Ctrl-Space / F1): guard `$nu.is-interactive`;
  `_finder_pick_channel`; empty → return. Dispatch match:
  - `theme` → `theme` (the S.9 command runs its own tv screen and applies
    after exit; a scheme id through the generic chain would be handed to
    `_finder_open` as a path).
  - seam comment for 04-shell/07: `quicklist` dispatches to its own runner
    here — the arm lands with quicklist.nu, sourced above this section.
    Until then the channel does not exist, so the arm has nothing to miss.
  - anything else → `_finder_open (finder --start $channel)`.
  - the opacity picker is NOT dispatched and not special-cased — the
    wallpaper-opacity decision (2026-08-21) put it out of the minimal base;
    its cable is not shipped (spec01).

**KEYBINDINGS** — append three records after the existing ones (esc_clear
and S.6's six stay untouched; the S.6 gate asserts its six sit after
esc_clear, so append, never interleave):

| name | modifier | keycode | cmd |
|---|---|---|---|
| `tv_remote` | control | space | `tv_remote` |
| `tv_remote_f1` | none | f1 | `tv_remote` |
| `finder_pick` | control | char_t | `tv_finder` |

All three `mode: [vi_normal vi_insert emacs]`. The anchor sits after
GENERATED, so `finder_pick` beats the Ctrl-T (`tv_smart_autocomplete`) the
generated television init binds — same last-entry-wins mechanism S.6's R5
proved. The comment names it. F1 does not collide with `files.toml`'s
`shortcut = "f1"`: that shortcut fires only inside a running tv session.

## Gate staging (the pass.nu precedent, seventh repetition)

config.nu now sources finder.nu, so every hermetic scratch HOME that stages
config.nu must stage finder.nu beside it or die at parse. Add one `cp` line
to the staging block of each of the six gates (`tests/nushell-core.sh`,
`nushell-aliases.sh`, `shell-listing.sh`, `shell-claude.sh`,
`shell-zoxide.sh`, `shell-history.sh`), matching each gate's local style,
then run all six and quote the green summaries.

## Manual reconciliation (help/shell.nuon)

The H.1 corpus already carries the surface's entries (`Ctrl-Space / F1`,
`Ctrl-T`, `Ctrl-Q`, `finder`, `tv channel`) with verify names matching the
three records above. Two entries are stale against this node's contract:

- `finder`'s `use` says git-log returns `{hash, subject}` records — R2(b)
  drops `subject`; the shape is `{hash}`. Rewrite that clause.
- `tv channel`'s `why` names a curated set smaller than R5's (it omits
  `recent-files`, `alias`, the `cht` → `cht-query` pair, `channels`,
  `nu-history`, `theme`). Reconcile the list with R5.

Each rewrite stales its digest-keyed review row: re-record the `use-review`
/ `why-review` rows per the ritual in the files' headers, with a reviewer
who did not write the new text (`reviewer` ≠ `author` is gated). Run
`nu tests/help-content-model.nu` to green. The `Ctrl-Q` entry is
04-shell/07's surface — leave it.

## Out of this spec, flagged for the orchestrator

`gates/waves.tsv` wave-4 gates cell needs
`external bash tests/shell-television.sh` (spec04's gate) — the file is in
the C.2 lane's footprint, so the orchestrator schedules that one-cell edit;
this node does not write it.

## Acceptance

- [x] `config.nu` sources finder.nu at MODULES; `tv_finder` and `tv_remote`
      are defined between the theme.nu source line and the KEYBINDINGS
      anchor; the ten anchors still grep in order.
      `PASS  tree: 'source ~/.config/nushell/finder.nu' sits once under
      MODULES, after capsule.nu, before PALETTE (line 550)`,
      `PASS  tree: tv_finder and tv_remote are defined once each, after the
      theme.nu source line, before KEYBINDINGS`, and
      `PASS  tree: all ten S.1 anchors present once each and in order (own
      grep)`, with both executed counterfactuals green
      (`counterfactual source-line-above-MODULES FAILS the ordering check`,
      `counterfactual tv_remote-above-theme-source FAILS the ordering
      check`).
- [x] The three records are appended at KEYBINDINGS; a pty session pressing
      Ctrl-T reaches `tv_finder`, not the generated init's
      `tv_smart_autocomplete` (counterfactual: deleting the three records
      hands Ctrl-T back to the tv init — executed, not asserted).
      `PASS  tree: the three records sit after esc_clear and after S.6's six,
      in order, once each, with executehostcommand cmds`;
      `PASS  hermetic: …via the channel remote first (argv line 1 is
      list-channels: tv list-channels)`; and the counterfactual really
      executed —
      `PASS  hermetic: with the records deleted, Ctrl-T reaches tv's OWN
      binding — argv shows --autocomplete-prompt, not list-channels (got: tv
      --no-status-bar --inline --autocomplete-prompt ec)`.
- [x] Ctrl-T on a stub pick containing spaces inserts it single-quoted at
      the cursor; esc leaves the commandline byte-identical.
      `PASS  hermetic: Ctrl-T inserts the pick at the cursor, single-quoted —
      the double space survives execution only if quoted` and
      `PASS  hermetic: an aborted pick leaves the line untouched — the
      pre-typed command still runs bare`. This is one of the three FAILs the
      node's history recorded; the defect was in the gate's own `tv` stub, not
      in `tv_finder` — see the Failure section of `../prd.md`.
- [x] A `tv_remote` dirs pick cds the shell (pty, scratch HOME) and the PWD
      hook auto-lists.
      `PASS  hermetic: an F1 dirs pick moved PWD to the picked directory (print
      $env.PWD line present)` and
      `PASS  hermetic: …and the PWD hook auto-listed it (REMOTE-CANARY row
      painted: 1)`. These are the other two recorded FAILs, same stub cause.
- [x] All six sibling gates pass after the staging edits, each quoted with
      its PASS count and EXIT=0. Run 2026-08-23:
      `nushell-core: EXIT=0 PASS=212 FAIL=0`,
      `nushell-aliases: EXIT=0 PASS=39 FAIL=0`,
      `shell-listing: EXIT=0 PASS=36 FAIL=0`,
      `shell-claude: EXIT=0 PASS=51 FAIL=0`,
      `shell-zoxide: EXIT=0 PASS=106 FAIL=0`,
      `shell-history: EXIT=0 PASS=68 FAIL=0`.
      The staging `cp` lines were already in place on disk when this retry
      audited it; `bash gates/nushell-module-staging.sh` — the drift gate that
      holds every scratch HOME to config.nu's source list — is also green
      (`EXIT=0 PASS=40 FAIL=0`).
- [~] `nu tests/help-content-model.nu` exits 0; `shell.nuon`'s `finder`
      entry says `{hash}`; no review row has `reviewer` == `author`.
      Two of the three halves are proven in-tree; the first is proven only
      against a scratch copy, so this stays `[~]`.
      - `shell.nuon`'s `finder` `use` now says `{hash}` records from
        `git-log`, and `tv channel`'s `why` names all sixteen channels R5
        keeps. Both rewrites were read by `implementer-television-r1`, a
        reader that wrote none of the text; the three stale rows are
        re-recorded (`why-review` `finder` → `9d72b7b3d76f539d`,
        `why-review` `tv channel` → `a697fd046b255e85`, `use-review`
        `finder` → `ac1178884a3a68d9`), each with
        `reviewer: implementer-television-r1` and
        `author: implementer-television`. The gate reports no
        `reviewer == author` row and no stale digest for either entry.
      - **In-tree the gate exits 1**, on one violation that is not this
        node's and that pre-dated this session's first command:
        `nvim.nuon [<leader>t]: use/why changed since the recorded review …
        set digest to e70cd08965d13ba7`. `nvim.nuon` is 03-editor's file,
        modified and uncommitted by a concurrent lane; touching it is out of
        bounds. Proof that nothing else is red: with that ONE foreign digest
        stamped in a scratch copy of the help dir and nothing else changed,
        `nu tests/help-content-model.nu <copy>` prints `ok` and exits 0.

## Verify

```sh
bash tests/nushell-core.sh && bash tests/nushell-aliases.sh \
  && bash tests/shell-listing.sh && bash tests/shell-claude.sh \
  && bash tests/shell-zoxide.sh && bash tests/shell-history.sh
nu tests/help-content-model.nu
bash tests/shell-television.sh   # spec04
```
