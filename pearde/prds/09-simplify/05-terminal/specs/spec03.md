---
complexity: 9
footprint:
  - home/dot_config/tinted-theming/tinty/config.toml
  - home/dot_config/tinted-theming/tinty/executable_tmux-colors.sh
---

# spec03 — one palette path, and the desk proves the whole cut

R10's tail, plus every acceptance box this PRD has that only a real desk can
answer. The files are already cut: `tinty/config.toml` is 13 lines (10 of
code, 3 of comment) from 33, `tmux-colors.sh` 140 from 170 with the base24
fallbacks, `display-panes-*`, `@scheme` and the `colors.lua` sentence gone,
and `config.nu`'s re-assert block is replaced by a four-line reason saying
the tty push and the `client-attached` hook already cover a new pane.

That reason is a claim, and it has not been tested. Test it, and if a pane
opened after `theme` is NOT tinted, put the block back with the one line
above it that R10 asks for.

Then deploy and press the keys. `chezmoi apply` must be scoped: the tree
carries a sibling PRD's neovim and television work and a bare apply would
ship it.

## Acceptance

- [x] `chezmoi apply` scoped to this PRD's files exits 0 and the deployed
      `~/.config/tmux/tmux.conf` matches the source
- [x] after `tmux source ~/.config/tmux/tmux.conf`: F3 prompts, Escape
      cancels with nothing on screen, a query opens the picker
- [x] F4 then an arrow splits with the cwd inherited; `F5 2` selects window
      2 and `F5 b` pane b
- [ ] F6 retints two attached windows and a pane opened after the toggle —
      with `config.nu`'s re-assert block still absent
- [ ] drag-select in a pane, then `pbpaste` prints the selection
- [ ] a fresh WezTerm window attaches to `main`, and shift-click on a URL
      opens it
- [x] `wc -l home/dot_local/bin/executable_tv-all` is at most 500

## Verify and Proof

```sh
set -eu
cd /Users/feb/dev/dotfiles
test "$(wc -l < home/dot_local/bin/executable_tv-all)" -le 500
! grep -nE 'base24|display-panes-|@scheme|colors\.lua' home/dot_config/tinted-theming/tinty/executable_tmux-colors.sh
chezmoi apply --dry-run --verbose \
  ~/.config/tmux/tmux.conf ~/.config/wezterm/wezterm.lua \
  ~/.config/tinted-theming/tinty ~/.local/bin/tv-all ~/.local/bin/tmux-main
chezmoi apply \
  ~/.config/tmux/tmux.conf ~/.config/wezterm/wezterm.lua \
  ~/.config/tinted-theming/tinty ~/.local/bin/tv-all ~/.local/bin/tmux-main
cmp home/dot_config/tmux/tmux.conf ~/.config/tmux/tmux.conf
tmux source ~/.config/tmux/tmux.conf
# the interactive half — F3/F4/F5/F6, the drag-select, the WezTerm window —
# is pressed by hand and the result written into the boxes above.
```
