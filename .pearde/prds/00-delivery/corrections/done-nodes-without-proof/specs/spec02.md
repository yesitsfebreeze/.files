---
est: 0.25h
executor: orchestrator
footprint:
  - prds/01-capsule/01-container-lifecycle/prd.md
  - prds/01-capsule/02-dev-image/prd.md
  - prds/02-terminal/01-appearance/prd.md
  - prds/02-terminal/02-startup-layout/prd.md
  - prds/02-terminal/03-f5-jump-mode/prd.md
  - prds/03-editor/01-options/prd.md
  - prds/04-shell/03-zoxide/prd.md
  - prds/04-shell/05-history/prd.md
  - prds/04-shell/08-claude-launchers/prd.md
  - prds/05-platform/01-deploy-mechanism/managed-config/prd.md
  - prds/05-platform/02-package-provisioning/packages-installer/prd.md
  - prds/05-platform/03-shell-init-generation/prd.md
  - prds/06-help/02-help-command/prd.md
---

# spec02 — thirteen `prd.md` `verify:` values, pre-resolved

Thirteen `done` nodes carry `verify: ""` while their **own** spec built a
dedicated gate, registered it in `gates/waves.tsv`, and quoted its passing run
in the PRD body. The proof was written and run. The field was left empty.

`verify:` in a `prd.md` is the orchestrator's field, so this is a paste, not a
judgement. Every value below is the command the node's own spec created, and
every one was **executed twice** on 2026-08-23: once by `just gates` through
the wave registry, once bare and alone. Both runs agree.

None of the thirteen is invented. Where a node had no command, this spec leaves
`verify: ""` alone.

## The twelve that are green

Each diff replaces `verify: ""`. Nothing else in any file changes — not
`state`, not `est`, not `actual`, not `claim`, not `deps`, not a body line.

| node `prd.md` | new `verify:` | measured bare, exit 0 |
|---|---|---|
| `prds/01-capsule/01-container-lifecycle` | `"bash tests/capsule-lifecycle.sh"` | `capsule-lifecycle: 60 pass, 0 fail` |
| `prds/01-capsule/02-dev-image` | `"bash tests/dev-image.sh"` | 47 PASS, 0 FAIL |
| `prds/02-terminal/01-appearance` | `"bash tests/wezterm-appearance.sh"` | `wezterm-appearance gate: ALL PASS` (74) |
| `prds/02-terminal/02-startup-layout` | `"bash tests/wezterm-startup-layout.sh"` | `wezterm-startup-layout gate: ALL PASS` (35) |
| `prds/02-terminal/03-f5-jump-mode` | `"bash tests/wezterm-f5-tab-select.sh"` | `wezterm-f5-tab-select gate: ALL PASS` (58) |
| `prds/03-editor/01-options` | `"bash tests/nvim-options.sh"` | 74 PASS, 0 FAIL |
| `prds/04-shell/03-zoxide` | `"bash tests/shell-zoxide.sh"` | 106 PASS, `EXIT=0` |
| `prds/04-shell/05-history` | `"bash tests/shell-history.sh"` | 68 PASS, `EXIT=0` |
| `prds/04-shell/08-claude-launchers` | `"bash tests/shell-claude.sh"` | 51 PASS, `EXIT=0` |
| `prds/05-platform/01-deploy-mechanism/managed-config` | `"bash tests/managed-config.sh"` | 65 PASS, 0 FAIL |
| `prds/05-platform/02-package-provisioning/packages-installer` | `"bash tests/provisioning.sh"` | 115 PASS, 0 FAIL |
| `prds/06-help/02-help-command` | `"bash tests/shell-help.sh"` | 88 PASS, `EXIT=0` |

Two notes on the choice of invocation, both load-bearing:

- The bare form is deliberate where a spec's own `verify:` names a stage.
  `managed-config`'s two specs verify `--gitconfig` and `--surface`;
  `packages-installer`'s three verify `--nvim`, `--shape`, `--packages`. The
  node's proof is the union, and the bare invocation is the union.
- `tests/dev-image.sh` bare is 47 checks against `--static`'s 25. The registry
  runs `--static` in wave 2 because the rest needs a container; bare passes
  today and is the stronger claim.

## The thirteenth, which goes red on purpose

```diff
-verify: ""
+verify: "bash tests/shell-init.sh"
```

on `prds/05-platform/03-shell-init-generation/prd.md`.

Measured three ways — no argument, `--apply`, `--gen`. No argument: exit
**1**, 92 PASS, **2 FAIL**. `--apply` alone: exit 1, the same two. `--gen`
alone: exit 0, 54 PASS. Both failures are in the `apply` stage:

```
FAIL  apply: S1.10 the hand-written ~/.config/television/config.toml is byte-identical after the apply
FAIL  apply: R4 chezmoi managed lists none of the three generated files
```

**Do not reach for a greener command.** `--gen` exits 0 and would make the
node look proven while half its contract fails; that substitution is the exact
defect this family of nodes exists to correct. The node is `done` with a red
gate, the red is the finding, and it needs its own correction node.

The `just gates` run also reported a third failure here —
`the gate wrote nothing outside its scratch (sha256 over prds, docs, gates,
tests, home, install.sh)`, with `changed: /Users/feb/dev/dotfiles/prds`. It is
**not** a defect: the solo run has 2 FAILs, not 3. A concurrent write into
`prds` during the run produced it. Verify any isolation FAIL alone before
believing it.

## Two that must stay `verify: ""`

Reported, not edited, because the reason belongs in each node's own body and
this spec touches only `verify:`.

| node | why no command proves it |
|---|---|
| `prds/00-delivery/corrections/w0-4-s2-corrections` | a parent whose children are all `done`. It has no claim of its own; its proof is the conjunction of theirs |
| `prds/05-platform/02-package-provisioning/homebrew-bootstrap` | `## Absorbed by P.2 — 2026-08-21`, zero specs. Nothing of its own to prove |

## Acceptance

- [x] The thirteen `verify:` values read exactly as the table and the diff
      above.
- [~] **Reworded by the orchestrator: `git diff` cannot answer this, and
      fails the wrong way in both directions.** Twelve of the thirteen files
      are untracked, so the diff is silent on them; the thirteenth
      (`02-terminal/01-appearance`) is tracked, and its diff carries an
      *earlier* `state: claimed → done` transition that shares the uncommitted
      working tree — so run as written this box reports `FAIL  a non-verify
      frontmatter key changed` about a write that is not this spec's. Measured
      both ways: unscoped it names seven unrelated nodes' transitions; scoped
      to the thirteen it names exactly `-verify: ""` / `+verify: "bash
      tests/wezterm-appearance.sh"` plus that one transition. Met instead by
      content: all thirteen frontmatter blocks parse, every key is well
      formed, and each `verify:` reads exactly as the table (`bad: 0`).
      The check's own defect is
      [`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md).
- [x] The twelve green commands were each re-run after the edit and each
      exited 0, with its PASS count quoted.
- [x] `bash tests/shell-init.sh` was re-run after the edit and exited 1 with
      the two `apply:` FAIL lines quoted verbatim.
- [x] The two `verify: ""` nodes above are reported by name to the user as
      needing a one-line reason in their own bodies. Neither file is edited
      here.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
want(){ [ "$(sed -n 's/^verify:[[:space:]]*//p' "$1" | head -1)" = "$2" ]; }

want prds/01-capsule/01-container-lifecycle/prd.md '"bash tests/capsule-lifecycle.sh"'
p "01 container-lifecycle repointed" $?
want prds/01-capsule/02-dev-image/prd.md '"bash tests/dev-image.sh"'
p "02 dev-image repointed" $?
want prds/02-terminal/01-appearance/prd.md '"bash tests/wezterm-appearance.sh"'
p "03 appearance repointed" $?
want prds/02-terminal/02-startup-layout/prd.md '"bash tests/wezterm-startup-layout.sh"'
p "04 startup-layout repointed" $?
want prds/02-terminal/03-f5-jump-mode/prd.md '"bash tests/wezterm-f5-tab-select.sh"'
p "05 f5-jump-mode repointed" $?
want prds/03-editor/01-options/prd.md '"bash tests/nvim-options.sh"'
p "06 options repointed" $?
want prds/04-shell/03-zoxide/prd.md '"bash tests/shell-zoxide.sh"'
p "07 zoxide repointed" $?
want prds/04-shell/05-history/prd.md '"bash tests/shell-history.sh"'
p "08 history repointed" $?
want prds/04-shell/08-claude-launchers/prd.md '"bash tests/shell-claude.sh"'
p "09 claude-launchers repointed" $?
want prds/05-platform/01-deploy-mechanism/managed-config/prd.md '"bash tests/managed-config.sh"'
p "10 managed-config repointed" $?
want prds/05-platform/02-package-provisioning/packages-installer/prd.md '"bash tests/provisioning.sh"'
p "11 packages-installer repointed" $?
want prds/06-help/02-help-command/prd.md '"bash tests/shell-help.sh"'
p "12 help-command repointed" $?
want prds/05-platform/03-shell-init-generation/prd.md '"bash tests/shell-init.sh"'
p "13 shell-init-generation repointed" $?

# only verify: lines moved
git diff -U0 -- prds | grep -E '^[+-][a-z_-]+:' | grep -vE '^[+-]verify:' \
  && { echo "FAIL  a non-verify frontmatter key changed"; rc=1; } \
  || echo "PASS  only verify: lines changed"

# the twelve are green, run alone
for g in capsule-lifecycle dev-image wezterm-appearance wezterm-startup-layout \
         wezterm-f5-tab-select nvim-options shell-zoxide shell-history \
         shell-claude managed-config provisioning shell-help; do
  bash "tests/$g.sh" > /dev/null 2>&1
  p "tests/$g.sh exits 0" $?
done

# the thirteenth is red, and says why
bash tests/shell-init.sh 2>&1 | grep -q 'R4 chezmoi managed lists none'
p "tests/shell-init.sh still reports the two apply failures" $?

# the two that stay empty are byte-unchanged
git diff --quiet -- prds/00-delivery/corrections/w0-4-s2-corrections/prd.md \
  prds/05-platform/02-package-provisioning/homebrew-bootstrap/prd.md
p "the two unprovable nodes are untouched" $?

exit $rc
```
