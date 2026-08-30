---
complexity: 20
footprint:
  - home/dot_config/nushell/help-check.nu
  - tests/help-drift-check.sh
---

# spec01 — every live handle classified, by rule where a list would rot

R6. 217 live Neovim maps, 123 nushell handles and 142 tmux keys, against 164
documented targets. The gap is classified **explicitly** — and mostly by
RULE, because a list of 150 lhs values is a list nobody can maintain and
nobody can disagree with in one place.

## The rules, and where each is written

In `help-check.nu`, beside the code that applies them:

1. **Neovim ships it.** Measured, not listed: a second `nvim --clean`
   spawn dumps the maps a Neovim with no config and no plugins has, and that
   set is subtracted. 123 of the 217. A hand-kept list would have called the
   `[`/`]` family, `gc`, `gcc`, `gx`, the `gr*` LSP maps and the snippet
   `<Tab>` gaps in our manual — every one of them arrived in Neovim 0.10 or
   0.11.
2. **No `desc` at all** — a plugin internal or a default that never carried
   one. Safe here because this config's own maps all set `desc`.
3. **`desc` equals a documented entry's title** — the same gesture in another
   mode. The manual documents a gesture once and names the modes in prose.
4. **`v` is not a mode, it is two.** A map created for mode `v` comes back
   under both `x` and `s`, so the six shift-select maps appeared three times
   each and twelve of them read as gaps. The expansion is in the checker, not
   the corpus: the manual should say what a person presses.

## The `_`-private convention, written down

A `_`-prefixed nushell command is private by this repo's convention — 99 of
the undocumented 120 were exactly that. The rule lives in one def,
`_hc_is_private`, so a reader can disagree with it in one place.

## What is listed, because a rule would be a stretch

`HC_ALLOW` holds 22 handles in three classes, each with its reason: help.nu's
two delegation aliases; std/help's eight subcommands (epic I2 says delegate,
never shadow — documenting them would be the shadow) plus four machinery
handles (`decorate-ls`, `tv_finder`, `tv_history_local`, `tv_remote`, each
reachable only from something that IS documented); and **nushell's own eight
keybindings**, measured — `nu -n`, with no configuration at all, reports
exactly those.

## What the classification exposed rather than hid

Seven real gaps, all closed rather than allowlisted: `cll`, `llm`,
`llm quota` and `llm regen` gained manual entries; `mkcd` and `quicklist`
gained the command target beside their concept and keybinding ones; and
`capsule recent` is now named by the key that runs it.

## Acceptance

- [x] `help --check` reports **undocumented: 0** over all four surfaces.
- [x] Every rule is written where it is applied, with its measurement.
- [x] The allowlist is 22 entries, not 281 — the rest is classified by rule.
- [x] `bash tests/help-drift-check.sh` exits 0 (36 PASS).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/help-drift-check.sh
```

Run 2026-08-30: rc 0, report reads `documented 164 · prose-only 15 ·
allowlisted 22 · live nvim maps 217 of which 123 are Neovim's own · live
buffer maps 5 · live tmux keys 142 · live wezterm keys 86`, and
`help --check: clean`.
