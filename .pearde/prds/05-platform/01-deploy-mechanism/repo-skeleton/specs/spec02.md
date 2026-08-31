---
est: 1.5h
verify: "bash tests/deploy-skeleton.sh --push && bash tests/deploy-skeleton.sh --cutover"
---

# spec02 — `just push`, `just cutover`, and the seam the gate runner hooks into

Goal: one command that publishes a local edit (commit + push, git only), a
second, deliberately-named command that hands this machine over to this repo,
and a root `justfile` that G.1 can add gate recipes to without either task
editing the other's file.

Today the repo has no `justfile` at all, and `just` walks *up* the directory
tree, so `just` run inside this repo silently resolves `/Users/feb/dev/justfile`
and offers its `i` and `s` recipes. `just push` here does not fail with "no
justfile"; it fails with "does not contain recipe `push`" against someone
else's file. That is the shape of the red.

## Amendment of 2026-08-21 — the cutover is a separate recipe

R5 as written in [`../../prd.md`](../../prd.md) reads "One `just push`: init
from this source, apply, commit, push, then update." **The user amended that
on 2026-08-21**, after this analyst raised the hazard: `chezmoi init --source
. --force` rewrites `sourceDir` in `~/.config/chezmoi/chezmoi.toml`, so a
`just push` typed for its git half would silently move this machine off
`/Users/feb/dev/.files` and onto a repo whose managed tree is, during Wave 1,
six `.nuon` files. Nothing is destroyed — `chezmoi apply` never removes
unmanaged files — but ownership moves, and it moves for the rest of the wave.

The decision: **`push` does the commit/push round trip only.** The
source-repointing moves behind an explicitly-typed `just cutover`. A doc
comment was judged insufficient protection for a whole wave. An interactive
confirmation stays rejected — it would make the recipe ungateable.

Two consequences this spec carries:

- R5's *round-trip proof* is re-cut. "Back out of a fresh clone" now ends in
  an **isolated apply from that fresh clone**, which exercises the deploy path
  without the live machine being cut over. Same coverage, no ownership change.
- R5's "then update" leaves the recipe. `chezmoi update` is `git pull` in the
  source directory plus an apply, which is only meaningful once `sourceDir`
  points here — i.e. after `cutover`. The daily pull-and-apply is `rr`,
  [`04-shell/02`](../../../../04-shell/02-aliases-utilities/prd.md) R4.

R5's text in the parent still describes the old single-recipe shape. That file
is not this node's to write; flagged for the orchestrator.

## Files

| File | State | Note |
|---|---|---|
| `justfile` | new | declared in the P.1 footprint; **shared with G.1** |
| `tests/deploy-skeleton.sh` | extend | the `--push` and `--cutover` stages; created in [`spec01`](spec01.md) |

## Design

```just
# Deploy recipes. Gate recipes live in gates/justfile and are imported when
# that file exists, so this file has one writer and the gates have another.
import? 'gates/justfile'

repo := justfile_directory()

# List the recipes.
default:
    @just --list

# Publish this repo: stage, commit, push. Git only.
# This does NOT deploy and does NOT change which repo this machine is
# deployed from. Deploying is `chezmoi apply`; changing ownership is
# `just cutover`, and nothing else in this file does it.
push message="dotfiles: update":
    git -C "{{ repo }}" add --all
    git -C "{{ repo }}" diff --cached --quiet || git -C "{{ repo }}" commit -m "{{ message }}"
    git -C "{{ repo }}" push

# DANGER, one-time and deliberate: hand this machine over to this repo.
# `chezmoi init --source` rewrites sourceDir in ~/.config/chezmoi/chezmoi.toml,
# so from here on `chezmoi apply`, `chezmoi update` and `rr` deploy from HERE
# and no longer from wherever they pointed before. Files the old source
# managed are not deleted, they simply stop being managed. Until the managed
# tree is complete this leaves the machine deployed from a repo that carries
# almost none of it. Type this on purpose.
cutover:
    chezmoi init --source "{{ repo }}" --force
    chezmoi apply --force
```

Each decision, and what it is for:

- **`import? 'gates/justfile'`** — the optional import. Verified working on
  the installed `just 1.58.0`: with the file absent, `just --list` succeeds;
  with it present, its recipes appear in the same list. This is the entire
  G.1 hook, and it is why `justfile` appearing in two tasks' footprints is
  not a two-writer conflict. `gates/` is already G.1's declared footprint.
- **`repo := justfile_directory()`** — every `git` call is `-C "{{ repo }}"`
  so the recipe behaves the same whichever subdirectory it is run from.
  `just` sets the working directory to the justfile's directory by default,
  but the explicit `-C` makes that a property of the recipe rather than of
  `just`'s defaults.
- **`git diff --cached --quiet || git commit`** — the live recipe committed
  unconditionally with the message `intermediate`, so a `just push` with
  nothing staged aborted the recipe *before* the push. Guard it, and take the
  message as a parameter with a default instead of hardcoding a junk one.
- **`push` contains no `chezmoi` at all.** This is the amendment, and it is
  checked rather than trusted: the gate lints the recipe body and, separately,
  runs `just push` with a *poison* `chezmoi` on `PATH` that exits 97 and logs
  if it is called. A future edit that folds a deploy back into `push` turns
  the gate red twice over.
- **`cutover` is a recipe, not a flag.** `just cutover` over `just push
  CUTOVER=1`: it shows up in `just --list` as its own line, it cannot be
  reached by adding an argument to a command someone already types daily, and
  `just`'s variable-override syntax (`--set`) reads worse than a verb.

## Isolation — load-bearing for the whole board, and enforced, not documented

Every chezmoi invocation the gate makes must carry **all five** of
`--config`, `--config-path` (on `init` only), `--destination`,
`--persistent-state` and `--cache`. `--source` alone is not enough and
`HOME` is not enough. This was learned by doing the damage: a scratch-`HOME`
run of `chezmoi init --source … --force` moved the destination correctly and
still rewrote the **real** `~/.config/chezmoi/chezmoi.toml`, repointing this
machine's live source from `/Users/feb/dev/.files` to a scratch directory. It
had to be restored by hand.

A comment saying "don't drop these" is exactly the protection the user just
rejected elsewhere in this spec, so the script enforces it two ways:

1. **Behavioural guard, in every stage.** At stage start, record
   `shasum -a 256 ~/.config/chezmoi/chezmoi.toml` and the output of
   `chezmoi source-path`. At stage end, assert both are unchanged. If an
   implementer drops `--config` or `--config-path`, `chezmoi init` rewrites
   the live config and **the gate goes red on the damage itself**, not on a
   style rule. This is the primary mechanism; it needs no parsing and cannot
   be satisfied by a comment.
2. **Structural lint, on the script itself.** The script greps its own source
   for a bare `chezmoi` in command position (`^\s*chezmoi\s`, or after a
   pipe) and fails if it finds one. Every real call goes through the resolved
   `"$CHEZMOI"` path with the flag block, or through the `PATH` shim. This
   catches the naive "just call chezmoi" edit before it can do harm.

`just push` and `just cutover` call bare `chezmoi` by design — they are the
real commands and must not be littered with test flags — so the gate isolates
from the outside, with a `chezmoi` shim first on `PATH`.

## The gate, stage `--push`

`just push` is git-only now, so this stage proves publication and then
deployment as two separate legs:

1. `cp -R "$REPO/." "$SCRATCH/work/"`, `rm -rf "$SCRATCH/work/.git"`, then
   `git init -b main`, set `user.name`/`user.email` locally, `git init --bare
   "$SCRATCH/remote.git"`, add it as `origin`, commit, push. The working tree
   is copied rather than cloned so the gate tests the justfile as it is now,
   not as it was last committed.
2. Lint the `push` recipe body for `chezmoi`, and put a **poison** shim on
   `PATH` (`echo POISON…; exit 97`) for the duration of the run.
3. Write a nonce into `$SCRATCH/work/home/dot_config/dot_p1-roundtrip` — the
   `dot_` prefix is required; a source file literally named `.p1-roundtrip`
   is chezmoi metadata and is silently not a target.
4. `( cd "$SCRATCH/work" && PATH="$SCRATCH/bin:$PATH" just push "gate:
   round-trip" )`, then assert the log contains no `POISON`.
5. Assert the nonce is in the bare remote, then `git clone` the bare remote
   into `$SCRATCH/reclone` and assert it is there too.
6. **Deploy leg:** pre-seed `$CFG` with `[data]`, then `init` + `apply` with
   `--source "$SCRATCH/reclone"` and the full flag block, into `$SCRATCH/dest`.
   Assert `<dest>/.config/.p1-roundtrip` holds the nonce.

## The gate, stage `--cutover`

Proves the recipe works without performing it on this machine:

1. Same scratch clone (no remote needed).
2. Write `$SCRATCH/bin/chezmoi`, a shim that `exec`s the real binary with
   `--destination`, `--config`, `--persistent-state`, `--cache`, `--no-tty`
   prepended and stdin from `/dev/null`. It must special-case `init`, adding
   `--config-path "$CFG"` — without it `chezmoi init` writes the *real*
   `~/.config/chezmoi/chezmoi.toml`. `--config-path` is an `init`-only flag,
   so it cannot simply join the common list.
3. Pre-seed `$CFG` with `[data] name/email` so the config template does not
   prompt (see [`spec01`](spec01.md)'s constraints — `--promptDefaults` reads
   stdin, and `--promptString` keys are the prompt text).
4. `( cd "$SCRATCH/work" && PATH="$SCRATCH/bin:$PATH" just cutover )`.
5. Assert `$CFG` now carries `sourceDir = "<work>"` — resolve the path with
   `cd … && pwd -P` first, because macOS resolves `/var` to `/private/var`
   and a literal comparison fails on that alone.
6. Assert `<dest>/.config/nushell/help/topics.nuon` exists — it deployed.
7. Assert the live guard.

## Acceptance

- [x] `justfile` exists at the repo root, and `just --list` run inside the
      repo lists `default`, `push` and `cutover` — i.e. it resolves this file
      and not `/Users/feb/dev/justfile`. Names are matched **exactly**
      (a first cut grepped `^ *push`, which a renamed `pushx` satisfied), and
      resolution is proved directly: `just --evaluate repo` run inside the
      repo prints `/Users/feb/dev/dotfiles`, a variable the parent justfile
      does not define.
- [x] The `justfile` contains `import? 'gates/justfile'`, and `just --list`
      still exits 0 with `gates/justfile` absent. With a throwaway
      `gates/justfile` in place, `gate-probe` appeared in `just --list`
      (exit 0) and the root `justfile` sha256 was identical before and after
      (`8f95925ca42fab23…`). Throwaway and `gates/` removed.
- [x] The body of the `push` recipe contains no `chezmoi` (doc-comment lines
      are stripped before the lint — the comment names the word on purpose),
      and a run of `just push` against a poison shim never invoked it: no
      `POISON` in the recipe output and the shim's own log stayed empty.
- [x] `push` takes a message parameter with a default, and running it twice
      with nothing changed the second time still reaches `git push` — the
      empty-commit guard does not abort the recipe (second run exit 0).
- [x] `git -C <remote.git> show main:home/dot_config/dot_p1-roundtrip` returns
      the nonce, and a fresh `git clone` of that bare remote contains it.
      (published, round-tripped)
- [x] An isolated `init` + `apply` **from that fresh clone** puts the nonce at
      `<dest>/.config/.p1-roundtrip`. (deployed, with no cutover anywhere)
- [x] `just cutover`, run under the isolating shim, rewrites the *scratch*
      config's `sourceDir` to the scratch clone and deploys the managed tree
      into the scratch destination. Paths compared after `pwd -P`, as the
      spec warned: the match is `/private/var/folders/…/work`.
- [x] After every stage, `~/.config/chezmoi/chezmoi.toml` has the same sha256
      as before the run and `chezmoi source-path` still resolves to
      `/Users/feb/dev/.files/home`. Hash in and out of all three stages:
      `02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1`.
      Confirmed once more after the last run, including a `cat` of the file.
- [x] The guard is proven to *fire*: with `P1_GUARD_CFG` pointed at a copy and
      `P1_GUARD_MUTATE=1` appending a line to that copy right after the
      snapshot, `--apply` and `--push` each printed
      `FAIL: …: LIVE chezmoi.toml unchanged (sha256 02d5d4ee…)` and exited 1
      (observed out-hash `c18676583e7a559a…`). The same copy left unmutated
      passes. The mutate hook refuses to run when the watched path is the
      real config (exit 2), so the rehearsal cannot become the accident.
- [x] The structural lint finds no bare `chezmoi` in command position in
      `tests/deploy-skeleton.sh`, and does find one when a bare call is
      appended to a scratch copy — `FAIL: lint: no bare chezmoi in command
      position`, exit 1, with the offending line number printed. This
      counterfactual caught a real bug in the first cut: a command
      substitution in `chk`'s label argument clobbered `$?`, so the lint
      found the hit and still reported PASS.
- [x] `bash tests/deploy-skeleton.sh --push` and `… --cutover` each exit 0,
      and each exits non-zero with its recipe temporarily renamed on a
      scratch copy of the repo: `push` -> `pushx` gives exit 1 starting at
      `FAIL: push: 'push' is a recipe of the justfile just resolves in this
      repo`; `cutover` -> `cutoverx` gives exit 1 with
      `FAIL: cutover: a 'cutover' recipe exists`.
- [x] `bash tests/deploy-skeleton.sh` with no argument runs all three stages
      and exits 0 — 53 PASS, 0 FAIL.

## Proven RED

Re-proved against the tree as it stands today, after the amendment:

- `just --dump` prints the recipes `i` and `s`
  from `/Users/feb/dev/justfile`. There is no `push` and no `cutover`.
- The amended `--push` prototype: **exit 1**, `FAIL: justfile missing`.
- The `--cutover` prototype: **exit 1**, `FAIL: no 'cutover' recipe`.
- Both literal `verify:` commands exit 127
  (`tests/deploy-skeleton.sh: No such file or directory`).

Green, against a copy of the repo carrying the `justfile` above:

- `--push`: `PASS`, exit 0 — recipe-body lint clean, poison shim never fired,
  nonce in the bare remote, in a fresh clone, and deployed from that clone
  into the scratch destination.
- `--cutover`: `PASS`, exit 0 — scratch `sourceDir` repointed at the scratch
  clone, managed tree deployed, live config byte-identical throughout.
- Guard counterfactual: armed against a copy of the live config and the copy
  mutated mid-run, the stage reports `FAIL: LIVE chezmoi.toml changed` and
  exits 1; against an untouched copy, `PASS`.
- Live machine after every run: `chezmoi source-path` =
  `/Users/feb/dev/.files/home`, `~/.config/chezmoi/chezmoi.toml` sha256
  `02d5d4ee50b5d379…` unchanged.

## Out of scope

- Gate recipes of any kind. G.1 writes `gates/justfile`; this spec only
  guarantees the import that finds it.
- An `rr` / `chezmoi update --force` alias, and `chezmoi update` inside any
  recipe here. That is `04-shell/02` R4, and it only means anything after a
  cutover.
- A `just apply` wrapper. `chezmoi apply` stays the single deploy step (R3);
  wrapping it would give the tree two names for one thing, and `push` no
  longer deploys precisely so that the deploy step stays visible.
- Performing the cutover. This spec builds and gates the recipe; when it is
  typed is the user's call.
