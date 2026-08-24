---
memo: a-tree-guard-must-not-guard-machinery-state
kind: note
status: decided
subject: A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
date: 2026-08-23
updated: 2026-08-24
prds:
  - 03-editor/07-formatting
  - 03-editor/02-keymaps
---

# a-tree-guard-must-not-guard-machinery-state — the board writes itself while you measure it

## Decision

A gate that hashes the repo to prove it wrote nothing outside its scratch must
treat `prds/` as **SOFT / INDETERMINATE**, the way `gates/selftest.sh` already
does. A HARD guard over `prds/` reports a red that no gate and no worker
caused, because the board's own machinery writes there continuously.

## Why

`tests/provisioning.sh` reported `changed: …/prds` on two of three consecutive
runs on 2026-08-23. The implementer did not assume and did not ignore it: it
hashed `prds/` either side of a run and named exactly one moved file —
**`prds/.plane-pull.json`**, untracked, 148 KB, the pearde live service's own
pull state, rewritten inside the guard's window. `plane-pull` appears nowhere
in `tests/provisioning.sh`, `install.sh` or `gates/lib.sh`. The third run, in
a quiet window, was clean, and that is the run its report quoted.

So the guard is correct about the bytes and wrong about the subject. Any lane
running that gate while the daemon pulls sees the same red, and the natural
misdiagnosis — "the gate leaks" or "another worker is writing the board" — is
expensive and wrong. `gates/selftest.sh` already reached this conclusion for
the same reason; `tests/provisioning.sh` did not inherit it.

This is a property of running a live ticket mirror beside the gates, and it
will get more common rather than less: the daemon reconciles within about a
second of any state change, and a state change is what a passing gate causes.

## A second instance, and the writer is the orchestrator

Found 2026-08-24, hours after this memo was written, while chasing the last
red on the board's own meta-gate. `gates/selftest.sh` was reported exiting 1
on two `--selftest` contracts. Run directly, one had already healed
(`gates/wave-status.sh --selftest` → **rc 0**; it had been red only while a
lane held `gates/waves.tsv`), and the other is this memo's category again:

```
gates/retired-phrases.sh --selftest → rc 1
FAIL  CF13: prds/, docs/ and AGENTS.md are byte-identical across the whole selftest
```

CF13 hashes **`prds/`** across its own run. `prds/` is the board. The
orchestrator writes a `prd.md` on every state transition, and a round is
nothing but state transitions — so **any orchestrator round in progress makes
this gate red**, and a board being worked is the normal case, not the
exception.

That widens the category in the way that matters. The first instance blamed
the live Plane service writing `.plane-pull.json`, which sounds like an
avoidable accessory. It is not the accessory: it is *the board being written at
all*. Stopping the daemon would not have fixed CF13. Nothing short of freezing
the board would, and a gate that requires a frozen board is a gate that can
only pass when nobody is working.

It also explains two reports that read as mysteries at the time: a worker
seeing `wrote nothing outside its scratch` FAILs that **named a different set
of gates on each run**, and another seeing a `prds` red on two of three
consecutive runs. Same cause, three surfaces.

## Corrected 2026-08-24 — the Decision above is too blunt as written

The rule says a gate "must treat `prds/` as SOFT / INDETERMINATE". Measured by
`gates-lib-anchored-lookup`'s analyst, **a name-keyed exclusion of `prds/`
inside `gates/lib.sh` would be actively wrong**:
`gates/retired-phrases.sh:395` hashes `$root/prds` where `$root` is a **scratch
copy**, which is a perfectly legitimate HARD subject. Excluding by name would
un-guard a real assertion in order to quiet a false one.

So the rule is about **the live board**, not about the path spelling. The
distinction a gate needs is which paths a daemon or an orchestrator writes
*during this run* — and `snapshot_paths` cannot know that, because it hashes
whatever list it is handed.

The judgement, from the same analysis: `lib.sh` is the right home for the
**mechanism** and the wrong home for the **policy**. The HARD/SOFT split that
solves this already exists — roughly 60 lines of `GATES_META_GUARD_HARD` /
`_SOFT` — but it lives inside `gates/selftest.sh`, and **none of the five other
sites inherited it**: `tests/provisioning.sh:497`, `tests/shell-init.sh:576`,
`tests/dev-image.sh:414`, and `gates/retired-phrases.sh:395` and `:735` (CF13)
all hash `prds/` HARD. Lift the split into `lib.sh` as an inheritable
`snapshot_soft` plus indeterminate-reporting pair, and leave the choice of
which paths are SOFT to each gate. That is two nodes, and neither is the one
that found it.

The machinery files, for whoever writes that: `prds/.plan.json`,
`prds/.view.html`, `prds/.history.jsonl` — all git-ignored, all rewritten
repeatedly on 2026-08-24, and all inside a bare `find` over `prds/`.

## Alternatives considered

**Stop the daemon while gates run** — rejected. It is the thing keeping the
mirror and the timeline honest, and a gate that requires the board to be
frozen is a gate nobody runs.

**Exclude only `.plane-*` files by name** — narrower, and it fails the next
time the machinery grows a file. The category is "board machinery state", not
three filenames.

**Leave it and let each lane rediscover it** — what happened tonight. It cost
one implementer three runs and a hashing detour to attribute, and it would
have cost the next lane the same.

## Consequences

- Until the guard is changed, a red naming `prds` — on
  `tests/provisioning.sh` or on `gates/retired-phrases.sh --selftest`'s CF13 —
  is **attributable, not mysterious**: the board is being written, by the
  daemon or by the orchestrator. Re-run in a quiet window before believing it,
  and never absorb it into an unrelated node's acceptance box.
- **A red that heals on its own is the tell.** `gates/wave-status.sh
  --selftest` went from rc 1 to rc 0 with no fix, because the lane holding
  `gates/waves.tsv` released it. Two of the three surfaces above behave the
  same way. If a whole-tree red disappears when you re-run it in a quiet
  window, it was never the subject's defect.
- This is knowingly **not filed as a PRD**. It changes no verdict about the
  deliverable — only how loudly a gate complains about a file no shipped
  configuration contains — which is the memo test in
  [`port-first-over-derived-findings`](port-first-over-derived-findings.md).
  Whoever next opens `tests/provisioning.sh` for a real reason should fix it
  in passing.
