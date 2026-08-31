# 03-nvim-resolver probe notes

Analyst-as-engineer, 2026-08-29. Appended after each step (connection drops).

## Step 0 — read the brief
- PRD body is a stub (title line only). Contract from parent `## Children`:
  R2 for global maps: one headless spawn that never installs plugins and
  raises on a missing config, the seven normalization rules, three-state desc.
- needs: 01-check-plumbing (done at 366bf77).

## Step 1 — read the ground already covered
Parent probe (266 lines) and 01-check-plumbing probe (325 lines) read whole.
State inherited: `home/dot_config/nushell/help-check.nu` (287 lines, committed)
already holds `_hc_norm_lhs` (7 rules), the three-state `desc` branch, and a
`_hc_nvim_live` that raises on a missing `~/.config/nvim/init.lua` and avoids
`--clean`. What it does NOT do, and what my contract is:
  - it reads the dump off **stdout** (`$out.stdout | from json`), which is
    where lazy.nvim's clone chatter lands -> the end-to-end death at :166;
  - nothing stops lazy.nvim installing missing plugins or running its update
    `checker` during the spawn (network I/O mid-check);
  - a plugin present in `lazy-lock.json` but absent from the store degrades
    SILENTLY once install is off: its maps just vanish -> false stale.
`home/dot_config/nvim/lua/config/lazy.lua` sets `install` (missing defaults
true) and `checker = { enabled = true }` — both reach the network.

## Step 2 — MEASURED: the corpus moved, re-counted rather than inherited
`home/dot_config/nushell/help/nvim.nuon`, this tree (after 7d48eb2):
    verify rows 74 = prose 5 + nvim-map 69
    nvim-map: global 61 · buffer 8      (was 58/8 last round)
    desc: absent 0 · null 7 · explicit 62   (was 0/7/59)
So the brief's "58 global targets" and "59 explicit desc" are both stale by
three — exactly the drift the memo warns about. Every number below is mine.

## Step 3 — MEASURED: THREE installers reach the network, not one
`lazy-lock.json` holds 20 plugins; the live store has all 20; the probe SEED
at /tmp/dc-nvim-seed holds 19 (no persistence.nvim) — a stale seed is
therefore a ready-made fixture for the degradation case.
Network-reaching startup work in the config, all three of which a headless
check spawn triggers:
  1. `lua/config/lazy.lua` — `install.missing` defaults TRUE (clones anything
     in the spec that is not in the store) and `checker = {enabled = true}`
     polls for updates. Plus the bootstrap block, which git-clones lazy.nvim
     itself when absent.
  2. `lua/plugins/lsp.lua:111` — `mason-lspconfig.setup{ensure_installed = 5
     servers}` downloads any server not under `stdpath("data")/mason`.
  3. `lua/plugins/treesitter.lua` — `install()` compiles missing parsers from
     source (curl + tree-sitter CLI) on every launch; offline-safe only once
     warm, by its own recorded measurement.
"Never installs plugins" therefore has three call sites, not one. Guard chosen:
a single `HELP_CHECK=1` env var set by the spawn and read at all three.

## Step 4 BUILT + MEASURED — the spawn observes and never provisions
Edits: `home/dot_config/nvim/lua/config/lazy.lua` (HELP_CHECK guard) and
`home/dot_config/nushell/help-check.nu` (`_hc_nvim_live` rewritten).
Probe harness: `probe/mk-machine.sh <dir> [plugin-to-withhold]` builds a
hermetic machine whose nvim plugin store can be COMPLETE or DEGRADED on
purpose; `probe/nu-c.sh` runs one `nu -c` inside it.

  m-full (24 plugins staged)      -> maps **217**   n 89 · v 45 · x 42 · s 21
                                     · o 11 · i 9
  m-degraded (persistence.nvim
   withheld, 23 staged)           -> RAISES "these plugins are declared but
                                     not installed: persistence.nvim", rc=1,
                                     and the store is STILL 23 — no clone.
  m-noguard (same machine, its
   lazy.lua's `local checking`
   forced to false)               -> store 23 -> **24**: lazy cloned
                                     persistence.nvim FROM THE NETWORK during
                                     the spawn, and the readback raise fired
                                     ("the spawn was allowed to install
                                     plugins"), rc=1.

The counterfactual is the point: the guard is proven load-bearing in both
directions, and the `install_missing` readback is an assertion that CAN fail
rather than a comment. 217 is also 3 more than the 214 the parent measured —
the session maps from 7d48eb2. Re-measured, not inherited.

## Step 5 MEASURED — no-buffer spawn loads five plugins, and no installer runs
`HELP_CHECK=1 nvim --headless` on m-full, reading lazy's own load state:
    loaded: lazy.nvim, nvim-web-devicons, oil.nvim, persistence.nvim, tinted-nvim
    <data>/nvim holds ONLY `lazy` — no `mason`, no `site`
nvim-lspconfig (mason's `ensure_installed`) and nvim-treesitter (`install()`)
are behind BufReadPre/BufReadPost, so a spawn that opens no buffer never
reaches either. That is now measured, not inferred, and it is why the guard
lands in lazy.lua alone. A check that OPENS a buffer — 04-nvim-buffer-maps —
has to carry HELP_CHECK to those two call sites; recorded in lazy.lua's
comment so the next reader does not have to re-derive it.

## Step 6 MEASURED — normalization on the GROWN corpus
m-full, 217 live maps, 61 global nvim-map targets:
    raw lhs           : 30 resolve
    seven rules       : **61 of 61**, zero misses
The seven rules are unchanged and still sufficient; the three targets added by
07-multiplexer/06-nvim-session resolve under them without a new rule.
Whole-run nvim surface: stale 0 · mismatched 0 · unresolved 8 (all buffer) ·
undocumented 156 (R6's, i.e. 05-allowlist's).

## Step 7 MEASURED — the desc three-state, all three states, by mutation
`probe/mutations.sh <machine>` applies each mutation, measures, reverts.
    M0 baseline                                        -> no findings
    M1 explicit desc drifts (live "Write the file")    -> **mismatched**
    M2 the map is deleted (<leader>w)                  -> **stale**
    M3 desc ABSENT (removed from the corpus target)    -> **mismatched**,
       and the message names the entry's TITLE: "<C-l>: live 'Go to right
       window' vs manual 'Move between windows'" — proof the absent state
       compares against the title, which no corpus target exercises today
       (absent 0)
    M4 desc NULL + a drifted live desc                 -> **no finding**
So each of the three states is proven by a mutation that fails without it,
including the one the corpus does not currently contain.

## Step 8 MEASURED — the core-default collision, re-counted
Bare `nvim --headless` with an empty HOME: **123** core default maps (same as
last round). Intersected with the 61 global targets: **8 collide** —
`<C-l> grn gra grr gri gO ]d [d` — and **all eight carry an explicit desc**.
Every null-desc target (`n <C-d>`, `n <C-u>`, `n n`, `n N`, `v <`, `v >`)
collides with nothing. So the degradation is bounded and NOT silent: deleting
a colliding map reports *mismatched* instead of *stale*, and the only shape
that would be invisible — a colliding target with `desc: null` — does not
exist in the corpus. The brief's "the real blind spot is 1 target" is better
stated as: 8 targets report the wrong CLASS on deletion, 0 report nothing.

## Step 9 — BLAST RADIUS of the lazy.lua edit, found by running, not reading
`tests/nvim-plugin-manager.sh` went **red** on the first run of it after the
guard landed:
    FAIL counterfactual: checker flipped off -> the checker.enabled check FAILS
Its counterfactual is a literal `sed 's/checker = { enabled = true/...'`, and
the line now reads `enabled = not checking`, so the MUTATION SILENTLY STOPPED
MUTATING — the counterfactual was vacuous, not the config broken. Fixed by
matching the new literal AND adding a staging assertion (`grep -qF` on the
copy) so a sed that matches nothing can never again read as a pass.
Gate now also asserts the guard itself, both directions:
    R6: install.missing = true on an ordinary launch
    HELP_CHECK=1: install.missing = false · checker.enabled = false ·
                  install.colorscheme untouched
    counterfactual: `local checking` forced false -> HELP_CHECK no longer
                  stops installing (the row that stops the guard being deleted)
`bash tests/nvim-plugin-manager.sh` -> rc=0, **72 PASS / 0 FAIL** (was 63).

A SECOND reader nearly went red and was avoided by writing the Lua
differently. `tests/nvim-colorscheme.sh:216` extracts the scheme with the
literal regex `install = \{ colorscheme = \{ "` . Measured against both key
orders: `install = { missing = ..., colorscheme = ... }` matches NOTHING;
`install = { colorscheme = ..., missing = ... }` still returns the scheme. So
`missing` goes last, and the reason is written at the line.
`bash tests/nvim-colorscheme.sh` -> rc=0, 121 PASS / 0 FAIL.

## Step 10 MEASURED — end to end, and the sibling's blocker is gone
Fresh machine, `help --check`:
    documented 147 · prose-only 16 · allowlisted 10 · live nvim maps 217
    stale 4        (the four shell corpus defects 02-shell-resolver owns)
    mismatched 0
    undocumented 173
    unresolved 8   (buffer-local, 04-nvim-buffer-maps')
    RC=1 — raised by the drift count, NOT by a JSON parse error
The `help-check.nu:166` death 01-check-plumbing recorded twice ("Error while
parsing JSON text") no longer happens: the dump is a file, and the plugin
that was being cloned mid-run cannot be cloned at all now.

## Step 11 — the corpus README gained the seventh rule
`home/dot_config/nushell/help/README.md`: the `<space>` -> `" "` row, plus the
measured weight of the table (raw 30 of 61, normalized 61 of 61). No gate
reads that table (`grep -rn 'leader expanded|normalized form|help/README'
tests gates` -> nothing), so it is documentation only.

## Step 12 — regression sweep on everything that reads what I touched
    tests/nvim-plugin-manager.sh  rc=0  72 PASS / 0 FAIL
    tests/nvim-colorscheme.sh     rc=0  121 PASS / 0 FAIL
    tests/shell-help.sh           rc=0   94 PASS / 0 FAIL
    tests/help-agent.sh           rc=0  100 PASS / 0 FAIL
    tests/help-browser.sh         rc=0   97 PASS / 0 FAIL

## Step 13 MEASURED — the two remaining raise paths
    no ~/.config/nvim at all      -> rc=1, "init.lua is missing …"
    lazy.nvim deleted from the
      store, HELP_CHECK on        -> rc=1, "nvim --headless exited 1 —
                                    HELP_CHECK: lazy.nvim is not installed
                                    at <path>", and lazy.nvim was NOT cloned
The `$j.lazy != true` branch is unreachable while the bootstrap guard stands
(the spawn exits 1 first) — it is defence for the case where someone removes
the guard but not lazy, and it is honest to record that it has no measurement
of its own.

## Step 14 — spec01 written, and its Verify block EXECUTED whole
`bash <extracted sh block>` under `set -e -o pipefail` -> **rc=0**.
Two traps hit while writing it, both of the class this board keeps hitting:
  1. `nu -c` RAISES on the missing-config paths, so
     `nu-c.sh … | grep -q 'init.lua is missing'` dies on pipefail even though
     the grep matched. Capture into a variable, then grep the variable.
  2. **nushell wraps `error make` text to the width of what it is printing
     to, with a `| ` continuation.** `grep -q 'allowed to install plugins'`
     matched interactively and MISSED in a redirect, where the wrap fell
     mid-phrase. The block now flattens the captured text (`flat()`) before
     every message assertion. Found by running the block, not by reading it —
     the first execution failed on exactly this line.
`probe/mutations.sh` was rewritten to ASSERT each expectation and exit
non-zero on a mismatch, so the desc boxes are checks rather than printouts.
Re-run against a freshly staged machine after every edit: the first run used
a machine staged before the last change to help-check.nu and reported the OLD
message text.

## Defects found outside this node's scope (reported, not fixed)
- `tests/nvim-plugin-manager.sh`'s checker counterfactual was a literal sed
  with no staging assertion, so it went vacuous the moment the line it
  matched changed. Fixed here because my edit is what changed the line, and a
  staging `grep -qF` added beside it. The same shape exists elsewhere in that
  file (three more `sed -i ''` counterfactuals) — only the two I touched now
  assert that the mutation landed.
- `tests/nvim-colorscheme.sh:216` reads lazy.lua with the literal regex
  `install = \{ colorscheme = \{ "` . Any key added before `colorscheme`
  turns that gate red on a file it only reads. Worked around by key order,
  with the reason written at the line; the extractor itself is 03-editor's.
