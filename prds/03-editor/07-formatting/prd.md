---
state: done
claim:
priority: 8
est: 1.75h
task: E.11
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
footprint:
  - home/dot_config/nvim/lua/plugins/conform.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
  - install.sh
  - tests/provisioning.sh
  - tests/nvim-formatting.sh
verify: "bash tests/nvim-formatting.sh"
needs:
---

# Format on save (conform.nvim)

Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Format on save
(conform.nvim)" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: One formatting owner: real formatters where they exist, LSP as
fallback, on save and on demand.

## Requirements
- [x] **R1** — **Plugin.** `stevearc/conform.nvim`, lazy on `BufWritePre` +
      the `ConformInfo` command.
- [x] **R2** — **Formatters by filetype.** lua → stylua, rust → rustfmt,
      python → black, markdown → prettier. **`markdown.mdx` is not among
      them:** answered 2026-08-23 by the user (see `## Answers` Q2) — no
      buffer in this config can hold that filetype, so the key would be dead
      configuration. The four binaries are provisioned by this node, per Q1.
- [x] **R3** — **Markdown intent.** prettier is chosen to align table pipes
      and normalize lists; prose must stay unwrapped (`proseWrap` defaults to
      `preserve`) — these PRD files are hand-wrapped and reflowing them would
      churn diffs.
- [x] **R4** — **On save.** `format_on_save` with a 500 ms timeout and
      `lsp_format = "fallback"`.

      **`"fallback"` covers two cases, not one.** Corrected 2026-08-23 by the
      orchestrator: this requirement said "a filetype without a listed
      formatter still gets formatted by its language server", which is half
      the behaviour. Measured — it also fires for a **listed formatter whose
      binary is not executable**, and when it does, the language server
      formats the buffer with *nothing* indicating that `stylua` never ran.
      Proved with an in-process fake LSP (`vim.lsp.start` with a `cmd`
      function advertising `documentFormattingProvider`), so the check is
      hermetic and needs no mason binary. That second case is the one that
      matters here, because no formatter this node names is currently
      installed — see the Questions below.

      The rest of the failure surface, all measured and all exiting 0 with
      the write succeeding: formatter absent and no LSP → `Formatters
      unavailable for <ft> file` at WARN on stderr, **deduped once per
      filetype per session**, so the second save of a session is silent;
      formatter present but failing → `Formatter failed. See :ConformInfo`
      at ERROR; timeout → `Formatter '<name>' timeout` at WARN with an
      unformatted write; a filetype with no configured formatter and no LSP
      → completely silent.
- [x] **R6** — **The file is `lua/plugins/conform.lua`.** Added 2026-08-23 by
      the orchestrator: this node never named its target file, while the
      sibling correction that fixed the same omission for
      [`12-small-plugins`](../12-small-plugins/prd.md) named
      `gitsigns.lua` / `which-key.lua` / `autopairs.lua` explicitly. The
      epic's [I8](../prd.md) says "named for the plugin" and the landed
      siblings are concern-named (`completion.lua` for blink.cmp,
      `colorscheme.lua` for tinted-nvim), so the invariant's wording and the
      practice disagree; `conform.lua` satisfies both readings. The
      disagreement itself is filed as
      [`i8-naming-wording`](../../00-delivery/corrections/i8-naming-wording/prd.md).
- [x] **R5** — **Manual.** `<leader>cf` formats asynchronously with the same
      LSP fallback.

## Acceptance
- [x] Save a `.lua` file: stylua formatting applied within the timeout.
- [x] Save a markdown file with a ragged table: pipes align, paragraph line
      breaks are untouched.
- [x] Save a filetype with no configured formatter but an active LSP: the LSP
      formats it.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Questions

Analyst round, 2026-08-23. Every fact below was measured in a seeded
scratch XDG root (`HOME` and all four XDG dirs pinned to it, plugins copied
from the live clones, offline) on nvim 0.12.4 against conform.nvim
`016802de402556da54c36bd7359b441266b01cdd`. The wiring itself is sound —
first-save formatting, the 500 ms timeout, the `<leader>cf` async path and
the LSP fallback all behave as R1–R5 describe. Both questions below are
about what the config points *at*.

Question *Q1*: **Not one formatter this PRD names is installed or
provisioned. Install them, or cut R2 down to what the machine has?**

Measured: `stylua`, `black` and `prettier` are absent from PATH. `rustfmt`
resolves only to the rustup shim in `~/.cargo/bin`. None of the four is in
`install.sh`'s `PKGS` — that list is the required set plus `just`, `jq`,
`gnupg`, `pass` and `git-delta`, each added by the node that needed it.
From Homebrew's own offline formula-name cache: `stylua`, `prettier` and
`black` are formulas; `rustfmt` is not, it ships with `rust` or rustup, and
`rust` is not in `PKGS` either.

What that means today, measured end to end. Save a lua file with `stylua`
missing and no language server attached: the write **succeeds**, the file
is written unchanged, and conform notifies `Formatters unavailable for lua
file` at WARN — **once per filetype per session**, so the second lua save
in the same session is completely silent. Exit status is 0 either way; the
save never fails. With a language server attached, `lsp_format =
"fallback"` routes that same save to the server, so the buffer *is*
formatted — by the LSP, with nothing to indicate stylua never ran. A
formatter that is present but fails is louder: `Formatter failed. See
:ConformInfo for details` at ERROR, and the write still succeeds.

The manual already promises the opposite. The `<leader>cf` entry in
`home/dot_config/nushell/help/nvim.nuon` reads "saving formats already —
stylua for lua, rustfmt for rust, black for python, prettier for
markdown". That sentence is false on this machine, and two of the three
acceptance boxes above ("stylua formatting applied", "pipes align") cannot
close against anything real.

Option A — provision them. Add `stylua`, `prettier`, `black` and `rust` to
`install.sh`'s `PKGS`. Cost: four more formulas in the unattended install,
one pulling node and one pulling python. `install.sh` belongs to
[`packages-installer`](../../05-platform/02-package-provisioning/packages-installer/prd.md),
so the edit is a carve-out. One consequence to accept: `init.lua` maps
`.jd` to `markdown`, and this user has many `.jd` files, so installing
prettier means every `.jd` save is reformatted by it. The repo itself
carries no `.prettierrc`, so prettier's defaults would also apply to every
hand-wrapped `prds/**/prd.md` saved from nvim — `proseWrap` defaults to
`preserve` so the wrapping survives, but list and table normalization
would not be opt-in. Unmeasured, because prettier is not installed.

Option B — cut R2 to `rustfmt` plus the LSP fallback, drop the three
missing formatters from `formatters_by_ft`, and rewrite the help entry to
match. Cost: on-save markdown table alignment goes away — the live
realignment in [`15-markdown-tables`](../15-markdown-tables/prd.md) is
what remains — and R3 loses its subject entirely.

Option C — port R2 as written and provision nothing. The config then names
four formatters of which at most one runs, this node's acceptance closes
only against stub binaries, and the help entry stays false.

Recommendation **A**. `.prettierrc` and `pyproject.toml` both exist in this
user's project tree, so prettier and black are wanted in real work. The
argument against C is the silence: a configured-but-absent formatter yields
either a once-per-session warning or an invisible substitution by the
language server, and neither is a state to ship deliberately.

Question *Q2*: **`["markdown.mdx"]` is dead configuration. Register the
extension, or drop the key?**

`markdown.mdx` is not a filetype any buffer in this config can hold.
Measured: `vim.filetype.match({ filename = "a.mdx" })` returns nothing on
nvim 0.12.4, opening a `.mdx` file leaves `filetype` empty, and nothing in
`init.lua` or any plugin spec registers the extension — `init.lua`
registers `.jd` → `markdown` and nothing else. There are no `.mdx` files
anywhere under `~/dev`. The same dead branch sits in
[`15-markdown-tables`](../15-markdown-tables/prd.md)'s
`ft = { "markdown", "markdown.mdx" }`.

Option A — drop the `["markdown.mdx"]` entry from R2. It names a filetype
it can never match.

Option B — add `vim.filetype.add({ extension = { mdx = "markdown.mdx" } })`
so the entry has a subject. That is a new capability (MDX support) and an
edit to `init.lua`, which belongs to
[`01-options`](../01-options/prd.md).

Recommendation **A**, and the same drop for `15-markdown-tables`. `.jd` is
the extension this environment actually uses, and it already routes to
prettier through the `markdown` key.

## Answers

Answered 2026-08-23 by the user, in the round the analyst asked.

- **Q1 — route A: provision the formatters.** `stylua`, `prettier`, `black`
  and `rust` (for `rustfmt`, which is not a formula of its own) join
  `install.sh`'s `PKGS`. This is a deliberate **carve-out** into
  [`packages-installer`](../../05-platform/02-package-provisioning/packages-installer/prd.md)'s
  file, authorised for this node only and recorded in this node's
  `footprint:` so nothing else edits `install.sh` in the same wave. The
  reason for A over C is the silence, measured: a configured-but-absent
  formatter either warns **once per filetype per session** or is invisibly
  substituted by the language server, and neither is a state to ship
  deliberately. Two consequences accepted with the answer: prettier will
  reformat every `.jd` save (`init.lua` maps `.jd` to `markdown`, and this
  user has many), and with no `.prettierrc` in the repo prettier's defaults
  apply to hand-wrapped `prds/**/prd.md` files saved from nvim —
  `proseWrap` defaults to `preserve`, so the wrapping survives, but list and
  table normalisation is not opt-in. Both are unmeasured because prettier is
  not installed yet; measure them once it is, and report rather than
  quietly re-tune.
- **Q2 — drop `["markdown.mdx"]`.** It names a filetype no buffer in this
  config can hold: `vim.filetype.match({ filename = "a.mdx" })` returns
  nothing on nvim 0.12.4, nothing registers the extension, and there are no
  `.mdx` files under `~/dev`. `.jd` is the extension this environment uses
  and it already routes to prettier through the `markdown` key. The same
  drop was ordered for
  [`15-markdown-tables`](../15-markdown-tables/prd.md) and is recorded in
  that node's body; **registering MDX support was declined**, so no edit to
  [`01-options`](../01-options/prd.md)'s `init.lua` follows from this.

## Blocked — one box, on another lane's census entry

Written 2026-08-23T22:30Z by the orchestrator. This node's own work is landed
and proven: `bash tests/nvim-formatting.sh` exits 0 at **137 PASS / 0 FAIL**
(tree 57, headless 107, formatters 51), and `bash tests/provisioning.sh` exits
0 at **115 PASS / 0 FAIL** after the `PROV_BINS` half of the carve-out landed.
The four formatters are installed and real: `stylua 2.5.2`, `prettier 3.9.6`,
`black 26.5.1`, and `rustfmt 1.8.0-stable` from the rustup shim — which is why
`rust` was correctly **not** installed, since `install.sh`'s loop guards on the
binary.

**The open box:** `bash tests/nvim-options.sh` exits 1, and it is not this
node's. The tree carries an untracked `lua/config/keymaps.lua` from the
in-flight [`02-keymaps`](../02-keymaps/prd.md) lane, and that gate's census
string does not name it. Proved foreign by construction, not argued: a copy of
the nvim tree **minus** `keymaps.lua` yields a `find | sort` string
byte-identical to the census line, this node's `conform.lua` included. That
lane has been sent its own census entry; `needs:` names it, and this box
closes when it lands. Nothing here is re-run.

**The carve-out grew by one file, and the frontmatter now says so.**
`tests/provisioning.sh` joined the footprint on this transition. It had to:
that gate's `PROV_BINS` is keyed on the **binary**, not the package, so R8's
straggler loop (`have "${p##*=}" && continue`) emits a per-package
`brew install` line for every package whose binary is missing from the list —
four new formulas, four lines, `shape/prov` red on an already-provisioned
machine. The analyst checked the two subset-shaped checks in that gate and
missed this third one; the subset reasoning was right, and `packages/retry`
widened itself from 20 to 24 exactly as predicted. Recorded because the
general rule is worth more than the fix: **a poison list keyed on binaries
must grow whenever `PKGS` does**, and `rust=rustfmt` means the name that goes
in is `rustfmt`.

**One spec box was amended rather than closed or failed.** spec02 required
that seeding `mason/registries` stop the `ENOTCONN` abort. It does not — 5 of
5 seeded runs still aborted — so the box could not be closed by any correct
implementation. The amendment is in the spec, the bug is filed as
[`offline-launch-eats-first-save`](../../00-delivery/corrections/offline-launch-eats-first-save/prd.md),
and what the gate does instead is stronger than what was asked: it stages the
probe root without `lua/plugins/lsp.lua`, the only file that loads mason, and
proves the isolation with a three-arm race control instead of assuming it.

**Still owed by the orchestrator:** the `gates/waves.tsv` wave-4 cell entry
(`external bash tests/nvim-formatting.sh --tree | … --headless | …
--formatters`, the `external ` prefix mattering because `gates/selftest.sh:300`
exempts external commands from the `--selftest` contract). `waves.tsv` is held
by the `02-keymaps` lane, so it lands with the same event this node waits on.
The two `gates/manual/wave4.md` verdict rows for the accepted consequences are
already written.

## Unblocked and closed 2026-08-24 by the orchestrator

`done`. The event `needs:` named has landed: `03-editor/02-keymaps` added its
own census entry, and the last open box closed against checks the orchestrator
ran rather than inherited:

```
bash tests/nvim-options.sh     → rc 0, 74 PASS / 0 FAIL
bash tests/nvim-formatting.sh  → rc 0, 137 PASS / 0 FAIL
```

Only the open box was re-checked, plus this node's own gate to prove the
census entry did not disturb it. Nothing else was re-run.

The `gates/waves.tsv` wave-4 cell now carries all three stages —
`external bash tests/nvim-formatting.sh --tree | … --headless | … --formatters`
— written by the orchestrator once the keymaps lane released the file, with the
`external ` prefix that keeps `gates/selftest.sh:300` from holding an
externally-owned script to the `--selftest` contract.
`bash gates/wave-status.sh --validate` exits 0 with `unreferenced: none`.
