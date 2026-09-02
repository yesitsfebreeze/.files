---
state: done       
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Provisioning — how the config reaches a machine

Purpose: This epic used to be "platform foundation", specced from
`capabilities.md`'s "Cross-platform dependency bootstrap" — a WezTerm-Lua
checker that installed zoxide/docker via brew or winget and stamped
`.cache/.bootstrap`. That was wrong twice over: winget is Windows-only (out of
scope), and the mechanism has already been **superseded** on the live machine.
The real deployment layer is the chezmoi source at `/Users/feb/dev/.files`,
inventoried in
[`capabilities-provisioning.md`(../../../docs/capabilities-provisioning.md):
`install.sh` (233 lines, at the repo root) installs the tool set — a
package-manager batch, a GitHub-release ladder for the tools distros do not
carry, a few cargo/git/npm builds — and calls `chezmoi apply` **last**, which
runs `run_after_generate-shell-init.sh`, the only script left in `home/`. That
script generates the starship/zoxide/television init files that the shell
merely sources, and it is load-bearing for
[`04-shell/01`](../04-shell/01-core-config/prd.md), which requires shell launch to
do zero setup work.

**Re-specced 2026-08-21.** This paragraph used to describe a three-stage
chezmoi script pipeline around a 559-line renderer over a YAML package model.
Commit `8fe3a71` (2026-08-19, *"Simplify dotfiles: drop theme/pi/data-driven
machinery, minimal chezmoi, one plain install.sh"* — 2490 deletions) removed
all of it. The shell-init generator survives that commit intact, so the
`04-shell/01` dependency above is unchanged.

Goal: One deploy path: clone, `./install.sh`, working machine — idempotent,
so a re-run is a no-op, and cheap to extend, so adding a tool means editing
one list in one script.

## Requirements

**Architecture invariants**

**I1** — **Apply-time, not launch-time.** Anything that costs
milliseconds at shell start is generated during `chezmoi apply` instead.
The shell only `source`s.

**I2** — **Idempotent by construction.** Every step is `command
-v`-guarded, so re-running is safe and cheap. (*Narrowed 2026-08-21:
the guard list used to name two chezmoi script-stage mechanisms
alongside `command -v`; `8fe3a71` deleted both, and the guard is what
survives — it is also exactly what `install.sh` relies on.*)

**I3** — **Tools are data.** ***Withdrawn 2026-08-21*** (user decision)
— this asserted that the package set lives in a chezmoi data file and
the installer is a renderer over it. Commit `8fe3a71` (2026-08-19)
deleted the data file and the renderer; rebuilding them would be
porting a capability its owner had just removed by hand. Marked
withdrawn in place rather than deleted, because I1–I4 are cited by
number — including by this epic's own acceptance boxes — and a
vanished I3 reads as a numbering error.

**I4** — **Never fail the whole apply.** One unavailable package warns
and continues; a partial machine beats an aborted one. With I3 gone
this is the invariant the epic most depends on.

## Acceptance

- [ ] **End to end on a scratch target — unmet, and it needs a machine this
      one is not.** clone → `./install.sh` → a machine on which every tool the
      other five epics assume resolves on `PATH`, with no manual step between
      the clone and the working shell.
      *(b) — genuinely unmet: every LEG is proven and the composition is not;
      the box itself names the missing machine. No scratch-target run has
      happened.*

      Every LEG is proven and the composition is not: `bash
      tests/provisioning.sh` (rc 0) holds the installer's shape and its
      required set, `bash tests/deploy-skeleton.sh` (63 PASS) proves a fresh
      `chezmoi init` + `apply` produces the tree and that a second apply
      reports nothing, and `bash gates/nvim-seed-registry.sh` (30 PASS) proves
      the mason seed. What no gate on a provisioned machine can do is the
      FIRST run on a machine that has none of it — registered as a human
      check in [`gates/manual/wave1.md`](../../gates/manual/wave1.md),
      unrun.
- [x] A second run immediately after the first reports zero changes: a second
      `install.sh` on a provisioned machine installs nothing, and
      `run_after_generate-shell-init.sh` re-runs to byte-identical output.
      (I2)

      Observed 2026-08-30, and by accident, which makes it a better reading
      than a designed one: a real (non-dry) `install.sh` run on this
      already-provisioned machine reported "already installed and up-to-date"
      for every brew formula it touched, installed nothing and exited 0. The
      structural half is `bash tests/provisioning.sh` — every step
      `command -v`-guarded — and the apply half is `deploy-skeleton`'s
      `R3 second apply --verbose prints nothing but always-run scripts`, with
      a counterfactual proving a drifted managed file still reports under the
      same narrowed command.
- [ ] **Forward-looking, and correctly still open.** Adding one tool to the
      base is a single edit to `install.sh`'s package
      list, and the next run installs it. Checked by carrier, not by diff:
      after adding the tool, `grep -rl <tool>` across the repo names
      `install.sh` and nothing else, so the package list is its only mention.
      `git diff` cannot answer this — `install.sh` is untracked
      (`git ls-files --error-unmatch`, 2026-08-23), so a diff over it is
      silent and the box would pass without observing the edit. This is a
      forward-looking design invariant, read as the contract when
      `05-platform` is implemented; an implementer reaching for `git diff`
      here measures nothing. (I2 — this box used to prove I3, which is
      withdrawn.)
      *(b) — a forward-looking invariant, correctly still open: it describes
      the next tool addition, which has not happened. The carrier check is
      specified, not executed.*
- [x] Apply survives a hostile machine: with one package made unresolvable,
      the run still exits 0 and the remaining tools are installed. (I4)

      `bash tests/provisioning.sh` (rc 0, 2026-08-30), and it is simulated
      rather than argued: `INSTALL_DRY_FAIL=install` makes `run()` return 1
      for any command whose argv carries that word, and the stage asserts
      the run **still exits 0**, emits at least one `!!` warn line (27 of
      them), and **still reaches `chezmoi apply`** — not merely non-fatal,
      but all the way to §4. The `set` line is asserted to carry `u` and
      `o pipefail` and deliberately NOT `e`, which is the mechanism that
      makes it true.

## Out of scope
- The legacy `conf/bootstrap.lua` checker and its `.cache/.bootstrap` stamp.
  Superseded; not ported.
- The legacy `~/.files` symlink deployer (`deploy.disabled`, `index`,
  `deleted`) — already `DO NOT PORT`.
- Windows of any kind, including the live
  `run_after_mirror-config-to-windows.sh`.
- `wp-stat-overlay` provisioning and the published docs site (`DEFER`).

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
