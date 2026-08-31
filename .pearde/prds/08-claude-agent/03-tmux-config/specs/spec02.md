---
complexity: 14
footprint:
  - tests/tmux-claude-config.sh
---

# spec02 — the gate: the docs' lines load, and the pairing survives them

The node's gate, `tests/tmux-claude-config.sh`, in the house dialect of
`gates/lib.sh` (`chk`, `-L`-labelled tmux with an EXIT-trap kill, lints on
this file itself). It proves the two things this node can owe: the conf
carries the docs' two lines as an append, and the append does what the
decision says — nothing at all to a pane that never asked, whole extended
keys to one that asked, legacy bytes beside them.

**What already stands (built by the analyst, pass one).** The gate is
written and green: `--options` 9 checks, `--bytes` 7 checks, `--selftest`
11 checks, 0 FAIL, rc 0, no-arg run byte-identical across consecutive runs.
Stages:

- **--options** loads the shipped conf into an isolated `-L` server:
  `extended-keys on`, the once-only `xterm*:extkeys` feature, the
  append-only diff check, the two kitty-off lines next door, and the
  structural non-goal check.
- **--bytes** is the point of the gate. Through the nested pty fixture
  (the F14/F15 shape of 01-session-and-windows), a collector pane receives
  real keystrokes under four arms: extended-keys on and off, each with and
  without a modifyOtherKeys mode-1 request on the pane's tty. The arms
  assert: a no-request pane gets BYTE-IDENTICAL input either way (the
  nushell pairing, undisturbed); both Shift+Enter spellings fold to bare
  `\r` for it; a requesting pane receives `CSI 27;2;13~` and keeps
  arrow-up and Ctrl+X legacy in the same stream; and with the option OFF
  the mode-1 request buys nothing — the docs' line is load-bearing.
- **--selftest** breaks each stage against scratch copies: extended-keys
  off (M1), the feature line deleted (M2), an earlier section edited (M3,
  the append-only conviction), and both lints (M4).

What remains: the implementer runs the boxes below, quotes the counts, and
repairs any red they meet on the machine the work lands on.

## Acceptance

- [x] `bash tests/tmux-claude-config.sh` exits 0 with 16 PASS, 0 FAIL, and
      two consecutive no-arg runs are byte-identical (labels are killed, so
      no run depends on a previous run's sockets)
      — run 2026-08-31: rc 0, 0 FAIL lines, 16 stage PASS (plus the shared
      PASS "precondition", 17 PASS lines total); `/tmp/g1.txt` vs
      `/tmp/g2.txt` from two consecutive no-arg runs diffed IDENTICAL
- [x] `bash tests/tmux-claude-config.sh --selftest` exits 0 with 12 PASS,
      0 FAIL — every stage proven by breaking it
      — run 2026-08-31: rc 0, 11 stage PASS (M1 ×2, M2 ×3, M3 ×3, M4 ×3)
      plus the shared PRECONDITION, 12 PASS lines total, 0 FAIL
- [x] the --bytes stage's arm B (off vs on to a no-request pane) really
      compares two byte streams and can fail: it is the pairing proof, not
      an option read — arm B is `[ "$a" = "$b" ]` over two od dumps of two
      independent nested-fixture runs ($D/on-none vs $D/off-none); the same
      comparison proven live to return rc 1 on differing streams and rc 0 on
      identical ones, so a tmux that changed what a neutral pane receives
      turns it red
- [x] every tmux call in the gate carries `-L` and the lint that enforces it
      is itself proven red by M4 — the gate's own tmux_lint over the file
      counts 0 unlabelled calls, and "--selftest M4: tmux_lint convicts an
      unlabelled tmux call" PASSed (a `tmux new-session -d` scratch file
      convicted); "both lints stay green on this file" PASSed

## Verify and Proof

```sh
bash tests/tmux-claude-config.sh
bash tests/tmux-claude-config.sh --selftest
# two consecutive no-arg runs must print identical output
bash tests/tmux-claude-config.sh > /tmp/g1.txt 2>&1
bash tests/tmux-claude-config.sh > /tmp/g2.txt 2>&1
diff /tmp/g1.txt /tmp/g2.txt
```