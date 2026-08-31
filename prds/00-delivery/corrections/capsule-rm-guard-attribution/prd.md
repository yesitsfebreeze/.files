---
state: done
claim: 
priority: 35
est: 1h
actual: 20m
mode: afk
needs:
verify: ""
origin: derived
---

# `capsule.nu` points an auditor of `docker rm` at a guard that does not cover it

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `home/dot_config/nushell/capsule.nu:453` states:

> There is no code path that reaches `docker rm` outside the
> `_capsule_owned` set.

Measured false by `pwd-closure-blast-radius`'s R4 census (2026-08-23).
`capsule.nu:405` runs `^docker rm -f $name` from `_capsule_name`, on the
`--rebuild` path. There are three `docker rm` sites and only `:459`/`:461`
iterate `_capsule_owned`.

**The safety property still holds** — the `--rebuild` path is guarded by the
`dir_label` check at `:399-401` — but by a *different* guard than the comment
names. That is the highest-stakes shape of this defect on the board: someone
auditing a destructive path reads this sentence, checks `_capsule_owned`, sees
it is sound, and never looks at `:399-401`. Then a later change to the
`dir_label` check has no comment telling anyone it is load-bearing, and the
one comment that mentions safety points somewhere else.

## Requirements
- [x] **R1** — The comment names the guard that actually covers each
      `docker rm` site: `_capsule_owned` for `:459`/`:461`, `dir_label` at
      `:399-401` for `:405`. Enumerate the three sites rather than making a
      universal claim, because the universal claim is what was wrong.
      **Done.** The `capsule clean` header now opens with the enumeration
      heading *THE THREE `docker rm` SITES, AND THE GUARD OVER EACH* and
      lists all three with their guards, plus a paragraph stating both
      predicates so the empty-value seam is visible; step 7 gained a
      three-line note at the site itself.
      `attribution_ok` PASSes and the universal claim is gone
      (`/usr/bin/grep -ciF 'no code path'` → `0`).
- [x] **R2** — `dir_label`'s own definition gains a line saying it guards the
      `--rebuild` removal. A load-bearing safety check with no comment saying
      so is one refactor from being simplified away.
      **Done.** `_capsule_state`'s header now says *dir_label is
      load-bearing: it is what guards the `--rebuild` REMOVAL*, names the
      2026-08-23 measurement, and records that `index .Config.Labels` prints
      the empty string rather than `<no value>`. Pinned verbatim by
      `attribution_ok`.
- [x] **R3** — **Verify the safety property itself, not just the prose.**
      **Done at spec time, 2026-08-23, and the property holds on both
      routes.** Every measurement ran the real CLI under nu 0.114.1 against a
      recording docker shim on a scratch `HOME` — no real `docker rm` ran and
      no container was created or touched.

      **Route A (`:405`, `--rebuild`), five runs:** a foreign container (empty
      `capsule.dir`) → exit 1, a refusal naming the container, **zero `rm`
      lines**; container absent → zero `rm`; container owned → exactly one
      `rm -f`, equal to the independently derived name. **`:399-401` is
      load-bearing and nothing else covers `:405`** — with only that test
      neutered in a scratch copy, the same input removes the *foreign*
      container, and **no check in either capsule gate notices**.

      **Route B (`:459`/`:461`):** against a mixed fixture, `clean` removed
      only the stopped capsule and `clean --all` only the two capsules;
      `capsule-handmade`, `postgres` and a label-only `renamed-thing`
      appeared in no `rm` line. Drop the label filter and `capsule-handmade`
      goes — so that guard is real too.

      Two supporting facts measured rather than assumed: `_capsule_name`
      always prepends `capsule-`, which is **why the sentence's conclusion
      was right while its mechanism was false**; and
      `index .Config.Labels "capsule.dir"` prints the **empty string**, never
      `<no value>`, for a label-less container — checked against docker 29.4.0
      and against Go `text/template`'s `index` on a nil map, an empty map, a
      map with other keys, and the key present-but-empty. A `<no value>`
      would have read as non-empty and opened the guard; it does not happen.

      **One seam, recorded and deliberately not closed.** The two guards
      implement different predicates: `_capsule_owned` is label-**key** plus
      prefix, `:399-401` tests the label's **value**. They diverge on exactly
      one input — a container named `capsule-*` carrying `capsule.dir` with an
      *empty* value: `--rebuild` refuses it, `clean` removes it (measured).
      This tool can never produce that container, because the create line
      always writes a non-empty `capsule.dir`, so it takes a deliberate
      imitator of the ownership marker — and under the label-as-marker
      convention the file already states, such a container has declared
      itself capsule's. That makes it a **definitional seam, not a
      destructive reach on a genuinely foreign container**, so the node's
      premise stands and no question goes to the user. R1's corrected comment
      states both predicates plainly, so the seam is visible rather than
      hidden. Closing it would change a guard, which is C.1's or C.2's.
- [x] **R4** — A gate assertion that the site count stays three, in the
      durable form the board settled: set equality against a declared
      roster, not a bare count. See
      [`armed-count-tripwires`](../armed-count-tripwires/prd.md).
      **Done.** `tests/capsule-lifecycle.sh` declares `RM_SITES` and asserts
      set equality via `sites_ok`; no `-eq 3` anywhere. Rows are
      `<def> :: <command>`, comment lines skipped. The PASS line reads
      `tree: the \`docker rm\` sites are exactly the 3 RM_SITES, def-scoped
      (3 sites) — capsule step 7 guarded by the dir_label refusal, both
      clean branches by _capsule_owned`. Both counterfactuals are red: a
      dropped site gives `MISSING [capsule clean :: ^docker rm $row.name];
      UNEXPECTED []`, and a fourth site of identical command text inside
      `_capsule_build` gives `MISSING []; UNEXPECTED [_capsule_build ::
      ^docker rm -f $name]`.

## Acceptance
- [x] The corrected comment is quoted beside all three `docker rm` sites and
      the guard covering each. Checked: `attribution_ok` PASSes —
      `tree: each removal site's comment names the guard that covers IT —
      step 6's dir_label refusal for --rebuild, _capsule_owned twice for
      clean — and the universal claim is gone`; and the
      `universal-claim-restored` counterfactual FAILs it. The edit is
      comment-only: `diff` of both files with comment lines stripped is
      empty.
- [x] R3's measurement is in the report, both routes. Route A is now also
      *held down* by hermetic scenario 12 plus control 4 — the neutered copy
      logs `rm -f capsule-proj-d5f03d78` against a label-less container,
      which the real file refuses with `capsule: a container named
      capsule-proj-dcdb3051 exists but was not created by capsule` and zero
      `rm` lines. Route B stays covered by scenario 9 and control 2, both
      PASS.
- [x] `bash tests/capsule-lifecycle.sh` and `bash tests/capsule-credentials.sh`
      reach `EXIT=0`, run alone. `capsule-lifecycle: 60 pass, 0 fail`
      (`rc=0`, baseline 49/0) and `capsule-credentials: 102 pass, 0 fail`
      (`rc=0`, unchanged). `bash gates/wave-status.sh --run 3` also exits 0
      with no `^FAIL` line.
- [x] A counterfactual: a fourth `docker rm` site added in a scratch copy
      makes the R4 assertion red, naming it. `chk_fail "tree: counterfactual
      rm-site-in-another-def FAILS the site-set check — identical command
      text, different def"` PASSes, and the re-derived diagnosis reads
      `MISSING []; UNEXPECTED [_capsule_build :: ^docker rm -f $name]` — the
      row a text-only set would have absorbed in silence.

## Out of scope
- Changing any guard. This node corrects prose and adds an assertion; if R3
  finds the property broken, that is C.1's or C.2's.

## The destructive event the refusal prevents, quoted

Recorded on the transition because it is the whole point of the node. From a
by-hand run of the guard-neutered control's machine, against the recording
shim on a scratch `HOME`:

```
rm -f capsule-proj-d5f03d78
```

That is a container with **no `capsule.dir` label** — a foreign container —
being removed. The unmutated file on the same fixture logs **zero** `rm` lines
and errors with:

```
capsule: a container named capsule-proj-dcdb3051 exists but was not created by capsule
```

No real `docker rm` ran, no daemon was contacted, no container was touched and
no credential was printed. The comment now names `dir_label` as the guard that
produces that refusal, so the next person auditing this path is pointed at the
line that actually holds it.
