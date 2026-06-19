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
    # Auto-list on directory change. The PWD env_change hook fires on every cd,
    # zoxide jump, or picker (`fcd`), so listing happens however you move. The
    # actual `la` closure is appended below, after the `la` alias is defined.
    hooks: {
        env_change: { PWD: [] }
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

# Convenience aliases.
alias cc = claude --dangerously-skip-permissions  # skip the per-tool prompts
alias bb = burrito                                # spawn-or-attach default session
alias ba = burrito --attach                       # attach to an existing session
# Vim/editor muscle memory for quitting the shell.
alias "/exit" = exit
alias ":q" = exit
alias q = exit

# Reload dotfiles: re-pull source and re-apply. --force overwrites local drift
# without prompting.
alias rr = chezmoi update --force

# cl — start a goal-loop Claude on your task.
#
# `cl clean the codebase up` launches cc, then auto-types two seeds: `/goal is the
# loop. Cancel loop if archived`, then `/loop <task>` (both submitted).
# Driven by cl.py, which runs claude in-place under a pty —
# no multiplexer, no attach — so it always renders, including inside burrito.
def cl [...task: string] {
    let text = ($task | str join " ")
    if ($text | is-empty) {
        error make { msg: "cl: needs a task, e.g. `cl clean the codebase up`" }
    }
    python3 ([$nu.default-config-dir cl.py] | path join) $text
}

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

# Shift+Up: history search scoped to the CURRENT directory, vs Ctrl-R which spans
# all of it. Same television UI, but the candidate list is pre-filtered by cwd
# straight from the sqlite history (which records a `cwd` per command), then piped
# into tv on stdin. The Shift+Up reedline binding is appended after `tv init nu`
# is sourced below, so it lands on top of television's own keymap. WezTerm already
# emits ESC[1;2A for Shift+Up and reedline decodes it as a real Shift+Up, so this
# needs nothing at the terminal layer.
def tv_history_local [] {
    let cur = (commandline | str substring 0..(commandline get-cursor))
    let out = (
        open $"($env.HOME)/.config/nushell/history.sqlite3"
        | query db "SELECT command_line FROM history WHERE cwd = :cwd GROUP BY command_line ORDER BY max(id) DESC LIMIT 5000" --params { cwd: $env.PWD }
        | get command_line
        | str join (char newline)
        | tv --no-status-bar --inline --input $cur
        | str trim
    )
    if ($out | is-not-empty) {
        commandline edit --replace $out
        commandline set-cursor --end
    }
}

# cf — copy a file's contents into the system clipboard. Picks the clipboard
# tool that matches the current session: pbcopy (macOS), wl-copy (Wayland),
# xclip (X11), then clip.exe (WSL). Display-var guards keep us from picking a
# Linux GUI tool that would hang when no compositor/server is attached.
#
# The `path`-typed argument gives filesystem tab-completion for free —
# nushell completes files/dirs, nested paths, `~`, and quoting on <Tab>.
def cf [file: path] {
    let f = ($file | path expand)
    if not ($f | path exists) {
        error make { msg: $"cf: no such file: ($file)" }
    }
    let data = (open --raw $f)
    if (which pbcopy | is-not-empty) {
        $data | pbcopy
    } else if ($env.WAYLAND_DISPLAY? | is-not-empty) and (which wl-copy | is-not-empty) {
        $data | wl-copy
    } else if ($env.DISPLAY? | is-not-empty) and (which xclip | is-not-empty) {
        $data | xclip -selection clipboard
    } else if (which clip.exe | is-not-empty) {
        $data | clip.exe
    } else {
        error make { msg: "cf: no clipboard tool found (need wl-copy, xclip, clip.exe, or pbcopy)" }
    }
    print $"copied ($f) to clipboard"
}

# Append the auto-list closure now that the `la` alias is in scope. `$before`
# is null on the first fire at shell start, so we skip that one to keep startup
# clean; thereafter every real cd lists the new directory in an interactive shell.
#
# `stty sane` first: a cd may arrive via a full-screen TUI (television in `fcd`,
# zoxide, the theme picker) that crashed or exited without restoring cooked-mode
# output. With `onlcr` off, eza's `\n` line breaks drop a row without returning
# to column 0 and the listing staircases. Restoring sane mode right before we
# print makes the auto-list immune to whatever left the terminal half-raw. It is
# a no-op in the normal case (terminal is already cooked between commands).
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and (is-terminal --stdout) {
            ^stty sane e> /dev/null
            la
        }
    }
)

# Source shell integrations. These files are generated at apply time by the
# chezmoi run_after script, not at shell start, so launching the shell does no
# setup work.
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/television/init.nu

# Bind Shift+Up to the cwd-scoped history picker (def above). Appended after the
# television init so it rides on top of tv's Ctrl-R/Ctrl-T bindings rather than
# being overwritten by them.
$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append {
            name: tv_history_local
            modifier: shift
            keycode: up
            mode: [vi_normal vi_insert emacs]
            event: { send: executehostcommand, cmd: "tv_history_local" }
        }
    )
)

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
