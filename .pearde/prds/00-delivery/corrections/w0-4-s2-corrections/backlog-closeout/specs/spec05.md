verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check05.sh`

# spec05 — file the wrong-baseline risk as row M-21 (R9)

**Goal.** `w0-4-s2-corrections/docs-inventories` R7 swept
`capabilities-nushell.md`, `-nvim.md` and `-terminal.md` for source-vs-deployed
wording — **before** `~/.local/share/chezmoi` was identified as a stale June
clone. The sweep used the wrong baseline. That node is `done` with R7 at `[~]`
and its `## Superseded guard` routes the re-measure here. A risk recorded only
inside a closed ticket's report is a risk nobody will find; put it in the
table the next audit reads.

**Files touched — two, bodies only.**
- `.mi/prds/00-delivery/corrections/prd.md` — one new row at the end of the
  `## S2 — my factual errors` table.
- `.mi/prds/.../backlog-closeout/prd.md` — R9's line gains a closing sentence
  recording the id filed. **Frontmatter is not touched.**

**RED baseline, measured before writing this spec:** `bash check05.sh` →
**15 FAIL**, exit 1.

## Why the id is M-21 and not L-13

Two gates constrain it, and they disagree with the obvious choice:

- `tests/live-bugs.sh` asserts **"no row id outside L-1..L-12"**. An `L-13`
  row turns this ticket's own `verify:` red.
- `gates/audit-findings.sh` asserts no row id outside `T/C/L/M`, and
  contiguity `1..max` within each class.

`M-21` is the only id satisfying both. Note that **`L-13` already exists** — as
a *record* in `.mi/docs/capabilities-provisioning.md`, deliberately not as a
table row, and `tests/live-bugs.sh` has a whole block asserting it. Do not
promote it.

## The row

```
| M-21 | unowned — needs a node; the `capabilities-terminal.md` third is inside
[`w0-2-terminal-respec`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/w0-2-terminal-respec/prd.md)'s remit | **The
source-vs-deployed sweep used the wrong baseline and must be re-measured.**
`w0-4-s2-corrections/docs-inventories` R7 swept `capabilities-nushell.md`,
`-nvim.md` and `-terminal.md` for source-vs-deployed wording on 2026-08-21,
before `~/.local/share/chezmoi` was identified as a two-months-stale June
clone whose HEAD is a git ancestor of the live source. That node is `done`
with R7 at `[~]`. Re-measure against `/Users/feb/dev/.files` — what `chezmoi
source-path` reports — and **never** against `~/.local/share/chezmoi`. Same
failure class as the seven assertions in `tests/live-bugs.sh` that were green
while asserting the opposite of the record until W0.8 repointed them. |
```

Write it as one physical line if the table's other rows are single-line; the
checks are whitespace-normalised either way. The link must resolve — Tier A
link health gates.

**No completion marker.** Nothing has been re-measured. R2 applies to a row
this node files exactly as it applies to a row it inherits.

**Do not attempt the re-sweep here.** The ticket says this node routes.

## Making the row reachable — the only honest route available

`gates/audit-findings.sh` disposes a finding three ways: an inline verdict
marker on its own row, a mention in some board `prd.md` other than the
backlog, or a mention in `plan.json`. M-21 has no marker (it is open, and
faking one is the exact thing R2 forbids), and this node owns neither another
node's `prd.md` nor `plan.json`. So the route is the one G.1 already
documented for the other seven: **this node's own R9 line records the id it
filed.** Append to R9:

```
Filed as **M-21**.
```

That is a record of work done, not a change of requirement, and it is what
keeps the row from going orphan the moment the gate next runs. `check05.sh`
asserts both the sentence and `49 findings, 0 undisposed`.

## Boxes

- [x] An `M-21` row exists, the M class is contiguous `M-1..M-21`, and the row
      has the same three cells as its neighbours.
- [x] No `L-13` row was invented.
- [x] The row names `docs-inventories`, its `R7`, all three inventories,
      `/Users/feb/dev/.files`, `~/.local/share/chezmoi` as the forbidden
      baseline, and says what the sweep was for.
- [x] The Owner cell routes the `capabilities-terminal.md` third to
      `w0-2-terminal-respec` and says the rest is unowned.
- [x] The row carries **no** completion marker.
- [x] This node's R9 line records `M-21`.
- [ ] `gates/audit-findings.sh` reports `49 findings, 0 undisposed`, exit 0,
      and `--selftest` exits 0.
      **Left open — the one thing that could not be satisfied.**
      `bash gates/audit-findings.sh` (the wave-0 gate, no flag) exits 0 with
      `49 findings, 0 undisposed`. `--selftest` exits 1, and only because
      this spec also requires `**Fixed` on M-11: the selftest hardcodes
      `probe="M-11"`, and its `strip_id_everywhere` neutraliser rewrites a
      marker to `(was &)`, which re-inserts the match — so an inline marker
      on that one row leaves it disposed and its three route counterfactuals
      unprovable. Proved by counterfactual: with M-11's marker replaced by a
      placeholder the selftest is `rc=0`; with it restored, `rc=1` on exactly
      those four assertions. The fix is one capture group in
      `gates/audit-findings.sh`, which `00-delivery/verification-gates` owns
      and this node may not write. Recorded in the M-11 row itself.
- [x] `tests/live-bugs.sh` 159 PASS / 0 FAIL, 40 `table:` + 50 `routing:`;
      Tier A broken links 0.
- [x] `chezmoi source-path` still prints `/Users/feb/dev/.files/home`, and
      `/Users/feb/dev/.files` matches `files-state.txt` — HEAD `8e99f58` plus a
      digest of its working tree. It already carried three uncommitted changes
      when W0.4h opened (`config.nu`, `wezterm.lua`, an untracked `theme.nu`);
      none of them is this ticket's, and the pin is what proves the ticket
      added none.
