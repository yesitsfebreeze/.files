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
git clone https://github.com/yesitsfebreeze/.files.git ~/.files && ~/.files/bootstrap.sh
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/yesitsfebreeze/.files.git "$HOME\.files"; & "$HOME\.files\bootstrap.ps1"
```

That installs chezmoi (and Homebrew on macOS if missing), asks once for your git
name + email, writes every config into place, and installs all the tools. Then
open WezTerm.

> Already have the repo checked out? Just run `setup/bootstrap.sh` (or
> `setup\bootstrap.ps1`) from it — no re-clone needed.

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
