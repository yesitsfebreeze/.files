# Dotfiles

A Linux dev environment — native on Linux or macOS — managed
with [chezmoi](https://chezmoi.io). One command installs the tools and writes
every config into place.

## Components

- **WezTerm** — terminal (plain host; no multiplexing)
- **burrito** — multiplexer (daemon-backed sessions, 9×9 grid navigation, tool
  overlays); auto-starts in the shell
- **Nushell** — shell
- **Neovim** — editor (Lua, lazy.nvim, LSP, Treesitter, Telescope)
- **Starship** — prompt
- **Git** — git + delta + lazygit + gh
- **pass** — password manager (GPG-backed `password-store`), with Nushell
  completion for subcommands and entry names. One-time setup below
- **CLI core** — ripgrep, fd, fzf, bat, zoxide, jq
- **Television** — fuzzy finder (`tv`); interactive shell finder (Ctrl-R history,
  Ctrl-T autocomplete) and the `ff`/`fcd`/`fg` helpers
- **Theme** — Gruvbox Dark Hard (static, via WezTerm's builtin scheme and
  tinted-nvim)

Run from a normal (non-admin) shell in your home directory.

## Install

Two steps: install the tools, then apply the configs. Run on **Linux or macOS**:

```sh
# 1. Install chezmoi and pull the repo
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init yesitsfebreeze/.files

# 2. Install tools + apply configs
cd ~/.local/share/chezmoi && ./install.sh
```

`install.sh` is a plain, idempotent script: package-manager batch install
(Homebrew on macOS, apt/pacman/dnf on Linux), a few GitHub-release/cargo/npm
fallbacks, and the small system tweaks (macOS menu-bar auto-hide, sudo PATH).
It ends by running `chezmoi apply` to write the configs.

> **Linux requirement:** the Claude CLI needs `bubblewrap` (`bwrap`) for
> subprocess sandboxing. It is installed automatically with the package set; on
> macOS the built-in Seatbelt sandbox is used instead, so no extra package.

## Commands

```sh
chezmoi update    # pull latest + re-apply
chezmoi apply     # re-apply current source
chezmoi diff      # preview pending changes
chezmoi cd        # enter source dir (exit returns)
```

**Finding the repo:** Use `chezmoi source-path` to locate your local .files directory.
It is usually cloned to `~/.local/share/chezmoi`, but you can verify with that command
or navigate directly via `chezmoi cd`.

## Password manager

[`pass`](https://www.passwordstore.org/) stores each secret as a GPG-encrypted
file under `~/.password-store`. Installing the tool does **not** create the store
— that is a one-time step tied to your GPG key, so `chezmoi apply` prints a
reminder pointing here until it is done. The store itself is private and lives in
your home dir; it is never tracked by these dotfiles.

Set it up once per machine:

```sh
# 1. Need a GPG key? Create one (skip if `gpg --list-secret-keys` already lists one).
gpg --full-generate-key

# 2. Find the key's id (or use the email you gave it).
gpg --list-secret-keys --keyid-format=long

# 3. Initialise the store for that key. This writes ~/.password-store/.gpg-id.
pass init <gpg-id-or-email>

# 4. (Optional) version the store with git, then add your own private remote.
pass git init
```

Daily use:

```sh
pass insert email/personal     # add a secret (prompts; nested paths allowed)
pass generate email/personal 24  # create a random 24-char password
pass                           # list the store as a tree
pass show email/personal       # print a secret
pass -c email/personal         # copy it to the clipboard (clears after ~45s)
pass edit email/personal       # edit in $EDITOR
pass rm email/personal         # remove
```

`PASSWORD_STORE_DIR` is pinned to the default in `env.nu`; change it there to
relocate the store. Nushell tab-completion offers the subcommands and your live
entry names (sourced from `pass.nu`).

## pi extensions

`install.sh` installs the `pi` binary (npm) and its npm-published extensions
(`pi-mcp-adapter`, `pi-claude-bridge`). The extension workspace
(`~/dev/_pi_extensions`, one git repo per package) is not auto-installed — set
it up once per machine:

```sh
pi install npm:pi-mcp-adapter npm:@vanillagreen/pi-claude-bridge
mkdir -p ~/dev/_pi_extensions
# clone each pi-* package repo you use into ~/dev/_pi_extensions/
```

## Develop

```sh
git clone https://github.com/yesitsfebreeze/.files
chezmoi apply --source <path-to-checkout>     # apply local WIP without pushing
git commit -am "..." && git push              # push; machines pick it up on update
```

Add/remove tools by editing the package lists in `install.sh`; the next run
installs the difference.

## Keys

burrito leader `Ctrl-Space` (tap twice for the grid navigator), Neovim leader
`Space`. WezTerm itself is a plain host — only clipboard shortcuts (`Ctrl-V`
paste, `Ctrl-C` smart copy/interrupt), no leader. Full keymaps in
`home/dot_config/burrito/config.toml` and `home/dot_config/nvim/`.
