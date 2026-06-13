# Dotfiles

Cross-platform dev environment (Windows / macOS / Linux), managed with
[chezmoi](https://chezmoi.io). One command sets up everything:

- **WezTerm** — terminal, multiplexer, and session manager (no tmux)
- **Nushell** — shell
- **Neovim** — editor (Lua + lazy.nvim, LSP, Treesitter, Telescope)
- **Starship** prompt, **git + delta + lazygit + gh**
- CLI core: ripgrep, fd, fzf, bat, eza, zoxide, jq
- Theme: Gruvbox Dark Hard everywhere, with a blinking block cursor. Centralized
  in `home/.chezmoidata/theme.yaml` — change palette/theme/cursor in one place,
  run `chezmoi apply`, and every tool re-themes together.

## Install

One `chezmoi init --apply` clones this repo, prompts once for your git name +
email, writes every config into place, and installs all the tools (Homebrew is
bootstrapped on macOS first). Run it from a **normal (non-admin) shell in your
home directory** — the dotfiles install per-user. Then open WezTerm.

**Windows (PowerShell)** — installs chezmoi via winget (puts it on PATH), then applies:

```powershell
winget install twpayne.chezmoi          # or: scoop install chezmoi
chezmoi init --apply yesitsfebreeze/.files
```

**macOS / Linux** — no prerequisites; installs chezmoi to `~/.local/bin`, then applies:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply yesitsfebreeze/.files
```

chezmoi clones the repo into its own source dir (`~/.local/share/chezmoi`) and
tracks this GitHub remote, so updates are a single command — no checkout to
manage yourself.

> Already have chezmoi installed (winget/scoop/brew)? Just run
> `chezmoi init --apply yesitsfebreeze/.files`. Avoid running it from an
> elevated shell or `C:\Windows\System32`.

## Update

```sh
chezmoi update    # git pull this repo, then re-apply
```

That is the whole update story: `chezmoi update` pulls the latest commit from
GitHub and applies the difference. Other day-to-day commands:

```sh
chezmoi apply     # re-apply the current source without pulling
chezmoi diff      # preview pending changes
chezmoi cd        # drop into the source dir; exit returns you back
```

Add or remove tools by editing `home/.chezmoidata/packages.yaml`; the next
`chezmoi apply` installs the difference.

## Develop

To change the dotfiles, edit this repo and push — every machine picks it up on
the next `chezmoi update`:

```sh
git clone https://github.com/yesitsfebreeze/.files
# edit files under home/, then:
chezmoi execute-template < home/<file>.tmpl   # render a template to check it
git commit -am "..." && git push
```

Apply work-in-progress straight from a local checkout without pushing:

```sh
chezmoi apply --source <path-to-checkout>
```

## Keys

WezTerm leader is `Ctrl-a`, Neovim leader is `Space`. Full keymaps live in
`home/dot_config/wezterm/wezterm.lua` and `home/dot_config/nvim/`.
