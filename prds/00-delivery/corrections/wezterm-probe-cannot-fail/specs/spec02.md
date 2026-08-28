---
complexity: 30
footprint:
  - prds/02-terminal/prd.md
---

# spec02 — `02-terminal`'s acceptance line gets a predicate, and the epic gets the constraint

R1 and R3's replacement: rewrite the epic's second acceptance line so it names
a **predicate** and the gate that applies it, and record the constraint that
bought it — `config_builder()` or the probe validates nothing; the exit code
is never a predicate — as an epic invariant where the next WezTerm author will
meet it.

**This unit is an edit to another PRD's body, so the analyst did not make it.**
Per the board protocol, an epic's body is the orchestrator's edit on the
transition. The exact replacement wording is below, ready to paste; nothing
about it has to be re-derived. What has to be *re-run* before the box is
ticked is the two commands in Verify — a tick nobody executed is the failure
mode this whole node exists to correct.

## What already stands

`gates/wezterm-config-fields.sh` (spec01) is built, green, and proven by its
own red. The numbers quoted below are its output on 2026-08-28. The epic's
prose already carries the corrected measurement table — what it does not yet
carry is a predicate, the gate's name, or the constraint as a standing rule.

## What is left

<!-- tree-links: target-file-vantage — every link quoted below is markup to be
written into prds/02-terminal/prd.md, so its relative path resolves from that
epic's directory, not from this spec's. Repairing them here would falsify the
paste-ready wording, which is the whole point of the section. -->

Three edits to `prds/02-terminal/prd.md`, all prose.

### 1. The Acceptance preamble

Replace:

> All four run 2026-08-28 by the orchestrator, under
> [`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
> R4, which requires an epic's own acceptance to be verified before it
> transitions. Three pass; the second is unfalsifiable as written and is why
> this epic is still `open`.

with:

> All four run 2026-08-28 by the orchestrator, under
> [`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
> R4, which requires an epic's own acceptance to be verified before it
> transitions. Two pass outright. The second was under-specified — it named a
> command and no predicate — and now closes on a gate proven by its own red.
> The first is the one still open, on a contract gap put to the user.

### 2. The second acceptance box

Replace the whole box — the line and every paragraph under it, from
`- [ ] No child names a WezTerm config field` down to and including the
`Filed as [wezterm-probe-cannot-fail]…` paragraph — with:

> - [x] No child names, and the shipped `wezterm.lua` does not set, a WezTerm
>       config field the installed build rejects at config-load time. The
>       check is `bash gates/wezterm-config-fields.sh`: probes built with
>       `wezterm.config_builder()` — because that is what ships — driven
>       through `wezterm --config-file <probe> ls-fonts --list-system`, with
>       the verdict read off **empty stderr and non-empty stdout**. The exit
>       code is not a predicate and the gate never reads it; see **I5**.
>
>       Run 2026-08-28 on `wezterm 20240203-110809-5046fc22`: rc 0, 7 PASS /
>       0 FAIL. Sixteen `config.<field>` names harvested from the children,
>       none rejected; the shipped `wezterm.lua` loads with 0 stderr bytes,
>       which validates all 31 of its own `config.<field>` assignments in that
>       one load because it uses `config_builder()` at line 12. The two sets
>       union to 30 distinct fields and nothing in either is rejected.
>
>       Proven by its own red, per `G.1`.
>       `bash gates/wezterm-config-fields.sh --selftest` appends
>       `config.no_such_wezterm_field = true` to a `scratch_tree` copy of
>       `wezterm.lua`, and writes `config.not_a_real_wezterm_field` into a
>       copied child. Each turns the gate rc 1, naming the field, with
>       ``ERROR … `is not a valid Config field` `` on stderr; removing the one
>       line restores rc 0. The same run shows the superseded plain-table
>       probe **green** on the identical violation, so the difference between
>       the two probe constructions stays on the record instead of in a
>       memory.
>
>       The line this replaces named the command without a predicate, and the
>       obvious predicate — the exit status — discriminates nothing. Filed and
>       corrected as
>       [`wezterm-probe-cannot-fail`](../00-delivery/corrections/wezterm-probe-cannot-fail/prd.md),
>       whose own first filing was wrong and is kept there as the record.

### 3. A new invariant, after I4

The constraint R3 was withdrawn in favour of. It is prose and carries a
number, per `AGENTS.md`'s invariant rule.

> **I5** — **A WezTerm config check goes through `config_builder()` and reads
> stderr; the exit code is not a predicate.** `wezterm.config_builder()`
> installs a validating `__newindex` metamethod that refuses an unknown field
> as it is assigned; a plain `return { ... }` table installs none and drops
> unknown keys silently. The probe's **construction**, not the build, is what
> decides whether a check can fail — and a probe that does not use
> `config_builder()` is not testing what ships
> (`home/dot_config/wezterm/wezterm.lua:12`). Measured 2026-08-28 on
> `20240203-110809-5046fc22` at `ls-fonts --list-system`: a clean
> `config_builder()` probe gives 791 stdout lines and 0 stderr bytes; the same
> probe plus one bogus key gives 0 stdout lines and 350 stderr bytes carrying
> `` `no_such_wezterm_field` is not a valid Config field ``. **Both exit 0** —
> as do a wrong value type, a `--config-file` that does not exist, and the
> whole set again with `config:set_strict_mode(true)`. Two constraints come
> with it. `show-keys` is not an error channel at all: on a config that
> `ls-fonts` rejects with 5 stderr lines, `show-keys --lua` exits 0 with 230
> stdout lines and **zero** on stderr, so it serves only as a read-back
> control. And the `__newindex` error is a Lua error that aborts the chunk, so
> a probe carrying several bad fields reports only the **first** — one field
> per probe. This invariant was bought by a measurement that was filed wrong
> and refuted the same day; the record is in
> [`wezterm-probe-cannot-fail`](../00-delivery/corrections/wezterm-probe-cannot-fail/prd.md).

## Acceptance

- [x] The epic's second acceptance box names a predicate (empty stderr /
      non-empty stdout) and the gate that applies it, and says the exit code
      is not usable.
- [x] The box is `[x]` **only after** the two Verify commands were re-run at
      edit time and their output quoted — not on this spec's say-so.
- [x] `02-terminal` carries **I5** in prose with a number, after I4, and no
      sentence anywhere in the epic says or implies that this build fails to
      reject unknown config keys. That claim is false; it was the withdrawn
      R3 and must not reach the epic in the epic's own voice.
- [x] `grep -rn 'wezterm-config-fields' prds/02-terminal/prd.md` returns at
      least one hit — the epic points at the gate that closes it.
- [x] `bash gates/tree-links.sh` still exits 0: the box adds two relative
      links out of the epic.

## Verify and Proof

```sh
bash gates/wezterm-config-fields.sh
bash gates/wezterm-config-fields.sh --selftest
grep -n 'wezterm-config-fields' prds/02-terminal/prd.md
grep -n '\*\*I5\*\*' prds/02-terminal/prd.md
bash gates/tree-links.sh
```

## Run 2026-08-28 — the orchestrator's edit

All three edits applied to `prds/02-terminal/prd.md`. The Verify block was
re-run at edit time, which is what the second box above requires:

- `bash gates/wezterm-config-fields.sh` → rc 0, 7 PASS / 0 FAIL, 16 fields
  harvested and 0 rejected, 31 artifact assignments validated in one load.
- `bash gates/wezterm-config-fields.sh --selftest` → rc 0. GREEN on the
  unmutated scratch copy; RED 1 on `config.no_such_wezterm_field` appended to
  the copied `wezterm.lua` (rc 1, and it says why — stderr carried the
  rejection); GREEN again on removing that one line; RED 2 on
  `config.not_a_real_wezterm_field` written into a copied child.
- `grep -c 'wezterm-config-fields' prds/02-terminal/prd.md` → 2.
- `grep -n '\*\*I5\*\*' prds/02-terminal/prd.md` → `77:`, immediately after
  I4 at `67:`.
- `bash gates/tree-links.sh` → rc 0, 1641 links in 480 files, 0 broken.
- The withdrawn-R3 check: `grep -in "silently ignores an unknown|does not
  reject unknown" prds/02-terminal/prd.md` → no match. The false claim reached
  the epic in a first draft this round and is gone from it.
