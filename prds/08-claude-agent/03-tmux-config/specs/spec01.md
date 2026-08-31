---
complexity: 14
footprint:
  - home/dot_config/tmux/tmux.conf
---

# spec01 — the tmux.conf section: extended-keys on, with the measured reason

Appends the section that makes Claude Code's Shift+Enter and notifications
work inside the `main` session: `set -s extended-keys on`, the
`set -as terminal-features 'xterm*:extkeys'` line the docs pair with it, and
the comment block that carries WHY appended `extended-keys` cannot disturb
the repo's kitty-protocol-off pairing. Two lines of code; the substance is
the measured reason.

**What already stands (built by the analyst, pass one).** The section IS
appended to `home/dot_config/tmux/tmux.conf` — the two option lines plus a
~45-line comment block recording the three measured facts the decision rests
on (probe/01, probe/02, probe/04). It loads stderr-clean, both options read
back, the append is proven to remove no earlier line, and the gate
(spec02/tests/tmux-claude-config.sh) is written and green against it. What
remains is only what a fresh implementer must be able to re-prove: the
boxes below, run against the tree as it lands, and any wording repair a
red box asks for.

The decision the PRD asked for, in one paragraph, as measured on tmux 3.7c
(Darwin 25.2.0, arm64): `extended-keys` governs only what tmux SENDS TO A
PANE THAT ASKED. A pane program that requested nothing — reedline, with
`use_kitty_protocol: false` — receives byte-identical input with the option
off and on (probe/01, all eight feature/request combinations). Modified keys
turn extended only after that pane enables modifyOtherKeys itself (mode 1
and mode 2 both measured in probe/04); the kitty protocol is not tracked per
pane at all — a pane pushing `CSI >1u` or flags 15 still gets plain `\r` —
so there is no path by which the line could re-arm what 04-shell/01 turned
off. With the option OFF, both extended Shift+Enter spellings fold to the
bare `\r` of plain Enter and Claude Code cannot distinguish newline from
submit, so the line is load-bearing for this epic's headline interaction.

## Acceptance

- [x] `tmux -L <probe-label> -f home/dot_config/tmux/tmux.conf new-session -d`
      exits 0 with empty stderr, and `show -sv extended-keys` answers `on`
      — run 2026-08-31: `rc=0`, `stderr-bytes=0`, `extended-keys` answered
      `on` (also PASS in gate `--options`: "the conf loads / …says nothing
      on stderr / extended-keys is on (got 'on')")
- [x] the loaded `terminal-features` list carries `xterm*:extkeys` exactly
      once (an `-as` append colliding with an earlier line would make it 2)
      — gate PASS "extkeys appears ONCE in the loaded feature list (got 1)"
- [x] `git diff -- home/dot_config/tmux/tmux.conf` removes no earlier line:
      the count of removed non-fence lines is 0 (this file's header contract)
      — gate PASS "git diff removes NO earlier line of tmux.conf (got 0)";
      diffstat independently reads "62 insertions(+)", 0 deletions
- [x] the comment block names all three measured facts and their probes:
      byte-identical input to a no-request pane, the modifyOtherKeys-only
      pane path, and the kitty protocol not tracked per pane — read in the
      appended section: probe/01 for the no-request pane, probe/04 for the
      mode-1/mode-2 path, probe/04 again for `CSI >1u`/flags 15 getting
      plain `\r`
- [x] `use_kitty_protocol: false` (home/dot_config/nushell/config.nu) and
      `enable_kitty_keyboard = false` (home/dot_config/wezterm/wezterm.lua)
      are still present, unedited — the pairing the decision was about
      — grep found them at config.nu:77 and wezterm.lua:123; gate PASS on
      both ("nushell still has use_kitty_protocol off", "wezterm still has
      enable_kitty_keyboard off")
- [x] the append names no key-table, status, palette or copy-mode line —
      the PRD's non-goals hold structurally, not just by intent
      — gate PASS "the append names no key-table/status/palette/copy line";
      the appended section read by eye is two option lines and comments

## Verify and Proof

```sh
# the options and the append-only property, against the shipped file
bash tests/tmux-claude-config.sh --options
# the measured reason, re-proven: what panes receive, by request and by option
bash prds/08-claude-agent/03-tmux-config/probe/01-what-the-pane-gets.sh
bash prds/08-claude-agent/03-tmux-config/probe/04-kitty-push.sh
```

Each probe prints its full matrix; the expected shape is in the probe
headers and in the tmux.conf comment block. A red box in `--options`
convicts the append; a changed matrix convicts a comment claim.