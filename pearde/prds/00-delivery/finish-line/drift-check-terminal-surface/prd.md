---
state: done       
priority: 4
est: 1.5h
mode: afk
needs:
  - 06-help/04-drift-check
verify: "help --check exits 0 with the terminal surface enabled"
origin: requested
from: 00-delivery/finish-line
---

# The deferred third surface — `help --check` against WezTerm

Parent: [Finish line](../prd.md) · net-new

Purpose: [`06-help/04-drift-check`](../../../06-help/04-drift-check/prd.md)
R3 — introspect the terminal via `wezterm show-keys --lua`, plus `--key-table`
for the F5 jump table. Answer 1 of the [finish-line round](../prd.md) cut it
from the first build so `help --check` could ship for the two surfaces that
carry most of the manual. **Deferred, not cancelled**, and this node is where
that promise is kept.

Why this was the surface to cut, recorded so the choice is auditable: the
terminal check has a blind spot the board already measured. `Ctrl+Shift+T`
resolves against WezTerm's **own** `SpawnTab` default, so its drift check
passes whether or not a capsule binding is ever written — named as a blind
spot in [`coverage`](../../../06-help/01-content-model/coverage/prd.md) R3.
A check that passes for the wrong reason is the least valuable third.

## Requirements
- [x] **R1** — `help --check` grows the terminal surface: `wezterm show-keys
      --lua` for the top-level bindings, `--key-table` for the F5 jump table
      ([`02-terminal/03`](../../../02-terminal/03-f5-jump-mode/prd.md)).
- [x] **R2** — The `Ctrl+Shift+T` blind spot is closed or recorded as
      unclosable: a binding that matches a WezTerm default must be
      distinguishable from one this config actually sets, or the check must
      say it cannot tell.
- [x] **R3** — `coverage` R3 and R5's terminal half close against this, which
      is the reason the node exists.
- [x] **R4** — R8 of the parent still holds: `--check` spawns wezterm, plain
      `help` never does.

## Delivered 2026-08-30, and larger than the promise

The deferred third surface landed as **two** surfaces, because the terminal
became two programs in between: `07-multiplexer` moved windows, panes, copy
and the palette to tmux, and left WezTerm three keys.

- **R1** — `help --check` reads BOTH. `kind: "tmux-key"` resolves against
  `tmux -L <label> list-keys -T <table>` (142 live keys, four tables) and
  `kind: "wezterm-key"` against `wezterm show-keys --lua` (86). The F5 jump
  table this requirement singled out is now a tmux key table and is read like
  any other — `--key-table` was a WezTerm concept and does not survive, which
  is a better outcome than implementing it.
- **R2** — **the blind spot is closed, not recorded as unclosable.** It was
  never really about `Ctrl+Shift+T`: it was that WezTerm ships a full set of
  window and pane bindings, so a documented key could resolve against a
  default nobody wrote. `config.disable_default_key_bindings = true`
  ([`07-multiplexer/08-wezterm-reduction`](../../../07-multiplexer/08-wezterm-reduction/prd.md))
  removes every default, so the loaded table contains only what this file
  sets. Measured: `ActivateTab` appears 46 times in WezTerm's stock table and
  **0** times in ours. `Ctrl+Shift+T` itself is now `Ctrl+Shift+O` and there
  is no `SpawnTab` for it to hide behind.
- **R3** — [`coverage`](../../../06-help/01-content-model/coverage/prd.md) is
  `done`, closed on this.
- **R4** — plain `help` still spawns nothing: `bash tests/shell-help.sh`
  (rc 0) greps `help.nu` with `_help_browse` excised and asserts it is the
  only def naming a spawn target. Every line that spawns is in
  `help-check.nu`, which is why the two files are separate at all.

## Acceptance
- [x] Deleting a documented terminal binding is reported as stale.

      `bash tests/help-drift-check.sh --terminal`, mutation 1: `F4 Right`
      removed from the conf → `Right in table 'split' is not bound by
      tmux.conf`. Mutation 3 does the same on the WezTerm side.
- [x] Adding an undocumented one is reported and exits non-zero.

      Mutation 2: a key added to the `jump` table → `undocumented`. The
      reverse direction runs over the tables this config OWNS (`jump`,
      `split`) and deliberately not over `root` or `copy-mode-vi`, which are
      tmux's own and full of shipped defaults — the same noise this node's
      blind spot was a case of.
- [x] A binding that exists only as a WezTerm default is either reported
      correctly or explicitly listed as indistinguishable, with the
      measurement.

      **Reported correctly, because it can no longer exist.** And the guard
      against the failure mode it implies is an ABSENCE, not a presence: if
      `show-keys` ever returns a table containing `ActivateTab`, the config
      failed to load and WezTerm fell back to its defaults, so the checker
      RAISES instead of reporting three stale keys. Asserting "one of our
      bindings is present" was tried first and convicted a legitimate
      finding — unbind the key the guard names and the checker blames the
      config instead of reporting the entry stale. Mutation 4 proves the
      raise.

## Out of scope
- The shell and Neovim surfaces; the parent owns those and ships first.
