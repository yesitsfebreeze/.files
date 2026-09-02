# spec03 — M-14: `source` is a real field; put it in the schema

est: 0.3h

## Goal

M-14 says `06-help/02` R4 and `06-help/03` R4 both render an entry's "source
PRD", a field the content model's schema does not define. Half of that is
still true and half of it has been overtaken: the field **exists, is
required, and is gated** — it is `01-content-model`'s R2 schema list that has
not caught up. Add it, so the two renderers stop citing an undefined field.

This is reconciliation with what H.1 landed, not a re-opening of it. Do not
touch R2's demotion notes, the `use` sub-box, R5's amendments, the `Findings`
section or the `Closing note` — nothing in this spec disagrees with any of
them.

## Files touched

- `.mi/prds/06-help/01-content-model/prd.md` (only this file)

## What was measured (2026-08-21, current HEAD)

- `tests/help-content-model.nu:23` — `const REQUIRED = ["title" "use" "topic"
  "mode" "verify" "source"]`. `source` is a **required** field, not optional.
- `tests/help-content-model.nu:722-733` — the gate resolves each `source`
  against the repo, accepting either node form (`<node>/prd.md`) or the
  pre-board flat forms, and errors with ``source `…` exists in neither node
  nor flat form`` otherwise.
- `tests/help-content-model.nu:159` — `source: "string"` in `FIELD_SHAPES`, so
  it is shape-checked like every other string field.
- `tests/help-content-model.nu:414` — `use-digest` keys on `use` **and**
  `source` together, which is why `use-review.nuon` invalidates when an entry
  is re-pointed at a different PRD. `source` is therefore load-bearing for the
  `use` review record, not merely decorative.
- All 84 live entries carry one; the gate's "entries name a source that only
  exists in pre-board flat form" note did not print on the last run, so zero
  are still on the flat form.
- R2's schema list runs `key`/`cmd`, `title`, `use`, `topic`, `mode`, `also`,
  `why`, `verify` — and stops. `source` is absent.

## Edits

1. **R2 schema list.** Add one sub-box, placed after `verify` so the list
   ends on the two machine-facing fields:

   `- [x]` **`source`** — the PRD this entry is specified by, repo-root
   relative; required, and **the field the detail views render**
   ([`02`](../../../../../06-help/02-help-command/prd.md) R4,
   [`03`](../../../../../06-help/03-browser/prd.md) R4). Gated: it must be present, a string, and
   resolve against the repo.

   Mark it `[x]` and name the check that proves it — `nu
   tests/help-content-model.nu`, which is this node's own `verify` and was run
   green on 84 entries at close. This box is `[x]` on evidence, not optimism:
   the field is enforced today.
2. **Say why it also matters beyond rendering**, in one clause: `use-review`'s
   digest keys on the `use`/`source` pair, so re-pointing an entry at a
   different PRD invalidates the recorded reading. Without that sentence a
   later reader can mistake `source` for a display-only field and drop it.
3. **Add a dated amendment line** under R2 in the style the node already uses
   (`Amended 2026-08-21 (<session id>), …`) recording that the field was
   present in the data and the gate from H.1's close but missing from the
   written schema, and that M-14 is what caught it. Do not rewrite the
   existing notes.
4. Do not add `source` to any `.nuon` file, do not touch
   `tests/help-content-model.nu`, and do not touch
   `home/dot_config/nushell/help/*` — the spec03 of another ticket is
   implementing against those files right now.

## Acceptance

- [ ] R2's schema list carries a `source` sub-box, ticked `[x]`.
- [ ] The PRD states that `source` is what the detail views render, in the
      words "the field the detail views render", so `02` R4 and `03` R4 stop
      citing an undefined field.
- [ ] The gate still lists `source` in `REQUIRED` — the verify fails if a
      later change quietly drops it, so the PRD and the check cannot drift
      apart in either direction.
- [ ] No frontmatter field is changed, and `state: done` is left alone.
- [ ] Nothing under `home/dot_config/nushell/help/` is modified.

## verify

Proved RED against the current tree before being written here (exit 1: both
PRD clauses missing, the gate clause already passing). The check reads two
files on purpose — a PRD-only assertion would go green on a schema entry that
no longer matches the enforcement.

```
nu -n -c 'let t = (open --raw prds/06-help/01-content-model/prd.md | str replace -ar "\\s+" " "); let checks = [[want, phrase]; [true, "[x] `source` —"], [true, "the field the detail views render"]]; let bad = ($checks | where {|r| ($t | str contains $r.phrase) != $r.want}); if ($bad | is-empty) { print "ok" } else { print ($bad | to text); exit 1 }'
```


**Amended 2026-09-01**: the `g` clause read `tests/help-content-model.nu` for
the `REQUIRED = [...]` enforcement line. `tests/` was retired on 2026-08-31 by
the memo `tests-and-gates-retire-a-dev-setup-is-not-a-product`, so the clause
asserted against a file deleted by decision and the block was red on
`file_not_found`, not on the PRD drifting. The two PRD clauses stay; the
schema now has no mechanical enforcement to cross-check, which is the
retirement decision working as recorded, not a gap this spec may reopen.
