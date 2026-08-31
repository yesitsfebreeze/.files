# spec02 — the keymaps gate: tests/nvim-keymaps.sh, registered in wave 3

Delivers the standing proof for R1–R9: a gate that runs the deployed-shape
config in a hermetic headless Neovim, reads every map back through
`maparg()`, executes the behavioral acceptance, and registers itself in
wave 3. Every probe mechanic below was RUN on this machine on 2026-08-22
against Neovim 0.12.4 before being prescribed; none is assumed.

**Est:** 1.5h

**Footprint:** `tests/nvim-keymaps.sh` (create), `gates/waves.tsv`
(wave 3 gates cell, one appended entry — SHARED FILE, see Registration)

## Shape

`bash tests/nvim-keymaps.sh [--tree|--headless]`, no argument runs both.
Source `gates/lib.sh`; follow `gates/probes.sh`'s editor rules and the
E.1/E.6 gate conventions: results to **stderr** (`--headless` stdout is
not a clean channel), every XDG dir into scratch, `/usr/bin/grep` always
(bare `grep` is ugrep here), `snapshot_paths`/`assert_unchanged` around
`~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
`~/.cache/nvim`.

**Staging is E.6's, not E.1's:** `init.lua` now requires `config.lazy`,
so a bare headless run tries to clone lazy.nvim. Reuse
`tests/nvim-completion.sh`'s lockfile-driven staging verbatim —
`LOCK_KEYS` from `lazy-lock.json`, `need_seed_source` (a missing live
clone is PROBE-ERROR 127, never a skip), `seed_lazy`, `cmp_stage`, and
its `cp -R`-to-nonexistent-destination warning. The git shim is not
needed: no probe here loads a plugin on purpose, and hermeticity is
already proven by E.6's gate — do not duplicate that owner.

**Simpler than E.6, measured:** these maps do nothing async.
`nvim_feedkeys(keys, "mx", false)` executes synchronously — "x" drains
the typeahead before returning — so every probe is a plain `-c` chain
ending `-c 'qa!'`. No defer_fn, no poll loop, no backgrounding.

**Vacuity control, every invocation:** the same lookup against a second
staging whose `keymaps.lua` is deleted (and its require line stripped
from `init.lua`) must report `maparg("<A-j>","n") == ""`, or the probe
is reading something other than this file.

## --tree: the files as text

- `home/dot_config/nvim/lua/config/keymaps.lua` exists.
- `init.lua` require order: `config.options` then `config.keymaps` then
  `config.lazy`, comment lines stripped first (the seam comment names
  modules in prose). Do NOT assert `config.autocmds` absent — E.4 adds
  it, same wave, and this gate stays green when it does.
- Scope guards on `keymaps.lua`, 0 hits each: `nvim_create_autocmd`
  (no autocmds — the live file's ungrouped `ModeChanged` is L-8 and
  E.14's), `shift_select`, `<S-Up>`, `<S-Down>`, `<S-Left>`,
  `<S-Right>`, `nohlsearch` (R1), `require(` (no plugin references),
  and `map(` lines mentioning `<C-q>`, `<C-c>` or `<C-v>` (R9 / E.14's
  keys; the R9 prose comment mentioning `<C-q>` must not trip this —
  match map calls, not comments).
- The two load-bearing comments present by keyword, one check each:
  the no-desc/re-centre reason, the `<C-q>`-unbound R9 note.

## --headless: the staged config in a real Neovim

**Readback, one `chk` per map.** `vim.fn.maparg(lhs, mode, false, true)`
accepts the source spelling (`<A-j>`, `<leader>p` — leader is set by
`config.options`) and returns `rhs` verbatim plus `desc` (measured).
Assert rhs and desc for all 20 desc-carrying maps against spec01's
table, and for the six no-desc maps assert rhs and `desc == nil`. Do
NOT use `nvim_get_keymap` lhs matching: it returns normalized notation
— `<A-j>` reads back `<M-j>`, `<C-d>` as `<C-D>`, `<leader>w` as a
literal `" w"`, `<` as `<lt>` (measured) — a lookup by written lhs
silently finds nothing.

**R9, the unbound key:** `maparg("<C-q>", m) == ""` for m in n, v, x,
i, o. This runs against the FULL staged config with plugins seeded, so
every rerun re-proves the epic-wide "no node may map it" — at wave 3
and after every later editor node lands.

**Behavioral probes, each its own `nv` run, all mechanics measured:**

- **Move line (R4 n-mode):** buffer `one two three four`, `gg` then
  feed `<A-j>` → lines read `two,one,three,four`.
- **Move selection (R4 v-mode, the PRD's second acceptance box):**
  feed `3GVj<A-k>` → the two lines moved up one, `vim.fn.mode() == "V"`
  (still selected), `line("v")`/`line(".")` span exactly the moved pair
  (measured: sel=2-3). The `=gv` re-indent is in the asserted rhs.
- **Indent keeps selection (R6):** on an indent-sensitive buffer feed
  `2GV>>` → the line gains 2×shiftwidth (4 spaces — the second `>`
  only lands if `gv` kept the selection) and `mode() == "V"`.
- **Buffer cycle (R3):** two files, feed `L` → bufname changes; feed
  `H` → back (measured).
- **Save (R7):** modify the buffer, feed `<leader>w` → `modified` is
  false and the bytes are on disk.
- **Register-safe paste (R8):** `clipboard=unnamedplus` would hit the
  real macOS clipboard, so the probe passes
  `--cmd 'lua vim.g.clipboard = { name="scratch", copy={...}, paste={...} }'`
  — an in-process Lua provider (measured working headless) — BEFORE the
  config loads. Then: `setreg("+","ZZZ")`, select line 2 (`BBB`), feed
  `<leader>p` → line 2 is `ZZZ` **and** `getreg("+")` is still `ZZZ`.
  The register half is the point of `"_dP`.
- Window nav/resize/splits (R2) and the centered-jump group (R5) are
  held by the rhs readback alone. Stated, not dodged: a behavioral
  scrolloff-999 centering probe passes with or without the `zz` maps
  mid-file (E.1's option masks them), so it would be a check that
  cannot fail — the rhs equality is the honest form, and the manual's
  `desc: null` targets pin the same four maps.

## Counterfactuals — the gate must be seen to fail

Against mutated stagings (never the repo files), each expected to FAIL
its check, shown in the gate's own output:

- Delete the visual `<A-j>`/`<A-k>` maps → the move-selection probe
  fails.
- Change `"_dP` to `p` in `<leader>p` → the paste probe fails on the
  register half (`getreg("+")` comes back `BBB`).
- Change `<gv` to `<` → the indent probe fails (`mode()` is `n` after
  the first `>`; the second never applies to the selection).
- Append `map("n", "<C-q>", "<Nop>")` → the R9 unbound check fails.

## Registration

Append ` | external bash tests/nvim-keymaps.sh` to **wave 3**'s gates
cell in `gates/waves.tsv` — E.3 is a wave 3 task; without the entry the
wave arms with the keymaps unproven. `external` because the script
lives in `tests/`; `gates/selftest.sh` reports it
unverified-by-contract, and the counterfactuals above are its own
falsification.

**Shared-file warning, not waivable silently:** one writer per file,
not per line. E.4 (same wave) will append to the same wave-3 cell, and
the S.5 lane holds staging lines in seven shell/capsule gate scripts —
not `waves.tsv`, but the orchestrator confirms nothing is mid-flight in
the file before this one-line append lands, or hands the append to
whoever holds it.

## Acceptance

- [x] `bash tests/nvim-keymaps.sh` exits 0 on the finished spec01 work:
      one `chk` per readback row, the R9 sweep, the six behavioral
      probes, all relayed from stderr.
  - Ran 2026-08-23: 108 PASS, 0 FAIL, `exit=0`. 26 readback `chk`s (rhs
    AND desc, `desc [<nil>]` measured on exactly the six no-desc maps),
    the R9 sweep green in n/v/x/i/o, and SEVEN behavioral probes rather
    than six — the re-indent half of the PRD's second acceptance box is
    executed here rather than left to the asserted rhs; see the box below
    and the gate header.
- [x] Every counterfactual staging fails its check — shown in the
      gate's output, not asserted in prose.
  - Five, each printing its own measurement: visual `<A-j>`/`<A-k>`
    deleted → `after=one,two,three,four`; `gv=gv` stripped of its `=` →
    `after=        wrong|if x then|end`; `"_dP` → `p` →
    `unnamed_after=BBB lines2=AAA,ZZZ,BBB`; `<gv`/`>gv` → bare `<`/`>` →
    `mode=n line2=[  bbb]`; `map("n", "<C-q>", "<Nop>")` appended →
    `n=[<Nop>]`, red on the tree guard too.
  - MEASURED CORRECTION to the paste counterfactual as specced. This spec
    says `getreg("+")` comes back `BBB`. IT DOES NOT: `+` reads `ZZZ`
    under BOTH configs, so that assertion cannot fail on this machine.
    Cause, measured with a counting Lua clipboard provider installed via
    `--cmd` before the config loads: under `clipboard=unnamedplus` this
    headless Neovim does not route implicit yanks/deletes through the
    provider at all (`"+yy` calls copy once, a following plain `yy` never
    calls it), so `"` and `+` are not aliased here. The discriminating
    observables are the UNNAMED register and a second paste of the same
    text; both are asserted. `+` is still read and printed as the
    containment check that no probe reached a real pasteboard.
- [x] The vacuity control runs on every invocation: the no-keymaps
      staging reports `<A-j>` unmapped.
  - Runs on every `--headless`/no-arg invocation.
    `STILL BOUND: RB n <A-j> BAD rhs=[<none>] desc=[<none>]` is absent —
    `<A-j>` is unmapped, and 0 of 26 rows read back the specced value.
  - AND IT CAUGHT SOMETHING. The obvious form of this check — all 26
    unmapped — GOES RED ON A CORRECT CONFIG: 25 come back unmapped and
    `<C-l>` comes back as Neovim's own default,
    `rhs=[<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>]
    desc=[:help CTRL-L-default]`. So R2's `<C-l>` → `<C-w>l` REPLACES a
    built-in rather than filling an empty slot. The control now asserts
    25 unmapped, that one exception BY NAME with its documented desc, and
    that not one row reads the specced value.
- [x] `assert_unchanged` passes: the developer's real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` are
      byte-identical after a full run.
  - `PASS  the gate touched no REAL Neovim state (~/.config/nvim,
    ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)` on every
    run, both stages and the full run.
- [x] **Amended and closed 2026-08-24 by the orchestrator.** The box asked
      two things: that `gates/waves.tsv` wave 3 names the gate, **and** that
      `bash gates/selftest.sh` still exits 0. The first is this node's and is
      proven. The second is a **whole-workspace verify**, and the board's own
      protocol says not to write one: it inherits every other node's flake, so
      it measures the tree's worst neighbour rather than this node's work.
      Tonight it measured five concurrent lanes. Struck on that ground, not
      because it is inconvenient — the worker was right to refuse to tick it,
      and right not to chase it.

      Replaced by the assertion this node can actually own: the gate is
      registered, `selftest.sh` classifies it correctly, and **no FAIL
      `selftest.sh` reports names this gate or `waves.tsv`**. All three are
      proven below. The two residual reds are named and routed in the PRD
      body.
  - HALF PROVEN as written, and the proven half is the half that is this
    node's. `grep -c nvim-keymaps
    gates/waves.tsv` → `1`, in the wave-3 row, and
    `bash gates/wave-status.sh` now reports wave 3 with `19 registered`
    (was 18). `gates/selftest.sh` reports it exactly as this spec
    predicted: `external, not held to the contract (owned by another
    node): bash tests/nvim-keymaps.sh`.
  - But `bash gates/selftest.sh` DOES NOT exit 0, and it did not before
    this node touched anything. Baseline, captured before the first write
    of this session: `exit=1`, 30 PASS, 8 FAIL. Final run after every
    write here: `exit=1`, 2 FAIL — `retired-phrases.sh --selftest` rc 1
    and `wave-status.sh --selftest` rc 1, BOTH red at baseline. Neither
    names this gate or `waves.tsv`.
  - The six baseline FAILs that cleared were lane races, not fixes, and
    they are why a whole-tree sweep is noisy tonight: an intermediate run
    of this same command showed three FAILs on
    `gates/nushell-module-staging.sh` (the S.5 lane rewriting it, so
    `--selftest` printed no MUTATION line) plus "wrote nothing outside
    its scratch" on `audit-findings.sh` and `manual-coverage.sh`, whose
    guard hashes `gates/` and `tests/` while other lanes write into them.
    Reported, not chased.
- [x] Wave-3 neighbors stay green, unedited: `bash
      tests/nvim-completion.sh` and `bash tests/nvim-plugin-manager.sh
      --tree` exit 0.
  - `nvim-completion exit=0` — `PASS — blink.cmp completion proven in a
    hermetic Neovim`. `plugin-manager --tree exit=0` — `PASS —
    lazy.nvim bootstrap, opts, and lockfile proven`. Both unedited.
    `bash tests/nvim-autocmds.sh` (E.4, the shared init.lua seam) also
    `exit=0` after the require was inserted above its own.
  - `bash tests/nvim-options.sh` was RED on this node's new file and is
    now green: E.1's gate asserts an exact file census of
    `home/dot_config/nvim/`, and `./lua/config/keymaps.lua` was added to
    it on the orchestrator's instruction — one entry, nothing else in
    that file. `exit=0`, no FAIL lines, and the census string now equals
    `find . -type f | LC_ALL=C sort` over the real tree byte for byte.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-keymaps.sh
bash gates/selftest.sh
bash tests/nvim-completion.sh
bash tests/nvim-plugin-manager.sh --tree
/usr/bin/grep -n 'nvim-keymaps' gates/waves.tsv   # wave 3 row
```
