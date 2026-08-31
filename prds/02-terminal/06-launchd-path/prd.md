---
state: done
claim: 
priority: 11
est: 2.5h
actual: 1h
task: T.7
mode: afk
needs:
  - 02-terminal/05-tab-content-state
verify: ""
---

# launchd PATH seeding

Parent: [Terminal epic](../prd.md) · C 2 · U 10 · source: Launchd PATH
seeding (C 2 · U 10) + Nushell as `default_prog` (C 1 · U 8), both in
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md)

**Scope grown 2026-08-23 by the orchestrator**, on a coverage gap this node's
absence created. `capabilities-terminal.md:132` carries a separate unmarked
entry, "Nushell as `default_prog`" (C 1 · U 8), which had **no PRD anywhere**
and no place on [`prds/README.md`](../../README.md)'s exclusion list — it was
neither ported nor excluded, it was simply lost in the board conversion. This
node's Purpose already presupposed `default_prog` exists, so it is the right
owner. Per the merged-entry rule the header keeps the dominant entry's rating
and lists both sources; `est` moves 1h → 1.5h for the added scope.

Purpose: a GUI launch of WezTerm inherits launchd's PATH, not a shell's.
Without seeding it the config's `default_prog` cannot be resolved, and the
pane comes up holding `No viable candidates found in PATH` instead of a
shell. The window does not die — R3 carries the measurement, and the reason
it matters: a pane you cannot type into is harder to diagnose than a window
that vanishes. This is the best value ratio in
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md), and the
item finding T-10 called the one uncovered feature whose absence is fatal.

## Status after the tmux cutover

**AMENDED 2026-08-30 by [`07-multiplexer/08-wezterm-reduction`](../../07-multiplexer/08-wezterm-reduction/prd.md).**
R1-R3, R5 and R7 — the launch PATH seeding, its shape, and the
`XDG_CONFIG_HOME` export — are untouched and still the reason this node
exists.

Two amendments. **R6 now names `~/.local/bin/tmux-main`** instead of
nushell's argv: the terminal opens into tmux, and the script resolves
`nu` on PATH, exports `XDG_CONFIG_HOME` before the exec and falls back
to a shell that exists — the same three obligations, one layer down and
in one place that an ssh login also says. **R4's F6 PATH prefix moved to
`tmux.conf`** with the binding, measurement and all; `tests/wezterm-launchd-path.sh`
reads it there and asserts none is left here.

The counterfactuals moved with it, and one got sharper. Without the
seeding you no longer get a pane that never started: `tmux-main` is an
absolute path, so it always spawns, cannot find `tmux` or `nu`, and hands
you `/bin/sh` with two lines saying why. The requirement is unchanged —
the seeding is what gets nushell running — and the failure is now
diagnosable instead of silent.

## Requirements

- [~] **R1** — **A GUI launch resolves the config's own program.** Launched
      from Finder, Spotlight or the Dock, WezTerm must find every binary the
      config names, not only those on launchd's default PATH.
- [x] **R2** — **A fixed four-entry prefix, macOS only.** Prepend
      `/opt/homebrew/bin`, `/opt/homebrew/sbin`, `~/.local/bin` and
      `~/.cargo/bin` to `set_environment_variables.PATH`, on macOS only. The
      requirement this replaces asked for a list computed from the
      provisioning layer's installed set; that asserts a capability the
      inventory does not show, which is the exact failure this epic's
      re-spec exists to stop. Fixing the list is safe for a stated reason:
      it seeds **directories**, not packages, so adding a package to the
      provisioning set needs no change here.
- [x] **R3** — **The reason is part of the requirement.** A GUI-launched
      WezTerm inherits launchd's minimal PATH
      (`/usr/bin:/bin:/usr/sbin:/sbin` — confirmed: `launchctl getenv PATH`
      is unset), which has no Homebrew, so the bare `nu` in `default_prog`
      cannot be found. This seeding only has to get the binary spawned;
      `env.nu` owns PATH from inside the shell, and nothing here duplicates
      that job.

      **The window does not die.** Corrected 2026-08-23 by the orchestrator:
      R1 and this requirement both said the window "dies immediately", and
      it does not. Measured — `wezterm-mux-server` under
      `env -i PATH=/usr/bin:/bin` with `default_prog = {"nu", …}` **creates
      the pane and keeps it**, showing
      `Unable to spawn nu because: / No viable candidates found in PATH
      "/usr/bin:/bin"`, then `didn't exit cleanly`. Neither config sets
      `exit_behavior`, and the default `CloseOnCleanExit` retains a pane
      whose process exited *un*cleanly. The requirement stands; the symptom
      is a dead pane you have to read, not a window that vanishes — which is
      worse to diagnose, not better. The gate asserts the pane still exists,
      so nobody can "correct" this back.
- [x] **R4** — **The same seeding is repeated inline in the F6 `sh -lc`**,
      for a related but *different* reason than R3's. One repetition, not
      two — the second subprocess was the wallpaper pipeline, dropped by open
      decision 5(a). The F6 binding itself is
      [`01-appearance`](../01-appearance/prd.md) R11's; cross-link it rather
      than restating it. **No code lands here:** the inline prefix arrived
      with `01-appearance` spec01 (line 201), so R4's work is a comment plus
      a gate assertion that it stays exactly one repetition.

      **What the prefix actually earns is not `nu`.** Corrected 2026-08-23
      by the orchestrator. `sh -lc` is a **login** shell, so `/etc/profile`
      runs `path_helper`, which reads `/etc/paths.d/homebrew` and puts
      `/opt/homebrew/bin` on PATH by itself. Measured:
      `env -i … sh -lc 'command -v nu; command -v tinty'` →
      `/opt/homebrew/bin/nu` found, `tinty` **NOT FOUND**. So the prefix
      earns `~/.local/bin` (where `tinty` lives), `~/.cargo/bin`, and
      `/opt/homebrew/sbin` — and `nu` would have resolved without it. The
      same wrong claim sits in
      [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md)
      ("where neither `nu` nor `tinty` resolves"), filed as
      [`terminal-inventory-path-claim`](../../00-delivery/corrections/terminal-inventory-path-claim/prd.md).
- [x] **R5** — **A terminal launch is unaffected**: no doubled or reordered
      entries that change which binary wins.

- [x] **R6** — **Nushell as `default_prog`, with both config files named.**
      `config.default_prog = { "nu", "--config",
      ~/.config/nushell/config.nu, "--env-config",
      ~/.config/nushell/env.nu }`.

      Without it a GUI launch falls back to the login shell, and on this
      machine **that is `zsh`, not `nu`** — so nushell never runs at all.
      `dscl . -read /Users/feb UserShell` → `/bin/zsh`, a GUI launch exports
      no `SHELL`, and a `default_prog`-less mux server was measured spawning
      `-zsh` (`cli list` title `zsh`). *Premise corrected 2026-08-23: this
      requirement first said the fallback was "plain `nu`" reading an
      undeployed `~/Library/Application Support/nushell/config.nu`. The truth
      is worse — not "the managed config does not load" but none of
      [`04-shell`](../../04-shell/prd.md) running, and no `help` at all.* That is the whole reason the
      corpus-path work
      ([`help-corpus-path-resolution`](../../00-delivery/corrections/help-corpus-path-resolution/prd.md))
      could not fix it from the `help.nu` side — `help.nu` is never sourced.
- [x] **R7** — **`XDG_CONFIG_HOME` is exported at launch.**
      `set_environment_variables.XDG_CONFIG_HOME = ~/.config`. `help` no
      longer needs it — the corpus is addressed by the same `~`-literal that
      sources it — but `$nu.default-config-dir` is read from the **launch**
      environment, and everything nushell derives from it moves without the
      export. Measured: with `--config` and no export, `$nu.history-path`
      resolves to `~/Library/Application Support/nushell/history.sqlite3`,
      so the history database silently leaves the managed tree.
      Cross-reference `history.nu`'s header, which records the same
      launch-time-constant lesson for that path.

## Acceptance
- [~] WezTerm launched from Finder opens a working shell rather than a pane
      holding `No viable candidates found in PATH`, and resolves `nu`,
      `nvim`, `tv` and `zoxide`.
- [x] The PATH in a GUI-launched session and in a terminal-launched session
      differ only by ordering that does not change which binary wins.
- [~] F6 works from a GUI-launched window, which is the check that the inline
      repetition in its subprocess is present.
- [~] A GUI-launched WezTerm comes up in **nushell** and renders this
      environment's manual. *Corrected 2026-08-23: the box said "not
      nushell's builtin welcome text", which describes a shape that does not
      occur — without R6 the pane is `zsh`, so the observable is the shell
      itself, not what `help` prints inside it.*
- [~] In that same window `$nu.default-config-dir` is `~/.config/nushell` and
      `$nu.history-path` sits under it, proving R7's export reached the
      launch environment rather than only `env.nu`.

**Why five boxes are `[~]` and not `[x]`, implemented 2026-08-23.** Every one
of them names a *GUI* launch as its observable, and the automated proof runs
through `wezterm-mux-server`, which spawns `default_prog` on the same mux code
path but is not the GUI: `wezterm.gui` is nil there, so the config loads
through a shim supplying only `wezterm.gui.default_key_tables()`, and
`window-config-reloaded` is a GUI event the mux server never emits, so the
nine-tab floor never runs and the probe sees one pane. What *was* executed, out
of `env -i PATH=/usr/bin:/bin`: the pane came up in nushell,
`$nu.default-config-dir` and `$nu.history-path` landed inside the managed tree,
`nu`, `nvim`, `tv` and `zoxide` all resolved under `/opt/homebrew/bin`, and
`help` rendered `Topics:` with its topic summaries — plus three
counterfactuals, each red for its own requirement. F6's own box stays `[~]`
because the automated stage proves only that `~/.local/bin` reaches the
subprocess's PATH; the observable is a colour change in a live window. The
residue is the three `T.7` rows the orchestrator adds to
`gates/manual/wave4.md`.

## Out of scope
- Anything about shell startup files. This is the launchd environment only;
  `env.nu` owns PATH inside the shell.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
