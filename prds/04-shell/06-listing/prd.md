---
state: done
claim:
priority: 31
est: 3h
task: S.3
mode: afk
needs:
  - 04-shell/02-aliases-utilities
  - 00-delivery/corrections/w0-4-s2-corrections
  - 06-help/01-content-model
verify: "bash tests/shell-listing.sh"
---

# Decorated ls + auto-list

Parent: [Nushell epic](../prd.md) · C 5 · U 8 · source: "Decorated ls +
auto-list on cd" in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: Nushell's structured `ls`, upgraded: icons, useful ordering, opt-in
real directory sizes — and shown automatically after every navigation.

## Requirements
- [x] **R1** — **Shadowed `ls`.** Builtin captured as `core-ls` before
      shadowing (alias targets bind at parse time). Wrapper redeclares the
      builtin's flags explicitly and defaults the pattern to `.`.
      *(tests/shell-listing.sh T1 order check + counterfactual; H1/H6.)*
- [x] **R2** — **Decoration.** Sort `type, modified` (dirs grouped, newest
      last, freshest nearest the prompt); prepend an `icon` column from an
      extension→glyph map with dir/generic fallbacks.
      *(H1 `icon,name,type,size,modified`; H2 sorted fixture order. The map
      is carried byte-verbatim from the live config — whose glyph strings
      are measurably EMPTY, see History.)*
- [x] **R3** — **`-D` (du).** Opt-in only: swap each dir's inode size for its
      recursive on-disk size via one `du` spawn. Never on by default
      (node_modules would stall every listing).
      **Live bug L-1 — the live implementation cannot work on macOS.** It
      runs `du -sb` and throws the error away (`e> /dev/null` discards
      stderr), but macOS `du` has no `-b`: `/usr/bin/du -sb <path>` prints
      `du: invalid option -- b` and its usage banner. The rebuild runs
      **`du -sk`** and multiplies by **1024** to reach bytes. `-sk` is also
      the *right* number: `-sb` is apparent size, `-sk` is allocated blocks,
      which is exactly what this requirement's own "on-disk size" asks for —
      so the correction runs in both directions.
      **Why not `gdu`:** it is not installed, and it is not in
      [`05-platform/02`](../../05-platform/02-package-provisioning/packages-installer/prd.md)
      R7's required package set — choosing it would mean adding coreutils to
      another node's required set to buy a flag `-sk` already provides.
      **The constraint that matters more than the flag.** The discarded
      stderr is why **L-1** survived: the banner went to `/dev/null`,
      `parse -r` found no rows, the size map came back empty, and the
      `default $row.size` fallback quietly restored the very inode sizes the
      flag exists to replace — so `ls -D` *looked* like it worked and showed
      the flat ~4 KB directory entries it was written to replace. The rebuild
      must not discard `du`'s stderr without also detecting the failure: a
      `du` that errors surfaces once, rather than degrading silently back
      into inode sizes.
- [x] **R4** — **Variants.** `l`, `ll`, `la`. *(H6: all resolve, `la` shows
      the dotfile `l` omits, `ll` columns a strict superset.)*
- [x] **R5** — **Auto-list hook.** The PWD env_change hook runs `la` after
      every real directory change in an interactive shell — skipping the first
      fire at startup, and skipping when the bare-word fallback is about to
      clear the screen. `stty sane` first, so a crashed full-screen TUI can't
      staircase the table. *(H7–H10; the hook body is `try { la | print }`
      behind a width guard — three measured constraints, see History.)*

## Acceptance
- [x] `cd` anywhere (including via zoxide/picker) prints the listing once,
      correctly aligned even right after quitting a TUI mid-render.
      *(tests/shell-listing.sh H7: pty cd prints the canary exactly once; H8:
      after `stty -onlcr` the listing still returns to column 0 because the
      hook runs `stty sane` first. zoxide/picker are unbuilt — they reach the
      same single PWD reaction point, epic invariant I2.)*
- [x] Plain `ls` in a dir with node_modules returns instantly; `ls -D` shows
      real recursive sizes — checked against a known directory, not against
      "it printed something", because L-1's failure mode was a discarded
      stderr and a plausible wrong number rather than an error.
      *(H3: plain `ls` never spawns du at all — a poison stub proves it; H4:
      the 2 MiB fixture dir reports 2097152 under `-D`, 96 plain.)*
- [x] With `du` made to fail (e.g. an unsupported flag), `ls -D` reports the
      failure once instead of silently showing inode sizes.
      *(H5: usage-banner stub exiting 64 → exactly one
      `ls -D: du produced no sizes, exit 64: du: invalid option` on stderr,
      and the dir shows its inode size, matching plain `ls`.)*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## History
Attempt 1, swept 2026-08-22: the claiming session died with the implementer
mid-task. Retried the same day.
Three specs exist in `specs/` with no acceptance box ticked, the verify
target `tests/shell-listing.sh` was never created, and the target repo holds
no listing work — `core-ls` appears only as core-config's reserved comment
at `home/dot_config/nushell/config.nu:143`. Clean slate; a retry starts from
the specs as written.

Attempt 2, landed 2026-08-22: all three specs implemented,
`tests/shell-listing.sh` green (EXIT=0), `tests/nushell-core.sh` and
`nu tests/help-content-model.nu` green, gate registered in wave 4. Four
findings, each measured and recorded in `config.nu`'s comments:

- **The live LS_ICONS glyphs do not exist.** Hexdump over the live file and
  every revision in the live repo's history: the map's value strings are
  empty — no private-use byte was ever there. Carried byte-verbatim per
  spec01 (`cmp` against live lines 64–77 identical), so the icon column
  renders empty. Restoring real glyphs is a correction against the live
  source; the manual's "each row carries an icon" currently overstates.
  Needs a backlog entry — outside this lane's write footprint.
- **The wrapper tilde-expands a leading `~` per pattern.** The builtin does
  not expand `~` inside a string variable, and spec01's own verify runs
  `ls ~/fix`; only the leading-tilde case is touched so plain-`ls` names
  stay relative.
- **The hook body is `try { la | print }` behind
  `(term size).columns > 0`.** Three pty measurements were recorded on
  0.114.1; **re-measured 2026-08-23, only the first stands.**
  - **Stands.** The hook runner discards a closure's return value, so bare
    `la` shows nothing and the listing must be `la | print`. Measured both
    ways: bare `ls` logs two fires and prints no table, `ls | print` prints
    it; against the real config, `dirs.txt` records the move while the
    marked filename never appears.
  - **Retired.** "`la | print` hangs the shell outright on a 0-column pty"
    does not reproduce. What reproduces is **one `Couldn't fit table into 0
    columns!` per fire, and the session carries on** — two `cd`s give two
    messages, `exit` is still read, a 200-entry directory does not hang, and
    keeping the `try` does not suppress it, so it is a display message and
    not a catchable error. The parenthetical assigning the guard to the
    *typed* path only is backwards: at a 0-column prompt, `la | print` and
    bare `la` print the same single line. This node's own gate already knew
    — `tests/shell-listing.sh:158-166` gives exactly this as the reason its
    runner sets a winsize. The bullet and the gate written for it
    contradicted each other; **the gate was right.**
  - **Retired, both halves.** "An error thrown in one PWD closure stops
    every PWD closure — dirstack included — for the rest of the session" is
    per-fire and forward-only, and the dirstack is what *survives*, because
    its append comes first. See
    [`pwd-closure-blast-radius`](../../00-delivery/corrections/pwd-closure-blast-radius/prd.md).

  The guard and the `try` both keep their place: the guard suppresses one
  noise line per `cd`, the `try` bounds an abort to one closure onward.
- **`gates/selftest.sh` exits 1 for a pre-existing reason:**
  `gates/wave-status.sh --selftest` still reads retired `.mi/prds/` paths.
  Its FAIL set is byte-identical with this node's registration removed —
  spec03's registration box is half-met and says so.
