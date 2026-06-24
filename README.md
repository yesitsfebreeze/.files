# Dotfiles

A Linux dev environment — native, inside WSL on Windows, or on macOS — managed
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
- **Theme** — Gruvbox Dark Hard, live-switchable via
  [tinty](https://github.com/tinted-theming/tinty) (base16). The terminal palette
  and Neovim follow your pick; ANSI-aware tools (Starship, lazygit, delta) ride the
  terminal palette; bat, Television, and WezTerm ship the gruvbox theme themselves.
  Switch live with **`theme`** (see below)

Run from a normal (non-admin) shell in your home directory.

## Install

One command. It installs chezmoi, then pulls and applies the dotfiles. Run it on
**Linux, WSL, or macOS**:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply yesitsfebreeze/.files
```

Already have chezmoi? Just `chezmoi init --apply yesitsfebreeze/.files`.

> **Linux requirement:** the Claude CLI needs `bubblewrap` (`bwrap`) for
> subprocess sandboxing. It is installed automatically with the package set; on
> macOS the built-in Seatbelt sandbox is used instead, so no extra package.

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

**Finding the repo:** Use `chezmoi source-path` to locate your local .files directory.
It is usually cloned to `~/.local/share/chezmoi`, but you can verify with that command
or navigate directly via `chezmoi cd`.

## Theme switcher

Each tool ships the Gruvbox Dark Hard default — builtin themes (bat, Television,
WezTerm) or ANSI colors that ride the terminal palette (Starship, lazygit, delta).
To change theme live, without editing files:

```sh
theme             # fuzzy-pick from tinty's official base16/base24 catalog
```

Scroll to preview each theme (terminal + shell retint via
[tinty](https://github.com/tinted-theming/tinty) OSC sequences); **Enter** applies
and persists it into new shells, **Esc** reverts to where you started. The picker
lists tinty's prebuilt tinted-shell schemes (~314 base16 + ~187 base24), so every
entry applies cleanly; the live pick is runtime state, layered on top of each
tool's gruvbox default.

Known limit: inside burrito, live palette passthrough to WezTerm depends on the
multiplexer (the OSC retint may be intercepted by the mux before WezTerm sees it).

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

burrito leader `Ctrl-Space` (tap twice for the grid navigator), Neovim leader
`Space`. WezTerm itself is a plain host — only clipboard shortcuts (`Ctrl-V`
paste, `Ctrl-C` smart copy/interrupt), no leader. Full keymaps in
`home/dot_config/burrito/config.toml` and `home/dot_config/nvim/`.
