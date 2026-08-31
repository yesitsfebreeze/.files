# spec01 — a non-record `verify` element must be a named violation, not a crash

verify: `nu tests/help-content-model.nu`

## Goal

Close the one residual the `cc-1787432671` evidence block names against R2's
`verify` sub-box: `bad-field`'s `record-list` arm checks *list-ness* and never
*element-ness*, so a `verify` list holding a non-record dies at
`tests/help-content-model.nu:568` with an uncaught nushell
`only_supports_this_input_type` instead of a violation with a message.

Reproduced on 2026-08-21 against a scratch copy of the help dir, with
`capsule.nuon`'s first entry mutated to `verify: ["foo"]`:

```
Error: nu::shell::only_supports_this_input_type
  x Input type not supported.
     ,-[tests/help-content-model.nu:568:35]
 568 |                         let tc = ($t | columns)
     :                                   ^|   ^^^|^^^
     :                                    |      `-- only table and record input data is supported
```

Real exit code is `1`, so it fails closed and the box stands — but the gate
stops at the first bad entry and reports nothing about the rest of the corpus,
and a reader gets a stack trace where every other boundary in this file gives
them the entry id and the reason. That asymmetry is the defect: this is the
only one of the four boundaries `bad-string`/`bad-string-list`/`bad-field`
serve that can still throw.

## Files

- `tests/help-content-model.nu` — `bad-field`'s `record-list` arm (~line 133),
  the `verify` loop (~line 560), and `selftest` (~line 361)
- `home/dot_config/nushell/help/README.md` — the `### verify — a list of typed
  targets` section, if it states the element contract

No `.nuon` surface file changes: the live corpus has no such element, and this
spec must not alter entry text.

## What to build

Extend `bad-field`'s `record-list` arm to check each element the same way
`bad-string-list` checks each of its own — one implementation reused, not a
fifth spelling of the idea, matching the comment at
`tests/help-content-model.nu:88-92` that says adding a boundary should touch
one place. Return the same `""`-means-good string the other two predicates
return, phrased in their voice (e.g. ``has an element that is a string, not a
record``).

Then make the `verify` loop trust it: guard the `for t in $v` body so a
non-record element is reported and skipped rather than reaching `$t | columns`.

## Acceptance

- [x] `verify: ["foo"]` on a live entry exits 1 with a named violation naming
      the file and entry id, and **no** `nu::shell::only_supports_this_input_type`
      anywhere in the output.
      Ran on a scratch copy, `capsule.nuon`'s first entry mutated: exit 1,
      `2 violation(s)` — ``capsule.nuon [capsule [dir]]: `verify` has an element
      that is a string, not a record`` and ``capsule.nuon [capsule [dir]]:
      verify target is a string, not a record``. No `only_supports` anywhere in
      the output.
- [x] `verify: [{kind: "prose"}, "foo"]` (a good element beside a bad one)
      exits 1 and still reports the violation, proving the loop reports and
      continues rather than dying on the first element.
      Ran, exit 1, same two messages. Run again with the bad element FIRST and
      a *defective* record second — `["foo", {kind: "incantation", name: "x"}]`
      — the run reports 3 violations including ``unknown verify kind
      `incantation```, so the loop really continues past the bad element rather
      than merely surviving it.
- [x] `verify: [5]` and `verify: [null]` each exit 1 with a shape message that
      names what the element actually is, not a generic one.
      `[5]` → ``has an element that is a int, not a record`` / ``verify target
      is a int, not a record``; `[null]` → ``is a nothing, not a record``.
- [x] The gate reports the *whole* corpus on a mutated file: with `verify:
      ["foo"]` on one entry **and** a second, unrelated defect elsewhere (e.g.
      a trailing period on another entry's `title`), both violations appear in
      one run. Today only the crash appears.
      Ran with `verify: ["foo"]` on `capsule.nuon [capsule [dir]]` and a
      trailing period on `shell.nuon [z <query>]`'s title: exit 1,
      `3 violation(s)`, and `shell.nuon [z <query>]: title ends with a period`
      is the first line.
- [x] `selftest` carries a control asserting `bad-field "verify" ["foo"]`
      returns non-`""` and `bad-field "verify" [{kind: "prose"}]` returns `""`.
      Forcing the new arm to return `""` unconditionally trips that control —
      run it and record the exit.
      Both controls are in `selftest`, plus three on `bad-record` itself
      (record / int / null). Forcing `"record-list" => ""` on a copy of the
      gate: exit 1, `1 violation(s)`, ``selftest: bad-field accepts a `verify`
      element that is a string — that element reaches `$t | columns` and
      crashes the run, so one bad entry hides the whole corpus``.
- [x] Unmutated: `nu tests/help-content-model.nu` still exits 0 with `84
      entries across 4 files, 9 topics, 10 prose-only … ok`. No entry text
      changed — `git diff --stat home/dot_config/nushell/help/*.nuon` is empty.
      Exit 0 with exactly that line, re-run on the finished tree.
      **The second clause is `[x]` for spec01 and cannot be for the ticket, so
      it is qualified rather than claimed:** spec01's own change touched
      `tests/help-content-model.nu` and one paragraph of `README.md` and no
      `.nuon` file at all — checked by md5 immediately after it landed, before
      spec02 began. spec02 then changed 14 `use` fields and two `why` fields by
      design, so the diff on the surface files is not empty at the end of the
      ticket. Every one of those edits is spec02's, is a recorded finding, and
      is listed in `use-review.nuon`.

## Out of scope

- Whether a `verify` target *resolves* against a live surface. That is
  [`coverage`](../coverage/prd.md) R5 and
  [`04-drift-check`](../../04-drift-check/prd.md), and building a resolver here
  poaches their interface.
- Any change to `VERIFY_KINDS` or to the six kinds.
