---
est: 0.5h
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec03.md
---

# spec02 — retire spec03's spent box-guard so the composite gate can go green

Blank the one non-blanked verify in the runner's directory — `spec03.md` —
because it is spent, in the exact shape its seven siblings already carry.
Without this, the ticket's acceptance "the runner exits 0" is unreachable:
the runner has an eighth red that is not the empty-eval defect. Run after
spec01.

## The measured spent-ness

`editor/specs/spec03.md`'s verify, run alone on 2026-08-24, prints exactly
one FAIL and exits 1:

```
FAIL: a box was closed
status: 1
```

The firing clause is
`grep -qE "^- \[[x~]\]" prds/03-editor/12-small-plugins/prd.md` — a one-shot
delta guard written to catch a box closing during the correction ticket's own
run. `12-small-plugins` is `state: done` today and its boxes are closed with
executed proofs, so the guard fires on legitimate history. This is Kind 1 of
`mi-rooted-verify-commands` spec02's triage ("a box was closed in another
node" — spent one-shot delta guard); spec03 escaped that census because the
boxes were still open when it measured (2026-08-23). Every other clause of
the command passes today — the single FAIL line above is the whole red.

Per that same triage rule, do not blank a command that is correctly
reporting a failure — this one is not: the failure it reports is the node
landing.

## Changes to `spec03.md`

Follow the shape of the blanked sibling `spec02.md` byte for byte in
structure:

1. Replace the live `verify:` line (the backticked command, currently line
   125) with exactly `verify: ""`.
2. Append a `## Spent proof` section that:
   - names the cause, not the symptom: `prds/03-editor/12-small-plugins/prd.md`
     has closed boxes because `12-small-plugins` is `state: done`; the
     `a box was closed` clause was a one-shot delta guard for this ticket's
     own run. "Stale" is not a reason.
   - quotes the FAIL line and exit status measured above.
   - names this node
     ([`verify-all-empty-eval`](../../../verify-all-empty-eval/prd.md)) as
     what retired it.
   - keeps the retired command **byte-identical** in a ```` ```text ````
     fence, as the execution record of a check that once ran green.
3. Touch nothing else in the file — the acceptance boxes and prose stay.

## Acceptance

- [x] `spec03.md`'s first `^verify:` line is exactly `verify: ""`.
- [x] The retired command appears byte-identical inside the
      `## Spent proof` fence — `diff <(old line) <(fenced line)` empty.
- [x] The Spent proof names `12-small-plugins`, `state: done`, and the
      firing clause; it quotes `FAIL: a box was closed`.
- [x] `bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
      exits 0, prints `SKIP  spec03`, and its summary counts 0 ran,
      8 skipped — quoted (this is the ticket's own `verify:` going green).

## Verify and Proof

```sh
bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh
echo "exit: $?"   # 0, with 8 SKIP lines and no FAIL
```
