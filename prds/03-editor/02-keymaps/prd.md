---
state: done
claim:
priority: 14
est: 2h
task: E.3
mode: afk
needs:
  - 03-editor/01-options
  - 06-help/01-content-model
  - 03-editor/03-autocmds
footprint:
  - home/dot_config/nvim/lua/config/keymaps.lua
  - home/dot_config/nvim/init.lua
  - tests/nvim-keymaps.sh
  - gates/waves.tsv
verify: "bash tests/nvim-keymaps.sh"
---

# Core keymaps

Parent: [Neovim epic](../prd.md) · C 2 · U 9 · source: "Core keymaps" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: The general keymap set. Plugin-specific maps do NOT live here — they
belong in their plugin spec's `keys = …` so the plugin lazy-loads.

## Requirements
- [x] **R1** — **Search: no `nohlsearch` map.** The live `<Esc>` →
      `<cmd>nohlsearch<CR>` map is **not ported** (live bug L-6,
      `lua/config/keymaps.lua:4`). With
      [`01-options`](../01-options/prd.md) R6's `hlsearch=false` there is
      never a highlight to clear, so the map is inert — decided 2026-08-21
      (afk) in
      [the corrections backlog](../../00-delivery/corrections/prd.md).
      Rejected: the LazyVim pairing, turning `hlsearch` on and keeping the
      map, which changes the feel of every search to give one dead line a
      job and would make [`06-help`](../../06-help/prd.md) document a
      binding that never fires. This requirement keeps its number and
      prescribes no keymap.
- [x] **R2** — **Windows.** `<C-h/j/k/l>` move between windows; `<C-Up/Down>`
      resize height ±2, `<C-Left/Right>` resize width ±2; `<leader>|` vsplit,
      `<leader>-` split.
- [x] **R3** — **Buffers.** `<S-h>` / `<S-l>` previous/next buffer,
      `<leader>bd` delete.
- [x] **R4** — **Move lines.** `<A-j>` / `<A-k>` move the current line
      (normal) or the selection (visual, re-selecting and re-indenting with
      `gv=gv`).
- [x] **R5** — **Stay centered.** `<C-d>`/`<C-u>` append `zz`; `n`/`N` →
      `nzzzv`/`Nzzzv` (centered and folds opened).
- [x] **R6** — **Visual indent.** `<` / `>` keep the selection (`<gv`, `>gv`).
- [x] **R7** — **Save/quit.** `<leader>w` write, `<leader>q` quit.
- [x] **R8** — **Register-safe paste.** `<leader>p` in visual → `"_dP`.
      Editor-style Shift+arrow selection and `<C-c>`/`<C-v>` are specced
      separately in [14-shift-select](../14-shift-select/prd.md).
- [x] **R9** — **`<C-v>` shadows blockwise-visual, deliberately;
      `<C-q>` stays unbound.** [`14-shift-select`](../14-shift-select/prd.md)
      R7 binds `<C-v>` in **visual mode** to `"_dP`, which shadows vim's
      entry into blockwise-visual from a selection. That is live bug L-9, and it
      was **decided 2026-08-21 (afk) to port as-is** — see
      [the corrections backlog](../../00-delivery/corrections/prd.md). It is
      half of the `<C-c>`/`<C-v>` pair that is the whole point of
      shift-select, and the shadow is narrow: the map is `v`-mode only, so
      normal-mode `<C-v>` still enters blockwise, and
      [`01-options`](../01-options/prd.md) R9's `virtualedit=block` still
      applies. Rejected: moving paste to another key, which breaks the pair
      for a mode that keeps a working alternative.

      **`<C-q>` is left unbound, on purpose.** It is vim's built-in
      synonym for blockwise-visual and the route the shadow leaves open, so
      binding it to anything closes the escape hatch that makes L-9
      acceptable. No node in this epic may map it. This is stated as a
      requirement because an unbound key is invisible to search — nothing
      else in the tree would stop a later agent from taking it.

## Acceptance
- [x] Every map above fires; `which-key` shows a description for each — except
      the centered-jump maps and the visual-indent `<`/`>` maps, which
      intentionally carry none.
  - Amended 2026-08-22 (analyst-keymaps): the parenthetical named only the
    centered-jump maps, but the live file and `nvim.nuon` (done dep H.1) fix
    visual `<`/`>` as `desc: null` too — six desc-less maps, not four.
    Aligned to the manual; no map gains or loses a desc by this edit.
    which-key itself lands with [`12-small-plugins`](../12-small-plugins/prd.md)
    (wave 4); the executable form at E.3 is the map's `desc`, which is the
    datum which-key renders.
  - Ran 2026-08-23, `bash tests/nvim-keymaps.sh` (exit 0): 26 `maparg`
    readbacks, each asserting rhs AND desc against spec01's table — e.g.
    `PASS  readback: n <A-j> -> rhs [<cmd>m .+1<CR>==] desc [Move line
    down]  ·  measured rhs=[<cmd>m .+1<CR>==] desc=[Move line down]`. The
    six exceptions measured `desc=[<nil>]` and no others did:
    `<C-d>`, `<C-u>`, `n`, `N`, visual `<`, visual `>`. Checked by hand
    against `help/nvim.nuon`: all 26 mode/lhs/desc triples match its
    `nvim-map` targets exactly, `desc: null` on exactly those six.
  - What "fires" means per map, stated rather than blurred: R3, R4, R6,
    R7 and R8 are EXECUTED by behavioral probes (see the next box and the
    gate's output). R2's window/resize/split maps and R5's centered jumps
    are held by rhs equality — spec02's reasoning, kept: a headless
    centering probe passes with or without the `zz` under E.1's
    `scrolloff=999`, so it would be a check that cannot fail.
  - Not proven here and not this node's: which-key's rendering. It lands
    with E.12 in wave 4.
- [x] `<A-k>` on a visual block moves it and leaves it selected and
      re-indented.
  - All three halves executed, not read off the rhs.
    Moves: `move selection (rc 0): after=one,three,four,two`.
    Still selected: `mode=V` with `sel=2-3`, exactly the moved pair.
    Re-indented: on a real `.lua` buffer (so nvim-treesitter's
    `indentexpr` is in place) `if x then | ········wrong | end` becomes
    `wrong | if x then | end` — the eight wrong spaces collapse to column
    0, which is the `=` in `gv=gv` doing its work. spec02 left this half
    to the asserted rhs; it turned out cheap to observe, so the gate
    observes it, with the counterfactual to match: strip the `=` and the
    line keeps its indent (`after=        wrong|if x then|end`).
- [x] No map in this file references a plugin.
  - `PASS  tree: no require( — PRD acceptance 3, no map here references a
    plugin` and `PASS  tree: no plugin repo string`. Controlled: a planted
    `require("which-key")` turns the first red in the selftests.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Verification — implemented 2026-08-23

`bash tests/nvim-keymaps.sh` (the node's `verify`) exits 0: 108 PASS, 0
FAIL, over `--tree` and `--headless`. What each requirement's tick rests on:

| R | Executed | Read back | Counterfactual |
|---|---|---|---|
| R1 | — | `nohlsearch` and `"<Esc>"` absent, 0 hits each | the live `<Esc>` map planted → both checks red |
| R2 | — | all 10 window/resize/split maps, rhs + desc | — (see the Acceptance note on why) |
| R3 | `<S-l>` a.txt→b.txt, `<S-h>` back | all 3 maps, rhs + desc | — |
| R4 | n-mode move, v-mode move, still-selected, span, re-indent | all 4 maps, rhs + desc | visual maps deleted → no move; `=` stripped → indent kept |
| R5 | — | `<C-d>zz`, `<C-u>zz`, `nzzzv`, `Nzzzv`, all `desc=[<nil>]` | — (a centering probe cannot fail under `scrolloff=999`) |
| R6 | `2GV>>` → 4 spaces, `mode()=V` | `<gv`, `>gv`, `desc=[<nil>]` | `gv` stripped → `mode=n`, 2 spaces |
| R7 | `<leader>w` clears `modified`, bytes on disk | both maps, rhs + desc | — |
| R8 | line replaced, register survives, second paste lands | rhs `"_dP`, desc | `p` instead → register clobbered, second paste wrong |
| R9 | `maparg("<C-q>", m) == ""` in n/v/x/i/o against the full staged config | no `map(` call on `<C-q>`/`<C-c>`/`<C-v>` here, and none anywhere under `lua/` | `map("n","<C-q>","<Nop>")` appended → red at runtime and in the tree |

Three things the run measured that the specs did not predict, all recorded
in the gate header and the spec boxes:

1. **`<C-l>` is not an empty slot.** The vacuity control (a staging with
   `keymaps.lua` deleted) reports 25 of 26 maps unmapped, not 26: `<C-l>`
   comes back as Neovim's own `:help CTRL-L-default`,
   `<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>`. R2's map
   REPLACES that built-in. Nothing is lost that R1 has not already
   decided — `hlsearch=false` makes the `nohlsearch` half inert — but the
   built-in's `diffupdate` and redraw go with it, and no PRD says so.
2. **spec02's paste counterfactual does not reproduce.** `getreg("+")`
   reads `ZZZ` under both the correct config and the `p` mutation, because
   under `clipboard=unnamedplus` this headless Neovim does not route
   implicit yanks and deletes through the clipboard provider at all. The
   unnamed register does discriminate, and carries the proof instead.
3. **A new file under `home/dot_config/nvim/` costs a census entry.**
   `tests/nvim-options.sh` (E.1's gate) asserts an exact `find | sort`
   census of that tree, so `./lua/config/keymaps.lua` had to be added to
   it — done on the orchestrator's instruction, one entry, nothing else in
   that file. The gate is green again.

## Failure — history, retried 2026-08-23

Retried 2026-08-23T20:52Z by the user's answer in the round. Set `specced`, not
`open`: both specs are on disk and the sweep below establishes the node is
unstarted rather than half-built, so a re-spec would discard work that is
sitting there. The history stays for whoever picks it up.

Swept by the orchestrator on 2026-08-22 22:05: the PRD was left `claimed` by
`implementer-keymaps`, whose session died. No live worker held the claim
(claim written 16:24, ~5.6h earlier).

Evidence at sweep time: both specs' acceptance boxes are unticked, no report
exists, and nothing landed in the target repo — `home/dot_config/nvim/lua/config/`
holds only `lazy.lua` and `options.lua`, and the spec's gate
`tests/nvim-keymaps.sh` was never written. Treat this as an unstarted node, not
a partial one; a retry can begin from the specs as written.

## Closed 2026-08-24 by the orchestrator

`done`. `bash tests/nvim-keymaps.sh` exits 0 at **108 PASS / 0 FAIL**; R1–R9
and all three acceptance boxes `[x]`, each against the output it rests on, with
a `## Verification` table separating what was *executed* from what was *read
back*. Wave-3 neighbours green and unedited (`nvim-completion` 0,
`nvim-plugin-manager --tree` 0, `nvim-autocmds` 0 on the shared seam), and
`tests/nvim-options.sh` is green after the census entry — re-run by the
orchestrator on this transition: **74 PASS / 0 FAIL, rc 0**.

**`actual:` left empty**: this was a retry over a swept `claimed`, and the node
carries a `## Failure` history.

**The census entry was not in the specs.** spec01 named `keymaps.lua` and
`init.lua` and stopped there, so as specced this node would have landed a new
file the census does not know about and left `tests/nvim-options.sh` red. The
`07-formatting` lane isolated it by construction — a copy of the tree minus
this node's untracked file yields a `find | sort` string byte-identical to the
census line — and the orchestrator extended this worker's brief rather than
respawning. Every nvim node that adds a file adds its own census entry; the
spec omission is the finding, not the entry.

**Three things the run measured that the specs did not predict:**

1. **`<C-l>` was never an empty slot, and R2 silently replaces a built-in.**
   The vacuity control is what caught it: "all 26 unmapped without
   `keymaps.lua`" **goes red on a correct config**, because 25 come back
   unmapped and `<C-l>` returns Neovim's own default,
   `<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>`. R1's `hlsearch=false`
   already makes the `nohlsearch` half inert, but the built-in's `diffupdate`
   and forced redraw go with it and **no requirement on this board says so**.
   The control now asserts 25 unmapped, that one exception by name, and that 0
   rows read the specced value. If the lost redraw is ever missed, that is a
   correction against R2 with this measurement already in hand — it is a
   deliberate, now-documented replacement rather than an accident.
2. **spec02's paste counterfactual does not reproduce, and the register it
   named cannot discriminate.** It prescribed `getreg("+")` returning `BBB`;
   `+` reads `ZZZ` under both the correct config and the mutation. Measured
   with a counting Lua clipboard provider: under `clipboard=unnamedplus` this
   headless Neovim never routes implicit yanks or deletes through the provider
   — `"+yy` calls copy once, a following plain `yy` never does — so `"` and
   `+` are **not** aliased and the specced assertion could not fail. The
   unnamed register does discriminate (`ZZZ` vs `BBB`), as does a second paste
   of the same text (`AAA,ZZZ,ZZZ` vs `AAA,ZZZ,BBB`); both are asserted, and
   `+` is kept only as the containment check that no probe reached the real
   pasteboard.
3. **The re-indent was made behavioural rather than textual.** spec02 left
   `gv=gv`'s `=` to an asserted right-hand side while the PRD's second
   acceptance box asks for the behaviour in words. On a real `.lua` fixture,
   so treesitter's `indentexpr` is present, `<A-k>` turns `········wrong` into
   column-0 `wrong`, with the counterfactual: strip the `=` and the indent
   survives. Seven behavioural probes, five counterfactuals.

**Two residual reds, neither this node's, both routed rather than absorbed:**
`gates/selftest.sh` exits 1 on `retired-phrases.sh --selftest` rc 1 and
`wave-status.sh --selftest` rc 1, **both red at baseline before this node's
first write** (baseline was 30 PASS / 8 FAIL; six of those cleared as other
lanes landed, which is lane noise, not repair). Neither names this gate or
`waves.tsv`. They are the board's `--selftest` contract failing for two gates
that nothing on the board owns; recorded in
[`the counterfactual memo`](../../memos/a-counterfactual-proves-its-own-mutation.md)'s
territory and reported in the round rather than absorbed into an unrelated
node's acceptance.
