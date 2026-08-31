---
state: done
claim: 
priority: 18
est: 2.5h
actual: 30m
mode: afk
needs:
  - 06-help/02-help-command
verify: ""
origin: derived
---

# `help` finds its corpus only where `XDG_CONFIG_HOME` is exported at launch

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: H.2's implementer measured (2026-08-23) that `help.nu` addresses the
manual corpus through `$nu.default-config-dir`, which is a **launch-time
constant**. `env.nu:82` assigns `XDG_CONFIG_HOME`, but that runs too late to
move it — the identical lesson `$nu.history-path` already taught, recorded in
`history.nu`'s header. With no `XDG_CONFIG_HOME` exported *before* nushell
starts, the constant resolves to `~/Library/Application Support/nushell` on
macOS and the corpus is not found at all.

Why this is live rather than theoretical: the repo's own `wezterm.lua`
deliberately omits `set_environment_variables`, so nothing in what this repo
deploys guarantees the export. It works on the current machine only because
the *live* WezTerm config — the one being replaced — exports it. The rebuild
is therefore one deploy away from a `help` that cannot find its own manual,
and [`AGENTS.md`](../../../../AGENTS.md) makes `help` the thing an agent reads
*before* acting on this environment. A manual that silently resolves to an
empty directory is worse than one that is missing.

This node also closes the half of
[`06-help/02-help-command`](../../../06-help/02-help-command/prd.md) R9 that
is marked `[~]` rather than `[x]`. R9's marking half is proven — `help "F5
<digit>"` renders `mode: terminal (host-only — the terminal is outside a
capsule)` — but its **mounting** half was only ever proven against a scratch
root, never a real container, because H.2 has no capsule to run. The two are
one subject: whether `help` finds its corpus when launched anywhere other than
this machine's current terminal.

## Requirements
- [x] **R1** — Established by measurement, and the answer is a **third**
      candidate: `$nu.home-dir | path join ".config" "nushell" "help"`, the
      same `~/.config/nushell` literal `config.nu` uses to `source`
      `help.nu`, so renderer and corpus can never come from different trees.
      The four-shape table is in `help.nu`'s own THE CORPUS header. Both of
      the suggested candidates are traps. `$nu.config-path | path dirname`
      is wrong by construction: `config.nu` sources every module by a
      `~`-literal, so `nu --config <alt>/config.nu` still loads
      `$HOME/.config/nushell/help.nu` — proven with a marker `def` in each
      of two trees, and again in the gate, where that resolution renders the
      alt tree's marker topic while the fixed one does not. An export is
      wrong too: `env.nu:82` assigns `XDG_CONFIG_HOME` unconditionally, so
      it is a copy of `$nu.home-dir/.config` wherever `env.nu` ran and
      nothing at all where it did not. **No fallback chain**, because a
      fallback is what turns "not found" into "found somewhere wrong".
- [x] **R2** — Loud, in four places. `_help_dir` raises on a missing
      corpus directory; `_help_topics` raises on an absent, empty or
      zero-byte `topics.nuon`; `_help_corpus` raises on an absent surface
      file or an empty flattened entry list. Every message starts `help: `,
      names the resolved path, names `chezmoi apply` and names the
      `help --delegate <name>` escape hatch — `finder.nu:99`'s empty-decode
      raise and `capsule.nu:367`'s missing-Dockerfile message, applied to a
      read. The silent failure this closes was measured: `topics.nuon = []`
      rendered `Topics:` and `First keys:` with nothing under them, rc 0,
      empty stderr. The gate now carries that render as a counterfactual
      against a `help.nu` with the length guard defeated, so the guard is
      shown to be what stops it. The named trade stands and is written into
      `help.nu`'s header: with the corpus gone `ls --help` raises (rc 1)
      while `help --delegate ls` still exits 0.
- [x] **R3** — `tests/shell-help.sh` gained a third stage, `--noxdg`, on
      its own machine and its own runner `nu_c_noxdg` — `nu_c` untouched, so
      the export-present render stays available to compare against. 88
      checks now run where 60 did, 0 failed. Reverting `help.nu` to its
      pre-spec01 state makes the gate report **16 failed**; every one of
      them is in `--tree` or `--noxdg`, and `--hermetic` stays fully green,
      which is exactly the blind spot `nu_c`'s pinned export created. The
      new stage's isolation rule is honoured and proven: an export-absent
      `nu` writes to `$HOME/Library/Application Support/nushell`, so the
      epilogue asserts that directory absent beside the `~/.cache/nushell`
      leak check.
- [x] **R4** — R9 on
      [`06-help/02-help-command`](../../../06-help/02-help-command/prd.md)
      is corrected and closed. **Done by the orchestrator on this node's
      spec transition**, because the finding was that R9's premise is false
      rather than unproven: `help` cannot run inside a capsule at all — the
      dev image ships zsh and no nushell, and `capsule` mounts no config
      directory, both settled in `done` nodes. R9 now states the marking
      half, the corpus half, and that a capsule is out of the picture, and
      its box is `[x]`. The corpus half is this node's to deliver, and R1-R3
      below are what deliver it.
- [x] **R5** — It splits, and the line is drawn where measurement put it.
      **This node owns the corpus half**: wherever `help.nu` is sourced, it
      finds its corpus. The **launch half** belongs to
      [`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md),
      and no line in `help.nu` can reach it — a plain
      GUI `nu` with no exported `XDG_CONFIG_HOME` loads
      `~/Library/Application Support/nushell/config.nu`, that file does not
      exist, so **none** of this repo's nushell configuration loads,
      `help.nu` is never sourced, and `help` is nushell's builtin welcome
      text. Measured. The split is named in `help.nu`'s THE CORPUS header
      ("OUT OF THIS FILE'S REACH, ON PURPOSE") and in the Findings below.
      The terminal node's own row must be added by the orchestrator: it is
      `state: analyzing` under another agent, and an implementer may not
      write another node's folder.

## Acceptance
- [x] `help` renders the corpus with `XDG_CONFIG_HOME` unset in the launching
      environment — command, environment, and output quoted. Ran
      `/usr/bin/env -i HOME=<machine>/home PATH=/usr/bin:/bin nu
      --no-history --config <machine>/home/.config/nushell/config.nu
      --env-config <machine>/home/.config/nushell/env.nu -c 'help'`:
      `rc=0 stderrbytes=0`, and `help --all | length` returned `92`, which
      is the staged corpus's own entry count (`92`). The gate asserts the
      same thing per-run: `PASS  noxdg: 'help' exits 0 with nothing on
      stderr under a launch that exports no XDG_CONFIG_HOME (rc=0)`.
- [x] With the corpus directory renamed away, `help` raises rather than
      rendering empty. Output quoted: `missing rc=1 stdoutbytes=0` and

      ```
      Error: nu::shell::error

        x help: the manual's corpus directory /private/var/…/home/.config/
        | nushell/help is missing — run `chezmoi apply`; `help --delegate
        | <name>` still reaches nushell's own help
      ```

      `help --delegate ls` in that same state returned `delegate rc=0`, and
      `ls --help` returned `rc=1` — the named trade, not a surprise.
- [x] `help` renders byte-identically under a launch that exports no
      `XDG_CONFIG_HOME` and under one that does — `cmp` on the two
      captures. `cmp` reported no difference (`IDENTICAL`, 1259 bytes), and
      the gate holds it: `PASS  noxdg: the export-absent overview is
      byte-identical to the export-present one (1259 bytes)`.
      **Replaced 2026-08-23 by the orchestrator**; the original
      box asked for a render inside a running capsule, which is
      unachievable: the dev image has no nushell
      ([`01-capsule/02-dev-image`](../../../01-capsule/02-dev-image/prd.md)
      R1) and `capsule` mounts no config directory. A capsule cannot be the
      proof, so the proof is the launch shape that actually varies.
- [x] `bash tests/shell-help.sh` still reports 0 failed, so nothing regressed
      while the resolution moved: `CHECKS: 88 run, 88 passed, 0 failed` /
      `EXIT=0`, up from 60 checks.

## Out of scope
- Redesigning where the corpus lives. This is about addressing it correctly,
  not relocating it.
- `$nu.history-path`, which taught the same lesson and is already handled in
  `history.nu`. Cross-reference it; do not re-fix it.

## Findings (implementer, 2026-08-23)

**The correct resolution was a third candidate, not either of the two the
node offered.** Both suggestions fail, and they fail differently, which is
why the header comment in `help.nu` records the four-shape table rather than
just the answer. The launch-time constant is not found at all under the
deployed launch; the loaded config's dirname *is* found, in the wrong tree.
The second is the more expensive failure — it renders, exits 0, and describes
a different machine — and the gate now carries it as a live counterfactual
(`noxdg: counterfactual $nu.config-path-dirname renders the ALT tree's
marker`) rather than as a sentence.

**The launch half is real, is out of `help.nu`'s reach, and needs a row in
[`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md).**
Measured: `nu` launched with no `XDG_CONFIG_HOME` and no `--config` reads
`~/Library/Application Support/nushell/config.nu`, which does not exist, so
none of this repo's nushell configuration loads at all — `help.nu` is never
sourced and `help` is nushell's builtin welcome text. That node's R2 already
prescribes `set_environment_variables.PATH` for the same GUI-launch reason;
what it does not yet say is that the same block (or a `default_prog` that
names `--config ~/.config/nushell/config.nu`) is what makes the repo's
nushell config load in the first place. It is `state: analyzing` under
another agent, so this is handed to the orchestrator rather than written
there.

**`gates/waves.tsv` and `gates/manual/wave5.md` needed no change, confirmed
rather than assumed.** `waves.tsv:26` registers wave 5 as `… | external bash
tests/shell-help.sh`, with no stage argument, and the script's no-argument
default now runs `stage_tree; stage_hermetic; stage_noxdg` — so the new stage
is picked up by the existing row. `gates/manual/wave5.md`'s H.2 step is an
adversarial manual check of the `--help` delegation and says nothing about
stages, so it is unaffected.

**Why 60 checks were green over a live defect, stated as a rule.** `nu_c()`
pinned `XDG_CONFIG_HOME` on every run, so the hermetic stage could not
observe a launch-time constant at all. That is not a gap in the checks; it is
a gap in the *launch shapes* the gate could express. Proof that the hole is
closed: reverting `help.nu` to its pre-spec01 state now yields 16 failures —
and every one is in `--tree` or `--noxdg`, while `--hermetic` stays 100%
green, which is the blind spot displayed rather than described.

## Orchestrator note on R5, 2026-08-23

The implementer reported the launch half as still needing a node. It does not
— it was filed while this node was being specced, and the implementer read
[`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md)
before that edit landed. That node now carries:

- **R6** — nushell as `default_prog` with both config files named, recording
  that without it a GUI launch falls back to the login shell (`zsh` on this
  machine), so none of `04-shell` runs and there is no `help` at all.
- **R7** — `XDG_CONFIG_HOME` exported at launch, recording that
  `$nu.default-config-dir` is read from the launch environment and
  `$nu.history-path` otherwise leaves the managed tree.

So R5's split is complete and both halves are owned: the corpus half closed
here, the launch half by T.7, which is `claimed` and running. Nothing further
to file.
