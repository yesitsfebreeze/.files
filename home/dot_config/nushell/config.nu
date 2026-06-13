# config.nu — main Nushell configuration.
# Launched explicitly by WezTerm via:  nu --config ~/.config/nushell/config.nu
# Colors follow the terminal palette (Catppuccin Mocha, set by WezTerm).

# ---------------------------------------------------------------------------
# Auto-start Zellij (the multiplexer that owns tabs/panes/session-restore).
# This is what makes multiplexing live in the SHELL, decoupled from WezTerm:
# any host terminal that drops us into an interactive Nushell gets Zellij.
# Replace this shell with the "main" Zellij session, resuming it if it exists.
# Guards (skip auto-start when):
#   - already inside Zellij        ('ZELLIJ' env already set) -> avoid recursion
#   - Zellij isn't installed        (e.g. native Windows -> WSL handles it instead)
#   - stdout isn't a real terminal  (scripts, `nu -c ...`, pipelines)
# Placed first so the outer shell does no extra work before handing off; the
# inner Nushell that Zellij spawns re-runs this file with $env.ZELLIJ set and
# falls straight through.
if ('ZELLIJ' not-in $env) and (which zellij | is-not-empty) and (is-terminal --stdout) {
    exec zellij attach --create main
}

$env.config = {
    show_banner: false
    edit_mode: vi
    cursor_shape: {
        vi_insert: line
        vi_normal: block
    }
    rm: { always_trash: true }
    table: {
        mode: rounded
        index_mode: auto
        header_on_separator: true
    }
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: sqlite
        isolation: true
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: fuzzy
        external: {
            enable: true
            max_results: 100
        }
    }
    filesize: { unit: binary }
    render_right_prompt_on_last_line: false
    use_kitty_protocol: false
}

# ---------------------------------------------------------------------------
# Aliases — modern CLI replacements.
# The Unix installer symlinks Debian's `batcat`/`fdfind` to `bat`/`fd`, so these
# names resolve on every platform.
# ---------------------------------------------------------------------------
alias ls = eza --icons --group-directories-first
alias l = eza --icons --group-directories-first
alias ll = eza -l --icons --group-directories-first --git
alias la = eza -la --icons --group-directories-first --git
alias lt = eza --tree --level=2 --icons --group-directories-first
alias cat = bat --paging=never
alias grep = rg
alias g = git
alias lg = lazygit
alias v = nvim
alias vi = nvim
alias cdi = zi          # zoxide interactive

# Reload dotfiles: re-pull the source from the already-configured remote and
# re-apply. --force overwrites local drift without prompting (non-interactive
# reload). No repo handle baked in here -- chezmoi knows its own source remote.
alias rlcfg = chezmoi update --force

# ---------------------------------------------------------------------------
# fzf-powered helpers
# ---------------------------------------------------------------------------

# Fuzzy-find a file and open it in $EDITOR.
def ff [] {
    let file = (fzf --height 40% --reverse --preview "bat --color=always --style=numbers {}" | str trim)
    if ($file | is-not-empty) { ^$env.EDITOR $file }
}

# Fuzzy-cd into a subdirectory.
def --env fcd [] {
    let dir = (fd --type d --hidden --exclude .git | fzf --height 40% --reverse | str trim)
    if ($dir | is-not-empty) { cd $dir }
}

# ---------------------------------------------------------------------------
# Keybindings: Ctrl-r fuzzy history via fzf.
# ---------------------------------------------------------------------------
$env.config = ($env.config | upsert keybindings [
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: "commandline edit --replace (history | get command | reverse | uniq | str join (char nl) | fzf --height 40% --reverse --scheme history --query (commandline) | str trim)"
        }
    }
])

# ---------------------------------------------------------------------------
# Source shell integrations. These files are GENERATED AT APPLY TIME by the
# chezmoi run_after script (run_after_generate-shell-init.{sh,ps1}), never at
# shell start, and are guaranteed to exist after any `chezmoi apply`/`update`.
# Sourcing only — launching the shell does no setup/install work.
# ---------------------------------------------------------------------------
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
