verify: ""

est: 20m

# spec02 — R4: supersede `docs-inventories`' spec03, don't abandon it red

Goal: R4. Three assertions in a **closed** ticket's landed verify guard the
opposite of what spec01 does. A closed gate may not be left failing, and it
may not be repaired by undoing spec01 either. This spec records the
supersession where the precedent puts it, and routes the one edit this node
is not allowed to make.

**One record for the whole pass — spec01 *and* spec03.** Splitting it would
mean two supersession passes against the same closed gate, which is the
fragmentation that stranded the guard in the first place. Runs last.

Files: `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/prd.md`
— this node's own PRD, and nothing else. Do **not** open
`../docs-inventories/specs/spec03.md`; W0.4i's `files` list in `plan.json` is
`.mi/docs/capabilities-provisioning.md` alone, and the tree's rule is one
writer per file.

**Proven RED on 2026-08-21**: `bash .../specs/check02.sh` exits 1 with three
failures — no `## Superseded guard` section, and both precedent links in R4
dead.

## What exactly goes stale, measured

`../docs-inventories/specs/spec03.md`'s `verify:` was run against the current
tree and returns `OK`, exit 0. After spec01 it fails on exactly three of its
assertions, and on nothing else:

1. `[ "$(RAT | wc -l)" = "12" ]` — the entry count. 12 becomes **10**.
2. The exact-order `WANT` string, which begins `Declarative package set|` and
   contains `Homebrew bootstrap|` and `Package installer|`. All three names
   leave the file; `Tool installation` enters between `Small tool configs`
   and `Neovim version gating`.
3. The `RL` C/U table, which asserts `Declarative package set@2 9`,
   `Package installer@8 9` and `Homebrew bootstrap@2 8`. Those three headings
   stop existing, so `NUM` returns empty for each.

**spec03 adds nothing to that list, and that is a design decision, not
luck.** Its corrections could easily have taken four more assertions with
them — the `L-12`, `L-13`, `solo-window` and `1149` tokens inside
`Managed config surface`, and the `not a port target` / `Decision 4` /
`canonical` phrases in the head. spec03 B2 and B3 correct all of them **in
place**, keeping every guarded literal while making the sentence true, so the
count stays at three. Say so in the record: a later reader needs to know the
tokens were preserved deliberately and must not be tidied away.

Everything else in spec03 survives both specs untouched and is re-asserted by
this node's `check01.sh` and `check03.sh`: the ratio-descending rule, the six surviving C/U
pairs (`Shell-init generation` 3/9, `Idempotent apply + push workflow` 3/9,
`Managed config surface` 3/9, `Neovim version gating` 4/8, `Starship prompt`
2/8, `Small tool configs` 2/7), the burrito-out-of-the-surface assertions,
the L-12 / L-13 / `solo-window` / `1149` records, the `](../prd/` link ban,
the every-relative-link-resolves walk, and the Decision 4 canonicality note in
the head.

## Boxes

- [x] **B1 — a `## Superseded guard` section is added to this node's
      `prd.md`**, at the end, in the shape
      [`odin-toolchain`](../../../../decisions/odin-toolchain/prd.md) used for
      the same situation and [`tinty`](../../../../decisions/tinty/prd.md)
      closed on. It must state, in prose a later reader can act on:

      - which ticket and file owns the stale guard —
        [`docs-inventories`](../../docs-inventories/prd.md) (W0.4a),
        `specs/spec03.md`;
      - the three assertions above, named concretely: the count `12` → `10`,
        the exact-order `WANT` string, and the `8 / 9` / `2 / 9` / `2 / 8`
        C/U entries;
      - why they are stale — the user's Q2 decision folded three entries into
        `Tool installation (install.sh)` at C 4 · U 9, so the guard now
        asserts an inventory that rates deleted machinery;
      - what else the same pass changed in that file, so the record is one
        coherent set and not a fragment: spec03's head correction naming
        `~/.local/share/chezmoi` as the stale clone, the `L-13` / `L-12`
        corrections, the `just push` / `just cutover` rewrite, and the
        `tinted-theming` reconciliation — none of which costs a fourth stale
        assertion, because the guarded tokens were kept in place;
      - that it is **superseded, not violated**, and that the replacement is
        this node's own `specs/check01.sh`, which re-asserts every one of
        spec03's surviving guards;
      - and the prohibition, in the words odin-toolchain used: **do not**
        "fix" `capabilities-provisioning.md` back to make the dead guard
        green.

- [x] **B2 — the routing is explicit, and says why it is routing.** The same
      section must state that W0.4i's `files` list is
      `.mi/docs/capabilities-provisioning.md` only, so it may not write the
      record into `docs-inventories/prd.md` or repoint `spec03.md`, and that
      the **orchestrator** routes both — exactly as it did for odin-toolchain
      ("recorded by the orchestrator, after this ticket closed") and for
      tinty ("the orchestrator repointed the guard"). Name the two edits it
      needs to make, so the routing is a work item and not a wish:

      1. mirror this section into
         `../docs-inventories/prd.md` as its own `## Superseded guard`, dated
         and attributed, the way odin-toolchain carries one;
      2. repoint `../docs-inventories/specs/spec03.md`'s verify — `12` →
         `10`, drop the three names from `WANT` and insert `Tool
         installation` after `Small tool configs`, drop the three
         `@…` pairs from `RL` — so W0.4a's gate is green again on re-run
         rather than green-by-exemption. **Three edits, no more:** every
         other assertion in that verify still passes against the file this
         node leaves behind, which the record should state so the
         orchestrator does not go looking for a fourth.

- [x] **B3 — this ticket's own acceptance is marked honestly.** The fourth
      acceptance box ("`docs-inventories`' superseded assertions are replaced
      by ones that pass, and the supersession is recorded in that ticket")
      cannot be closed from inside this footprint. Mark it `[~]` with a
      one-line note pointing at the `## Superseded guard` section and the two
      routed edits — not `[x]`. A `[x]` this node did not prove is a false
      record that outlives its author.

- [x] **B4 — R4's two precedent links resolve.** They are dead today:
      `../../decisions/odin-toolchain/prd.md` and
      `../../decisions/tinty/prd.md` both resolve to
      `.mi/prds/00-delivery/corrections/decisions/`, which does not exist.
      The decisions live at `.mi/prds/00-delivery/decisions/`, so from this
      node the correct prefix is `../../../decisions/`. Fix both in R4. The
      check walks every relative link in the file and fails on any that does
      not resolve — the same walk spec03 runs over the inventory, for the
      same reason.

## Out of scope

- Editing `../docs-inventories/**`. That is the whole point of this spec:
  the record is written here and routed, not reached for.
- Re-opening W0.4a. Its deliverables are unaffected — spec01 changes nothing
  spec03 actually *did*, only what it asserts about entries the user has
  since folded.

## Spent proof

The check's `\]\((\.\.[^)#]*)\)` link regex spans newlines and now matches
the literal `` `](../prd/` `` pattern quoted in prose at
`prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/prd.md:183`,
added after this node closed; all twelve real relative links in that file
resolve.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/check02.sh`
```
