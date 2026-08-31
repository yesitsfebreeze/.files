---
est: 0.25h
footprint:
  - prds/04-shell/02-aliases-utilities/prd.md
  - prds/04-shell/06-listing/prd.md
  - prds/00-delivery/verification-gates/prd.md
  - prds/01-capsule/03-credential-propagation/prd.md
  - prds/03-editor/04-plugin-manager/prd.md
executor: orchestrator
---

# spec03 — five `prd.md` frontmatter `verify:` values, pre-resolved

The census turned up a second class the finding did not anticipate: five
`prd.md` frontmatter `verify:` values on **`done`** nodes that cannot execute
as written, none of them `.mi/`-rooted. Two name a real file but never invoke
an interpreter, and three are prose rather than a command.

`verify:` in a `prd.md` is the orchestrator's field. Every replacement below
is quoted verbatim and was **measured** by the analyst on 2026-08-23, so this
is a paste, not a judgement. None of the five was invented: in each case
the replacement is the command the node's **own spec** built to prove it.

## The five edits

**1 · `prds/04-shell/02-aliases-utilities/prd.md`**

```diff
-verify: "tests/nushell-aliases.sh"
+verify: "bash tests/nushell-aliases.sh"
```

The file exists but its mode is `-rw-r--r--`, so invoking it as a command
exits **126**. Measured with `bash`: `CHECKS: 39 run, 39 passed, 0 failed`,
exit 0. The node is `done` and now provably so.

**2 · `prds/04-shell/06-listing/prd.md`**

```diff
-verify: "tests/shell-listing.sh"
+verify: "bash tests/shell-listing.sh"
```

Same cause, exit **126** as written. With `bash` the gate *runs* and exits
**1** with one failure:

```
FAIL  tree: T1 counterfactual core-ls-after-def-ls FAILS the order check
```

This node is `done` with a red gate. **Do not reach for a command that makes
it green** — the red is the finding. It needs its own correction node; that
node is not this one's to write, and the `verify:` above is correct as it
stands.

**3 · `prds/00-delivery/verification-gates/prd.md`**

```diff
-verify: "every gate script exits non-zero on an induced failure; the runner runs the whole set in one command"
+verify: "just gate-selftest && just gates"
```

The prose is not paraphrased into a command — the node's own
[`spec05`](../../../verification-gates/specs/spec05.md) opens by quoting it
("this node's own `verify:` is 'every gate script exits non-zero on an
induced failure'") and says the spec exists to make it machine-checked,
building `gates/selftest.sh` and the `gate-selftest` recipe; the second
clause is [`spec01`](../../../verification-gates/specs/spec01.md)'s runner,
whose `gates` recipe is documented in `gates/justfile` as "the one command R5
asks for". So the two halves of the sentence are the two recipes.

Measured, both halves. `just gate-selftest` exits **1** with one failure:

```
FAIL  contract: wave-status.sh accepts --selftest and exits 0 (rc 1)
```

`just gates` exits **1** with **13** failures, spanning waves — the first
four being the same `wave-status.sh --selftest` contract, `preflight:
gates/selftest.sh`, `registry: every script under tests/ is named by a row
(unreferenced: nvim-explorer.sh)` and two `apply:` checks. It takes over ten
minutes to run, which is worth knowing before anyone puts it in a loop.

`just gates` is board-wide by construction, so this node's `verify:` goes
green only when the whole board does. That is not too broad by accident —
the node's own requirement is "the runner runs the whole set in one command",
and substituting something narrower to get a green would be inventing a
weaker proof. As with case 2, this node is `done` with a red proof, and the
red is the point.

**4 · `prds/01-capsule/03-credential-propagation/prd.md`**

```diff
-verify: "git push works inside a capsule (wave-4 gate)"
+verify: "bash tests/capsule-credentials.sh"
```

Its own `spec03-credentials-gate.md` builds `tests/capsule-credentials.sh` as
"the gate for spec01 and spec02". Measured: exit **0**,
`capsule-credentials: 102 pass, 0 fail`. The dropped "git push" clause loses
nothing: it is already registered as manual item **C.3** at
`gates/manual/wave4.md:142` ("`git push` over both protocols"), so the manual
half stays where the manual half belongs and nothing needs adding there.

**5 · `prds/03-editor/04-plugin-manager/prd.md`**

```diff
-verify: "nvim --headless '+Lazy! sync' +qa exits 0"
+verify: "bash tests/nvim-plugin-manager.sh"
```

As written this is prose wearing a command's clothes — run it and `nvim`
treats `exits` and `0` as two files to open, so whatever it exits says
nothing. Its own `spec02-gate-and-lockfile.md` builds
`tests/nvim-plugin-manager.sh` (stages `--tree` / `--headless` /
`--network`). Measured with no argument: exit **0**,
`PASS — lazy.nvim bootstrap, opts, and lockfile proven`.

## Five that must be left exactly as they are

These also name a path that does not exist, and that is **correct**: the path
is what the node itself will create. They are forward-looking, not rot, and
editing them would be the census's own failure mode.

| node | `verify:` | creator |
|---|---|---|
| `prds/03-editor/02-keymaps` (`failed`) | `bash tests/nvim-keymaps.sh` | its `spec02-gate.md`, footprint `tests/nvim-keymaps.sh` (create) |
| `prds/03-editor/06-explorer` (`specced`) | `bash tests/nvim-explorer.sh` | its `spec02-gate.md` |
| `prds/03-editor/12-small-plugins` (`specced`) | `bash tests/nvim-small-plugins.sh` | its `spec02-gate.md` |
| `prds/03-editor/15-markdown-tables` (`specced`) | `bash tests/nvim-markdown-tables.sh` | its `spec02-gate.md` |
| `prds/00-delivery/corrections/retired-phrase-sweep` (`open`) | `bash gates/retired-phrases.sh` | its own frontmatter `footprint` |

## Two recommendations this spec does not act on

Both sit on `open` nodes, so their analysts set a real command at spec time
and an edit here would pre-empt them. Recorded so they are not lost:

- `prds/04-shell/07-quicklist` — `verify: "quicklist round-trips a pick
  (wave-5 gate)"`. `quicklist` is not installed; the value is prose.
- `prds/06-help/04-drift-check` — `verify: "help --check exits 0"`. Dropping
  the `exits 0` tail leaves `help --check`, which is a command and is what
  AGENTS.md already promises. `help` does not exist yet, so it stays
  forward-looking either way.

## Acceptance

- [ ] The five `verify:` values read exactly as the diffs above. Nothing else
      in any of the five files changes — not `state`, not `est`, not
      `actual`, not `claim`, not a body line.
- [ ] Each replacement was executed and its exit code quoted: 0 for cases 1,
      4 and 5; 1 for cases 2 and 3, with the FAIL line quoted verbatim.
- [ ] The five forward-looking values in the table are byte-unchanged:
      `grep -nF` each of the five against its file, output quoted, and the
      count of matches equal to five. `git diff` over
      `prds/03-editor prds/00-delivery/corrections/retired-phrase-sweep`
      cannot carry it — `prds/03-editor` is 15 of 45 tracked and the
      `retired-phrase-sweep` node is untracked entirely (`git ls-files --error-unmatch`, 2026-08-23),
      so "shows nothing" is what an untracked tree always shows. Unprovable in
      retrospect: the pre-edit state was untracked, so git never held a copy
      and no `cp` aside was kept. What would have proved it: the five `grep
      -nF` lookups above, run before and after.
- [ ] The two `done`-but-red nodes (`04-shell/06-listing`,
      `00-delivery/verification-gates`) are reported by name to the user as
      needing their own correction node. Neither gate is edited here.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

want(){ [ "$(sed -n 's/^verify:[[:space:]]*//p' "$1" | head -1)" = "$2" ]; }

want prds/04-shell/02-aliases-utilities/prd.md '"bash tests/nushell-aliases.sh"'
p "1 aliases-utilities repointed" $?
want prds/04-shell/06-listing/prd.md '"bash tests/shell-listing.sh"'
p "2 listing repointed" $?
want prds/00-delivery/verification-gates/prd.md '"just gate-selftest && just gates"'
p "3 verification-gates repointed" $?
want prds/01-capsule/03-credential-propagation/prd.md '"bash tests/capsule-credentials.sh"'
p "4 credential-propagation repointed" $?
want prds/03-editor/04-plugin-manager/prd.md '"bash tests/nvim-plugin-manager.sh"'
p "5 plugin-manager repointed" $?

# the three that must be green
bash tests/nushell-aliases.sh    > /dev/null 2>&1; p "case 1 exits 0" $?
bash tests/capsule-credentials.sh > /dev/null 2>&1; p "case 4 exits 0" $?
bash tests/nvim-plugin-manager.sh > /dev/null 2>&1; p "case 5 exits 0" $?

# the two that must stay red, and say why
bash tests/shell-listing.sh 2>&1 | grep -q 'core-ls-after-def-ls'
p "case 2 still reports the T1 counterfactual failure" $?
bash gates/selftest.sh 2>&1 | grep -q 'wave-status.sh accepts --selftest'
p "case 3a still reports the wave-status --selftest failure" $?
# case 3b takes >10 min; run it once and quote the count rather than looping
just gates > /tmp/jg.txt 2>&1
[ "$(grep -ci '^FAIL' /tmp/jg.txt)" -ge 1 ]
p "case 3b just gates is red (13 FAILs at spec time)" $?

# the forward-looking five are untouched
git diff --quiet -- prds/03-editor prds/00-delivery/corrections/retired-phrase-sweep
p "the forward-looking values are byte-unchanged" $?

exit $rc
```
