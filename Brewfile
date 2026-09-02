# Every formula and cask this machine needs. `brew bundle` installs the set;
# install.sh runs it. Order is alphabetical within each group.

tap "tinted-theming/tinted"

# shell, prompt, navigation
brew "nushell"
brew "starship"
brew "zoxide"
brew "television"
brew "tinted-theming/tinted/tinty"

# editor and its formatters — conform.nvim names these by binary, and a
# configured-but-absent formatter is SILENT behind lsp_format = "fallback".
brew "neovim"
brew "black"
brew "prettier"
brew "rust"       # rustfmt ships with it and has no formula of its own
brew "stylua"

# core CLI
brew "bat"
brew "eza"
brew "fd"
brew "git"
brew "git-delta"
brew "jq"
brew "ripgrep"
brew "tmux"

# fzf is zoxide's interactive picker (zi/cdi), not a picker to reach for.
brew "fzf"

# git, containers, tasks, secrets
brew "chezmoi"
brew "docker"     # the CLI formula; the daemon is a separate, deliberate choice
brew "gh"
brew "gnupg"
brew "just"
brew "lazygit"
brew "pass"

cask "font-caskaydia-cove-nerd-font"
