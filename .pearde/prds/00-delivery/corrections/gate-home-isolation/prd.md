---
state: done
priority: 50
est: 2.75h
task: W0.9
mode: afk
needs:
verify: ""
origin: derived
---

# Gate HOME isolation

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/deploy-skeleton.sh` deploys with an **ambient `$HOME`**. Now
that a `run_after` script exists, every run of that gate writes into the user's
real home directory. Pin `HOME` so a gate can never touch the machine it runs
on.

**Created 2026-08-21 by the orchestrator**, from a defect `05-platform/03-shell-init-generation`
(P.4) found by hitting it. Its `cz()` helper passes `--destination "$root/dest"`
but never sets `HOME`, so chezmoi's run-script stage inherits the caller's. P.4's
generator writes to `$HOME/.cache/nushell/init/`, so running the gate created a
real `~/.cache/nushell/init/` with 2280 / 1966 / 1809-byte files. P.4 measured
the blast radius (every other real path byte-identical; `~/.config/television/config.toml`
untouched only because it already existed) and removed the directory, which had
not existed before. **The machine is as found — but it will reappear on the next
`just gates`.**

This is the **second** isolation failure of the same family measured today, and
the pair is the point:

- `HOME` does not isolate **chezmoi** — a scratch-`HOME` `chezmoi init --force`
  rewrote the real `~/.config/chezmoi/chezmoi.toml` and repointed this machine.
  Fixed by passing `--config`, `--config-path`, `--destination`,
  `--persistent-state` and `--cache` explicitly.
- `--destination` does not isolate a **`run_` script's** `$HOME`. The flags
  bound where chezmoi *writes*; they do not bound what a script chezmoi *runs*
  inherits.

Neither half is sufficient alone. A gate must do both.

P.4 could not fix this: its spec S4.7 explicitly protects `cz()` as P.1's, and
reaching into it would have been a two-writer edit on a file P.4 was already
narrowing elsewhere. That was the right call, and it is why this node exists.

## Requirements
- [x] **R1** — **Both** unpinned sites in `tests/deploy-skeleton.sh` set `HOME`
      to the same scratch directory they pass as `--destination`.
      *Amended 2026-08-21 on the analyst's measurement: `cz()` is not the only
      one.* `--cutover` reaches chezmoi through a second path — the PATH shim
      it writes at `$S/bin/chezmoi`, which carries the five flags and **no
      `HOME`**. With only `cz()` pinned, `--apply` and `--push` go clean while
      `--cutover` still writes the user's home, and the gate reports
      60 PASS / 0 FAIL throughout. A `cz()`-only fix would close this node
      **green with the defect live** — the exact failure this board has now hit
      three times.
- [x] **R1b** — `tests/managed-config.sh` has the **identical** defect and was
      never reported: same `cz()` shape, real `init`+`apply`, no `HOME`. From a
      clean start it creates the same three files. In footprint because no live
      writer holds it and `just gates` wave 1 runs it, so leaving it means the
      sweep still writes the machine.
- [x] **R2** — The fix is proved by **counterfactual**: with `HOME` pinned, a
      full gate run leaves `~/.cache/nushell` absent; with the pin removed, the
      same run creates it. Demonstrate both. A fix that is merely present is
      not proved.
- [x] **R3** — Audit the other gates for the same defect and report per gate,
      fixing only those in this footprint: `tests/shell-init.sh`,
      `tests/managed-config.sh`, `tests/provisioning.sh`, `tests/live-bugs.sh`
      and the scripts under `gates/`. P.4's own `tests/shell-init.sh` already
      sets `env -i HOME=…` on every invocation and is believed clean —
      **verify rather than assume**, and say which gates you checked.
- [x] **R4** — Record the constraint where the next gate author will meet it,
      not only in this ticket: the two-part rule (flags bound where chezmoi
      writes; `HOME` bounds what its scripts inherit) belongs in
      `gates/lib.sh`'s guard section, which every gate sources.
- [x] **R5** — `tests/deploy-skeleton.sh`'s existing assertions survive
      untouched — it is at **60 PASS / 0 FAIL** after P.4's spec04. The PASS
      count may rise; it may not fall.
- [x] **R6** — **A gate must bound what it measures.** `gates/selftest.sh`'s
      "wrote nothing outside its scratch" check attributes a change **by
      window**: it deep-snapshots all of `.mi`, `tests` and `gates` around
      each script's `--selftest` and blames that script for anything that
      moved. `.mi/prds/**` is where every analyst writes its specs and where
      the orchestrator writes ticket state, so any concurrent lane convicts
      an innocent gate. Measured 2026-08-21: a quiet run is 25 PASS / 0 FAIL,
      and the same run with one file under `.mi/prds/` being appended to
      mid-run is 23 PASS / **2 FAIL**, convicting `tree-links.sh` and
      `audit-findings.sh`, neither of which wrote anything. The orchestrator
      has called this a false positive three times today and twice blamed the
      wrong script — which is exactly how a real leak gets waved through.
      Attribute by **path**, not by window: a change the script could not
      have caused must not be reported as its failure. It must still go red
      on a gate that genuinely writes outside its scratch.

      Added 2026-08-21 by the orchestrator, mid-analysis. It is the same
      thesis as R1–R5 — a gate that does not bound its own reach produces a
      verdict that is noise — which is why it lives here and not in a tenth
      node. It does raise this node above its 0.75h estimate.

## Acceptance
- [x] `bash tests/deploy-skeleton.sh` exits 0 and leaves `~/.cache/nushell`
      absent, proved by checking before and after in the same run.
      *rc 0, 63 PASS / 0 FAIL, and three in-run assertions —
      `PASS  {apply,push,cutover}: no REAL user path under $HOME was touched
      (moved: <none>)` — each hashing seven real paths on stage entry and
      re-hashing them on stage exit. `~/.cache/nushell` absent before and
      after.*
- [x] The counterfactual is demonstrated: unpinning `HOME` re-creates it.
      *Twice, both hermetically under a fake `HOME` so the real one is never
      dirtied. (a) Pristine repo → rc 1, the leak lands in the fake home at
      2280 / 1809 / 1998 bytes; fixed repo → rc 0, absent. (b) With only the
      `--cutover` PATH-shim pin removed and `cz()` still pinned, the gate goes
      **red on its own guard** — which is the case a `cz()`-only fix would
      have shipped green.*
- [x] `just gates` PASS count does not fall.
      *677 PASS / 0 FAIL, rc 0, against the orchestrator's 667 PASS / 5 FAIL.
      Ten more PASSes, five fewer FAILs. Details and the T.8 caveat in the
      completion record below.*
- [x] Every gate named in R3 is reported on by name.
      *Table below: all thirteen invocations re-measured by the implementer,
      each with the real user paths hashed immediately before and after.*
- [x] `gates/selftest.sh` stays green while an unrelated file under
      `.mi/prds/` is rewritten throughout the run, and still goes red on a
      gate that genuinely writes outside its scratch. Both directions
      demonstrated.
      *Green: the exact probe that measured 23 PASS / 2 FAIL now measures
      25 PASS / 0 FAIL with `INDETERMINATE` lines naming the churned file.
      Red: the original vandal still fails, and a new HARD-path vandal
      (`.mi/docs/`) fails and names the file it blames. Both are now
      permanent `--selftest` counterfactuals, not one-off runs.*

## Out of scope
- `repo-skeleton`'s R3 evidence sentence, which quotes a command whose flags
  P.4 changed to `--exclude=always`. Tracked separately by the orchestrator; a
  `[x]` whose stated proof no longer reproduces is a false record, but it is a
  wording fix, not a defect.


## Completion record — 2026-08-21

### R3: the audit, every named gate, re-measured not inherited

Each invocation was run on its own, with eleven real user paths
(`~/.cache/{nushell,starship,television}`, `~/.zoxide.nu`,
`~/.config/{nushell/help,television,chezmoi,wezterm,nvim}`, `~/.gitconfig`,
`~/.local/share/chezmoi`) hashed immediately before and immediately after.
"moved" is the diff of those two hashes. All figures are the implementer's own
runs, after the fixes landed.

| invocation | rc | PASS / FAIL | moved |
|---|---|---|---|
| `bash tests/deploy-skeleton.sh` | 0 | 63 / 0 | none |
| `bash tests/managed-config.sh` | 0 | 65 / 0 | none |
| `bash tests/shell-init.sh` | 0 | 95 / 0 | none |
| `bash tests/provisioning.sh` | 0 | 115 / 0 | none |
| `bash tests/live-bugs.sh` | 0 | 159 / 0 | none |
| `bash gates/tree-links.sh` | **1** | 0 / 0 | none |
| `bash gates/audit-findings.sh` | 0 | 101 / 0 | none |
| `bash gates/manual-coverage.sh` | 0 | 19 / 0 | none |
| `bash gates/probes.sh` | 0 | 0 / 0 | none |
| `bash gates/probes.sh --selftest` | 0 | 10 / 0 | none |
| `bash gates/selftest.sh` | 0 | 25 / 0 | none |
| `bash gates/selftest.sh --selftest` | 0 | 12 / 0 | none |
| `bash gates/wave-status.sh --matrix` | 0 | 0 / 0 | none |
| `bash gates/wave-status.sh --validate` | 0 | 6 / 0 | none |
| `bash gates/wave-status.sh --selftest` | 0 | 16 / 0 | none |

**Verdicts.** `tests/deploy-skeleton.sh` and `tests/managed-config.sh` were
the two defective gates; both are fixed here and both now carry their own
real-path assertion. `tests/shell-init.sh` is clean and was **verified, not
assumed** — its `cz()` wraps every call in `/usr/bin/env -i HOME="$S/home" …`
with `--destination "$S/home"`, the same directory, and it is the precedent
both fixes were built on. `tests/provisioning.sh` is clean and runs no real
chezmoi at all. `tests/live-bugs.sh` is clean and read-only. Every script
under `gates/` is clean for `HOME`: none of them runs chezmoi except the
read-only `source-path` probe in `lib.sh`'s guard. `gates/selftest.sh` was
clean for `HOME` and defective for **attribution**, which is R6, fixed here.
`gates/wave-status.sh` was clean in itself and dirty only by inheritance —
its `--sweep` invokes the two defective gates, which is why **`just gates`
wrote the user's home** until now; that is gone with the two fixes.
`gates/lib.sh` is a library, not a gate, and now carries the rule.

Two corrections to the analyst's audit table, neither a `HOME` defect:

1. `gates/tree-links.sh` **exits 1, not 0**, and reports **99** broken links
   across 99 files, not 96 across 90 — the count grew because concurrent lanes
   kept adding specs with the same relative-link mistake (links written as if
   from the node directory rather than from `specs/`). The sweep reports it as
   `wave 0 gate: … exited 1 — reported, not gating (wave is PENDING)`, so it
   does not fail `just gates`. Pre-existing, unrelated, **routed** below.
2. `bash gates/probes.sh` with no argument is 0 PASS / 0 FAIL by design; its
   assertions live behind `--selftest`. Not a defect, just worth not
   misreading as an empty gate.

### The sweep, and the T.8 caveat

`just gates`, real user paths hashed in the same wrapper immediately before
and after: **rc 0, 677 PASS / 0 FAIL**, `~/.cache/nushell` **absent** both
times, and not one watched path moved a byte. Against the orchestrator's
`667 PASS / 5 FAIL` that is ten more PASSes — three from the `deploy-skeleton`
home-guard, one from `managed-config`, six from the two new `selftest`
counterfactuals — and the five false FAILs gone.

That sweep also carried six `INDETERMINATE:` lines naming
`.mi/prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec01.md`: a
**real** concurrent analyst writing a spec while `manual-coverage.sh` was
under test. Before this node that was a FAIL convicting an innocent gate. It
is now a named, non-failing report — R6 working on live traffic rather than in
a rehearsal.

A second sweep five minutes later came back **674 PASS / 3 FAIL**, and it is
not a regression: at 19:48 the orchestrator added task **T.8**
(`02-terminal/07-grid-centering`) to `.mi/gantt/plan.json`, and
`gates/waves.tsv` — not this node's file — has no row for it. One root cause,
two cascades:

```
FAIL  registry: every plan.json task appears in a wave row (missing: T.8)
FAIL  contract: wave-status.sh accepts --selftest and exits 0 (rc 1)
FAIL  preflight: gates/selftest.sh
```

674 + 3 = 677. **Proved rather than argued:** an exact copy of the repo with
*only* a `T.8` row added to the copy's `gates/waves.tsv` — nothing else
changed, the real registry untouched — sweeps at **rc 0, 677 PASS / 0 FAIL,
0 INDETERMINATE**. The same gap is why `bash gates/selftest.sh` reads
24 PASS / 1 FAIL against the live board after 19:48 and **25 PASS / 0 FAIL**
in that copy, and why spec03's `verify:` exits 1 today. This is also the S3.6
surface biting for real: a gate whose `--selftest` *reads* the board can have
its own verdict changed by a concurrent lane, and no snapshot narrowing
touches that.

Everything this node owns is green throughout, on the live board, after the
T.8 gap appeared: `bash tests/deploy-skeleton.sh` rc 0 at 63 PASS / 0 FAIL,
`bash tests/managed-config.sh` rc 0 at 65 PASS / 0 FAIL,
`bash gates/selftest.sh --selftest` rc 0 at 12 PASS / 0 FAIL, and both fake-`HOME`
counterfactual verifies rc 0.

### Machine end state

Unchanged from how it was found, checked after every run:

- `~/.cache/nushell` — **absent**
- `chezmoi source-path` — `/Users/feb/dev/.files/home`
- `~/.config/chezmoi/chezmoi.toml` — sha256 `02d5d4ee…`

Nothing was installed and `/Users/feb/dev/.files` was not modified.

### Routed to the orchestrator, not fixed here

1. **`T.8` needs a `gates/waves.tsv` row.** Until it has one, `just gates` is
   3 FAIL for a reason no gate caused. `waves.tsv` belongs to the wave's own
   task, not to this node.
2. **`gates/tree-links.sh`: 99 broken links across 99 files** in `.mi/prds`,
   concentrated in `00-delivery/decisions/wallpaper-opacity/specs/` and
   `00-delivery/decisions/tinty/specs/` — relative links written as if from
   the node directory rather than from `specs/`. The gate exits 1 but the wave
   is PENDING, so nothing enforces it. Growing, because each new analyst
   repeats the pattern.
3. **`tests/shell-init.sh` watches `$HOME/.config/nushell` as a whole**, which
   holds the live `history.sqlite3-wal` that interactive Nushell rewrites at
   any moment. A latent flake that will read as "the gate touched a real user
   path" when it did nothing. Narrowing it to `$HOME/.config/nushell/help`
   fixes it. P.4's file, not this node's.
4. **A frozen board snapshot for the board-*reading* gates** —
   `audit-findings.sh`, `tree-links.sh`, `manual-coverage.sh`. This node fixes
   write attribution; it does not fix a gate whose own verdict moves because
   the board moved under it. Documented in `gates/selftest.sh`'s header where a
   reader meets the surprising FAIL, and deliberately left as its own node.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All 23 spec boxes ticked against runs.
Re-verified independently: `tests/deploy-skeleton.sh` **63 PASS / 0 FAIL**
(floor was 60), `tests/managed-config.sh` **65 PASS / 0 FAIL** (was 64),
`~/.cache/nushell` **absent**, and `HOME` pinned at both `deploy-skeleton`
sites and the one in `managed-config`.

**The amended R1 was the whole ticket.** My original wording — "pin `HOME` in
`cz()`" — would have shipped green with the defect live: `--cutover` reaches
chezmoi through a second path, the PATH shim at `$S/bin/chezmoi`, and with only
`cz()` pinned the gate reports 60 PASS / 0 FAIL **while still writing the user's
home**. The implementer added a third counterfactual proving exactly that: with
only the shim pin removed, `--cutover` now goes rc 1 on
`FAIL: cutover: no REAL user path under $HOME was touched (moved: …/.cache/nushell …/.cache/starship)`.
The leak a `cz()`-only fix would have shipped is now caught by the gate itself.

**R1b was a defect nobody had reported.** `tests/managed-config.sh` had the
identical unpinned `cz()` and created the same three files from a clean start.

**R6 caught a real conviction, live, during its own verification.** The quiet
sweep printed six `INDETERMINATE:` lines naming
`w0-2-terminal-respec/specs/spec01.md` — a genuine concurrent analyst writing
while `manual-coverage.sh` was under test. **Pre-fix that was a FAIL convicting
an innocent gate.** I had called that false positive three times today and twice
blamed the wrong script; it is now a named, non-failing report.

**Both fixes were proved in both directions**, and the counterfactuals are
permanent gate lines rather than one-off runs — 6 new PASS lines, and
`gates/selftest.sh --selftest` went 6 → 12.

**Orchestrator error, found by this ticket and fixed:** I added `T.8` to
`plan.json` without a `gates/waves.tsv` row, and the registry check requires
every plan task to appear in a wave. That cascaded to 3 FAILs in `just gates`,
1 in `selftest.sh`, and made spec03's own `verify:` exit 1 — none of it this
node's doing, and the implementer proved so on an exact repo copy with only
that row added (sweep rc 0, 677 PASS). `T.8` is now in wave 3, its earliest
slot given deps `W0.2` (wave 0) and `T.1` (wave 2). `wave-status.sh --selftest`
is back to exit 0.

**One residue of the same design limit, recorded not fixed.** The HARD
(attributable) path set includes `.mi/docs/`, which a *lane* may legitimately
hold — `w0-2-terminal-respec` is writing `capabilities-terminal.md` and
`capabilities.md` right now, so a full sweep during that window still convicts
`audit-findings.sh`. The honest operational rule, learned repeatedly today: **do
not run the full sweep while implementers are writing.** Whether `.mi/docs/`
belongs in HARD or SOFT is a real question for the node that inherits S3.6's
frozen-board-snapshot work.

**Two things routed, not fixed:** `gates/tree-links.sh` now reports **99 broken
links across 99 files** and exits 1 (its wave is PENDING, so it does not gate) —
growing, because each new analyst repeats the `specs/`-relative-link mistake, so
it wants a convention fix rather than a link sweep. And `tests/shell-init.sh`
watches `$HOME/.config/nushell` wholesale, which holds the live
`history.sqlite3-wal` that the user's own shell rewrites at any moment — a
latent flake; narrowing to `.../help` fixes it. P.4's file.
