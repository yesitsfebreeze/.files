---
state: open
priority: 15
est:
mode: afk
needs:
verify: "bash gates/tree-links.sh"
origin: derived
---

# The inventory says lualine's `auto` theme *errors* on base16; it paints the
# wrong palette instead

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `docs/capabilities-nvim.md:177-179` records the lualine constraint as
`auto` **erroring** when base16 is absent. E.13's analyst measured what
actually happens on lualine `221ce6b2` with tinted-nvim `a1f4cd34`, and it is
worse:

`auto.lua` collapses `base16-*` to the bundled `base16` theme, which falls
through three steps. `setup_base16_vim()` needs `vim.g.base16_gui00` or (since
PR #1352) `vim.g.tinted_gui00` — and **tinted-nvim sets zero `vim.g` keys**
matching either. `setup_base16_nvim()` needs the absent `nvim-base16`. Then
`setup_default()`: a **hardcoded Tomorrow-Night palette**. The run exits 0 and
paints `#81a2be` / `#b5bd68` / `#b294bb` / `#de935f` on `#282a2e`, with
`command` collapsed onto `normal`. The only signal is a deferred WARN at ~2 s
and `:LualineNotices` appearing.

**The constraint is real; only its mechanism is wrong.** That is precisely the
failure mode [`AGENTS.md`](../../../../AGENTS.md) warns about — it makes
carrying constraints *with* their reason the point, and an over-claimed reason
invites the opposite error. A reader who tries `auto`, sees no error, and
concludes the explicit theme is unnecessary would ship a statusline painted in
a scheme nothing else in the environment uses, and `tinty apply` would not
move it.

Same class as
[`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md) and
[`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md): a recorded
"why" whose stated mechanism is broader or simply different from what
reproduces. Three instances now.

## Requirements
- [ ] **R1** — The inventory entry states the measured behaviour: `auto`
      resolves, exits 0, and paints a hardcoded Tomorrow-Night fallback,
      with the three-step fall-through named and the two `vim.g` prefixes
      tinted-nvim does **not** set. The observable signal — a deferred WARN
      and `:LualineNotices` — is part of the reason, because it is the only
      thing a user would notice.
- [ ] **R2** — The entry's complexity and usefulness numbers are re-read and
      left alone unless the correction genuinely changes them. It almost
      certainly does not: the workaround is the same explicit theme either
      way. If they do change, make the argument explicitly.
- [ ] **R3** — **Census `capabilities-nvim.md` for other claims of this
      shape** — a stated failure mode that has not been run since the
      version pairing moved. Report each with what it claims, what
      reproduces, and how you measured. This file was written against a
      lualine and a tinted-nvim that have both moved since.
- [ ] **R4** — [`03-editor/13-statusline`](../../../03-editor/13-statusline/prd.md)
      R3 already carries the corrected mechanism, written by the
      orchestrator. Read it rather than re-deriving, and keep the two texts
      in agreement — if they disagree after this edit, the PRD is the one
      that was verified against a running editor.

## Acceptance
- [ ] The corrected entry is quoted beside the measurement that justifies it,
      including the four fallback hex values and the two absent `vim.g`
      prefixes.
- [ ] The R3 census is in the report, one verdict per claim.
- [ ] `bash gates/tree-links.sh` Tier A stays at 0 broken, asserted as a
      **delta** — the tree is written by several lanes and an absolute count
      is stale before it is read. That lesson cost two nodes already.

## Out of scope
- Changing what theme the statusline uses. That is
  [`03-editor/13-statusline`](../../../03-editor/13-statusline/prd.md) R5's
  and it is settled.
- Filing lualine's silent fallback upstream.
