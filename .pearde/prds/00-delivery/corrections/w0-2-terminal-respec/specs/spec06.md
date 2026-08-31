verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; a=prds/02-terminal/05-tab-content-state/prd.md; b=prds/02-terminal/06-launchd-path/prd.md; A="$(tr "\n" " " < "$a" | tr -s " ")"; B="$(tr "\n" " " < "$b" | tr -s " ")"; hasA() { echo "$A" | grep -qF "$1" || { echo "FAIL: 05-tab-content-state missing: $1"; rc=1; }; }; hasB() { echo "$B" | grep -qF "$1" || { echo "FAIL: 06-launchd-path missing: $1"; rc=1; }; }; hasA "get_foreground_process_name"; hasA "04-shell/01-core-config"; hasA "OSC 133"; hasA "net-new"; echo "$A" | grep -qF "Detect prompt emission via the terminal stream" && { echo "FAIL: R4 still requires a signal 04-shell/01 R5 turns off"; rc=1; }; echo "$A" | grep -qF "before the prompt redraw completes" && { echo "FAIL: an unfalsifiable timing box survives"; rc=1; }; hasB "launchd"; hasB "/opt/homebrew/bin"; hasB "set_environment_variables"; hasB "No viable candidates found in PATH"; hasB "env.nu"; hasB "C 2"; hasB "U 10"; hasB "sh -lc"; echo "$B" | grep -qF "derived from the provisioning layer" && { echo "FAIL: R2 still asserts a derived list; the live seeding is a fixed four-entry prefix"; rc=1; }; echo "$B" | grep -qF "Parent:" || { echo "FAIL: 06-launchd-path has no Parent line, so it cites no epic and no rating"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 1h

# spec06 — `05-tab-content-state` and `06-launchd-path`

Goal: two children that are neither wrong-by-audit nor decision-blocked, but
each carries one requirement that cannot be built as written.

Files: `.mi/prds/02-terminal/05-tab-content-state/prd.md` and
`.mi/prds/02-terminal/06-launchd-path/prd.md`.

**Proved RED 2026-08-21 — 14 failures**, five against the first file (the
absent `get_foreground_process_name`, `04-shell/01-core-config` and
`OSC 133`, plus the two live guards on R4's unbuildable signal and the
unfalsifiable timing box) and nine against the second.

## `05-tab-content-state` — C 4 / U 7, `net-new`

Keep the feature and its rating; it is the one terminal node with no
inventory entry, because it is not live anywhere. Its Acceptance is
unusually good and mostly survives. One requirement does not.

- [x] **B1 — R4 is unbuildable as written, and this is the fix.** It requires
      classifying panes by "prompt emission via the terminal stream, not via
      a shell hook", while
      [`04-shell/01-core-config`](../../../../04-shell/01-core-config/prd.md) R5
      turns **OSC 133/633 off** on purpose (the phantom-blank-line fix for
      the starship two-line prompt under WezTerm). OSC 133 *is* the
      terminal-stream prompt marker, so R4 asks for a signal the shell is
      deliberately not emitting. Rewrite it against the **foreground
      process**: a pane is `occupied` when its foreground process is not the
      shell. That satisfies R4's actual intent — "no shell-side dependency",
      which the process check meets more completely than prompt markers ever
      did, since it needs no cooperation from any `$SHELL`.
- [x] **B2 — the accessor is verified, not assumed.**
      `pane:get_foreground_process_name()` must exist on the installed build
      before it becomes a requirement — the same build where
      `pane:get_current_working_directory()` is nil and raised on every status
      tick. Checked for this re-spec, read-only:
      `strings` on the `20240203` binary finds
      `get_foreground_process_name` **4 times** and
      `get_current_working_directory` **0 times**. The probe correctly
      reports the known-absent method as absent, which is what makes the
      positive result trustworthy. Record the check in the PRD so the
      implementer can repeat it rather than trust this line.
- [x] **B3 — R2's trigger list follows R4.** "The first prompt emission from
      a shell" is no longer a trigger. Reclassify on pane creation, pane
      exit, and the `update-status` tick, which R5 already relies on.
- [x] **B4 — one acceptance box is unfalsifiable and is replaced.** "flips
      tab 3 to `occupied` **before the prompt redraw completes**" names no
      observable procedure and races a repaint. Replace with the tick-bounded
      form the sibling box already uses: the flip is observable within one
      `status_update_interval`.
- [x] **B5 — R3's colours cross-link rather than restate.** The two states
      derive from the active scheme with no hardcoded hex; the derivation
      lives in [`01-appearance`](../../../../02-terminal/01-appearance/prd.md) B4, which already
      owns `colors.tab_bar`. Keep R3's distinction that occupied/inactive is
      a separate signal from focused/inactive.

## `06-launchd-path` — C 2 / U 10, source `Launchd PATH seeding`

The best value ratio in the inventory, and the one uncovered item T-10 called
fatal. The node has no `Parent:` line at all today, so it cites neither epic
nor rating.

- [x] **B6 — add the `Parent:` header** with `C 2 · U 10 · source: Launchd
      PATH seeding`, matching the inventory exactly.
- [x] **B7 — R2 is wrong and is replaced.** It requires the seeding be
      "derived from the provisioning layer's installed set rather than a
      hardcoded list". The live seeding is a fixed four-entry prefix —
      `/opt/homebrew/bin`, `/opt/homebrew/sbin`, `~/.local/bin`,
      `~/.cargo/bin` — prepended to `set_environment_variables.PATH` on macOS
      only. Requiring a derived list asserts a capability the inventory does
      not show, which is exactly what this whole task exists to stop. Spec
      the fixed prefix, and record *why* it is safe to fix: it seeds **dirs**,
      not packages, so adding a package to the provisioning set needs no
      change here.
- [x] **B8 — the reason is the requirement.** A GUI-launched WezTerm inherits
      launchd's minimal `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), which has
      no Homebrew, so the bare `nu` in `default_prog` cannot be found. The
      window does not die: the pane is created and **kept**, holding
      **"No viable candidates found in PATH"** and then `didn't exit
      cleanly`, because neither config sets `exit_behavior` and the default
      `CloseOnCleanExit` retains an uncleanly-exited pane. A pane you cannot
      type into is harder to diagnose than a window that vanishes. This only
      has to get the binary spawned; `env.nu` owns `PATH` from inside the
      shell.
- [x] **B9 — the same seeding is repeated inline in the F6 `sh -lc`**, for
      the identical reason. One repetition now, not two: the second
      subprocess was the `Ctrl+Shift+B` wallpaper pipeline, dropped by
      decision 5(a). Cross-link [`01-appearance`](../../../../02-terminal/01-appearance/prd.md)
      B11, which owns the F6 binding.
- [x] **B10 — R3 survives unchanged.** A terminal launch is unaffected: no
      doubled or reordered entries that change which binary wins.

## Out of scope

- `plan.json`'s `T.7` row, whose `spec` pointed at the epic rather than at
  this node. Already amended by the conductor; noted so the change is
  traceable to this task.
