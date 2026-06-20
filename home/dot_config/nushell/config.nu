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
# Native `ls` with Nerd Font icons. Nushell's builtin `ls` returns a structured
# table (name/type/size/modified) but no glyphs, so we add an `icon` column from
# an extension → glyph map (directory and generic-file fallbacks). `sort-by type
# modified` keeps dirs grouped and lists newest last, so the freshest files sit
# closest to the prompt.
const LS_ICONS = {
    rs: "", js: "", mjs: "", cjs: "", ts: "", tsx: "", jsx: "",
    py: "", go: "", lua: "", rb: "", php: "", java: "", c: "", h: "",
    cpp: "", hpp: "", cc: "", cs: "", swift: "", kt: "", scala: "", clj: "",
    ex: "", exs: "", vim: "",
    json: "", jsonc: "", toml: "", yaml: "", yml: "", ini: "", conf: "", cfg: "",
    md: "", markdown: "", txt: "", pdf: "", log: "", sql: "", csv: "",
    sh: "", bash: "", zsh: "", fish: "", nu: "", ps1: "",
    html: "", htm: "", css: "", scss: "", sass: "", vue: "", svelte: "",
    png: "", jpg: "", jpeg: "", gif: "", bmp: "", svg: "", webp: "", ico: "",
    mp3: "", wav: "", flac: "", ogg: "", mp4: "", mkv: "", mov: "", webm: "",
    zip: "", tar: "", gz: "", xz: "", zst: "", bz2: "", "7z": "", rar: "",
    lock: "", db: "", sqlite: "", sqlite3: "",
}

# Decorate an `ls` table: sort (dirs first, newest last), prefix an icon column.
def decorate-ls []: table -> table {
    sort-by type modified
    | insert icon {|row|
        if $row.type == "dir" {
            ""
        } else {
            $LS_ICONS
            | get --optional ($row.name | path parse | get extension | str downcase)
            | default ""
        }
    }
    | move icon --before name
}

def l  [path: string = "."] { ls    $path | decorate-ls }
def ll [path: string = "."] { ls -l $path | decorate-ls }
def la [path: string = "."] { ls -a $path | decorate-ls }
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

# cd that creates missing directories. Existing paths behave exactly like the
# builtin (and still fire the PWD auto-list hook below); a non-existent target is
# `mkdir`-ed first, so `cd some/new/path` + Enter just makes and enters it. `cd`
# (home) and `cd -` (previous dir) are passed straight through.
#
# The wrapper is named `mkcd` and `cd` is aliased to it *after* the def, so the
# `cd $target` in the body still resolves to the builtin (no recursion); the
# alias only redirects the names typed at the prompt.
def --env mkcd [dir?: path] {
    let target = if ($dir | is-empty) { $env.HOME
    } else if $dir == "-" { "-"
    } else { $dir | path expand }
    if $target != "-" and not ($target | path exists) {
        let ans = (input $"($target) does not exist. create it? [y/N] ")
        if ($ans | str downcase | str trim) not-in ["y" "yes"] {
            print "aborted"
            return
        }
        mkdir $target
    }
    cd $target
}
alias cd = mkcd

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

# Local history, two ways. The sqlite history records a `cwd` per command, so we
# can scope both the Ctrl-R picker and the Up/Down cycle to the current directory.
# Bindings (appended after `tv init nu` below): Ctrl-R = local picker, Ctrl-Shift-R
# = global picker (tv's own def); Up/Down = local cycle, Shift+Up/Down = global.
# The cwd query, shared by both defs.
def _hist_cwd [] {
    open $"($env.HOME)/.config/nushell/history.sqlite3"
    | query db "SELECT command_line FROM history WHERE cwd = :cwd GROUP BY command_line ORDER BY max(id) DESC LIMIT 5000" --params { cwd: $env.PWD }
    | get command_line
}

# Ctrl-R: television history picker, candidates pre-filtered to this directory and
# piped in on stdin (vs Ctrl-Shift-R which uses tv's global `tv_shell_history`).
def tv_history_local [] {
    let cur = (commandline | str substring 0..(commandline get-cursor))
    let out = (_hist_cwd | str join (char newline) | tv --no-status-bar --inline --input $cur | str trim)
    if ($out | is-not-empty) {
        commandline edit --replace $out
        commandline set-cursor --end
    }
}

# Up/Down: inline cwd-scoped history cycle. reedline's native traversal is
# global-only (no cwd filter), so this re-implements the cycle over just this
# directory's commands, newest-first, tracking position in $env across keypresses.
# Typing anything (buffer no longer matches what we last injected) resets to the
# newest entry. Shift+Up/Down keep reedline's native global traversal.
def --env _hist_local [--down] {
    let dir = (if $down { -1 } else { 1 })
    let buf = (commandline)
    let last = ($env._HIST_LOCAL_LAST? | default "")
    let pos = (if $buf != $last { -1 } else { $env._HIST_LOCAL_POS? | default (-1) })
    let cmds = (_hist_cwd)
    let n = ($cmds | length)
    if $n == 0 { return }
    let np = ([([($pos + $dir) 0] | math max) ($n - 1)] | math min)
    let pick = ($cmds | get $np)
    commandline edit --replace $pick
    commandline set-cursor --end
    $env._HIST_LOCAL_POS = $np
    $env._HIST_LOCAL_LAST = $pick
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

# o — open a location in the host file manager, à la macOS `open`. WSL only: hand
# the path to Windows Explorer, which pops a File Explorer window at a folder (or
# opens a file in its default Windows app). We guard on explorer.exe (same WSL
# test as `cf`'s clip.exe) so a non-WSL shell gets a clear error, not a hang.
#
# Named `o`, not `open`: Nushell's builtin `open` reads/parses files and is used
# above by the history (sqlite), cf (--raw), and theme readers. A custom `open`
# def or alias hoists across the whole config scope and would shadow the builtin
# for those readers too — so we leave `open` alone and add the launcher as `o`.
#
# explorer.exe wants a Windows path (wslpath translates) and exits 1 even on
# success, so we capture and drop its status to avoid a spurious nu error.
def o [path?: path] {
    if (which explorer.exe | is-empty) {
        error make { msg: "o: not on WSL (no explorer.exe) — nothing to open" }
    }
    let target = (if ($path | is-empty) { $env.PWD } else { $path | path expand })
    if not ($target | path exists) {
        error make { msg: $"o: no such path: ($target)" }
    }
    let win = (do { wslpath -w $target } | complete)
    let arg = (if $win.exit_code == 0 { $win.stdout | str trim } else { $target })
    ^explorer.exe $arg | complete | ignore
}

# Append the auto-list closure now that the `la` alias is in scope. `$before`
# is null on the first fire at shell start, so we skip that one to keep startup
# clean; thereafter every real cd lists the new directory in an interactive shell.
#
# `stty sane` first: a cd may arrive via a full-screen TUI (television in `fcd`,
# zoxide, the theme picker) that crashed or exited without restoring cooked-mode
# output. With `onlcr` off, the table's `\n` line breaks drop a row without
# returning to column 0 and the listing staircases. Restoring sane mode before we
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

# History keymap, appended after the television init so it overrides tv's own
# Ctrl-R binding (reedline keys the map by (modifier,keycode); a later entry wins).
#   Ctrl-R        local picker        Ctrl-Shift-R  global picker (tv's def)
#   Up/Down       local inline cycle  Shift+Up/Down native global traversal
# Each arrow falls through to menu nav first (`until` tries menuup/menudown, which
# no-op when no menu is open, then runs ours), so completion menus still work.
#
# use_kitty_protocol: without it a terminal collapses Ctrl-Shift-R to the same byte
# as Ctrl-R (shift is lost on control+letter), so the two pickers couldn't coexist.
# The kitty keyboard protocol carries the full modifier set; WezTerm negotiates it,
# and reedline only uses it when the terminal acks, so it's a safe no-op elsewhere.
$env.config.use_kitty_protocol = true
$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            {
                name: hist_picker_local
                modifier: control
                keycode: char_r
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_history_local" }
            }
            {
                name: hist_picker_global
                modifier: control_shift
                keycode: char_r
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_shell_history" }
            }
            {
                name: hist_up_local
                modifier: none
                keycode: up
                mode: [vi_normal vi_insert emacs]
                event: { until: [{ send: menuup } { send: executehostcommand, cmd: "_hist_local" }] }
            }
            {
                name: hist_down_local
                modifier: none
                keycode: down
                mode: [vi_normal vi_insert emacs]
                event: { until: [{ send: menudown } { send: executehostcommand, cmd: "_hist_local --down" }] }
            }
            {
                name: hist_up_global
                modifier: shift
                keycode: up
                mode: [vi_normal vi_insert emacs]
                event: { until: [{ send: menuup } { send: previoushistory }] }
            }
            {
                name: hist_down_global
                modifier: shift
                keycode: down
                mode: [vi_normal vi_insert emacs]
                event: { until: [{ send: menudown } { send: nexthistory }] }
            }
        ]
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

# `finder`: composable, typed fuzzy finder — chains tv channels, returns nu data.
source ~/.config/nushell/finder.nu
