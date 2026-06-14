# Dotfiles

A Linux dev environment — native, inside WSL on Windows, or on macOS — managed
with [chezmoi](https://chezmoi.io). One command installs the tools and writes
every config into place.

## Components

- **WezTerm** — terminal (plain host; no multiplexing)
- **Zellij** — multiplexer (tabs/panes/sessions); auto-starts in the shell
- **Nushell** — shell
- **Neovim** — editor (Lua, lazy.nvim, LSP, Treesitter, Telescope)
- **Starship** — prompt
- **Git** — git + delta + lazygit + gh
- **CLI core** — ripgrep, fd, fzf, bat, eza, zoxide, jq
- **Television** — fuzzy finder (`tv`); interactive shell finder (Ctrl-R history,
  Ctrl-T autocomplete) and the `ff`/`fcd`/`fg` helpers
- **Theme** — Gruvbox Dark Hard everywhere, centralized in
  `home/.chezmoidata/theme.yaml`; edit once, `chezmoi apply`, all tools re-theme.
  For live switching, run **`theme`** (see below)

Run from a normal (non-admin) shell in your home directory.

## Install

One command. It installs chezmoi, then pulls and applies the dotfiles. Run it on
**Linux, WSL, or macOS**:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply yesitsfebreeze/.files
```

Already have chezmoi? Just `chezmoi init --apply yesitsfebreeze/.files`.

> **Windows:** there is no native Windows setup. Install WezTerm on Windows, then
> run the command above inside WSL Ubuntu (`wsl -d Ubuntu`). WezTerm boots straight
> into that WSL session, so everything you use lives in Linux.

## Commands

```sh
chezmoi update    # pull latest + re-apply
chezmoi apply     # re-apply current source
chezmoi diff      # preview pending changes
chezmoi cd        # enter source dir (exit returns)
```

## Theme switcher

`theme.yaml` sets the tracked default (Gruvbox Dark Hard). To change theme live,
without editing files:

```sh
theme             # fuzzy-pick from ~365 Gogh themes
```

Scroll to preview each theme system-wide (terminal + shell retint instantly via
[tinty](https://github.com/tinted-theming/tinty) OSC sequences); **Enter** applies
and persists it into new shells, **Esc** reverts to where you started. The Gogh
catalog is converted to base24 schemes on `chezmoi apply`; the live pick is
runtime state and never overrides the `theme.yaml` default in the source tree.

## Develop

```sh
git clone https://github.com/yesitsfebreeze/.files
chezmoi execute-template < home/<file>.tmpl   # render a template to check it
chezmoi apply --source <path-to-checkout>     # apply local WIP without pushing
git commit -am "..." && git push              # push; machines pick it up on update
```

Add/remove tools by editing `home/.chezmoidata/packages.yaml`; the next
`chezmoi apply` installs the difference.

## Keys

WezTerm leader `Ctrl-a`, Neovim leader `Space`. Full keymaps in
`home/dot_config/wezterm/wezterm.lua` and `home/dot_config/nvim/`.
