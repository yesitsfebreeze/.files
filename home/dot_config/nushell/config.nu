# config.nu — the one nushell config the whole shell epic shares. WezTerm
# launches nu with an explicit `--config` pointing here; env.nu (the
# env-config) has already run by the time this file is evaluated.
#
# THIS FILE IS CO-WRITTEN. The schedule gives `home/dot_config/nushell/config.nu`
# to S.1 through S.9, serially, so the sections below are laid out as NAMED
# ANCHORS in a load-bearing order and every later node appends at its anchor
# rather than re-deriving where its block belongs. The anchors are
# `# ── NAME ──` comment lines and a gate asserts both that all ten are present
# and that they appear in this order. Anchors that are empty today are empty on
# purpose — they are reservations, not omissions.
#
# Two tidier-looking layouts were measured and are closed:
#
#   * nushell autoload. `$nu.user-autoload-dirs` on this host resolves to
#     ~/Library/Application Support/nushell/autoload — OUTSIDE ~/.config —
#     which would split the managed tree across two roots.
#   * pre-declared `source` lines for files a sibling node will create later.
#     A `source` of a missing file is a PARSE error
#     (`nu::parser::sourced_file_not_found`), so this file can only ever source
#     files that already exist when it is deployed. That is why the MODULES
#     anchor below sources only modules that ship in this tree, and why each
#     module's `source` line lands in the same change as the module file —
#     recents.nu and quicklist.nu, the last two to arrive, both did. The
#     radius of getting it wrong is a WORKING BUT NAKED REPL, not a shell
#     that refuses to start — measured at the GENERATED anchor below.
#
# See .mi/prds/04-shell/01-core-config/specs/spec03.md.

# ── CONFIG ──
$env.config = {
    show_banner: false
    edit_mode: emacs
    # A solid block cursor in emacs mode. The TERMINAL supplies the blink;
    # this file deliberately does not restate the terminal's own setting.
    cursor_shape: {
        emacs: block
    }
    rm: { always_trash: true }
    table: {
        mode: rounded
        index_mode: auto
        header_on_separator: true
    }
    history: {
        max_size: 100_000
        # sync_on_enter is what makes a command typed in ANOTHER pane arrive
        # in this one without opening a new shell — it writes and re-reads on
        # every Enter rather than at exit.
        sync_on_enter: true
        file_format: sqlite
        # isolation: false is what 04-shell/05-history requires — ONE merged
        # sqlite that every pane and session shares and that the Ctrl-R
        # channel can read in full. `true` would give each session its own
        # slice and the global history picker would only ever see itself.
        isolation: false
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: fuzzy
        # external is what makes completion for external commands work at
        # all; without it nushell completes its own builtins only.
        external: {
            enable: true
            max_results: 100
        }
    }
    filesize: { unit: binary }
    # use_kitty_protocol stays OFF. With it on, reedline fires the kitty
    # support query twice at startup and the WezTerm pty returns the reply too
    # late to consume, so it leaks as a literal `^[[?0u` above the prompt.
    # What turning it off COSTS: shift is lost on control+letter, so
    # Ctrl-Shift-R is indistinguishable from Ctrl-R — which is exactly why
    # 04-shell/05-history binds the global history picker to Alt-R instead.
    use_kitty_protocol: false
    shell_integration: {
        # OSC 133/633 prompt-zone markers OFF. starship's prompt here is two
        # lines, and reedline re-emits the prompt-start mark on every repaint;
        # the terminal renders each one as a phantom blank line above the
        # input. Nothing in this environment uses the terminal's semantic-zone
        # features, so turning the markers off is a clean cut.
        osc133: false
        osc633: false
        # OSC 7 stays ON, and it is here so the two disables above are not
        # mistaken for turning ALL terminal integration off: OSC 7 is what
        # reports the cwd to the host terminal, which is what WezTerm's status
        # line reads. Measured: both are on by default — a bare `nu -n` REPL
        # under a pty emits `ESC]7;file://…` and `ESC]133;D;0`.
        osc7: true
    }
    # Declared EMPTY here on purpose. `hooks.env_change.PWD` is a LIST and
    # two different nodes append a closure to it (this node's dirstack push,
    # 04-shell/06's auto-list). 04-shell/03 appends NOTHING here: the PWD
    # hook may not fire for a cd made in pre_execution, so its bare-word
    # fallback sets $env._NAV from pre_execution and clears it from
    # pre_prompt instead. Two appends to a list cannot conflict the way two
    # edits to one fused closure body can, and this file is co-written by
    # both appenders.
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

alias q = exit
alias ":q" = exit
alias "/exit" = exit

alias rr = chezmoi update --force

# cf — copy a file's contents into the system clipboard. Picks the clipboard
# tool that matches the current session: pbcopy (macOS), wl-copy (Wayland),
# xclip (X11). The display-var guards on $env.WAYLAND_DISPLAY? and
# $env.DISPLAY? are what make this safe headless: wl-copy and xclip hang
# forever waiting for a compositor or X server when none is attached, so a
# `which` hit alone must never select them.
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
    } else {
        error make { msg: "cf: no clipboard tool found (need wl-copy, xclip, or pbcopy)" }
    }
    print $"copied ($f) to clipboard"
}

# ── LISTING ──
# This anchor sits before FUNNEL and HOOKS, and DEF ORDER IS NOT WHAT THAT
# BUYS. Nushell PREDECLARES every def in a block before it parses any body,
# so a closure or a def body may call a def written LOWER in the same file,
# and `la` is a def. Measured 2026-08-23 on 0.114.1: a PWD closure calling
# `la` with `def la` written BELOW it wrote `la.txt: LA-RAN` on the first
# `cd`, zero `nu::parser` errors; the control
# `nu -n -c 'let c = {|| later }; def later [] {...}; do $c'` printed
# `LATER-RAN`.
#
# WHAT BINDS TEXTUALLY IS AN ALIAS AND A `source`, and neither is
# predeclared: an alias target resolves where the parser meets the `alias`
# line, and a `source`d name enters scope only from its own line downwards.
# Two measurements, same session:
#
#   * `alias core-ls = ls` below MUST precede `def ls`. Alias first: the
#     shadow ran. Alias after the def: `Command core-ls not found` on the
#     FIRST `ls` — loud, not silent, and NOT recursion, because the alias
#     then points at OUR `ls` while the body's `core-ls` was never in scope.
#   * had the auto-list closure named an ALIAS instead of the `la` def, this
#     anchor order WOULD be load-bearing: a closure calling an alias
#     declared below it gives `Command not found`.
#
# tests/nushell-core.sh asserts both textual-binding pairs with swapped-order
# counterfactuals, which is what makes them checked artefacts and not
# conventions. The ten-anchor order is its own contract (S4.10); nothing here
# licenses moving an anchor.

# The builtin `ls` already returns a structured table (name/type/size/
# modified); the shadow below adds an `icon` column from this extension→glyph
# map and a `sort-by type modified` — dirs grouped, newest last, freshest
# rows nearest the prompt. The map is carried VERBATIM from the live config
# (its values were intended as Nerd Font private-use glyphs, which retyping
# corrupts silently — hence verbatim, never retyped by hand). Measured
# 2026-08-22, hexdump over every revision of the live repo: the value
# strings are EMPTY — no private-use byte has ever been in that file — so
# the icon column currently renders empty. Restoring real glyphs is a
# correction against the live source, not something to invent here.
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

# Capture the builtin under a second name BEFORE `ls` is shadowed below.
# Alias targets bind at parse time, so `core-ls` stays bound to the builtin
# and the wrapper cannot recurse.
alias core-ls = ls

# Decorate an `ls` table: sort, prepend the icon column, and — only with
# `du: true` — swap each dir's inode size (a flat ~4 KB) for its recursive
# on-disk size, from ONE `du` spawn over all dir names, rows matched back by
# the path `du` echoes. Opt-in only: `du` walks the whole tree under each
# dir, so node_modules would stall every plain `ls`/auto-list.
#
# THE DU CALL IS `du -sk` × 1024, THROUGH `complete`, AND THAT IS LIVE BUG
# L-1'S CORRECTION. The live config asks du for bytes with the `-b` flag and
# discards stderr, but macOS `du` has no `-b`: it prints `invalid option`
# plus a usage banner — straight into /dev/null. `parse -r` then found no
# rows, the size map came back empty, and the `default $row.size` fallback
# quietly restored the very inode sizes the flag exists to replace, so
# `ls -D` LOOKED like it worked. `-sk` (allocated 1024-byte blocks, × 1024
# to bytes) is also the right number: `-b` is apparent size and this column
# is on-disk size. Not `gdu` either — it is not in 05-platform/02 R7's
# required package set. And the constraint that outranks the flag: a failing
# `du` SURFACES ONCE, via `print -e` so the table pipeline stays clean,
# instead of degrading silently back to inode sizes. The gate greps for the
# banned flag spelling by name, so it is kept out of this file entirely and
# a hit is proof of a regression rather than of a comment.
def decorate-ls [du: bool]: table -> table {
    let rows = ($in | sort-by type modified)
    let dirs = (if $du { $rows | where type == "dir" | get name } else { [] })
    let dir_sizes = if ($dirs | is-empty) { {} } else {
        let res = (do { ^du -sk ...$dirs } | complete)
        let parsed = ($res.stdout | lines | parse -r '(?<size>\d+)\s+(?<name>.+)')
        let first_err = ($res.stderr | lines | get --optional 0 | default "")
        if ($parsed | is-empty) {
            # No rows at all: every dir keeps its inode size, and the
            # failure speaks — this is the branch L-1's discarded stderr hid.
            print -e $"ls -D: du produced no sizes, exit ($res.exit_code): ($first_err)"
            {}
        } else {
            if $res.exit_code != 0 {
                # Partial rows (e.g. one unreadable subtree): use them, and
                # still say so once.
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
            # `default $row.size` is safe ONLY because the no-rows branch
            # above already spoke; without that notice this line is exactly
            # how L-1 stayed invisible.
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
            | default ""
        }
    }
    | move icon --before name
}

# Shadow `ls`. Flags are redeclared explicitly, not `--wrapped`, so the
# builtin reparses them as flags rather than paths; an empty pattern becomes
# ["."] because the builtin's empty spread (`ls ...[]`) returns nothing
# rather than the cwd. Two deliberate letter deviations from the builtin:
# `-D` here is OUR du decoration (the builtin spells `--directory` `-D`,
# here it is `-d`), and the builtin's own `--du` is not exposed at all — its
# native flag also walks the tree, and decorate-ls owns recursive dir
# sizing.
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
    # `~` is expanded here because the builtin does not expand it inside a
    # string VARIABLE (only in a directly typed bare word), and every
    # pattern reaches it through the `$paths` spread below. Only a leading
    # `~` is touched: a full `path expand` would absolutize `.` and turn
    # every plain-`ls` name column into absolute paths.
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
# The directory-history helpers. Sourced HERE, before `mkcd` is defined and
# before the PWD hook is appended, because nushell binds a def body's and a
# closure's command calls at PARSE time: `_startdir_save` must already be in
# scope for `mkcd`, and `_dirstack_push` for the hook closure below.
source ~/.config/nushell/dirstack.nu

# `mkcd` — the single navigation funnel (epic invariant I1). An existing path
# behaves exactly like the builtin `cd`; a non-existent one is offered as a
# `mkdir`, so `cd some/new/nested/dir` + Enter just makes and enters it. `cd`
# with no argument goes home and `cd -` is passed straight through.
#
# Confirm semantics, and the manual already documents them this way: a BLANK
# keypress confirms (Enter, and also Space or Tab, because the test is for a
# non-blank key rather than for Enter specifically) and ANY non-blank key —
# including the reflex `y` — prints `aborted` and returns without moving.
#
# Every kind of move lands here: real `cd`, zoxide jumps (which reach it
# through the `cd` alias inside the generated init), picker jumps and the
# bare-word fallback. That is what makes this the one place the new-shell
# start dir is recorded — startdir.txt is updated however you moved.
#
# THE CONFIRM BINDING IS `let reply`. The live config binds it to `ans`
# instead. On nushell 0.115 `ans` became a BUILTIN variable name; an agent
# upgrading nushell hit the collision and broke this machine's login shell.
# The pinned version here is 0.114.1, where the old name still works — the
# point is that avoiding it costs nothing and keeping it cost a login shell.
# The gate greps for the banned binding by name, so the name itself is kept
# out of this file and a hit is proof of a regression rather than of a comment.
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

# The alias is written AFTER the def, and that ordering is load-bearing: alias
# targets and def bodies both resolve at parse time, so the `cd $target` inside
# `mkcd` above still binds to the BUILTIN and does not recurse. The alias only
# redirects the name typed at the prompt — and the name reached by everything
# downstream that calls `cd`, which is the other half of why it is here.
#
# IT MUST ALSO COME BEFORE THE GENERATED ZOXIDE INIT AT THE `GENERATED` ANCHOR
# BELOW, AND GETTING THAT WRONG FAILS SILENTLY. The generated
# ~/.cache/nushell/init/zoxide.nu calls `cd` in two places, and nushell binds
# those calls when it parses that file. Measured, two otherwise identical
# configs, same zoxide jump: with the alias BEFORE the source, the funnel ran
# (`MKCD-SAW /tmp`); with it AFTER, the jump still landed in the right place
# and printed NOTHING — no error, no warning — and startdir.txt and the
# dirstack simply never updated for zoxide jumps. Invariant I1 dies quietly.
# The gate asserts the two line numbers, which is why this is a checked
# artefact and not a convention.
alias cd = mkcd

# ── HOOKS ──
# This node appends EXACTLY ONE closure (see the empty-list comment in the
# record above). 04-shell/06's auto-list and its `stty sane` is the one other
# PWD append. 04-shell/03 appends NOTHING here: its `$env._NAV` guard lives on
# pre_execution/pre_prompt, because the PWD hook may not fire from
# pre_execution (its R7); the auto-list closure only reads the marker.
# THE DIRSTACK APPEND MUST STAY FIRST; tests/nushell-core.sh DO.1 checks it.
#
# `$before != null` skips the fire that happens at startup, `$after != $before`
# skips a non-move, and `$nu.is-interactive` keeps a scripted `nu -c` from
# writing to the recency stack at all. On the guard, see the measurement at the
# PALETTE anchor below — `is-terminal --stdout` is NOT usable in a condition.
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            _dirstack_push $after
        }
    }
)

# 04-shell/06's auto-list append: `la` after every real directory change,
# with the same three guards as the dirstack append above.
#
# `^stty sane` runs FIRST. A cd can arrive via a full-screen TUI that
# crashed mid-render and left the pty half-raw; with onlcr off the table's
# `\n` drops a row without returning to column 0 and the listing staircases.
# Sane mode is a no-op in the normal case.
#
# `$env._NAV?` is 04-shell/03's screen-clear guard: the bare-word fallback
# sets it when it is about to clear the screen, where an eager `la` would
# only be wiped. 03 OWNS setting the variable; this closure only reads it,
# and the optional access degrades safely — unset → "" → `la` runs.
#
# `try { la | print }` behind a width guard, NOT bare `la`. Every piece is
# load-bearing, measured on the pinned 0.114.1 under a real pty, 2026-08-22:
#   * the hook runner DISCARDS an env_change closure's return value — a bare
#     `la` computes the table and displays nothing, with no error. The
#     explicit print is what makes the listing appear at all.
#   * on a terminal reporting 0 columns the listing has THREE OUTCOMES, and
#     the wording retired here named none of them. Measured 2026-08-23 on the
#     pinned 0.114.1 under the DSR-answering pty runner, width guard removed
#     so the branch is reached. A NON-EMPTY directory prints ONE MESSAGE PER
#     CD — `Couldn't fit table into 0 columns!` — AND THE SESSION CARRIES ON:
#     two cds two messages, three cds three, `exit` still read, a 200-entry
#     directory no different. An EMPTY DIRECTORY SPINS THE SHELL AT 100% CPU:
#     no message, no further prompt, the next cd never read, `ps` reporting
#     state R at 98-100% until the runner kills it at its 40 s ceiling. And
#     the `try` CHANGES NEITHER OUTCOME — kept or removed, the message is
#     still printed and the spin is still unrecoverable, so neither one is a
#     catchable error.
#   * THE SPIN IS THE EMPTY TABLE AT ZERO WIDTH, NOT `la`. `[] | print` and
#     `print ([] | table)` spin identically at 0 columns, `[{a: 1}] | print`
#     prints the message and returns, and three repeats of the empty case
#     timed out identically.
#   * SO `(term size).columns > 0` IS A HANG GUARD AND A NOISE GUARD AT ONCE,
#     and the only thing that stops either — the `try` cannot. It skips the
#     listing where the terminal has no width to put it in, so a cd into an
#     empty directory is silent and the prompt returns. TWO READINGS ARE
#     RETIRED HERE. The unconditional hang claim, true only for the empty
#     directory it never mentioned; and the parenthetical that split the
#     typed path from the printed one, which claimed a difference that does
#     not exist — EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME. A typed bare
#     `la` prints the message too, and so does `nu -e 'la'`; all three spin
#     on an empty directory, 3/3 per cell. `tests/shell-listing.sh:158-166`
#     has had the message half right for months, as the reason its runner
#     sets a winsize; it never reached the empty case.
#   * the `try` is the last line of defence for whatever else the render can
#     throw, and its reach is NARROWER THAN A SESSION-WIDE LATCH. Measured
#     2026-08-23 on the pinned 0.114.1 under a real pty with a three-closure
#     config — a logger, a thrower, a second logger — driven twice: once with
#     `error make`, once with A MISSING EXTERNAL, and the two runs are
#     INDISTINGUISHABLE. The logger appended BEFORE the thrower recorded
#     every fire; the thrower's own tail and the logger appended AFTER it
#     recorded NOTHING, EVER; and one error box arrived per fire —
#     FOUR FIRES, FOUR BOXES. So an error aborts the REMAINDER OF ITS OWN
#     CLOSURE and every closure appended AFTER it, on EVERY fire. It does
#     not latch for a session, and it never touches a closure appended
#     before it.
#   * WHICH MAKES THE `try` LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION,
#     AND NOTHING ENFORCES THAT ORDER. The dirstack survives an unguarded
#     throw in this closure only because its own append at the HOOKS anchor
#     above is the FIRST one — it has already run by the time this body is
#     reached. Measured the same day against this very file, with one extra
#     PWD closure whose body is a missing external: appended AHEAD of the
#     dirstack push, DIRS.TXT IS NEVER CREATED AT ALL (two cds, two error
#     boxes); the identical closure appended after both, dirs.txt recorded
#     both moves. Same error, opposite outcome, decided only by position. A
#     failed listing must never take the dirstack down with it — and a later
#     node appending a PWD closure ahead of the dirstack push would move the
#     damage without touching a line of this block.
#
# AND ON `which`, BECAUSE THE REDIRECT IS NOT A GUARD. `e> /dev/null` does
# not suppress a not-found error: there is no child process whose stderr
# could be redirected, so nushell raises nu::shell::external_command before
# any spawn happens. Measured 2026-08-23 on the pinned 0.114.1 under a real
# pty with $env.PATH narrowed so `stty` does not resolve: ONE FULL ERROR BOX
# PER CD, quoting this very line — one cd one box, two cds two, three cds
# three.
#
# THE BLAST RADIUS IS WHY THIS OUTRANKS ITS LIKELIHOOD, and the measurement
# refines the `try` paragraph above. An error inside a PWD closure aborts
# THAT closure at the failing statement — so the `la` below never runs
# again — and every PWD closure appended AFTER it never runs either, while
# the closures appended BEFORE it keep firing on every move. It is not a
# session-wide latch: the failing closure re-fires and re-errors at each cd.
# Driven with a three-closure config, once with `error make` and once with a
# missing external, the two are indistinguishable: the closure before the
# failure logged all three moves, the closure after it logged none. So the
# damage today is bounded only by ORDER — S.1's dirstack push is the FIRST
# append and survives (measured: dirs.txt still recorded both moves with
# stty absent), the auto-list in this closure does not, and anything a later
# node appends after it would not either.
#
# /bin/stty is macOS base, so this is latent rather than live: it fires on a
# machine with a mangled PATH, which is exactly when the shell has to keep
# working. `try { ^stty sane e> /dev/null }` would contain the error too and
# is deliberately NOT the fix: it would equally swallow a REAL stty failure,
# where `which` says what it means and is the tree's settled idiom (env.nu's
# ollama-host probe, `tinty init` at the PALETTE anchor below, finder.nu's
# `tv` bail). COST of the lookup, same shell, same day: 100 lookups of an
# ABSENT name take 410 µs (~4 µs each), 100 of a present one 929 µs (~9 µs
# each) — three orders of magnitude under the spawn it gates, so R9's
# zero-work startup is untouched.
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            if (which stty | is-not-empty) { ^stty sane e> /dev/null }
            if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {
                try { la | print }
            }
        }
    }
)

# ── GENERATED ──
# The three shell integrations. These files are GENERATED at chezmoi-apply
# time by home/run_after_generate-shell-init.sh and are only `source`d here, so
# launching a shell does no setup work (R9).
#
# The paths are literal, and XDG_CACHE_HOME is deliberately NOT honoured:
# nushell resolves `source` at PARSE time and cannot read `$env`, so
# `source ($env.XDG_CACHE_HOME | path join ...)` is not expressible at all. One
# hardcoded path on both sides cannot diverge; a generator that honoured the
# variable while the shell could not would write to one directory and source
# from another, producing three failing `source` lines at every shell start.
#
# The generator's guarantee that all three files ALWAYS exist — even when the
# tool is missing, failing or silent, in which case it writes an empty file —
# is load-bearing here and not a nicety. A `source` of a missing file is
# `Error: nu::parser::sourced_file_not_found`, a PARSE error, and the radius
# is NOT "the shell refuses to start". It is worse than that, and it was
# measured 2026-08-23 on 0.114.1.
#
# INTERACTIVELY THE SHELL STARTS AND THE WHOLE FILE IS DISCARDED. With one
# bad `source` at the top, nu printed the error, reached a prompt (`print
# ALIVE=4` ran), and every command this file defines was gone — the ones
# ABOVE the failing line as well as the ones below. Four probes, two above
# and two below: all four answered `Command not found`; with the `source`
# line removed all four ran. NON-INTERACTIVELY it fails the other way round:
# `nu -c` prints the same error, NEVER RUNS THE COMMAND, and exits 1.
#
# So the failure mode to fear is A WORKING BUT NAKED REPL, which is harder to
# notice than a shell that refuses to start: nothing looks broken, everything
# is merely absent. That is what the copymode staging outage looked like from
# the inside.
source ~/.cache/nushell/init/starship.nu
source ~/.cache/nushell/init/zoxide.nu
source ~/.cache/nushell/init/television.nu

# ── MODULES ──
# One source line per module that exists in the managed tree. A module and
# its line land in the SAME change, because a `source` of a missing file is a
# parse error that DISCARDS THE WHOLE OF THIS FILE and leaves a working but
# naked REPL (measured; the GENERATED anchor above carries the numbers).
# chezmoi deploys the module and this line in one apply, which is what keeps
# the pair atomic on a real machine.
#
# 04-shell/07-quicklist SHIPS TWO MODULES, NOT ONE, and the order below is
# the reason. Nushell binds a def body's calls at parse time, and that node
# has a genuine cycle: zoxide.nu and finder.nu both CALL `_recents_add`, so
# the log must parse ABOVE both; the quicklist runner CALLS `_finder_decode`,
# `_finder_open`, `_finder_parse` and `finder`, so it must parse BELOW
# finder.nu. One file cannot sit on both sides of finder.nu. So recents.nu
# (the log, no dependencies) goes here, between claude.nu and zoxide.nu, and
# quicklist.nu (the runner) goes directly below finder.nu. An earlier version
# of this paragraph anticipated a single quicklist.nu above zoxide.nu; that
# guess is what the split corrects. Both lines are here now, and
# tests/shell-quicklist.sh executes the counterfactual: with recents.nu
# sourced below zoxide.nu, that file's four `_recents_add` call sites bind as
# EXTERNALS at parse.
source ~/.config/nushell/pass.nu
source ~/.config/nushell/claude.nu
source ~/.config/nushell/recents.nu
source ~/.config/nushell/zoxide.nu
source ~/.config/nushell/history.nu
source ~/.config/nushell/capsule.nu
source ~/.config/nushell/finder.nu
source ~/.config/nushell/quicklist.nu
source ~/.config/nushell/copymode.nu

# 06-help/02: the manual, and the capture that lets it delegate. THIS ORDER,
# and these three lines here rather than inside help.nu, are forced by the
# parser: `use std/help` and `def help` in ONE file fail at parse with
# `nu::parser::unknown_flag` into std/help/mod.nu:795 (nushell predeclares a
# block's defs, so std's `@example {help --find char}` resolves `help`
# against our signature, which has no `--find`). A `source`d file is its own
# block, so the `use` and the alias live here and only the `def` lives
# there. `core-help` must be an ALIAS and must come BEFORE the shadow: alias
# targets bind at parse time (the `core-ls` precedent), which is what keeps
# it pointing at std's `help` and stops the wrapper recursing.
use std/help
alias core-help = help
source ~/.config/nushell/help.nu

# ── PALETTE ──
# Re-assert the active tinty scheme, so the last `tinty apply` survives into
# every new shell.
#
# (a) WHY IT IS NEEDED: WezTerm's own `color_scheme` is only the BASE palette.
#     tinty persists the pick in its `current_scheme`, and tinted-shell
#     delivers it as OSC sequences the terminal applies at runtime. Nothing
#     re-emitted those at shell start, which is why every new terminal came up
#     looking like plain gruvbox no matter what had been applied.
# (b) WHY THE ARTIFACT AND NOT `tinty init`: the artifact is the very file
#     `tinty init` sources, but `init` also spawns the tinty binary and its
#     whole hook chain for hooks that are no-ops on an unchanged scheme.
#     Measured on this machine 2026-08-21, five runs each: sourcing the
#     artifact is ~5 ms (0.026 s total), `tinty init` is ~128 ms (0.641 s
#     total) — on every single shell start. `init` survives only as the
#     fresh-machine fallback, before any apply has generated the artifact.
# (c) WHY THE GUARD: the artifact writes its escapes to `$TTY` itself and
#     no-ops when that is not a writable terminal, so this is already inert
#     under `nu -c`. The guard is there to skip the SPAWN.
# (d) It is a no-op until something has been applied, so a machine that has
#     never picked a scheme simply keeps the terminal's base scheme.
# (e) It runs BEFORE anything that defines the `theme` command (the THEME
#     anchor below), so the re-assert is what a new shell sees first.
#
# This is the one deliberate exception to R9's "generated integrations are
# produced at apply time": the active scheme changes at RUNTIME, so nothing
# generated at apply time could carry it.
#
# THE GUARD IS `$nu.is-interactive`, AND IT IS NOT THE ONE THE LIVE CONFIG
# USES. Measured on nushell 0.114.1, 2026-08-21, under a real pty (a
# `/bin/sh -c '[ -t 1 ]'` spawned from inside nu answers yes there):
#
#     if (is-terminal --stdout) { ... }   ->  SKIPPED interactively
#                                             SKIPPED under `nu -c`
#     if $nu.is-interactive     { ... }   ->  FIRED   interactively
#                                             SKIPPED under `nu -c`
#
# `is-terminal --stdout` reports the redirection state of the CURRENT
# pipeline, and a parenthesised sub-expression captures stdout, so as an `if`
# condition it is false unconditionally — on a terminal or off one. The live
# config guards on it, which is why the re-assert it describes has never
# actually fired. `$nu.is-interactive` draws exactly the line these guards
# want, and is used at every guard in this file and in env.nu.
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
# 04-shell/09: the `theme` command, the A/B slots and the scheme picker. It
# sits AFTER the palette re-assert above, per R10(e), so a new shell has
# re-asserted the live scheme before anything can switch it. The file also
# parses standalone under `nu -n` — the terminal's F6 sources it out of band.
source ~/.config/nushell/theme.nu

# 04-shell/04-television's entry points. They live HERE, not in finder.nu,
# for a parse-order reason: nushell binds a def body's calls at parse time,
# and `tv_remote` dispatches to `theme` (defined by theme.nu, just above) and
# to `quicklist` (defined by quicklist.nu at MODULES). A def in finder.nu,
# sourced earlier than both, could bind neither. This is the live config's
# own layout. Content between anchors, not a new anchor: the gates grep the
# ten-anchor set.

# Ctrl-T: open the finder and splice the selection into the prompt at the
# cursor (fzf-style). Same first step as Ctrl-Space — the channel remote
# opens first. Paths/grep-files/commit-hashes are shell-quoted (reusing
# finder's own quoter) so spaces survive. Empty/aborted pick leaves the line
# untouched.
def tv_finder [] {
    let sel = (finder)
    if ($sel | is-empty) { return }
    let parts = ($sel | each { |it|
        let s = (match (($it | describe -d).type) {
            "record" => ($it.file? | default ($it.hash? | default ($it.sheet? | default ($it | to nuon))))
            _ => ($it | into string)
        })
        _finder_shquote $s
    })
    commandline edit --insert ($parts | str join " ")
}

# Ctrl-Space / F1: open the tv channels remote and ACT on the pick (vs
# Ctrl-T, which inserts). THREE channels are dispatched to their own runner
# rather than through the generic chain, for the same reason in all three
# cases — what the channel emits is not a path. `theme` runs the S.9 command,
# which draws its own tv screen and applies after exit; a scheme id through
# the generic chain would be handed to _finder_open as a path. `quicklist`
# runs 04-shell/07's runner, because a quicklist row is a TAB-delimited record
# of kind, value, cwd and channel, and the generic chain would hand that whole
# row to _finder_open as a path too. `manual` runs 06-help/03's browser, for
# exactly that second reason: its row is TAB-delimited (topic, id, title, and
# the entry's corpus index) and the generic chain would hand the whole row to
# _finder_open. The opacity picker is NOT dispatched and not special-cased — the wallpaper-opacity decision (2026-08-21) put it out
# of the minimal base and its cable is not shipped. Anything else runs the
# typed finder chain and opens the result by type (file -> editor, dir -> cd,
# commit -> git show). --env so a cd from the pick reaches the shell.
def --env tv_remote [] {
    if not $nu.is-interactive { return }
    let channel = (_finder_pick_channel)
    if ($channel | is-empty) { return }
    if ($channel == "theme") { theme; return }
    if ($channel == "quicklist") { quicklist; return }
    # RETURNS the browser's value rather than calling and discarding it, which
    # is the one place this arm differs from the theme and quicklist ones: those
    # two act (a retint, a cd, an editor) and have nothing to hand back, while
    # `_help_browse`'s `enter` RETURNS the entry's detail and returning it is
    # the whole of "enter prints that entry into the scrollback" (06-help/03 R4)
    # on this path too. `_help_browse "" ""; return` would swallow it and make
    # Ctrl-Space -> manual -> enter do nothing visible.
    if ($channel == "manual") { return (_help_browse "" "") }
    _finder_open (finder --start $channel)
}

# ── KEYBINDINGS ──
# LAST, and that is load-bearing: reedline resolves a duplicate
# (modifier, keycode) pair to the LATER entry, and 04-shell/05-history depends
# on beating the Ctrl-T and Ctrl-R that the generated television init binds at
# the GENERATED anchor above. Anything appended here wins.
#
# `esc_clear` is an UNCONDITIONAL `edit: clear`: the line goes whether or not a
# completion or history menu is open. `edit: clear` has no menu-close branch,
# so the two-stage "close the menu first, then clear" behaviour the live
# comment claims is not what the live code does either. The shipped manual
# (help/shell.nuon) already describes it as an unconditional clear with no
# menu-close branch, and this binding is what makes that entry true.
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

# 04-shell/05-history's keymap (its R5, and the reason this anchor is last):
# reedline resolves a duplicate (modifier, keycode) pair to the LATER entry,
# and this anchor sits after GENERATED, so the six records below beat the
# Ctrl-R the generated television init binds. The defs live in history.nu,
# sourced at MODULES.
#   Ctrl-R        local picker         Alt-R          global picker
#   Up/Down       local inline cycle   Shift+Up/Down  native global traversal
# Each arrow tries menuup/menudown FIRST — the `until` members no-op with no
# menu open — so completion menus keep the arrows (R4). Alt, not Ctrl-Shift,
# for the global picker: see the use_kitty_protocol comment at the CONFIG
# anchor above.
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

# 04-shell/04-television's keymap (its R4), appended AFTER 05-history's six —
# that node's gate asserts its six sit after esc_clear, so append, never
# interleave. Same last-entry-wins mechanism 05-history's R5 proved: this
# anchor sits after GENERATED, so `finder_pick` beats the Ctrl-T
# (tv_smart_autocomplete) the generated television init binds. F1 does not
# collide with files.toml's `shortcut = "f1"`: that shortcut fires only
# inside a running tv session.
#   Ctrl-Space / F1   run a channel and ACT on the pick (tv_remote)
#   Ctrl-T            run a channel and INSERT the pick, quoted (tv_finder)
$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings | append [
            {
                name: tv_remote
                modifier: control
                keycode: space
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_remote" }
            }
            {
                name: tv_remote_f1
                modifier: none
                keycode: f1
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_remote" }
            }
            {
                name: finder_pick
                modifier: control
                keycode: char_t
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_finder" }
            }
        ]
    )
)

# 04-shell/07-quicklist's keymap (its R3), appended as its OWN block AFTER
# 04-shell/04's three records — never interleaved, because that node's gate
# asserts its three sit together, in order, after S.6's six.
#
# `name: quicklist` IS NOT FREE CHOICE: help/shell.nuon's `Ctrl-Q` entry
# carries `verify: [{kind: "keybinding", name: "quicklist"}]`, and 06-help/04's
# `--check` resolves that name against this record. Renaming it breaks a
# shipped manual entry.
#
# NOTHING COMPETES FOR Ctrl-Q, measured rather than carried. The live config's
# comment says this record "overrides reedline's default ctrl+q (reverse
# history search)"; on the pinned 0.114.1
# `keybindings default | where ($it.code | str contains "q")` returns an EMPTY
# list, so there is no default Ctrl-Q to override and that sentence is not
# carried forward. `tv init nu` binds only char_t and char_r, and WezTerm's
# only `q` key is CTRL|SHIFT+q (window close). So the record needs no "wins
# over" reason; it sits at KEYBINDINGS because that anchor is where records
# go.
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
