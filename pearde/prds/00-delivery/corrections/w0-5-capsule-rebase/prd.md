---
state: done
claim:
priority: 28
est: 0.75h
task: W0.5
mode: afk
needs:
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/corrections/w0-6-live-bugs
verify: ""
origin: derived
from: 00-delivery/corrections
---

# Re-base 01-capsule on build-once and free the colliding bindings

Purpose: The capsule epic rests on legacy code that never worked and claims
keybindings that are already taken. Re-base it before anything is built.

## Requirements
- [x] **R1** — Re-base the epic on "build once": one image definition, built
      once, reused. C-2 records that no live capsule implementation exists to
      consolidate from, so this is design, not porting. spec01 Verify
      2026-08-22: `PASS epic: build-once purpose`, `PASS epic: cites C-2`,
      `PASS 01: retitled`.
- [x] **R2** — Resolve the `Ctrl+Shift+B` / `Ctrl+Shift+T` collisions (C-1).
      `Ctrl+Shift+B` is contested with the live wallpaper feature; the answer
      comes from the wallpaper-opacity decision. Resolved: `Ctrl+Shift+B` is
      free per decision 5(c); the recents new-tab variant moves to
      `Ctrl+Shift+O`, `SpawnTab` keeps `Ctrl+Shift+T`. spec01/spec02 Verify
      2026-08-22: `PASS epic: T stays SpawnTab`, `PASS R2: new-tab key is O`,
      `PASS decisions: rekey recorded`.
- [x] **R3** — Do not preserve legacy `mount` behaviour. C-3: it cd'd to a
      nonexistent `~/docker`, passed wrong `just` recipe arguments, and
      mounted `./workspace` rather than `$PWD`. Design the lifecycle semantics
      fresh. Checked 2026-08-22: every `mount` mention in `prds/01-capsule/`
      is a finding citation, a source-list entry, or a non-goal; the epic's
      one-entry-path acceptance replaces the "covers everything the old
      `mount` did" box (`PASS epic: old acceptance box gone`).
- [x] **R4** — Correct C-4: `devzsh` has no zsh baked in (`CMD ["bash"]`), so
      zsh, oh-my-zsh and Claude Code come only from the new image. spec03
      Verify 2026-08-22: `PASS 02: C-4 attribution`, `PASS 02: sources
      restored`.
- [x] **R5** — Give the capsule terminal keybinding an owner. `01-capsule/01`
      req 4 requires `capsule --rebuild` bound in the terminal and the epic
      success criterion requires one keybinding; no task binds it. Owned now:
      epic `## Bindings` routes `Ctrl+Shift+B` and `Ctrl+Shift+D` to
      `01-container-lifecycle` R8. spec01 Verify 2026-08-22: `PASS 01: R8
      terminal bindings`, `PASS epic: Bindings section`.

## Acceptance
- [x] No capsule PRD describes behaviour of the legacy `mount` script.
      Checked 2026-08-22: `grep -rn` for `~/docker`, `just run`,
      `./workspace`, `` `mount` `` across `prds/01-capsule/` returns only
      finding citations (C-3), the `Parent:` source lists, and the
      porting non-goals.
- [x] Every binding the epic claims is free, or its conflict is recorded with
      the resolution. The epic claims exactly `Ctrl+Shift+D/B/S/O`, each with
      an owner; the table records all four unbound live and in defaults, `B`
      freed by decision 5(c), and the `Ctrl+Shift+T` conflict resolved in
      `01-container-lifecycle` and `04-recent-workspaces` `## Decisions`.
      spec01/spec02 Verify 2026-08-22: `PASS epic: claims Ctrl+Shift+O`,
      `PASS 01: T resolution recorded`, `PASS acceptance: plain-tab check`.
- [x] C-1 through C-5 are each fixed or recorded as accepted with a reason.
      spec04 Verify 2026-08-22: `PASS C-1/C-2/C-4/C-5: fixed record`,
      `PASS C-3: residue landed`, `PASS no open C rows left`.

## Out of scope
- Building the image or the CLI. C.1 and C.2 do that.

## History
Attempt 1, swept 2026-08-22: the claiming session died with the implementer
mid-task. Retried the same day.
Four specs exist in `specs/` with no acceptance box ticked. Whether the
implementer edited any capsule PRD before dying is unverifiable — the whole
`prds/` tree is untracked, so there is no diff to consult. A retry should
diff the capsule PRDs against the specs' intent before rewriting.

Re-validated 2026-08-22 (analyst). The dead session's edits are in the
tree: spec01, spec02 and spec03 are fully applied — each spec's Verify
script passes as-is against `prds/01-capsule/**` and `prds/README.md`.
spec04 is untouched: every `C-*` row in
`prds/00-delivery/corrections/prd.md` still carries its original
`— **open**` text. spec04 was amended twice: its C-3 edit now replaces the
stale "has not landed" clause instead of appending beside it, and its
diff acceptance check uses a scratch copy because `git diff` shows nothing
for the untracked `prds/` tree. Remaining implementer work: run spec04,
re-run the four Verify scripts, tick the spec and PRD boxes from the
executed checks.

Closed out 2026-08-22 (implementer). spec04 applied per the amended text:
the five `C-*` rows in `prds/00-delivery/corrections/prd.md` carry their
dated records, C-3's stale "has not landed" clause replaced. The
scratch-copy diff shows one hunk, every changed line starting `| C-`. All
four Verify scripts pass, 40 checks, zero FAIL. Spec and PRD boxes ticked
from the executed checks.
