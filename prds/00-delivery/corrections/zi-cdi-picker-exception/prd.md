---
state: done
priority: 8
complexity: 8
blast-radius: low
commit: 9d3f424
est:
mode: afk
claim: 
needs:
  - 04-shell/04-television
verify: "nu tests/help-content-model.nu"
origin: derived
from: 04-shell/03-zoxide
---

# The manual names `zi` as the fzf exception and forgets `cdi`

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: two findings from the `cdi-manual-source` reader
(`implementer-cdi-r1`, 2026-08-23), both the same defect seen from two sides:
the corpus treats `zi` as the sole fzf exception when
[`04-shell/03-zoxide`](../../../04-shell/03-zoxide/prd.md) R2 names the
**pair** `zi`/`cdi`.

1. **The `cdi` entry names no fzf exception of its own.** A reader landing on
   `cdi` sees "the same picker" and has to follow `also` to `zi`
   (`shell.nuon:30`) to learn the picker is fzf rather than television. This
   is entry completeness, not prose truth — nothing in `cdi` is false.
2. **The `idioms` nit at `use-review.nuon:156` still stands.**
   `shell.nuon:395` names only `zi` as the exception, and `:398`'s `also`
   omits `cdi`, while `tv channel`'s `why` (`shell.nuon:194`) *does* name
   both. So the corpus is internally inconsistent about the same fact.

Why it matters more than a wording nit: [`AGENTS.md`](../../../../AGENTS.md)
makes the manual the thing an agent reads *before* acting, and the exact
failure mode it names is "reaching for `fzf` when television is what is
installed". An entry that is silent about which picker it opens is the one
place that lesson has to land. The two finders are deliberate — television in
the shell, telescope in the editor — and `zi`/`cdi` are the documented
exception to that; an exception recorded in only half the places a reader
looks is an exception that will be missed.

Deps on [`04-shell/04-television`](../../../04-shell/04-television/prd.md)
because the wording has to match which surfaces television actually owns once
that node lands, and it is currently `failed`.

## Requirements
- [ ] **R1** — The `cdi` entry states which picker it opens, so a reader
      landing on it needs no `also` hop to learn it is fzf and not
      television.
- [ ] **R2** — The `idioms` entry (`shell.nuon:395`) and its `also`
      (`:398`) name the `zi`/`cdi` pair, matching `04-shell/03-zoxide` R2
      and `tv channel`'s `why` at `:194`.
- [ ] **R3** — Every edited entry re-digests through the gate's own helper,
      with a reader-reviewer distinct from the author, per the corpus's
      review ritual — the same shape
      [`cdi-manual-source`](../cdi-manual-source/prd.md) R2 established. The
      `use-review.nuon:156` note that recorded this nit is retired in the
      same change, not left standing beside its own fix.
- [ ] **R4** — **Census before editing, report after.** Find every entry
      whose `use` or `why` implies a picker without naming it. Two were
      found by accident, from a node about something else; the question is
      how many there are. Gaps outside R1 and R2 are reported, not fixed
      here.

## Acceptance
- [ ] `nu tests/help-content-model.nu` passes, output quoted.
- [ ] `rg -n 'fzf' home/dot_config/nushell/help/` shows the exception named
      at `cdi`, at `zi`, and in `idioms`, quoted.
- [ ] The R4 census is in the report as a list, with a verdict per entry.
- [ ] `use-review.nuon` carries no note describing a defect that the same
      commit fixed — checked by reading the notes this change touches.

## Out of scope
- Changing which picker `zi`/`cdi` use. That is
  [`decisions/fzf`](../../decisions/fzf/prd.md), settled; this node
  documents the settled answer.
- Any picker-silent entry the R4 census turns up beyond the two named.
