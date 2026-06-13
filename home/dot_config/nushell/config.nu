# config.nu — main Nushell configuration.
# Launched explicitly by WezTerm via:  nu --config ~/.config/nushell/config.nu
# Colors follow the terminal palette (Catppuccin Mocha, set by WezTerm).

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
    filesize: { metric: false }
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
# Source generated integrations (created by env.nu; guaranteed to exist).
# ---------------------------------------------------------------------------
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
