---
complexity: 18
footprint:
  - home/dot_config/tmux/tmux.conf
  - tests/tmux-status-bar.sh
---

# spec01 — the bar, and the gate that expands it

WezTerm's bar ported onto tmux (Q5 answer 2, narrowed by Q9): digit-only
window labels whose **colour** carries occupancy, the host on the left and
blank when local, the active pane's cwd beside an HH:MM clock on the right,
and the pane letters printed on the borders so Q3's index addressing stays
honest after a renumber.

## What the conf does

- `status-position top`, `status-interval 5` — the WezTerm tick. The clock is
  HH:MM, so a faster tick repaints the bar sixty times for one visible change.
- **Every colour is an ANSI slot, never a hex value.** `colour0` is base00 and
  `colour7` is base05 after tinted-shell's OSC 4, so the bar follows a `tinty
  apply` on any terminal that honours it. base02 has no ANSI slot; `colour8`
  stands in until `04-palette-delivery`'s `colors.conf` sets the exact style.
- **Occupancy** is `#{P:…}` over the window's panes emitting `X` for each pane
  whose command is not a shell, and `#{m:*X*,…}` asking whether any did — the
  port of wezterm.lua's `tab_is_occupied`. The membership test reads
  pattern-first and delimits with `|`, for the reason `02-key-tables` gives:
  `[` opens an fnmatch character class and the bracket form answers TRUE for
  `nushell` when asked about `nu`.
- **Background says focus, foreground says busy** — the same split wezterm.lua
  made, so the two signals never compete for one channel.
- **The left segment is decided once, at parse time**, from the SERVER's
  environment: a tmux started over ssh inherits `SSH_CONNECTION` and names its
  host; one started on this desk does not and draws nothing. tmux cannot see
  where the client is, so no format could decide this, and an `if-shell` per
  tick would be a process per five seconds.
- **The pane letter is derived from the index the key uses** —
  `#{a:#{e|+|:96,#{pane_index}}}` — not from a lookup table, which is what
  makes it correct the instant after tmux renumbers.
- **The border line follows the pane count** through a
  `window-layout-changed` hook: a one-pane window would otherwise spend a row
  of the grid saying `a` about the only pane there is.
- **T-9 holds.** The F5 legend was cut from the WezTerm bar as noise and does
  not return; the digits are the legend.

## Acceptance

- [x] `bash tests/tmux-status-bar.sh` exits 0, 28 PASS, no FAIL line.
- [x] Run twice it prints **byte-identical** output — no scratch path, pid or
      clock reading leaks into a line. (`diff -q` on two runs: identical.)
- [x] `bash tests/tmux-status-bar.sh --selftest` exits 0: each of M1–M5 breaks
      one mechanism against a copy of the real conf and the check that
      measures it goes red, and M6 convicts both lints on planted files.
- [x] Every reading goes through `#{E:…}`, the same expander the status line
      runs — not a `show -gv` of the unexpanded option, which would pass on a
      format tmux never renders.
- [x] Not one style option carries a hex value (`show -g` over the bar's
      options greps 0), and M5 proves that check can go red.
- [x] The occupancy tint is behavioural: an idle `/bin/sh` window reads
      `colour8`, the same window running `sleep` reads `colour7`, and a second
      idle pane does not un-light it.
- [x] Pane 1 prints `a` and pane 2 `b`; after `kill-pane` on pane 1 the
      survivor prints `a` — the label follows the KEY, not the content.
- [x] The border line is `off` at one pane, `top` at two, `off` again after a
      kill, through the hook and not through a poll.
- [x] The right segment carries the **active** pane's cwd (compared against
      that pane's own `#{pane_current_path}`, tilde-folded the same way) and an
      HH:MM clock; a pane at `$HOME` renders `~` and the expansion contains no
      `$HOME`.
- [x] Started with `SSH_CONNECTION` in the environment the left segment names
      the host and expands to a real hostname; started without it, it is empty.
- [x] No tmux server is left on the default socket after a run (`tmux ls`
      reads "no server running").

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/tmux-status-bar.sh
bash tests/tmux-status-bar.sh --options
bash tests/tmux-status-bar.sh --render
bash tests/tmux-status-bar.sh --selftest

# byte-identical twice
bash tests/tmux-status-bar.sh > /tmp/sb1.log 2>&1
bash tests/tmux-status-bar.sh > /tmp/sb2.log 2>&1
diff -q /tmp/sb1.log /tmp/sb2.log

# the default socket must be untouched
tmux ls > /tmp/sbls.$$ 2>&1 || true
grep -q 'no server running' /tmp/sbls.$$ || { cat /tmp/sbls.$$; exit 1; }
rm -f /tmp/sbls.$$
```

Run 2026-08-30: main rc 0 (28 PASS, 0 FAIL), `--selftest` rc 0 (14 PASS),
two runs byte-identical, default socket clean.
