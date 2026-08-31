---
complexity: 16
footprint:
  - install.sh
  - home/dot_config/tmux/tmux.conf
  - tests/tmux-persistence.sh
---

# spec01 — resurrect and continuum, cloned not tpm'd

Q7, Q11, Q12. `install.sh` clones the two repos to
`$XDG_DATA_HOME/tmux/plugins`; `tmux.conf` runs each with one `run-shell`.
No tpm: it exists to install and update plugins and to give a config a place
to declare them, and chezmoi plus `install.sh` already do the first two while
two lines do the third.

## The three things that had to be measured

- **`run-shell '<sh>'`, not `if-shell '<test>' 'run-shell "<path>"'`.** The
  natural spelling **loads silently and runs nothing**: `run-shell`'s argument
  is a tmux command string, so tmux expands `${…}` on it first, has no `:-`
  default form, the expansion fails, `if-shell` swallows the error, and the
  plugin never starts with no message anywhere. Inside `run-shell '<sh>'` the
  whole string goes to `/bin/sh` and the expansion is the shell's. Measured on
  3.7c, 2026-08-30.
- **The `-x` guard is worth less than it looks, and the comment says so.**
  Without it, `run-shell` on a missing file produces no error on stderr and
  none in `show-messages`. It buys intent and a shell not spawned, not a
  rescued config. An unprovisioned machine gets a fully working tmux either
  way, minus persistence — the honest degradation.
- **Continuum goes last**, because its init reads the `@continuum-*` options
  and schedules the save loop; anything set after it is not seen by the loop
  it started.

## What comes back (Q12)

Layout, cwds, and nvim **through persistence.nvim**, using resurrect's inline
strategy — `@resurrect-processes '"~nvim->nvim -c …persistence…load()"'`,
06-nvim-session's published interface, carried verbatim.
`@resurrect-strategy-nvim 'session'` is deliberately **not** set: it restores
with `nvim -S` only when a literal `Session.vim` sits in the pane's cwd, which
would mean an untracked file in every working tree the editor was opened in.
Pane contents are not captured — a screenshot of every scrollback on disk,
growing without bound, for no gain.

## Acceptance

- [x] `bash tests/tmux-persistence.sh` exits 0, 32 PASS, no FAIL.
- [x] `--selftest` exits 0: M1 (continuum moved above resurrect) breaks the
      ordering check, M2 (the plugin path drifted off `$XDG_DATA_HOME`) stops
      both plugins running, M3 shows the strategy option is visible when set,
      M4 catches a drifted clone root in `install.sh`.
- [x] Options load as specified: `@resurrect-dir` under `~/.local/state`,
      save interval 15, restore `on`, capture-pane-contents `off`, the nvim
      inline strategy present and naming `persistence`, and
      `@resurrect-strategy-nvim` **unset**.
- [x] With an empty `XDG_DATA_HOME` the conf loads, stderr is empty, and the
      key tables are still there (jump has ≥ 19 keys).
- [x] With stub plugins both `run-shell`s fire and continuum's fires **last**.
- [x] `INSTALL_DRY_RUN=1 sh install.sh` names both clones; `install.sh`'s
      clone root and both of `tmux.conf`'s read paths are the same expression;
      neither file mentions tpm outside a comment.
- [x] Against the **real** plugins: a save driven through `run-shell` writes a
      state file naming both windows and recording the pane's cwd.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/tmux-persistence.sh
bash tests/tmux-persistence.sh --selftest
tmux ls 2>&1 | grep -q 'no server running'
```

Run 2026-08-30: rc 0 (32 PASS), `--selftest` rc 0, default socket clean. The
plugins were cloned to `~/.local/share/tmux/plugins` so `--live` had something
real to read.
