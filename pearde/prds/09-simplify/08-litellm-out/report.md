# 08-litellm-out — implementer report

Verdict: DONE

Both specs implemented and verified. spec01 stands in the lane
`lane/09-simplify-08-litellm-out`, 15 files, verify green twice and falsifiable.
spec02 is built and live on the machine: `~/dev/llm-router` is a git repo at
`f48463d`, and the five commands are symlinks into it from `~/.local/bin`.

**Two boxes cannot close inside a lane and are named below with the exact
command that closes them.** `chezmoi`'s source root is the LIVE repo
(`/Users/feb/dev/dotfiles/home`), not this lane, so spec01's deletions do not
reach the machine until the lane is merged. Until then `~/.config/nushell/litellm.nu`
is still deployed and still sourced, and its `def cll` shadows the new binary.
The post-merge state is proven, not assumed — see **The one wall**.

---

## Per-spec box status

### spec01 — cut the router out of `home/`

| box | state | evidence |
|---|---|---|
| No file under `home/` is a router source | [x] | all six absent; `git status` shows 6 `D` |
| `config.nu` has no `litellm` line | [x] | `grep -c litellm` -> 0 |
| `shell.nuon` parses, no `cll`/`llm` row | [x] | parses, 38 rows, router rows -> 0 |
| `nvim.nuon` parses, no dangling `also:` | [x] | parses; `"cll [model]"` -> 0 hits |
| `.chezmoiremove` names `litellm.nu`, nothing under `.local/bin/` | [x] | 14 entries, `^\.local/bin/` -> 0 |
| Exactly four files still name `cll`/`litellm` | [x] | matches the spec's `want` string exactly |
| Manual byte-identical on a second run | [x] | three hashes identical, `3669281859b2…` |
| `deploy-into-a-throwaway-home.sh` exits 0 twice | [x] | `rc=0`, `rc=0`, identical output |
| After `chezmoi apply` + fresh terminal, `<leader>xc` and `cc` open Claude Code | [ ] | **needs the merge** — see below |

### spec02 — the router as its own project

| box | state | evidence |
|---|---|---|
| `~/dev/llm-router` is a git repo with `bin/`, `litellm.nu`, `README.md`, `install.sh` | [x] | `git ls-files` lists 9; commit `f48463d` |
| Each of the five parses under its own shebang | [x] | 3x `bash -n`, 2x `py_compile`, all ok |
| `install.sh` idempotent — five links, exits 0 both times | [x] | `rc=0` twice, five links asserted after |
| `nu -l -c 'which cll'` resolves into the project | [ ] | **shadowed pre-merge** — see below |
| `cll --list` exits 0 and prints a model name | [x] | `rc=0`, 79 model names |
| No `~/.local/bin` name is a regular file any more | [x] | all five now symlinks into the project |
| `README.md` names three couplings and four lost gestures | [x] | greps green; falsifiability confirmed |
| `fzf-model-picker` says where the picker lives | [x] | **orchestrator's box** — read and confirmed at `prd.md:49-50` |

Verify output, both specs, run twice with no change between:

```
spec01 RUN 1 -> OK  (rc=0)     spec01 RUN 2 -> OK  (rc=0)
spec02 RUN 1 -> OK  (rc=0)     spec02 RUN 2 -> OK  (rc=0)
```

Falsifiability (step 10): `touch home/dot_local/bin/executable_cll` ->
`FAIL: … still here`, rc=1. Redacting `pi/agent/auth.json` from the README ->
rc=1. Both restored, both blocks green again.

---

## The one wall — two boxes, one cause, one command

`chezmoi source-path` is `/Users/feb/dev/dotfiles/home`. A lane is a separate
worktree, so **no apply from this lane reaches the machine**, and a scoped apply
`--source LANE/home --destination $HOME` is worse than useless: the lane's
`config.nu` is the branch-point version, and deploying it would erase
`09-simplify/05-terminal`'s pending PALETTE change from the machine. Step 6
forbids exactly that, so I did not do it.

So on this machine right now: `~/.config/nushell/litellm.nu` is still deployed,
`config.nu:236` still sources it, and its `def --wrapped cll` **shadows** the
new binary. `nu -l -c 'which cll'` answers `~/.config/nushell/litellm.nu`. This
is not a defect in either spec — it is spec01 not yet deployed.

**Proven, not assumed.** I deployed the lane into a throwaway destination and
pointed nushell at that config:

```
nu --env-config $D/.config/nushell/env.nu --config $D/.config/nushell/config.nu \
   -c 'which cll | get path | first'
-> /Users/feb/.local/bin/cll          # and that is a symlink to ~/dev/llm-router/bin/cll
-> which cc -> /Users/feb/.config/nushell/claude.nu   # cc survives
```

Nothing changed but the `source` line. So both boxes close the moment the lane
is merged and applied. **After merging, the orchestrator runs:**

```sh
cd /Users/feb/dev/dotfiles
chezmoi diff                       # read what else is pending — 05-terminal has work here
chezmoi apply --force ~/.config/nushell/litellm.nu ~/.config/nushell/config.nu
test ! -e ~/.config/nushell/litellm.nu       # the retirement fired
nu -l -c 'which cll | get path | first'      # must now answer ~/.local/bin/cll
```

`--force` is required: step 8 measured that a retired target chezmoi no longer
recognises prompts, and headless that is `could not open a new TTY`, exit 1.

The nvim half is verified to the limit a headless run allows — the plugin loads,
`terminal_cmd` reads `cll`, and `cll` resolves to the project:

```
claudecode loaded: true   terminal_cmd: cll
command -v cll -> /Users/feb/.local/bin/cll -> /Users/feb/dev/llm-router/bin/cll
```

Only the keypress itself is unproven, and that needs a person.

---

## Findings

### F1 — 947 bytes of uncommitted `cll` work the move would have destroyed

The gravest thing found. `home/dot_local/bin/executable_cll` is **12005 bytes at
HEAD and 12952 in the live working tree**, uncommitted. The deployed
`~/.local/bin/cll` is byte-identical to the working tree, not to HEAD — so the
newer version is the one actually running on this machine.

The 947 bytes are the proxy auto-start: `proxy_live()`, a `nohup litellm-up`
with a 60s liveliness poll, and a comment recording why the wait polls
liveliness rather than the child it spawned (two racing `cll`s each spawn one;
the loser dies on the bound port). None of the other five files diverge.

spec02 step 2 says to take the files from `git show <sha>:…`, and the staging
probe uses `HEAD`. Following that literally would have shipped a `cll` **older
than the one on the machine**, and the merge — which deletes the live source
file — would then have destroyed the auto-start permanently, with no copy left
anywhere. I took `cll` from the live working tree instead and recorded it in the
project's commit message. Every other file came from `HEAD` as written.

This is not a redefinition of the spec: the spec asks for "the six files before
spec01 lands", and the working tree *is* what stands before it lands. There was
one correct action, so per step 1 it is a finding, not a fork.

### F2 — `config.nu` is held by another node's live claim, but the hunks are disjoint

`just board-guard` refuses `home/dot_config/nushell/config.nu`:

```
held by 09-simplify/05-terminal (claimed, claim implementer-terminal 2026-09-02 15:02)
```

Both nodes list it in their footprint. I checked whether they actually collide:
they do not. This node deletes **line 236** (`source ~/.config/nushell/litellm.nu`);
05-terminal rewrites the PALETTE block at **lines 249-271**. Disjoint hunks — the
merge applies both cleanly. The orchestrator should still sequence them rather
than let two workers write the file at once. `just board-guard-blocks` is green.

### F3 — the PRD's R2 names a directory this repo never had

R2 asks that `home/dot_config/litellm/` leave `home/`. It is not in the worktree,
not at HEAD, and not in `git ls-files` — the repo has never held it. The deployed
`~/.config/litellm/config.yaml` exists but is **generated at runtime** by
`litellm-gen-config`, not deployed by chezmoi (`chezmoi managed` does not list
it). The requirement is scoped wrong against the tree. Per step 1 I did not
repair it and did not ask. It is correctly absent from spec01's footprint, so
nothing is left undone — but the config.yaml on this machine is now an orphan
that the project regenerates, and no requirement covers it.

### F4 — the PRD's "nineteen state directories" is twenty entries

`cll`'s `for item in … ; do` list holds **twenty** names — nineteen directories
plus `history.jsonl`, which is a file. Counter, written down per step 1's second
Fails-when: whitespace-separated tokens of that list, deduplicated, `= 20`. The
PRD's "nineteen" is right about directories and wrong about entries. The README
states both numbers with the counter so a recount is possible.

### F5 — `Ctrl+click` is a dangling `also:` target, pre-existing, outside scope

A whole-surface check of every `also:` target against every `cmd`/`key` across
the six help `.nuon` files found exactly one dangling link: `Ctrl+click`. It
dangles identically at HEAD (108 names, 1 dangling) and in the lane (104 names, 1
dangling). Not caused by this change; not fixed. The 108->104 drop is exactly the
four router rows, which is a clean confirmation the cut took what it meant to.

### F6 — a transient until the merge

`~/.local/bin/{cll,litellm-env,litellm-gen-config,litellm-up,llm-quota}` are now
symlinks into the project, but the LIVE chezmoi source still manages those five
paths as regular files. **Any `chezmoi apply` before the merge will overwrite the
symlinks back to regular files**, silently un-installing the project. The merge
removes the source files and ends it. If someone applies in the meantime, `sh
~/dev/llm-router/install.sh` puts it back.

---

## Health floor

The brief listed no file under the floor, and none of my edits lowered one.
Nothing moved.

---

## Workflow cut-a-feature-its-readers-still-name

| # | step | result | note |
|---|---|---|---|
| 1 | measure-the-premise-not-the-prd | pass | every spec01 premise reproduced; two PRD requirements scoped wrong (F3, F4) |
| 2 | prove-nothing-reads-it | pass | whole-tree grep; one hit outside `home/` (`docs/simplification-plan.md`), a plan document, not a reader. `chezmoi managed` asked who owns the targets — and the byte-count comparison it prescribes is what found F1 |
| 3 | stage-the-extraction-in-a-throwaway-project | pass | `stage-the-router-project.sh` rc=0; 3 bash + 2 python3 parse, PATH sibling resolution survives, reach-back into `config.nu` at `cll:204` named and written into the README |
| 4 | carry-the-why-across-the-rewrite | pass | the `~/.local/bin/cll:212-221` line-number pointer became a description plus the `terminal_cmd = "claude"` fallback; `## litellm.nu` removed and re-pointed from `internals/neovim.md`; pointer check found no dead links this change made |
| 5 | regenerate-every-derived-surface | pass | `just manual` = `node scripts/generate-manual.mjs`; fixed point across two runs; tree already matched; no removed string survives in the generated manual |
| 6 | apply-scoped-not-bare | **not run — correctly** | `chezmoi diff` read first: the three `run_after_*.sh` rendered as new files at `$HOME` root exactly as the atomic predicts (executed, not deployed), and 05-terminal's work is pending. The lane is not the source root, so no apply from here can be scoped safely. See **The one wall** |
| 7 | prove-in-a-shell-that-loaded-the-config | pass | `nu -l`, both-configs-named, and a bare tmux `nu` (6s/8s waits) all answered. Positive-shape match with a failing default arm. Found the shadowing that blocks the box |
| 8 | check-what-apply-left-behind | pass | tested at DEPLOYED paths, not source paths; the five orphans were regular files and are now the replacement's symlinks; `litellm.nu`'s retirement carried by `.chezmoiremove` and proven to fire in the throwaway destination |
| 9 | prove-the-orphan-can-be-owned-by-its-replacement | pass | `chezmoiremove-vs-external-install.sh` rc=0 — foreign file deleted on passes 2 and 3, symlink deleted on pass 4. `.chezmoiremove` is a permanent uninstaller, so spec01 keeping `.local/bin/` out of it is correct, and the replacement owning the names is the right mechanism |
| 10 | run-the-verify-twice | pass | both blocks twice, identical output; both assertions broken on purpose and both went red; no assertion names an act, and no `git add`/`git commit` appears in either block |

No back-edge was taken. Every step ran once, in order, except step 6, which was
read and deliberately not executed for the reason its own Do step gives.

### Edits

Three atomics cost me something. Replacement text follows; I have not touched
the workflow files.

**1. `stage-the-extraction-in-a-throwaway-project`, Do step 1** — the atomic says
to write each file out of the commit that still holds it. That is wrong whenever
the file being moved has uncommitted changes, which is the normal state of a
dotfiles working tree and was the state here (F1). Replace Do step 1's second
sentence with:

> Build the destination before the deletion is real: `mktemp -d`, then write
> each file out at its deployed mode. Take it from the **working tree**, not
> from the commit, unless you have just proved they are the same: `git show
> HEAD:<p> | wc -c` against `wc -c <p>` against `wc -c <deployed path>`, for
> every file. A file whose worktree and deployed bytes agree with each other but
> not with `HEAD` is carrying uncommitted work that only the machine holds, and
> the deletion this move is part of is what destroys it. Measured 2026-09-02 by
> 09-simplify/08-litellm-out: `cll` was 12005 at `HEAD` and 12952 in both the
> worktree and the deploy — 947 bytes of proxy auto-start that `git show HEAD:`
> would have silently dropped on the floor.

And add to its `## Fails when`:

> - The staging probe reads `HEAD` and the spec repeats it, so both agree and
>   both are wrong. Two sources agreeing is not a measurement when they share an
>   assumption. Compare against the deployed bytes, which is the third,
>   independent witness.

**2. `apply-scoped-not-bare`** — every Do step assumes the apply can be run from
where the work is. In a lane it cannot: `chezmoi source-path` names the live
repo, and a lane is a different worktree. The atomic has no arm for this and I
had to reason it out. Add as Do step 0:

> 0. `chezmoi source-path` first, and compare it to `git rev-parse
>    --show-toplevel`. If they differ you are in a worktree the deploy tool does
>    not read, and **no apply from here reaches the machine**. Do not reach for
>    `--source <this worktree>/home` to force it: the rest of that tree is the
>    branch point, so the apply would deploy every *other* file at its stale
>    version and erase whatever another lane has pending on the machine. Deploy
>    from the source root after the merge, and prove the post-state now by
>    applying into a throwaway `--destination` instead.

**3. `prove-in-a-shell-that-loaded-the-config`, `## Fails when`** — the atomic
warns that the check must name something new, but not that the shell's own
config can make the check answer about the wrong thing entirely. Add:

> - The name being checked is also defined by a module the config `source`s. A
>   nushell `def` **shadows** an identically-named binary on PATH, so `which
>   cll` answers `~/.config/nushell/litellm.nu` however the binary was installed
>   — the check is grading the shell config, not the install. When the same
>   change also retires that module, the check cannot pass until the retirement
>   is deployed, and it will look like the install failed. Assert with `command
>   -v <name>` in a POSIX shell for the install, and keep the nushell form for
>   the retirement. Measured 2026-09-02; recorded as `[[260902-eb4b]]`.

---

## Vocabulary

No term in the contract was unknown. One word I needed and the grammar does not
define: **shadow** in the nushell sense — a sourced `def` making an
identically-named binary on PATH unreachable by that name. The grammar has no
row for it, and `delete-the-shadow-the-replacement-leaves` uses "shadow" for the
different, PATH-ordering sense (an old copy ahead on PATH). Two meanings, one
word, both live on this board — worth a row that separates them.

## Knowledge written back

`sources/260902-eb4b.md` — a nushell `def` sourced from config shadows an
identically-named binary on PATH, with the measurement and the consequence for
any spec that verifies an install with `nu -l -c 'which X'`.
