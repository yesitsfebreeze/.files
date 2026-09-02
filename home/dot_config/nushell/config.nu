# config.nu — the one nushell config the whole shell shares.
#
# Ten named anchors in a load-bearing order; sections append at their anchor.
# Why any of this is shaped the way it is: manual → internals/nushell.
# Read it before changing a line marked TRAP.
#
# The rule everything else follows from: nushell binds names at PARSE time.
# `def`s are predeclared block-wide (order-free); `alias` and `source` bind
# textually (order is load-bearing).

# ── CONFIG ──
$env.config = {
    show_banner: false
    edit_mode: emacs
    cursor_shape: {
        emacs: block
    }
    # interactive `rm` goes to the macOS Trash — the safety net for a
    # mistyped path. It applies to scripts too, so a script deleting a file
    # the user never typed passes `-p` and unlinks: a trashed file plays the
    # Finder trash sound and piles ~/.Trash up. See internals/nushell, `rm`.
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
    # OFF: reedline's kitty query reply arrives too late through the WezTerm
    # pty and leaks as a literal `^[[?0u`. Costs shift on control+letter,
    # which is why the global history picker is Alt-R and not Ctrl-Shift-R.
    use_kitty_protocol: false
    shell_integration: {
        # OFF: starship's prompt is two lines and reedline re-marks on every
        # repaint, which the terminal draws as phantom blank lines.
        osc133: false
        osc633: false
        # ON, and stated so the two above do not read as "integration off":
        # this is what reports the cwd the multiplexer shows.
        osc7: true
    }
    # Empty on purpose. PWD is a LIST and two sections append a closure to
    # it; two appends cannot conflict the way two edits to one body can.
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

# The board tool. `pearde` ships as a python entry point in its own repo with
# no installed binary — `install --apply` builds symlinks for the skills and
# then prints this alias and the `PEARDE_AS` export in env.nu for you to add
# by hand; nothing in it writes a shell file. TRAP: the path is the SOURCE
# repo, not the `.claude/skills/pearde` symlink inside a project — every
# install on this machine points into ~/dev/infra/pearde, and an alias
# pinned to one project's skills directory answers only inside that project.
alias pearde = python3 ~/dev/infra/pearde/resources/pearde.py

# TRAP: the display-var guards are what make this safe headless — wl-copy and
# xclip hang forever with no compositor, so a `which` hit alone must not pick
# them.
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
    } else {
        error make { msg: "cf: no clipboard tool found (need wl-copy, xclip, or pbcopy)" }
    }
    print $"copied ($f) to clipboard"
}

# ── LISTING ──


# Glyphs are MACHINE-COPIED from nvim-web-devicons (lazy-lock.json pin), never
# hand-typed — this map was silently empty in every earlier revision. Dirs
# carry no icon because nothing in the dependency tree vendors a folder glyph.
const LS_ICONS = {
    rs: "", js: "", mjs: "", cjs: "", ts: "", tsx: "", jsx: "",
    py: "", go: "", lua: "", rb: "", php: "", java: "", c: "", h: "",
    cpp: "", hpp: "", cc: "", cs: "󰌛", swift: "", kt: "", scala: "", clj: "",
    ex: "", exs: "", vim: "",
    json: "", jsonc: "", toml: "", yaml: "", yml: "", ini: "", conf: "", cfg: "",
    md: "", markdown: "", txt: "󰈙", pdf: "", log: "󰌱", sql: "", csv: "",
    sh: "", bash: "", zsh: "", fish: "", nu: "", ps1: "󰨊",
    html: "", htm: "", css: "", scss: "", sass: "", vue: "", svelte: "",
    png: "", jpg: "", jpeg: "", gif: "", bmp: "", svg: "󰜡", webp: "", ico: "",
    mp3: "", wav: "", flac: "", ogg: "", mp4: "", mkv: "", mov: "", webm: "",
    zip: "", tar: "", gz: "", xz: "", zst: "", bz2: "", "7z": "", rar: "",
    lock: "", db: "", sqlite: "", sqlite3: "",
}

const LS_ICON_DEFAULT = ""

# TRAP: MUST precede `def ls`. Alias targets bind textually, so this keeps
# core-ls pointing at the builtin and stops the wrapper recursing.
alias core-ls = ls

# TRAP: `du -sk` × 1024, never `du -b` — macOS du has no -b, and the old code
# sent the usage banner to /dev/null and silently fell back to inode sizes, so
# `ls -D` looked like it worked. A failing du must SURFACE once via print -e.
def decorate-ls [du: bool]: table -> table {
    let rows = ($in | sort-by type modified)
    let dirs = (if $du { $rows | where type == "dir" | get name } else { [] })
    let dir_sizes = if ($dirs | is-empty) { {} } else {
        let res = (do { ^du -sk ...$dirs } | complete)
        let parsed = ($res.stdout | lines | parse -r '(?<size>\d+)\s+(?<name>.+)')
        let first_err = ($res.stderr | lines | get --optional 0 | default "")
        if ($parsed | is-empty) {
            print -e $"ls -D: du produced no sizes, exit ($res.exit_code): ($first_err)"
            {}
        } else {
            if $res.exit_code != 0 {
                print -e $"ls -D: du exit ($res.exit_code): ($first_err)"
            }
            $parsed | reduce --fold {} {|it, acc|
                $acc | insert $it.name (($it.size | into int) * 1024 | into filesize)
            }
        }
    }
    $rows
    | each {|row|
        if $row.type == "dir" {
            $row | update size ($dir_sizes | get --optional $row.name | default $row.size)
        } else {
            $row
        }
    }
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

# Flags redeclared, not --wrapped, so the builtin reparses them as flags. `-D`
# here is our du decoration; the builtin's `--directory` is `-d`. Only a
# leading `~` is expanded — a full `path expand` would absolutize `.`.
def ls [
    --all (-a)
    --long (-l)
    --short-names (-s)
    --full-paths (-f)
    --du (-D)
    --directory (-d)
    --mime-type (-m)
    ...pattern: string
] {
    let paths = (if ($pattern | is-empty) { ["."] } else {
        $pattern | each {|p| if ($p | str starts-with "~") { $p | path expand } else { $p } }
    })
    core-ls --all=$all --long=$long --short-names=$short_names --full-paths=$full_paths --directory=$directory --mime-type=$mime_type ...$paths
    | decorate-ls $du
}

def l  [path: string = "."] { ls    $path }
def ll [path: string = "."] { ls -l $path }
def la [path: string = "."] { ls -a $path }

# ── FUNNEL ──
source ~/.config/nushell/dirstack.nu

# The single navigation funnel: real cd, zoxide jumps, picker jumps and the
# bare-word fallback all land here, which is what makes it the one place the
# start dir is recorded. A BLANK keypress confirms; any other key aborts.
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

# TRAP: after the def (so `cd` inside mkcd stays the builtin and cannot
# recurse) and BEFORE the GENERATED anchor. The generated zoxide init calls
# `cd` and binds it at ITS parse time — with this line after that source, every
# zoxide jump silently bypasses the funnel: right directory, no error, and the
# dirstack and startdir never update.
alias cd = mkcd

# ── HOOKS ──
# TRAP: THE DIRSTACK APPEND MUST STAY FIRST. An error in a PWD closure aborts
# that closure and every closure appended AFTER it, on every fire — so the
# dirstack survives a failing listing only by being appended ahead of it.
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
            # `which`, because `e> /dev/null` is NOT a guard: with no child to
            # spawn, nushell raises external_command before any redirect.
            if (which stty | is-not-empty) { ^stty sane e> /dev/null }
            # TRAP: the width test is a HANG guard, not cosmetics — at 0
            # columns an EMPTY directory spins the shell at 100% CPU, and the
            # `try` catches neither that nor the noise. The explicit `print` is
            # required: the hook runner discards a closure's return value.
            if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {
                try { la | print }
            }
        }
    }
)

# ── GENERATED ──
# Generated at chezmoi-apply time so shell start does no setup work. Paths are
# literal: `source` resolves at parse time and cannot read $env.
#
# TRAP: a `source` of a MISSING file is a parse error that DISCARDS THIS WHOLE
# FILE — interactively you get a working but naked REPL, with every command
# above the failing line gone too. The generator therefore always writes all
# three files, empty if the tool is missing.
source ~/.cache/nushell/init/starship.nu
source ~/.cache/nushell/init/zoxide.nu
source ~/.cache/nushell/init/television.nu

# ── MODULES ──
# One line per module that EXISTS; a module and its line land in the same
# change, because a missing source discards this file (see GENERATED).
#
# TRAP: the order resolves a real cycle. recents.nu must parse ABOVE zoxide.nu
# and finder.nu (both call _recents_add); quicklist.nu must parse BELOW
# finder.nu (it calls finder's defs). One file could not do both.
source ~/.config/nushell/pass.nu
source ~/.config/nushell/claude.nu
source ~/.config/nushell/litellm.nu
source ~/.config/nushell/recents.nu
source ~/.config/nushell/zoxide.nu
source ~/.config/nushell/history.nu
source ~/.config/nushell/capsule.nu
source ~/.config/nushell/finder.nu
source ~/.config/nushell/quicklist.nu
source ~/.config/nushell/copymode.nu

# TRAP: these three live HERE, not in help.nu. `use std/help` and `def help` in
# ONE file fail at parse — nushell predeclares the block's defs, so std's
# @example resolves `help` against our signature. A sourced file is its own
# block. `core-help` must be an alias, and must precede the shadow.
use std/help
alias core-help = help
source ~/.config/nushell/help-check.nu
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

# `tv_finder` and `tv_remote` stood here and were removed on 2026-09-01 with
# the three keys that were their only callers. Both opened `_finder_pick_channel`
# — the channel list — and that question ("which channel is it in?") is the one
# F3 no longer asks. `finder` itself is untouched and still takes `--start`.

# ── KEYBINDINGS ──
# LAST, and load-bearing: reedline resolves a duplicate (modifier, keycode) to
# the LATER entry, so records here beat the Ctrl-T/Ctrl-R the generated
# television init binds. Append, never interleave.
#
# Arrows try menuup/menudown first (the `until` members no-op with no menu
# open) so completion menus keep them. `name: quicklist` is not free choice —
# a shipped manual entry resolves that exact name.
$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            {
                name: esc_clear
                modifier: none
                keycode: escape
                mode: [emacs vi_insert]
                event: { edit: clear }
            }
        ]
    )
)

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
                modifier: alt
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

# The finder has no shell keybinding. Ctrl-Space, F1 and Ctrl-T all opened a
# channel list from this prompt and were retired on 2026-09-01: the one way in
# is now F3, bound in tmux.conf, which reaches the same channels from any pane
# rather than only from a nushell prompt — inside nvim, inside a Claude pane,
# inside anything. The `finder` command itself stays, for scripts and for
# anyone who wants one named channel.
#
# TRAP: dropping our Ctrl-T record is NOT the same as freeing Ctrl-T. The
# generated `tv init nu` binds it to tv's own `tv_smart_autocomplete`, so
# removing ours would hand the key back to television rather than clear it —
# a picker would still open, just a different one. `event: null` is nushell's
# unbind, and it works here for the same reason the override did: reedline
# resolves a duplicate (modifier, keycode) to the LATER entry, and this block
# is appended after the init's. Ctrl-R and Alt-R keep their pickers on
# purpose; only the channel list is gone.
$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            {
                name: tv_completion
                modifier: control
                keycode: char_t
                mode: [vi_normal vi_insert emacs]
                event: null
            }
        ]
    )
)

$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            {
                name: quicklist
                modifier: control
                keycode: char_q
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "quicklist" }
            }
        ]
    )
)
