# spec02 — rekey the recents picker off `Ctrl+Shift+T` and give C-5's indicator a real host

Resolves the live half of C-1 (`Ctrl+Shift+T` is WezTerm's `SpawnTab`, the
tab reconciler's manual new-tab path) by moving the picker's new-tab variant
to `Ctrl+Shift+O`, re-specs the "Recent:" indicator that has no host (C-5),
and settles the recents-store path discrepancy the work breakdown routed to
W0.5. Covers W0.5 R2 (the `Ctrl+Shift+T` half) and the C-5 acceptance line.

**Est:** 0.75h

**Footprint:** `prds/01-capsule/04-recent-workspaces/prd.md`

Never edit the frontmatter (`---` block). Do not edit
`home/dot_config/nushell/help/*.nuon` — stale help entries are recorded as a
handoff, per the `capsule.nuon` precedent in `w0-4-s2-corrections/capsule`.

## Edits — all in `prds/01-capsule/04-recent-workspaces/prd.md`

1. Replace R1 with:

   > - [ ] **R1** — **Recording.** Every successful capsule mount appends
   >       the directory to `~/.cache/capsule/recents.nuon`, deduplicated,
   >       capped at 20, most recent first. Written by the lifecycle tool,
   >       not by the terminal layer. State, not config: the store lives
   >       outside `~/.config`, so `chezmoi apply` never touches it and
   >       the managed-config surface census stays at nine
   >       ([managed-config](../../../../05-platform/01-deploy-mechanism/managed-config/prd.md)).

   This settles the discrepancy `00-delivery/work-breakdown` records under
   Track C: the schedule put the store at
   `home/dot_config/capsule/recents.nuon`, the PRD at `.cache/recent`.
   Neither survives — a mutable recency list under chezmoi management would
   be overwritten on apply, and the bare legacy path named no owner
   directory. The file keeps the schedule's name and format, outside the
   managed surface.

2. In R2, replace `` `Ctrl+Shift+T` mounts it in a new tab `` with
   `` `Ctrl+Shift+O` mounts it in a new tab ``.

3. Replace R3 with:

   > - [ ] **R3** — **Feedback.** The picker surface itself announces the
   >       mode — its title reads `Recent` — so a stray keypress is not
   >       mistaken for the normal prompt. The status bar is not the
   >       host: the live bar is clock-only, `set_left_status` is never
   >       called (finding C-5), and the JUMP-hint precedent (T-9)
   >       removed status hints as noise.

4. Add an Acceptance box after the existing first box:

   > - [ ] `Ctrl+Shift+O` on a selection opens that capsule in a new tab;
   >       `Ctrl+Shift+T` still spawns a plain tab through the
   >       reconciler's manual path.

5. Append a `## Decisions` section before `## Out of scope`:

   > ## Decisions
   >
   > **Decided 2026-08-22 (afk, `w0-5-capsule-rebase` R2): the new-tab
   > variant is `Ctrl+Shift+O`; `Ctrl+Shift+T` stays `SpawnTab`.** The
   > legacy picker used `Ctrl+Shift+T`, but that key is WezTerm's default
   > `SpawnTab` and the tab reconciler treats it as the manual new-tab
   > path (finding C-1) — live machinery the terminal re-spec keeps. C-1
   > instructs picking a new binding. `Ctrl+Shift+O` is unbound in the
   > deployed `wezterm.lua`, in WezTerm's defaults
   > (`wezterm -n show-keys`), and on the board; the legacy
   > `Ctrl+Shift+O` opacity toggle never reached the live config and is
   > excluded, so no muscle memory is displaced. Rejected: taking the key
   > from `SpawnTab`, which breaks the nine-tab floor's manual path;
   > dropping the new-tab variant, which is a `SIMPLIFY` of an inventory
   > entry the author rated take-over-as-is. Reversal costs one key name
   > here and one row in the rebuilt keys table.
   >
   > **The status indicator is respecced (finding C-5).** The legacy
   > picker's `Recent:` status hint has no host in the rebuild — R3 names
   > the reason. Mode feedback is the picker surface itself.
   >
   > Stale downstream, recorded not fixed:
   > `home/dot_config/nushell/help/terminal.nuon`'s `[Ctrl+Shift+T]` and
   > `[Ctrl+Shift+S]` entries still describe the old key and the status
   > indicator, and its header comment calls `Ctrl+Shift+T` "the one real
   > collision left". Correcting them is `06-help` work with an
   > independent re-read attached, per the `capsule.nuon` precedent in
   > [`w0-4-s2-corrections/capsule`](../../w0-4-s2-corrections/capsule/prd.md).

## Acceptance

- [x] R1 names `~/.cache/capsule/recents.nuon` and the reason it sits
      outside the managed-config surface; `` `.cache/recent` `` is gone.
      Verify 2026-08-22: `PASS R1: nuon store path`, `PASS R1: old path
      gone`, `PASS R1: managed-config reason`.
- [x] R2 claims `Ctrl+Shift+S` and `Ctrl+Shift+O`; no requirement claims
      `Ctrl+Shift+T`. Verify 2026-08-22: `PASS R2: new-tab key is O`,
      `PASS R2: T claim gone`.
- [x] R3 puts mode feedback on the picker surface and cites C-5 and T-9.
      Verify 2026-08-22: `PASS R3: C-5 reason`, `PASS R3: T-9 precedent`.
- [x] `## Decisions` records the rekey with its rejected alternatives and
      the stale `terminal.nuon` handoff. Verify 2026-08-22: `PASS
      decisions: rekey recorded`, `PASS decisions: help handoff`.
- [x] Frontmatter unchanged. `git diff` is empty by construction
      (untracked tree); checked 2026-08-22 by printing the `---` block:
      well-formed, scheduled fields intact.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
f=prds/01-capsule/04-recent-workspaces/prd.md
fail=0; chk(){ if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }
chk "R1: nuon store path"          "grep -qF '~/.cache/capsule/recents.nuon' $f"
chk "R1: old path gone"            "! grep -qF '(\`.cache/recent\`)' $f"
chk "R1: managed-config reason"    "grep -qF 'census stays at nine' $f"
chk "R2: new-tab key is O"         "grep -qF '\`Ctrl+Shift+O\` mounts it in a new' $f"
chk "R2: T claim gone"             "! grep -qF '\`Ctrl+Shift+T\` mounts' $f"
chk "R3: C-5 reason"               "grep -q 'C-5' $f && grep -qF 'set_left_status' $f"
chk "R3: T-9 precedent"            "grep -q 'T-9' $f"
chk "acceptance: plain-tab check"  "grep -qF 'plain tab' $f"
chk "decisions: rekey recorded"    "grep -qE 'Decided 2026-08-[0-9]{2}.*R2' $f"
chk "decisions: help handoff"      "grep -qF 'terminal.nuon' $f"
exit $fail
```
