---
est: 1.5h
verify: "bash tests/deploy-skeleton.sh --apply"
---

# spec01 — the chezmoi source root

Goal: make this repository a chezmoi source that deploys `home/` and nothing
else, idempotently, into a target that is not `$HOME` when a gate is running.
Today it is not one: `chezmoi apply --source .` treats the repo root as the
source, and the board, the contract file and a scratch directory are all
targets. Measured against the tree as it stands (see `## Proven RED`), a bare
apply would create `~/AGENTS.md`, `~/CLAUDE.md`, `~/.mi/`, `~/tests/`,
`~/vicky/` and `~/home/`.

This spec also ships the first half of the node's gate script, because R3's
"a second apply changes nothing" is not a claim anyone can re-check by
reading.

## Files

| File | State | Note |
|---|---|---|
| `.chezmoiroot` | new | declared in the P.1 footprint |
| `home/.chezmoiignore` | new | declared in the P.1 footprint |
| `home/.chezmoi.toml.tmpl` | new | **footprint addition** — see below |
| `tests/deploy-skeleton.sh` | new | **footprint addition** — see below |

Two files are outside the footprint `plan.json` records for P.1. Neither is
claimed by any other task (checked across every `files` list in
`.mi/gantt/plan.json`), and both are load-bearing here:

- `home/.chezmoi.toml.tmpl` **is** the chezmoi root. It is what makes a clone
  anywhere register itself as the source (`sourceDir = .chezmoi.workingTree`),
  which is the only reason R5's "init from this source" does anything, and it
  is where `.name` / `.email` come from — the data `dot_gitconfig.tmpl` (P.5,
  which `deps` on this node) renders against. Without it P.5 has no data
  source and has to invent one in a one-file footprint.
- `tests/deploy-skeleton.sh` follows the convention the repo already has:
  `tests/help-content-model.nu` is H.1's own gate for its own node. A
  node-specific check script is not G.1's deliverable; G.1 owns the *runner*
  and the cross-cutting gates. The optional import in
  [`spec02`](spec02.md) is the seam that lets G.1 pick this up without
  either task editing the other's file.

Read-only in this spec, never written: `home/dot_config/nushell/help/**`
(H.1's, and being written concurrently). The gate copies the tree into a
scratch directory rather than applying from the repo in place, so it never
writes into the working tree at all.

## Design

**`.chezmoiroot` holds exactly `home`.** One line, no trailing content.
chezmoi then reads `<repo>/home` as the source directory and everything
beside it — `.mi/`, `tests/`, `vicky/`, `AGENTS.md`, `justfile` — stops being
a target by construction rather than by an ignore rule that has to be
maintained. This is why the managed tree is `home/dot_config/…` and not
`dot_config/…` at the root, and it is the shape the existing
`home/dot_config/nushell/help/` already assumes.

**`home/.chezmoiignore`** carries the rules the skeleton needs and no
speculation. It matches *target* paths, and it accepts `#` comments:

```
# Documentation of the source tree is not configuration. The manual's own
# README (home/dot_config/nushell/help/README.md) tells an editor how to write
# an entry; it is not part of the deployed manual, which is the .nuon files.
README.md
**/README.md

# Finder litter. chezmoi reads the filesystem, not the git index, so a stray
# .DS_Store inside home/ becomes a real ~/.config/.DS_Store even though the
# repo's .gitignore drops it.
.DS_Store
**/.DS_Store
```

No OS conditionals. The host is macOS only (contract, "Scope decisions
already made"), and the live source's `.chezmoiignore` gated the Homebrew
bootstrap out on non-macOS for a dual-platform setup that is `DO NOT PORT`.
Say so in a comment so nobody re-adds the ladder.

**`home/.chezmoi.toml.tmpl`** does two jobs and no more:

```
{{- $name  := promptStringOnce . "name"  "Full name (for git)" -}}
{{- $email := promptStringOnce . "email" "Email (for git)" -}}
sourceDir = {{ .chezmoi.workingTree | quote }}

[data]
    name = {{ $name | quote }}
    email = {{ $email | quote }}
```

`promptStringOnce` prompts on a fresh machine and never again, because it
short-circuits when the key already exists in the config's `[data]`. That
short-circuit is also the only headless path — see the constraints below.

## Constraints, with the reason (all measured, not assumed)

- **`HOME` does not isolate chezmoi.** Pointing `HOME` at a scratch directory
  moves the *destination* but **not** the config file: a `chezmoi init
  --source <scratch> --force` run under a scratch `HOME` rewrote the real
  `~/.config/chezmoi/chezmoi.toml` and repointed this machine's live source
  from `/Users/feb/dev/.files` to the scratch repo. It had to be restored by
  hand. A gate must pass `--config` *and* `--config-path` explicitly, plus
  `--destination`, `--persistent-state` and `--cache`. This is the single
  most expensive fact in this spec; do not drop a flag from the harness.
- **A headless `chezmoi init` must pre-seed `[data]`, not pass flags.**
  `--promptDefaults` with no default argument in the template still prompts,
  and under `--no-tty` it reads **stdin** — inside a script driven by a
  heredoc it silently consumed the remaining lines and exited 0 with garbage
  data. `--promptString` works but its keys are the *prompt text*
  (`"Full name (for git)=…"`), so any wording change breaks the gate.
  Writing `[data] name/email` into the scratch config before `init` is the
  stable path: `promptStringOnce` finds them and never prompts. Redirect
  `< /dev/null` anyway, as a second line of defence.
- **`chezmoi init` defaults to `--data=true`** and folds in template data
  from whatever config it can already see. A first scratch run leaked the
  user's real email into the scratch config. Pre-seeding makes this moot;
  do not rely on ambient data being absent.
- **A source entry whose name begins with `.` is chezmoi metadata**, never a
  target. Managed dotfiles use the `dot_` prefix. This is why the gate's
  round-trip fixture in [`spec02`](spec02.md) is `dot_p1-roundtrip`.

## The gate, part one

`tests/deploy-skeleton.sh` takes a stage selector: `--apply` (this spec),
`--push` and `--cutover` ([`spec02`](spec02.md)), no argument = all three.
Shape that is known to work, in the repo's existing `tests/` idiom (collect
failures, print one line each, exit non-zero at the end):

**Define the live-config guard here, once, and run it from every stage.** Per
the constraint above, a dropped `--config` or `--config-path` silently
rewrites this machine's real chezmoi config. So each stage records
`shasum -a 256 ~/.config/chezmoi/chezmoi.toml` and `chezmoi source-path` on
entry and asserts both are unchanged on exit. The gate then fails on the
damage itself rather than on a comment nobody has to obey. `spec02` proves
the guard fires.

1. Copy `$REPO` into `$SCRATCH/src` and drop a `.DS_Store` into
   `$SCRATCH/src/home/dot_config/` — the check runs against a faithful copy so
   the repo working tree is never written to.
2. Pre-seed `$SCRATCH/chezmoi.toml` with `[data] name/email`.
3. `chezmoi --source "$SCRATCH/src" --destination "$SCRATCH/dest" --config
   "$SCRATCH/chezmoi.toml" --persistent-state … --cache … --no-tty init
   --config-path "$SCRATCH/chezmoi.toml" --force < /dev/null`
4. `chezmoi … apply --force`
5. Assert the boundary, the ignores, then apply again and assert silence.

## Acceptance

- [x] `.chezmoiroot` exists at the repo root and its whole content is `home`.
      (`od -c` => `h o m e \n`, one line.)
- [x] `home/.chezmoiignore` and `home/.chezmoi.toml.tmpl` exist, and the
      generated scratch config contains a `sourceDir` line — i.e. the config
      template rendered rather than being skipped. The pre-seeded `[data]`
      also survived `init`, so nothing prompted and no ambient email leaked.
- [x] A scratch apply creates `<dest>/.config/nushell/help/*.nuon` — the
      managed tree reaches its target under the new root.
- [x] The same apply creates **none** of `AGENTS.md`, `CLAUDE.md`, `.mi`,
      `tests`, `vicky`, `justfile`, `.chezmoiroot`, `home` in the target.
      Reported as `leaked:<none>`; `.obsidian`, `.pi` and `.kern` were added
      to the same census. With `.chezmoiroot` moved aside the identical run
      reports `leaked: AGENTS.md CLAUDE.md tests vicky justfile home`,
      reproducing `## Proven RED`.
- [x] No `.DS_Store` and no `README.md` appears anywhere under the target,
      with a `.DS_Store` deliberately planted in the copied source.
- [x] A second `chezmoi apply --force --verbose` immediately after the first
      prints **nothing**, and `chezmoi status` prints nothing. (R3)
- [x] The gate writes nothing outside its own scratch directory: after a run,
      `git status --porcelain` over `home/`, `.chezmoiroot` and `tests/` shows
      only the files this spec added — `?? .chezmoiroot`,
      `?? home/.chezmoi.toml.tmpl`, `?? home/.chezmoiignore`, `?? justfile`,
      `?? tests/deploy-skeleton.sh`. The ` M` entries alongside them are
      concurrent H.1 work under `home/dot_config/nushell/help/**`,
      `tests/help-content-model.nu` and `tests/live-bugs.sh`, untouched here.
      The planted `.DS_Store` is asserted absent from the working tree.
- [x] The live-config guard is defined once and invoked by every stage, and it
      passes: `~/.config/chezmoi/chezmoi.toml` has the same sha256 before and
      after the run and `chezmoi source-path` still resolves to
      `/Users/feb/dev/.files/home`. In and out, every stage:
      `02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1`.
- [x] `bash tests/deploy-skeleton.sh --apply` exits 0, and exits non-zero
      when `.chezmoiroot` is temporarily moved aside — **exit 1**, six FAIL
      lines. The induced run was done against a full copy of the repo in
      scratch (the gate derives `$REPO` from `BASH_SOURCE`), so the working
      tree was never mutated.

## Proven RED

A prototype of exactly these checks was run against the tree as it stands
today. Exit 1, with:

```
FAIL: .chezmoiroot missing
FAIL: .chezmoiroot is not 'home'
FAIL: home/.chezmoiignore missing
FAIL: home/.chezmoi.toml.tmpl missing
FAIL: generated config has no sourceDir
FAIL: repo entry 'AGENTS.md' deployed into the target
FAIL: repo entry 'CLAUDE.md' deployed into the target
FAIL: repo entry 'tests' deployed into the target
FAIL: repo entry 'vicky' deployed into the target
FAIL: repo entry 'home' deployed into the target
FAIL: home/dot_config did not deploy to .config
FAIL: source README.md deployed
```

The same prototype against a copy of the repo carrying the three files above
printed `PASS`, exit 0. The literal `verify:` command exits 127 today
(`tests/deploy-skeleton.sh: No such file or directory`).

## Out of scope

- `.gitattributes` with `eol=lf`. The live source carries it because rendered
  template bytes are verbatim and a stray CR aborts a bash line continuation —
  a real constraint, but one that came from the dual-platform Windows mirror
  that is `DO NOT PORT`. macOS-only, checked out on macOS, there is no CRLF
  source. Recorded here so the reason is not lost if Windows ever returns.
- Any `run_*` script, `.chezmoidata/`, or `dot_gitconfig.tmpl`. P.2, P.3, P.4
  and P.5 own those; this spec only makes the root they live in.
- Any file under `home/dot_config/<tool>/`. Each per-app directory belongs to
  its own track.
