# pearde-shell-wiring — implementer report

Verdict: DONE

Pass two re-ran every acceptance box against the tree as I found it rather
than inheriting pass one's claim. **8 of 8 boxes in `specs/spec01.md` are
`[x]`**, each ticked as it closed, against output quoted below. The probe
passes 8 of 8, `help --check` exits 0 with `undocumented: 0`, and all five
footprint paths are deployed with an empty `chezmoi diff`.

**Corrected after review.** A skeptic found that my own `probe/verify.sh`
carried the same class of defect I caught in box 6: its box-4 arm could not
fail on a missing alias. The claim it guards was true, but the guard was not
a guard. It is fixed and the fix is proven below. Nothing else changed.

Nothing was left blocked and no question needs putting to anyone.

## What I changed

**No configuration change.** Pass one's code was already correct and already
deployed; my job was to prove it, and re-proving is what these boxes are for.
The files I wrote are this report, the eight ticks in `specs/spec01.md`, one
knowledge conclusion, and — after review — two fixes to `probe/verify.sh`.
Nothing under `home/`, `.pearde/workflows/` or `prd.md` was touched.

## The boxes, with the output that closed them

| # | box | proof |
|---|---|---|
| 1 | `env.nu` sets `$env.PEARDE_AS`, comment says what reads it | `env.nu:55` `$env.PEARDE_AS = "engineer"`, under 12 lines of comment naming the refusal |
| 2 | `config.nu` aliases `pearde` at the SOURCE repo | `config.nu:88` `alias pearde = python3 ~/dev/infra/pearde/resources/pearde.py` |
| 3 | `chezmoi diff` empty for both | empty, rc 0 |
| 4 | a config-loaded shell runs `pearde sweep --dry` | `sweep: no claim silent past claim-ttl 30m` — on a check that can now fail; see below |
| 5 | a bare interactive `nu` shows the same two | tmux probe: `MARK=engineer` and `sweep: ...` |
| 6 | `help --check` exits 0, `undocumented: 0`, allowlist unchanged | `REAL_EXIT=0`; `help-check.nu:322` still `alias: ["core-help" "core-ls"]` |
| 7 | `help "pearde [cmd]"` prints it, verify target right | entry prints; `shell.nuon:643` `verify: [{kind: "alias", name: "pearde"}]` |
| 8 | generated pages carry it and regenerate byte-identical | see below |

Box 6's exit code needed care. My first reading piped `help --check` into
`tail`, so `$?` returned **tail's** status, not nushell's — a clean `0` that
proves nothing. Re-run as `nu ... -c 'help --check' >/dev/null; echo $?` it is
a genuine `REAL_EXIT=0`.

Box 8, stronger than the spec asked. The spec compares the two `agents.md`
pages across a regeneration; I snapshotted the **whole** `help/manual/` tree
instead, because the brief asked which generated pages `just manual` rewrites
beyond my own entry. The answer is **none**:

```
=== FULL manual dir diff across a regeneration ===
ok  ENTIRE manual corpus byte-identical after regeneration
ok  just manual leaves the corpus byte-identical too
```

I ran it through `node scripts/generate-manual.mjs` and again through `just
manual` (`justfile:42-43` shows the recipe is exactly that node call). The
manual pages already dirty against HEAD before my run are dirty because they
were regenerated earlier, not hand-edited — they are generator-consistent
right now. **I reverted nothing.**

## The probe's box-4 check could not fail — found by review, fixed

Credit where due: a skeptic re-reading `probe/verify.sh:41-47` found that its
box-4 arm green-lit a missing alias, and was right. I reproduced it before
changing anything rather than taking the report on trust.

The old arms graded `*refused*` bad, `*"unknown command"*` and
`*"executable was not found"*` bad, and **everything else `ok`**. nushell
0.115.1 emits neither of those strings. Captured live:

```
Error: nu::shell::external_command
  x External command failed
 1 | pearde sweep --dry
   :    `-- Command `pearde` not found
  help: Did you mean `parse`?
```

Fed through the old case logic verbatim, that graded `VERDICT: ok`. The
underlying claim survived only by luck — the tmux step greps the pane for
`sweep: `, which an error banner lacks — and that step printed `skip` and
exited 0 when `command -v tmux` failed, so on a machine without tmux nothing
in the probe could detect the missing alias at all.

Two fixes, both in `probe/verify.sh`:

1. **Grading is now positive and the default arm is `bad`.** Only the success
   shape `*"sweep: "*` passes; a `*"not found"*` / `*"External command
   failed"*` arm catches the real error, and any unrecognised output fails.
   Enumerating failures and defaulting to success is the bug itself — the one
   output it did not enumerate was the only one that mattered.
2. **The no-tmux branch fails instead of skipping.** That branch is the only
   check proving the shell you actually GET loads these files; every other
   check names both config paths explicitly and so proves only that the files
   work. Skipping it and exiting 0 reported a green probe that never tested
   the claim.

Proven by grading real text through the new logic, not by assertion:

```
1. REAL missing-alias error (captured live)  -> bad (unresolved)
2. REAL success output (config-loaded shell) -> ok
   text: sweep: no claim silent past claim-ttl 30m
3. persona refusal shape                     -> bad (refused)
4. unrecognised junk                         -> bad (unrecognised)
```

And the no-tmux branch tested for real, not simulated — a shim PATH holding
`nu`, `chezmoi` and `git` but genuinely no tmux (all four share
`/opt/homebrew/bin`, so dropping the directory was not an option):

```
tmux visible in shim PATH? -> NO (good)
FAIL no tmux — the bare interactive shell could not be checked
EXIT_UNDER_NO_TMUX=1  (must be non-zero)
```

Full probe on the normal PATH after the fix: **8 of 8 ok, PROBE_RC=0.**

The lesson generalises past this file, and I had already written half of it in
box 6 without applying it to my own artifact: a check whose default branch is
success is not a check. Both defects in this run — the piped exit code and
this — are the same shape.

## The repo's own gate

`help --check`, and it is clean. The justfile exposes only `default`,
`cutover` and `manual` — there is no test or gate recipe, which matches the
contract's note that `tests/` and `gates/` were deleted on 2026-08-31. The
three `unresolved: 3` nvim buffer-local findings predate this change and do
not fail the check.

## Step 3 earned its place

`chezmoi diff` showed four unrelated pending items before and after my run,
unchanged: `.config/nvim/lazy-lock.json`, and `generate-shell-init.sh`,
`register-mcp.sh`, `seed-mason-registry.sh`. The last three render as
additions at `$HOME` root because they are `home/run_after_*.sh` run-scripts.
A bare `chezmoi apply` would have carried all four along.

## The trap, re-measured rather than inherited

I did not take pass one's word for the step-4 trap. Measured again, nushell
0.115.1:

```
nu -c 'print $env.PEARDE_AS?'  -> UNSET                    (deployed, correct)
nu -c 'pearde sweep --dry'     -> External command failed
nu -c 'print $env.EDITOR?'     -> nvim        (inherited — looks loaded)
nu --env-config ... --config ... -c 'print $env.PEARDE_AS?' -> engineer
```

Two independent measurements now agree, so the two source notes are promoted
to a conclusion:
`[[a-nushell-config-change-must-be-proved-in-a-shell-that-loade]]`, from
`[[260902-6c05]]` and `[[260902-181d]]`.

## Findings — outside my scope, not fixed

**1. `prd.md` is still an unfilled template.** The body under the `#` heading
is the angle-bracket instructions. The contract survives only in this report
and in `specs/spec01.md`; if both were lost the PRD would say nothing about
what was built. I did not write the body — that is analyst work and the brief
forbids me the frontmatter. Worth fixing at the source: a PRD that reaches an
implementer with no body is only buildable because a memory note happened to
name it.

**2. `why-review.nuon` and `use-review.nuon` instruct a deleted gate.**
Independently reproduced. `why-review.nuon:19,30,42` and
`use-review.nuon:20,51` name `tests/help-content-model.nu` as the enforcer;
`ls` on that path answers *No such file or directory*. The proof it is now
inert: my entry carries a `why`, `grep -c pearde why-review.nuon` returns
**0**, and `help --check` still reports clean. I added no row — the digest
those files ask for is printed by the deleted gate, and inventing one would
put a false "somebody read this" on the record. Deserves a correction of its
own.

## Word not in the grammar

None. Every term in the brief resolved.

## Workflow wire-a-tool-into-the-shell

| # | step | outcome | note |
|---|---|---|---|
| 1 | `recover-the-contract` | pass | Re-confirmed from two sources myself: `install.sh:216-218` prints both lines verbatim, and `references/install.md` documents them. Neither is my inference from the other. |
| 2 | `write-into-the-chezmoi-source` | pass | `chezmoi source-path` gives `/Users/feb/dev/dotfiles/home`. Both lines already there, at the anchors, each with a comment naming what reads it and the refusal when unset. |
| 3 | `apply-scoped-not-bare` | pass | Scoped diff empty; the four unrelated pending items still pending. |
| 4 | `prove-in-a-shell-that-loaded-the-config` | pass, after a fix | Both forms answer and the `nu -c` trap was re-measured, not inherited. But the probe arm asserting it could not fail — found by review, reproduced, fixed, and the fix proven by grading real failure and success text through the new logic. |
| 5 | `document-the-new-surface` | pass | Entry at `shell.nuon:634-644`; whole corpus regenerates byte-identical. |
| 6 | `rerun-the-drift-check` | pass | `undocumented: 0`, `help --check: clean`, real exit 0. |

No back-edge was taken. Every step passed first time. Step 4's claim held
throughout; what failed review was the probe arm guarding it, corrected in
place without reopening the step.

### Edits

None of these four atomics has a `## Fails when` body at all —
`rerun-the-drift-check.md` has the heading with nothing under it, and the
other three lack the heading entirely. Below is replacement text for the
shapes this run actually hit. **I did not edit the workflow files.**

**`rerun-the-drift-check.md` — frontmatter, `subject:`.** It currently reads
``subject: help --check` is the one command...`` — the opening backtick is
missing, so the value starts mid-token. Replace with:

```
subject: "`help --check` is the one command that says the configuration and its manual still agree"
```

**`rerun-the-drift-check.md` — add under `## Fails when`:**

```
- The check is piped — `help --check | tail`, `| grep` — and `$?` is then the
  PIPE's exit code, not nushell's. It reads as a clean 0 no matter what the
  check did. Run it as `nu ... -c 'help --check' >/dev/null; echo $?` when the
  exit status is what you are claiming.
- It exits 0 while reporting a non-zero `unresolved:` count. `unresolved` does
  NOT fail the check — measured 2026-09-02, `unresolved: 3` alongside
  `help --check: clean` and exit 0. Read the `undocumented:` line for your own
  surface; do not read a clean exit as "no findings".
- It reports `undocumented: 0` because the surface was added to `HC_ALLOW`
  rather than documented. Grep the allowlist and confirm it is unchanged — a
  passing check and a hidden surface look identical from the exit code.
```

**`prove-in-a-shell-that-loaded-the-config.md` — add `## Fails when`:**

```
- The tmux probe is read before the shell has finished starting, and
  `capture-pane` returns an empty or half-drawn pane that greps as a failure.
  nushell's startup is not instant: allow ~6s after `new-session` and ~8s
  after `send-keys` before capturing, as `probe/verify.sh` does.
- The check names a variable that already existed. Then both forms answer and
  neither proves anything about this change. Pick a name that did not exist
  before the change — that is what makes the check falsifiable.
- The probe enumerates the FAILURE strings and defaults to success. nushell
  0.115.1 answers an unresolved alias with "Command `x` not found" under a
  nu::shell::external_command banner — not "unknown command", not "executable
  was not found" — so a probe written against those two strings grades a
  missing alias OK. Match the SUCCESS shape positively and make the default
  arm fail; measured 2026-09-02.
- The bare-shell step is skipped when `tmux` is absent and the probe still
  exits 0. That step is the only one proving the shell you actually get loads
  the config; every other check names both config paths explicitly. A skipped
  bare-shell check must FAIL the probe, not pass it quietly.
```

**`document-the-new-surface.md` — add `## Fails when`:**

```
- Only the pages your entry touches are compared across the regeneration, so a
  generator that also rewrote unrelated pages goes unnoticed. Snapshot the
  WHOLE manual tree and `diff -rq` it; the honest claim is "the corpus is
  byte-identical", not "my two pages are".
- `git diff --exit-code` is used to prove the pages are generated. It fails on
  the very change being blessed, because the pages are legitimately dirty
  against HEAD while the PRD is in flight. Compare each page to ITSELF across
  a regeneration instead.
```

**`apply-scoped-not-bare.md` — add `## Fails when`:**

```
- `chezmoi diff` renders `home/run_after_*.sh` run-scripts as new files at
  `$HOME` root, which reads as three scripts about to be written into the home
  directory. They are scripts chezmoi EXECUTES, not files it deploys.
  Alarming, not a defect — do not scope around them in a panic.
```
