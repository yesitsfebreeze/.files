# help-check.nu — `help --check`, the manual's drift check (06-help/04-drift-check).
#
# WHY THIS IS NOT IN help.nu, AND CANNOT BE. help.nu carries R8's no-spawn
# guarantee, and tests/shell-help.sh enforces it twice: `render_no_spawn_ok`
# greps the whole file (with `_help_browse`'s body excised) for `nvim`,
# `wezterm`, `git`, `tv` or `chezmoi` in command position, and
# `browse_only_spawner_ok` asserts `_help_browse` is the ONLY def in that file
# naming a spawn target. This check spawns `nvim --headless`, so a single line
# of it inside help.nu turns both gates red. The flag lives on `def help`;
# every line that spawns lives here.
#
# SOURCED BEFORE help.nu, NOT AFTER. Measured on the pinned 0.114.1: a `def`
# in one sourced file calling a `def` from a file sourced LATER fails at run
# time with `nu::shell::external_command — Command not found`, because each
# `source` is its own block and predeclaration does not cross it. So config.nu
# holds `source ~/.config/nushell/help-check.nu` above
# `source ~/.config/nushell/help.nu`, and the order is gated.
#
# EXIT CODE IS `error make`, NOT `exit` (R7). `exit 1` inside a def closes the
# INTERACTIVE shell — `help --check` typed at a prompt would end the session.
# `error make` gives rc 1 under `nu -c` (which is what a commit hook or CI
# runs) and prints an error at a prompt without killing it. The report is
# printed before the raise, so a failing run still shows what drifted.

# ── the corpus ──────────────────────────────────────────────────────────────
#
# Addressed by the SAME `~`-literal help.nu uses, for help.nu's own recorded
# reason (its THE CORPUS header): the renderer and the checker must read the
# same tree or the check certifies a manual nobody renders.
def _hc_dir [] {
    let dir = ($nu.home-dir | path join ".config" "nushell" "help")
    if not ($dir | path exists) {
        error make {msg: $"help --check: the manual's corpus directory ($dir) is missing — run `chezmoi apply`"}
    }
    $dir
}

# Every verify target in the corpus, flattened, each carrying the id and title
# of the entry it came from so a report names the entry a reader can look up.
def _hc_targets [] {
    let dir = (_hc_dir)
    ["shell" "nvim" "terminal" "capsule"] | each {|f|
        let p = ($dir | path join $"($f).nuon")
        if not ($p | path exists) {
            error make {msg: $"help --check: the manual is missing ($p) — run `chezmoi apply`"}
        }
        let rows = (open $p)
        if (not (($rows | describe) =~ '^(list|table)')) { return [] }
        $rows | each {|e|
            let id = (if (($e.key? | default "") | is-not-empty) { $e.key } else { $e.cmd? | default "" })
            $e.verify | each {|t|
                # `desc` is THREE-STATE (epic I5), so absence is recorded as a
                # boolean here and never collapsed into null: a target that
                # OMITS desc compares against the title, one that writes
                # `desc: null` asserts existence only. `open` on a
                # heterogeneous .nuon keeps the records heterogeneous, which
                # is the only reason `"desc" in ($t | columns)` can tell them
                # apart at all.
                {
                    file: $f
                    id: $id
                    title: $e.title
                    kind: $t.kind
                    name: ($t.name? | default "")
                    mode: ($t.mode? | default "")
                    lhs: ($t.lhs? | default "")
                    has_desc: ("desc" in ($t | columns))
                    desc: ($t.desc? | default null)
                    scope: ($t.scope? | default "global")
                    # tmux-key and wezterm-key. `table` defaults to each
                    # reader's own root: tmux calls it `root`, WezTerm has no
                    # name for it at all and prints it first, which is why the
                    # empty string is the WezTerm default rather than a
                    # borrowed word.
                    key: ($t.key? | default "")
                    mods: ($t.mods? | default "NONE")
                    table: ($t.table? | default "")
                }
            }
        } | flatten
    } | flatten
}

# ── nvim lhs normalization (R2) ─────────────────────────────────────────────
#
# `nvim_get_keymap` does NOT return the lhs you wrote. The corpus holds the
# written form because the manual has to show what you press, so every
# comparison goes through here. Measured against Neovim 0.12.4 with the repo's
# config staged, 2026-08-29 — WITHOUT this, 30 of 66 targets resolve; WITH it,
# 58. The 36 false "stale" reports are silent and look exactly like a real
# regression, which is why this is a table and not a guess.
#
#   written          returned
#   <leader>ff       "  ff"      leader is <Space> in this config
#   <space>          " "         the seventh rule, and it is NOT in the
#                                corpus README's six-row table — found by
#                                `<leader><space>`, which returns "  " and
#                                was the single global miss after the other six
#   <C-h>            <C-H>       the letter upper-cases
#   <A-j>            <M-j>       alt is reported as meta
#   <S-h>            H           shift on a LETTER folds into the letter
#   <S-Right>        <S-Right>   shift on a NAMED key does not fold
#   <                <lt>
def _hc_norm_lhs [lhs: string] {
    mut s = ($lhs | str replace --all "<leader>" " " | str replace --all "<Leader>" " ")
    $s = ($s | str replace --all --regex "<[Ss]pace>" " ")
    $s = ($s | str replace --all --regex "<A-([^>]+)>" "<M-${1}>")
    $s = ($s | str replace --all --regex "<C-([a-zA-Z])>" "<C-${1}>")
    # nushell's regex replace has no case operator, so the upper-casing of a
    # control letter is done by hand over the alphabet rather than pretended.
    for c in ([a b c d e f g h i j k l m n o p q r s t u v w x y z]) {
        $s = ($s | str replace --all $"<C-($c)>" $"<C-($c | str uppercase)>")
        $s = ($s | str replace --all $"<S-($c)>" ($c | str uppercase))
        $s = ($s | str replace --all $"<S-($c | str uppercase)>" ($c | str uppercase))
    }
    if $s == "<" { return "<lt>" }
    $s
}

# ── the shell surface (R1) ──────────────────────────────────────────────────
#
# INTROSPECTION MUST RUN IN A CONFIGURED SHELL. A bare `nu -c` has no config
# loaded and reports zero keybindings and zero of our aliases — measured: the
# live `$env.config.keybindings` is empty under `nu -c` and holds 11 named
# entries under the repo's config.nu. This def runs INSIDE the configured
# shell by construction, because it is sourced by that config; nothing is
# spawned to reach it.
def _hc_shell_live [] {
    {
        keybinding: ($env.config.keybindings | get name | uniq)
        alias: (scope aliases | get name)
        command: (scope commands | where type == "custom" | get name)
    }
}

# ── the Neovim surface (R2) ─────────────────────────────────────────────────
#
# One headless spawn for the whole check, never one per target: the process is
# the cost. Every mode the schema admits is dumped in that one run.
#
# THE SPAWN OBSERVES, IT NEVER PROVISIONS (R2). A start that installs is a
# start that changes the answer it is being asked for. Measured 2026-08-29:
# lazy.nvim git-cloned persistence.nvim from the network in the middle of a
# check because the lockfile named it and the store did not have it, and the
# clone chatter on stdout killed the JSON parse. `HELP_CHECK=1` turns
# lazy's `install.missing` and its update `checker` off
# (home/dot_config/nvim/lua/config/lazy.lua) — and the dump READS THAT SETTING
# BACK, so the guard is proven in force on every run instead of assumed.
#
# AND EVERY WAY THE DUMP CAN BE DEGRADED RAISES, because a degraded dump is
# indistinguishable from drift and reads as OUR bug. Four of them, each with
# its own message: no config at all (Neovim answers with its own 123 defaults
# — 54 false stales, measured), lazy.nvim not loaded, the install guard not in
# force, and any declared plugin absent from the store (its maps are simply
# not there, so every map it provides reads as stale).
def _hc_nvim_live [] {
    if (which nvim | is-empty) {
        error make {msg: "help --check: nvim is not on PATH — the Neovim surface cannot be introspected"}
    }
    # THE DUMP GOES TO A FILE, NEVER TO STDOUT. Anything the config or a
    # plugin prints at startup shares stdout with the payload, and the check
    # then dies in `from json` on someone else's chatter — which is how the
    # clone above was found. A file the spawn is handed by env cannot be
    # written into by a plugin that does not know its name.
    let dump = (mktemp -t "help-check-nvim-XXXXXX")
    # A REAL FILE ON DISK, WITH A REAL EXTENSION, created here rather than in
    # the Lua: the buffer-local dump needs FileType to have fired, and a
    # scratch buffer with `setfiletype` fires it without the rest of the
    # pipeline that plugins actually hang off.
    let probe_base = (mktemp -t "help-check-buf-XXXXXX")
    let probe = ($probe_base + ".lua")
    "local x = 1\nreturn x\n" | save -f $probe
    rm -f $probe_base
    let lua = '
local maps = {}
for _, m in ipairs({"n","v","x","i","o","t","c","s"}) do
  for _, k in ipairs(vim.api.nvim_get_keymap(m)) do
    maps[#maps+1] = {mode = m, lhs = k.lhs, desc = k.desc}
  end
end

-- BUFFER-LOCAL MAPS (04-nvim-buffer-maps). Eight documented targets carry
-- `scope: "buffer"` and are invisible to the global dump above, because they
-- attach to a buffer on an event. Two events, and only one of them can be
-- fired here:
--
--   FileType  — fired by opening a real file. The autopairs <BS>/<CR> pair
--               and the
--               filetype-local maps come back this way, and this dump
--               gets them. (An apostrophe must not appear anywhere in this
--               block: the whole Lua program is a single-quoted nushell
--               string, and one closes it.)
--   LspAttach — needs a language server to start, install itself through
--               mason if absent, index the file and reply. That is a network
--               install and seconds of wall clock inside a check that has to
--               be cheap enough to run before every commit, and it would make
--               the manual correctness depend on a server being reachable.
--               NOT DONE, deliberately; those targets stay UNRESOLVED and the
--               measurement below is what says so rather than a guess:
--               `lsp_clients` is how many attached in the time this spawn
--               takes, and it is reported.
--
-- A real file on disk, not a scratch buffer: `setfiletype` fires FileType
-- without the rest of the pipeline, and autopairs attaches on BufEnter.
local buf_maps = {}
local probe = vim.env.HELP_CHECK_PROBE
-- `silent`, and it is not cosmetic: a headless nvim writing the "N lines"
-- message to a stdout nushell is capturing died on SIGPIPE (exit -13) every
-- run. Measured 2026-08-30.
pcall(vim.cmd, "silent edit " .. probe)
-- WAIT ON A CONDITION, NOT A DURATION. A FileType map arriving is the event
-- being waited for; `vim.wait(200, function() return false end)` spins for
-- 200ms and can still return before a lazily-loaded plugin has attached.
vim.wait(2000, function() return #vim.api.nvim_buf_get_keymap(0, "n") > 0 end)
for _, m in ipairs({"n","v","x","i","o"}) do
  for _, k in ipairs(vim.api.nvim_buf_get_keymap(0, m)) do
    buf_maps[#buf_maps+1] = {mode = m, lhs = k.lhs, desc = k.desc}
  end
end
local lsp_clients = 0
if vim.lsp and vim.lsp.get_clients then
  lsp_clients = #vim.lsp.get_clients({ bufnr = 0 })
end

-- `missing` is a STRING, not a list: vim.json.encode writes an empty Lua
-- table as `{}` (an object), which would arrive in nushell as a record and
-- make `is-empty` mean something different from what it means on a list.
local missing, installed, install_missing = {}, 0, nil
local ok, cfg = pcall(require, "lazy.core.config")
if ok then
  install_missing = cfg.options.install.missing
  for name, p in pairs(cfg.plugins) do
    if (vim.uv or vim.loop).fs_stat(p.dir) then
      installed = installed + 1
    else
      missing[#missing+1] = name
    end
  end
end
local f = assert(io.open(vim.env.HELP_CHECK_DUMP, "w"))
f:write(vim.json.encode({
  maps = maps,
  n_maps = #maps,
  buf_maps = buf_maps,
  n_buf_maps = #buf_maps,
  lsp_clients = lsp_clients,
  lazy = ok,
  installed = installed,
  missing = table.concat(missing, " "),
  install_missing = install_missing,
}))
f:close()
'
    # THE CONFIG MUST BE THERE, AND ITS ABSENCE MUST RAISE. Measured
    # 2026-08-29: with no config on the machine, `nvim --headless` starts
    # anyway and `nvim_get_keymap` returns Neovim's OWN defaults — 123 maps
    # against the 214 a configured start reports. The check then declared 54
    # of our maps stale and one mismatched, every one of them false, and it
    # exited non-zero for the wrong reason. A missing config is not drift.
    let init = ($nu.home-dir | path join ".config" "nvim" "init.lua")
    if not ($init | path exists) {
        error make {msg: $"help --check: ($init) is missing — the Neovim surface cannot be introspected, and a bare `nvim` would report Neovim's own defaults as drift"}
    }
    # NO `--clean`, AND NO `--noplugin`. Either one skips the plugin and site
    # directories, which is the same silent degradation by a second route: 123
    # maps instead of the config's own count, and every plugin-provided map we
    # document reads as stale. The install guard is an env variable precisely
    # because the command-line flags that stop plugins loading also stop them
    # being seen.
    # `complete` captures stdout, stderr and the code together, so nvim's
    # startup chatter never reaches the report. It must wrap the external
    # DIRECTLY — a redirection in between makes it "only works on external
    # commands".
    # THE SPAWN'S OUTPUT GOES TO A FILE, NOT THROUGH A PIPE. Measured
    # 2026-08-30: `^nvim … | complete` died with exit -13 — SIGPIPE — on runs
    # where the spawn lived long enough to write anything to stdout, which is
    # every run now that the dump waits for a language server to attach. A
    # redirection has no reader to go away.
    let spawnlog = (mktemp -t "help-check-nvim-log-XXXXXX")
    # `complete` only wraps an external directly, and a redirection is not
    # one — so the exit status is taken from `$env.LAST_EXIT_CODE` after a
    # `do -i` that cannot itself raise.
    let rc = (with-env {HELP_CHECK: "1", HELP_CHECK_DUMP: $dump, HELP_CHECK_PROBE: $probe} {
        do -i { ^nvim --headless -c $"lua ($lua)" -c "qa!" out+err> $spawnlog }
        $env.LAST_EXIT_CODE
    })
    let out = {exit_code: $rc}
    let spawn_said = (if ($spawnlog | path exists) { open --raw $spawnlog } else { "" })
    rm -f $spawnlog
    rm -f $probe
    if $out.exit_code != 0 {
        rm -f $dump
        error make {msg: $"help --check: nvim --headless exited ($out.exit_code) — ($spawn_said | str trim)"}
    }
    if (not ($dump | path exists)) or (($dump | path type) != "file") {
        error make {msg: "help --check: the headless spawn wrote no keymap dump — nvim started but the check's lua never ran"}
    }
    let raw = (open --raw $dump)
    rm -f $dump
    if ($raw | str trim | is-empty) {
        error make {msg: "help --check: the headless spawn wrote an empty keymap dump"}
    }
    let j = ($raw | from json)
    if $j.lazy != true {
        error make {msg: "help --check: lazy.nvim did not load in the headless spawn — the dump would be Neovim's own defaults, not this configuration"}
    }
    if $j.install_missing != false {
        error make {msg: "help --check: the spawn was allowed to install plugins (lazy `install.missing` is not false) — HELP_CHECK is not being honoured by lua/config/lazy.lua, and a check that provisions cannot be trusted to observe"}
    }
    if ($j.missing | is-not-empty) {
        error make {msg: $"help --check: these plugins are declared but not installed: ($j.missing). Their maps are absent from the dump and would report as stale. Install them first — `nvim --headless \"+Lazy! restore\" +qa` — then re-run the check"}
    }
    if $j.n_maps == 0 {
        error make {msg: "help --check: the headless spawn reported zero global maps, which no working configuration does"}
    }
    # The buffer dump rides along with the global one — same spawn, so the
    # process cost is unchanged. Returned as a record rather than a bare list
    # because the resolver needs the LSP measurement too.
    {global: $j.maps, buffer: ($j.buf_maps? | default []), lsp_clients: ($j.lsp_clients? | default 0)}
}

# ── the tmux surface (07-multiplexer/09, resolver by 06-help/04/07) ─────────
#
# ONE HEADLESS SERVER FOR THE WHOLE CHECK, ON ITS OWN SOCKET, KILLED AFTER.
# `-L help-check` is not tidiness: without it this reads the DEVELOPER'S live
# server, so a key they bound by hand this morning would resolve and a key the
# conf lost would still be found. The whole point is to measure the FILE.
#
# `list-keys -T <table>` prints the LOADED table, which is the only reading
# worth making — a grep of the conf's bytes passes on a line tmux rejected.
# The four tables are the ones this config writes into; tmux's other default
# tables hold nothing of ours.
#
# THE CONF IS ADDRESSED BY THE SAME `~`-LITERAL THE CORPUS IS, for the same
# recorded reason: the checker must read the file the machine runs, not a copy
# in a repo that may not even be deployed.
def _hc_tmux_live [] {
    if (which tmux | is-empty) {
        error make {msg: "help --check: tmux is not on PATH — the terminal surface cannot be introspected. tmux is a hard dependency of this configuration; install it and re-run"}
    }
    # $HELP_CHECK_TMUX_CONF overrides the deployed path, and it exists for
    # exactly one caller: tests/help-drift-check.sh, which has to point the
    # resolver at a MUTATED copy to prove the check can go red. A gate that
    # can only ever read the real file cannot demonstrate a finding, and one
    # that reimplements the resolver to get around that is testing itself.
    # It is never set in normal use, and the default is the deployed file.
    let conf = ($env.HELP_CHECK_TMUX_CONF? | default "~/.config/tmux/tmux.conf" | path expand)
    if not ($conf | path exists) {
        error make {msg: $"help --check: ($conf) does not exist — run `chezmoi apply`. A check that cannot read the conf must say so rather than report every tmux key stale"}
    }
    let sock = "help-check"
    # A leftover server from an interrupted run would answer with a stale
    # conf, which is drift the check would invent. Kill first, always.
    #
    # `err> /dev/null`: killing a server that is not there writes "error
    # connecting to …" to stderr, which is the normal case here.
    do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore

    # THE SENTINEL, and why the probe loads a COPY of the conf.
    #
    # `new-session -d` returns before the config has finished being applied.
    # Measured 2026-08-30 on a loaded machine: `list-keys -T root` answered
    # with tmux's 24 SHIPPED defaults and `list-keys -T jump` with "table
    # jump doesn't exist", on a server whose conf binds both — every
    # documented key then reads STALE, which is the worst failure a drift
    # check has: confident, specific, and blaming the manual for the
    # checker's own race. Waiting for the reading to stop changing does not
    # fix it either: the pre-config reading is stable, so it settles on the
    # defaults.
    #
    # So the probe appends one line to a copy and waits for THAT line to take
    # effect. tmux applies a config's commands in order, so the sentinel being
    # set means every binding above it has been. (A non-`-F` `if-shell` forks
    # and its BODY may still land later — the clipboard sink is the only one,
    # and it binds no keys.) The copy is the conf plus one line and nothing
    # else, which is why this does not weaken "the checker reads the file the
    # machine runs".
    let probe_conf = (mktemp -t "help-check-tmux-XXXXXX")
    $"(open --raw $conf)\nset -g @hc-loaded 1\n" | save -f $probe_conf

    # THE SESSION RUNS `cat`, NOT THE CONFIGURED SHELL, and that is the second
    # half of the same bug. With `default-command` in force the pane starts
    # nushell; in a scratch HOME that shell can exit immediately, the session
    # goes with it, THE SERVER EXITS — and the very next `tmux -L … list-keys`
    # silently STARTS A NEW SERVER with no `-f` at all. Measured 2026-08-30:
    # the first reading answered 28 root keys and 19 jump keys, and every
    # reading after it answered tmux 3.7c's 24 shipped defaults and "table
    # jump doesn't exist". `cat` on a pty blocks forever and cannot exit, so
    # the server the probe configured is the server every reading reaches.
    #
    # THE CONF IS LOADED WITH `source-file`, NOT WITH `-f`, AND THAT IS HOW
    # ITS ERRORS ARE HEARD. Measured 2026-08-30: `tmux -f <conf-with-a-bad-line>
    # new-session` exits 0, writes nothing to stderr and logs nothing to
    # `show-messages` — the bad line is simply skipped. The same file through
    # `source-file` answers "conf:1: unknown command: …". A checker that
    # cannot hear that reports every key the skipped lines would have bound as
    # STALE, which is the manual being blamed for the config.
    let up = (do -i { ^tmux -L $sock -f /dev/null new-session -d -s help-check cat } | complete)
    if $up.exit_code != 0 {
        rm -f $probe_conf
        error make {msg: $"help --check: could not start the probe tmux server — ($up.stderr | str trim)"}
    }
    let load = (do -i { ^tmux -L $sock source-file $probe_conf } | complete)
    let said = ($"($load.stdout)($load.stderr)" | str trim)
    if ($said | is-not-empty) {
        rm -f $probe_conf
        do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
        error make {msg: $"help --check: the conf did not load cleanly — tmux said: ($said)"}
    }
    mut loaded = false
    for _ in 1..60 {
        let v = (do -i { ^tmux -L $sock show -gv @hc-loaded } | complete)
        if ($v.exit_code == 0) and (($v.stdout | str trim) == "1") { $loaded = true; break }
        sleep 100ms
    }
    rm -f $probe_conf
    if not $loaded {
        do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
        error make {msg: "help --check: the tmux probe never finished loading the conf within six seconds. Reporting drift off a half-applied config would blame the manual for the config's load order"}
    }

    let read_tables = {||
        ["root" "jump" "split" "copy-mode-vi"] | each {|t|
            let out = (do -i { ^tmux -L $sock list-keys -T $t } | complete)
            if $out.exit_code != 0 { [] } else {
                $out.stdout | lines | each {|l|
                    # `bind-key    -T <table> <key>  <command…>` — the key is
                    # the fourth field, taken POSITIONALLY rather than by a
                    # pattern, because a tmux key can be a bracket, a brace or
                    # a backslash-escaped `#`, and every one of those breaks a
                    # regex written for letters.
                    let f = ($l | split row -r '\s+' | where {|x| $x | is-not-empty })
                    if ($f | length) < 4 { null } else { {table: $t, key: ($f | get 3)} }
                } | compact
            }
        } | flatten
    }
    let rows = (do $read_tables)

    # AND THE SERVER MUST STILL BE OURS. If it died mid-read, tmux started a
    # fresh default one under us and the reading above is of tmux's shipped
    # defaults — which reads as every documented key being stale. The sentinel
    # is the proof of identity, not just of load order.
    let still = (do -i { ^tmux -L $sock show -gv @hc-loaded } | complete)
    if (($still.exit_code != 0) or (($still.stdout | str trim) != "1")) {
        do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
        error make {msg: "help --check: the tmux probe server did not survive the read — tmux will have started a fresh one with no config, and its shipped defaults would be reported as every documented key going stale"}
    }
    do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
    if ($rows | is-empty) {
        error make {msg: "help --check: the tmux probe read zero bindings, which no loaded conf produces"}
    }
    $rows
}

# ── the WezTerm surface (R3) ────────────────────────────────────────────────
#
# Three keys are still WezTerm's after the tmux cutover and they were going
# UNCHECKED — `wezterm-key` targets fell through the resolver silently, which
# is the worst of both worlds: documented, and unverified without saying so.
#
# `show-keys --lua` prints a Lua table; it is read with a line regex rather
# than parsed, because the only fields wanted are `key` and `mods` and pulling
# in a Lua parser to read two strings would be the more fragile choice.
#
# THE SPAWN NEEDS THE CONFIG NAMED. `wezterm --config-file <path> show-keys`
# against the DEPLOYED file, for the corpus's reason. And note what this
# command does NOT tell you: a config that fails to load falls back to
# WezTerm's defaults SILENTLY and prints a plausible table — so the reader
# asserts one of our own bindings is present and raises if not, rather than
# certifying a default table as ours.
def _hc_wezterm_live [] {
    if (which wezterm | is-empty) {
        error make {msg: "help --check: wezterm is not on PATH — the three keys it still owns cannot be introspected"}
    }
    # Same seam, same single caller. See _hc_tmux_live.
    let conf = ($env.HELP_CHECK_WEZTERM_CONF? | default "~/.config/wezterm/wezterm.lua" | path expand)
    if not ($conf | path exists) {
        error make {msg: $"help --check: ($conf) does not exist — run `chezmoi apply`"}
    }
    let out = (do -i { ^wezterm --config-file $conf show-keys --lua } | complete)
    if $out.exit_code != 0 {
        error make {msg: $"help --check: `wezterm show-keys` failed: ($out.stderr | str trim)"}
    }
    let rows_all = ($out.stdout | lines | each {|l|
        let k = ($l | parse -r "key = '(?<key>[^']*)'.*mods = '(?<mods>[^']*)'.*action = (?<action>.*)")
        if ($k | is-empty) {
            let k2 = ($l | parse -r "key = '(?<key>[^']*)'.*mods = '(?<mods>[^']*)'")
            if ($k2 | is-empty) { null } else { {key: ($k2 | first).key, mods: ($k2 | first).mods, action: ""} }
        } else {
            {key: ($k | first).key, mods: ($k | first).mods, action: ($k | first).action}
        }
    } | compact)
    let rows = ($rows_all | select key mods)
    # THE SILENT-FALLBACK GUARD. Measured 2026-08-30: a Lua error in
    # wezterm.lua makes `show-keys` print WezTerm's stock table with exit 0,
    # and every one of our keys then reads stale.
    #
    # THE SENTINEL IS AN ABSENCE, NOT A PRESENCE, and that distinction is the
    # whole of it. Asserting "one of our bindings is there" was tried first
    # and it convicted a legitimate finding: unbind the very key the guard
    # names and the checker raises "the config failed to load" instead of
    # reporting a stale entry, which is the case the check exists for.
    #
    # This config sets `disable_default_key_bindings = true`, so ActivateTab
    # cannot appear in a table it produced — while WezTerm's fallback table is
    # full of them (46, measured). No single binding of ours is load-bearing
    # for the guard, so any one of them can go stale and be reported.
    if (($rows_all | where {|r| $r.action =~ 'ActivateTab'}) | is-not-empty) {
        error make {msg: "help --check: `wezterm show-keys` returned a table binding ActivateTab, which this config cannot produce — it sets disable_default_key_bindings, so the config failed to load and WezTerm fell back to its own defaults. `wezterm --config-file <path> ls-fonts` prints the error that show-keys swallows"}
    }
    $rows
}

# ── the allowlist (R6) ──────────────────────────────────────────────────────
#
# NOT OURS TO DOCUMENT, AND SAID EXPLICITLY RATHER THAN SILENTLY SKIPPED.
# Measured 2026-08-29 against the repo's staged config: the reverse direction
# reports 156 live Neovim maps and 120 live nushell commands with no manual
# entry. Almost all are Neovim's own defaults and plugin internals, or private
# `_`-prefixed helpers. This constant is a STUB holding only the classes the
# core build proved out; the full classification is its own unit.
const HC_ALLOW = {
    # help.nu's own delegation aliases — machinery, not manual surface.
    alias: ["core-help" "core-ls"]
    # std/help's subcommands arrive in `scope commands` because config.nu does
    # `use std/help`. They are nushell's, and epic I2 says delegate never
    # shadow, so documenting them here would be the shadow.
    #
    # The four below are THIS CONFIG'S machinery: a handle exists because
    # something else has to call it, not because a person types it.
    #   decorate-ls        the `ls` pipeline's inner stage; `ls` is documented
    #   tv_finder          the television channel provider behind `finder`
    #   tv_history_local   the provider behind the history channel
    #   tv_remote          the Ctrl-Space dispatcher; the KEY is documented
    # Each is reachable only from something that IS in the manual, which is
    # the test applied: a handle nobody can usefully type is not a gap.
    command: ["help aliases" "help commands" "help externs" "help modules" "help operators" "help escapes" "banner" "pwd"
              "decorate-ls" "tv_finder" "tv_history_local" "tv_remote"]
    # NUSHELL'S OWN KEYBINDINGS, not ours. Measured 2026-08-30: `nu -n`, with
    # no configuration whatsoever, reports exactly these eight in
    # `$env.config.keybindings`. Documenting them would be documenting
    # nushell, and the manual is about what THIS configuration adds.
    keybinding: ["completion_menu" "ide_completion_menu" "completion_previous"
                 "history_menu" "next_page_menu" "undo_or_previous_page_menu"
                 "help_menu" "search_history"]
    nvim: []
}

# ── the Neovim classification (R6) ──────────────────────────────────────────
#
# 217 live maps, 61 documented targets. Listing the other 156 by `lhs` would be
# a list nobody could maintain and nobody could disagree with in one place, so
# they are classified by RULE instead, and the rules are here where a reader
# can argue with them.
#
#   1. `desc` begins ":help " — Neovim's own shipped default, and it says so
#      in its own words. `Y`, `&`, the `[`/`]` family, gx, gcc.
#   2. no `desc` at all — a plugin's internal map or a Neovim default that
#      never carried one. This config's own maps all set `desc`; that is what
#      makes the rule safe here, and it is asserted by tests/nvim-keymaps.sh
#      rather than assumed.
#   3. `desc` EQUALS THE TITLE OF A DOCUMENTED ENTRY — the same gesture in
#      another mode. The manual documents a gesture once and names the modes
#      in prose; twenty of the shift-select maps are one entry, and listing
#      each (mode, lhs) pair would be a manual written for the introspection
#      API rather than for a person.
#
# Rule 3 is the load-bearing one and it is deliberately narrow: it matches on
# the exact title string, so a map with a description of its own still shows
# up as a gap.
# NEOVIM'S OWN DEFAULTS ARE MEASURED, NOT LISTED. `nvim --clean` loads no
# configuration and no plugin, so every map it reports is one Neovim ships.
# Subtracting that set is what makes rule 4 below a fact instead of a
# maintained list that goes stale the first time Neovim adds a default —
# which it does: the `[`/`]` bracket family, `gc`, `gcc`, `gx`, the `gr*` LSP
# maps and the snippet `<Tab>` all arrived in 0.10 and 0.11, and a hand-kept
# list would have called every one of them a gap in our manual.
#
# `--clean` also skips shada and the user's plugin store, so this spawn is
# cheap and cannot be perturbed by the machine it runs on.
def _hc_nvim_defaults [] {
    let dump = (mktemp -t "help-check-clean-XXXXXX")
    let lua = '
local maps = {}
for _, m in ipairs({"n","v","x","i","o","t","c","s"}) do
  for _, k in ipairs(vim.api.nvim_get_keymap(m)) do
    maps[#maps+1] = m .. "\31" .. k.lhs
  end
end
local f = io.open(os.getenv("HELP_CHECK_DUMP"), "w")
f:write(table.concat(maps, "\n"))
f:close()
'
    # Redirected, never piped — see _hc_nvim_live for the SIGPIPE this avoids.
    let cleanlog = (mktemp -t "help-check-clean-log-XXXXXX")
    with-env {HELP_CHECK_DUMP: $dump} {
        do -i { ^nvim --clean --headless -c $"lua ($lua)" -c "qa!" out+err> $cleanlog } | ignore
    }
    rm -f $cleanlog
    let body = (if ($dump | path exists) { open --raw $dump } else { "" })
    rm -f $dump
    if ($body | str trim | is-empty) {
        error make {msg: "help --check: `nvim --clean` reported no default maps, which no Neovim does — the defaults could not be measured and every one of them would be reported as an undocumented gap"}
    }
    $body | lines
}

def _hc_nvim_is_ours [m: record, titles: list<string>, defaults: list<string>] {
    # 4. Neovim ships it — measured against `nvim --clean`, above.
    if $"($m.mode)\u{1f}($m.lhs)" in $defaults { return false }
    let d = ($m.desc? | default "")
    if ($d | is-empty) { return false }
    if ($d | str starts-with ":help ") { return false }
    if $d in $titles { return false }
    true
}

# A `_`-prefixed nushell command is private by this repo's convention — 99 of
# the 120 undocumented ones are that. The rule is written here, not spread
# through the report, so a reader can disagree with it in one place.
def _hc_is_private [name: string] { $name | str starts-with "_" }

# ── the resolver ────────────────────────────────────────────────────────────
#
# THREE CLASSES, AND THE SECOND IS THE DANGEROUS ONE (R4). Undocumented is the
# common failure; stale sends a reader — or an agent — to a key that does
# nothing; mismatched is a title that has quietly stopped describing its map.
def _hc_resolve [] {
    let targets = (_hc_targets)
    let live = (_hc_shell_live)
    let prose = ($targets | where kind == "prose")
    let nvim_targets = ($targets | where kind == "nvim-map")
    let tmux_targets = ($targets | where kind == "tmux-key")
    let wez_targets = ($targets | where kind == "wezterm-key")
    let nvim_dump = (if ($nvim_targets | is-empty) { {global: [], buffer: [], lsp_clients: 0} } else { _hc_nvim_live })
    let maps = $nvim_dump.global
    # Each surface is read only when something documents it, so a machine
    # missing one tool can still check the others.
    let tkeys = (if ($tmux_targets | is-empty) { [] } else { _hc_tmux_live })
    let wkeys = (if ($wez_targets | is-empty) { [] } else { _hc_wezterm_live })

    # stale + mismatched, per kind
    mut findings = []
    for t in ($targets | where kind in ["keybinding" "alias" "command"]) {
        if ($t.name not-in ($live | get $t.kind)) {
            $findings = ($findings | append {class: "stale", surface: "shell", kind: $t.kind, id: $t.id, detail: $t.name})
        }
    }
    for t in $nvim_targets {
        # A buffer-local map (the LSP aliases attach on LspAttach, oil and the
        # table plugin attach per filetype) is NOT in the global dump, so the
        # global lookup would report every one of them stale. Eight targets are
        # in this class today. They are reported as UNRESOLVED, never as stale:
        # a check that cannot see a surface must say so rather than guess.
        if $t.scope == "buffer" {
            # RESOLVED WHERE THE EVENT COULD BE FIRED. The dump opens a real
            # file, so FileType and BufEnter have run and the maps that attach
            # on those are there to be found — which is a real check, not a
            # shrug.
            let want_b = (_hc_norm_lhs $t.lhs)
            if (($nvim_dump.buffer | where mode == $t.mode and lhs == $want_b) | is-not-empty) {
                continue
            }
            # And unresolved WITH THE MEASUREMENT where it could not: the
            # number of LSP clients that attached says which case this is.
            # Zero means the server never started, which is the documented
            # cost of not installing one inside a check.
            $findings = ($findings | append {class: "unresolved", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) — buffer-local, and not on the probe buffer \(a lua file, ($nvim_dump.lsp_clients) LSP client\(s\) attached, ($nvim_dump.buffer | length) buffer maps\). It attaches on an event this dump does not fire — InsertEnter, or a filetype other than lua"})
            continue
        }
        let want = (_hc_norm_lhs $t.lhs)
        let hit = ($maps | where mode == $t.mode and lhs == $want)
        if ($hit | is-empty) {
            # The normalized form is QUOTED in the report because leader
            # normalizes to a space: an unquoted `<leader>w -> " w"` renders as
            # a stray gap and reads like a formatting bug rather than the key
            # actually looked up.
            $findings = ($findings | append {class: "stale", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) -> looked up as '($want)', not in the live dump"})
            continue
        }
        # desc three-state (epic I5): `desc: null` asserts existence only, an
        # explicit string must equal the live one, and an OMITTED desc compares
        # against the entry's title.
        if $t.has_desc and ($t.desc == null) { continue }
        let want_desc = (if $t.has_desc { $t.desc } else { $t.title })
        let got = (($hit | first).desc? | default "")
        if $got != $want_desc {
            $findings = ($findings | append {class: "mismatched", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.lhs): live '($got)' vs manual '($want_desc)'"})
        }
    }

    # tmux keys. A target's `table` defaults to `root`, which is where the
    # three unprefixed keys live; the rest name `jump`, `split` or
    # `copy-mode-vi`. Only STALE is possible here — there is no description to
    # mismatch against, because a tmux binding carries none.
    for t in $tmux_targets {
        let tbl = (if ($t.table | is-empty) { "root" } else { $t.table })
        if (($tkeys | where table == $tbl and key == $t.key) | is-empty) {
            $findings = ($findings | append {class: "stale", surface: "terminal", kind: "tmux-key", id: $t.id, detail: $"($t.key) in table '($tbl)' is not bound by tmux.conf"})
        }
    }
    for t in $wez_targets {
        if (($wkeys | where key == $t.key and mods == $t.mods) | is-empty) {
            $findings = ($findings | append {class: "stale", surface: "terminal", kind: "wezterm-key", id: $t.id, detail: $"($t.key) + ($t.mods) is not bound by wezterm.lua"})
        }
    }

    # UNDOCUMENTED, ON THE TABLES THIS CONFIG OWNS ONLY. `jump` and `split`
    # exist because this conf created them, so every key in them is ours and
    # an undocumented one is a real gap. `root` and `copy-mode-vi` are tmux's
    # own tables carrying dozens of default and mouse bindings, so the
    # reverse direction there would report tmux's shipped defaults as our
    # omission — the noise class the allowlist exists to avoid, avoided here
    # by not generating it.
    let doc_tkeys = ($tmux_targets | each {|t| $"(if ($t.table | is-empty) { 'root' } else { $t.table })\u{1f}($t.key)" })
    for k in ($tkeys | where table in ["jump" "split"]) {
        if $"($k.table)\u{1f}($k.key)" in $doc_tkeys { continue }
        $findings = ($findings | append {class: "undocumented", surface: "terminal", kind: "tmux-key", id: $"($k.table) ($k.key)", detail: $"bound in the '($k.table)' table, which this config owns entirely"})
    }

    # undocumented, both surfaces
    let doc = {
        keybinding: ($targets | where kind == "keybinding" | get name)
        alias: ($targets | where kind == "alias" | get name)
        command: ($targets | where kind == "command" | get name)
    }
    for k in ["keybinding" "alias" "command"] {
        for n in ($live | get $k) {
            if $n in ($doc | get $k) { continue }
            if $n in ($HC_ALLOW | get -o $k | default []) { continue }
            if $k == "command" and (_hc_is_private $n) { continue }
            $findings = ($findings | append {class: "undocumented", surface: "shell", kind: $k, id: $n, detail: $n})
        }
    }
    # `v` IS NOT A MODE, IT IS TWO. A map created for mode "v" is returned by
    # `nvim_get_keymap` under BOTH "x" (visual) and "s" (select), so the six
    # shift-select maps documented once as "v" appear three times in the live
    # dump and the two extra copies read as undocumented gaps. Measured
    # 2026-08-30: twelve findings, every one of them a map the manual does
    # document. The expansion is here rather than in the corpus because the
    # manual should say what a person presses, not what an introspection API
    # returns for it.
    let doc_maps = ($nvim_targets | each {|t|
        let lhs = (_hc_norm_lhs $t.lhs)
        if $t.mode == "v" {
            [$"v\u{1f}($lhs)" $"x\u{1f}($lhs)" $"s\u{1f}($lhs)"]
        } else {
            [$"($t.mode)\u{1f}($lhs)"]
        }
    } | flatten)
    let doc_titles = ($targets | get title | uniq)
    let nvim_defaults = (if ($maps | is-empty) { [] } else { _hc_nvim_defaults })
    for m in $maps {
        let k = $"($m.mode)\u{1f}($m.lhs)"
        if $k in $doc_maps { continue }
        if $m.lhs in $HC_ALLOW.nvim { continue }
        # The three classification rules live in _hc_nvim_is_ours, beside the
        # reasoning. A map that is not ours is not a gap in our manual.
        if not (_hc_nvim_is_ours $m $doc_titles $nvim_defaults) { continue }
        $findings = ($findings | append {class: "undocumented", surface: "nvim", kind: "nvim-map", id: $"($m.mode) ($m.lhs)", detail: ($m.desc? | default "")})
    }

    {
        findings: $findings
        counts: {
            documented: (($targets | length) - ($prose | length))
            prose: ($prose | length)
            allowlisted: (($HC_ALLOW.alias | length) + ($HC_ALLOW.command | length) + ($HC_ALLOW.keybinding | length) + ($HC_ALLOW.nvim | length))
            nvim_maps_live: ($maps | length)
            nvim_buf_maps_live: ($nvim_dump.buffer | length)
            nvim_defaults: ($nvim_defaults | length)
            tmux_keys_live: ($tkeys | length)
            wezterm_keys_live: ($wkeys | length)
        }
    }
}

# ── the report (R4, R5, R7) ─────────────────────────────────────────────────
def _help_check [--json] {
    let r = (_hc_resolve)
    if $json { return $r }
    let by = ($r.findings | group-by class)
    print $"documented ($r.counts.documented) · prose-only ($r.counts.prose) · allowlisted ($r.counts.allowlisted) · live nvim maps ($r.counts.nvim_maps_live) of which ($r.counts.nvim_defaults) are Neovim's own · live buffer maps ($r.counts.nvim_buf_maps_live) · live tmux keys ($r.counts.tmux_keys_live) · live wezterm keys ($r.counts.wezterm_keys_live)"
    for c in ["stale" "mismatched" "undocumented" "unresolved"] {
        let rows = ($by | get -o $c | default [])
        print $"($c): ($rows | length)"
        for row in $rows { print $"  [($row.surface)/($row.kind)] ($row.id) — ($row.detail)" }
    }
    let bad = ($r.findings | where class in ["stale" "mismatched" "undocumented"] | length)
    if $bad > 0 {
        error make {msg: $"help --check: ($bad) drift findings — the manual and the live configuration disagree"}
    }
    print "help --check: clean"
}
