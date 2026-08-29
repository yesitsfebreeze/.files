---
state: done
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
actual: 0.11h
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
- [x] **R2** — **Picker.** `Ctrl+Shift+S` opens a fuzzy-selectable list and
      mounts the choice in the current pane; `Ctrl+Shift+O` mounts it in a new
      tab. `[~]`, not `[x]`: both keys are proven in the compiled key table
      (`tests/capsule-recents.sh --keys`) and the picker call is proven
      against a RECORDING `tv` shim (`--hermetic` s5, s6, s7). The live
      screen and the mount it performs were manual boxes 1 and 2 for C.4.

      **Lifted `[~]` -> `[x]` 2026-08-29.** `bash tests/capsule-recents-gui.sh`
      drives both keys against a real GUI WezTerm and reads the screen back:
      `Ctrl+Shift+S` opens the list in the current pane and Enter attaches at
      `/workspace`; `Ctrl+Shift+O` puts it in a NEW tab while the pane it came
      from keeps running its command. 29 run, 29 passed, EXIT=0. No shim: the
      real `tv`, the real `capsule`, a real container.
- [x] **R3** — **Feedback.** The picker surface itself announces the
      mode — its title reads `Recent` — so a stray keypress is not
      mistaken for the normal prompt. The status bar is not the
      host: the live bar is clock-only, `set_left_status` is never
      called (finding C-5), and the JUMP-hint precedent (T-9)
      removed status hints as noise. `[~]`: `--input-header "Recent"`
      is asserted verbatim in the file and in the recorded argv, and the
      real `tv` accepts the flag set (`--hermetic` s8); the RENDERED
      title was manual box 1.

      **Lifted `[~]` -> `[x]` 2026-08-29.** The rendered title reads `Recent`
      on screen, read out of `wezterm cli get-text` rather than asserted from
      the argv.
- [x] **R4** — **Hygiene.** Directories that no longer exist are skipped or
      pruned on read; the list survives terminal restarts. Proven against
      the real reader and real files, no stub involved:
      `tests/capsule-recents.sh --hermetic` s1 (prune and write-back), s2
      (no churn when every entry lives), s3 (no store, no file created).

## Acceptance
- [x] Mount three directories, restart WezTerm, press `Ctrl+Shift+S`: all
      three appear, newest first; selecting one attaches to its capsule.

      `tests/capsule-recents-gui.sh` C.4/1, 2026-08-29: the probe is quit and
      relaunched (a different pid, asserted), the list opens titled `Recent`
      at `1 / 3`, and the three are read off the screen in the store's order —
      `gamma beta alpha`, compared as a string, not eyeballed. Typing `beta`
      gives `1 / 1` with gamma gone. Enter reaches a `/workspace` prompt in
      the container.

      **Six runs, and every red but one was a check that could not
      discriminate rather than a defect in the picker** — the fixture, a marker
      grepped from a screen carrying its own command echo, two dropped
      keystrokes, a retry that appended so the green became unreachable, and
      an absence assertion that went green on a blank screen. The rule that
      came out of it is
      [`an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen`](../../memos/an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen.md).

      **The narrowing assertion needed a fixture fix, and it is worth
      recording.** Staged under the scratch path, all three entries matched
      the query `beta` — tv's matcher is a fuzzy SUBSEQUENCE matcher and
      `b`,`e`,`t`,`a` all occur in order inside the 100-character shared
      prefix. The picker showed `1 / 3` and narrowing looked broken. It was
      not; the fixture was. Under `/tmp/c4h/work` the same query gives
      `1 / 1`.
- [x] `Ctrl+Shift+O` on a selection opens that capsule in a new tab;
      `Ctrl+Shift+T` still spawns a plain tab through the reconciler's
      manual path.

      C.4/2 and C.4/4, 2026-08-29. `Ctrl+Shift+O` from a pane running
      `sleep 400sec` adds one tab, the picker is in the NEW pane and not in
      the busy one, and the busy pane's command has still not finished.
      `Ctrl+Shift+T` adds a tab with no picker in it and a usable shell —
      the BEHAVIOUR, not `show-keys`' declaration, which is what that box
      says no automated gate had shown.
- [x] A deleted directory no longer appears after the next picker open.

      C.4/5, 2026-08-29. With `beta` deleted from disk and still named in the
      store, the first open lists two and omits it, `recents.nuon` no longer
      names it, and a second open still lists two — the rewrite survives the
      pick that follows it, which is the half hermetic testing could not
      reach.

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

## Unblocked 2026-08-29 — the five ran, and the reason they could not was not the one written here

`bash tests/capsule-recents-gui.sh` → **35 run, 35 passed, EXIT=0**, the last
three of those an epilogue asserting the live machine is untouched —
`~/.cache/capsule` still absent, `~/.config/wezterm` still carrying no capsule
binding, and `chezmoi source-path` unmoved at `/Users/feb/dev/.files/home`; `--selftest` → **4 run, 4
passed**, three counterfactuals failing for three different reasons. The five
C.4 rows in [`gates/manual/wave4.md`](../../../gates/manual/wave4.md) are
`[x]` with an amendment saying who graded them.

**The section below is kept exactly as written, because its diagnosis was
wrong in an instructive way.** It says these boxes need "a GUI WezTerm and a
live tv screen" and that the guard makes the picker "undrivable without a
terminal". Both true, and neither was the blocker. Measured 2026-08-29: the
binding is at `home/dot_config/wezterm/wezterm.lua:1213` and is **absent from
`~/.config/wezterm/`**; `wezterm show-keys --lua` counts 0
`SpawnCommandInNewTab`; `command -v capsule` is empty; `~/.cache/capsule/`
does not exist; `chezmoi source-path` answers `/Users/feb/dev/.files/home`.
Nobody could press `Ctrl+Shift+S` on this machine and get a picker, human or
otherwise, because `just cutover` has not run. A box can be blocked for a
reason nobody wrote down, and "only a human can do this" is a comfortable
place for that reason to hide.

**What the tick claims, and what it does not.** The harness stages a HOME out
of this repo and drives an isolated WezTerm at it — its own app bundle, real
GUI keystrokes through `osascript`, the screen read back with `wezterm cli
get-text`. So the bindings are proven under `--config-file`, with `capsule`
and the nushell config supplied by the staging rather than by chezmoi. **What
survives a cutover is untested until there is a cutover**, and that is a
smaller claim than the boxes were written to make.

**`just cutover` is now the visible unmade decision, and no node owns it.**

**Why `verify:` stays the headless command.** This node now has two proofs and
they are not interchangeable. `bash tests/capsule-recents.sh` runs anywhere and
is what `just gates` can call; `bash tests/capsule-recents-gui.sh` needs a
window server, a real GUI WezTerm and Accessibility permission for whatever
terminal invokes it, so it is deliberately absent from `gates/waves.tsv` — a
gate suite that cannot run headless is a gate suite that gets switched off.
The GUI harness is named here, and in the amended C.4 rows, rather than hidden
in a frontmatter field that a headless runner would fail on.

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

spec01-recents-picker: exit 0
╭───┬───────────────────────────────────────────────────────────────────╮
│ 0 │ /var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/a │
│ 1 │ /var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/b │
╰───┴───────────────────────────────────────────────────────────────────╯
/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/b
--- store after prune:
["/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/a", "/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/b"]--- tv argv:
--source-command printf '%s\n' '/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/a' '/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.7v0ZQVSQPU/b' --input-header Recent --no-sort --no-preview --keybindings enter="confirm_selection"
Error: nu::shell::error

  x capsule recent: interactive-only — tv needs a TTY
--- tv argv after the guard (must be empty):
cd count:   0
just count: 0
FAIL count: 0

spec02-picker-bindings: exit 0
show-keys exit=0
62:    { key = 'B', mods = 'CTRL', action = act.SendString 'capsule\u{20}--rebuild\r' },
65:    { key = 'D', mods = 'CTRL', action = act.SendString 'capsule\r' },
78:    { key = 'O', mods = 'CTRL', action = act.SpawnCommandInNewTab{ args = { 'nu', '--config', '/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.xaVhLH8Wd5/.config/nushell/config.nu', '--env-config', '/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.xaVhLH8Wd5/.config/nushell/env.nu', '--execute', 'capsule\u{20}recent' }, domain =  'CurrentPaneDomain' } },
81:    { key = 'Q', mods = 'CTRL', action = act.EmitEvent 'user-defined-2' },
84:    { key = 'S', mods = 'CTRL', action = act.SendString 'capsule\u{20}recent\r' },
85:    { key = 'T', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
86:    { key = 'T', mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
93:    { key = 'X', mods = 'CTRL', action = act.EmitEvent 'user-defined-3' },
149:    { key = 'F6', mods = 'NONE', action = act.EmitEvent 'user-defined-1' },
171:      { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
172:      { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
1
1

spec03-recents-gate: exit 0
── stage --tree: the two managed files as text
      guard[tree] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[tree] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path in  = /Users/feb/dev/.files/home
PASS  tree: capsule.nu is a regular file in the managed tree
PASS  tree: wezterm.lua is a regular file in the managed tree
PASS  tree: the three picker helpers appear once each above `def capsule [`, and `def "capsule recent" [` once below `def "capsule clean" [`
PASS  tree: counterfactual copy really dropped the _capsule_shquote def line
PASS  tree: counterfactual shquote-def-dropped FAILS the parse-order check
PASS  tree: counterfactual copy really moved _capsule_recents_pick below `def capsule [`
PASS  tree: counterfactual pick-def-below-capsule FAILS the parse-order check
PASS  tree: _capsule_recents_pick carries all 4 tv flags verbatim — --input-header "Recent" (R3), --no-sort (R1's order), --no-preview, --keybindings 'enter="confirm_selection"'
PASS  tree: counterfactual copy really deleted --no-sort
PASS  tree: counterfactual no-sort-deleted FAILS the flag-set check — without it tv reorders by match quality and the newest entry leaves the top
PASS  tree: exactly one `^tv ` and no bare `tv ` in command position — the shim can observe every call
PASS  tree: counterfactual copy really calls a bare tv
PASS  tree: counterfactual bare-tv-call FAILS the call-convention check
PASS  tree: _capsule_recents_read opens (_capsule_recents) and exactly one NON-COMMENT line names recents.nuon — C.2's def, no second literal
PASS  tree: counterfactual copy really spelled the store path a second time
PASS  tree: counterfactual second-store-literal FAILS the one-store-path check
PASS  tree: `capsule recent` is guard -> _capsule_recents_read -> _capsule_recents_pick -> `capsule $picked` — one mount path, and the live run is gates/manual/wave4.md boxes 1 and 2
PASS  tree: counterfactual copy really stops short of the mount
PASS  tree: counterfactual pick-not-mounted FAILS the composition check
PASS  tree: wezterm.lua carries the s CTRL|SHIFT SendString("capsule recent\\r") entry
PASS  tree: counterfactual copy really altered the S payload
PASS  tree: counterfactual wez-s-payload-altered FAILS the S entry check
PASS  tree: the o CTRL|SHIFT entry is SpawnCommandInNewTab over nu_config/nu_env with "--execute", "capsule recent", and names no literal config path
PASS  tree: counterfactual copy really hardcoded the nushell config path in the o entry
PASS  tree: counterfactual wez-o-hardcoded FAILS the o entry check — 06-launchd-path's locals must be reused, not respelled
      guard[tree] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path out = /Users/feb/dev/.files/home
PASS  tree: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  tree: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --keys: the compiled key table
      guard[keys] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[keys] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[keys] source-path in  = /Users/feb/dev/.files/home
PASS  keys: show-keys --lua exits 0 under an isolated HOME (rc=0)
PASS  keys: stderr free of 'Configuration Error'
PASS  keys: 'S' with 'CTRL' is SendString 'capsule\u{20}recent\r' (R2, in this pane)
PASS  keys: the dump does NOT contain an unescaped 'capsule recent' — a check grepping for it could never pass
PASS  keys: 'O' with 'CTRL' is SpawnCommandInNewTab (R2, a new tab)
PASS  keys: the O row's args end '--execute', 'capsule\u{20}recent'
PASS  keys: the O row's domain is 'CurrentPaneDomain' — the tab lands in this window
PASS  keys: the O row names /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.GpNcww/keys-home/.config/nushell/config.nu — nu_config was reused, not respelled
PASS  keys: the O row names /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.GpNcww/keys-home/.config/nushell/env.nu — nu_env was reused, not respelled
PASS  keys: counterfactual O row carrying a foreign home FAILS the nu_config reuse check
PASS  keys: 'T' with 'CTRL' is still SpawnTab 'CurrentPaneDomain' — the tab reconciler's manual path (finding C-1)
PASS  keys: 'T' with 'SHIFT|CTRL' is still SpawnTab 'CurrentPaneDomain'
PASS  keys: 'D' with 'CTRL' is still SendString 'capsule\r' — C.2 undisturbed
PASS  keys: 'B' with 'CTRL' is still SendString 'capsule\u{20}--rebuild\r' — C.2 undisturbed
PASS  keys: 'F6' is still bound — no terminal-epic row displaced
PASS  keys: 'Q' is still bound — no terminal-epic row displaced
PASS  keys: 'X' is still bound — no terminal-epic row displaced
      guard[keys] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[keys] source-path out = /Users/feb/dev/.files/home
PASS  keys: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  keys: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --hermetic: the real helpers, a recording tv shim, no terminal
      guard[hermetic] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[hermetic] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path in  = /Users/feb/dev/.files/home
PASS  hermetic: pre `tv` on the scenario PATH is the shim, not the real television
PASS  hermetic: pre no `docker` at all on the scenario PATH — this stage cannot reach a daemon
PASS  hermetic: s1 a store of three with the middle entry deleted reads back as the two live ones in stored order, and the file on disk is rewritten to those two (R4)
PASS  hermetic: s2 a store whose every entry exists is byte-identical after a read — no churn on the common path
PASS  hermetic: s3 no store file: an empty list, and no file created
PASS  hermetic: s4 `capsule recent` non-interactive: non-zero exit naming interactive-only, and NO tv log — the guard fires before the call
PASS  hermetic: s5 exactly one tv invocation, carrying --input-header Recent, --no-sort, --no-preview and --keybindings enter="confirm_selection", and the shim's line comes back as the pick (R2, R3)
PASS  hermetic: s6 the recorded source command emits the store's directories one per line IN ORDER — newest first survives into the screen's input (R1, R2)
PASS  hermetic: s7 a directory name with a space and a single quote round-trips through the source command byte-identically
PASS  hermetic: s8 the real tv does not reject this flag set at argument parsing (rc=1, not 2)
PASS  hermetic: s8 stderr free of 'Error parsing CLI arguments' — the key="action" grammar is the accepted one
PASS  hermetic: s8 control the inverse form 'confirm_selection = "enter"' IS rejected with 'Error parsing CLI arguments' — tv validates eagerly, so a typo is loud
NOTE  hermetic: s9 the live keypress -> tv screen -> mount path is NOT covered here
      (the guard makes it undrivable without a terminal). Its text half is
      --tree's composition check; its live half is the five C.4 rows in
      gates/manual/wave4.md.
PASS  hermetic: control copy really returns its argument unquoted from _capsule_shquote
PASS  hermetic: control shquote-passthrough FAILS scenario 7 — an unquoted name with a space becomes two paths
PASS  hermetic: control copy really dropped the prune write-back
PASS  hermetic: control no-prune-writeback FAILS scenario 1 — the dead entry is filtered but never removed
PASS  hermetic: control copy really dropped the TTY guard
PASS  hermetic: control tty-guard-dropped FAILS scenario 4 — without it the def walks into tv with no terminal
PASS  hermetic: control copy really dropped --no-sort from the call
PASS  hermetic: control no-sort-dropped FAILS scenario 5's argv check
PASS  hermetic: live ~/.cache/capsule, capsule.nu and wezterm.lua untouched
      guard[hermetic] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path out = /Users/feb/dev/.files/home
PASS  hermetic: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  hermetic: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
capsule-recents: 69 pass, 0 fail
exit=0
--tree FAIL count: 0
--keys FAIL count: 0
--hermetic FAIL count: 0
PASS  hermetic: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
capsule-lifecycle: 60 pass, 0 fail

## An earlier exchange — kept, but it is not a round

**The heading here used to be `## Answers`, and that was the defect.** The
board's rule is that a heading with nothing behind it is deleted rather than
filled: there was no `## Questions` above this, the round was never recorded,
and writing one now would be inventing a fork nobody put. So the section stays
for what it holds and stops claiming to be an answer.

**The reply is kept verbatim.**

> we should have a picker, bit i dont know hat your question is here

What the user said is a remark about the question, not an answer to it — the
round it belonged to was never recorded here, so a later reader met an answer
with nothing above it and no way to tell what was settled. Per the board's own
rule, a reply saying the question was wrong changes the round rather than
being written down as a decision.

**What is settled:** there is a picker, and it is built. R1 is `[x]`, the
implementation landed, and `bash tests/capsule-recents.sh` passes against a
recording `tv` shim. Nothing about the picker's existence was ever in doubt,
which is why the question read as confusing.

**What is not settled is not a question for the user at all** — it is five
things only a human at a GUI WezTerm can see, and they are listed in
`## Blocked` below and written into `gates/manual/wave4.md` as the C.4 rows.
That is why this node is `blocked` and not `question`: it waits on an
observation, not on a decision.

Repaired 2026-08-28 under
[`doctor-debt-live-nodes`](../../00-delivery/finish-line/doctor-debt-live-nodes/prd.md)
R2 and R3.

## Questions

Board-frontier drill round, 2026-08-29 — the second such round on this board.
This node's fork. The `## Blocked` section above names the reason these five
boxes need a person: *"five things only a human at a GUI WezTerm can see."*
**That reason was measured this round and it is wrong** — or rather, it is
true and it is not the blocker.

Measured 2026-08-29, on this machine:

| probe | result |
|---|---|
| `grep "key = \"s\"" home/dot_config/wezterm/wezterm.lua` | **:1213**, `SendString("capsule recent\r")` |
| the same grep against `~/.config/wezterm/*.lua` | **no match** |
| `wezterm show-keys --lua \| grep -c SpawnCommandInNewTab` | **0** |
| `command -v capsule` | **nothing** |
| `ls ~/.cache/capsule/` | **No such file or directory** |
| `chezmoi source-path` | `/Users/feb/dev/.files/home` — the pre-rebuild repo |

So nobody can press `Ctrl+Shift+S` on this machine and get a picker, human or
not: the binding is in this repo and is not in the running config, because
`just cutover` has not run. The five boxes were unrunnable for a reason none
of them states.

The other half of the measurement is what makes the fork real. `osascript`
System Events answers `rc=0` — Accessibility is granted — so a *real* GUI
keystroke can be injected, which is the key path `Ctrl+Shift+S` actually
travels; `wezterm cli send-text` is not, because it pastes into the pane and
never reaches the binding layer. `wezterm cli get-text` reads any pane,
`wezterm start --always-new-process --class <name>` gives an instance that can
be quit and reopened without touching the session driving it, and Docker is up
(29.4.0).

### Q1: C.4's real blocker is that the config is not deployed, not that it needs a human. How should the five get run?

1. **Build the harness and run them.** An isolated instance pointed at this
   repo's config file directly — the `Ctrl+Shift+O` binding already spawns
   `nu --config <repo> --execute "capsule recent"`, so the nushell half needs
   no deployment either. Real GUI keys via osascript, the screen read back
   with `wezterm cli --class <name> get-text`. (recommended)
2. **Run `just cutover` first, then the user presses the keys.** The boxes are
   then exactly what they were written to be, with no harness and no caveat.
3. **Split: close this node on its automated evidence** and move the five to a
   standing manual node that is nobody's `needs:`.

## Answers

Answered 2026-08-29 by the user, in the board-frontier drill round.

**Q1** — **Build the harness and run them.** All five PASS lines are
mechanical and readable from `get-text`: a list titled `Recent`, three
directories newest-first, typing narrows, Enter attaches at `/workspace`, Esc
leaves a live prompt in the directory picked from, `Ctrl+Shift+T` still a
plain tab, and a deleted directory gone from `recents.nuon` on the first
re-open.

**Three conditions the answer carries, so the tick means what it says.**

- **The harness is the grader of record, and the node must say so.** These
  boxes were written as human checks. Closing them by machine is a change to
  what they assert, not a discovery that they were always automatable, and the
  `## Blocked` section's sentence above is amended rather than deleted.
- **It proves the binding under `--config-file`, not under a deployed tree.**
  That is a narrower claim than the box's, and the gap is named: `capsule` on
  `PATH` and the deployed nushell config are supplied by the harness, not by
  chezmoi. What survives cutover is untested until cutover.
- **It has side effects on the real machine** — `~/.cache/capsule/recents.nuon`
  is created and a capsule image is built. Both are the feature's own
  artifacts and neither exists today.

**`just cutover` is now a visible unmade decision and nothing on the board
owns it.** Option 2 named it and was not taken, so it is recorded here rather
than filed: the rebuild's whole point is a machine running this repo, and the
step that does it has never been scheduled.
