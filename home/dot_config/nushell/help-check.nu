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
def _hc_nvim_live [] {
    if (which nvim | is-empty) {
        error make {msg: "help --check: nvim is not on PATH — the Neovim surface cannot be introspected"}
    }
    let lua = '
local o = {}
for _, m in ipairs({"n","v","x","i","o","t","c","s"}) do
  for _, k in ipairs(vim.api.nvim_get_keymap(m)) do
    o[#o+1] = {mode = m, lhs = k.lhs, desc = k.desc}
  end
end
io.write(vim.json.encode(o))
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
    # NO `--clean`. It skips the plugin and site directories, which is the
    # same silent degradation by a second route: 123 maps instead of 214, and
    # every plugin-provided map we document reads as stale.
    # `complete` captures stdout, stderr and the code together, so nvim's
    # startup chatter never reaches the report. It must wrap the external
    # DIRECTLY — a redirection in between makes it "only works on external
    # commands".
    let out = (^nvim --headless -c $"lua ($lua)" -c "qa!" | complete)
    if $out.exit_code != 0 {
        error make {msg: $"help --check: nvim --headless exited ($out.exit_code)"}
    }
    $out.stdout | from json
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
    command: ["help aliases" "help commands" "help externs" "help modules" "help operators" "help escapes" "banner" "pwd"]
    nvim: []
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
    let maps = (if ($nvim_targets | is-empty) { [] } else { _hc_nvim_live })

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
            $findings = ($findings | append {class: "unresolved", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) — buffer-local, not in the global dump"})
            continue
        }
        let want = (_hc_norm_lhs $t.lhs)
        let hit = ($maps | where mode == $t.mode and lhs == $want)
        if ($hit | is-empty) {
            $findings = ($findings | append {class: "stale", surface: "nvim", kind: "nvim-map", id: $t.id, detail: $"($t.mode) ($t.lhs) -> ($want)"})
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
    let doc_maps = ($nvim_targets | each {|t| $"($t.mode)\u{1f}(_hc_norm_lhs $t.lhs)" })
    for m in $maps {
        let k = $"($m.mode)\u{1f}($m.lhs)"
        if $k in $doc_maps { continue }
        if $m.lhs in $HC_ALLOW.nvim { continue }
        $findings = ($findings | append {class: "undocumented", surface: "nvim", kind: "nvim-map", id: $"($m.mode) ($m.lhs)", detail: ($m.desc? | default "")})
    }

    {
        findings: $findings
        counts: {
            documented: (($targets | length) - ($prose | length))
            prose: ($prose | length)
            allowlisted: (($HC_ALLOW.alias | length) + ($HC_ALLOW.command | length) + ($HC_ALLOW.nvim | length))
            nvim_maps_live: ($maps | length)
        }
    }
}

# ── the report (R4, R5, R7) ─────────────────────────────────────────────────
def _help_check [--json] {
    let r = (_hc_resolve)
    if $json { return $r }
    let by = ($r.findings | group-by class)
    print $"documented ($r.counts.documented) · prose-only ($r.counts.prose) · allowlisted ($r.counts.allowlisted) · live nvim maps ($r.counts.nvim_maps_live)"
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
