---
state: done
claim:
priority: 30
est: 3.5h
task: S.9
mode: afk
needs:
  - 00-delivery/decisions/tinty
  - 04-shell/01-core-config
verify: "bash tests/theme-switcher.sh"
---

# Theme switcher

Parent: [Shell epic](../prd.md) · C 8 · U 5 · source: "Theme switcher (tinty +
television)" in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: the shell half of the palette that
[`decisions/tinty`](../../00-delivery/decisions/tinty/prd.md) just decided to
keep. `tinty` owns the palette and every other surface inherits it — but the
*switching* lives in nushell's `theme.nu`, and until now no node owned it.

**Created 2026-08-21 by the orchestrator**, from a finding by `decisions/tinty`'s
analyst. *Rating corrected the same day, also on that analyst's finding: the
header first read `C 5 · U 7`, invented rather than read. The inventory entry
is **C 8 / U 5** — ratio −3, near the bottom of the sort — and a `SIMPLIFY`
node inherits its entry's rating verbatim (the precedent is
[`08-claude-launchers`](../08-claude-launchers/prd.md), which sources a
`SIMPLIFY` entry rated 7/6 and carries `C 7 · U 6`). The reduction is expressed
in Requirements and Out of scope, never by re-scoring the header. The human
overrode the **marker**, not the measurements: the numbers were never wrong,
the membership was.* The finding itself: withdrawing tinty's `DEFER` turns the theme switcher from deferred
work into **missing** work. It was rated in the inventory and then fell through
the gap between "cosmetic, revisit later" and "infrastructure, keep" — with no
node, it would have vanished behind a decision to retain it. This node exists
so that cannot happen. Its requirements are a starting point written from the
inventory and the tinty decision, not a verified spec: **the analyst must check
every one against live `~/.config/nushell/theme.nu` before speccing**, per the
working contract's "verify against the live config, always".

## Requirements
- [x] **R1** — `tinty apply <scheme>` is the single funnel that changes the
      palette. Nothing else writes the scheme, so every reader stays coherent.
      *(2026-08-22: every apply site in `theme.nu` is `^tinty apply` and the
      module writes only its slot files — in gate `--module` the stubbed
      tinty's log is the only writer of `current_scheme` across every
      scenario. `bash tests/theme-switcher.sh --module` rc=0.)*
- [x] **R2** — A/B scheme slots with a toggle between them (`_theme_toggle` in
      the live config), so switching between a light and a dark scheme is one
      keystroke rather than a picker round trip. *(Implemented A/B per
      spec01's reconciliation — slots, not light/dark semantics. Gate:
      round-trip toggle, apply-before-pointer with a failing counterfactual,
      drift adoption, no-op skip all PASS.)*
- [~] **R3** — A television-backed scheme picker, honouring the epic invariant
      that tv owns every picker screen. See
      [`04-television`](../04-television/prd.md). *(The `theme` channel, its
      preview and the `tv theme` dispatch ship and pass gate `--preview`
      (template render, one-OSC-11 preview, no apply while browsing); the
      interactive tv screen itself needs a deployed config to drive, so this
      is met against fixtures, not a live round trip.)*
- [x] **R4** — The tinted-shell palette re-assert in `config.nu` is kept and
      is this node's responsibility to keep working; it is S.1 **R10**'s
      counterpart. It is not orphaned — that was the premise the decision
      overturned. *(Untouched by this node's anchor edit;
      `bash tests/nushell-core.sh --tree` EXIT=0 on 2026-08-22, S3.17 checks
      included, and the THEME source line lands after it per R10(e).)*
- [x] **R5** — The F6 binding that fronts the switcher is **out of this node** —
      it belongs to
      [`w0-2-terminal-respec`](../../00-delivery/corrections/w0-2-terminal-respec/prd.md)
      R5. This node owns the command; the terminal owns the key. *(This node
      ships no keybinding; its half of the contract — `theme.nu` parses
      standalone under `nu -n` and exports `_theme_toggle` for the terminal's
      out-of-band invocation — is gate-proven.)*
- [x] **R6** — Every command and keybinding this node adds carries a `help`
      manual entry in the same change, or `help --check` reports it
      undocumented and exits non-zero. See
      [`06-help`](../../06-help/prd.md). *(`theme`, `theme toggle`,
      `theme slots` entries in `shell.nuon` with reviewed use/why rows;
      `nu tests/help-content-model.nu` prints `ok`, exit 0, 2026-08-22.)*

## Acceptance
- [x] Requirements are reconciled against live `~/.config/nushell/theme.nu`
      before any of them is implemented, and any that the live config
      contradicts is corrected rather than implemented as written. *(Done at
      spec time, 2026-08-22 — spec01's reconciliation section records the
      verdicts (A/B not light/dark, apply-before-pointer, the `SIMPLIFY`
      drops) and the implementation follows them.)*
- [~] Switching schemes moves WezTerm, and the shell's own prompt colors, with
      no restart. *(The whole chain ships and is proven against fixtures:
      config.toml's hook runs tinted-shell's OSC item then wezterm-colors.sh,
      which writes the colors.lua WezTerm watches — gate `--hook` PASS. The
      no-restart retint on a real screen needs the deployed machine; not
      executable from this repo without writing the live config.)*
- [~] `help` lists the switcher's commands and its keybinding. *(The entries
      exist and F6 is named in `theme toggle`'s use — pre-S.5 check
      `open home/dot_config/nushell/help/shell.nuon | where cmd == "theme"`
      returns one row. The `help` command itself is 06-help work and is not
      built yet.)*

## Out of scope

This is what the `SIMPLIFY` verdict drops. The palette-owning core is minimal
base; the rest of the C 8 surface is not.

- The **background-override ladder** and its **R/G/B tuner**. The background
  override also overlaps
  [`decisions/wallpaper-opacity`](../../00-delivery/decisions/wallpaper-opacity/prd.md),
  which dropped wallpaper cycling and the opacity toggle on 2026-08-21.
- The **liked and recency sets** over the scheme catalog.
- The static swatch preview in the picker, if it proves to cost more than it
  returns; the live OSC-11 background retint is the part that earns its place.
- Neovim syntax-color inheritance. `tinty apply` moves the editor background
  but not its syntax colors; that boundary is specified by E.5 R7, not here.
- The F6 keybinding itself (R5).
