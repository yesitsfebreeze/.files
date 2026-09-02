# 07-provisioning — implementer report

Verdict: DONE

Pass two, as engineer, on workflow `replace-a-hand-rolled-mechanism`.
Pass one (the analyst's probe) left the code built and uncommitted in this
working tree; this pass measured the survivors, re-proved every claim, closed
the two things pass one left open, and ticked the boxes against output it ran.

`install.sh` 493 → **78 lines**. `run_after_generate-shell-init.sh` 112 → 35.
`run_after_register-mcp.sh` 65 → 29. The package set is a 28-entry `Brewfile`.
Every spec box and every PRD box is `[x]`, each quoting the check that closed it.

- **specs**: 3 of 3, all boxes closed — spec01 7/7, spec02 5/5, spec03 4/4
- **PRD**: R1–R6 closed, 5 of 5 acceptance lines closed
- **verify**: `probe/verify.sh` — 20 assertions, PASS on three consecutive runs
  with byte-identical output and nothing edited between them, and once more
  after a negative control proved the last assertion can still fail
- **gates**: `just board-guard` and `just board-guard-blocks` both exit 0

## What this pass changed

Three edits; everything else was measurement.

0. `probe/verify.sh` — its last assertion, "no file target left undeployed",
   was **repo-wide** and therefore not a check on this node. It went red
   mid-pass on `09-simplify/04-nushell`'s in-flight `config.nu`,
   `nushell-modules.md` and `zoxide.nu`. Scoped to the four targets this PRD
   deploys, named one by one — a directory pattern over `internals/` still
   caught another node's `nushell-modules.md`. Negative control run: appending
   a line to the deployed `capsule/Dockerfile` turned it red
   (`FAIL a file target is still pending: MM .config/capsule/Dockerfile`), and
   a scoped `chezmoi apply --force` on that one path restored it to 3489 bytes
   on both sides. The check can still fail; it just fails for this node only.
1. `internals/neovim.md:557` — pass one's repointing of the `PKGS` citation
   left a lowercase sentence opening: "…renders nothing. the `Brewfile`
   carries git…". Fixed to "The". Inside the footprint and inside spec03's
   scope; not a refactor.
2. That edit made the deployed copy stale, which the verify caught as
   `FAIL a file target is still pending`. Deployed with a **scoped**
   `chezmoi apply ~/.config/nushell/help/manual/internals/neovim.md`, never a
   bare one.

## Verify output (run 3 of 3, identical to runs 1 and 2)

```
  ok   Brewfile lists 28 entries
  ok   every formula resolves
  ok   every cask resolves
  ok   tinty is in the Brewfile
  ok   brew owns tinty
  ok   no ~/.local/bin/tinty shadow
  ok   install.sh is 78 lines
  ok   install.sh parses
  ok   install.sh runs brew bundle
  ok   install.sh trusts the tinted tap
  ok   chezmoi apply comes after brew bundle
  ok   no deleted-test or seam citations
  ok   three non-empty init files
  ok   a failing tool yields an empty file, exit 0
  ok   the ~/.claude.json finding survives
  ok   the empty-build-context rule survives
  ok   the internals page says brew bundle
  ok   the internals page names no wave or gate
  ok   the page is deployed
  ok   no file target left undeployed
PASS
```

`probe/shell-init-missing-tool.sh` separately:
`PASS: exit 0, zoxide.nu empty, other two intact` (`starship.nu 2280`,
`television.nu 1809`, `zoxide.nu 0`).

## The apply was scoped, deliberately

`chezmoi status` before and after this pass shows the same three ` R `
run-scripts pending — `generate-shell-init.sh`, `register-mcp.sh`,
`seed-mason-registry.sh`. The third is `06-neovim-television`'s and a bare
`chezmoi apply` runs all three, so the bare form was never used. What was run:
`chezmoi apply --dry-run` (exit 0), one scoped `chezmoi apply <path>` (exit 0),
and the shell-init generator directly. No file target is left undeployed.

## Findings — reported, not fixed

- **`run_after_seed-mason-registry.sh` now has no caller.** R2 removed
  `export MASON_SEED=1` from `install.sh`, and that variable is the script's own
  early-exit guard (`:69`). It also still cites `SHELL_INIT_BREW_PREFIXES` at
  `:61`, a seam this PRD deleted. Out of scope; `06-neovim-television` owns it,
  and its decision is now the only thing keeping the file alive. Carried
  forward from pass one and re-measured today.
- **`internals/provisioning.md` was committed by another pass.** The page pass
  one wrote as untracked was swept into `3f02c2c` (`03-help-system — one
  corpus, one generator, one search`), which is now an ancestor of HEAD. Its
  content is this PRD's, unaltered, and it is deployed. Nothing to repair — but
  spec03's "net-new, uncommitted" framing is one commit out of date, and the
  page's history now names a PRD that did not write it.
- **`help --check` does not exist**, so the drift check that would normally
  guard a new manual page could not be run. `home/dot_config/nushell/help-check.nu`
  is staged deleted by the concurrent `09-simplify/03-help-system` pass and
  `help.nu` has no `--check` flag. `internals/index.md:15` still describes
  `internals/help.md` as "How `help` and `help --check` are built". Same owner;
  left alone.
- **`AGENTS.md` still tells every agent that `help --check` "reports it as
  undocumented and exits non-zero".** That sentence is now false. Outside this
  PRD's footprint, so not edited.

## Health floor

`install.sh`, scored **39** (branching, longest) on the 493-line version, is
the one file in the footprint under the floor. It moved a long way inside the
spec's scope rather than by a refactor:

| | before (`938bac6`) | after |
|---|---|---|
| lines | 493 | 78 |
| branch keywords (`if`/`elif`/`case`/`for`/`while`/`&&`/`\|\|`) | 51 | 10 |
| longest function | the dry-run `run()` wrapper and the OS dispatch | none — no function is over 3 lines |

The three drivers of the old score are gone with the material that caused
them: the dry-run seam, the APT/PACMAN/DNF dispatch, and the Neovim version
floor. No `.pearde/health/` note was rewritten — the health record is the
orchestrator's to rescore, and writing it is outside my scope.

## Knowledge

Pass one reported two Homebrew facts written back and unconfirmed. **They had
not landed** — a query for them today returned 32 hits, 0 strong, and the tool
enqueued a gap. Both are now on record:

- `[[260902-4c37]]` — `brew bundle` skips an untrusted third-party tap and
  still exits 0
- `[[260902-0a18]]` — `brew bundle check` reports the machine, not the Brewfile

No `conclude` was written: the two notes answer different questions, so there
is no pair of sources agreeing on one claim.

## Workflow replace-a-hand-rolled-mechanism

| # | step | outcome |
|---|------|---------|
| 1 | measure-the-premise-not-the-prd | passed, with the documented failure mode — see below |
| 2 | prove-the-replacement-is-a-drop-in | passed. `/opt/homebrew/bin/tinty` → 0.34.0, `tinty current` → `base16-caroline`, `tinty list` → 538 entries. State unmoved |
| 3 | delete-the-shadow-the-replacement-leaves | passed. `command -v tinty` → `/opt/homebrew/bin/tinty`; `~/.local/bin/tinty` does not exist |
| 4 | prove-nothing-reads-it | passed. Every identifier grepped tree-wide; one reader found, out of scope, reported not fixed |
| 5 | apply-scoped-not-bare | passed, and it fired for real — the neovim.md edit needed a scoped apply |
| 6 | run-the-surface-that-consumed-it | passed. `just --list` names nothing deleted; `chezmoi apply --dry-run` exits 0; three deployed targets still resolve |
| 7 | assert-the-post-state-twice | passed. Three consecutive runs, exit 0, `diff` identical. It failed once first, for a real reason, and the fix was step 5 |

No back-edge was taken. Step 7's first failure was diagnosed and fixed inside
step 5's own remit rather than by re-entering step 6.

**Step 1 hit its own documented `Fails when`.** Every premise had been acted on
by pass one, so a command measuring it would have measured the *result*. The
survivors were measured instead, and the pass that changed each is named:

| requirement | premise | survivor measured today | pass |
|---|---|---|---|
| R1 | `rust` is only there for `rustfmt` | `conform.lua:21` still reads `rust = { "rustfmt" }` — the premise **reproduces**, so the offer to drop `rust` is declined and it stays in the Brewfile | one built, two re-measured |
| R2 | `install.sh` is 493 lines with a dry-run seam | `git show 938bac6:install.sh \| wc -l` → 493; working tree → 78 | one |
| R3 | the script is 112 lines around a `SHELL_INIT_BREW_PREFIXES` seam | 35 lines, seam absent, output byte-identical at 2280/1966/1809 | one |
| R4 | 65 lines of prose around one finding | 29 lines, finding at `:4`/`:8` | one |
| R5 | `Dockerfile:6,10` cite `tests/dev-image.sh` | negated `rg` over the four files matches nothing | one |
| R6 | no `internals/` page describes provisioning | **did not reproduce as written**: `internals/` now holds 10 pages and `provisioning.md` is one of them, committed at HEAD by `3f02c2c` | one wrote it, `03-help-system` committed it |

**The counter, written down** — because step 1's second `Fails when` says a
count without its counter cannot be rechecked. "28 entries" is
`brew bundle list --file Brewfile --all | wc -l`: one `tap`, 26 `brew`, one
`cask`. Comment and blank lines are not counted; `brew bundle list` emits
names only.

### Edits

None. Every atomic's command ran as written, every path in the workflow
resolved, and no check was one that cannot fail. Two of the workflow's
`Fails when` clauses fired exactly as described and were handled by the
guidance already in them:

- step 1's "the premise was already acted on by an earlier pass" — the whole
  of this pass, handled by measuring the survivor and naming the pass.
- step 5's "`chezmoi diff` renders `home/run_after_*.sh` as new files at
  `$HOME` root" — seen, and correctly read as scripts chezmoi executes rather
  than files it deploys. Not scoped around in a panic.

The workflow's step 6 wants "the surface that consumed it" and this repo's
answer is thin: `just --list` holds five recipes and none named any deleted
thing even before the cut, so that surface can only ever pass. The real
surfaces here were `chezmoi apply --dry-run` and running the rewritten scripts
directly. Not an edit — the atomic already names both — but worth saying that
`just --list` carried no signal on this job.

## Grammar

No word was needed that `grammar.py` does not define.
