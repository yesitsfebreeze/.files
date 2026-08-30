---
complexity: 14
footprint:
  - tests/tmux-copy-and-clipboard.sh
---

# spec02 — the gate: press the keys, read the wire, break every line

`tests/tmux-copy-and-clipboard.sh`, five stages, house dialect
(`. gates/lib.sh`, `chk`/`chk_ok`/`chk_fail`, `rc` accumulated, `/usr/bin/grep`
because bare `grep` here is a shell function over ugrep).

Two things separate it from a gate that greps the conf and calls that proof.
**It presses keys through a real dispatch** — an outer tmux whose pane runs
`tmux -L <inner> attach`, so `send-keys` to the outer pane arrives in the
inner tmux's key tables — because `list-keys` proves a binding is registered
and nothing about what it does, and `send-keys -X` drives the copy-mode
command while skipping the binding entirely. **And it reads the wire**: the
outer tmux's `pipe-pane -O` records every byte the inner client writes to
its terminal, which is where the OSC 52 is or is not.

Stages: `--load` (loaded option and key tables, plus the hook driven on both
entry paths), `--entry` (both extended-key spellings, and the negative that
plain `C-x` still reaches the pane), `--cycle` (the c-cycle including the
wrap), `--sink` (both arms, each asserting the sink that must fire **and**
the one that must not), `--selftest` (seven mutations). No argument runs the
first four.

Traps the gate is built around, each measured:

- **`script(1)` cannot read this wire.** `< /dev/null` forwards a `^D` that
  kills the pane and the server, and even with that fixed macOS `script`
  logged zero bytes — the buffer never reached disk. A lint in the file
  forbids `script` in command position.
- **`chk "label $(cmd)" $?` is a guaranteed false PASS.** `status_lint` is
  the widened form: `.*` spans quotes inside the substitution, because the
  narrow `[^"]*` version shipped green over `chk "x $(cmd "arg")" $?`.
- **The falsifying mutation for `set-clipboard` is `off`, not deletion.**
  tmux's default is `external` and `external` already emits OSC 52, so
  deleting the line leaves the wire check green.
- **`v` is not a stable reading.** On tmux 3.7c a server created by
  `new-session` prints `copy-mode-vi v` as `rectangle-toggle` and one created
  by `start-server` as `begin-selection`, reproducibly. The gate asserts
  `Space` and `V`, which read the same in every arrangement.
- **`v="$(cmd < file 2>/dev/null)"` cannot suppress a missing-file
  diagnostic**: the redirection is applied before the `2>/dev/null` beside
  it. Sink files are pre-created and read through `cat`.
- **A fixed sleep after `y` flakes.** The copy travels outer pane → inner
  client → inner server → a piped command; the gate polls for the sink file
  and settles before `y`, because a check that is empty one run in two is
  worse than a red one.

## Acceptance

- [x] `bash tests/tmux-copy-and-clipboard.sh` exits 0 and every line is PASS.
- [x] Run twice in a row it prints **byte-identical** output — no scratch
      path, no pid, no timing noise.
- [x] `bash tests/tmux-copy-and-clipboard.sh --selftest` exits 0, and each of
      its seven mutations is the failure the line guards, not a deletion
      tmux's own default repairs:
      **A** no `jump-to-mark` → press 4 lands off the anchor;
      **B** the sink branch forced to OSC 52 → `pbcopy` receives nothing;
      **C** `set-clipboard on` on the local arm → an OSC 52 goes out beside
      `pbcopy`;
      **D** no `after-copy-mode` hook → the toggle survives an exit by `q`;
      **E** no `mode-keys` line under `EDITOR=emacs` → `mode-keys` reads
      `emacs`;
      **F** `set -pu` moved above the copy → the buffer is set and the OSC 52
      is gone;
      **G** all three linters convict a planted counterfactual and pass a
      clean file.
- [x] Every `tmux` call in the script is `-L`-labelled and every label is
      killed; after a full run `tmux ls` reports no server on the **default**
      socket.
- [x] The stub-PATH arm is proven to be a real stub: `command -v pbcopy`
      under it fails.
- [x] No box in this gate asserts that `gates/selftest.sh` exits 0. That is a
      whole-workspace command, it is red for reasons this node did not cause,
      and no `07-multiplexer` node carries a `task:` id, so this script cannot
      be registered in `gates/waves.tsv` from inside this node.

## Verify and Proof

```sh
bash tests/tmux-copy-and-clipboard.sh
bash tests/tmux-copy-and-clipboard.sh > /tmp/r1 2>&1; bash tests/tmux-copy-and-clipboard.sh > /tmp/r2 2>&1; diff /tmp/r1 /tmp/r2
bash tests/tmux-copy-and-clipboard.sh --selftest
tmux ls
```
