# config.nu — main Nushell configuration.
# Launched explicitly by WezTerm via:  nu --config ~/.config/nushell/config.nu
# Colors follow the terminal palette (Gruvbox Dark Hard, set by WezTerm).

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
    # Block cursor in every mode (terminal applies the blink).
    cursor_shape: {
        vi_insert: block
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
    use_kitty_protocol: false
}
# NOTE: render_right_prompt_on_last_line is deliberately NOT set in the block
# above. The starship init (sourced at the end of this file) force-merges it to
# `true`, which clobbers anything set here. We re-assert `false` AFTER that
# source instead -- see the end of the file.

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
# television-powered helpers. tv is the interactive finder (replaces fzf in the
# shell): Ctrl-T smart autocomplete and Ctrl-R history come from the sourced
# `tv init nu` integration near the end of this file. These defs add two
# side-effecting shortcuts on top of the builtin tv channels.
# ---------------------------------------------------------------------------

# Fuzzy-find a file (tv `files` channel, bat preview) and open it in $EDITOR.
def ff [] {
    let file = (tv files | str trim)
    if ($file | is-not-empty) { ^$env.EDITOR $file }
}

# Fuzzy-cd into a subdirectory (tv `dirs` channel).
def --env fcd [] {
    let dir = (tv dirs | str trim)
    if ($dir | is-not-empty) { cd $dir }
}

# Live-grep across files (tv `text` channel). Enter runs the channel's builtin
# edit action, opening $EDITOR at the matched line (no stdout round-trip needed).
def fg [] {
    tv text
}

# ---------------------------------------------------------------------------
# Source shell integrations. These files are GENERATED AT APPLY TIME by the
# chezmoi run_after script (run_after_generate-shell-init.{sh,ps1}), never at
# shell start, and are guaranteed to exist after any `chezmoi apply`/`update`.
# Sourcing only — launching the shell does no setup/install work.
# ---------------------------------------------------------------------------
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/television/init.nu   # tv Ctrl-T autocomplete + Ctrl-R history

# Undo starship's forced `render_right_prompt_on_last_line: true`. On
# WezTerm/Windows that setting parks the caret on the last terminal line, where
# reedline's per-keystroke cursor reposition is emitted as a newline instead of
# a carriage return -- so every keypress inserts a blank line (cleared on Enter).
# See nushell#5585 and wezterm#1999. Must run AFTER the starship source above.
$env.config.render_right_prompt_on_last_line = false
