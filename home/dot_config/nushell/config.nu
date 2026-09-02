# config.nu — the one nushell config the whole shell shares.
#
# Ten named anchors in a load-bearing order; sections append at their anchor.
# Why any of this is shaped the way it is: manual → internals/nushell.
# Read it before changing a line marked TRAP.
#
# nushell binds names at PARSE time: `def`s are predeclared block-wide
# (order-free); `alias` and `source` bind textually (order is load-bearing).

# ── CONFIG ──
$env.config = {
    show_banner: false
    edit_mode: emacs
    cursor_shape: {
        emacs: block
    }
    # `rm` goes to the macOS Trash, scripts included — a script that deletes a
    # file the user never typed needs `-p` to unlink. See internals/nushell.
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
    # OFF: reedline's kitty query reply leaks through the WezTerm pty as a
    # literal `^[[?0u` — costs control+letter, hence Alt-R not Ctrl-Shift-R.
    use_kitty_protocol: false
    shell_integration: {
        # OFF: starship's two-line prompt plus reedline re-marking paints
        # phantom blank lines. osc7 stays ON — it reports cwd to the multiplexer.
        osc133: false
        osc633: false
        osc7: true
    }
    # Empty: two sections append a PWD closure each, so two appends never
    # conflict the way two edits to one body could.
    hooks: {
        env_change: { PWD: [] }
    }
}

# ── ALIASES ──
alias cat = bat --paging=never
alias grep = rg
alias g = git
alias lg = lazygit
alias nv = nvim
alias vi = nvim
alias nn = nvim ~/notes.md
alias y = yazi

alias q = exit
alias ":q" = exit
alias "/exit" = exit

alias rr = chezmoi update --force

# `pearde` ships as a python entry point in its own repo with no installed
# binary; `install --apply` prints this alias and env.nu's PEARDE_AS export
# for you to add by hand. TRAP: the path is the SOURCE repo
# (~/dev/infra/pearde), never the `.claude/skills/pearde` symlink inside a
# project — a project-pinned path answers only inside that project.
alias pearde = python3 ~/dev/infra/pearde/resources/pearde.py

def cf [file: path] {
    let f = ($file | path expand)
    if not ($f | path exists) {
        error make { msg: $"cf: no such file: ($file)" }
    }
    open --raw $f | pbcopy
    print $"copied ($f) to clipboard"
}

# ── LISTING ──

# Glyphs are MACHINE-COPIED from nvim-web-devicons (lazy-lock.json pin), never
# hand-typed. Dirs carry none — nothing in the dependency tree has a folder glyph.
const LS_ICONS = {
    rs: "", js: "", mjs: "", cjs: "", ts: "", tsx: "", jsx: "",
    py: "", go: "", lua: "", rb: "", php: "", java: "", c: "", h: "",
    cpp: "", hpp: "", cc: "", cs: "󰌛", swift: "", kt: "", scala: "", clj: "",
    ex: "", exs: "", vim: "",
    json: "", jsonc: "", toml: "", yaml: "", yml: "", ini: "", conf: "", cfg: "",
    md: "", markdown: "", txt: "󰈙", pdf: "", log: "󰌱", sql: "", csv: "",
    sh: "", bash: "", zsh: "", fish: "", nu: "", ps1: "󰨊",
    html: "", htm: "", css: "", scss: "", sass: "", vue: "", svelte: "",
    png: "", jpg: "", jpeg: "", gif: "", bmp: "", svg: "󰜡", webp: "", ico: "",
    mp3: "", wav: "", flac: "", ogg: "", mp4: "", mkv: "", mov: "", webm: "",
    zip: "", tar: "", gz: "", xz: "", zst: "", bz2: "", "7z": "", rar: "",
    lock: "", db: "", sqlite: "", sqlite3: "",
}

const LS_ICON_DEFAULT = ""

# TRAP: MUST precede `def ls` — alias targets bind textually, so this keeps
# core-ls pointing at the builtin and stops the wrapper recursing.
alias core-ls = ls

# The icon overlay only — directory sizes are the builtin's own `--du`.
def decorate-ls []: table -> table {
    $in
    | sort-by type modified
    | insert icon {|row|
        if $row.type == "dir" {
            ""
        } else {
            $LS_ICONS
            | get --optional ($row.name | path parse | get extension | str lowercase)
            | default $LS_ICON_DEFAULT
        }
    }
    | move icon --before name
}

# Flags redeclared, not --wrapped, so the builtin reparses them — `-d`/`-D`
# keep the builtin's own meaning (`-d` disk usage, `-D` the directory
# itself). Only a leading `~` is expanded; a full `path expand` would
# absolutize `.`.
def ls [
    --all (-a)
    --long (-l)
    --short-names (-s)
    --full-paths (-f)
    --du (-d)
    --directory (-D)
    --mime-type (-m)
    ...pattern: string
] {
    let paths = (if ($pattern | is-empty) { ["."] } else {
        $pattern | each {|p| if ($p | str starts-with "~") { $p | path expand } else { $p } }
    })
    core-ls --all=$all --long=$long --short-names=$short_names --du=$du --directory=$directory --mime-type=$mime_type ...$paths
    | decorate-ls
}

def l  [path: string = "."] { ls    $path }
def ll [path: string = "."] { ls -l $path }
def la [path: string = "."] { ls -a $path }

# ── FUNNEL ──
source ~/.config/nushell/dirstack.nu

# Every kind of navigation — real cd, zoxide jumps, picker jumps, the
# bare-word fallback — lands here, the one place the start dir is recorded.
# A BLANK keypress confirms creating a missing dir; any other key aborts.
#
# TRAP: `let reply`, never `ans` — that became a builtin variable name in
# nushell 0.115 and the collision broke this machine's login shell.
def --env mkcd [dir?: path] {
    let target = if ($dir | is-empty) { $env.HOME
    } else if $dir == "-" { "-"
    } else { $dir | path expand }
    if $target != "-" and not ($target | path exists) {
        let reply = (input --numchar 1 $"Create '($target)' ? Enter to confirm. All else will cancel. ")
        if ($reply | str trim) != "" {
            print "aborted"
            return
        }
        mkdir $target
    }
    cd $target
    _startdir_save $env.PWD
}

# TRAP: after the def (so `cd` inside mkcd stays the builtin) and BEFORE
# GENERATED — the generated zoxide init binds `cd` at ITS parse time, so a
# zoxide jump after that point would silently bypass this funnel.
alias cd = mkcd

# ── HOOKS ──
# TRAP: THE DIRSTACK APPEND MUST STAY FIRST. An error in a PWD closure aborts
# every closure appended after it, on every fire — the dirstack survives a
# failing listing only by being appended ahead of it.
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            _dirstack_push $after
        }
    }
)

$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            # `which`, not `e> /dev/null` — with no child to spawn, nushell
            # raises external_command before any redirect can guard it.
            if (which stty | is-not-empty) { ^stty sane e> /dev/null }
            # TRAP: the width test is a HANG guard — at 0 columns an EMPTY
            # directory spins the shell at 100% CPU, and `try` catches
            # neither that nor the noise. `print` is required: the hook
            # runner discards a closure's return value.
            if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {
                try { la | print }
            }
        }
    }
)

# ── GENERATED ──
# Generated at chezmoi-apply time so shell start does no setup work.
#
# TRAP: a `source` of a MISSING file is a parse error that DISCARDS THIS
# WHOLE FILE, so the generator always writes all three, empty if the tool is
# missing.
source ~/.cache/nushell/init/starship.nu
source ~/.cache/nushell/init/zoxide.nu
source ~/.cache/nushell/init/television.nu

# ── MODULES ──
# One line per module that EXISTS (see GENERATED for why).
#
# TRAP: order resolves a real cycle — recents.nu parses ABOVE zoxide.nu and
# finder.nu (both call _recents_add); quicklist.nu parses BELOW finder.nu
# (it calls finder's defs).
source ~/.config/nushell/pass.nu
source ~/.config/nushell/claude.nu
source ~/.config/nushell/litellm.nu
source ~/.config/nushell/recents.nu
source ~/.config/nushell/zoxide.nu
source ~/.config/nushell/history.nu
source ~/.config/nushell/capsule.nu
source ~/.config/nushell/finder.nu
source ~/.config/nushell/quicklist.nu

# TRAP: these three live HERE, not in help.nu — `use std/help` and `def
# help` in ONE file fail at parse (predeclaration resolves std's @example
# against our signature). `core-help` must precede the shadow.
use std/help
alias core-help = help
source ~/.config/nushell/help.nu

# ── PALETTE ──
# Re-assert the active tinty scheme so the last `tinty apply` survives into a
# new shell. The artifact is sourced rather than `tinty init` because init
# spawns the binary and its whole hook chain: ~5 ms vs ~128 ms per shell.
#
# TRAP: the guard is `$nu.is-interactive`, NOT `is-terminal --stdout`. The
# latter reports the CURRENT pipeline's redirection and a parenthesised
# sub-expression captures stdout, so as a condition it is false unconditionally
# — the live config guards on it, which is why its re-assert never fired.
if $nu.is-interactive {
    let data = ($env.XDG_DATA_HOME? | default ($nu.home-dir | path join ".local" "share"))
    let palette = ($data | path join "tinted-theming" "tinty" "artifacts" "tinted-shell-scripts-file.sh")
    if ($palette | path exists) {
        try { ^bash $palette e> /dev/null }
    } else if (which tinty | is-not-empty) {
        try { ^tinty init e> /dev/null }
    }
}

# ── THEME ──
source ~/.config/nushell/theme.nu

# ── KEYBINDINGS ──
# LAST, and load-bearing: reedline resolves a duplicate (modifier, keycode)
# to the LATER entry, so records here beat the Ctrl-T/Ctrl-R the generated
# television init binds. Append, never interleave.
#
# Arrows try menuup/menudown first so completion menus keep them.
# `name: quicklist` is not free choice — a shipped manual entry names it.
#
# TRAP: `tv_completion`'s `event: null` unbinds Ctrl-T from
# `tv_smart_autocomplete`, which tv's generated init binds it to — dropping
# this record would hand the key back to tv rather than free it. The finder
# has no other shell keybinding; F3, in tmux.conf, is the one way in from
# any pane. Ctrl-R and Alt-R keep their own pickers.
const KB_MODES = [vi_normal vi_insert emacs]

$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            { name: esc_clear, modifier: none, keycode: escape, mode: [emacs vi_insert], event: { edit: clear } }
            { name: hist_picker_local, modifier: control, keycode: char_r, mode: $KB_MODES, event: { send: executehostcommand, cmd: "tv_history_local" } }
            { name: hist_picker_global, modifier: alt, keycode: char_r, mode: $KB_MODES, event: { send: executehostcommand, cmd: "tv_shell_history" } }
            { name: hist_up_local, modifier: none, keycode: up, mode: $KB_MODES, event: { until: [{ send: menuup } { send: executehostcommand, cmd: "_hist_local" }] } }
            { name: hist_down_local, modifier: none, keycode: down, mode: $KB_MODES, event: { until: [{ send: menudown } { send: executehostcommand, cmd: "_hist_local --down" }] } }
            { name: hist_up_global, modifier: shift, keycode: up, mode: $KB_MODES, event: { until: [{ send: menuup } { send: previoushistory }] } }
            { name: hist_down_global, modifier: shift, keycode: down, mode: $KB_MODES, event: { until: [{ send: menudown } { send: nexthistory }] } }
            { name: tv_completion, modifier: control, keycode: char_t, mode: $KB_MODES, event: null }
            { name: quicklist, modifier: control, keycode: char_q, mode: $KB_MODES, event: { send: executehostcommand, cmd: "quicklist" } }
        ]
    )
)
