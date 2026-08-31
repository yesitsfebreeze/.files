# spec05 — record W0.4f R3 as already discharged

Est: **0.2h**

## Files touched
- `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/prd.md`
  (this ticket's own node; `## Notes` section only — **not** frontmatter)

## Goal

W0.4f R3 asks to reconcile "requirement 7 also notes `fzf` is required whether
or not it is wanted" with the fzf decision. **It was discharged before this
ticket was analysed**, and the record should say so rather than the box being
ticked as if this ticket did it.

Evidence to write down:

- The phrase existed in exactly one file in the tree,
  `05-platform/02-package-provisioning/packages-installer/prd.md` — the
  grandchild that took R7 in the split, not either of W0.4f's originally
  declared files.
- `decisions/fzf` landed 2026-08-21 and its implementer replaced the
  parenthetical in place. R7 now reads that fzf is in the set as `zi`'s
  dependency and is "an accepted, documented exception to `04-shell`'s 'tv
  owns every picker screen'", linking `decisions/fzf` and backlog decision 3.
- Neither of W0.4f's two declared footprint files contains the string `fzf`
  at all, so there was never anything for this ticket to reconcile in them.

Add a `## Notes` entry saying that, so the `[x]` on R3 is a true record with
its proof attached rather than optimism (AGENTS.md: "a `[x]` you did not prove
is not optimism, it is a false record that outlives you").

## Acceptance
- [x] The node records R3 as already discharged, naming
      `packages-installer/prd.md` as where the reconciliation landed and
      `decisions/fzf` as what discharged it.
- [x] If the old "whether or not it is wanted" wording is quoted, it is
      clearly marked as gone.
- [x] Frontmatter is unchanged.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check05.sh`
      exits 0.

**Proven RED 2026-08-21**: check05 exits 1 with 4 failures — no discharge
record, no reference to `packages-installer`, no `decisions/fzf` citation.

verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check05.sh`
