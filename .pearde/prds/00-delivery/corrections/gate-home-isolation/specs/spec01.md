---
spec: 01
node: 00-delivery/corrections/gate-home-isolation
task: W0.9
covers: R1, R2, R5
verify: "F=$(mktemp -d); mkdir -p \"$F/.config/chezmoi\"; cp ~/.config/chezmoi/chezmoi.toml \"$F/.config/chezmoi/\"; printf '[user]\\n\\tname = P1 gate\\n\\temail = p1-gate@example.invalid\\n[init]\\n\\tdefaultBranch = main\\n' > \"$F/.gitconfig\"; /usr/bin/env HOME=\"$F\" P1_GUARD_CFG=\"$F/.config/chezmoi/chezmoi.toml\" bash tests/deploy-skeleton.sh && [ ! -e \"$F/.cache/nushell\" ]"
---

# spec01 — pin `HOME` in `tests/deploy-skeleton.sh`

Goal: `bash tests/deploy-skeleton.sh` must not be able to write into the home
directory of the machine it runs on. Today it does: every run creates a real
`~/.cache/nushell/init/` with three files.

**Files this spec may edit — one file, nothing else:**

- `tests/deploy-skeleton.sh`

`tests/managed-config.sh` and `gates/lib.sh` are spec02's. Do not touch them
here.

## What was measured, so you do not rediscover it

All figures taken 2026-08-21 on this machine by the analyst, real `~` restored
to its exact pre-run state afterwards (`~/.cache/nushell` did not exist before
and does not exist now).

| run | result |
|---|---|
| `bash tests/deploy-skeleton.sh`, repo as-is | exit 0, **60 PASS / 0 FAIL**, and `~/.cache/nushell/init/{starship.nu,zoxide.nu,television.nu}` created at **2280 / 1966 / 1809** bytes |
| the same run, all other real paths | byte-identical. The *only* drift in `~` was the new `.cache/nushell` |
| `cz()` pinned, `--apply` | clean |
| `cz()` pinned, `--push` | clean |
| `cz()` pinned, `--cutover` | **still creates `~/.cache/nushell`** |
| both sites pinned, full run | exit 0, **60 PASS / 0 FAIL**, `~/.cache/nushell` absent |

**The single most important finding, and it is not in the PRD:** R1 names
`cz()`, and `cz()` alone does **not** fix this node. With `cz()` pinned the
full gate still ends 60 PASS / 0 FAIL *and still writes the user's home* — the
`--cutover` stage reaches chezmoi through a **second** invocation site, the
PATH shim it writes at `$S/bin/chezmoi`, which carries the five flags and no
`HOME`. A fix that stops at `cz()` closes this node while the defect is still
live. Both sites, or nothing.

### The counting rule for the 60

`/usr/bin/grep -c '^PASS'` = 60. That is 59 `chk` lines plus the script's
final `PASS — the deploy skeleton holds…` summary line. `grep -c '^PASS  '`
(two spaces, `chk` lines only) = 59. R5's floor is the `^PASS` figure, 60.
Do not "fix" a count that was never wrong.

## The rule this node exists to establish

Two halves. Neither is sufficient alone, and both were learned by damaging
this machine:

1. **`HOME` does not isolate chezmoi.** A scratch-`HOME` `chezmoi init
   --force` rewrote the real `~/.config/chezmoi/chezmoi.toml` and repointed
   this machine at a throwaway repo. Fixed by passing `--config`,
   `--config-path` (init only), `--destination`, `--persistent-state` and
   `--cache` explicitly. This file already does that.
2. **`--destination` does not isolate a `run_` script's `$HOME`.** Those flags
   bound where chezmoi *writes*. They do not bound what a script chezmoi
   *runs* inherits. `home/run_after_generate-shell-init.sh` writes to a
   literal `$HOME/.cache/nushell/init` (decision D1a — Nushell resolves
   `source` at parse time and cannot read `$env`, so the path cannot be a
   variable), and it inherited the caller's. This file does **not** do that
   yet, and that is the defect.

## Boxes

- [x] **S1.1** — `cz()` sets `HOME` to the same directory it passes as
      `--destination`, i.e. `$root/dest`. The prefix-assignment form is
      enough and is the minimum-risk change:

      ```bash
      cz() {
        local root="$1"; shift
        HOME="$root/dest" \
        "$CHEZMOI" \
          --source "$root/src" \
          --destination "$root/dest" \
          ...
      }
      ```

      Rehearsed by the analyst in a scratch clone: 60 PASS / 0 FAIL, no
      change to any existing assertion.

- [x] **S1.2** — The `--cutover` stage's PATH shim (`$S/bin/chezmoi`, the
      heredoc quoted `<<'SHIM'`) exports `HOME="$P1_DEST"` before it builds
      `common=(…)`. This is the second site and it is load-bearing: with only
      S1.1 applied, `bash tests/deploy-skeleton.sh --cutover` still created
      `~/.cache/nushell`. Rehearsed:

      ```bash
      #!/bin/bash
      set -u
      # HOME too, not just the flags: --destination bounds where chezmoi
      # WRITES; it does not bound what a run_ script chezmoi RUNS inherits.
      export HOME="$P1_DEST"
      common=(
        --destination     "$P1_DEST"
      ```

      Put the pin inside the shim rather than on the `just cutover` env line,
      so anything the recipe reaches chezmoi through is covered.

- [x] **S1.3** — A real-`HOME` guard is added in this file's **own dialect**,
      alongside the existing `guard_begin`/`guard_end`, and every stage calls
      it. It records the state of the real user paths on entry and asserts
      them unchanged on exit, in the same run — that is the literal wording of
      the node's first acceptance box ("proved by checking before and after in
      the same run"). Shape it on `guard_begin`/`guard_end`: hash each path
      (a missing path hashes to a sentinel such as `<absent>`, so *appearing*
      counts as a change), print the in-value, assert the out-value with
      `chk`.

      **`tests/deploy-skeleton.sh` does not source `gates/lib.sh`** and must
      not start to here. It predates the library and defines its own `chk`,
      `guard_begin`, `guard_end` and `lint_self`; sourcing `lib.sh` would
      collide with all four. `gates/lib.sh`'s own header records that these
      scripts deliberately agree on a *dialect* rather than sharing code.
      Duplicate the few lines.

- [x] **S1.4** — The guarded path list is exactly the set this gate could
      plausibly damage:

      `$HOME/.cache/nushell`, `$HOME/.cache/starship`,
      `$HOME/.cache/television`, `$HOME/.zoxide.nu`,
      `$HOME/.config/nushell/help`, `$HOME/.config/television`,
      `$HOME/.gitconfig`

      **Do not watch `$HOME/.config/nushell` as a whole.** Measured: it holds
      the live `history.sqlite3-wal`, which the developer's own interactive
      Nushell rewrites at any moment (observed changing mid-session while no
      gate ran). Watching the directory makes the guard flaky for a reason no
      gate causes. `.config/nushell/help` is the subtree the managed tree
      actually deploys into, and it is stable.

- [x] **S1.5** — The header `SAFETY` block gains the **second** half of the
      rule. It currently states half 1 ("HOME does not isolate chezmoi") in
      full and is silent on half 2, which is why this defect shipped. Say
      plainly that `--destination` bounds where chezmoi writes and not what a
      `run_` script inherits, name
      `home/run_after_generate-shell-init.sh` as the script that proved it,
      and name both pinned sites so the next reader knows there are two.

- [x] **S1.6** — R5 holds: `/usr/bin/grep -c '^PASS'` on a full run is **≥ 60**
      and `/usr/bin/grep -c '^FAIL'` is **0**. Record the actual numbers in
      this box when you close it. The count may rise — S1.3 adds `chk` lines —
      it may not fall.

      MEASURED 2026-08-21, `bash tests/deploy-skeleton.sh` against the real
      `$HOME`: rc 0, `^PASS` = **63**, `^FAIL` = **0**. The floor of 60 rose by
      exactly the three `chk` lines S1.3 adds, one per stage
      (`apply`/`push`/`cutover`). `^PASS  ` (two spaces, `chk` lines only) =
      62, up from 59. Nothing fell.

- [x] **S1.7** — The structural lint still passes: `lint: no bare chezmoi in
      command position in deploy-skeleton.sh` is PASS. Neither pin introduces
      a bare `chezmoi` (S1.1 keeps `"$CHEZMOI"`; S1.2's shim already execs
      `"$P1_REAL_CHEZMOI"`).

- [x] **S1.8** — R2, both directions, demonstrated **hermetically** and
      recorded in this box. Do not prove this by dirtying the real `~`; use a
      fake `HOME` so the counterfactual is repeatable:

      ```bash
      F=$(mktemp -d)
      mkdir -p "$F/.config/chezmoi"
      cp ~/.config/chezmoi/chezmoi.toml "$F/.config/chezmoi/"
      printf '[user]\n\tname = P1 gate\n\temail = p1-gate@example.invalid\n[init]\n\tdefaultBranch = main\n' > "$F/.gitconfig"
      /usr/bin/env HOME="$F" P1_GUARD_CFG="$F/.config/chezmoi/chezmoi.toml" \
        bash tests/deploy-skeleton.sh && [ ! -e "$F/.cache/nushell" ]
      ```

      `P1_GUARD_CFG` is the file's existing test-only hook and is why this
      works: the live-config guard needs a config to watch, and under a fake
      `HOME` the real one is not on the path it computes. The seeded
      `.gitconfig` is **required**, not decoration — `--push` makes a real
      commit, and without a git identity in the fake `HOME` that stage fails
      for a reason unrelated to this node (measured: 57 PASS / 3 FAIL).

      Analyst measurement of exactly this command, for you to reproduce:
      **pristine repo → rc 1** (60 PASS / 0 FAIL, and
      `$F/.cache/nushell/init/` created — the leak, now landing in the fake
      home instead of the real one); **rehearsed fix → rc 0** (60 PASS / 0
      FAIL, `$F/.cache/nushell` absent). Real `~/.cache/nushell` absent
      throughout both.

      REPRODUCED by the implementer, 2026-08-21, both directions:

      * **RED, pristine repo → rc 1.** 60 PASS / 0 FAIL, and
        `$F/.cache/nushell/init/` created holding `starship.nu` 2280,
        `television.nu` 1809, `zoxide.nu` 1998 bytes.
      * **GREEN, after S1.1+S1.2 → rc 0.** 63 PASS / 0 FAIL,
        `$F/.cache/nushell` absent, and every stage printing
        `home-guard[<stage>] ~/.cache/nushell in = <absent>` /
        `out = <absent>`.

      And a third run that proves S1.2 is not decoration and S1.3 is not
      theatre: with **only the shim pin removed** (S1.1 still in place),
      `bash tests/deploy-skeleton.sh --cutover` under the fake `HOME` went
      **rc 1** on
      `FAIL: cutover: no REAL user path under $HOME was touched (moved:
      …/.cache/nushell …/.cache/starship)`, with the three files present in
      the fake home. That is the exact leak a `cz()`-only fix leaves live,
      now caught by the gate itself. The file was restored byte-identical
      afterwards. The real `~/.cache/nushell` was absent throughout all
      three runs.

## Verify

The frontmatter `verify:` is the S1.8 command as a one-liner. It was proved
**RED before any edit** (rc 1 against the repo as it stands) and GREEN against
the rehearsed fix (rc 0). It touches the real `~` only to *read*
`~/.config/chezmoi/chezmoi.toml`.

Run `bash tests/deploy-skeleton.sh` unadorned as well: after S1.3 that run
carries its own real-home assertion, which is the node's acceptance box 1.

## Out of scope

- **An in-gate counterfactual for the pin.** Inducing the de-pinned state from
  inside the gate needs a full scratch copy of the repo (the script resolves
  `REPO` from its own location) and a re-entrant `--cutover`, which recurses
  unless a further env guard is threaded through. Disproportionate for a
  0.75h node when S1.8 demonstrates both directions in eight lines. The node
  asks for the counterfactual *demonstrated*, not gated.
- **A structural lint for the `HOME` pin.** `lint_no_bare_chezmoi` works
  because a bare command name is a token; "this helper sets HOME" is not, and
  every cheap approximation is fragile. S1.3's behavioural guard is the
  enforcement, exactly as `guard_begin`/`guard_end` is the enforcement for
  half 1 of the rule.
- `tests/managed-config.sh`, `gates/lib.sh` — spec02.
- `repo-skeleton`'s R3 evidence sentence (the node's own Out of scope).
