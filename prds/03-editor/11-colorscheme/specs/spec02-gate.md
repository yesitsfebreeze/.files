---
est: 1.5h
footprint:
  - tests/nvim-colorscheme.sh
  - gates/waves.tsv
---

# spec02 — the standing gate `tests/nvim-colorscheme.sh`, and the wave-3 cell

Write `tests/nvim-colorscheme.sh` (stages `--tree` / `--headless`) proving
R1–R7 and all four PRD acceptance boxes against a staged, seeded, offline
Neovim, and register both stages in `gates/waves.tsv` wave 3 — E.5's wave.

Every value below was measured 2026-08-22 on nvim 0.12.4 with tinted-nvim
`a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5`. Nothing here is hoped.

**No `--network` stage.** Restore-reproducibility for the new lockfile row
lives in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop, which
widens on its own; duplicating it would give one fact two owners.

**Not this gate's subject:** the tinty→WezTerm half of the palette chain.
`tests/theme-switcher.sh` (S.9) owns the hook and `colors.lua` generation;
`tests/wezterm-appearance.sh` (T.1) owns the `dofile` read. This gate proves
the *editor* half — that the background is inherited rather than painted,
and that the syntax palette is deliberately static.

## Runner

Source `gates/lib.sh`; `chk` / `chk_ok` / `chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` **and `~/.config/wezterm`** —
this node's subject is a palette chain whose other end is a real deployed
file, so the guard has to cover it — plus `assert_unchanged` at exit.
`/usr/bin/grep` always: bare `grep` is ugrep on this machine. Missing `nvim`
or `python3` is `PROBE-ERROR` and exit 127, the `tests/nvim-options.sh`
shape, never a skip.

Stage `home/dot_config/nvim/` into a scratch XDG root with `HOME` pinned to
the same root; seed with the lockfile-driven helper
(`tests/nvim-options.sh`'s `seed_lazy`: every `lazy-lock.json` key copied
from `~/.local/share/nvim/lazy/<name>`, an absent live clone is
`ASSUMPTION MISSING` + exit 127, and `cp -R` goes to a **nonexistent**
destination — into an existing directory it nests the source inside it).

Watchdog per nvim run: there is no `timeout` on this machine. Background the
process, poll `kill -0` for 20s, `kill -9` on overrun, record TIMEOUT.

Prepend a **logging git shim** to PATH for the whole stage — append `"$*"`
to `git-calls.log`, exec the real git. The hermeticity assertion is that the
log holds no `clone`, `fetch` or `ls-remote`; "no git calls at all" is the
wrong assertion, since a seeded lazy still runs local `rev-parse`.

Results go to **stderr** — `--headless` stdout is not a clean channel.
Probes are `-c` chains that end in `qa!`; do not append a trailing `-c qa`
to a probe that defers work, and never plain `qa` on a modified scratch
buffer (E37 hangs forever headless).

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/colorscheme.lua`, each a function over a path
so the selftest copies reuse it. **Strip comment lines first** for every
value check — this node's file carries long explanatory comments that name
the very strings being matched, and prose is not configuration.

- names `tinted-theming/tinted-nvim`; `priority = 1000`; `lazy = false`;
  `default_scheme = "base16-gruvbox-dark-hard"`;
  `apply_scheme_on_startup = true`; `transparent = true`; `blink = true`;
  `lualine = true`.
- the guard shape (R3): `pcall(require, "tinted-nvim")`, an early return on
  `not ok`, `get_palette()`, and an early return on `not p`. All four, as
  separate `chk` lines — R3 names each.
- the six derivations, base key by base key: `CursorNormal`+`base0D`,
  `CursorInsert`+`base0B`, `CursorVisual`+`base0E`, `CursorReplace`+`base08`,
  `Whitespace`+`base02`, `NonText`+`base02` — each matched on its own line,
  so a swapped pair goes red rather than passing on set membership.
- R4's ordering: the bare `set_palette_hl()` call appears at a **lower line
  number** than `nvim_create_autocmd`, and `nvim_create_autocmd` appears
  exactly once.
- epic I7: `nvim_create_augroup("palette_hl", { clear = true })` — the
  `clear = true` matched, not just the `augroup` word.
- `guicursor`: all five segments verbatim —
  `a:blinkwait700-blinkon400-blinkoff250`, `n-c-sm:block-CursorNormal`,
  `i-ci-ve:ver25-CursorInsert`, `v:block-CursorVisual`,
  `r-cr-o:hor20-CursorReplace`.
- **the hex ban**, and it is the mechanical form of the settled invariant
  "nothing below WezTerm hardcodes hex values":
  `/usr/bin/grep -cE '#[0-9A-Fa-f]{6}'` over the whole file returns 0.
- R7's boundary, as absence: the file contains no `selector`, no
  `TINTED_THEME` and no `current_scheme`. The boundary is the plugin
  default; a spelled-out block is what a future tweak would add, so the
  gate notices it arriving.
- scope guard (epic I8): no `vim.keymap.set`; no `lualine` theme table or
  `require("lualine")`; exactly one repo-shaped string in the file.
- **cross-file consistency:** `lua/config/lazy.lua`'s
  `install = { colorscheme = { … } }` names the same scheme string as
  `default_scheme`. Until this node landed, lazy named a scheme no plugin
  provided; the two must not drift apart again. Read-only — do not edit
  `lazy.lua`.
- `lazy-lock.json`: parses (python3), holds `tinted-nvim`, `commit` is 40
  hex chars. Membership, not exact equality — the exact key set is nobody's
  contract here, and later plugin nodes must not have to edit this gate.

**Carry a comment saying what `lazy = false` cannot be proved by.**
`lua/config/lazy.lua` sets `defaults = { lazy = false }`, so deleting the
line changes no observable state (measured). It is a text check only, and
saying so stops a later reader from "strengthening" it into a vacuous
readback.

**Selftests, every invocation** — each a copy with one mutation, each named:
`default_scheme` pointed at another scheme goes red; `transparent = true` →
`false` goes red; a planted `#1d2021` goes red under the hex ban; the eager
`set_palette_hl()` call deleted goes red under the ordering check;
`clear = true` deleted goes red under I7; a `selector = { enabled = true }`
block planted goes red under the boundary check.

## `--headless` (hermetic; seeded; logging git shim)

**Startup readback probe**, one `chk` per line, every value measured:

- `vim.g.colors_name == "base16-gruvbox-dark-hard"`; `vim.o.background ==
  "dark"`; `vim.o.termguicolors == true`.
- **`Normal` carries no background** — `nvim_get_hl(0, {name="Normal"}).bg`
  is nil. This is R6/PRD acceptance 1's mechanism half: the terminal's
  background *is* the editor's, so a live retint needs no editor change.
- palette readback via `require("tinted-nvim").get_palette()`:
  `base0D=#83a598`, `base0B=#b8bb26`, `base0E=#d3869b`, `base08=#fb4934`,
  `base02=#504945`, `base00=#1d2021` — the scheme R2 names, observed.
- the six groups, **checked twice against different facts**: each group
  equals the corresponding `get_palette()` slot (the derivation, R3), *and*
  each equals the gruvbox-dark-hard literal above (the scheme, R2). One
  check alone cannot fail on the other's defect.
- `lazy.core.config.plugins["tinted-nvim"].priority == 1000` and the plugin
  is loaded at startup (R1). Note in a comment: with the line deleted the
  readback is **nil**, not lazy's default 50 (measured) — so the assertion
  is on the literal 1000, and it discriminates.
- `#nvim_get_autocmds({ group = "palette_hl", event = "ColorScheme" }) == 1`
  — exactly one, R4 plus I7's idempotence.
- `vim.o.guicursor` equals the full five-segment string verbatim (R5).
- **integration effects, not config readback** (R2): `BlinkCmpLabelMatch`
  fg `== #83a598` (base0D) and `LualineInsertA` bg `== #83a598`. Both keys
  are `true` by default, so a `config.options` readback would pass with the
  keys deleted; the groups existing is the only assertion with teeth. Say
  that in a comment. `BlinkCmpMenu` is `{ link = "Pmenu" }` and reads as
  nil through `nvim_get_hl` without `link` following — do not probe it.

**Re-derive probe** (PRD acceptance 3, executed): in one session run
`:colorscheme base16-tokyo-night-dark`, then assert `colors_name` moved and
all six groups equal the **new** palette — measured
`CursorNormal=#2ac3de`, `CursorInsert=#9ece6a`, `CursorVisual=#bb9af7`,
`CursorReplace=#c0caf5`, `Whitespace`/`NonText``=#2f3549` — with `Normal`
still carrying no background. Carry the measured reason as a comment:
`load()` runs `vim.cmd("highlight clear")` before re-applying, so the
failure mode is six **nil** groups, not six stale ones.

**Boundary probe** (R7, and PRD acceptance 4's editor half — this is the
whole reason that box can close without a GUI): in a fresh scratch root,
write `base16-tokyo-night-dark` into
`$HOME/.local/share/tinted-theming/tinty/current_scheme` **and** export both
`TINTED_THEME` and `BASE16_THEME` to it, then launch. Assert:
`vim.g.colors_name` is still `base16-gruvbox-dark-hard`; the `String`
highlight fg is still `#b8bb26`; and
`require("tinted-nvim.config").options.selector.enabled == false`. All three
measured. Comment the two reasons R7 records: the env route reads
`TINTED_THEME` while tinty exports `BASE16_THEME`, and the file route
expands a literal `~` path, ignoring `XDG_DATA_HOME` — which is why the
probe writes under `$HOME/.local/share` and not under the scratch
`XDG_DATA_HOME`.

**Counterfactuals**, each a `cf_stage` copy with one `sed`, each naming the
check it turns red (each costs a watchdogged run, deliberately):

| mutation | goes red on |
|---|---|
| `apply_scheme_on_startup = true` → `false` | `colors_name` nil; all six groups nil |
| `transparent = true` → `false` | `Normal` bg becomes `#1d2021` |
| `priority = 1000` deleted | priority readback nil |
| `lualine = true` → `false` | `LualineInsertA` nil |
| `blink = true` → `false` | `BlinkCmpLabelMatch` nil |
| eager `set_palette_hl()` deleted | `CursorNormal` nil at startup |
| the `ColorScheme` autocmd block deleted | re-derive probe: all six nil after the switch |
| `if not p then return end` deleted **and** `apply_scheme_on_startup = false` | startup errors `attempt to index local 'p' (a nil value)` — R3's nil check is load-bearing, and this is the two-mutation case that shows it |
| `ver25-CursorInsert` → `block-CursorInsert` | the `guicursor` readback |
| `CursorVisual`'s `p.base0E` → `p.base0C` | the per-group derivation check |

**Hermeticity, last check of the stage:** `git-calls.log` holds no
`clone|fetch|ls-remote`.

No-arg runs both stages.

## `gates/waves.tsv`

Append to the **wave-3** gates cell:
`| external bash tests/nvim-colorscheme.sh --tree | external bash tests/nvim-colorscheme.sh --headless`.
That file is a live lane taken round-by-round — hand the one-cell append to
the orchestrator rather than racing it.

## Acceptance

- [x] `bash tests/nvim-colorscheme.sh --tree` exits 0, and all six selftest
      mutations are red-then-caught with their output quoted.
- [x] `bash tests/nvim-colorscheme.sh --headless` exits 0; every one of the
      ten counterfactuals is quoted naming the red check; no TIMEOUT.
- [x] The boundary probe's three assertions are quoted verbatim — this is
      PRD acceptance 4's editor half and closes it against a real run, not a
      reading.
- [x] `git-calls.log` holds no `clone`, `fetch` or `ls-remote` (quoted).
- [x] `assert_unchanged` green — no write to `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` or
      `~/.config/wezterm`.
- [x] **Closed by the orchestrator on the transition.** Appended
      `| external bash tests/nvim-colorscheme.sh --tree | external bash
      tests/nvim-colorscheme.sh --headless` to the wave-3 gates cell;
      `bash gates/wave-status.sh --validate` green on all seven integrity
      checks, `unreferenced: none`. Original box:
      `gates/waves.tsv`'s wave-3 row carries both stages, and
      `bash gates/wave-status.sh` still parses the row.
- [x] **Closed by the orchestrator on the transition**, since it was red on
      exactly the carved-out cell (`unreferenced: nvim-colorscheme.sh`).
      After the append: `bash gates/selftest.sh` → **exit 0, 0 FAIL**,
      `5 script(s) held to the contract · 33 external, reported not failed`.
      Original box: `bash gates/selftest.sh` exits 0 — the new gate satisfies
      the suite's
      `--selftest` contract or is reported as unverified-by-contract, not as
      a failure.

## Verify and Proof

```sh
bash tests/nvim-colorscheme.sh                 # both stages
bash tests/nvim-options.sh                     # census neighbour still green
bash tests/nvim-plugin-manager.sh              # all three stages
bash tests/nvim-completion.sh                  # ban sweep neighbour
bash gates/selftest.sh                         # the meta-gate
bash gates/wave-status.sh                      # the wave-3 row still parses
```

## Implementation notes (2026-08-23)

Two measured corrections to the predictions above. Both are in the gate as
comments, because rediscovering either costs a debugging round.

- **"The `ColorScheme` autocmd block deleted" gives FIVE nil groups, not
  six.** `load()` runs `vim.cmd("highlight clear")` and then re-applies the
  scheme — and `NonText` is a *standard* Vim group, so the incoming scheme
  paints it itself (`#16161e` on tokyo-night) instead of leaving it cleared.
  `Whitespace` is standard too but that scheme does not set it, so it does
  clear to nil. Either way the group no longer carries `base02`, so the
  counterfactual is asserted on the **derivation** rather than on nil-ness:
  the four `Cursor*` groups and `Whitespace` are nil, `NonText` is the
  scheme's own value, and not one of the six still equals its palette slot.
- **`git-calls.log` is ABSENT in this stage, and that is a pass.** The
  runner note "no git calls at all is the wrong assertion" holds for
  `tests/nvim-completion.sh`, where blink.cmp's load-time version check runs
  local `git`. Here nothing installs (everything is seeded) and blink never
  loads, because `lsp.lua` is lazy on `BufReadPre` and no probe in this gate
  opens a file. So the shim is proved by resolving PATH — `command -v git`
  under the probe's PATH is the shim — and the log is judged on its content,
  with an absent log reported as zero calls.

`gates/waves.tsv`'s wave-3 cell is the orchestrator's, so the last two boxes
are left `- [ ]`. Both were proved against a scratch copy of the registry
with the segment appended: `gates/wave-status.sh --validate --registry
<copy>` is green on all seven checks, and the matrix shows wave 3 at
`9 registered`. `gates/selftest.sh` is red on exactly one line —
`registry: every script under tests/ is named by a row (unreferenced:
nvim-colorscheme.sh)` — which the cell closes.
