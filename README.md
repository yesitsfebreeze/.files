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

One command installs [chezmoi](https://chezmoi.io), clones this repo, and applies
everything. chezmoi prompts once for your git name + email, writes every config
into place, and installs all the tools (Homebrew is bootstrapped on macOS first).
Then open WezTerm.

**macOS / Linux**

```sh
sh -c "$(curl -fsSL https://get.chezmoi.io)" -- init --apply yesitsfebreeze/.files
```

**Windows (PowerShell)** — needs winget or scoop for the tool installs:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply yesitsfebreeze/.files"
```

chezmoi clones the repo into its own source dir (`~/.local/share/chezmoi`) and
tracks this GitHub remote, so updates are a single command — no checkout to
manage yourself.

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
