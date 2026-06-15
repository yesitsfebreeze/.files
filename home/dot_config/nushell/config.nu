# config.nu — Nushell config, launched explicitly by WezTerm.

# Start prompt: ask before launching burrito (shell-level multiplexer). Enter
# replaces this shell with burrito's spawn-or-attach default session; Esc (or any
# other key) stays in plain Nushell.
#
# Launch burrito as a CHILD of this nu process — do NOT `exec` it. burrito has no
# shell-config key; it picks each cell's shell by walking its parent process tree
# for a known shell. Running it as a child keeps nu as burrito's parent, so that
# walk finds nu directly and every cell launches nu. (`exec` would replace this nu
# process, making burrito's parent WezTerm — the walk finds no shell and burrito
# falls back to $SHELL.) When burrito exits we exit too, mirroring `exec`.
#
# Recursion guard: burrito does NOT export any marker of its own, and it spawns
# Nushell in every cell. Each cell re-sources this file, so without a guard every
# cell would re-prompt and re-launch burrito — infinite nesting. We set BURRITO
# ourselves just before launch; burrito inherits its environment into every
# spawned cell, so cells see it and skip this block.
if ('BURRITO' not-in $env) and (which burrito | is-not-empty) and (is-terminal --stdout) {
    print -n "Press [Enter] to launch burrito. Everything else to canel."
    let key = (input listen --types [key])
    print ""
    if ($key.code == "enter") {
        $env.BURRITO = "1"
        burrito
        exit
    }
}

$env.config = {
    show_banner: false
    edit_mode: vi
    # Block cursor in every mode; the terminal applies the blink.
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
        # Shared live history across all panes/sessions (burrito spawns many).
        # `false` keeps one merged sqlite the Ctrl-R channel always reads in full.
        isolation: false
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
    # Disable OSC 133/633 prompt-zone markers. With WezTerm hosting burrito
    # hosting Nushell, both may interpret OSC 133; the two-line starship prompt
    # re-emits the prompt-start mark on every reedline repaint, which the terminal
    # then renders as a phantom blank line above the input. We don't use the
    # terminal's semantic-zone features, so turning the markers off is a clean cut.
    shell_integration: {
        osc133: false
        osc633: false
    }
}

# Aliases. The Unix installer symlinks Debian's `batcat`/`fdfind` to `bat`/`fd`,
# so those names resolve on every platform.
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
alias cdi = zi

# Reload dotfiles: re-pull source and re-apply. --force overwrites local drift
# without prompting.
alias rlcfg = chezmoi update --force

# television helpers (Ctrl-T autocomplete / Ctrl-R history come from `tv init nu`
# sourced below). These defs add find-file, fuzzy-cd, and live-grep shortcuts.
def ff [] {
    let file = (tv files | str trim)
    if ($file | is-not-empty) { ^$env.EDITOR $file }
}

def --env fcd [] {
    let dir = (tv dirs | str trim)
    if ($dir | is-not-empty) { cd $dir }
}

# Live-grep; the tv `text` channel's builtin edit action opens $EDITOR at the
# match directly, so there's no stdout to capture.
def fg [] {
    tv text
}

# Source shell integrations. These files are generated at apply time by the
# chezmoi run_after script, not at shell start, so launching the shell does no
# setup work.
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/television/init.nu

# Live theme: re-apply the last `theme` pick so it persists into new shells.
# tinty re-emits OSC palette sequences; stdout is left attached on purpose —
# that IS the retint. No-op until you pick a theme, so the Gruvbox base stands.
if (which tinty | is-not-empty) and (is-terminal --stdout) {
    # `try` swallows a nonzero exit (no scheme applied yet). Do not use `complete`
    # here — it would capture stdout and eat the OSC escape sequences.
    try { ^tinty init e> /dev/null }
}

# `theme`: fuzzy picker over tinty's official base16/base24 catalog with apply-on-focus preview.
source ~/.config/nushell/theme.nu

# `pass` (password-store) completion: subcommands + live entry names from the store.
source ~/.config/nushell/pass.nu
