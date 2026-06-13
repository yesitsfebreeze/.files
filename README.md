# Dotfiles

Cross-platform dev environment (Windows / macOS / Linux), managed with
[chezmoi](https://chezmoi.io). One command sets up everything:

- **WezTerm** — terminal, multiplexer, and session manager (no tmux)
- **Nushell** — shell
- **Neovim** — editor (Lua + lazy.nvim, LSP, Treesitter, Telescope)
- **Starship** prompt, **git + delta + lazygit + gh**
- CLI core: ripgrep, fd, fzf, bat, eza, zoxide, jq
- Theme: Catppuccin Mocha everywhere

## Install

**macOS / Linux**

```sh
curl -fsSL https://raw.githubusercontent.com/yesitsfebreeze/.files/main/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/yesitsfebreeze/.files/main/install.ps1 | iex
```

The installer clones the repo into `~/.files` (or `git pull`s it if already
present), then runs bootstrap: it installs chezmoi (and Homebrew on macOS if
missing), asks once for your git name + email, writes every config into place,
and installs all the tools. Then open WezTerm.

> Already have the repo checked out? Just run `./bootstrap.sh` (or
> `.\bootstrap.ps1`) from it — no re-clone needed.

## Day to day

```sh
chezmoi apply     # re-apply configs on this machine
chezmoi update    # git pull, then apply
chezmoi diff      # preview pending changes
```

Add or remove tools by editing `home/.chezmoidata/packages.yaml`; the next
`chezmoi apply` installs the difference.

## Keys

WezTerm leader is `Ctrl-a`, Neovim leader is `Space`. Full keymaps live in
`home/dot_config/wezterm/wezterm.lua` and `home/dot_config/nvim/`.
