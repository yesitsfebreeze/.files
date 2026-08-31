---
state: done
priority: 26
est: 0.5h
mode: hitl
needs:
  - 00-delivery/decisions/fzf
verify: ""
origin: requested
---

# Decision: fzf as the model picker for `cll`

Purpose: A second picker outside tv. [`04-shell`](../../../04-shell/prd.md) I3
allows exactly one fzf exception — `zoxide query --interactive` behind
`zi`/`cdi` — and says in the same breath that it is **"an exception and not a
precedent: a second picker outside tv is a new decision, not an appeal to this
one."** This node is that new decision, so the second exception is recorded
where the rule is rather than inferred from the first.

**Decided 2026-08-25 (user).** `cll`'s model picker is fzf. I3 is amended to
name two exceptions instead of one.

## What it settles

- The picker for [`04-shell/10-litellm-launcher`](../../../04-shell/10-litellm-launcher/prd.md)
  is `fzf`, not a tv cable channel and not nushell's `input list --fuzzy`.
- The first draft of that node **did** use `input list --fuzzy`, chosen to
  stay inside I3. It was replaced on the user's instruction; the reason is
  capability, not preference. The catalogue is ~80 rows across six providers
  and wants three things at once: group headers per provider, a per-row
  provider column that survives filtering, and dim secondary text for the
  fallback chain. fzf does that with `--ansi`, `--with-nth`, `--nth` and
  `--accept-nth`. `input list` renders records as an aligned table but has no
  ANSI pass-through, so the group/detail distinction collapses to one weight.
- fzf is already in the required package set
  ([P.2](../../../05-platform/02-package-provisioning/packages-installer/prd.md)
  R7) as `zi`'s dependency, so this adds no dependency — only a second caller.
- It remains **not a precedent**. A third picker outside tv is another new
  decision.

## Acceptance

- [x] I3 names two exceptions, with this node linked as the second.
- [x] The gate asserts the picker is fzf and that the flags survive:
      `bash tests/shell-litellm.sh --tree` exits 0.

## Out of scope

- Re-opening the `zi`/`cdi` exception ([`decisions/fzf`](../fzf/prd.md)).
- Migrating tv's existing picker screens to fzf. tv still owns those.
