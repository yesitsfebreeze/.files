---
complexity: 20
footprint:
  - tests/tmux-key-tables.sh
---

# spec02 — `tests/tmux-key-tables.sh`, the gate that presses the keys

Three stages plus a lint. `--tables` reads the **loaded** key tables out of a
headless `tmux -L <label> -f <conf> new-session -d`; `--keys` drives the same
bindings through **real key dispatch** in a nested tmux; `--selftest` proves
every stage by breaking the thing it measures. No argument runs the first two,
byte-identically twice in a row.

Both reading stages exist because they are different claims. `list-keys` says
a binding **parsed**; it says nothing about what tmux does when the key
arrives, and `send-keys` to the inner pane writes to the shell's pty and tests
nothing at all. Only a keystroke delivered to a pane that is running an
attached client reaches the inner tmux's dispatch.

**Five rules the fixture must obey, four inherited and one new:**

1. Every `tmux` call carries `-L <label>` and every label is killed — enforced
   by `tmux_lint` on this file and by an EXIT trap.
2. No `chk "label $(cmd)" $?`. Take `st=$?` first. `status_lint`'s current
   regex (`.*` spanning inner quotes) is the one to copy.
3. The fixture's session path, the active pane's cwd and `$HOME` are three
   different directories, or the digit's `-c ~` and tmux's own key-binding
   default become one answer and the Q14 check cannot fail.
4. **Never put a bare `Escape` immediately before a function key.** A lone
   Escape delivered to an attached tmux client makes the next escape-sequence
   key arrive as literal bytes — reproduced against a conf whose only line is
   `bind -n F5 new-window`, so it is nothing of this node and it will fail a
   correct conf. `escape_lint` enforces it.
5. Byte assertions on the pty need a trailing `Enter`: the pty is in canonical
   mode and nothing appears until a newline. The first probe read "nothing
   received" for every arm and would have concluded the forwarding was broken.

The forwarded keys are `033 [ 1 5 ~` for F5 and **`033 O S`** for F4 — xterm
puts F1-F4 on SS3 and F5 upward on CSI, so a gate expecting `033[14~` fails a
correct implementation.

Each `--selftest` mutant is derived from the **real** conf, never from the
previous mutant. Chaining them silently cancelled a mutation during this
build: M3 removes the jump forwarder, so an M5 built on M3 held 18+1 = exactly
the 19 keys its check demanded and reported green while carrying the defect it
was planting.

## Acceptance

- [x] `bash tests/tmux-key-tables.sh` exits 0 with no `FAIL` line, and two
      consecutive runs are byte-identical — no scratch path reaches the output
- [x] `--tables` covers every structural acceptance box of spec01, reading
      `list-keys -T <table>` rather than grepping the conf's bytes
- [x] `--keys` drives F5-digit create/select, the two disagreeing cwd rules,
      the pane letters, four mistypes cancelling, the zero-byte pty assertion,
      both double-taps as bytes, and F6 end to end under a scratch `$HOME`
- [x] `bash tests/tmux-key-tables.sh --selftest` exits 0, and each mutation
      goes red for the check it targets: the glob-class delimiter (M1), the
      digit's `-c ~` removed (M2), the jump forwarder removed (M3), the
      split's `-c` removed (M4), a re-added bare-cancel letter bind (M5), a
      forwarded F6 (M6), the three lints on planted counterfactuals (M7), and
      F6's payload pointed at a missing file (M8)
- [x] M1 is proved **behavioural**, not cosmetic: on a session whose only
      window is 11, the glob-class form still answers "window 1 exists"
- [x] every mutant is copied from the real conf, so no mutation can be
      cancelled by an earlier one
- [x] no tmux server is left on the default socket after a run, and
      `tests/tmux-session-and-windows.sh` still exits 0 with output unchanged
      from before this node's append

## Verify and Proof

```sh
bash tests/tmux-key-tables.sh
bash tests/tmux-key-tables.sh --selftest
bash tests/tmux-session-and-windows.sh
```
