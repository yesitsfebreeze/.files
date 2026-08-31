---
state: done
claim: 
priority: 33
est: 1.5h
actual: 10m
mode: afk
needs:
verify: ""
origin: derived
---

# Every interactive shell start prints `Command 'ollama-host' not found`

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `home/dot_config/nushell/env.nu:168` runs `^ollama-host` guarded by
`$nu.is-interactive`. The guard is on interactivity, not on the binary
existing — and `complete` does **not** catch a missing external. T.7's
analyst reproduced it in a spawn probe: on any machine without
`~/.local/bin/ollama-host`, every interactive nushell start prints
`Command 'ollama-host' not found`.

**This repo does not deploy that binary.** `git ls-files home` carries no
`dot_profile` and nothing under `.local/bin`, so the file exists on this
developer's machine and nowhere the rebuild puts it. The failure is therefore
guaranteed on a fresh provision — which is precisely the case the rebuild
exists to serve, and a first-run error message on every prompt is the worst
possible first impression of the new configuration.

Found while specifying [`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md),
not by the shell lane's own gates — `env.nu` belongs to
[`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md), which is
`done`. The same analyst noted a second reason the shell gates could not see
it: this developer's `~/.profile` sources `~/.cargo/env`, also undeployed, so
any login-shell PATH check run with the real `HOME` passes for the wrong
reason.

## Requirements
- [x] **R1** — An interactive start on a machine with no `ollama-host`
      prints nothing. Guard on the binary resolving, not on interactivity
      alone — `which` returning empty is the check `complete` cannot make.
- [x] **R2** — The behaviour when the binary *is* present is unchanged.
      Whatever `OLLAMA_HOST` gets set to today it still gets set to; this is
      a guard, not a redesign.
- [x] **R3** — The reason lands in the comment: `complete` does not catch a
      missing external, so a `^cmd | complete` idiom is not a presence
      check. That is the hard-won part, and the same idiom appears elsewhere
      in this tree.
- [x] **R4** — **Census `env.nu` and its siblings for the same idiom.** Any
      other `^binary` invoked at startup behind a guard that is not "does it
      exist" has this defect. List them with their line numbers and report;
      each is its own node.
- [x] **R5** — The gate covers it with the binary **absent**, in
      `stage_hermetic`, on its own machine with the poison stub deleted.

      **Premise corrected 2026-08-23 by the orchestrator — I had the reason
      wrong, and the truth is more useful.** This requirement first said the
      shell gates run with the developer's real PATH in some stages. They do
      not: *every* stage isolates PATH completely —
      `nu_c`/`nu_pty`/`nu_pty_e` run
      `/usr/bin/env -i … PATH="$M/bin:/usr/bin:/bin"`
      (`tests/nushell-core.sh:278,288,298`) and `cz()` the same (`:876`), so
      `~/.local/bin/ollama-host` was never reachable.

      What made the binary resolve was **the fixture**. `mk_machine`
      installs a poison stub (`:269`) and `stage_apply` another (`:917`), and
      `tests/shell-listing.sh:301-303` states the reason outright: *"an
      interactive shell probes ollama-host, and a MISSING external inside its
      `do|complete` is a shell error that takes the config down, so the stub
      must exist"*. Six sibling gates do the same. So the gates knew about
      this defect and worked around it, in writing, without anyone filing it
      — which is a more interesting failure than a PATH leak. The second half
      of the blindness: `stage_apply` reaches the deployed `env.nu` only
      through `nu_c`, which never enters an interactive branch.

      Therefore the check has exactly one home, and the stub must be
      **deleted** there for it to be able to fail.

## Acceptance
- [x] An interactive nushell start under a scratch `HOME` with no
      `ollama-host` on PATH produces empty stderr — command and output
      quoted.
- [x] The same start with a stub `ollama-host` on PATH still sets
      `OLLAMA_HOST` to what it set before, quoted both ways.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, and the new check goes
      red when the guard is reverted — the counterfactual, quoted.
- [x] The R4 census is in the report.

## Out of scope
- Deploying `ollama-host` or anything else into `~/.local/bin`. Whether the
  rebuild should ship it is a scope question for
  [`05-platform`](../../../05-platform/prd.md), not this correction; this
  node makes its absence silent.
- `~/.profile` and `~/.cargo/env`. Recorded above as why the shell gates
  could not see this, and not this node's to fix.

## Orchestrator note, 2026-08-23

One discrepancy the implementer flagged rather than buried: it re-measured the
guard's cost at 0.61-1.0 ms per 100 absent lookups (~6-10 µs each) against the
analyst's 0.49 ms (~5 µs). Same order of magnitude, and the conclusion — three
orders of magnitude under the ~11 ms spawn — holds either way. Its machine was
carrying two parallel implementer sessions, which is the likely cause. The
comment in `env.nu` records the re-measured figure; the gate's OH.5 cost check
passes against it.
