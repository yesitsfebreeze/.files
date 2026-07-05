# config.nu — Nushell config, launched explicitly by WezTerm.
$env.config = {
    show_banner: false
    edit_mode: emacs
    # Block cursor; the terminal applies the blink.
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
        # Keep osc7 on: it reports the cwd to the host terminal, which WezTerm's
        # update-right-status reads to show the current directory (replacing the
        # static "default" workspace label). Default is already true; explicit here
        # so the disables above aren't mistaken for turning ALL integration off.
        osc7: true
    }
    # Auto-list on directory change. The PWD env_change hook fires on every cd,
    # zoxide jump, or picker (`finder`), so listing happens however you move. The
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

# Capture the builtin `ls` under a second name BEFORE we shadow `ls` below — alias
# targets resolve at parse time, so `core-ls` stays bound to the builtin and the
# wrappers can reach it without recursing.
alias core-ls = ls

# Decorate an `ls` table: sort (dirs first, newest last), prefix an icon column,
# and — only with `-D` — swap each directory's inode size (a flat ~4 KB) for its
# recursive on-disk size. The `du` swap is opt-in because it walks the whole tree
# under each dir (one `du` spawn, names matched back by the path du echoes), so a
# huge dir like node_modules would otherwise stall every plain `ls`/auto-list.
def decorate-ls [du: bool]: table -> table {
    let rows = ($in | sort-by type modified)
    let dirs = (if $du { $rows | where type == "dir" | get name } else { [] })
    let dir_sizes = if ($dirs | is-empty) { {} } else {
        ^du -sb ...$dirs e> /dev/null
        | lines
        | parse -r '(?<size>\d+)\s+(?<name>.+)'
        | reduce --fold {} {|it, acc|
            $acc | insert $it.name ($it.size | into int | into filesize)
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
            | get --optional ($row.name | path parse | get extension | str downcase)
            | default ""
        }
    }
    | move icon --before name
}

# Shadow `ls` so a bare `ls` (and l/ll/la) all show recursive folder sizes + icons.
# Flags are declared explicitly (not `--wrapped`) so the builtin reparses them as
# flags instead of treating them as paths; pattern defaults to "." because the
# builtin's empty-spread (`ls ...[]`) returns nothing rather than the cwd.
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
    let paths = (if ($pattern | is-empty) { ["."] } else { $pattern })
    # -D no longer goes to the builtin (its native --du also walks the tree); our
    # decorate-ls owns recursive dir sizing and only does it when $du is set.
    core-ls --all=$all --long=$long --short-names=$short_names --full-paths=$full_paths --directory=$directory --mime-type=$mime_type ...$paths
    | decorate-ls $du
}
def l  [path: string = "."] { ls    $path }
def ll [path: string = "."] { ls -l $path }
def la [path: string = "."] { ls -a $path }
alias cat = bat --paging=never
alias grep = rg
alias g = git
alias lg = lazygit
alias v = nvim
alias vi = nvim
alias nn = nvim ~/notes.md
alias cdi = zi

# Convenience aliases.
# Skip the per-tool prompts. With no args, fall back to a default prompt.

# _claude_share — an account profile isolates only credentials + settings; the
# heavy, meant-to-be-shared state (plugins, project/session history, caches…) is
# symlinked back to the top-level ~/.claude so it stays reachable from every login.
# .claude.json / settings are seeded once from the default so a new account starts
# configured (enabled plugins, MCP servers, project trust) but then diverges; the
# credentials file is left absent on purpose so the account logs in fresh.
def _claude_share [root: path, name: string] {
  let profile = ($root | path join $name)
  mkdir $profile
  let shared = [
    plugins projects sessions session-env history.jsonl cache file-history
    shell-snapshots agent-memory hooks hub jobs plans backups paste-cache
    context-mode debug tasks teams telemetry
  ]
  for item in $shared {
    let src = ($root | path join $item)
    let dst = ($profile | path join $item)
    if (($src | path exists) and (not ($dst | path exists))) {
      ^ln -s $src $dst
    }
  }
  for f in [".claude.json" "settings.json" "settings.local.json"] {
    let src = ($root | path join $f)
    let dst = ($profile | path join $f)
    if (($src | path exists) and (not ($dst | path exists))) {
      cp $src $dst
    }
  }
}

# _claude_login — pick a login profile and return its CLAUDE_CONFIG_DIR.
# A profile is a subdir of ~/.claude that _claude_share seeded with its own
# settings.json; Claude's internal dirs (projects, sessions, cache…) never carry one,
# so they self-filter. The last-used profile (recorded in ~/.claude/.last-login) is
# listed first, so a bare Enter relaunches it. The "＋ new login" entry creates a
# fresh, isolated profile. Returns null on cancel (Esc / empty name).
def _claude_login [] {
  let root = ($env.HOME | path join ".claude")
  let last_file = ($root | path join ".last-login")
  let new_label = "＋ new login"

  # Detect profiles by their seeded settings.json, NOT .credentials.json: on macOS
  # Claude keeps credentials in the login Keychain (service "Claude Code-credentials"
  # plus a per-CLAUDE_CONFIG_DIR "…-<hash>" entry), so no per-profile .credentials.json
  # file is ever written — the old check found nothing and the picker came up empty on
  # Mac. settings.json is copied by _claude_share for every profile and works on both
  # Linux (file creds) and macOS (Keychain). The top-level ~/.claude is always offered
  # as "default".
  let profiles = (ls $root
    | where type == dir
    | get name
    | where {|d| ($d | path join "settings.json" | path exists) }
    | each {|d| $d | path basename }
    | sort)
  let profiles = (["default"] ++ ($profiles | where {|p| $p != "default" }))

  let last = (if ($last_file | path exists) { open $last_file | str trim } else { "" })
  let ordered = (($profiles | where {|p| $p == $last }) ++ ($profiles | where {|p| $p != $last }))
  let sel = (($ordered | append $new_label) | input list --fuzzy "claude login")
  if ($sel | is-empty) { return null }

  let name = (if $sel == $new_label { (input "new login name: " | str trim) } else { $sel })
  if ($name | is-empty) { return null }

  # "default" maps to the top-level ~/.claude; any other name is a subdir profile
  # that shares the heavy state and only keeps its own credentials + settings.
  let dir = (if $name == "default" { $root } else { ($root | path join $name) })
  if $name != "default" {
    mkdir $dir
    _claude_share $root $name
  }
  $name | save -f $last_file
  $dir
}

def cc [...args] {
  let dir = (_claude_login)
  if ($dir | is-empty) { return }
  with-env { CLAUDE_CONFIG_DIR: $dir } {
    if ($args | is-empty) {
      claude --dangerously-skip-permissions
    } else {
      claude --dangerously-skip-permissions ...$args
    }
  }
}

# cr — like cc, but resume a session within the chosen profile.
def cr [...args] {
  let dir = (_claude_login)
  if ($dir | is-empty) { return }
  with-env { CLAUDE_CONFIG_DIR: $dir } {
    claude --dangerously-skip-permissions --resume ...$args
  }
}
alias bb = burrito                                # spawn-or-attach default session
alias ba = burrito --attach                       # attach to an existing session
# Vim/editor muscle memory for quitting the shell.
alias "/exit" = exit
alias ":q" = exit
alias q = exit

# Reload dotfiles: re-pull source and re-apply. --force overwrites local drift
# without prompting.
alias rr = chezmoi update --force

# `dirstack`: directory-history helpers. Sourced HERE (before mkcd and the PWD hook
# below) so `_startdir_save` is in scope for mkcd and `_dirstack_push` for the hook.
# Drives both the new-shell start dir (env.nu reads startdir.txt) and the Alt-O picker.
source ~/.config/nushell/dirstack.nu

# cd that creates missing directories. Existing paths behave exactly like the
# builtin (and still fire the PWD auto-list hook below); a non-existent target is
# `mkdir`-ed first, so `cd some/new/path` + Enter just makes and enters it. `cd`
# (home) and `cd -` (previous dir) are passed straight through.
#
# The wrapper is named `mkcd` and `cd` is aliased to it *after* the def, so the
# `cd $target` in the body still resolves to the builtin (no recursion); the
# alias only redirects the names typed at the prompt.
#
# mkcd is also the single funnel every `cd` flows through — real `cd`, zoxide jumps
# (z/zi reach it via the `cd` alias inside __zoxide_z), `zz`, and picker jumps. So
# this is where we record the new-shell start dir: ANY move into a directory updates
# startdir.txt, so a new shell opens wherever we last navigated — by whatever means.
# The recency stack (Alt-O) likewise logs every move via the PWD hook below.
def --env mkcd [dir?: path] {
    let target = if ($dir | is-empty) { $env.HOME
    } else if $dir == "-" { "-"
    } else { $dir | path expand }
    if $target != "-" and not ($target | path exists) {
        let ans = (input --numchar 1 $"Create '($target)' ? Enter to confirm. All else will cancel. ")
        if ($ans | str trim) != "" {
            print "aborted"
            return
        }
        mkdir $target
    }
    cd $target
    _startdir_save $env.PWD
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

# jj — find the zoxide-known dir named `journal` that has a `vicky` subfolder
# (disambiguates from any other `journal`), cd into it, and open Claude there.
def --env jj [] {
    let matches = (zoxide query -l journal
        | lines
        | where {|p| ($p | path basename) == "journal" and ($p | path join vicky | path exists) })
    if ($matches | is-empty) {
        error make { msg: "jj: no zoxide-known `journal` dir with a `vicky` subfolder" }
    }
    cd ($matches | first)
    cc
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
# `stty sane` first: a cd may arrive via a full-screen TUI (television in `finder`,
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
            _dirstack_push $after
            # A z-fallback jump (below) clears the screen in pre_prompt to bury the doomed
            # "command not found"; an eager `la` here would only be wiped, so skip it.
            if ($env._NAV? | default "" | is-empty) { la }
        }
    }
)

# Source shell integrations. These files are generated at apply time by the
# chezmoi run_after script, not at shell start, so launching the shell does no
# setup work.
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/television/init.nu

# `finder`: composable, typed fuzzy finder — chains tv channels, returns nu data. Sourced
# HERE (before the zoxide wrappers below) so `_recents_add` is in scope for them: nushell
# resolves a def body's command calls at parse time, so the recents logger must already be
# loaded when `_z_nav`/`_zi_nav` are parsed.
source ~/.config/nushell/finder.nu

# Wrap the generated z/zi. The jump itself goes through mkcd (via the `cd` alias
# inside __zoxide_z), so it already records the new-shell start dir — a zoxide jump
# is treated as a real move, same as `cd`. These wrappers add two things on top:
# `z` also opens (if the single arg resolves to an existing file, edit it; otherwise
# it's a directory query handed to zoxide), and both log the navigation into the
# cross-channel recents stack (the `quicklist` source) via `_recents_add`, so a
# `z`-opened file or jumped-to dir resurfaces there alongside finder picks. Dir jumps
# log only when PWD actually moved (a no-match `z` leaves it put — nothing to record);
# file opens always log the edited path. `cdi` (aliased to `zi` before zoxide loads)
# forward-references zi, so it follows these overrides too — verified: a pre-zoxide
# alias-to-alias resolves the latest target.
def --env --wrapped _z_nav [...rest: string] {
    let target = ($rest | str join " " | path expand)
    if (($rest | length) == 1 and ($target | path type) == "file") {
        _recents_add "FileList" $target "zoxide"
        ^$env.EDITOR $target
    } else {
        let before = $env.PWD
        __zoxide_z ...$rest
        if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
    }
}
def --env --wrapped _zi_nav [...rest: string] {
    let before = $env.PWD
    __zoxide_zi ...$rest
    if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
}
alias z = _z_nav
alias zi = _zi_nav

# zc — like `z`, but directories only, then drop into a Claude (`cc`) session in
# the jumped-to dir. The jump lands in the Alt-O recency stack and updates the
# new-shell start dir (via mkcd, same as any move), then launches `cc` right there.
# No file-edit branch — unlike `z`, `zc` is dirs only by design.
def --env --wrapped zc [...rest: string] {
    __zoxide_z ...$rest
    cc
}

# `zz` — step back to the previous directory (the dir-history toggle). Pairs with the
# z-fallback below: a bare unknown token jumps forward via zoxide, `zz` steps back.
alias zz = cd -

# z as the default verb. A bare line whose first word is NOT a known command, path, or
# nu expression is treated as a zoxide navigation query — `proj` ⏎ jumps just like
# `z proj`, no prefix typed. Real commands, paths, and any pipeline/expression run
# untouched. This is the "zoxide as a fallback when nothing was found" behaviour.
#
# Nushell gives no clean hook for this: `command_not_found` can't cd (its env changes are
# discarded) and the unknown command always errors. So we jump from `pre_execution`, where
# a cd DOES persist, then bury the doomed command's "not found" by CLEARING the screen in
# `pre_prompt` (after the error has printed) and letting the next prompt redraw fresh in
# the jumped-to dir. A clear is the only scroll-safe wipe — the prompt usually sits at the
# bottom of the screen, so the error scrolls the view and any cursor-restore trick misses
# it; and reedline repaints over anything pre_prompt prints, so a post-clear `la` can't
# survive (the new-dir prompt is the jump's confirmation instead).
#
# We jump ONLY on a genuine zoxide dir match (querying directly, not via __zoxide_z, whose
# empty no-match result would `cd` HOME); a no-match line falls straight through to the
# normal "command not found", and the screen is left untouched.
def --env _z_fallback [] {
    if not (is-terminal --stdout) { return }
    let buf = (commandline | str trim)
    if ($buf | is-empty) { return }
    # any shell/nu metacharacter means it is an expression or a real invocation — leave it.
    let meta = ['|' '>' '<' ';' '&' '(' ')' '{' '}' '[' ']' '$' '`' '"' "'" '#' '^' '=' '!']
    if ($meta | any {|c| $buf | str contains $c }) { return }
    let tokens = ($buf | split row -r '\s+')
    let first = ($tokens | first)
    # a resolvable name (builtin/alias/def/external) or a path-ish token is a real command.
    if (which $first | is-not-empty) { return }
    # bail only on real path operators — a leading '/' or '~', any embedded '/' (so `./x`,
    # `../x`, `~/x`, `a/b` are paths), a flag, or bare `.`/`..`. A dotdir NAME like `.files`
    # is NOT a path operator, so it stays a valid zoxide nav target.
    if ($first | str starts-with '-') or ($first | str starts-with '/') or ($first | str starts-with '~') or ($first | str contains '/') or ($first in ['.' '..']) { return }
    # candidate navigation: ask zoxide directly, jump only on a genuine dir match.
    let q = (^zoxide query --exclude $env.PWD -- ...$tokens | complete)
    if $q.exit_code != 0 { return }
    let path = ($q.stdout | str trim)
    if ($path | is-empty) or (($path | path type) != 'dir') { return }
    cd $path
    # cd in pre_execution may not trip the env_change PWD hook, so log the Alt-O recency
    # entry here (mirrors the `z` wrappers); _dirstack_push dedups if the hook also fired.
    # (`cd` → mkcd already recorded the new-shell start dir.)
    _dirstack_push $env.PWD
    _recents_add "DirList" $env.PWD "zoxide"
    $env._NAV = "1"                   # signal the screen-clear in pre_prompt
}
$env.config.hooks.pre_execution = (
    ($env.config.hooks.pre_execution? | default [])
    | append {|| _z_fallback }
)
$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {||
        if ($env._NAV? | default "" | is-not-empty) {
            $env._NAV = ""
            print -n $"(char -u '1b')[2J(char -u '1b')[H"   # clear screen + cursor home
        }
    }
)

# History keymap, appended after the television init so it overrides tv's own
# Ctrl-R binding (reedline keys the map by (modifier,keycode); a later entry wins).
#   Ctrl-R        local picker        Alt-R         global picker
#   Up/Down       local inline cycle  Shift+Up/Down native global traversal
# Each arrow falls through to menu nav first (`until` tries menuup/menudown, which
# no-op when no menu is open, then runs ours), so completion menus still work.
#
# use_kitty_protocol stays OFF: with it on, reedline fires the kitty support query
# twice at startup and the WSL2<->WezTerm PTY returns the reply too late to consume,
# so it leaks as `^[[?0u` above the prompt. The only thing kitty bought us was
# telling Ctrl-Shift-R apart from Ctrl-R (shift is lost on control+letter); the
# global picker now uses Alt-R, which is byte-distinct without kitty.
$env.config.use_kitty_protocol = false
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
            {
                # ctrl+space: open the tv channels remote directly (the finder). Type a
                # channel's prefix to pick it — `q` lands on the quicklist of recent picks.
                name: tv_remote
                modifier: control
                keycode: space
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_remote" }
            }
            {
                # Escape: close any open menu first; if none, clear the line (like Ctrl-C).
                name: esc_clear
                modifier: none
                keycode: escape
                mode: [emacs vi_insert]
                event: { edit: clear }
            }
            {
                # Ctrl-T: open the finder, insert its selection at the cursor.
                # Overrides tv init.nu's Ctrl-T (tv_smart_autocomplete) — appended later wins.
                name: finder_pick
                modifier: control
                keycode: char_t
                mode: [vi_normal vi_insert emacs]
                event: { send: executehostcommand, cmd: "tv_finder" }
            }
        ]
    )
)

# Live theme: re-emit the last `theme` pick's palette so it persists into new shells.
# A fresh shell only needs the OSC retint. `tinty init` would deliver it, but it first
# spawns the tinty binary AND its hook chain (wezterm-colors.sh + zebar-colors.sh) —
# ~65ms — and those two hooks are no-ops on an unchanged scheme (they regenerate only on
# a real `theme` switch). So source tinty's cached tinted-shell artifact directly: it is
# the exact file `tinty init` sources ($TINTY_THEME_FILE_PATH), writing the same palette
# OSC straight to the tty in a single bash spawn (~5ms). Fall back to `tinty init` only
# when the artifact is absent (fresh machine, before the first apply). stdout is left
# attached on purpose — that IS the retint. No-op until you pick a theme, so Gruvbox stands.
if (is-terminal --stdout) {
    let data = ($env.XDG_DATA_HOME? | default ($nu.home-dir | path join ".local" "share"))
    let palette = ($data | path join "tinted-theming" "tinty" "artifacts" "tinted-shell-scripts-file.sh")
    if ($palette | path exists) {
        try { ^bash $palette e> /dev/null }
    } else if (which tinty | is-not-empty) {
        try { ^tinty init e> /dev/null }
    }
    # tinted-shell's OSC 11 above sets bg to the scheme's base00; re-emit our
    # background-override (if any) so it wins. stdout stays attached — that IS the retint.
    let bg_override = ($nu.home-dir | path join ".config" "tinted-theming" "tinty" "bg-override.sh")
    if ($bg_override | path exists) { try { ^bash $bg_override e> /dev/null } }
}

# `theme`: fuzzy picker over tinty's official base16/base24 catalog with apply-on-focus preview.
source ~/.config/nushell/theme.nu

# `pass` (password-store) completion: subcommands + live entry names from the store.
source ~/.config/nushell/pass.nu

# Ctrl-T: open the finder and splice the selection into the prompt at the cursor
# (fzf-style). `--fresh` skips resuming the last search so the key is non-blocking.
# Paths/grep-files/commit-hashes are shell-quoted (reusing finder's own quoter) so
# spaces survive. Empty/aborted pick leaves the line untouched.
def tv_finder [] {
    let sel = (finder --fresh)
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

# `quicklist`: the cross-channel "recent picks" channel + its open/replay runner.
source ~/.config/nushell/quicklist.nu

# Ctrl-Space: open the tv channels remote and ACT on the pick (vs ctrl-t which inserts).
# Pick a channel from the remote; `quicklist` (type `q`) drops into the recents picker,
# anything else runs the typed finder chain and opens the result by type (file -> editor,
# dir -> cd, commit -> git show). --env so a cd from the pick reaches the shell.
def --env tv_remote [] {
    if not (is-terminal --stdin) { return }
    let channel = (_finder_pick_channel [] null)
    if ($channel | is-empty) { return }
    if ($channel == "quicklist") { quicklist; return }
    # `theme` produces scheme-id strings, not paths — routing them through _finder_open
    # would `^$env.EDITOR base16-…` (open the id in nvim). Hand off to the `theme` command,
    # which runs the same picker and applies the pick via _theme_commit (tinty apply).
    if ($channel == "theme") { theme; return }
    _finder_open (finder --start $channel --fresh)
}
