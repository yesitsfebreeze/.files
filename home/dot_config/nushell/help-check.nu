# help-check.nu
# Why this file is shaped the way it is:
#   manual → internals/help

# ── the corpus ──────────────────────────────────────────────────────────────
def _hc_dir [] {
    let dir = ($nu.home-dir | path join ".config" "nushell" "help")
    if not ($dir | path exists) {
        error make {msg: $"help --check: the manual's corpus directory ($dir) is missing — run `chezmoi apply`"}
    }
    $dir
}

# ── the scratch dir ─────────────────────────────────────────────────────────
# Three probes need a real path on disk, and none of them can be a pipe:
#
#   * the nvim keymap dump is written to a FILE because a headless nvim writing
#     to a stdout nushell is capturing dies on SIGPIPE (measured 2026-08-30 —
#     see the `silent` note in the lua), and because the spawn's startup noise
#     has to land somewhere that is not the payload.
#   * the buffer-local maps only attach over a real file with a real extension:
#     a scratch buffer fires neither FileType nor BufEnter, which is the whole
#     point of the probe.
#   * `tmux source-file` takes a path. It does not read stdin.
#
# So there is one directory, emptied when a run STARTS and never cleaned up
# after it. Nothing accumulates — the next run clears it — and a check that
# deleted its probes in the same breath as it failed would leave nothing to
# look at. The reset is also what makes a leftover dump impossible to misread
# as this run's: it cannot survive into the run that would read it.
#
# Fixed path, so two runs at once would share it. This is a check a person
# types, not a daemon.
def _hc_scratch [] { $nu.temp-dir | path join "help-check" }

def _hc_scratch_reset [] {
    let d = (_hc_scratch)
    if ($d | path exists) { rm -prf $d }
    mkdir $d
}

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
                    key: ($t.key? | default "")
                    mods: ($t.mods? | default "NONE")
                    table: ($t.table? | default "")
                }
            }
        } | flatten
    } | flatten
}

# ── nvim lhs normalization (R2) ─────────────────────────────────────────────
def _hc_norm_lhs [lhs: string] {
    mut s = ($lhs | str replace --all "<leader>" " " | str replace --all "<Leader>" " ")
    $s = ($s | str replace --all --regex "<[Ss]pace>" " ")
    $s = ($s | str replace --all --regex "<A-([^>]+)>" "<M-${1}>")
    $s = ($s | str replace --all --regex "<C-([a-zA-Z])>" "<C-${1}>")
    for c in ([a b c d e f g h i j k l m n o p q r s t u v w x y z]) {
        $s = ($s | str replace --all $"<C-($c)>" $"<C-($c | str uppercase)>")
        $s = ($s | str replace --all $"<S-($c)>" ($c | str uppercase))
        $s = ($s | str replace --all $"<S-($c | str uppercase)>" ($c | str uppercase))
    }
    if $s == "<" { return "<lt>" }
    $s
}

# ── the shell surface (R1) ──────────────────────────────────────────────────
def _hc_shell_live [] {
    {
        keybinding: ($env.config.keybindings | get name | uniq)
        alias: (scope aliases | get name)
        command: (scope commands | where type == "custom" | get name)
    }
}

# ── the Neovim surface (R2) ─────────────────────────────────────────────────
def _hc_nvim_live [] {
    if (which nvim | is-empty) {
        error make {msg: "help --check: nvim is not on PATH — the Neovim surface cannot be introspected"}
    }
    let dump = (_hc_scratch | path join "nvim-maps.json")
    let probe = (_hc_scratch | path join "probe.lua")
    "local x = 1\nreturn x\n" | save -f $probe
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
    let init = ($nu.home-dir | path join ".config" "nvim" "init.lua")
    if not ($init | path exists) {
        error make {msg: $"help --check: ($init) is missing — the Neovim surface cannot be introspected, and a bare `nvim` would report Neovim's own defaults as drift"}
    }
    let spawnlog = (_hc_scratch | path join "nvim.log")
    let rc = (with-env {HELP_CHECK: "1", HELP_CHECK_DUMP: $dump, HELP_CHECK_PROBE: $probe} {
        do -i { ^nvim --headless -c $"lua ($lua)" -c "qa!" out+err> $spawnlog }
        $env.LAST_EXIT_CODE
    })
    let out = {exit_code: $rc}
    let spawn_said = (if ($spawnlog | path exists) { open --raw $spawnlog } else { "" })
    if $out.exit_code != 0 {
        error make {msg: $"help --check: nvim --headless exited ($out.exit_code) — ($spawn_said | str trim)"}
    }
    if (not ($dump | path exists)) or (($dump | path type) != "file") {
        error make {msg: "help --check: the headless spawn wrote no keymap dump — nvim started but the check's lua never ran"}
    }
    let raw = (open --raw $dump)
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
    {global: $j.maps, buffer: ($j.buf_maps? | default []), lsp_clients: ($j.lsp_clients? | default 0)}
}

# ── the tmux surface (07-multiplexer/09, resolver by 06-help/04/07) ─────────
def _hc_tmux_live [] {
    if (which tmux | is-empty) {
        error make {msg: "help --check: tmux is not on PATH — the terminal surface cannot be introspected. tmux is a hard dependency of this configuration; install it and re-run"}
    }
    let conf = ($env.HELP_CHECK_TMUX_CONF? | default "~/.config/tmux/tmux.conf" | path expand)
    if not ($conf | path exists) {
        error make {msg: $"help --check: ($conf) does not exist — run `chezmoi apply`. A check that cannot read the conf must say so rather than report every tmux key stale"}
    }
    let sock = "help-check"
    do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore

    let probe_conf = (_hc_scratch | path join "tmux.conf")
    $"(open --raw $conf)\nset -g @hc-loaded 1\n" | save -f $probe_conf

    let up = (do -i { ^tmux -L $sock -f /dev/null new-session -d -s help-check cat } | complete)
    if $up.exit_code != 0 {
        error make {msg: $"help --check: could not start the probe tmux server — ($up.stderr | str trim)"}
    }
    let load = (do -i { ^tmux -L $sock source-file $probe_conf } | complete)
    let said = ($"($load.stdout)($load.stderr)" | str trim)
    if ($said | is-not-empty) {
        do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
        error make {msg: $"help --check: the conf did not load cleanly — tmux said: ($said)"}
    }
    mut loaded = false
    for _ in 1..60 {
        let v = (do -i { ^tmux -L $sock show -gv @hc-loaded } | complete)
        if ($v.exit_code == 0) and (($v.stdout | str trim) == "1") { $loaded = true; break }
        sleep 100ms
    }
    if not $loaded {
        do -i { ^tmux -L $sock kill-server err> /dev/null } | ignore
        error make {msg: "help --check: the tmux probe never finished loading the conf within six seconds. Reporting drift off a half-applied config would blame the manual for the config's load order"}
    }

    let read_tables = {||
        # The tables tmux.conf actually pushes. A table missing from this list
        # is not reported as unknown — every key documented in it is reported
        # STALE, which reads as the manual being wrong about a binding that is
        # in fact bound. `jump-pane` was absent from 2026-09-01, when the digit
        # gained a second table, until it was noticed here: ten findings, all
        # of them the checker's own blind spot. `split` was in its place and
        # had been retired when F4 folded into F5.
        ["root" "jump" "jump-pane" "copy-mode-vi"] | each {|t|
            let out = (do -i { ^tmux -L $sock list-keys -T $t } | complete)
            if $out.exit_code != 0 { [] } else {
                $out.stdout | lines | each {|l|
                    let f = ($l | split row -r '\s+' | where {|x| $x | is-not-empty })
                    if ($f | length) < 4 { null } else { {table: $t, key: ($f | get 3)} }
                } | compact
            }
        } | flatten
    }
    let rows = (do $read_tables)

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
def _hc_wezterm_live [] {
    if (which wezterm | is-empty) {
        error make {msg: "help --check: wezterm is not on PATH — the three keys it still owns cannot be introspected"}
    }
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
    if (($rows_all | where {|r| $r.action =~ 'ActivateTab'}) | is-not-empty) {
        error make {msg: "help --check: `wezterm show-keys` returned a table binding ActivateTab, which this config cannot produce — it sets disable_default_key_bindings, so the config failed to load and WezTerm fell back to its own defaults. `wezterm --config-file <path> ls-fonts` prints the error that show-keys swallows"}
    }
    $rows
}

# ── the allowlist (R6) ──────────────────────────────────────────────────────
const HC_ALLOW = {
    alias: ["core-help" "core-ls"]
    # tv_shell_history / tv_smart_autocomplete are television's own init
    # definitions — upstream, not our additions.
    command: ["help aliases" "help commands" "help externs" "help modules" "help operators" "help escapes" "banner" "pwd"
              "decorate-ls" "tv_history_local"
              "tv_shell_history" "tv_smart_autocomplete"]
    keybinding: ["completion_menu" "ide_completion_menu" "completion_previous"
                 "history_menu" "next_page_menu" "undo_or_previous_page_menu"
                 "help_menu" "search_history"
                 # television's generated init re-exports its own bindings under
                 # tv_* names — upstream defaults, not our additions. Our own
                 # records override Ctrl-T/Ctrl-R; these are what survives.
                 "tv_completion" "tv_history"]
    nvim: []
}

# ── the Neovim classification (R6) ──────────────────────────────────────────
def _hc_nvim_defaults [] {
    let dump = (_hc_scratch | path join "nvim-defaults.txt")
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
    let cleanlog = (_hc_scratch | path join "nvim-clean.log")
    with-env {HELP_CHECK_DUMP: $dump} {
        do -i { ^nvim --clean --headless -c $"lua ($lua)" -c "qa!" out+err> $cleanlog } | ignore
    }
    let body = (if ($dump | path exists) { open --raw $dump } else { "" })
    if ($body | str trim | is-empty) {
        error make {msg: "help --check: `nvim --clean` reported no default maps, which no Neovim does — the defaults could not be measured and every one of them would be reported as an undocumented gap"}
    }
    $body | lines
}

def _hc_nvim_is_ours [m: record, titles: list<string>, defaults: list<string>] {
    if $"($m.mode)\u{1f}($m.lhs)" in $defaults { return false }
    let d = ($m.desc? | default "")
    if ($d | is-empty) { return false }
    if ($d | str starts-with ":help ") { return false }
    if $d in $titles { return false }
    true
}

def _hc_is_private [name: string] { $name | str starts-with "_" }

# ── the resolver ────────────────────────────────────────────────────────────
def _hc_resolve [] {
    _hc_scratch_reset
    let targets = (_hc_targets)
    let live = (_hc_shell_live)
    let prose = ($targets | where kind == "prose")
    let nvim_targets = ($targets | where kind == "nvim-map")
    let tmux_targets = ($targets | where kind == "tmux-key")
    let wez_targets = ($targets | where kind == "wezterm-key")
    let nvim_dump = (if ($nvim_targets | is-empty) { {global: [], buffer: [], lsp_clients: 0} } else { _hc_nvim_live })
    let maps = $nvim_dump.global
    let tkeys = (if ($tmux_targets | is-empty) { [] } else { _hc_tmux_live })
    let wkeys = (if ($wez_targets | is-empty) { [] } else { _hc_wezterm_live })

    mut findings = []
    for t in ($targets | where kind in ["keybinding" "alias" "command"]) {
        if ($t.name not-in ($live | get $t.kind)) {
            $findings = ($findings | append {class: "stale", surface: "shell", kind: $t.kind, id: $t.id, detail: $t.name})
        }
    }
    for t in $nvim_targets {
        if $t.scope == "buffer" {
            let want_b = (_hc_norm_lhs $t.lhs)
            if (($nvim_dump.buffer | where mode == $t.mode and lhs == $want_b) | is-not-empty) {
                continue
            }
            $findings = ($findings | append {class: "unresolved", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) — buffer-local, and not on the probe buffer \(a lua file, ($nvim_dump.lsp_clients) LSP client\(s\) attached, ($nvim_dump.buffer | length) buffer maps\). It attaches on an event this dump does not fire — InsertEnter, or a filetype other than lua"})
            continue
        }
        let want = (_hc_norm_lhs $t.lhs)
        let hit = ($maps | where mode == $t.mode and lhs == $want)
        if ($hit | is-empty) {
            $findings = ($findings | append {class: "stale", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) -> looked up as '($want)', not in the live dump"})
            continue
        }
        if $t.has_desc and ($t.desc == null) { continue }
        let want_desc = (if $t.has_desc { $t.desc } else { $t.title })
        let got = (($hit | first).desc? | default "")
        if $got != $want_desc {
            $findings = ($findings | append {class: "mismatched", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.lhs): live '($got)' vs manual '($want_desc)'"})
        }
    }

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

    let doc_tkeys = ($tmux_targets | each {|t| $"(if ($t.table | is-empty) { 'root' } else { $t.table })\u{1f}($t.key)" })
    for k in ($tkeys | where table in ["jump" "split"]) {
        if $"($k.table)\u{1f}($k.key)" in $doc_tkeys { continue }
        $findings = ($findings | append {class: "undocumented", surface: "terminal", kind: "tmux-key", id: $"($k.table) ($k.key)", detail: $"bound in the '($k.table)' table, which this config owns entirely"})
    }

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
