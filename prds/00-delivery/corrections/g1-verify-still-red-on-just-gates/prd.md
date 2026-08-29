---
state: blocked
priority: 14
est:
mode: afk
needs:
  - 00-delivery/quiet-board-sweep
verify: "just gates"
origin: derived
from: 00-delivery/verification-gates
complexity: 40
blast-radius: mid
---

# `G.1` is `done` and `just gates` still exits 1 — five reds, none of them about link walking

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`00-delivery/verification-gates`](../../verification-gates/prd.md)
(`G.1`) is `state: done` and carries `verify: "just gate-selftest && just
gates"`. **The second half fails.** Found 2026-08-28 while working
[`tree-links-selftest-stale-pin`](../tree-links-selftest-stale-pin/prd.md),
which fixed the *first* half — `just gate-selftest` now exits 0 in a quiet
window, and the failure moved rather than cleared.

`just gates` → `sweep rc=1`, **4813 PASS / 5 FAIL**, on two ARMED waves:

**wave 1, `tests/managed-config.sh`** — reproduced by the orchestrator,
`EXIT=1`:

```
FAIL  surface: home/ holds only declared entries (undeclared: dot_local)
FAIL  surface: home/dot_config/ holds only declared tools (undeclared: litellm)
```

Both paths landed in **`0b77a71`** (`04-shell/10-litellm-launcher`,
2026-08-28) without the gate's declared surface being updated alongside. The
declaration is at `tests/managed-config.sh:340`.

**wave 2, `tests/shell-init.sh`** — reproduced, `EXIT=1`:

```
FAIL  apply: S1.10 the hand-written ~/.config/television/config.toml is
      byte-identical after the apply
FAIL  apply: R4 chezmoi managed lists none of the three generated files
```

**This is the same node, the same day, as `waves-registry-missing-s10`, and
the same commit.** `0b77a71` landed `S.10` across 36 files, skipping the board
transitions — "code now, PRD after" by its own Provenance — and left **two**
gates unmaintained: the wave registry, corrected already, and the managed
surface, corrected here. That is worth writing down once rather than
rediscovering a third time.

## Requirements
- [x] **R1** — `tests/managed-config.sh`'s declared surface gains `dot_local`
      and `litellm`, **or** the two paths are shown not to belong under
      `home/` and are moved. Decide which by reading what they are, not by
      whichever makes the gate green — a declared-surface gate exists to make
      an undeclared path a decision, and silently declaring it is how the
      decision gets skipped a second time.
      **Answered below** ("R1 — the argument, both directions"). Both are
      declared, each narrowly, and the one part that is genuinely another
      node's call is routed there rather than settled here.
- [x] **R2** — `tests/shell-init.sh`'s two `apply:` reds are diagnosed and
      fixed, or shown to be a fixture defect rather than a real regression.
      — both are fixture defects (the analyst's pass, recorded above), and the
      replacements are green: `bash tests/shell-init.sh --apply` `EXIT=0`,
      45 PASS / 0 FAIL, with
      `PASS  apply: S1.10 the generator left ~/.config/television/config.toml exactly as chezmoi wrote it`
      and `PASS  apply: R4 chezmoi managed lists none of the three generated files under .cache/nushell/init/`.
      Each replacement has a counterfactual that drives it red — see spec01.
      **Nothing overwrites a user's television config.**
- [x] **R3** — `just gates` exits 0, tally quoted not asserted, or every
      remaining red is named here with evidence that it is a different fault.
      — **`just gates` does not exit 0**, so R3 closes on its second limb:
      `sweep rc=1`, **3550 PASS / 43 FAIL**, 23 of them armed wave gates. Every
      one is named and attributed below, and **none is this node's work**. The
      two piles this node was filed for are gone.
- [x] **R4** — Once green, **`G.1`'s own `verify:` is run in full** and its
      state confirmed. If `just gate-selftest && just gates` still does not
      pass, `G.1` is not `done` and this node says so rather than leaving a
      closed PRD with a broken proof.
      — Run in full, both halves. **It does not pass.** `just gate-selftest`
      → `EXIT=1`, 45 PASS / 3 FAIL; `just gates` → `sweep rc=1`, 3550 PASS /
      43 FAIL. So **this node says it: `G.1`'s `verify:` is red, and `G.1`
      should not be read as proven on this tree.** What the node also says,
      because it is equally true, is that **no red on either half traces to
      `G.1`'s subject or to this node** — see below. The state is not this
      node's to write; the evidence for whoever writes it is here.
- [x] **R5** — Check the rest of `0b77a71`'s 36 files for a third unmaintained
      gate. Two were found by accident, in one day, by two different nodes.
      Enumerate what that commit touched rather than checking the two already
      known. **Enumerated below. No third gate traces to `0b77a71` — but a
      third stale gate of exactly that class exists on the board, from a
      different commit, and this pass found and fixed it.**

## R1 — the argument, both directions

The question was put and never answered: *do `dot_local` and `litellm` belong
under `home/` at all?* Answering it needs the two treated separately, because
they fail for different reasons if they fail.

**`dot_local` belongs, and the case against it is the stronger-sounding one.**
`0b77a71` deploys five hand-written commands — `cll`, `litellm-env`,
`litellm-gen-config`, `litellm-up`, `llm-quota`. The case *for* is that
`~/.local/bin` is the only PATH-visible target this rebuild has, and that was
checked against the generator rather than assumed:
`grep -n 'local/bin' home/run_after_generate-shell-init.sh` returns
`65:export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"`. Nothing under
`home/dot_config/<tool>/` is on any PATH. A command the user types has one
honest place to live, and moving these out of `home/` would mean either
un-deploying them or inventing a second deploy mechanism beside chezmoi.

The case *against* is not rhetorical: `dot_local` is named **by the census's
own comment** as an example of the wholesale port of the legacy source root
that check 1 exists to catch, beside `dot_assembly`, `dot_bash_profile` and
`dot_pi` — all of which are in `FORBIDDEN`. Admitting the root admits
`share/`, `state/` and `lib/` with it, and the legacy tree has all three.
That objection is answered by narrowing rather than by dismissing it:
`DOT_LOCAL_TOP="bin"` plus check 1b admits `bin` and nothing else, so the
wholesale port this list exists to stop still trips. The narrowing is proved
in both directions by `--selftest`, which plants `home/dot_local/share/` and
watches the predicate report it, then removes it and watches it go quiet.

**`litellm` belongs under `home/`, but it does not belong in R2's nine, and
this node does not have standing to put it there.** `~/.config/litellm/` is a
tool's config directory, which is exactly the shape
`05-platform/01-deploy-mechanism/managed-config` R2 describes — so the honest
move is to declare it, not to move it out. But R2 enumerates **nine** names,
and growing that list is that node's decision. The file already has the
mechanism for precisely this case: `capsule` sits in `SURFACE_PENDING` under a
note saying it is allowed and not endorsed, and raised with the epic owner.
`litellm` is the second such name and takes the same route.

So the residual question — *should `litellm` become R2's tenth name?* — is
**open, on the record, and routed to `05-platform/01-deploy-mechanism/managed-config`**,
which is a different thing from being skipped. What this node refused to do is
the thing R1 warned about: type `litellm` into `SURFACE` because that is what
makes the gate green.

One thing `litellm` turned up that neither branch of R1 anticipated: its one
file did not need a different *home*, it needed a chezmoi **attribute**. See
spec03 — that is the live bug on this node, and it was re-measured on
2026-08-29 rather than carried on the analyst's word.

## R5 — `0b77a71`'s 36 files, enumerated

`git show --name-status --format='' 0b77a71` gives **36 files: 8 deliverables
and 28 board documents.** The board documents cannot leave a gate stale —
`gates/tree-links.sh` and `gates/wave-status.sh` both cover them and both are
green. So the sweep is over the eight:

| # | file | gate that had to notice | outcome |
|---|---|---|---|
| 1 | `home/dot_config/litellm/config.yaml` (A) | `tests/managed-config.sh` `SURFACE` | **stale — known**, fixed by spec02; and it turned out to need `create_` too (spec03) |
| 2 | `home/dot_config/nushell/config.nu` (M) | `gates/nushell-module-staging.sh` | green — the module list is **derived** from config.nu's own `source` lines, so it cannot go stale |
| 3 | `home/dot_config/nushell/litellm.nu` (A) | same | green, `rc=0`; the gate names `shell-litellm` explicitly as a documented direct-source exception |
| 4–8 | `home/dot_local/bin/executable_{cll,litellm-env,litellm-gen-config,litellm-up,llm-quota}` (A) | `tests/managed-config.sh` `HOME_TOP`; `tests/deploy-skeleton.sh` | `HOME_TOP` **stale — known**, fixed by spec02. `deploy-skeleton` keeps no hand-kept source surface (`grep -n dot_local` returns nothing) and is green, `EXIT=0`, 63 PASS |
| — | `tests/shell-litellm.sh` (A) | `gates/waves.tsv` registry | **stale — known**, already fixed by `waves-registry-missing-s10`; `waves.tsv:26` now carries `external bash tests/shell-litellm.sh` in wave 5 |

Searched for any further hand-kept list the commit should have grown:
`grep -rln 'llm-quota\|litellm-up\|litellm-env\|litellm-gen-config' gates/ tests/ justfile`
returns only `tests/shell-litellm.sh` and `tests/managed-config.sh` — the two
already accounted for. `gates/nushell-module-staging.sh`'s `GATE_FLOOR` is a
hand-kept list of gate names, but it is documented as a **floor for the derived
list, never a substitute**, so a new gate absent from it is not drift.

**Answer: no third unmaintained gate traces to `0b77a71`. The count is two,
and it is now complete.**

**But the class is not exhausted, and that is the finding.** Running spec01's
verify on this pass turned up a third stale gate of exactly this shape, from a
*different* commit landed the same morning:

```
FAIL  apply: I2 chezmoi status is empty once the always-run script line is
      removed (got:  R seed-mason-registry.sh)
```

`5e7934c` (2026-08-29, "C.4 harness + R7's seeder") added
`home/run_after_seed-mason-registry.sh`, a **second** always-run script.
`tests/shell-init.sh`'s `S3.10` filtered chezmoi status with
`grep -v 'generate-shell-init\.sh'` — one literal name, correct on the day it
was written — so a correctly-added script read as a regression. Fixed in this
node's own footprint by deriving the set from the tree
(`always_run_targets()`); full write-up in spec01.

Three for three, the mechanism is the same: **a hand-kept list standing in for
a property of the tree.** The wave registry, the managed surface and now the
status filter all failed the same way, and all three fixes were the same
move. That is worth more than the count R5 asked for.

## R3 — the sweep, 2026-08-29, on a tree three sessions were writing

Run detached, `just gates` → `══ sweep rc=1`, **3550 PASS / 43 FAIL**. The
tally is quoted, not asserted, as R3 asks.

**The tree was live while it ran, and that is not a caveat — it is most of the
result.** A second session (`dotfiles-ef`, `prds/07-multiplexer`) was adding
files under `home/`, `tests/` and `prds/` throughout, and the sweep's own
guards say so in their own words.

**The two piles this node was filed for are closed.** Neither
`FAIL apply: S1.10 …` nor `FAIL apply: R4 chezmoi managed …` appears anywhere
in the sweep log, and neither does either `surface:` red the node's Purpose
quotes for `dot_local` and `litellm`.

Of the 23 armed wave-gate reds:

**18 — every nvim gate, `exited 127`.** One cause, and the pairing is exact:
`grep -c 'persistence.nvim is absent'` = 18, `grep -c 'exited 127'` = 18, each
`PROBE-ERROR` on the line immediately above its own `FAIL`. The message is
`PROBE-ERROR: /Users/feb/.local/share/nvim/lazy/persistence.nvim is absent —
ASSUMPTION MISSING, the seed source is the live clone`. The other session added
`home/dot_config/nvim/lua/plugins/session.lua` declaring `persistence.nvim`,
which is not yet cloned onto this machine, so every nvim gate dies in probe
preflight before running a check. Not this node's footprint, and not a code
fault: the gates are refusing to measure against a missing assumption, which
is what they are supposed to do.

**1 — `tests/managed-config.sh exited 1`**, on
`FAIL surface: home/dot_config/ holds only declared tools (undeclared: tmux)`.
`home/dot_config/tmux/` is the other session's untracked directory. Re-measured
serially after the sweep: same single red, `EXIT=1`, 65 PASS. Against a clean
`git archive HEAD` tree with this node's footprint overlaid the same gate is
`EXIT=0`, **67 PASS / 0 FAIL**, every `surface:` line `<none>`. The gate is
working exactly as designed — an undeclared path is a decision, and this one
is the other session's to make.

**1 — `tests/shell-init.sh exited 1`**, and this one needs saying plainly.
Its **only** red was
`FAIL the gate wrote nothing outside its scratch (sha256 over prds, docs,
gates, tests, home, install.sh)`, on `changed: /Users/feb/dev/dotfiles/tests`.
All 100 substantive checks passed inside that same run, the S1.10 and R4
replacements among them. This is the artifact
[`a-concurrent-lane-trips-the-scratch-guard`](../../../memos/a-concurrent-lane-trips-the-scratch-guard.md)
describes — **and I cannot rule myself out as the writer**: I edited
`tests/shell-init.sh` (stripping one trailing space) while the sweep was in
flight, which is precisely the mistake the memo exists to explain and I made it
anyway. Re-measured serially afterwards with nothing else writing:
`bash tests/shell-init.sh` → **`EXIT=0`, 100 PASS, 0 FAIL**, ending
`PASS — shell-init generation holds, and nothing real was written`.
**Do not edit the repo while the sweep runs** — the guard cannot tell your
editor from a misbehaving gate.

**3 — `gates/{tree-links,manual-coverage,retired-phrases}.sh exited 1`**, all
on the other session's content:

- `retired-phrases.sh` —
  `FAIL RP7 CARRIER prds/memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md
  carries \`the terminal owns the palette\``. That memo is **untracked**, written
  by the other session minutes earlier.
- `manual-coverage.sh` —
  `FAIL boxes: no checklist box is ticked in the repo (ticked:wave4.md wave6.md )`,
  about `gates/manual/`, another lane's human checks.
- `tree-links.sh` — explicitly out of scope for this node (see Out of scope);
  it is [`tree-links-selftest-stale-pin`](../tree-links-selftest-stale-pin/prd.md)'s,
  and its red arrives with the other session's new `prds/07-multiplexer/` tree.

The meta-gate's four `contract: … wrote nothing outside its scratch` reds are
the same artifact again, and the gate says so itself: three different,
unrelated gates were each blamed for the identical
`changed: /Users/feb/dev/dotfiles/tests/tmux-session-and-windows.sh`, under
three printed `INDETERMINATE:` lines. A file none of them touches, moving
between three of them — the memo's exact tell.

One red is a **fourth instance of this node's own finding**, and is left for
its owner rather than fixed here:
`FAIL registry: every script under tests/ is named by a row (unreferenced:
capsule-recents-gui.sh nvim-session.sh tmux-session-and-windows.sh)` — the
wave registry stale again, against three test files outside this footprint.

## R4 — `G.1`'s verify, run end to end

`verify: "just gate-selftest && just gates"`. Both halves were run. **Neither
passes, and `&&` means the pair does not either.**

**First half — `just gate-selftest` → `EXIT=1`, 45 PASS / 3 FAIL**, three reds,
all the same shape and none this node's:

```
FAIL  contract: tree-links.sh accepts --selftest and exits 0 (rc 1)
FAIL  contract: manual-coverage.sh accepts --selftest and exits 0 (rc 1)
FAIL  contract: wave-status.sh accepts --selftest and exits 0 (rc 1)
```

- `tree-links.sh` is this node's declared Out of scope.
- `manual-coverage.sh` is red on `gates/manual/` checklist boxes, another lane.
- `wave-status.sh --selftest` run on its own gives
  `FAIL baseline: the real registry validates against a board copy` — the wave
  registry, unreferenced against `capsule-recents-gui.sh`, `nvim-session.sh`
  and `tmux-session-and-windows.sh`, all outside this footprint.

Worth recording for the next reader: this run's **nine** `wrote nothing outside
its scratch` checks were **all green**. The sweep's four reds on that same
check, thirty minutes earlier, were therefore concurrency and not code — the
memo's claim, reproduced by simply running it again with less traffic.

**Second half — `just gates` → `sweep rc=1`, 3550 PASS / 43 FAIL.** Triaged
above under R3.

**The finding for whoever settles `G.1`'s state.** `tree-links-selftest-stale-pin`
fixed the first half and this node fixed the second, and both are *fixed*: the
five reds this node was filed for are gone, and every red now standing was
introduced by lanes that landed after those nodes ran. `G.1`'s verify is a
**whole-repo** command, so it can only ever be green in a quiet window — it
reports the health of the tree, not of `G.1`. Judging `G.1` by it on a tree
three sessions are writing is judging it by other people's work in flight. That
is not an argument for calling `G.1` proven; it is an argument that this verify
needs re-running serially, once, when the board is quiet, and that whoever does
that gets to write the state.

## Acceptance
- [ ] `just gates` exits 0, its PASS/FAIL tally quoted. — **NOT MET, and left
      open deliberately.** The tally is quoted (`sweep rc=1`, **3550 PASS / 43
      FAIL**) but the exit is 1, so the box cannot be ticked as written and a
      tick would be a false record. What is true is the weaker claim R3 allows
      and this node proved: **not one of the 43 reds is this node's work**, the
      five it was filed for are gone, and the two gates in its footprint are
      green when measured serially — `tests/shell-init.sh` `EXIT=0`, 100 PASS
      / 0 FAIL, and `tests/managed-config.sh` `EXIT=0`, 67 PASS / 0 FAIL on a
      clean `HEAD` tree. Closing this box needs one serial sweep in a quiet
      window, which is a scheduling act, not more work on this node.
- [x] `G.1`'s `verify:` runs end to end and its result is recorded in this
      node, whatever it is. — run end to end, both halves; the result is red
      and is recorded above under R4 with each of the six distinct causes
      attributed. `just gate-selftest` `EXIT=1` (45 PASS / 3 FAIL),
      `just gates` `rc=1` (3550 PASS / 43 FAIL).
- [x] R5's sweep of `0b77a71` is written down with a count, including "no
      third gate" if that is the answer. — written up above with the full
      36-file enumeration (8 deliverables, 28 board documents) and a per-file
      table. **The answer is "no third gate" from that commit; the count is
      two, and it is complete.** A third of the same class was found from a
      different commit (`5e7934c`) and fixed, and a fourth is standing in the
      wave registry against another lane's files.

## Out of scope
- `just gate-selftest`, the first half of `G.1`'s verify. That is
  [`tree-links-selftest-stale-pin`](../tree-links-selftest-stale-pin/prd.md)
  and it is claimed.
- The concurrency artifact in `gates/selftest.sh`'s sha256 window, recorded in
  [`a-concurrent-lane-trips-the-scratch-guard`](../../../memos/a-concurrent-lane-trips-the-scratch-guard.md).
  A red naming a file the gate has no business with is that, not this.

## Analyst pass, 2026-08-28 — R2 answered, and it is the answer that matters

**R2: both `apply:` reds are fixture defects. Nothing overwrites a user's
television config.** Established by running `bash tests/shell-init.sh --apply`
from `git worktree` copies at three commits, not by reading the code:

| tree | `S1.10` | `R4 chezmoi managed` |
|---|---|---|
| `2714042` — the commit that ADDED this gate | FAIL | PASS |
| `0b77a71~1` — before the litellm node | FAIL | FAIL |
| `HEAD` | FAIL | FAIL |

`S1.10` wrote a sentinel into `$S/home/.config/television/config.toml`, called
it "hand-written", and asserted it byte-identical after an apply — but
`home/dot_config/television/config.toml` is a **managed source file**, so that
target is a managed target and `chezmoi apply` restores it *correctly*. The
check has been red since the day it was written and **could never have been
green**. The real failure it names — the `run_after` generator's `tv init nu`
clobbering the file — is untested by it, and is separately proven green
against the real `tv` by the `--live` stage's `S3.17`.

`R4`'s pattern was the unanchored `(starship|zoxide|television)\.nu` matched
against all of `chezmoi managed`; the single line it returns is
`.config/nushell/zoxide.nu`, the zoxide **nushell module** landed legitimately
by `04-shell/03-zoxide` at `35e0fb4`. A basename collision outside the init
directory is not what R4 claims — the claim is that nothing under
`.cache/nushell/init/` is managed.

**Neither red was caused by `0b77a71`.** This node's Purpose implied both piles
shared that cause; only the `managed-config.sh` half does. Corrected here
rather than left standing.

**The `create_` finding, which is the live bug on this node.**
`home/dot_config/litellm/config.yaml` shipped at `0b77a71` as a plain managed
file while `litellm-gen-config` rewrites the deployed target at run time
(`04-shell/10` R9), and `rr` is `chezmoi update --force` (`config.nu:119`).
Measured on a scratch apply: apply → regenerate → `chezmoi status` reports
`MM .config/litellm/config.yaml` → apply → **the regenerated routes are gone**.
Renamed to `create_config.yaml` — chezmoi's `create_` attribute, so the
deployed target keeps its name — the same fixture reports a CLEAN status,
keeps the regeneration across an apply, and still re-creates the file when it
is deleted, so a fresh machine still gets a baseline.

Rather than fix the instance, `tests/managed-config.sh:474-492` gains a general
assertion: **every source file that declares itself generated must carry
`create_`**, with the predicate read from the file's own first line, because
the generator writes that header and so it cannot go stale behind a rename.

**Three specs, complexity 30 + 25 + 30.** The analyst was killed twice by
infrastructure — a stream watchdog, then the machine sleeping — after writing
all three specs and before returning its verdict. The specs are on disk with
their boxes open, which is the correct shape for an analyst; `specced` is
written here by the orchestrator on the files rather than on the report, per
the rule that a transition is confirmed on disk and never taken on a worker's
word.

**Still owed, and not to be closed on this pass:** R5's sweep of `0b77a71`'s
36 files for a third unmaintained gate, and R1's argument for whether
`dot_local` and `litellm` belong under `home/` at all. Both are named in the
specs' open boxes; neither has been answered, and neither is assumed.
