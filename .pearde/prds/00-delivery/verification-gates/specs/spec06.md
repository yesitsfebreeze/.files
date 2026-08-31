# spec06 — the interactive checklists, and the fresh-machine run

Goal: R3 and R7. Some acceptance criteria genuinely need a human at a
terminal, and the honest move is to enumerate them per wave rather than
pretend they are automated. R7 goes further: the last gate must run on a
machine that has never seen this config, because everything else can pass on
a developer box that already has the tools installed and prove nothing.

The failure this prevents is the second half of this node's acceptance — "no
gate silently depends on a human having looked."

## Files touched
- `gates/manual/wave0.md` … `gates/manual/wave6.md` — new.
- `gates/manual-coverage.sh` — new.
- `gates/justfile` — extend with the `manual` recipe.

## The checklists

One file per wave 0–6. Each entry is a `- [ ]` box that names its task id
first, then the gesture, then what a pass looks like:

```
- [ ] **T.3** — press F5, then the letter painted in the second pane.
      PASS: focus lands in that pane. FAIL: bell, or focus elsewhere.
      (L-11: the bell is currently silent — `audible_bell` is Disabled and no
      visual bell is set — so a miss looks like nothing happening.)
```

Seeded from two sources, both machine-readable:

1. **`.mi/gantt/plan.json`** — every task with a non-empty `manual` field.
   Measured: **12 today** — `S.4`, `E.5`, `E.14`, `T.3`, `H.2`, `H.4`, `D.1b`,
   `D.1c`, `D.1d`, `D.2`, `D.3`, and `G.1` itself.
2. **This node's R3**, which names four checks by hand that no task field
   carries: the F5 jump landing on the right pane, the smear of a cursor,
   whether the bare-word jump *feels* instant, and the shift-select collapse
   under real keyboard timing.

Three of the twelve (`D.1b`, `D.1c`, `D.1d`) are the held human decisions and
belong in `wave0.md`; `D.2` and `D.3` are open questions in
[`01-capsule/02`](../../../01-capsule/02-dev-image/prd.md) and
[`03-editor/14`](../../../03-editor/14-shift-select/prd.md). `G.1`'s own entry
is the instruction to prove each gate by breaking it — spec05 automates that,
so its checklist entry is a pointer to `just gate-selftest`, not a manual
gesture.

## `gates/manual/wave6.md` carries the fresh-machine procedure

R7 is non-negotiable and cannot be faked on this box. Write the procedure as
numbered, copy-pasteable steps: a container or VM with nothing installed but
git and curl, `git clone` this repo, run the bootstrap, `chezmoi apply`, then
open a shell and work in it for ten minutes. `docker` is on this machine
(`/usr/local/bin/docker`) and `lima` is installed, so the recipe can name a
concrete image rather than hand-waving.

**Do not build an automated fresh-machine gate on this host.** A scratch
`HOME` on a developer box has every tool already on `PATH`, so such a gate
would pass while proving nothing — which is precisely what R7 warns about.
Say that in the file, next to the procedure, so nobody "improves" it later.

Two entries below it, both named in the gantt: `help --check` exits 0, and
`ls --help` still behaves (a `--help` delegation regression breaks the whole
shell — that is why `H.2` needs an adversarial second agent).

## `gates/manual-coverage.sh`

The drift check that keeps the checklists honest:

- Every task id with a non-empty `manual` in `plan.json` appears in **exactly
  one** checklist. Zero or two is red.
- Every checklist entry names a task id that exists in `plan.json`.
- R3's four hand-named checks each appear somewhere, matched **through
  `norm`** — they are prose, this repo wraps at ~78 columns, and per-line
  matching on wrapped prose is the false-negative machine that has bitten
  several lanes today.
- `wave6.md` contains the fresh-machine procedure and the two `--help`
  entries.
- No checklist box is `[x]`. These are run by a human at gate time; a
  pre-ticked box is the "silently depends on a human having looked" failure
  written down.

## Acceptance
- [x] `gates/manual/wave{0..6}.md` all exist; `just manual <n>` prints one.
- [x] `bash gates/manual-coverage.sh` exits 0 against the checklists as
      written.
- [x] Removing one entry makes it red and names the missing task id
      (`missing: E.14`). Proved in a scratch copy.
- [x] Adding a second copy of an entry to another wave makes it red, naming
      both files (`duplicated: E.14(wave4.md,wave5.md)`). Proved.
- [x] An entry naming a task id absent from `plan.json` makes it red
      (`unknown: wave5.md:Z.99`). Proved. A box carrying no task id at all is
      caught by the same check.
- [x] Re-wrapping one of R3's four checks across a line break does **not**
      make it red — the `norm` path is exercised, not just present. Proved by
      re-wrapping "the smear of a cursor" in a scratch copy, together with
      the other half: a plain per-line `grep -F` on that same file fails.
- [x] Ticking a box `[x]` in a scratch copy makes it red. (`[~]` too.)
- [x] All 12 tasks with a non-empty `manual` are covered, and the count is
      read from `plan.json` at run time rather than hard-coded — the plan is
      regenerated by `/mi-gantt` and a frozen number would rot on the next
      replan.
- [x] `gates/manual-coverage.sh` is registered in `gates/waves.tsv` (wave 0)
      and runs as part of `just gates`.

verify: `bash gates/manual-coverage.sh`

Proved RED before writing this spec: `bash gates/manual-coverage.sh` → `No
such file or directory`, exit 127.

Est: 1h
