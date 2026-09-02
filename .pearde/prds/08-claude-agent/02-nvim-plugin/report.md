# 08-claude-agent/02-nvim-plugin — implementer, 2026-09-02

Verdict: DONE

Implementer `impl-nvim`, as engineer, on workflow `land-an-answered-fork`
(its first run). This report **replaces** the analyst's re-spec report of
11:42; that one is history.

**4 of 5 spec01 boxes `[x]`, 1 `[~]`.** Everything the node exists to deliver
is deployed, measured and in git. The `[~]` is box 5 — the scoped commit —
and it is `[~]` rather than `[x]` because the commit was **overtaken by
another agent's 199-file baseline commit two minutes before spec01 was
written**. See `## The one box that could not close`. No action of mine could
have closed it, and I did not redefine it to make it close.

Nothing was left to commit: my footprint is clean against HEAD.

## Box status

| # | box | state | proof |
|---|---|---|---|
| 1 | no live `split_side` key in `claude.lua` | `[x]` | 2 matches, both comment lines |
| 2 | lockfile delta: 3 insertions, 0 deletions, sorted | `[x]` | `3	0	…lazy-lock.json`, 23 entries, sorted True |
| 3 | `chezmoi diff` on the deployed `claude.lua` is empty | `[x]` | no output, exit 0 |
| 4 | `help --check` exits 0, `undocumented: 0` | `[x]` | exit 0, `undocumented: 0`, allowlist `nvim: []` |
| 5 | one commit naming those two paths and no third | `[~]` | overtaken by `5dceabc` (199 files) |

### Box 1 — Q2 landed

```
72:        -- carries `split_side = "right"`. Whatever this call passed would be
76:        -- headless): `split_side = "bottom"` and no key at all both end at
```

Filtering to non-comment lines returns nothing. Q2 ("accept the right-hand
panel, delete the inert setting") is in the file as an absence plus the
comment that explains the absence.

### Box 2 — the three pins

`git show --numstat 5dceabc -- home/dot_config/nvim/lazy-lock.json` →
`3	0` (3 added, 0 deleted). The three added lines:

```
+  "claude-tmux.nvim": { "branch": "main", "commit": "90b221c423385eb18a234e52378a18bc14f6dd5f" },
+  "claudecode.nvim":  { "branch": "main", "commit": "2390c6e45c4789072c293ac69de051d169668b29" },
+  "snacks.nvim":      { "branch": "main", "commit": "882c996cf28183f4d63640de0b4c02ec886d01f2" },
```

No removed line. 23 entries, `sorted: True`, each pin 40-hex on `main`. All
three match the live store exactly (`git -C ~/.local/share/nvim/lazy/<p>
rev-parse HEAD`).

The box's command (`git diff --stat HEAD`) now prints nothing, because the
delta is already **in** HEAD. I proved the delta's shape — which is what the
box asserts — against the commit that carries it. The substitution is
disclosed, not silent.

### Box 3 — source and deployed agree

`chezmoi diff ~/.config/nvim/lua/plugins/claude.lua` → no output, exit 0.

The lockfile target *was* pending and is no longer: the deployed
`~/.config/nvim/lazy-lock.json` named none of the three plugins while all
three were installed in the live store. Applied scoped (step 2 below); both
paths now diff empty.

### Box 4 — the drift check

```
documented 191 · prose-only 15 · allowlisted 24 · live nvim maps 229 …
stale: 0
mismatched: 0
undocumented: 0
unresolved: 3
help --check: clean
```

Exit `0`, run unpiped with output redirected to a file, so `$?` is nushell's
and not a pipeline's. The 3 `unresolved` are pre-existing buffer-local nvim
maps (`q`, autopairs `<BS>`/`<CR>`) that attach on events the dump does not
fire — none is this node's surface. `HC_ALLOW.nvim` is `[]` and the
allowlist file is unmodified against HEAD, so `undocumented: 0` is earned by
documentation, not by hiding.

## The one box that could not close

Box 5 asks for one commit whose `--stat` names `claude.lua` and
`lazy-lock.json` and no third path. There is no such commit and I could not
make one.

Both files were committed at **11:39:04** by `5dceabc` — *"the 2026-09-01
tree as it stood, landed before simplification"*, a deliberate baseline for
`09-simplify` covering **199 files, 3546 insertions, 12135 deletions**.
spec01 was written at 11:41 and says "Both files are `M` in the working tree
and neither is committed"; that sentence was already two minutes stale when
it was written.

The content that landed is correct — `claude.lua` at 88 changed lines and the
lockfile at exactly `3	0`, both verified above. What is missing is only the
*scoping* of the commit, and the PRD's `## Constraints` names it: "Lockfile
discipline. The lazy-lock.json delta commits with the spec". The delta did
commit **with** `claude.lua`, in one commit — it also committed with 197
other paths belonging to other nodes.

Closing this box now would need `5dceabc` rewritten. That commit is
`09-simplify`'s baseline and touches 199 paths outside my footprint, so per
the brief it is a defect outside my scope: reported, not fixed. Nothing in my
footprint is uncommitted, so there is also nothing for a scoped commit to
contain.

**The orchestrator's call**, not mine: accept the unscoped landing, or
reshape history. I recommend accepting it — the delta is additive, correct
and traceable, and the two files did land together.

## Workflow land-an-answered-fork

First run. Rows honest; `## Fails when` on two atomics was empty and my run
fills one.

| # | atomic | outcome | what happened |
|---|--------|---------|---------------|
| 1 | `take-the-answers-not-the-stale-report` | pass | Read `## Answers` first. Q1 maps to spec01's `## Out of scope` (spec02 deleted, its footprint gone with `ad3f1a6`); Q2 maps to acceptance box 1. `report.md` on disk was the **analyst's**, not a failed implementer's — the atomic's premise did not bite this run, but reading the answers first is what surfaced that. No back-edge. |
| 2 | `apply-scoped-not-bare` | pass | `chezmoi diff` bare first: 4 pending targets. Three are `run_after_*` run-scripts rendered as new files at `$HOME` root — **exactly the shape the atomic's `## Fails when` warns about**, and it was correct to leave them alone. The fourth, `.config/nvim/lazy-lock.json`, was mine. Applied by name. Re-diff of both my paths: empty. The three run-scripts still pending. No back-edge. |
| 3 | `read-the-merged-config-not-the-source` | pass, after one failed measurement | Merged table read straight out of the running plugin: `split_side = "right"`, `split_size = 30`, `toggle_key = "<C-j>"`, `split_width_percentage = 0.3`, `terminal_cmd = "cll"`. Observable result: `%0 left=0 139x50`, `%1 left=140 60x50` — a right split. They agree, and both disagree with nothing in the source, which sets no `split_side` at all. Fourth independent reproduction. **First attempt measured nothing** — see `### Edits`. No back-edge taken (the failure was in my instrumentation, not the step's premise). |
| 4 | `rerun-the-drift-check` | pass | Exit 0, `undocumented: 0`, run unpiped. Checked the allowlist per the third `## Fails when`: `nvim: []`, file unmodified. Read `unresolved: 3` rather than resting on the clean exit, per the second. All three `## Fails when` earned their place. No back-edge. |

### Edits

One replacement, for `read-the-merged-config-not-the-source`, whose
`## Fails when` is empty and whose step 3 asks for pane geometry without
warning that the probe destroys it. My first run listed one pane, `%1
left=0 200x50` — which reads as "no split happened" and is the exact wrong
conclusion. The probe body ends `vim.cmd("qa!")`, so the split is gone before
`list-panes` can run; polling every 0.2s never caught it either, because
teardown is faster than the tick. Dropping the quit produced the true
geometry on the first try.

Add to `read-the-merged-config-not-the-source`, under `## Fails when`:

> - The probe quits the program as its last act, and the window or pane
>   layout is torn down before it can be listed. A single full-size pane then
>   reads as "the split never happened", which is the opposite of the truth.
>   Polling does not save you — teardown beats the tick. Drop the quit from
>   the probe body and kill the whole server after measuring, or hold the
>   program open on a timer; read the merged table and the layout from the
>   *same* live process.

`take-the-answers-not-the-stale-report` also has an empty `## Fails when` and
I have nothing to add: its premise (a stale `Verdict:` reading as current)
did not arise, because the analyst had already replaced the file. An empty
section it is, honestly, until a run hits it.

## Findings

Reported, not acted on — none is in this node's footprint.

### F-A — a 199-file commit swallowed this node's footprint

New this run, and the reason box 5 is `[~]`. Full account above. Beyond this
node: a bulk "the tree as it stood" commit taken while workers hold claims
will silently absorb any worker's footprint and make every scoped-commit
acceptance box in flight unclosable. Worth a rule — quiesce the board before
a baseline commit, or take the baseline as a branch.

### F1 — a manual entry contradicts the answered fork (analyst's, re-confirmed)

`home/dot_config/nushell/help/nvim.nuon:476` still says Claude spawns "in a
split below the editor". Q2 settled the right-hand panel and I measured it
right for the fourth time this run. `help --check` cannot catch it: it
compares `lhs`/`mode`/`desc`, and this is prose in the `use` field — clean is
not correct here. Owner `08-claude-agent/04-help-entries`; one writer per
file, so untouched.

### F3 — the PRD's `## Constraints` is stale twice (analyst's, unchanged)

It says the plugin launches `claude` directly (the tree sets
`terminal_cmd = "cll"`, and I measured `TERMINAL-CMD cll` again), and names
`<leader>a*` maps that are `<leader>x*`. The orchestrator's to fix;
frontmatter and contract are not mine.

## Not mine in the tree

`git status --short` at hand-back, none of it my footprint:

```
 M .pearde/.gitignore
 M .pearde/prds/08-claude-agent/02-nvim-plugin/prd.md          <- orchestrator's claim line
 M .pearde/prds/08-claude-agent/02-nvim-plugin/report.md       <- this file
 M .pearde/prds/08-claude-agent/02-nvim-plugin/specs/spec01.md <- my box ticks
 D .pearde/prds/08-claude-agent/02-nvim-plugin/specs/spec02.md <- analyst's Q1 deletion
?? .pearde/prds/08-claude-agent/02-nvim-plugin/probe/fire-deployed.lua
?? .pearde/prds/08-claude-agent/02-nvim-plugin/probe/pass-two.md
?? .pearde/prds/09-simplify/                                   <- another worker
?? .pearde/workflows/land-an-answered-fork.md                  <- analyst
?? .pearde/workflows/read-the-merged-config-not-the-source.md  <- analyst
?? .pearde/workflows/take-the-answers-not-the-stale-report.md  <- analyst
```

`.pearde/prds/09-simplify/` is a second worker's and I left it alone. Nothing
under `home/` is modified: my footprint is clean, which is why there is no
commit from me.

## Knowledge

Nothing learned outside this repo — no web, no library this tree does not
hold. The forced-right merge is already on record as `[[260902-79f9]]` and
this is its fourth reproduction, not a new fact. No word in my contract was
missing from `grammar.py show`.
