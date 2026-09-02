---
complexity: 5
footprint:
  - home/dot_config/nushell/help/terminal.nuon
  - home/dot_config/nushell/help/manual/guide/copy.md
---

# spec02 — the widen cycle leaves the manual too

R3's second half, and R11. The `c` cell → word → line cycle and its
`@copy-cycle` option are already gone from `tmux.conf` — verified: a loaded
server lists no `c` in `copy-mode-vi`, and `v`, `V`, `y`, `Enter`, `C-c` and
`Escape` are all still bound. `terminal.nuon` has not caught up: three
entries still teach the cycle as a live gesture (`copymode`'s `use` and
`why`, and the F4 entry's `use`), and `manual/guide/copy.md` is generated
from them, so the deployed manual currently documents a key that does
nothing.

Read the finding in `report.md` under **`v` is not what R3 says it is**
before rewriting the `use` text: after the cut there is no keyboard
word-select at all. Say what the keys actually do now, not what R3 assumed.

`just manual` is the generator; it runs clean today and must be re-run after
the `.nuon` edit or the page stays stale.

## Acceptance

- [x] no entry in `home/dot_config/nushell/help/terminal.nuon` names the `c`
      widen cycle, the cell/word/line widening, or a hook that "clears the
      widen cycle"
- [x] the F4 and `copymode` entries describe the keys a loaded server
      actually binds in `copy-mode-vi`
- [x] `just manual` exits 0 and leaves no further diff when run twice
- [ ] `home/dot_config/nushell/help/manual/guide/copy.md` no longer says
      "widen", "each further `c`" or "widening"

## Verify and Proof

```sh
set -eu
cd /Users/feb/dev/dotfiles
! grep -nE 'widen|widening|each further .c.' home/dot_config/nushell/help/terminal.nuon
just manual
just manual
! grep -nE 'widen|widening|each further .c.' home/dot_config/nushell/help/manual/guide/copy.md
tmux -L specB kill-server 2>/dev/null || true
tmux -L specB -f home/dot_config/tmux/tmux.conf new-session -d
! tmux -L specB list-keys -T copy-mode-vi | grep -qE '^bind-key .* c +'
tmux -L specB kill-server
```
