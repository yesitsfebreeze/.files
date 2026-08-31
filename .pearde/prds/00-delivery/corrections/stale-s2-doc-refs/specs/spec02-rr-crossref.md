# spec02 — repoint the `rr` cross-reference from R4 to R3

One-line fix in the deploy-mechanism PRD's Allocation list. It says `rr`
moved to the aliases node as its R4; there it is **R3**
([`04-shell/02`](../../../../04-shell/02-aliases-utilities/prd.md): `**R3** —
**Dotfiles sync.** rr → chezmoi update --force`). R4 is a deliberate gap —
`bb`/`ba`'s retired number, kept open because the tree cites requirements by
number.

**Est:** 0.5h

**Footprint:** `prds/05-platform/01-deploy-mechanism/prd.md`

## Changes

In `prds/05-platform/01-deploy-mechanism/prd.md` (lines 51–52):

```
- moved out of this epic — R4 (`rr` = `chezmoi update --force`), now
  [`04-shell/02`(../../../../../../prds/00-delivery/corrections/04-shell/02-aliases-utilities/prd.md) R4
```

Change only the trailing citation `R4` → `R3`. The first `R4` names this
epic's own retired requirement number and is correct; it stays.

## Acceptance

- [x] The Allocation line ends `...aliases-utilities/prd.md) R3`. Ran
      2026-08-22: `rg -n 'aliases-utilities/prd\.md\) R3'
      prds/05-platform/01-deploy-mechanism/prd.md` matches line 52; the
      same grep for `) R4` exits 1.
- [x] `prds/04-shell/02-aliases-utilities/prd.md` still carries `rr` as
      **R3** and the R4-gap note — read, not edited. Ran 2026-08-22:
      `rg -n '\*\*R3\*\* — \*\*Dotfiles sync'` matches line 27; the file
      is untouched by this change.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
rg -n 'aliases-utilities/prd\.md\) R3' prds/05-platform/01-deploy-mechanism/prd.md
rg -n 'aliases-utilities/prd\.md\) R4' prds/05-platform/01-deploy-mechanism/prd.md && exit 1
rg -n '\*\*R3\*\* — \*\*Dotfiles sync' prds/04-shell/02-aliases-utilities/prd.md
```
