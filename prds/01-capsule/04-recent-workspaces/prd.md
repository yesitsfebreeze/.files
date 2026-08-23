---
state: blocked
claim:
priority: 10
est: 1.75h
task: C.4
mode: afk
needs:
  - 01-capsule/01-container-lifecycle
  - 02-terminal/06-launchd-path
  - 00-delivery/corrections/w0-5-capsule-rebase
  - 05-platform/01-deploy-mechanism/managed-config
  - 06-help/01-content-model
  - 01-capsule/03-credential-propagation
verify: "bash tests/capsule-recents.sh"
---

# Recent-workspace picker

Parent: [Capsule epic](../prd.md) · C 5 · U 7 · source: "Recent-workspace picker"

Purpose: Fast re-entry into previously used workspaces: a picker over the last
mounted directories, opened from the terminal, landing either in the current
pane or a new tab.

## Requirements
- [x] **R1** — **Recording.** Every successful capsule mount appends
      the directory to `~/.cache/capsule/recents.nuon`, deduplicated,
      capped at 20, most recent first. Written by the lifecycle tool,
      not by the terminal layer. State, not config: the store lives
      outside `~/.config`, so `chezmoi apply` never touches it and
      the managed-config surface census stays at nine
      ([managed-config](../../05-platform/01-deploy-mechanism/managed-config/prd.md)).
      Proven by `tests/capsule-lifecycle.sh` scenario 10 (C.2), re-run
      2026-08-23: 60 pass, 0 fail.
- [~] **R2** — **Picker.** `Ctrl+Shift+S` opens a fuzzy-selectable list and
      mounts the choice in the current pane; `Ctrl+Shift+O` mounts it in a new
      tab. `[~]`, not `[x]`: both keys are proven in the compiled key table
      (`tests/capsule-recents.sh --keys`) and the picker call is proven
      against a RECORDING `tv` shim (`--hermetic` s5, s6, s7). The live
      screen and the mount it performs are manual boxes 1 and 2 for C.4.
- [~] **R3** — **Feedback.** The picker surface itself announces the
      mode — its title reads `Recent` — so a stray keypress is not
      mistaken for the normal prompt. The status bar is not the
      host: the live bar is clock-only, `set_left_status` is never
      called (finding C-5), and the JUMP-hint precedent (T-9)
      removed status hints as noise. `[~]`: `--input-header "Recent"`
      is asserted verbatim in the file and in the recorded argv, and the
      real `tv` accepts the flag set (`--hermetic` s8); the RENDERED
      title is manual box 1.
- [x] **R4** — **Hygiene.** Directories that no longer exist are skipped or
      pruned on read; the list survives terminal restarts. Proven against
      the real reader and real files, no stub involved:
      `tests/capsule-recents.sh --hermetic` s1 (prune and write-back), s2
      (no churn when every entry lives), s3 (no store, no file created).

## Acceptance
- [ ] Mount three directories, restart WezTerm, press `Ctrl+Shift+S`: all
      three appear, newest first; selecting one attaches to its capsule.
- [ ] `Ctrl+Shift+O` on a selection opens that capsule in a new tab;
      `Ctrl+Shift+T` still spawns a plain tab through the reconciler's
      manual path.
- [ ] A deleted directory no longer appears after the next picker open.

## Decisions

**Decided 2026-08-22 (afk, `w0-5-capsule-rebase` R2): the new-tab variant
is `Ctrl+Shift+O`; `Ctrl+Shift+T` stays `SpawnTab`.** The legacy picker
used `Ctrl+Shift+T`, but that key is WezTerm's default `SpawnTab` and the
tab reconciler treats it as the manual new-tab path (finding C-1) — live
machinery the terminal re-spec keeps. C-1 instructs picking a new binding.
`Ctrl+Shift+O` is unbound in the deployed `wezterm.lua`, in WezTerm's
defaults (`wezterm -n show-keys`), and on the board; the legacy
`Ctrl+Shift+O` opacity toggle never reached the live config and is
excluded, so no muscle memory is displaced. Rejected: taking the key from
`SpawnTab`, which breaks the nine-tab floor's manual path; dropping the
new-tab variant, which is a `SIMPLIFY` of an inventory entry the author
rated take-over-as-is. Reversal costs one key name here and one row in the
rebuilt keys table.

**The status indicator is respecced (finding C-5).** The legacy picker's
`Recent:` status hint has no host in the rebuild — R3 names the reason.
Mode feedback is the picker surface itself.

Stale downstream, recorded not fixed:
`home/dot_config/nushell/help/terminal.nuon`'s `[Ctrl+Shift+T]` and
`[Ctrl+Shift+S]` entries still describe the old key and the status
indicator, and its header comment calls `Ctrl+Shift+T` "the one real
collision left". Correcting them is `06-help` work with an independent
re-read attached, per the `capsule.nuon` precedent in
[`w0-4-s2-corrections/capsule`](../../00-delivery/corrections/w0-4-s2-corrections/capsule/prd.md).

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Blocked — the five manual boxes, and nothing else

Written 2026-08-23T21:52Z by the orchestrator. Everything the worker owns is
landed and proven: `bash tests/capsule-recents.sh` exits 0 at **69 pass / 0
fail** across `--tree` (27), `--keys` (19) and `--hermetic` (23);
`tests/capsule-lifecycle.sh` holds its 24-pass `--tree` baseline and passes
60/0 in full; the C.2 gate's `cd`/`just ` word counts on `capsule.nu` are both
0, so no comment was allowed to redden a landed node. All 19 spec boxes are
`[x]` with quoted output.

**Why this is not `done`:** the three PRD acceptance lines each need a GUI
WezTerm and a live tv screen, and spec03 scenario 9 says so and forbids faking
them. R2 and R3 sit at `[~]` for the same reason — the keys, the argv and the
guard are proven against a **recording tv shim**, which is a stub-backed pass.
The worker claimed no green it did not have, which is the behaviour the board
wants; the honest state for that is `blocked`, not `done`.

**What closes it:** the five C.4 rows the orchestrator has written into
`gates/manual/wave4.md` — the picker after a restart, the new-tab variant, an
abort costing nothing, `Ctrl+Shift+T` still plain, and a deleted directory.
Ticking them closes the three acceptance lines and lifts R2/R3 to `[x]`.
`unblock 01-capsule/04-recent-workspaces` re-runs only those boxes.

**Still owed by the orchestrator:** the `gates/waves.tsv` wave-4 row
`external bash tests/capsule-recents.sh`. Measured by the worker:
`bash gates/wave-status.sh --validate` reports exactly one red,
`unreferenced: capsule-recents.sh`, and the row closes it. The file is held by
the `02-keymaps` lane right now, so the row waits for that lane rather than
for this node.

**Two deviations the worker made deliberately, both accepted:** the hermetic
PATH follows `capsule-lifecycle.sh`'s shape (`nu` by absolute path,
`PATH="$M/bin:/usr/bin:/bin"`) because `/opt/homebrew/bin` holds the real `tv`
**and** the real `docker`, which made the spec's own precondition box
unachievable as written; and two counts skip comment lines, because the
picker's header quotes its own `^tv --source-command` call and documents
`--no-sort` in prose. The same rule `rm_sites` already applies in
`capsule-lifecycle.sh`: a comment may not fake a call site, and it may not
inflate one either.

## Report

**DONE from the worker; `blocked` on the board.**

`bash tests/capsule-recents.sh` → exit 0, **69 pass / 0 fail** (`--tree` 27, `--keys` 19, `--hermetic` 23). `tests/capsule-lifecycle.sh --tree` held its 24-pass baseline; full run 60/0. C.2's word counts on `capsule.nu` are 0 for both `cd` and `just `, so no comment reddened a landed node. All 19 spec boxes `[x]` with quoted output.

Landed: `capsule.nu` (`_capsule_recents_read`, `_capsule_shquote`, `_capsule_recents_pick`, `capsule recent`), `wezterm.lua` (`Ctrl+Shift+S` SendString, `Ctrl+Shift+O` SpawnCommandInNewTab), and `tests/capsule-recents.sh`.

**Not `done`:** the three PRD acceptance lines each need a GUI WezTerm and a live tv screen, and spec03 forbids faking them. R2/R3 sit at `[~]` — proven against a recording tv shim, which is a stub-backed pass. The five C.4 rows are now written into `gates/manual/wave4.md`; ticking them closes the acceptance lines and lifts R2/R3.

Still owed by the orchestrator: the `gates/waves.tsv` wave-4 row `external bash tests/capsule-recents.sh`. `gates/wave-status.sh --validate` reports exactly one red (`unreferenced: capsule-recents.sh`) and the row closes it. The file is held by the `02-keymaps` lane.

Two deliberate deviations, both accepted: the hermetic PATH follows `capsule-lifecycle.sh`'s shape, because `/opt/homebrew/bin` holds the real `tv` and the real `docker` and made the spec's own precondition unachievable; and two counts skip comment lines, since the picker's header quotes its own `^tv --source-command` call.
