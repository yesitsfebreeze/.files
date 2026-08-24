---
state: done
commit: 03d7bb5
claim:
priority: 12
est: 1.5h
task: S.7
mode: afk
needs:
  - 04-shell/04-television
  - 00-delivery/corrections/w0-4-s2-corrections
  - 06-help/01-content-model
verify: "quicklist round-trips a pick (wave-5 gate)"
---

# Quicklist — cross-channel recents

Parent: [Nushell epic](../prd.md) · C 6 · U 6 · source: "Quicklist —
cross-channel recents" in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: One recency log for everything you pick or jump to — finder
selections, zoxide jumps, fallback jumps, `z`-opened files — re-surfaceable as
a tv channel. That is the **rebuild's intent, not a description of the live
config**: live bug **L-4** — `_recents_add` is defined and exported in
`finder.nu`, and `finder` never calls it. The only four call sites are in
`config.nu` (the three zoxide wrappers and the bare-word fallback), and all
four tag the entry with channel `zoxide`, so today the log holds directory
jumps only and a file opened through the finder never reaches it.

## Requirements
- [x] **R1** — **Log.** `_recents_add kind value channel`: entries carry kind,
      value, channel, cwd, timestamp; dedup by channel+value, newest first,
      cap 200; stored as nuon in XDG state.
- [x] **R2** — **Producers.** The zoxide wrappers, the bare-word fallback, and
      finder picks all log; a failed jump logs nothing. The finder half is the
      **L-4** fix, and it goes **inside `finder`, where the channel name is
      already in hand** — logging from the call site instead loses it, and an
      entry whose channel is unknown cannot be replayed (R3). That is the
      difference between a log that can be replayed and one that cannot.
- [x] **R3** — **`Ctrl-Q`** opens the quicklist tv channel (also reachable
      from the channels remote). Two confirm keys via `--expect`:
  - [x] `enter` → OPEN by type, reusing finder's decoder + opener (file →
        editor, dir → cd, commit → git show);
  - [x] `ctrl-r` → REPLAY: cd to the cwd the pick was made in, re-run its
        originating channel there. **New behaviour to build and prove, not a
        port:** because `finder` never logged (**L-4**), every live entry
        carries channel `zoxide`, so this path has never run for any other
        channel — there is no live demo it can be marked met against.
- [x] **R4** — **Empty state.** An empty log prints a one-line hint instead of
      opening tv.

## Acceptance
- [x] Jump somewhere with `z`, open a file via the finder, then `Ctrl-Q`: both
      appear, newest first; enter on the dir entry cds there.
- [x] `ctrl-r` on a `text` (grep) entry reopens the grep picker in the
      directory where the original search ran. Prove this against the
      rebuild: no live entry has ever carried a channel other than `zoxide`
      (R2), so a demo of the live config cannot close this box.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Interrupted 2026-08-24, then resumed and finished — history

Recorded by the orchestrator so nobody misreads the `claim:` above as a live
worker. The implementer was **stopped by the user** mid-run, at its own words
"now the hermetic dispatch scenarios" — so this is neither a failed attempt nor
an infrastructure kill, and it must not be swept to `failed` on the assumption
that something broke.

**Substantial code is on disk and none of it is verified.** Measured at the
moment of the stop:

| file | state |
|---|---|
| `home/dot_config/nushell/recents.nu` | present, 108 lines |
| `home/dot_config/nushell/quicklist.nu` | present, 111 lines |
| `home/dot_config/television/cable/quicklist.toml` | present, 38 lines |
| `tests/shell-quicklist.sh` | present, 1138 lines |
| `gates/manual/wave5.md` | present, 23 lines |

**Zero acceptance boxes are ticked in either spec.** So the gate exists and has
never been run to green in the record, the eight-file nushell staging edit may
be partial, and `tests/shell-television.sh:133`'s `DROPPED` assertion — which
goes red the moment `cable/quicklist.toml` exists — may or may not have been
flipped yet. Treat the tree as *unproven*, not as wrong.

**Two things the orchestrator did around the stop:** the wave-5 registry row
`external bash tests/shell-quicklist.sh` was written into `gates/waves.tsv`
and `bash gates/wave-status.sh --validate` is green with it, so that half is
not owed any more. And every file in this node's footprint was deliberately
**excluded** from the three commits on `board/session-3-landings`, precisely
because a worker was inside them.

**Its scratch is cleaned up.** `m-ql/` and `cf-no-ctrlq-record.nu` were in the
repo root at 01:29 and are gone; the lane was told to move them and appears to
have done so before stopping.

Resuming that worker is cheaper than restarting: it holds the measurements
behind two modules, a 1138-line gate and the parse-order argument for the
two-module split. A fresh implementer would re-derive all of it from a tree it
did not write.

## Proof (implementer, 2026-08-24)

R1–R4 and both acceptance boxes were closed against runs, not readings. The
gate is `tests/shell-quicklist.sh` (`--tree` + `--hermetic`, 111 PASS / 0
FAIL, EXIT=0); the per-box detail and every counterfactual sha pair are in
[`specs/spec01`](specs/spec01-recents-log.md#proof-implementer-2026-08-24) and
[`specs/spec02`](specs/spec02-quicklist-channel.md#proof-implementer-2026-08-24).

The two boxes the PRD says no live demo can close were closed against the
rebuild, in the hermetic stage:

* **L-4, fixed and executed.** `finder --start files` and `finder --start
  text` now append `FileList`/`files` and `GrepList`/`text` entries carrying
  the RAW pick line, so the log holds more than directory jumps for the first
  time. The log call sits below each branch's empty-decode check, and a pick
  that fails that check leaves the log byte-identical.
* **`ctrl-r` replay on a non-`zoxide` channel.** A `GrepList`/`text` entry
  recorded in scratch dir A, `quicklist` run from dir B, `ctrl-r` pressed:
  the second `tv` invocation is `tv text …`, the tv stub's recorded PWD is
  **A**, and the shell is left in A.

Also worth carrying forward: this node ships **two** modules (`recents.nu`
above `zoxide.nu`, `quicklist.nu` below `finder.nu`) because the parse-order
cycle the analyst measured is real, and the eight-gate staging edit — not the
nu code — was the change's blast radius.

## Closed 2026-08-24 by the orchestrator

`done`. The worker resumed after the stop recorded above and finished the
verification pass it was in the middle of. `bash tests/shell-quicklist.sh` →
**EXIT=0, 111 PASS / 0 FAIL**, with `shell-zoxide.sh` 117/0,
`shell-television.sh --tree` green on the census flip (15 → 16, `quicklist` now
in CURATED), and `shell-help.sh` / `nushell-core.sh` green beside them.
Orchestrator spot-checks on this transition: `gates/nushell-module-staging.sh`
**44 PASS / 0 FAIL rc 0** — so the eight-gate staging edit is complete and both
new modules stage everywhere — plus `wave-status.sh --validate` rc 0 and
`manual-coverage.sh` rc 0.

**`actual:` is left empty.** The elapsed time spans a user stop and a resume,
so it measures the interruption rather than the work. Same rule as a BLOCKED
round-trip: a wrong number is worse than none.

**The wave-5 registry row was already written** by the orchestrator while this
lane was mid-flight, so the item the report lists as owed is closed:
`gates/waves.tsv` row 5 carries `external bash tests/shell-quicklist.sh` and
the validator is green with it.

**Four spec corrections, all measured:** `_recents_load` needs two guards
because `"" | from nuon` returns **null** and a list of records describes as
`table<...>` rather than `list<...>`; the replay spawn is the tv stub's
**third** invocation through `tv_remote`, not the second, since
`_finder_pick_channel` spends two first — so the gate asserts the argv
*sequence* instead of an index; the banned `is-terminal` spelling had to leave
the comments as well as the code; and the live claim that `Ctrl-Q` overrides a
reedline default is confirmed false on 0.114.1 and not carried.

**Ten in-gate counterfactuals each print their sha pair on one line**, red
before repair and green after — the shape
[`a-counterfactual-proves-its-own-mutation`](../../memos/a-counterfactual-proves-its-own-mutation.md)
asks for, now landed in a second gate. Three were added to `shell-zoxide.sh`'s
`recents_ok` to replace the shim greps the deletion emptied, and one of those
(shim-reintroduced) was not asked for: nothing else would notice a shadowing
no-op coming back.

**Three findings, reported not fixed:**

1. `gates/nushell-module-staging.sh --selftest`'s GREEN half pins an anchor
   that names `copymode` and `help`, so a module appended *after* `help` would
   no-op its mutation. Both new modules were deliberately placed **before**
   `copymode` to keep it matching. Worth stating plainly: **the tripwire that
   node landed hours earlier already defends this** — a no-op now fails
   `the mutation changed the copy` with an equal sha pair on one line, so the
   failure mode is a red gate rather than a silent pass. That is the tripwire
   earning its keep on a case nobody predicted.
2. `home/dot_config/nushell/help/use-review.nuon:135` carries an L-4 qualifier
   describing the live `quicklist.nu`; the shipped `Ctrl-Q` entry in
   `shell.nuon` is now true of this tree, so the qualifier is stale. Untouched
   — spec02 forbids writing under `help/`, and a `why`/`use` edit stales a
   review digest that needs a reader who is not the author.
3. **Wall clock on this machine is heavily contended**: the same hermetic stage
   measured 8s, 100s, 194s and 273s at ~1% CPU. Correctness was stable and only
   elapsed time moved — another data point for
   [`a-headless-gate-red-may-be-load-not-code`](../../memos/a-headless-gate-red-may-be-load-not-code.md),
   and the reason `actual:` on this board is worth so little while five lanes
   run.
