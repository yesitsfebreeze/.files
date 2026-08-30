# 04-drift-check — probe notes (pass one, uncommitted)

Everything below is measured on this machine, 2026-08-29, nu 0.114.1,
Neovim 0.12.4. Nothing here is inferred.

## The parse error, reproduced

    $ nu -c 'source home/dot_config/nushell/help.nu; help --check'
    Error: nu::parser::unknown_flag
      x The `help` command doesn't have flag `check`.

`--check` appears in help.nu only in a comment (line 56). `def help`'s
signature has nine flags and `--check` is not one. That is the whole of the
"parse error today" AGENTS.md records — a missing flag, not a broken file.
`nu -c 'source help.nu'` alone exits 0.

## The configuration is NOT deployed

`~/.config/nushell/` is the PRE-rebuild tree: no `help.nu`, no `help/`
corpus, no `capsule.nu`/`zoxide.nu`/`recents.nu`/`claude.nu`/`copymode.nu`.
`just cutover` has not run. `chezmoi source-path` answers
`/Users/feb/dev/.files/home` (a reading of today).

Consequence: the check cannot be run against the deployed tree at all. It is
built and measured against a HERMETIC machine — the repo's nushell tree staged
into an isolated HOME, the pattern `tests/shell-help.sh:mk_machine` already
uses. `probe/mk-machine.sh` + `probe/nu-c.sh` reproduce it.

## help.nu cannot hold the check — gated, not stylistic

`tests/shell-help.sh:229` `render_no_spawn_ok` greps help.nu for
`(\^|^|[ ({;]|\| *)(nvim|wezterm|git|tv|chezmoi)[[:space:]]` and for
`$env.EDITOR`; `browse_only_spawner_ok` asserts `_help_browse` is the ONLY def
naming a spawn target. `--check` spawns `nvim --headless`, so one line of it in
help.nu turns both red. Hence `home/dot_config/nushell/help-check.nu`.

## Source order is load-bearing

Measured: a `def` in one sourced file calling a `def` from a file sourced
LATER fails at RUN time with `nu::shell::external_command — Command not
found`. Each `source` is its own block; predeclaration does not cross it.

    source a.nu; source b.nu; foo   ->  Command `bar` not found
    source b.nu; source a.nu; foo   ->  "hi from bar"

So config.nu must source `help-check.nu` ABOVE `help.nu` (which is at line
609, under `use std/help` / `alias core-help = help` at 607-608).

## Corpus scale — 160 verify targets

    command 28 · nvim-map 66 · wezterm-key 26 · prose 16 · alias 13 · keybinding 11

## Shell surface, both directions (hermetic machine)

    KEYBINDING doc=11 live=11   stale 0   undocumented 0        <- clean
    ALIAS      doc=13 live=18   stale 0   undocumented 5
               undocumented: core-help, core-ls, z, zi, zz
    COMMAND    doc=28 live=134  stale 4   undocumented 120
               stale: z, zi, zz, pass
               of the 120: 99 are `_`-prefixed private helpers, 21 public

**A real corpus defect, found by the build:** `z`, `zi`, `zz` are documented
with `kind: "command"` but are live as ALIASES. They appear in both the stale
list and the undocumented list — the same three handles, on the wrong side of
the kind boundary. `pass` is stale outright. This is exactly the class
`01-content-model/coverage` R5 predicted.

The 21 public undocumented commands: banner, capsule clean, capsule list,
capsule recent, cll, decorate-ls, help aliases, help commands, help externs,
help modules, help operators, llm, llm quota, llm regen, mkcd, nu-complete
pass, pwd, quicklist, tv_finder, tv_history_local, tv_remote.

## Neovim surface — normalization is load-bearing and measured

`probe/nvim-dump.sh` stages the repo's nvim config with a seeded offline
plugin store and dumps `nvim_get_keymap` for 8 modes in ONE headless run:
**214 global maps** (n 86, v 45, x 42, s 21, o 11, i 9).

    66 nvim-map targets
      raw lhs comparison        : 30 resolve, 36 miss
      6 README normalization rules: 57 resolve, 9 miss
      + the <space> rule        : 58 resolve, 8 miss

**The README's measured table is missing a seventh row.** `<space>` → `" "`.
Found by `<leader><space>`, which returns `"  "` (two spaces) live and was the
single GLOBAL miss after the six documented rules. The other 8 misses are all
`scope: "buffer"`.

    written          returned
    <leader>ff       "  ff"
    <space>          " "        <- NOT in home/.../help/README.md
    <C-h>            <C-H>
    <A-j>            <M-j>
    <S-h>            H
    <S-Right>        <S-Right>
    <                <lt>

## desc three-state — the epic's I5 defect is already fixed

Corpus today: **absent 0 · null 7 · explicit 59**. Explicit-desc mismatches
against live: **0**.

The epic's I5 says four `nvim-map` targets "omit `desc` where the live maps set
`LSP: …` strings — four drift-check false failures waiting". Measured today
that is false: ZERO targets omit `desc`. Either the corpus was fixed since I5
was written or the claim was never accurate. Finding for the report; not mine
to edit.

## The 8 buffer-local misses need a different mechanism

    n q · i <BS> · i <CR> · n gd · n gI · n <leader>rn · n <leader>ca · n K

None are in the global dump by construction. Resolving them needs a headless
Neovim with an LSP server ATTACHED (gd, gI, <leader>rn, <leader>ca, K) and
filetype buffers open (q, <BS>, <CR>). That is a different introspection path
from the global dump, not a parameter of it.

## Reverse direction, Neovim: 156 undocumented live maps

    n 47 · x 41 · v 31 · s 21 · o 11 · i 5    (40 carry no desc at all)

Nearly all Neovim's own defaults (`Y`, `&`, `[b`, `]b`, `[a`) and bundled
matchit (`%`, `[%`). R6's allowlist has to classify ~156 nvim maps + 120
nushell commands + 5 aliases = **~281 live handles**. That is a data-curation
contract, not a code one.

## Exit code: `error make`, never `exit`

`exit 1` inside a def closes the INTERACTIVE shell — `help --check` typed at a
prompt would end the session. `error make` gives rc 1 under `nu -c` (what a
hook or CI runs) and prints an error at a prompt without killing it. Report is
printed BEFORE the raise.

## Built so far

`home/dot_config/nushell/help-check.nu` — parses clean. Holds `_hc_dir`,
`_hc_targets` (three-state desc preserved), `_hc_norm_lhs` (all 7 rules
verified), `_hc_shell_live`, `_hc_nvim_live`, `HC_ALLOW` (stub), `_hc_resolve`
(4 classes: stale / mismatched / undocumented / unresolved), `_help_check`.

## END TO END: `help --check` runs and exits 1 (built, measured)

    $ nu --config <machine>/config.nu -c 'help --check'
    documented 144 · prose-only 16 · allowlisted 10 · live nvim maps 217
    stale: 4
      [shell/command] z <query> — z
      [shell/command] zi — zi
      [shell/command] zz — zz
      [shell/command] pass <tab> — pass
    mismatched: 0
    undocumented: 176      (159 nvim + 17 shell)
    unresolved: 8          (every one scope: "buffer")
    RC=1

**mismatched is 0 and stale on the nvim surface is 0**: all 58 global
`nvim-map` targets resolve and every `desc` agrees. The whole nvim half of R2
works. The four stale rows are the real corpus defects named above.

## Two silent-degradation traps, both hit and both fixed

1. **No nvim config on the machine.** `nvim --headless` starts anyway and
   `nvim_get_keymap` returns Neovim's OWN defaults — 123 maps against 217.
   The check then reported **54 stale and 1 mismatched, every one false**, and
   exited non-zero for the wrong reason. A missing config is not drift, so
   `_hc_nvim_live` now raises when `~/.config/nvim/init.lua` is absent.
2. **`--clean`.** Same degradation by a second route: it skips the plugin and
   site dirs, 123 maps again. Removed.

Both were caught only because the standalone probe had already measured 214;
a build without that number would have shipped 54 false stales.

## `complete` must wrap the external DIRECTLY

`^nvim ... e>| ignore | complete` fails with `complete only works on external
commands`. `(^nvim ... | complete)` captures stdout, stderr and the code
together, which is also what keeps nvim's startup chatter out of the report.

## lazy.nvim CLONES FROM THE NETWORK on a headless start

A plugin in `lazy-lock.json` that is not in the data dir is git-cloned during
`help --check`'s spawn. Observed: `persistence.nvim` cloned mid-run. So the
check performs network I/O and can hang, and its answer depends on what a
package manager decided to do. `--noplugin`/`--clean` are not the fix (trap 2).
This needs `lazy.nvim`'s install-on-start disabled for the check's spawn, and
it is not covered by any requirement in the PRD.

(`persistence.nvim` is absent from the local store because
`07-multiplexer/06-nvim-session` is adding it concurrently — not a defect.)

## Where R6 stands: the allowlist is the outstanding cost

176 undocumented, against a 10-entry stub allowlist. 159 nvim + 17 shell.
Classifying ~281 live handles as ours-or-not is the single largest piece
left and it is data curation, not code.

## Acceptance, run against the build

| # | acceptance box | result |
|---|---|---|
| A1 | add a nushell keybinding, no manual entry | **PASSES** — undocumented 176 → 177, `[shell/keybinding] drift_probe_binding`, run raises |
| A2 | delete a documented Neovim map → stale | **PARTIAL** — see the blind spot below |
| A3 | change a map's `desc`, not the manual → mismatched | **PASSES** — `<leader>w`: live `'Write the file'` vs manual `'Save'` |
| A4 | clean tree exits 0 with per-surface counts | **CANNOT PASS TODAY** — 176 undocumented against a 10-entry stub allowlist |

A2 in detail. Deleting `<leader>w` (line 46 of keymaps.lua) reports **stale**,
4 → 5. Correct. Deleting `<C-l>` (line 7) reports **mismatched**, not stale:

    [nvim/nvim-map] <C-l>: live ':help CTRL-L-default' vs manual 'Go to right window'

because Neovim binds `<C-l>` itself. The lhs still exists; only the desc moved.

## The Neovim surface has the SAME blind spot the WezTerm surface was cut for

Measured: a bare `nvim --headless` with an empty HOME reports **123** core
default maps. Intersected against our 58 global `nvim-map` targets:

    COLLIDE with a Neovim default: 8 of 58
      n <C-l>   grn   gra   grr   gri   gO   ]d   [d

Seven of the eight are exactly R6's named exception — the LSP defaults we
*chose* not to re-map. For those the collision is harmless by design: they ARE
Neovim's, so "deleted" is not a state they have. **Only `<C-l>` is ours and
shadowed by a default**, and for it a deletion degrades from stale to
mismatched. A target with `desc: null` in that class would make a deletion
invisible entirely; none is in that class today.

So the blind spot is real but it is 1 target, not 8 — a much better answer
than the WezTerm `Ctrl+Shift+T` case that justified deferring R3. Worth
recording because the finish-line answer treated the blind spot as unique to
the terminal.

## BLAST RADIUS: config.nu gained a `source`, and that breaks parse everywhere

Proven directly — a machine with `help-check.nu` NOT staged:

    Error: nu::parser::sourced_file_not_found
       ,-[config.nu:609:8]
     609 | source ~/.config/nushell/help-check.nu
         :        `-- File not found

Every gate staging a hermetic HOME dies at PARSE before one assertion of its
own runs. That is `tests/{help-browser,help-agent,nushell-aliases,nushell-core,
shell-claude,shell-help,shell-history,shell-listing,shell-quicklist,
shell-television,shell-zoxide}.sh` — each carries its own `MODULES=` constant.

**And the gate written to catch exactly this cannot see it.**
`gates/nushell-module-staging.sh` derives its module list from config.nu:

    $GREP -oE '^source ~/\.config/nushell/[a-z]+\.nu$' "$1" | sed 's|.*/||'

`[a-z]+` has **no hyphen**, so `help-check.nu` never enters the list, and the
gate PASSES — printing "every in-scope gate stages every module config.nu
sources (misses: 0)" — while all eleven siblings are broken. Its own header
says it exists because "`copymode.nu` arrived at config.nu:436 and SIX shell
gates went silently red". The same failure, one character of regex away.

Two ways out, and the cheap one is a trap: naming the file `helpcheck.nu`
fits the existing regex and changes no gate, but leaves the hole for the next
hyphenated module. Widening to `[a-z-]+` and updating the eleven `MODULES=`
constants is the correct fix and is most of unit 1's cost.

## Verdict input

Seven implementable units, summing far past 40. The node holds at least three
separate contracts: a resolver, a ~281-handle data classification, and (per the
binding memo) a `tmux-key` kind against a `tmux.conf` that does not exist yet.
