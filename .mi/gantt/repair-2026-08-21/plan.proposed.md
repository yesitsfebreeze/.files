# The plan

Inventory taken at `de3825547380fbde62ff74dc0dd99278dbbefa41`. Board measured
again at drafting time: **519 open + 3 stubbed + 23 closed = 545 boxes across
77 nodes**. (The inventory's own aggregate line says "16 closed"; its per-file
table sums to 23, and 23 is what `grep -cE '^[ \t]*- \[x\]'` returns across
the tree today. The open and stubbed counts match the census exactly.)

**Ledger balances: 551 ids in, 551 ids placed, 0 lost.** Checked
mechanically, id by id, not by reading: zero duplicates, zero missing, zero
invented. The arithmetic is spelled out in [The migration map](#the-migration-map).

---

## What changes, in one paragraph

Today the board is 77 nodes in six epics plus a meta-epic, ordered by
directory number, with three nodes walled behind `## Escalation`, two of them
walled by the same defect: a requirement that can only be met by writing a
file the node's own downstream task owns. Nothing on the board can be closed
with proof, because no gate runner exists anywhere in the repository. After
this plan the board is 78 nodes ordered by what unblocks the most: a gate
runner, the schedule fold and the four human decisions go first because 519
boxes are downstream of them; the two ownership cycles are cut by re-homing
three requirements into the nodes that already own the files, under fresh
numbers, with pointers left behind; twenty-eight nodes whose only boundary was
a filename fold into the sibling that writes the same file, becoming
`out-of-scope` redirect stubs that keep their addresses; a new node,
`00-delivery/first-run`, owns the one thing that means we shipped — `just
install` on a machine that has never seen this config. No closed node is
touched, no node id is renamed or moved, no requirement number is reused, and
every one of the 522 live boxes lands somewhere nameable.

---

## The plan

Priority is the frontier order. Within a tier the footprints are disjoint for
every *source directory under `.mi/`*, so the tier is the width — **with one
stated exception, which is a wall this plan does not have the standing to
resolve.** Every implementation tier collides on
`home/dot_config/nushell/help/`, because the board root's **I3** requires each
node that adds a binding to write its own `help` entry in the same change
while [`06-help/01-content-model`](#47--06-help01-content-model--keep-frontmatter-and-one-amendment)
R1 — a **closed** box — fixes that surface at five shared files. At priority
80 alone that is six nodes writing five files. The contradiction, both
candidate resolutions and the reason neither is a restructure's call are
written into
[`06-help/02-help-command`](#28--06-help02-help-command--rewrite)'s body under
`## Stated wall: the help content surface has no single writer`, and it is
**unresolved**. Read "the tier is the width" as true of `.mi/` and false of
the help content surface until someone answers it as a decision node.
`max-workers` on the board root is 3, so a tier wider than 3 is slack, not a
promise.

| # | Node | What it is | Why here | What it unblocks |
|---|---|---|---|---|
| 1 | `00-delivery/verification-gates` p100 | The gate runner: one command, one script per surface, proven by induced failure | Nothing on this board can close with proof today — no `justfile`, no `Makefile`, no `package.json`, and `tests/` holds two ad-hoc scripts. Four `verify:` fields already name a "wave gate" that exists nowhere | Every acceptance box on the board that says "the gate passes"; `04-shell/07`'s and `01-capsule/03`'s verify strings |
| 2 | `00-delivery/work-breakdown` p100 | The schedule record, and its generated folds | `plan.json` holds 63 tasks; `plan.md`, `delivery-gantt.md` and the README build order disagree with it and with each other, and one real task (`H.1c`) is in none of them | Correct dispatch for everything; removes the widest shared-file collision on the board |
| 3 | `00-delivery/corrections/w0-3-platform-rewrite` p100 | Closes on R1 alone; R2 and R3 re-homed | 43 tasks are transitively downstream — the hardest edge in the graph — and it cannot close inside its own footprint | `w0-4-*` (all six), `repo-skeleton`, `06-help/04-drift-check` |
| 4 | `00-delivery/corrections/w0-6-live-bugs` p100 | The live-bug catalogue and routing table, and nothing else | Same ownership shape as W0.3; its blocking question (Decision 4) is answered | `w0-2`, `w0-5`, the three hitl decisions that were gated behind it |
| 5 | `00-delivery/decisions/{tinty,fzf,shift-select-scope,odin-toolchain}` p95 hitl | Four forks, four addresses, asked as one numbered round | Human wall-clock is the only thing parallelism cannot remove, and three of them were gated behind an afk deadlock | 9 implementation nodes between them |
| 6 | `00-delivery/decisions/wallpaper-opacity` p95 hitl | Narrowed to one question and left open | Two of its four halves are already excluded (README:143, README:165-166), which frees `Ctrl+Shift+B` on its own; the static `window_background_opacity` value and the base00 tint are not answered anywhere and stay the human's | `Ctrl+Shift+B` for `capsule --rebuild`, immediately; `02-terminal/01-appearance`'s opacity value when answered |
| 7 | `00-delivery/corrections/w0-2-terminal-respec` p95 | Re-spec all of `02-terminal` from the live inventory | Its input (`capabilities-terminal.md`) exists; W0.1 closed 2026-08-20. The edges making it wait on the correction sweep and the bug catalogue are invented | `02-terminal/*`, `coverage` R3 |
| 8 | `w0-4-s2-corrections/{editor,shell,platform,docs-inventories,help}` p95 | Five correction lanes, one directory each | Each owns exactly one directory, so five run concurrently instead of one agent serialising ~22 files | Their epics' implementation nodes |
| 9 | `w0-4-s2-corrections/delivery` p95 | Sole writer of `.mi/prd/README.md` | Receives W0.3's re-homed R2 as a fresh R7 — the task that already owns the file | The README exclusion list, the child counts |
| 10 | `00-delivery/corrections/w0-5-capsule-rebase` p95 | Sole writer of `.mi/prd/01-capsule/`; absorbs the second capsule correction node | Two nodes pointed at one directory would serialise no matter how many agents are free | `01-capsule/*` |
| 11 | `00-delivery/corrections/w0-4-s2-corrections` p90 | Cross-tree de-duplication and the wrap rule; runs alone | The one class of correction no single-directory child can do: deciding which copy of a duplicated fact survives needs a reader who can see all of them | The corrections roll-up |
| 12 | `00-delivery/corrections` p88 · `00-delivery/decisions` p88 | The two roll-up records | Ready only once their children are covered | `00-delivery` |
| 13 | `05-platform/01-deploy-mechanism/repo-skeleton` p85 | The chezmoi spine and the `justfile` | Nothing reaches a machine without it, and it is from-scratch work per Decision 4 | Every config surface, `just check`, `just install` |
| 14 | `01-capsule/02-dev-image` p85 | One Dockerfile | The earliest implementation node with no upstream at all | `01-capsule/01` |
| 15 | `02-terminal/01-appearance` p80 | Palette, font, platform detection | The terminal owns the palette three other epics inherit | `02-terminal/02`, `03-editor/11`, `04-shell/04` |
| 16 | `03-editor/01-options` p80 | Options, keymaps, autocmds, lazy — one load-order contract | `mapleader` must be set before any spec is evaluated; the four files are meaningless apart | every other editor node |
| 17 | `04-shell/01-core-config` p80 | env, config, aliases, launchers, the `mkcd` funnel | Every later shell node loads into the environment it defines | `04-shell/03`, `04-shell/04` |
| 18 | `05-platform/02-package-provisioning/packages-installer` p80 | `packages.yaml`, the installer, the Homebrew bootstrap | chezmoi's phase order puts it between the skeleton and the generators | `05-platform/03`, `01-capsule/02`, the Neovim floor |
| 19 | `01-capsule/01-container-lifecycle` p80 | The capsule CLI: lifecycle, credentials, recency | One executable, one file; credentials are flags the mount passes | the capsule bindings |
| 20 | `06-help/02-help-command` p80 | Every renderer over one content source | The rule "document it in the same change" is only enforceable once there is something to write into | `06-help/04`, `coverage` |
| 21 | `02-terminal/02-startup-layout` p70 | Window/tab model and tab-state colouring | One file, one contract: what creates a tab decides its colour | `02-terminal/03` |
| 22 | `03-editor/09-lsp` p70 | LSP, completion, formatting, treesitter | One wiring problem: blink exports the capabilities table LSP consumes | — |
| 23 | `04-shell/03-zoxide` p70 | The navigation funnel and the listing that follows it | Three faces of one invariant: one funnel, one PWD hook | `04-shell/04` |
| 24 | `05-platform/03-shell-init-generation` p70 | `run_after` generators and launchd PATH seeding | Only this node knows the installed set the seeding must derive from | GUI launches |
| 25 | `02-terminal/03-f5-jump-mode` p65 | Jump mode and copy mode | Both are one-shot key tables in the same region of the same file | — |
| 26 | `03-editor/08-telescope` p65 | Telescope, oil, gitsigns, which-key, autopairs, table mode | Six specs with no wiring between them sharing one directory | — |
| 27 | `04-shell/04-television` p65 | Channels, decoders, history, quicklist | The quicklist reuses the finder's decoder verbatim | `06-help/02` browser |
| 28 | `03-editor/11-colorscheme` p60 | Palette, cursor, statusline | Both derive from one `get_palette()` call and both rebuild on `ColorScheme` | — |
| 29 | `03-editor/14-shift-select` p55 | Shift-to-select and table mode's editing layer | The one SIMPLIFY gated on a human answer | `coverage` R2 |
| 30 | the six epic roll-ups p50 | `01-capsule` … `06-help` | Ready when their subtrees are covered | `00-delivery`, root |
| 31 | `00-delivery/first-run` p45 | The ship gate: `just install` on a machine that has never seen this config | This is what "delivered" means; everything before it is a subsystem | root |
| 32 | `06-help/04-drift-check` p40 | `help --check` | Needs all three live surfaces to exist | `coverage` |
| 33 | `06-help/01-content-model/coverage` p30 | Every surface documented, every target resolving | Provable only against a live surface and a running drift check | `06-help/01-content-model` |
| 34 | `06-help/01-content-model` p25 | The one remaining `[~]`: the two adversary passes | Its child must be covered before it is ready — see the cycle cut below | `06-help` |
| 35 | `00-delivery` p20 · `.` p10 | The meta-epic and the root | Statements about everything else | — |
| — | 28 ABSORB stubs p0 | Dissolved nodes, kept as addresses | `state: out-of-scope`, body is a pointer | — |

### One dependency cycle this plan cuts, found while ordering

`06-help/01-content-model` cannot become ready until its child `coverage` is
covered (worker.md §2); `coverage` declares `deps: 06-help/04-drift-check`;
`04-drift-check` declares `deps: 06-help/01-content-model`. That is a cycle,
and it deadlocks the last three nodes on the board. The coverage node's own
`## Note on deps` names the escape hatch: *"It would deadlock only if the
parent were reopened — if that happens, drop this edge."* The parent is
`state: open` with `R5` `[~]`, i.e. it is exactly the case that note warns
about. **The repair: delete `.mi/prd/06-help/01-content-model` from
`04-drift-check`'s `deps`.** The drift check needs the content *files*, which
exist on disk today (six under `home/dot_config/nushell/help/`), not the
node's closure. The chain then runs surfaces → drift-check → coverage →
content-model, which is the order priorities 40 / 30 / 25 encode.

---

## The board, node by node

Each block below is the **whole content** of the file at its path. Anything
the current file holds that a block does not show is deleted by the apply —
which is how a careful-looking instruction destroys the record. Two directives
exist so that nothing has to be shown to be kept:

- **`«PRESERVE: ## <heading text>»`** — copy that entire section, from its
  `##` line to the line before the next `##`, **byte for byte** out of the
  current file at `de38255`. Named by heading text, never by line range: a
  line range reads as careful and silently deletes whatever recorded decision
  sits below the cut.
- **`«PRESERVE-BOX: - [x] **Rn** — <first words…>»`** — copy that box **and
  its entire indented body**, byte for byte, out of the current file. **A
  closed `[x]` box shown as a one-line summary means exactly this: copy the
  full body.** A closed box's body here is often dozens of lines of close
  evidence — the check that would have proved the requirement, the
  counterfactual that was run — and a summary line is not a copy of it. This
  single rule covers most of what gets lost.

Six more rules, and they bind the applier:

1. **No requirement number is ever reused.** `git log --format=%s%n%b | grep
   -nE 'requirement [0-9]|\bR[0-9]+\b'` returns 28 citations in this
   repository's history today. A vacated number stays a **gap**: it is left in
   `## Requirements` as a plain non-box line reading `R2 — *re-homed …*`, so
   the number is spent and a scheduler cannot see it. New boxes take the next
   free integer. Re-run that grep after applying and check every citation
   still resolves to the same content.
2. **`## Out of scope` lines are enumerated, never re-derived.** They carry
   recorded user decisions; a dropped line is that decision silently reversed.
   Where a block writes fewer out-of-scope lines than the current file has,
   the difference is stated in the block's header.
3. **`[~]` stays `[~]`.** Downgrading a stub to `[ ]` loses the honest record
   that a stub is load-bearing. Exactly three `[~]` boxes exist:
   `w0-3-platform-rewrite` acceptance 2, `w0-6-live-bugs` R3,
   `06-help/01-content-model` R5. The first is re-homed as `[~]`, the second
   is re-homed as `[~]`, the third stays where it is as `[~]`.
4. **Every count is measured at the moment it is written.** The counts in this
   document were taken during drafting: 77 `prd.md` files, 63 tasks in
   `plan.json`, 519/3/23 boxes, 35 `burrito|brr` hits across 14 files under
   `.mi/prd`, 6 `rcwd` hits, 1 `DO NOT PORST` hit in `.mi/docs`, 7
   `editor.lua` hits, 6 `cdi` hits, 2 `owns the palette` hits. A number
   written from the old tree is wrong the moment the plan lands and reads as
   authoritative the whole time.
5. **Three `## Escalation` sections are folded in, not deleted.**
   `02-terminal/01-appearance`, `w0-6-live-bugs` and `w0-3-platform-rewrite`
   each carry one, and an `## Escalation` heading takes a node off the work
   surface (§2) and adds 1 to what it owes (§1). Each is re-headed as a
   `## Findings` subsection with **every byte of its text intact**. Law 1:
   corrections are appended and shadow the old value; deletion is not
   expressible.
6. **No node's `verify:` names a command that cannot run, and no node's gate
   is a board-wide sweep.** Re-profiled 2026-08-21 against the working tree,
   because the profile this plan was first drafted against was wrong. The six
   names it offered — `mi-gantt`, `mi-rating`, `mi-reconcile`, `mi-repair`,
   `mi-replan`, `mi-run` — are harness **workflow modules**, not programs:
   they carry `export const meta = {…}`, a top-level `return` and a free
   `args` binding, and the dispatcher loads them. Run directly, every one of
   the six exits **1**:

   ```
   $ node .mi/workflows/mi-reconcile.js
   if (!profile) return { error: 'profile failed — …' }
                 ^^^^^^
   SyntaxError: Illegal return statement
   $ echo $?   → 1        (identical for the other five)
   ```

   Under §6 — *"if the node has `verify:`, **you ran it**; its output is the
   evidence"* — a `verify:` that exits 1 makes its node permanently
   uncloseable. So **no block in this document names one.** Nor would one
   prove anything if it ran: `verify:` is specified as proving *this node's
   own* requirements, and one identical drift sweep on forty-five nodes is
   node-independent by construction.

   What the blocks carry instead:

   - Two `verify:` strings name scripts that exist and exit 0 today, measured:
     `"bash tests/live-bugs.sh exits 0"` on `w0-6-live-bugs` and
     `"nu tests/help-content-model.nu exits 0"` on `06-help/01-content-model`.
   - Two are **carried forward from the board rather than regressed away**, a
     defect an earlier draft of this plan introduced:
     `03-editor/01-options` takes
     `03-editor/04-plugin-manager`'s `"nvim --headless '+Lazy! sync' +qa exits
     0"` along with its absorbed content, and `repo-skeleton` keeps its own
     `"chezmoi apply on a scratch target is idempotent…"` string verbatim.
     `06-help/04-drift-check` keeps `"help --check exits 0"`, which is
     pre-existing.
   - Every other node gets **`verify: ""`** — the format's own word for
     unproven, which is honest and closeable by inspection — **plus the
     `**Gate.**` paragraph below, written into the node's body** so that no
     reader has to infer why the field is empty.

   **The `**Gate.**` paragraph is part of every block whose `verify:` is
   `""`.** The applier writes it as its own paragraph immediately after that
   node's Purpose, filling `<gate>` from this table and `<rel>` with the
   relative path from that node to
   `.mi/prd/00-delivery/verification-gates/prd.md`:

   | Node | `<gate>` |
   |---|---|
   | anything under `02-terminal/` | `bash tests/gates/terminal.sh` |
   | anything under `03-editor/` | `bash tests/gates/editor.sh` |
   | anything under `04-shell/` | `bash tests/gates/shell.sh` |
   | anything under `05-platform/` or `01-capsule/` | `bash tests/gates/deploy.sh` |
   | anything under `06-help/` | `bash tests/gates/help.sh` |
   | anything under `00-delivery/`, and the board root | `bash tests/gates.sh` |

   > **Gate.** This node has **no runnable gate today**. `verify:` is `""`
   > rather than a command that would exit non-zero for the wrong reason, and
   > the node's proof until then is its `## Acceptance` boxes, run by hand and
   > recorded. When [`verification-gates`](<rel>) lands `<gate>`, this node's
   > `verify:` becomes `<gate>` **in the same commit that first closes a box
   > against it** — and not one commit earlier, because a gate that does not
   > exist yet cannot have been run.

   `00-delivery/verification-gates` itself takes `verify: ""` and the same
   paragraph with `<gate>` = `bash tests/gates.sh`: it is the node that builds
   the runner, and naming its own unwritten output as its gate is the circle
   this rule exists to break. The 28 stubs take `verify: ""` and **no**
   `**Gate.**` paragraph — an `out-of-scope` stub holds no work and has
   nothing to prove.

### The check that ships with this plan

Per file, never aggregate, and counting all three box states.

```
# before applying, on de38255, and again after
for f in $(find .mi/prd -name prd.md | sort); do
  printf '%s\tx=%s\topen=%s\tstub=%s\n' "$f" \
    "$(grep -cE '^[ \t]*- \[x\]' "$f")" \
    "$(grep -cE '^[ \t]*- \[ \]' "$f")" \
    "$(grep -cE '^[ \t]*- \[~\]' "$f")"
done > /tmp/boxes.before   # …after
diff /tmp/boxes.before /tmp/boxes.after
```

An aggregate `- [x]` count rises the moment a bookkeeping box is added and
hides closed boxes destroyed elsewhere — a green check over the exact defect
it was written to catch. A check counting only `[x]` is the same failure one
state over: it absorbs every deleted `[ ]` and `[~]`, which is where the live
work is.

**One strengthening, stated because it is a deviation.** The literal rule "no
file's count falls in any of the three" is unsatisfiable for any plan that
merges — a merge moves boxes out of a file by construction. So the rule here
is: *no **unexplained** fall.* Every per-file fall must be matched, id for id,
by rows in [The migration map](#the-migration-map) that move exactly those ids
out of that file into a named destination, and the destination file's count
must rise correspondingly — or by a `retired` row carrying quoted evidence.
For a file with no migration rows, zero falls are allowed, which is the
original rule. This is strictly stronger than the literal form for the
un-merged case and is the only form that catches a box vanishing from a merged
file.

**Closed-box manifest, enumerated by text so the applier checks boxes and not
numbers.** Only four files carry `[x]` boxes today, and a count is not an
enumeration: two closed boxes deleted and two bookkeeping boxes added leaves
the count intact and the record gone. Every one of the 23 survives, byte for
byte, with its full body. Grep the opening text of each after the apply.

| File | Closed boxes that must still be present, by their opening text |
|---|---|
| `00-delivery/corrections/w0-1-terminal-inventory` (7, file untouched) | `**R1** — Read \`~/.config/wezterm/\` and rate every capability` · `**R2** — Cover the machinery the current PRDs miss entirely (T-10, ~230` · `**R3** — Record the real font and palette.` · `**R4** — Sort entries best value-ratio first` · `\`.mi/docs/capabilities-terminal.md\` exists and every entry carries both` · `Every item in T-10's list appears as a rated entry.` · `No entry describes a capability that is not present in` |
| `00-delivery/corrections/w0-3-platform-rewrite` (1) | `**R1** — \`.mi/SYSTEM.md\`'s epic table still reads \`05-platform \| macOS` — **including its "Met by the tree as it stands" evidence body and its "Correction, recorded because the premise is false" paragraph** |
| `00-delivery/corrections/w0-6-live-bugs` (2) | `**R1** — The \`L-1\`..\`L-12\` table exists in the backlog and is populated.` (with its "Caveat on the check" paragraph) · `**R5** — The six bugs that no board node names — L-2, L-5, L-7, L-9,` |
| `06-help/01-content-model` (13) | `**R1** — **Format.**` · `**R2** — **Entry schema.**` and its seven nested `[x]` sub-boxes (`key` or `cmd`, `title`, `use`, `topic`, `mode`, `also`, `why`) · the nested `[x]` `\`verify\` — present and well-typed` · `**R3** — **Topics.**` · `**R4** — **Concept entries.**` · the acceptance box `Opening a content file directly is readable as plain text` |

After the apply those four counts must read 7 / 1 / 2 / 13 unchanged **and**
each row above must still grep. Any other value, or any missing line, is a
destroyed record. No fifth file acquires an `[x]`: this plan closes no box it
did not find closed.

---

### 1 · `00-delivery/verification-gates` — REWRITE

Path survives, body replaced. Current file has 0 `[x]`, 13 `[ ]`, 0 `[~]`;
after: 0 / 21 / 1 — the stub is
`w0-3-platform-rewrite`'s link-check box, carried forward in its own state
per rule 3. Two ids leave (`verification-gates-r7` and `-b6` →
`00-delivery/first-run`) and the R2 sub-boxes fold into R3. Its current `## Out of scope` is the boilerplate
line "Anything this node's Requirements do not name…", replaced by three
specific lines. Its `deps` edge to `repo-skeleton` is cut: a gate runner that
waits on the deploy layout is a gate that arrives after the work it judges.

```markdown
--- .mi/prd/00-delivery/verification-gates/prd.md ---
---
state: open
mode: afk
deps: []
priority: 100
verify: ""
---

# Verification gates

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Nothing on this board can be closed with proof today. There is no
`justfile`, `Makefile`, `package.json` or CI config anywhere in the
repository, `tests/` holds two ad-hoc scripts, and four `verify:` fields
already name a "wave gate" runner that exists nowhere — which makes every
acceptance box phrased "the wave gate passes" uncloseable by construction,
including this node's own. That is not a missing convenience; it is the board
asserting a closing condition it has no machinery to evaluate. This node
builds the runner first, before any configuration is written, so every later
node has a real check to point at. It is the single largest chain-cut
available: 519 open boxes are downstream of it.

## Requirements
- [ ] **R1** — **One command runs every gate.** `tests/gates.sh` with no
      arguments runs the whole set and exits non-zero if any member fails.
      Nothing outside it counts as a rule.
- [ ] **R2** — **A gate that finds nothing to check FAILS.** Each gate script
      asserts a non-zero count of the things it inspects before judging them,
      so an empty or missing surface is a failure and not a silent pass.
- [ ] **R3** — **Per-surface headless probes**, one script each, each exiting
      non-zero on failure. `tests/gates/shell.sh` drives `nu -l -c '<expr>'`
      for commands and pipelines and reads `$env.config.keybindings` for
      bindings — the `-l` is load-bearing and is not a style choice, see R7.
      `tests/gates/editor.sh` drives `nvim --headless -c '<lua>' -c 'qa'`,
      `nvim_get_keymap` per mode, `:checkhealth`, and `:Lazy! sync` exit
      status. `tests/gates/terminal.sh` drives `wezterm show-keys --lua` and
      `wezterm --config-file <f> ls-fonts` and diffs against the intended set.
- [ ] **R4** — **Selection by wave, not by hand.** `tests/gates.sh --wave <n>`
      runs wave n's gates and every earlier wave's gates; a regression sweep is
      the default, not an option. The wave→gate mapping is data in one file,
      not branching in the script.
- [ ] **R5** — **Fail open.** An input the runner cannot map to a gate runs
      the whole set rather than being skipped.
- [ ] **R6** — **Every gate is proven by breaking it.** For each gate script,
      one recorded line names the violation introduced and the failure
      observed. A gate with no recorded induced failure is not a gate.
- [ ] **R7** — **Gate scripts launch a configured shell.** A bare `nu -c`
      loads no user config. Measured 2026-08-21: `nu -c '$env.config.keybindings
      | length'` returns 0 while `nu -l -c` returns 13 — so the naive probe
      reports every documented binding stale, every live binding absent, and
      still exits 0. Every shell probe names its invocation explicitly.
- [ ] **R8** — **Interactive-only checks are enumerated, not implied.**
      `tests/gates/manual.md` lists, per wave, every criterion that genuinely
      needs a human at a terminal — the F5 jump landing on the right pane, the
      shift-select collapse under real keyboard timing — and `tests/gates.sh`
      prints that list and its count at the end of each wave rather than
      silently assuming someone looked.
- [ ] **R9** — **Definition of done is executable.** A task is done when its
      node's acceptance criteria have been RUN by this runner and its `help`
      entries exist, not when they have been read.
- [ ] **R10** — **A tree-link gate.** `tests/gates/links.sh` walks every
      markdown link under `.mi/prd` and `.mi/SYSTEM.md` and fails on any
      unresolvable target. It is multi-line aware: this repo wraps at ~78
      columns, which manufactures links split across lines, and a naive
      per-line walker silently passes one — the demonstrated defect that left
      `w0-3-platform-rewrite`'s link box at `[~]` rather than `[x]`. The
      walker's scope is decided here and stated: the board plus `SYSTEM.md`,
      not `.mi/` as a whole, because `.mi/workflows/refs/` carries 11 broken
      links back at the framework's own source repo and is owned by no lane.
- [ ] **R11** — **The replacement for a wave-numbered gate is decided here,
      and applied by whoever owns the file.** An acceptance or `verify:` that
      said "the wave-N gate passes" names a gate script path instead, so the
      check is reachable from the node that must run it. Exactly two carry the
      old phrasing today, both in `verify:` strings:
      `.mi/prd/04-shell/07-quicklist/prd.md` and
      `.mi/prd/01-capsule/03-credential-propagation/prd.md`. **This node
      writes neither.** `.mi/prd/04-shell/` belongs to
      [`w0-4-s2-corrections/shell`](../corrections/w0-4-s2-corrections/shell/prd.md)
      R9 and `.mi/prd/01-capsule/` to
      [`w0-5-capsule-rebase`](../corrections/w0-5-capsule-rebase/prd.md) R6;
      they make the edit and their acceptance proves it. Requiring it here
      would rebuild, at the very top of the frontier, the exact
      write-a-file-your-own-downstream-task-owns deadlock that walled W0.3 and
      W0.6 — and it is the deadlock this whole restructure exists to cut.
      Writing the corresponding edges into `plan.json` belongs to
      [`work-breakdown`](../work-breakdown/prd.md) R6, which owns
      `.mi/gantt/`; this node writes nothing under `.mi/gantt/`.
- [ ] **R12** — **A duplication gate.** A check asserts each cross-tree fact
      appears in exactly one file: `cdi` (6 hits today), the
      `use_kitty_protocol` escape-leak reason (8 hits across `.mi/prd` and
      `.mi/docs`), and "the terminal owns the palette" (2 hits). Law 1's
      reviewed rung is otherwise unenforceable and drifts silently at exactly
      the clause that mattered.
- [ ] **R13** — **Register what already exists, and edit neither.**
      `tests/help-content-model.nu` and `tests/live-bugs.sh` are added to the
      runner's manifest and run under it with their behaviour unchanged. This
      is registration, not authorship: this node writes only
      `tests/gates.sh` and `tests/gates/`, and `tests/live-bugs.sh` stays
      [`w0-6-live-bugs`](../corrections/w0-6-live-bugs/prd.md)'s file and its
      `verify:` string. Registering is part of this node; changing a
      registered script's behaviour is that script's owner's.

## Acceptance
- [ ] `bash tests/gates.sh` runs from a clean checkout and exits 0, printing a
      per-surface count for every gate it ran.
- [ ] Each gate script has one recorded induced-failure line naming what was
      broken and the non-zero exit that followed.
- [ ] Emptying any single surface config makes `tests/gates.sh` exit non-zero
      rather than pass with zero checks.
- [ ] A shell probe written as `nu -c` instead of `nu -l -c` fails the
      runner's own self-check.
- [ ] `bash tests/gates.sh --wave 5` also runs the wave 1–4 gates, proven by
      their printed counts appearing in the output.
- [ ] Breaking one markdown link under `.mi/prd/` exits non-zero, and the same
      link wrapped across two lines is still caught.
- [ ] The replacement form for a wave-numbered gate is stated in R11, and the
      two nodes carrying the old phrasing are named there with the lane that
      owns each. Whether those two strings have actually been replaced is
      `w0-4-s2-corrections/shell` R9's and `w0-5-capsule-rebase` R6's
      acceptance, not this node's — this node owns no file under
      `.mi/prd/04-shell/` or `.mi/prd/01-capsule/`.
- [ ] Both existing `tests/` scripts run under the runner.
- [~] The Wave 0 tree link check passes. *Carried forward from
      [`w0-3-platform-rewrite`](../corrections/w0-3-platform-rewrite/prd.md)'s
      second acceptance box, in the state it was in.* **STUB: the underlying
      fact is true — an uncommitted multi-line-aware walker reports 244 links
      across 78 files, 0 broken over `.mi/prd`, and 18 links, 0 broken for
      `.mi/SYSTEM.md` — but no committed gate exists, and the walker is not
      it.** It becomes `[x]` when R10 lands and the committed script is what
      reports it. Downgrading it to `[ ]` would lose the record that a
      load-bearing stub is standing in for the gate this node builds.

## Out of scope
- Any judgement of whether a configuration is GOOD. This node proves that
  stated behaviour is present, not that it is well chosen.
- The fresh-machine run itself — [`00-delivery/first-run`](../first-run/prd.md)
  owns it, because the runner is built first and that is proved last.
- CI, hooks, or scheduling. The runner is invoked by hand and by node
  `verify:` fields; nothing installs it into git.
- The `justfile`. [`repo-skeleton`](../../05-platform/01-deploy-mechanism/repo-skeleton/prd.md)
  owns it and exposes `just check` as a call into `tests/gates.sh`.
```

### 2 · `00-delivery/work-breakdown` — REWRITE

Path survives, body replaced. Current: 0 `[x]`, 4 `[ ]`, 0 `[~]`; after:
0 / 11 / 0. The current file's requirements section does not exist — it holds
four acceptance boxes and ~150 lines of hand-authored task tables. Those
tables are the thing this node stops authoring: they become a fold of
`plan.json`. **Nothing from them is lost** — `plan.json` already holds all 63
tasks with sizes, files and deps, and the three defects the tables carry
(`delivery-r1`/`-r2`/`-r3`) become R7, R8 and R9 here.

```markdown
--- .mi/prd/00-delivery/work-breakdown/prd.md ---
---
state: open
mode: afk
deps: []
priority: 100
verify: ""
---

# Work breakdown

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Three files declare themselves folds of
[`.mi/gantt/plan.json`](../../../gantt/plan.json) and
[`.mi/gantt/ledger.jsonl`](../../../gantt/ledger.jsonl) and disagree with
them — 63 tasks in the record against what the views print, zero done against
one done, and one real task (`H.1c`, `06-help/01-content-model/coverage`)
absent from every human view of the schedule while sitting in the plan, on the
board and in the ready set. This node takes sole ownership of the plan record
and makes every view of it generated, so that no other node ever writes a
schedule fact again.

## Requirements
- [ ] **R1** — **`plan.json` is the only home for task identity, size, deps
      and footprint.** Its task-id set equals the node set produced by `find
      .mi/prd -name prd.md`; a node with no task and a task with no node are
      both failures. Measured at drafting: 77 nodes, 63 tasks.
- [ ] **R2** — **`.mi/docs/delivery-gantt.md` and `.mi/gantt/plan.md` are
      regenerated** from `plan.json` plus the ledger on every run and carry no
      hand-authored per-item state. Refolding from empty and comparing byte
      for byte produces no difference. `.mi/prd/README.md` is generated by the
      same generator but is written by
      [`w0-4-s2-corrections/delivery`](../corrections/w0-4-s2-corrections/delivery/prd.md),
      which owns that file — one writer per file, including this one.
- [ ] **R3** — **Membership is by existence.** Epic child counts, the tree
      shape and the build order are computed from directory existence and the
      dep graph, never from a maintained list.
- [ ] **R4** — **Every task appears in exactly one wave, and no wave contains
      two tasks whose footprints share a source directory.** The generator
      refuses to emit a colliding wave rather than emitting it with a warning.
      This is the one checkable statement of "one writer per file"; the root
      node and `00-delivery` point at it and do not restate it.
- [ ] **R5** — **Each wave states its agent count** and it is at or under the
      board root's `max-workers`, which is 3.
- [ ] **R6** — **Every dependency edge a task declares exists as a task id in
      the same file.** Edges asserted only in a node's `verify:` prose — the
      two nodes whose `verify:` names a gate by wave number rather than by
      path, `04-shell/07-quicklist` and
      `01-capsule/03-credential-propagation` — are written
      as real edges to
      [`verification-gates`](../verification-gates/prd.md), and the
      `06-help/01-content-model` edge is deleted from `04-drift-check`'s deps
      because it closes a cycle (see that node).
- [ ] **R7** — **The critical path is computed, never quoted.** The stated
      figure equals the sum along the computed longest chain. The current text
      states "≈ 26 agent-hours" while its own sizes sum to 33, which violates
      this file's own acceptance criterion that the path is recomputed
      whenever dependencies change.
- [ ] **R8** — **The generated views name no removed task and no removed
      layout.** `T.5 burrito integration` went with burrito on 2026-08-20, and
      `conf/` is a legacy-only directory that C.4 no longer targets (M-18).
- [ ] **R9** — **One header per track.** The duplicated Track T header row
      with prose wedged between the two copies is a rendering artifact of hand
      authoring and cannot survive generation.
- [ ] **R10** — **Ordering lives in the dep graph, not in directory
      prefixes.** The generated build order carries a note that `00`–`06` is a
      value-ratio ordering and NOT an execution order, because the real graph
      inverts it in at least two places: `06-help/01-content-model` is a
      declared dependency of 32 tasks in epics 01–04, and
      `02-terminal/01-appearance` sits behind the whole Wave-0 backlog.
- [ ] **R11** — **Every task the plan holds appears in every generated view.**
      `H.1c` is the standing test case.
- [ ] **R12** — **Priority carries information.** All 77 nodes sit at the
      default priority today, so directory numbering is the only ordering
      signal a reader has and it actively misleads. Every task's node carries
      an explicit `priority:` and the generator refuses a tie it cannot break
      from the dep graph.
- [ ] **R13** — **No requirement anywhere else instructs a node to update
      `delivery-gantt.md` or `plan.md`.** Their absence is the proof that the
      fold is the only writer.

## Acceptance
- [ ] Regenerating both views twice in a row produces identical output, and
      diffing the second run against the committed files shows no change.
- [ ] `grep -rn 'delivery-gantt.md\|plan.md' .mi/prd --include=prd.md` returns
      no requirement or acceptance box asking any node to edit them.
- [ ] The generated wave list contains every id in `plan.json` including
      `H.1c`, and the task count printed reconciles against `find .mi/prd
      -name prd.md | wc -l` minus the nodes `plan.json` declares out of scope.
- [ ] Introducing a wave that puts two same-footprint tasks side by side makes
      the generator exit non-zero.
- [ ] The stated critical path and the sum of its task sizes agree.
- [ ] `grep -c 'T\.5' .mi/gantt/plan.md` returns 0.

## Out of scope
- Deciding what the tasks ARE. That is the board; this node records and
  orders, it does not scope.
- `.mi/prd/README.md`. Owned by
  [`w0-4-s2-corrections/delivery`](../corrections/w0-4-s2-corrections/delivery/prd.md),
  which runs this generator against it.
- The dispatcher in `.mi/workflows/`, which is mid-migration with uncommitted
  changes. If the runner and the plan disagree, the plan record is the
  authority and the runner is the defect; establishing which is at fault is
  this node's, repairing the runner is not.
- Hand-editing any generated view, including "just correcting the row". Both
  files say GENERATED at line 1 and mean it.
- Calendar dates. Estimates are agent-hours and wave positions.
- Managing the human's time. This plans the work, not the person.
```

### 3 · `00-delivery/corrections/w0-3-platform-rewrite` — CLOSE-AS-MET on R1

Path survives. Current: 1 `[x]`, 3 `[ ]`, 1 `[~]`; after: 1 / 4 / 0, with the
three departures named in the map (`-r2` → `delivery`, `-r3` →
`docs-inventories`, `-b2` → `verification-gates`) and `-b1` retired.

**The `-b1` retirement, with its evidence, because an earlier draft asserted
it and showed none.** `-b1` is the acceptance box *"The `SYSTEM.md` epic
table, the README exclusion list and the inventory sort are all correct."* Two
of its three conjuncts are **still false at `de38255`**, re-derived rather than
trusted: the value ratios in `.mi/docs/capabilities-provisioning.md` run 6, 7,
6, 1, 4, 6, 6, 6, 5, −2, −1, 0 in file order and rise at position 2, so the
sort is not best-first; and `.mi/prd/README.md`'s `## Excluded` section carries
no entry for `wp-stat-overlay installer (DEFER)` or `Published docs site
(DEFER)`. It is therefore retired **only because both false conjuncts land as
checkable acceptance boxes in the nodes that own those files**, and it is
retired against those two boxes by name:

- the README half → [`w0-4-s2-corrections/delivery`](#11--00-deliverycorrectionsw0-4-s2-correctionsdelivery--rewrite)
  R7, whose acceptance box reads *"All three provisioning verdicts appear in
  the exclusion list with their reasons."*
- the sort half → [`w0-4-s2-corrections/docs-inventories`](#9--00-deliverycorrectionsw0-4-s2-correctionsdocs-inventories--rewrite)
  R6, whose acceptance box reads *"Recomputing the value ratios in file order
  for all four inventories yields a non-increasing sequence in each, printed
  as evidence."*

The `SYSTEM.md` conjunct is R1, which is `[x]` and stays. Had either
replacement box been absent, `-b1` would have stayed open here: a conjunct
with no home is a fact deleted, not a fact moved. That is the whole of the
evidence for this retirement, and it is stated because "retired with evidence"
without the evidence is the claim vouching for itself. **R1's closed box and its entire evidence body are preserved byte
for byte**, including its "Correction, recorded because the premise is false"
paragraph. The `## Escalation` section is folded in: its text moves whole,
unedited, under `## Findings` as `### The escalation of 2026-08-21, and its
resolution`, which is what clears the node for work.

Evidence that R1 is met, quoted from its own box: *"`grep -n "05-platform"
.mi/SYSTEM.md` returns exactly one hit, line 66 … `grep -c "macOS dependency
bootstrap" .mi/SYSTEM.md` returns 0 … `find .mi/prd/05-platform -name prd.md`
returns 8 … which is `3 (+4)` exactly."* Adversary-confirmed at HEAD
`646a531`.

```markdown
--- .mi/prd/00-delivery/corrections/w0-3-platform-rewrite/prd.md ---
---
state: open
mode: afk
deps: []
priority: 100
verify: ""
---

# Finish the 05-platform provisioning rewrite

Purpose: The epic and its three children were rewritten, but the rewrite left
residues that the repo's own conventions require. This is the hardest edge in
the graph — 43 tasks are transitively downstream — and it could not close
inside its own footprint: R2 needed `.mi/prd/README.md` and R3 needed
`.mi/docs/capabilities-provisioning.md`, both on this node's no-write list and
both owned by tasks that declare a dependency on this one. Every lane
dispatched here re-walled forever. Resolved 2026-08-21 by option (A) of the
escalation below: the two requirements move down into the nodes that already
own those files, under fresh numbers; this node closes on R1, which is met.
The dependency direction is unchanged and no footprint is widened.

## Requirements
«PRESERVE-BOX: - [x] **R1** — `.mi/SYSTEM.md`'s epic table still reads … »
      (copy the box and its full multi-paragraph evidence body byte for byte
      from the current file, including the "Correction, recorded because the
      premise is false" paragraph)

R2 — *re-homed 2026-08-21.* The README exclusion list carrying no provisioning
entries, though `capabilities-provisioning.md` holds three verdicts, is now
[`w0-4-s2-corrections/delivery`](../w0-4-s2-corrections/delivery/prd.md)
**R7**, which owns `.mi/prd/README.md`. The met half — 05-platform's own
`## Out of scope` already carrying the Windows-mirroring and DEFER text —
stands as the record and is not re-derived. Number retained as a gap; do not
reuse.

R3 — *re-homed 2026-08-21.* The `capabilities-provisioning.md` sort-order
violation (ratios 6,7,6,1,4,6,6,6,5,−2,−1,0 in file order, rising at position
2) is now
[`w0-4-s2-corrections/docs-inventories`](../w0-4-s2-corrections/docs-inventories/prd.md)
**R6**, which owns `.mi/docs/`. The corrected order and its tie-break are
recorded in `## Findings` so the receiving node does not re-derive them.
Number retained as a gap; do not reuse.

- [ ] **R4** — The re-homing is legible from both ends: each moved requirement
      names its new node and number here, and each receiving node names where
      its text came from, so the escalation is readable without this file.

## Acceptance
- [ ] R1 stands `[x]` with its original evidence, and this node's
      `## Escalation` heading is gone — folded into `## Findings`, text
      intact — because the wall it names is resolved by re-homing rather than
      by widening the footprint.
- [ ] R2 and R3 each point at a requirement number that exists in the
      receiving node, and neither number is reused here.
- [ ] This node's declared `files` list is unchanged: the four
      `.mi/prd/05-platform/**/prd.md` files, and nothing else.

## Out of scope
- Re-deriving the epic and its children. That work landed; only the residues
  were open.
- Writing `.mi/prd/README.md` or anything under `.mi/docs/` — the reason this
  node was walled. It does not acquire them.
- Flipping the `w0-4a`/`w0-4g` dependency edges. The direction stays as it is;
  the requirements move, not the graph.
- Re-using requirement numbers R2 and R3 for anything else, ever.

## Findings
«PRESERVE: ## Findings»
      (the existing section, unchanged — the link-walker refutation, the empty
      `## Acceptance` heading on `05-platform/prd.md`, and the scope of the
      Wave 0 link check)

### The escalation of 2026-08-21, and its resolution
«PRESERVE: ## Escalation»
      (the entire existing `## Escalation` section moved here verbatim,
      heading demoted to `###`, including "What was hit", "What change is
      needed", options (A) and (B), "No split proposed", and
      "### Replacement text, so the downstream node does not re-derive it")

Resolved 2026-08-21: option (A). R2's open half is
`w0-4-s2-corrections/delivery` R7; R3 is
`w0-4-s2-corrections/docs-inventories` R6.

## Notes
«PRESERVE: ## Notes»
```

### 4 · `00-delivery/corrections/w0-6-live-bugs` — REWRITE

Path survives. Current: 2 `[x]`, 4 `[ ]`, 1 `[~]`; after: 2 / 4 / 0. Both
closed boxes preserved with their full bodies. `R2` retired (evidence below),
`R3` re-homed to `w0-4-s2-corrections/editor` R6 **carrying its `[~]`
state** — the receiving box opens `[~]`, not `[ ]`, because the decision
exists and only the transcription is missing. The `## Escalation` folds into
`## Findings` verbatim, which is what clears the node.
`## Assumptions`, `## Decisions` and `## Findings` are preserved whole with
**exactly one edit, stated here so an applier has one reading**: see "The one
edit to the routing table" below. They are the expensive part of this node and
nothing else in them moves.

**The one edit to the routing table, and why "preserve it byte for byte" was
not expressible.** `## Findings`' routing table names an owner node per bug.
Eight of its thirteen rows name a node this plan folds into a zero-requirement
`out-of-scope` stub — L-1 (`04-shell/06-listing`), L-4
(`04-shell/07-quicklist`), L-6 and L-9 (`03-editor/02-keymaps`), L-7
(`03-editor/06-explorer`), L-8 (`03-editor/03-autocmds`,
`03-editor/10-treesitter`), L-10 (`03-editor/12-small-plugins`), L-12
(`05-platform/01-deploy-mechanism/managed-config`). An earlier draft ordered
the table preserved byte for byte **and** required every row to resolve to a
requirement number in an existing node. After the stubs land, those two cannot
both hold. Resolved in favour of the record, both halves kept:

- **Corrections are appended and shadow; deletion is not expressible** (law
  1). Each of the eight owner cells is rewritten to name the **fold
  destination**, with the original owner kept in the same cell as
  `(was: <original node>)`. `04-shell/06-listing` → `04-shell/03-zoxide`
  (was: `04-shell/06-listing`); `04-shell/07-quicklist` →
  `04-shell/04-television`; `03-editor/02-keymaps` and `03-editor/03-autocmds`
  → `03-editor/01-options`; `03-editor/06-explorer` and
  `03-editor/12-small-plugins` → `03-editor/08-telescope`;
  `03-editor/10-treesitter` → `03-editor/09-lsp`;
  `05-platform/01-deploy-mechanism/managed-config` →
  `05-platform/01-deploy-mechanism/repo-skeleton`.
- **Nothing else in the table changes** — not the `#` column, not the Status
  column, not the four requirement lines below it, not the two audit-finding
  subsections, not "Why R3 is `[~]` and not `[x]`".
- **The edit lands in this node's own 2b commit**, which precedes step 2g's
  stub commit, so the table already points at the destinations by the time the
  stubs exist. At no commit does a row point at a node that holds no
  requirements.

`w0-6-live-bugs-r2` is **RETIRED**, with evidence: it is a second tracker over
boxes that already exist in the nodes that own those files. L-3 and L-4 are
already `w0-4-s2-corrections/shell` R1 and R2; L-6, L-8 and L-10 are already
`w0-4-s2-corrections/editor` R3, R1 and R2. This node may not write
`.mi/prd/03-editor/` or `.mi/prd/04-shell/`, so it can only ever restate what
those nodes record — laws.md law 1, reviewed rung: *"a document does not
restate another; an ungated copy goes lossy at exactly the clause that
mattered."* The half it genuinely owns is R4, naming the owner, which stays.

```markdown
--- .mi/prd/00-delivery/corrections/w0-6-live-bugs/prd.md ---
---
state: open
mode: afk
deps: []
priority: 100
verify: "bash tests/live-bugs.sh exits 0"
---

# Record the live-config bugs so the rebuild fixes them

Purpose: Thirteen bugs found in the live configuration that the rebuild must
not reproduce. This node is the catalogue and the routing table — the single
home for which node owns each fix — and nothing else. It was previously also a
second tracking mechanism for whether those fixes had landed, which put it in
the same deadlock as W0.3: it could not close without edits to files it may
not write. It closes on what it owns; the fixes are boxes in the nodes that
own the files. Its blocking question, decision 4, was answered by the user on
2026-08-21 and is recorded in the parent backlog.

## Requirements
«PRESERVE-BOX: - [x] **R1** — The `L-1`..`L-12` table exists in the backlog … »
      (copy the box and its full body byte for byte, including the "Caveat on
      the check" paragraph)

R2 — *retired 2026-08-21.* "Each bug is either fixed in the PRD that owns it,
or recorded as accepted-with-reason" is a second tracker over boxes that
already exist in the nodes that own those files: L-3 and L-4 are
`w0-4-s2-corrections/shell` R1/R2, L-6/L-8/L-10 are
`w0-4-s2-corrections/editor` R3/R1/R2. This node may not write those files.
The half it owns is R4. Number retained as a gap; do not reuse.

R3 — *re-homed 2026-08-21.* L-6 and L-9 being questions rather than records is
now [`w0-4-s2-corrections/editor`](../w0-4-s2-corrections/editor/prd.md)
**R6**, which owns `.mi/prd/03-editor/`. It opens there as `[~]`, not `[ ]`:
the decisions are real and verified against a live nvim 0.12.4 (see
`## Decisions`), and only the transcription into the owning PRDs is missing.
Number retained as a gap; do not reuse.

- [ ] **R4** — Every `L-*` row names the node that owns its fix **and the
      requirement number in that node that carries it**. A row naming an owner
      but no number is what let L-2, L-7, L-9 and L-12 sit unplaced; an owner
      without a number is not routing. A row whose owner column reads PLACE is
      an unplaced bug and counts as open.
«PRESERVE-BOX: - [x] **R5** — The six bugs that no board node names … »
      (copy the box and its full body byte for byte)

## Acceptance
- [ ] No `L-*` row is left as an open question, and no row's owner column
      reads PLACE.
- [ ] Every `L-*` row names a node that exists on the board **and holds
      requirements** and a requirement number that exists in that node,
      checked by resolving all thirteen by hand. The eight rows whose original
      owner became an `out-of-scope` stub name the fold destination, with the
      original kept as `(was: …)`; a row still pointing at a
      zero-requirement stub is a failure of this box, not a permitted
      indirection.
- [ ] `bash tests/live-bugs.sh` exits 0.

## Out of scope
- Implementing the fixes. This node routes them; the S, E and T nodes apply
  them.
- Writing any file under `.mi/prd/03-editor/`, `04-shell/`, `05-platform/` or
  `02-terminal/`. Those belong to the correction lanes and are why this node
  deadlocked before.
- Tracking whether a routed fix has landed. The receiving node's own boxes are
  that record; a second tracker here goes stale and reads as authoritative the
  whole time it is wrong.
- Finding new live bugs. The sweep is closed; a new one is a new entry placed
  by whoever finds it.

## Assumptions
«PRESERVE: ## Assumptions»

## Decisions
«PRESERVE: ## Decisions»

## Findings
«PRESERVE-WITH-ONE-EDIT: ## Findings»
      (all four subsections copied byte for byte — the two audit-finding
      corrections, the routing table, the four requirement lines other nodes'
      owners must place, and "Why R3 is `[~]` and not `[x]`" — with exactly
      one edit and no other: the owner cell of rows L-1, L-4, L-6, L-7, L-8,
      L-9, L-10 and L-12 names the fold destination, keeping the original as
      `(was: <original node>)` in the same cell. The eight destinations are
      listed in this block's header. Every other byte of the section is
      copied. This is the only «PRESERVE-WITH-ONE-EDIT» in the document, and
      the edit is enumerated rather than described because an edit stated as a
      rule is an edit an applier will widen.)

### The escalation of 2026-08-20, and its resolution
«PRESERVE: ## Escalation»
      (the entire existing `## Escalation` section moved here verbatim,
      heading demoted to `###`, including the source-vs-deployed measurement
      table, the three-part decision-4 question, the sequencing note, and
      "### Resolved 2026-08-21 — decision 4 answered by the user")

## Notes
«PRESERVE: ## Notes»
```

### 5 · `00-delivery/corrections/w0-2-terminal-respec` — REWRITE

Current: 0 / 9 / 0; after: 0 / 11 / 0. `R6` retired (README tree and child
counts become a generated fold — Law 4, "membership by existence, not by a
maintained list"), and `R8`/`R9` retired as well: this plan writes those two
facts into `02-terminal/01-appearance` itself (block 23), and stating them in
both places is a double-write of one file. Acceptance box 3 re-homed to
`delivery`. Deps cut to `w0-1` alone: its input exists, and a bug catalogue
does not gate a terminal re-spec. **Scope narrowed, stated because it is a
change of contract:** W0.2 re-specs the five terminal children this plan does
not rewrite inline, and `01-appearance`'s own `deps` edge on W0.2 is cut in
the same change — a node may not depend on a node that would overwrite it
with what it already holds.

```markdown
--- .mi/prd/00-delivery/corrections/w0-2-terminal-respec/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-1-terminal-inventory
priority: 95
verify: ""
---

# Re-spec the terminal epic from the inventory

Purpose: The terminal epic was written from the legacy inventory and is wrong
in almost every requirement. A live probe of wezterm `20240203-110809-5046fc22`
rejects four of the five config fields `01-appearance` names as invalid Config
fields, `fc-list` finds zero `agave` faces against 36 CaskaydiaCove, and the
`/src/colors` path R1 depends on does not exist — `ls /src` returns "No such
file or directory" and there is no Nix, flake or lockfile anywhere in this
repo. This node is the single owner of the rewrite for all six terminal
children. Its input, `capabilities-terminal.md`, exists: W0.1 closed
2026-08-20.

## Requirements
- [ ] **R1** — Rewrite each terminal PRD from `capabilities-terminal.md` and
      the deployed 1149-line `~/.config/wezterm/wezterm.lua`, not from the
      current file and not from the abandoned 339-line chezmoi source. Per
      decision 4 the deployed tree is canonical; the ~810-line delta is not
      pushed back.
- [ ] **R2** — The self-healing nine-tab floor is the tab/pane model, and it
      is written down as such: what re-creates a missing tab, when, and what
      stops it recursing. burrito is deleted, so the two-competing-models
      problem is gone; remove every burrito reference from the epic.
- [ ] **R3** — Correct the confirmed errors, each with the probe that proves
      it: the font is CaskaydiaCove Nerd Font at 14.0pt on macOS and 9.0pt
      elsewhere, not agave 18pt; the palette source is
      `~/.config/wezterm/colors.lua`, tinty-generated; palette ownership runs
      terminal→downstream, not the inverse; `Cmd+N` and `gui-attached` do not
      exist in the live config (T-5, T-7); and the F5 letter set is
      `asdfghjkl` indexing `tab:panes()` in split-creation order, not geometry
      (T-8).
- [ ] **R4** — Record that `PaneSelect` must not be used, with its reason: a
      Lua-opened modal cannot be dismissed across a tab switch, so a jump that
      changes tabs leaves a stuck overlay. That is a documented failure and
      the reason is the expensive part.
- [ ] **R5** — Give the ~230 uncovered lines of live machinery a home in one
      of the three rewritten terminal nodes, or record them as dropped with a
      reason. Nothing is left uncovered by silence.
R6 — *retired 2026-08-21.* "Update the epic and `README.md` together:
children go from five to six" instructed a node to hand-edit a file that is
now a generated fold — the README tree and the epic child counts are computed
from directory existence by
[`work-breakdown`](../../work-breakdown/prd.md) R3 and written by
[`delivery`](../w0-4-s2-corrections/delivery/prd.md) R8. Keeping it would make
a second writer of a generated file. Number retained as a gap; do not reuse.
Not a box: a retired requirement must be invisible to the scheduler.
- [ ] **R7** — Record the F5 miss-path bug (L-11) in the jump-mode node: the
      miss path rings BEL, but `audible_bell = "Disabled"` and no visual bell
      is set, so a mistyped jump letter gives no feedback at all. Name the
      feedback the rebuild uses instead. W0.6's routing table marks this
      **PLACE** and R5's generic clause is a container, not a statement.
R8 — *retired 2026-08-21, because this plan already performed it.* "Record
that the palette is read with `dofile` under `pcall` plus
`add_to_config_reload_watch_list`, and that `dofile`-not-`require` is
load-bearing" is written, in full and with its reason, as
[`02-terminal/01-appearance`](../../../02-terminal/01-appearance/prd.md)
**R1**. Two nodes stating one fact is a double-write of one file and the
"one requirement, one home" rule forbids it. Number retained as a gap; do not
reuse. Not a box: a retired requirement must be invisible to the scheduler.

R9 — *retired 2026-08-21, same reason.* "Record the platform detection
actually used: `wezterm.target_triple` with `triple:find('darwin')` at
`wezterm.lua:10-11`" is
[`02-terminal/01-appearance`](../../../02-terminal/01-appearance/prd.md)
**R4**. Number retained as a gap; do not reuse. Not a box.
- [ ] **R10** — The palette-ownership statement lives in the `02-terminal`
      epic and nowhere else; the terminal children and
      [`03-editor/11-colorscheme`](../../../03-editor/11-colorscheme/prd.md)
      reference it rather than restating it. It appears twice in the tree
      today, in neither of those places.

## Acceptance
- [ ] No terminal PRD asserts a capability `capabilities-terminal.md` does not
      show, checked by reading all three rewritten nodes against it.
- [ ] Every config field name any terminal node writes is accepted by
      `wezterm --config-file <probe> ls-fonts --list-system` with no
      invalid-Config-field error.
- [ ] Each of T-1 through T-11 is fixed in a terminal node or recorded in the
      backlog as accepted with a reason, with none left unmarked.
- [ ] L-11 resolves to a requirement number in a terminal node.

## Out of scope
- Implementing any of it. The T nodes build; this one specifies.
- burrito. It is deleted from the repo (2026-08-20) and no terminal node
  acquires its tab or session behaviour.
- Editing `.mi/prd/README.md` or any epic child-count table — those are
  generated folds owned by `delivery` and `work-breakdown`.
- Pushing the ~810-line wezterm delta back into the abandoned chezmoi source.
- **`.mi/prd/02-terminal/01-appearance/prd.md`.** This plan applies that
  node's re-spec inline — block 23 is the rewritten file, written from
  `capabilities-terminal.md` and the deployed `wezterm.lua` — so W0.2 rewrites
  the other five terminal children and not that one. It is named here because
  an earlier draft had both nodes writing the same file with the same two
  facts, and had `01-appearance` declaring a `deps` edge on the node that
  would overwrite it; that edge is cut and R8/R9 are retired above. R1–R5, R7
  and R10 still apply to the five remaining children.
```

### 6 · `00-delivery/corrections/w0-4-s2-corrections/editor` — REWRITE

Current: 0 / 6 / 0; after: 0 / 9 / 1 — R6 arrives from `w0-6-live-bugs` R3
carrying its `[~]`. R1–R5 keep their numbers and text, sharpened.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/editor/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

# 03-editor corrections

Purpose: One epic's share of the S2/S3 corrections sweep, and the sole writer
of `.mi/prd/03-editor/`. One writer per file, so the lanes run in parallel
instead of one agent serialising ~22 files. It also lands four findings that
have no home anywhere on the board today, because the node that found them may
not write this directory.

## Requirements
- [ ] **R1** — L-8: the treesitter `FileType` autocmd and shift-select's
      `ModeChanged` are ungrouped, so a reload stacks duplicates — a violation
      of `03-autocmds`' own invariant, which already states the pattern
      correctly for its own four autocmds. Record grouping as a requirement in
      both places. Neither destination states it today.
- [ ] **R2** — L-10: gitsigns delete/topdelete glyphs are empty strings live;
      both documents describe them as glyphs, and the PRD reproduces the bug
      by writing a literal empty string. Substitute the actual nerd-font
      character into the requirement text and record that the glyph is
      restored, not that the loss is ported.
- [ ] **R3** — L-6: `<Esc>` → `nohlsearch` is inert because `hlsearch=false`.
      Port one or the other and say which, as a decision with its reason, not
      as a question. The answer is recorded in
      [`w0-6-live-bugs`](../../w0-6-live-bugs/prd.md) `## Decisions`: keep
      `hlsearch = false`, drop the inert map.
- [ ] **R4** — M-1: the scrolloff overclaim in `01-options` — `scrolloff=999`
      does not centre the cursor "at all times"; the first and last half-screen
      are uncentred. M-3: the live binary is 0.12.4, where
      `vim.highlight.on_yank` is deprecated in favour of `vim.hl.on_yank`, and
      `03-autocmds` R1 prescribes the deprecated API. M-17 closes as
      already-done: the epic's Purpose reads "~680 lines across 14 files"
      today, measured at `.mi/prd/03-editor/prd.md:13`.
- [ ] **R5** — Record that `plugins/editor.lua` is split into one file per
      plugin, and that the filename appears nowhere in the live tree though
      three PRDs write it — 7 hits under `.mi/prd`, measured.
- [~] **R6** — *re-homed from [`w0-6-live-bugs`](../../w0-6-live-bugs/prd.md)
      R3, 2026-08-21.* L-6 and L-9 stop being questions and become records in
      the nodes that must implement them. L-9's answer is already written and
      checked against a live nvim 0.12.4 — the visual-mode `<C-v>` shadow is
      intentional, port as-is, leave `<C-q>` unbound — and travels verbatim
      into both the keymaps and shift-select requirements. L-7 gets a
      requirement too: oil is lazy on `keys`, so `default_file_explorer` is
      not installed until `<leader>e`, and with netrw disabled `:e some/dir`
      opens neither — the explorer node's third acceptance line asserts the
      behaviour the bug prevents. **STUB: the decisions exist in
      `w0-6-live-bugs` `## Decisions`; the transcription into the owning PRDs
      is what is missing.** Opens `[~]` because that is the state it carried,
      and downgrading it to `[ ]` would lose the record that a real decision
      is standing in.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
- [ ] `grep -rn 'editor.lua' .mi/prd/03-editor` returns nothing, and the
      gitsigns requirement contains a visible glyph rather than an empty code
      span.
- [ ] L-6, L-7, L-8, L-9 and L-10 each name `03-editor` as owner in the
      live-bug routing table and each has a matching requirement number in a
      `03-editor` node.
- [ ] No requirement in `03-editor` names `vim.highlight.on_yank`.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
  split.
- Writing any Neovim Lua. This node corrects specification only.
- `.mi/docs/capabilities-nvim.md`, whose sort-order violations belong to the
  docs-inventories node.
- Answering the shift-to-select fork — that is
  [`decisions/shift-select-scope`](../../../decisions/shift-select-scope/prd.md).
```

### 7 · `00-delivery/corrections/w0-4-s2-corrections/shell` — REWRITE

Current: 0 / 7 / 0; after: 0 / 14 / 0. R1–R6 keep their numbers; R7, R8 and R9
are new (R9 receives `verification-gates` R11's edit for the one file in this
directory that names a wave-numbered gate), and one acceptance box is added
for it.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/shell/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

# 04-shell corrections

Purpose: One epic's share of the S2/S3 corrections sweep, and the sole writer
of `.mi/prd/04-shell/`. The shell epic carries the largest cluster of live
bugs the rebuild must not reproduce — a channel name that is not a channel, a
decoder that has never once fired, a `du` flag macOS does not support with its
stderr discarded — plus a whole deleted subsystem still named in two
requirements.

## Requirements
- [ ] **R1** — L-3: `rcwd` is not a channel; the real name is `recent-dirs`,
      and the decoder only types `rcwd`, so recent-dir picks are never decoded
      as paths. Wrong in `01-core-config`, `04-television` (twice) and the
      inventory — 6 hits under `.mi/prd`, measured. `recent-dirs` becomes the
      only name that appears.
- [ ] **R2** — L-4: finder picks are never logged to the quicklist; only
      zoxide jumps and the bare-word fallback log. `07-quicklist`'s premise
      and one acceptance criterion are wrong and must be corrected, not
      carried.
- [ ] **R3** — L-1: `ls -D` runs `du -sb`, which macOS `du` does not support,
      and stderr is discarded so sizes silently stay inode sizes. Specify a
      measurement that works on macOS (`-sk`, or `gdu`) and require that a
      failure is visible rather than swallowed.
- [ ] **R4** — M-7: `bb`/`ba` invoke `brr`, not `burrito`. Both aliases go
      away entirely now that burrito is deleted (2026-08-20); remove
      requirement 4 from `02-aliases-utilities` rather than correcting the
      binary name.
- [ ] **R5** — Remove the burrito-sessions channel from `04-television`, which
      also dissolves the `cht.sh=f5` / `burrito-sessions=f5` shortcut
      collision.
- [ ] **R6** — Absorb the uncovered live behaviour the backlog lists: the
      `nu-history` channel that `Alt-R` depends on, `ollama-host`, starship,
      `$env.ENV_CONVERSIONS`, `esc_clear`, and the `cursor_shape` / `table` /
      `sync_on_enter` / `completions.external` blocks. Each gets a requirement
      in the node that owns it or an explicit line saying it is dropped and
      why.
- [ ] **R7** — *re-homed from [`w0-6-live-bugs`](../../w0-6-live-bugs/prd.md),
      2026-08-21.* L-2 gets a requirement, which it has nowhere on the board
      today: the `Commits` decoder reads field index 1 of a line the channel
      has already reduced to a bare hash, and the `^[0-9a-f]{7,}$` guard then
      drops every row, so commit → `git show` has never once run. Require the
      decoder to read the field the channel actually emits, and require a
      check that a commit pick reaches `git show` with a non-empty diff.
- [ ] **R8** — De-duplicate within this epic. `02-aliases-utilities` states
      `rr` → `chezmoi update --force` twice: once as R3 and once as a box
      labelled "R4 (from `05-platform/01` req 4)" asserting the same fact
      verbatim. R3's text survives; the duplicate box goes. The pointer that
      produced it — `05-platform/01-deploy-mechanism`'s allocation table
      saying "moved out of this epic — R4; see the Notes below" — is dangling:
      that file has no `## Notes` section. Removing the dangling pointer is
      `w0-4-s2-corrections/platform` R1's pass over that file. Within this
      epic, `cdi` is stated in two PRDs and the OSC 133 double-marking reason
      in more than one place: `cdi` keeps one home in the zoxide node, the
      OSC/terminal-integration reason one home in `04-shell/01-core-config`
      R5, and the others reference them.
- [ ] **R9** — *received from
      [`verification-gates`](../../../verification-gates/prd.md) R11,
      2026-08-21.* `.mi/prd/04-shell/07-quicklist/prd.md`'s `verify:` reads
      `"quicklist round-trips a pick (wave-5 gate)"` — a gate named by wave
      number, which is reachable from no node and exists nowhere. Replace the
      wave reference with the gate script path
      `bash tests/gates/shell.sh`, keeping the behavioural half of the string.
      This lane makes the edit because it owns `.mi/prd/04-shell/`;
      `verification-gates` decides the replacement form and writes no file
      here.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
- [ ] `grep -rn 'burrito\|brr\|rcwd' .mi/prd/04-shell` returns nothing.
- [ ] L-1, L-2, L-3 and L-4 each have a matching requirement number in a
      `04-shell` node, and the live-bug routing table's rows for them read
      routed rather than PLACE.
- [ ] `rr` → `chezmoi update --force` appears exactly once in the tree.
- [ ] `grep -rnE 'wave-[0-9]+ gate' .mi/prd/04-shell` returns nothing.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
  split.
- Writing any nushell. This node corrects specification only.
- `.mi/docs/capabilities-nushell.md`, including its `bb`/`ba` entries — that
  is the docs-inventories node.
- The fzf-versus-tv fork, which is
  [`decisions/fzf`](../../../decisions/fzf/prd.md).
```

### 8 · `00-delivery/corrections/w0-4-s2-corrections/platform` — REWRITE

Current: 0 / 4 / 0; after: 0 / 9 / 0. R1–R3 keep their numbers; R4 and R5 new.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/platform/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

# 05-platform corrections + burrito strip

Purpose: One epic's share of the S2/S3 corrections sweep, and the sole writer
of `.mi/prd/05-platform/`. Decision 4 changed what this epic is — a
from-scratch deploy mechanism, not a port of a working one, because the
chezmoi source and the deployed tree were measured to be different programs
rather than copies. This node makes the specification say that, and strips the
deleted subsystem out of the managed surface and the package set.

## Requirements
- [ ] **R1** — Remove burrito from `01-deploy-mechanism` requirement 2's
      managed-surface list. In the same pass, remove that file's dangling
      allocation pointer "moved out of this epic — R4; see the Notes below":
      the file has no `## Notes` section, and the requirement it points at is
      already `04-shell/02-aliases-utilities` R3.
- [ ] **R2** — Remove `burrito/brr` from `02-package-provisioning` requirement
      7's required set. It is still there, in the string
      `tinty, docker, burrito/brr, gh`.
- [ ] **R3** — Requirement 7 also asserts that `fzf` is required whether or
      not it is wanted, an outcome the fzf decision has not reached. Replace
      the assertion with a reference to
      [`decisions/fzf`](../../../decisions/fzf/prd.md) and reconcile it with
      whatever that returns, rather than leaving both statements standing.
- [ ] **R4** — *re-homed from [`w0-6-live-bugs`](../../w0-6-live-bugs/prd.md),
      2026-08-21.* L-12, with its correction, which it has nowhere on the
      board today: `solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh`
      and `background.png` are dead in the DEPLOYED tree but `solo-window.*`
      IS referenced by the abandoned chezmoi-source `wezterm.lua`, which
      defines `solo_window()` and calls it twice. Under decision 4 the deployed
      tree is canonical, so they are dead — but the requirement must carry
      *why*, or the next reader who greps the source tree reinstates them.
- [ ] **R5** — State in the epic that 05-platform builds a deploy mechanism
      from scratch. The chezmoi source at `~/.local/share/chezmoi` is not a
      port target; L-13 records that applying it as it stands would destroy
      the configuration the inventories were written from.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
- [ ] `grep -rn 'burrito\|brr' .mi/prd/05-platform` returns nothing.
- [ ] No 05-platform node describes itself as porting the chezmoi source, and
      L-12 resolves to a requirement number here carrying the
      source-vs-deployed nuance.
- [ ] The required package set names `fzf` only in the form the decision
      returned, with no "whether or not it is wanted" hedge.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
  split.
- Writing any chezmoi templates or scripts.
- `.mi/docs/capabilities-provisioning.md`, which is the docs-inventories
  node's — including the two paragraphs that still argue the chezmoi source is
  canonical.
- Deciding fzf.
```

### 9 · `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` — REWRITE

Current: 0 / 6 / 0; after: 0 / 13 / 0. R1–R5 keep their numbers; R6 arrives
from W0.3 R3; R7 and R8 are new.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

# Docs inventories

Purpose: The rated inventories in `.mi/docs/` are the spec source every build
node writes from, and the sole property of this node. `capabilities.md` is
USER-AUTHORED — the backlog's own acceptance says its corrections are
confirmed with the author before editing, so that confirmation is a box here
and not an assumption. Three inventories contradict either themselves or a
decision already taken.

## Requirements
- [ ] **R1** — `capabilities.md` is user-authored. No edit to it lands until
      the author's confirmation is recorded here with a date.
- [ ] **R2** — Fix the marker typo `DO NOT PORST` (1 hit, `capabilities.md`
      line 154, the OpenCode theme-generation entry), the missing markers on
      the three entries the README treats as excluded ("Cross-platform
      Lua/shell/PowerShell parity", "Cross-platform dependency bootstrap",
      "Just task runner"), the header note describing verdicts as containing
      `|` when none do, and the "maximiz:ed" typo.
- [ ] **R3** — Fix the sort-order violations: four rises in
      `capabilities-nvim.md`, opacity below theme in `capabilities-nushell.md`.
- [ ] **R4** — Reconcile the mini.nvim entry, unmarked in one inventory and
      double-rated in another.
- [ ] **R5** — Strip burrito: the `bb`/`ba` aliases in
      `capabilities-nushell.md` and burrito from
      `capabilities-provisioning.md`'s package list.
- [ ] **R6** — *re-homed from
      [`w0-3-platform-rewrite`](../../w0-3-platform-rewrite/prd.md) R3,
      2026-08-21.* `capabilities-provisioning.md` violates the best-ratio-first
      sort rule its own header line 6 states: recomputed from the file, its
      value ratios run 6, 7, 6, 1, 4, 6, 6, 6, 5, −2, −1, 0 in file order,
      rising at position 2. Re-sort it descending by (usefulness − complexity)
      with ties broken by existing file order. The resulting order is recorded
      in W0.3's R3 box; do not re-derive it.
- [ ] **R7** — Propagate decision 4 into the inventories.
      `capabilities-provisioning.md`:13–16 states the chezmoi source "is how
      this machine actually gets configured" and :101–103 states canonicality
      "is a human decision"; both are false as of 2026-08-21. Rewrite them to
      state that the deployed `~/.config` tree is canonical and that
      `05-platform` rebuilds from scratch — and not that the file is a
      historical artifact, because `05-platform` still points here as its spec
      source.
- [ ] **R8** — Sweep every `.mi/docs/capabilities-*.md` for text written
      against the chezmoi SOURCE tree rather than the deployed one. Each of
      the four opens with "Source of truth: the live config in `~/.config/…`
      (chezmoi-managed)", which is two claims of which the second is false.
      Where one is found, that is a correction, not a difference of opinion;
      each is fixed or recorded with the line it was found at.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
- [ ] `grep -rn 'DO NOT PORST\|burrito' .mi/docs` returns nothing.
- [ ] Recomputing the value ratios in file order for all four inventories
      yields a non-increasing sequence in each, printed as evidence.
- [ ] Every inventory entry carries a complexity, a usefulness and a verdict
      marker, or falls under the header note's unmarked-means-take-over rule.
- [ ] `grep -n 'chezmoi source' .mi/docs/capabilities-provisioning.md` returns
      only lines naming it as abandoned.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
  split.
- `.mi/docs/delivery-gantt.md`, which is a generated fold owned by
  [`work-breakdown`](../../../work-breakdown/prd.md).
- Any file under `.mi/prd/`. The inventories are this node's; the PRDs that
  cite them are their own nodes'.
- Re-rating anything. Verdicts and numbers change only where a correction
  requires it, and never silently. Fixing a sort order is not re-deciding a
  number.
- `research-*.md`, which carries no ratings and no per-item state.
- Creating `capabilities-terminal.md`, which W0.1 already produced.
```

### 10 · `00-delivery/corrections/w0-4-s2-corrections/help` — KEEP

Unchanged except frontmatter (`priority: 95`, `verify:`). Current: 0 / 5 / 0;
after: 0 / 5 / 0. R1–R4 and the acceptance box stand as written; they are
correct and specific, and nothing in this plan moves them.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/help/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

«PRESERVE: everything from the `# 06-help corrections` title to end of file —
Purpose, R1–R4, the acceptance box and `## Out of scope` — byte for byte.»
```

### 11 · `00-delivery/corrections/w0-4-s2-corrections/delivery` — REWRITE

**This node survives** rather than dissolving, because it already owns
`.mi/prd/README.md` and that is where W0.3's re-homed R2 belongs — the task
that already owns the file. Current: 0 / 7 / 0; after: 0 / 9 / 0. R1, R2 and
R3 leave for `work-breakdown` (they are defects in the schedule document, not
in the README); R5 and R6 leave for the `w0-4-s2-corrections` parent (they are
cross-tree, not README); R4 and the acceptance box stay; R7, R8 and R9 arrive.
**R9 is new in this repair**: `.mi/SYSTEM.md` was owned by nobody in the
earlier draft while the plan changed the very number it states, and
`CLAUDE.md`/`AGENTS.md` are symlinks to it, so the wrong count would have been
the first thing every future agent read.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 95
verify: ""
---

# Readme corrections

Purpose: One epic's share of the S2/S3 corrections sweep, and the sole writer
of `.mi/prd/README.md` and of `.mi/SYSTEM.md` — the index, the tree diagram, the
build order, the canonical exclusion list, and the working contract every
agent reads first (`CLAUDE.md` and `AGENTS.md` are symlinks to it). It states its exclusions three times in three forms
and carries none of the three provisioning verdicts the provisioning inventory
holds. The work-breakdown-document defects that used to sit in this node moved
to [`work-breakdown`](../../../work-breakdown/prd.md), which owns the schedule;
the cross-tree duplication and wrap items moved to the sweep parent, which is
the only node that can see all the copies at once.

## Requirements
R1 — *re-homed 2026-08-21.* The critical-path arithmetic defect ("≈ 26
agent-hours"; its own sizes sum to 33) is a defect in
`.mi/prd/00-delivery/work-breakdown/prd.md`, not in the README, and is now
[`work-breakdown`](../../../work-breakdown/prd.md) **R7**. Number retained as
a gap; do not reuse.

R2 — *re-homed 2026-08-21.* M-18, the `conf/` target for C.4, is now
[`work-breakdown`](../../../work-breakdown/prd.md) **R8**. Number retained as
a gap; do not reuse.

R3 — *re-homed 2026-08-21.* The duplicated Track T header row is now
[`work-breakdown`](../../../work-breakdown/prd.md) **R9**, where it becomes
unrepresentable rather than merely fixed. Number retained as a gap; do not
reuse.

- [ ] **R4** — `README.md` states its exclusions twice: once in prose and once
      inside the `## Excluded` list, with a third pointer earlier in the file.
      One survives, and it is the list, because it is the one other documents
      cite. Every other mention becomes a link to it.

R5 — *re-homed 2026-08-21.* The S3 duplicated facts (`cdi` in two PRDs, the
kitty-protocol reason in three places, "the terminal owns the palette"
repeated) span every epic and cannot be decided by a single-directory writer.
Now [`w0-4-s2-corrections`](../prd.md) **R1**. Number retained as a gap; do
not reuse.

R6 — *re-homed 2026-08-21.* The ~78-column wrap limit and the table exemption
apply tree-wide. Now [`w0-4-s2-corrections`](../prd.md) **R2**. Number
retained as a gap; do not reuse.

- [ ] **R7** — *re-homed from
      [`w0-3-platform-rewrite`](../../w0-3-platform-rewrite/prd.md) R2,
      2026-08-21.* The `## Excluded` list carries no provisioning entries
      though `capabilities-provisioning.md` holds three verdicts. Measured:
      `grep -in "mirror|wp-stat|docs site|provisioning|chezmoi"
      .mi/prd/README.md` returns 6 hits, all in the intro paragraph and the
      tree diagram, none in `## Excluded`. `SYSTEM.md` requires a DO NOT PORT
      decision to appear in the epic Non-goals *and* the README exclusion
      list; the epic half is already met. Replacement text, in the file's
      house style with each reason taken from the inventory entry rather than
      invented, is recorded in W0.3's R2 box — do not re-derive it.
- [ ] **R8** — The README tree diagram, the epic child counts and the build
      order are regenerated from the board by
      [`work-breakdown`](../../../work-breakdown/prd.md)'s generator in the
      same change, never hand-maintained. Node membership is by existence; a
      list beside it goes stale silently. This node runs the generator and
      lands its output; `work-breakdown` owns the generator.
- [ ] **R9** — **`.mi/SYSTEM.md` has an owner, and it is this node.** It
      carries the epic child-count table and the sentence "77 nodes in all",
      and `CLAUDE.md` and `AGENTS.md` at the repo root are symlinks to it — so
      it is the first thing every future agent reads, and a wrong number there
      is wrong everywhere at once. After the restructure the tree holds **78
      addresses, 28 of them `out-of-scope` redirect stubs holding no work**,
      which is a different sentence from "77 nodes in all". The child-count
      table and the node count are produced by `work-breakdown`'s generator
      from `find .mi/prd -name prd.md` and landed here, and the count is
      stated in the form the tree can prove: total addresses, and how many
      hold work. Until this node runs, `SYSTEM.md` is stale by exactly one
      node and twenty-eight stubs, and this requirement is the record of that.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
- [ ] The exclusion list appears exactly once, and every other mention is a
      link to it.
- [ ] All three provisioning verdicts appear in the exclusion list with their
      reasons.
- [ ] The README tree, the child counts and the build order agree with
      `find .mi/prd -name prd.md`, and re-running the generator produces no
      diff.
- [ ] `.mi/SYSTEM.md`'s epic child-count table and its node-count sentence
      agree with `find .mi/prd -name prd.md | wc -l` and with the count of
      files whose frontmatter is not `state: out-of-scope`, and re-running the
      generator produces no diff. Checked through `CLAUDE.md` as well, to
      prove the symlink still resolves to the same file.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
  split.
- The work-breakdown document's own defects, and the cross-tree duplication
  and wrap sweep. Both moved; the numbers above say where.
- Authoring per-item state into the README. It is a fold.
- Rewriting `.mi/SYSTEM.md`'s prose. This node lands the generated table and
  the node count into it and touches nothing else there; the working
  contract's wording is the user's.
```

### 12 · `00-delivery/corrections/w0-5-capsule-rebase` — REWRITE

Current: 0 / 8 / 0; after: 0 / 11 / 0. R1–R5 keep their numbers and text; the
three boxes arriving from `w0-4-s2-corrections/capsule` are duplicates of R3
and R5 and land as sharpenings inside them, and that node's acceptance box is
this node's acceptance box 3. R6 and its acceptance box are new: they receive
`verification-gates` R11's edit for the one file in this directory that names
a wave-numbered gate. Both nodes wrote `.mi/prd/01-capsule/` and could
never have run in parallel; the split bought nothing and cost a shared-writer
hazard.

```markdown
--- .mi/prd/00-delivery/corrections/w0-5-capsule-rebase/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
priority: 95
verify: ""
---

# Re-base 01-capsule on build-once and free the colliding bindings

Purpose: The capsule epic rests on legacy code that never worked and claims
keybindings that are already taken. Re-base it before anything is built. This
node is the sole writer of `.mi/prd/01-capsule/`; the separate capsule
correction node is folded in here, because two nodes pointed at one directory
serialise no matter how many agents are free and they carry one contract
between them.

## Requirements
- [ ] **R1** — Re-base the epic on "build once": one image definition, built
      once, reused. C-2 records that no live capsule implementation exists to
      consolidate from — no `~/docker`, no Dockerfile or capsule script in
      `~/.config` — so this is design, not porting. Rebuild happens when the
      definition changed, not per invocation.
- [ ] **R2** — Resolve the `Ctrl+Shift+B` / `Ctrl+Shift+T` collisions (C-1).
      `Ctrl+Shift+B` is free: wallpaper cycling is `DO NOT PORT` and the
      opacity picker is `DEFER` on the README exclusion list, settled by
      [`decisions/wallpaper-opacity`](../../decisions/wallpaper-opacity/prd.md)
      on 2026-08-21, so `capsule --rebuild` takes it. `Ctrl+Shift+T` is
      WezTerm's own `SpawnTab` default, which the tab reconciler treats as the
      manual new-tab path — claiming it is a shadow, not a free key, and it
      must be overridden explicitly or another key picked.
- [ ] **R3** — Do not preserve legacy `mount` behaviour. C-3: it `cd`'d to a
      nonexistent `~/docker`, passed wrong `just` recipe arguments, and
      mounted `./workspace` rather than `$PWD`. It never worked, so its
      behaviour is not the specification and no capsule PRD may describe it as
      the target. Design the lifecycle semantics fresh.
- [ ] **R4** — Correct C-4: `devzsh` has no zsh baked in (`CMD ["bash"]`), so
      zsh, oh-my-zsh and Claude Code come only from the new image and must be
      requirements of it, not assumptions about the base.
- [ ] **R5** — Give the capsule terminal keybinding an owner, and name both
      halves in both nodes: the capsule node owns the CLI subcommand, the
      terminal node owns the key that invokes it. `01-capsule/01` req 4
      requires `capsule --rebuild` bound in the terminal and the epic success
      criterion requires one keybinding; no task binds it today. C-5 also
      applies: the "Recent:" status indicator has no host, because the live
      status bar is clock-only and `set_left_status` is never called.
- [ ] **R6** — *received from
      [`verification-gates`](../../verification-gates/prd.md) R11,
      2026-08-21.* `.mi/prd/01-capsule/03-credential-propagation/prd.md`'s
      `verify:` reads `"git push works inside a capsule (wave-4 gate)"` — a
      gate named by wave number, reachable from no node and existing nowhere.
      Replace the wave reference with the gate script path
      `bash tests/gates/deploy.sh`, keeping the behavioural half. That node
      folds into `01-capsule/01-container-lifecycle` as C1, so the corrected
      string lands on the destination node's `verify:` and the stub keeps
      none. This lane makes the edit because it owns `.mi/prd/01-capsule/`.

## Acceptance
- [ ] No capsule PRD describes behaviour of the legacy `mount` script.
- [ ] Every binding the epic claims is free, or its conflict is recorded with
      the resolution and the node that owns each half.
- [ ] C-1 through C-5 are each fixed or recorded as accepted with a reason.
- [ ] The image requirements name every tool they assume, with none inherited
      from a base that does not carry it.
- [ ] `grep -rnE 'wave-[0-9]+ gate' .mi/prd/01-capsule` returns nothing.

## Out of scope
- Building the image or the CLI. C.1 and C.2 do that.
- Files outside `.mi/prd/01-capsule/`, including `.mi/docs/` and
  `.mi/prd/README.md`.
- Answering the Odin-toolchain question — that is
  [`decisions/odin-toolchain`](../../decisions/odin-toolchain/prd.md); this
  node records the fork without resolving it.
```

### 13 · `00-delivery/decisions/wallpaper-opacity` — NARROWED, and it stays open

**An earlier draft of this plan closed this node as met. That was wrong and is
withdrawn.** The README answers a narrower question than the node asks, and
closing a `mode: hitl` fork against evidence for a different question is the
false record §6 forbids.

**What the README does settle**, and it is real. `.mi/prd/README.md:143`,
under `**\`DO NOT PORT\` — legacy \`~/.files\`:**` — "… Obsidian vault
dashboards · **background image cycling** · Karabiner Windows-keyboard rules
…". `.mi/prd/README.md:165-166`, under `**\`DEFER\` — real, but not in the
minimal base:**` — "theme switcher (tinty + tv) · **opacity picker** · smear
cursor · …". So the wallpaper **cycler** is refused and the interactive
opacity **picker** is deferred. That is enough to free `Ctrl+Shift+B` for
`capsule --rebuild`, and the binding half is recorded as settled in
`w0-5-capsule-rebase` R2 and `01-capsule/01-container-lifecycle` R4 on the
strength of the cycler verdict alone.

**What it does not settle, and what the node actually asks.** This node's own
escalation, at `02-terminal/01-appearance:104-105`, states the fork as
*"`decisions/wallpaper-opacity` decides `window_background_opacity` and the
base00 tint (`capabilities-terminal.md:220-229`)"*. The live config sets
`window_background_opacity = 0.95` and `macos_window_background_blur = 30`
(`~/.config/wezterm/wezterm.lua:608-614`). Excluding an interactive *picker*
says nothing about what static opacity the rebuild ships, and nothing at all
about the base00 tint. Those two are what remain, and they are the human's.

Current: 0 / 2 / 0; after: 0 / 2 / 0 — **unchanged**. The node stays `open` and
`hitl`; both boxes stay `[ ]`. What this plan contributes is the narrowing:
two of the four sub-questions are struck as already answered, and the
remaining question is stated in one sentence so the human round-trip is
cheap.

```markdown
--- .mi/prd/00-delivery/decisions/wallpaper-opacity/prd.md ---
---
state: open
mode: hitl
deps: []
priority: 95
verify: ""
---

# Decision: wallpaper cycling + opacity toggle, and the Ctrl+Shift+B collision

Purpose: A scope fork only a person may settle. T-11 was never fixed nor
converted into a task, violating the backlog acceptance criterion "every S1
item is either fixed or converted into a task". C-1 hands `Ctrl+Shift+B` to
capsule, silently deleting the live wallpaper feature. Gates T.1 and C.2.

> **Gate.** This node has **no runnable gate today**. `verify:` is `""`
> rather than a command that would exit non-zero for the wrong reason, and the
> node's proof until then is its `## Acceptance` boxes, run by hand and
> recorded. When [`verification-gates`](../../verification-gates/prd.md) lands
> `bash tests/gates.sh`, this node's `verify:` becomes `bash tests/gates.sh`
> in the same commit that first closes a box against it — and not one commit
> earlier, because a gate that does not exist yet cannot have been run.

**Two of the four sub-questions are already answered and are struck, 2026-08-21
— by lookup, not by decision.** The canonical exclusion list refuses both:
background image cycling is `DO NOT PORT` at `.mi/prd/README.md:143`, and the
interactive opacity **picker** is `DEFER` at `.mi/prd/README.md:165-166`.
Checked with `grep -n "background image cycling\|opacity picker"
.mi/prd/README.md`, which returns exactly those two lines. Consequence, and it
does not wait on the rest of this node: **`Ctrl+Shift+B` is free** for
`capsule --rebuild`, because the feature that held it is refused outright.

**The narrowed question, and it is the whole of what is left.** This node's
escalation at `02-terminal/01-appearance:104-105` states the fork as
"decides `window_background_opacity` and the base00 tint
(`capabilities-terminal.md:220-229`)". Excluding a *picker* does not decide
what static opacity the rebuild ships. The live config sets
`window_background_opacity = 0.95` with `macos_window_background_blur = 30`
(`~/.config/wezterm/wezterm.lua:608-614`). So:

> **Ask the human, in one round:** does the rebuild ship
> `window_background_opacity = 0.95` and `macos_window_background_blur = 30`
> as the live config has them, ship fully opaque (`1.0`, no blur), or take
> some other value — and does the base00 tint apply on top of it?
> Recommendation: keep `0.95` + blur 30, because it is what the machine runs
> today and no rating asked for a change; but this is taste and money, which
> is why the node is `hitl`.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec. Two of the four halves are answered by lookup and are struck above
      with the grep that proves it; this box closes when the remaining
      question — the static `window_background_opacity` value, the blur, and
      the base00 tint — has an answer with a date. A `[x]` here against the
      README alone would be a close against evidence for a different question.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.
      [`01-capsule/01-container-lifecycle`](../../../01-capsule/01-container-lifecycle/prd.md)
      R4 may already bind `capsule --rebuild` to `Ctrl+Shift+B`: that half
      rests on the cycler's `DO NOT PORT` alone and does not wait on this
      node.
      [`02-terminal/01-appearance`](../../../02-terminal/01-appearance/prd.md)
      is the one that waits — it carries the opacity value, and this box
      closes when that node's requirements state the answered value.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
  nodes it gates.
- Re-opening the exclusion list. A reversal is the user's call and is made
  there, in `.mi/prd/README.md`, not here.
- The `Ctrl+Shift+B` binding itself, which is no longer contested: the cycler
  is refused, so the key is free, and `w0-5-capsule-rebase` R2 records it.

## Notes

Narrowed 2026-08-21, not closed. An earlier restructure proposal marked both
boxes `[x]` against `.mi/prd/README.md` and set this node `state: done`; the
README excludes a *cycler* and a *picker*, while this node decides a static
opacity value and a tint. That proposal's second box also cited
`02-terminal/01-appearance`'s `## Out of scope` naming both features — text
the same apply would not write until three commit groups later, so the
evidence did not exist at the commit that claimed it. The withdrawal is
recorded here rather than dropped, because a close that was refuted is part of
the record.
```

### 14–17 · `00-delivery/decisions/{tinty,fzf,shift-select-scope,odin-toolchain}` — REWRITE (addresses kept)

Four addresses survive. A node id is an address and a claim is a commit
against `.mi/prd/<path>/prd.md`; folding four directories out of existence to
buy one human round-trip destroys four addresses for a benefit that is a
property of how the questions are *asked*, not of how many files hold them.
The "ask all of them as one numbered round" instruction lives in the parent's
requirements instead. Each child: current 0 / 2 / 0, after 0 / 2 / 0 — the two
boxes keep their text; what changes is the frontmatter (`priority`, the `deps`
edge to `w0-6-live-bugs` cut) and the Purpose, which now names the live
destination path instead of `04-corrections-backlog.md`, a file that does not
exist. Each keeps its `## Notes` section verbatim.

```markdown
--- .mi/prd/00-delivery/decisions/tinty/prd.md ---
---
state: open
mode: hitl
deps: []
priority: 95
verify: ""
---

# Decision: does tinty stay as palette owner

Purpose: A scope fork only a person may settle. Open decision 2. tinty
generates `~/.config/wezterm/colors.lua`, which the terminal reads with
`dofile` under `pcall` and which Neovim, television and the statusline all
inherit — so it owns the palette everything downstream derives from (T-3),
while the README defers the tinty + tv theme switcher as cosmetic. If it goes,
something else must own the palette; if it stays, it is not cosmetic. The
answer is recorded here and in
[`00-delivery/corrections/prd.md`](../../corrections/prd.md) — the live path;
`04-corrections-backlog.md` was renamed in `8ecbbe4` and no longer exists.
Gates `02-terminal/01-appearance`, `02-terminal/02-startup-layout`,
`03-editor/11-colorscheme` and `04-shell/01-core-config`, which is on the
critical path. Carry with the answer the reason `dofile` is not
interchangeable with `require`: `require` caches by module name and would
return the first palette on a second `tinty apply`. Not gated on any afk node:
a question a human answers waits on the human and nothing else.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec, naming which artifact is the palette source of truth after it and
      the alternative that lost.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
  nodes it gates.
- The theme switcher UI and the opacity picker — both `DEFER` on the README
  exclusion list.

## Notes
«PRESERVE: ## Notes»
```

```markdown
--- .mi/prd/00-delivery/decisions/fzf/prd.md ---
---
state: open
mode: hitl
deps: []
priority: 95
verify: ""
---

# Decision: fzf accepted exception or replaced

Purpose: A scope fork only a person may settle. Open decision 3. `zi`/`cdi`
shell out to `zoxide query --interactive`, which spawns fzf — violating the
shell epic's own invariant that "tv owns every picker screen". Either fzf is an
accepted, documented exception with its reason, or `zi` is replaced with a
tv-backed picker and fzf leaves the required package set. This is the one
legitimate home for the fork: it is asserted in three places today, and the
other two close mechanically off the answer —
[`packages-installer`](../../../05-platform/02-package-provisioning/packages-installer/prd.md)
R7 currently hard-codes an outcome the decision has not reached ("fzf is
required whether or not it is wanted"), and
[`w0-4-s2-corrections/platform`](../../corrections/w0-4-s2-corrections/platform/prd.md)
R3 says to reconcile it. Gates `04-shell/03-zoxide`, `04-shell/04-television`
and `packages-installer`. The answer is recorded here and in
[`00-delivery/corrections/prd.md`](../../corrections/prd.md) — the live path.
Not gated on any afk node.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec, with the alternative that lost and why.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
  nodes it gates.
- fzf inside a capsule container. That toolbox is a separate list and this
  invariant is host-side.
- Replacing telescope in the editor. Two finders is a decision already made.

## Notes
«PRESERVE: ## Notes»
```

```markdown
--- .mi/prd/00-delivery/decisions/shift-select-scope/prd.md ---
---
state: open
mode: hitl
deps: []
priority: 95
verify: ""
---

«PRESERVE: everything from the `# Decision: shift-to-select full port with
tests, or the conscious downgrade` title to end of file — Purpose, both
acceptance boxes, `## Out of scope` and `## Notes` — byte for byte. The only
change is the frontmatter above (`priority`, `verify`).»
```

```markdown
--- .mi/prd/00-delivery/decisions/odin-toolchain/prd.md ---
---
state: open
mode: hitl
deps: []
priority: 95
verify: ""
---

# Decision: does the Odin-from-source / pi-oilrig toolchain survive into the image

Purpose: A scope fork only a person may settle. CLAUDE.md's Known gaps lists
this as undecided. It was an `## Open questions` section on an afk node, so an
agent would have silently taken the recommendation and closed the fork without
anyone deciding. They dominate build time; the PRD's own recommendation is
**drop**, and add per-project later. Gates the dev image. The answer is
recorded in the `## Open questions` section of
[`01-capsule/02-dev-image`](../../../01-capsule/02-dev-image/prd.md) — the
live path; `01-capsule/02-dev-image.md` was converted to a node directory and
no longer exists — and mirrored here.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec, with the alternative that lost and why.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer, including the layer ordering: a toolchain
      that stays sits below the config layer so editing config does not
      rebuild it.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
  nodes it gates.
- The rest of the image's toolbox. Only the Odin/pi question is here.
- Host-side Odin. This is about the container.

## Notes
«PRESERVE: ## Notes»
```

### 18 · `00-delivery/corrections/w0-4-s2-corrections` — REWRITE

Current: 0 / 1 / 0; after: 0 / 6 / 0. It gains the two cross-tree requirements
that no single-directory child can do, and runs alone in its tier because its
footprint spans every epic.

```markdown
--- .mi/prd/00-delivery/corrections/w0-4-s2-corrections/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
priority: 90
verify: ""
---

# Apply the S2/S3 corrections across the tree

Purpose: The corrections sweep, split one child per epic touched so each writes
only files it owns. Six children remain — capsule folded into
[`w0-5-capsule-rebase`](../w0-5-capsule-rebase/prd.md), which already owned
that directory. This node becomes ready only once all six are covered, which
is exactly when the one class of correction none of them can do alone becomes
safe: the cross-tree de-duplication, where the same fact is stated in two or
three epics and only a reader who can see all of them can decide which copy
survives. It runs alone, on purpose.

## Requirements
- [ ] **R1** — *re-homed from [`delivery`](delivery/prd.md) R5, 2026-08-21.*
      Cross-tree de-duplication: each fact stated in more than one epic keeps
      exactly one home and the others reference it. Measured at drafting:
      `cdi` 6 hits, the kitty-protocol reason 8 hits across `.mi/prd` and
      `.mi/docs`, "owns the palette" 2 hits, neither of them the terminal
      epic. Name the surviving home for each — `cdi` in the zoxide node, the
      kitty reason in `04-shell/01-core-config` R5, the palette statement in
      the `02-terminal` epic.
- [ ] **R2** — *re-homed from [`delivery`](delivery/prd.md) R6, 2026-08-21.*
      Markdown wraps at ~78 columns and tables are exempt. State the exemption
      where the rule is stated rather than quietly breaking it, and bring the
      over-long files into line without mangling a table to fit.
- [ ] **R3** — No S2 or S3 backlog item is left unmarked. Each is fixed, or
      recorded as accepted with a reason, in
      [`00-delivery/corrections/prd.md`](../prd.md).

## Acceptance
- [ ] Every child is covered, and no S2 or S3 item is left unmarked in the
      backlog.
- [ ] Each duplicated fact appears once, checked by grepping for its
      distinctive phrase and finding one statement plus references.
- [ ] No non-table line in `.mi/prd` or `.mi/docs` exceeds 78 columns.

## Out of scope
- Any single epic's corrections. The children own those, and doing them here
  re-creates the serialisation the split exists to remove.
- Generated files: `README.md`, `delivery-gantt.md` and `plan.md` are folds
  owned by `delivery` and `work-breakdown`.
- Re-opening any correction a child closed.
```

### 19 · `00-delivery/corrections` — REWRITE

Current: 0 / 4 / 0; after: 0 / 6 / 0. The four acceptance boxes become three
requirements plus three acceptance boxes; `corrections-b2` (the "three open
decisions" bullet, now wrong on both halves — there are four live forks, and
they no longer live in this file) moves to `00-delivery/decisions`. **All
evidence sections are preserved whole**: the S1 tables, the four open
decisions including decision 4's full resolution text, the S2 live-bug table,
the S2 factual-error table, the coverage-gaps section and the S3 hygiene list.
They are the record of what four audits found and Law 1 does not permit
deleting them.

```markdown
--- .mi/prd/00-delivery/corrections/prd.md ---
---
state: open
mode: afk
deps: []
priority: 88
verify: ""
---

# Corrections backlog

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Findings from the four-agent audit of 2026-08-20, which checked every
PRD and inventory against the live configs. Severity: **S1** invalidates a PRD
or a scope decision · **S2** a factual error to correct · **S3** cosmetic.
`[x]` = already fixed in that pass — the author's own note, not an executed
check, which is why `w0-3-platform-rewrite` `## Notes` records a node that was
nearly closed on the strength of one. This node is the register, not the
fixer: every S1/S2/S3 item names the node whose requirements carry it, and it
closes when no item is left without an owner.

## Requirements
- [ ] **R1** — Every S1, S2 and S3 item names the node that owns its fix, and
      that node's `## Requirements` carries the corrected behaviour. No item's
      fix is owned here.
- [ ] **R2** — Every item is marked fixed, accepted-with-reason, or retired
      against the exclusion list — never left ambiguous, and never left as a
      question. L-6 and L-9 are the standing cases: both rows still read
      "Intentional?" and "Port one or the other, not both", and both have
      answers in [`w0-6-live-bugs`](w0-6-live-bugs/prd.md) `## Decisions`.
- [ ] **R3** — `capabilities.md` corrections are confirmed with the author
      before editing, and the confirmation is recorded with a date. The edit
      itself belongs to
      [`docs-inventories`](w0-4-s2-corrections/docs-inventories/prd.md) R1.

## Acceptance
- [ ] Every S1, S2 and S3 row carries a disposition — fixed,
      accepted-with-reason, or converted to a task with the task named — and
      no row's disposition is empty.
- [ ] Every S1 item is either fixed or converted into a task before Wave 1
      starts.
- [ ] No S2 live bug is reproduced in the rebuild; each is fixed or documented
      as accepted-with-reason, with the node that owns it named.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Owning any fix. This node routes; the build nodes implement.
- Holding the answers to the open forks. Those live in
  [`00-delivery/decisions`](../decisions/prd.md); this file holds only
  decision 4, which was answered here before that node existed and stays where
  the commits point.
- Discovering new findings. A new one is placed at the node that owns the
  area, not appended here.

«PRESERVE: ## S1 — the terminal epic is specced from the wrong config»
«PRESERVE: ## S1 — capsule collides with live bindings and rests on broken code»
«PRESERVE: ## S1 — open decisions for the human»
      (including item 4 in full: the deployed-vs-source measurement, "Decided
      2026-08-21 (user)", the (a)/(b)/(c) consequences and the L-12 note)
«PRESERVE: ## S2 — bugs in the live config (do not reproduce these)»
«PRESERVE: ## S2 — my factual errors»
«PRESERVE: ## S2 — coverage gaps found»
«PRESERVE: ## S3 — hygiene»
```

### 20 · `00-delivery/decisions` — REWRITE

Current: 0 / 1 / 0; after: 0 / 6 / 0. The single acceptance box stays; two
requirements arrive — the "one numbered round" instruction, and the dead-path
repair. The five children keep their addresses.

```markdown
--- .mi/prd/00-delivery/decisions/prd.md ---
---
state: open
mode: afk
deps: []
priority: 88
verify: ""
---

# Open decisions

Purpose: The scope forks an agent must not resolve alone. Each child is one
decision, gating a different part of the build; each is answered by a person
and recorded with a date. Four are live and one — wallpaper/opacity — closed
2026-08-21 against the README exclusion list, which already refused both
halves. Between them the four gate nine implementation nodes, and human
wall-clock is the one thing no amount of parallelism removes.

## Requirements
- [ ] **R1** — **Ask the frontier as ONE numbered round**, each question with
      a recommended answer, then wait — worker.md Appendix C. Four separate
      hitl children cost four separate human turnarounds for one contract; the
      round is a property of how they are asked, not of how many files hold
      them, which is why the four addresses stay. Questions whose
      prerequisites are still open belong to a later round.
- [ ] **R2** — **No decision node depends on an afk node.** A fork waiting on
      a human waits on the human and nothing else. The
      `deps: w0-6-live-bugs` edges on tinty, fzf and wallpaper-opacity put
      three human-answerable questions behind an agent-side footprint
      deadlock, which is backwards; they are cut.
- [ ] **R3** — **Every reference to an answer's destination names a live
      path.** Four decision bodies point at `04-corrections-backlog.md`, which
      does not exist — it became
      [`00-delivery/corrections/prd.md`](../corrections/prd.md) in `8ecbbe4` —
      and one points at `01-capsule/02-dev-image.md`, now
      `01-capsule/02-dev-image/prd.md`.

## Acceptance
- [ ] Every child is resolved, so no node is waiting on an unanswered fork.
- [ ] `grep -rn '04-corrections-backlog.md\|02-dev-image.md' .mi/prd .mi/gantt`
      returns nothing.
- [ ] No decision node's `deps` names a correction task.

## Out of scope
- Implementing any answer. The work lives in the nodes each decision gates.
- Re-opening decision 4 (the deployed `~/.config` tree is canonical, the
  chezmoi source abandoned). It is answered and its consequences are scheduled
  corrections, not a fork.
- Any fork not on this list. A fifth live fork is a new child, not an
  extension of this one.

## Notes
«PRESERVE: ## Notes»
```

### 21 · `05-platform/01-deploy-mechanism/repo-skeleton` — REWRITE

Current: 0 / 4 / 0; after: 0 / 15 / 0. Absorbs `managed-config` (2 boxes) and
the `01-deploy-mechanism` parent (4). R1, R3 and R5 keep their numbers — they
were allocated from the parent and are cited that way; R2 arrives from
`managed-config` **keeping its own number**, which is free because this node
has no R2 today and R2 is what that requirement has always been called; R6
arrives from the parent, likewise keeping its number. R7–R9 are new.

```markdown
--- .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
priority: 85
verify: "chezmoi apply on a scratch target is idempotent (second apply is a no-op); just push round-trips a local edit"
---

# Repo skeleton: chezmoi source layout, home/, justfile

Parent: [`../prd.md`](../prd.md) · source: [`01-deploy-mechanism`](../prd.md)
requirements R1, R2, R3, R5, R6

Purpose: Everything in this repo reaches a machine through one apply, and
nothing can be deployed or idempotency-tested until the skeleton that apply
reads exists — so this is the spine, and it is from-scratch work. Decision 4
established that the chezmoi source and the deployed tree are different
programs and that applying the source as it stands would destroy the config,
so there is no working mechanism to port. It also gives the repo the task
runner it does not have. It owns the repo-root mechanics only; each tool's
directory under `home/dot_config/` belongs to that tool's epic, which is what
lets six epic lanes write configuration concurrently behind it.

## Requirements
- [ ] **R1** — **Source layout.** `home/` holds the managed tree
      (`dot_config/`, `dot_gitconfig.tmpl`, `run_*` scripts, `.chezmoidata/`),
      named by `.chezmoiroot`, with the repo root carrying the `justfile` and
      docs. The mapping from a source path to its deployed path is mechanical,
      with no per-file special cases.
- [ ] **R2** — *from [`managed-config`](../managed-config/prd.md).* **Managed
      config surface.** One source of truth per tool under `home/dot_config/`:
      nushell, nvim, wezterm, television, `starship.toml`, bat, gh, lazygit,
      tinted-theming. Templated only where it must differ per machine
      (`dot_gitconfig.tmpl`). burrito is not on the list; it was deleted from
      the repo on 2026-08-20.
- [ ] **R3** — **Apply.** `chezmoi apply` is the single deploy step and is
      idempotent — a second apply on an unchanged source reports no changes.
- [ ] **R5** — **Push recipe.** One `just push`: init from this source, apply,
      commit, push, then update. Mirrors the live workflow so muscle memory
      carries over.
- [ ] **R6** — *from [`01-deploy-mechanism`](../prd.md).* **Script ordering
      contract.** chezmoi runs `run_once_before` → package installer
      (`run_onchange`) → `run_after`. Anything depending on an installed tool
      lives in a later stage than the install, and stages re-resolve PATH
      because a tool installed this run is not on it yet. Asserted by
      observation of the apply log, not by naming the prefixes.
- [ ] **R7** — **The recipes.** `just install` (init plus apply on a machine
      that has never seen the repo), `just apply`, `just push`, and
      `just check`, which is a call into
      [`tests/gates.sh`](../../../00-delivery/verification-gates/prd.md).
- [ ] **R8** — **`home/` is not assumed empty.** It already holds the
      `06-help` content model — six files under
      `home/dot_config/nushell/help/`, the only implementation artifacts in
      the repo today. The skeleton accommodates existing managed files rather
      than scaffolding over them, and `.chezmoiignore` keeps `.mi/`, `tests/`,
      `justfile` and `capsule/` out of the deployed tree.
- [ ] **R9** — **Every directory the skeleton creates is claimed by exactly
      one epic**, recorded here as a table, so one-writer-per-file is a
      property of the layout rather than a rule someone remembers. Each
      per-app config dir is owned by its own track: `nushell/` by S.x, `nvim/`
      by E.x, `wezterm/` by T.x, `help/` by H.x.

## Acceptance
- [ ] `chezmoi apply` on a scratch target is idempotent (second apply is a
      no-op); `just push` round-trips a local edit.
- [ ] Fresh clone + `chezmoi apply` on a scratch target produces the full
      `~/.config` tree.
- [ ] Editing one tool's config touches exactly one path under
      `home/dot_config/`, asserted by a check, not by convention.
- [ ] The apply log shows the three script phases in the contracted order.
- [ ] `git status --porcelain home/dot_config/nushell/help` is empty after an
      apply.
- [ ] `just check` runs `bash tests/gates.sh`.
- [ ] No managed-surface list anywhere names burrito.

## Out of scope
- The sibling node's requirements. This document held two contracts and was
  split; the parent lists which requirement went where.
- Installing anything. Packages are
  [`packages-installer`](../../02-package-provisioning/packages-installer/prd.md).
- Generating shell init files, which is
  [`03-shell-init-generation`](../../03-shell-init-generation/prd.md) and must
  run after packages.
- The contents of any tool's config directory — this node creates the slot,
  the epic fills it.
- Porting the abandoned chezmoi source's file contents. Only its rated
  capabilities carry over.
- The gate scripts themselves. This node calls them.

## Notes
«PRESERVE: ## Notes»
      (the footprint-narrowing note, plus `managed-config`'s own footprint
      note appended verbatim as a second paragraph)
```

### 22 · `01-capsule/02-dev-image` — REWRITE

Current: 0 / 9 / 0; after: 0 / 11 / 0. R1–R6 keep their numbers and text,
sharpened by `w0-5-capsule-rebase` R4; R7 is new and closes the fork
explicitly. `## Open questions` is preserved — it is where the odin decision
lands.

```markdown
--- .mi/prd/01-capsule/02-dev-image/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/00-delivery/decisions/odin-toolchain
priority: 85
verify: ""
---

# Dev image

Parent: [Capsule epic](../prd.md) · C 7 · U 8 · sources: "Standalone dev
image" and "Capsule image"

Purpose: Exactly one image definition for capsule containers, merging the two
previous images. Ubuntu LTS base, unprivileged `dev` user, `/workspace` as
workdir. It is the earliest implementation node on the board with no upstream
at all — it needs no config, no deploy mechanism and no shell — and it is the
concrete meaning of "build once": the lifecycle tool reuses this image and
never defines a second one. Nothing is assumed present in the base: `devzsh`'s
CMD is `["bash"]` and it carries no zsh (C-4).

## Requirements
- [ ] **R1** — **Shell environment.** zsh + oh-my-zsh as the interactive
      shell, installed by this image rather than inherited. The zsh config
      itself is container-only; the host zshrc is not ported.
- [ ] **R2** — **CLI toolbox.** ripgrep, fd, fzf, tmux, neovim, bat, eza, git,
      build-essential, Python.
- [ ] **R3** — **Runtimes.** Node 22 (or current LTS), pinned in the image
      definition rather than resolved at build time.
- [ ] **R4** — **Agents.** Claude Code and OpenCode preinstalled, starting
      without a login flow given the credentials the lifecycle tool mounts.
- [ ] **R5** — **User.** Unprivileged `dev` user with passwordless sudo,
      created by the image or first-run setup — not running as root.
- [ ] **R6** — **Layering for speed.** Order layers so tool installs cache
      well; a config tweak must not re-download toolchains.
- [ ] **R7** — The Odin-from-source and pi/pi-oilrig toolchain is present or
      absent exactly as
      [`decisions/odin-toolchain`](../../00-delivery/decisions/odin-toolchain/prd.md)
      returned, with the decision's date cited here. A toolchain that stays
      sits below the config layer, per R6.

## Acceptance
- [ ] Single `Dockerfile` in the repo; nothing else builds a dev image.
- [ ] Cold build completes without interaction from a clean docker cache;
      rebuild after editing only the final config layer reuses all toolchain
      layers, shown by the build output.
- [ ] `whoami` inside a capsule prints `dev`; `sudo true` succeeds without a
      password; all listed tools are on `$PATH`; `zsh --version` succeeds.
- [ ] `docker history` of the image shows no credential material in any layer.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Container lifecycle — naming, reuse, rebuild detection, mounting and cleanup
  are [`01-container-lifecycle`](../01-container-lifecycle/prd.md).
- Mounting credentials. This image must work with them mounted and must bake
  none of them in.
- A second image for any purpose. One definition is the epic's whole point.

## Open questions
«PRESERVE: ## Open questions»
      (the Odin/pi question and its "drop" recommendation — this is the
      section `decisions/odin-toolchain` writes its answer into)
```

### 23 · `02-terminal/01-appearance` — REWRITE

Current: 0 / 9 / 0; after: 0 / 17 / 0. **R2 and its acceptance are RETIRED**
with evidence (below); R1, R3 and R4 survive as corrected requirements under
their own numbers — their intent is real, only the mechanism named was
invented. The `## Escalation` folds into `## Findings` verbatim: it is the
most valuable text in this node and it is what clears the node for work. The
damaged `## Notes` line is left in place as evidence, per the escalation's own
instruction, and is quoted in the findings.

**RETIRED — `01-appearance-r2` and `01-appearance-b3`.** R2 requires a fixed
horizontal scroll margin of 1.0 lines and a status-bar height of 2.0 lines;
b3 asserts they occupy exactly 3.0 lines on a 21-inch Mac display. Evidence,
quoted from this node's own escalation: *"R2 `scroll-margin` → 'not a valid
Config field. Did you mean one of `scrollback_lines`,
`scroll_to_bottom_on_input`?' · R2 `status-bar-height` → 'not a valid Config
field. Did you mean `status_update_interval`?'"* — from minimal probe configs
run through `wezterm --config-file <probe> ls-fonts --list-system` against
`20240203-110809-5046fc22`. WezTerm has no scroll-margin and no
status-bar-height concept at all, so there is no reduced or corrected version
to carry forward: the refusal is at the field name, not the value. The
acceptance line also conditions on "6dpi", which is not a real display
density.

```markdown
--- .mi/prd/02-terminal/01-appearance/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/decisions/tinty
priority: 80
verify: ""
---

# Terminal Appearance

**Parent:** [Terminal epic](../prd.md) • C4 • U9 • V5

Purpose: The terminal owns the palette that Neovim and television inherit, so
this is the first node in the terminal lane and the thing three other epics
read a colour decision from. Its previous text was written from the legacy
inventory and was refuted field by field against the installed binary; this
states only what wezterm `20240203-110809-5046fc22` accepts, and carries the
reasons for the two non-obvious mechanisms — the `dofile` palette read and the
platform-triple detection — because rediscovering them costs days.

## Requirements
- [ ] **R1** — **Palette source.** The active scheme is read from
      `~/.config/wezterm/colors.lua`, tinty-generated, with `dofile` under
      `pcall`, and that file is registered with
      `add_to_config_reload_watch_list` (`wezterm.lua:417-433`). `dofile` and
      not `require` is load-bearing: `require` caches by module name and would
      return the FIRST palette on a second `tinty apply`
      (`wezterm.lua:432-433`), so the reload appears to work once and then
      silently stops. There is no `/src/colors` — `ls /src` returns "No such
      file or directory" — and no Nix, flake or lockfile anywhere in this
      repo.
R2 — *retired 2026-08-21.* Scroll margin and status-bar height are not
WezTerm concepts; both field names are rejected at config-load time by the
installed binary, so there is no corrected version of this requirement.
Number retained as a gap; do not reuse. Not a box: a retired requirement must
be invisible to the scheduler.
- [ ] **R3** — **Text rendering** is configured through
      `freetype_render_target`. `font-sub-pixel-rendering` is not a valid
      Config field — the binary suggests `font`, `font_size`, `font_shaper` —
      and neither is `italic-weight`.
- [ ] **R4** — **Platform detection** uses `wezterm.target_triple` with
      `triple:find("darwin")` (`wezterm.lua:10-11`). `wezterm.target-os` is
      not a WezTerm surface.
- [ ] **R5** — **Font.** CaskaydiaCove Nerd Font at 14.0pt on macOS and 9.0pt
      elsewhere (`wezterm.lua:510-520`), with `font_dirs` → `~/Library/Fonts`.
      Measured: `fc-list | grep -ic agave` = 0, `fc-list | grep -ic caskaydia`
      = 36. The previous "agave, 18pt" named a font that is not installed.
- [ ] **R6** — **Every configuration key this node names is accepted by the
      installed binary.** A key rejected as an invalid Config field is a
      failed requirement, not a version difference to work around.
- [ ] **R7** — **Nothing downstream hardcodes hex values.** The scheme defined
      here is what Neovim's base16 transparent setup and television's
      `default` ANSI theme inherit. This node is the single statement of
      palette ownership in the terminal children; the epic carries the
      invariant and the other two reference it.
- [ ] **R8** — **Palette entries survive a reload:** the same scheme is in
      effect in a window opened before and a window opened after a
      `tinty apply`, with no restart.
- [ ] **R9** — **The OSC re-tint broadcast is guarded** by
      `wezterm.GLOBAL.tinty_osc` (`wezterm.lua:583-589`), so that every
      font-size edit and padding override does not re-blast every live pane.
- [ ] **R10** — **Padding is zeroed and recomputed every tick by
      `center_grid`** to centre the cell grid (T-4). There is no
      platform-aware padding, and the grid-centering machinery is part of the
      ~230 uncovered lines W0.2 R5 must home.
- [ ] **R11** — Every binding this node defines has its `help` entry in the
      same change, and no entry is transcribed from the pre-respec text: the
      existing `Ctrl+Shift+D` and `Ctrl+Shift+S` entries match nothing live.

## Acceptance
- [ ] `wezterm --config-file home/dot_config/wezterm/wezterm.lua ls-fonts
      --list-system` loads the config with no invalid-Config-field error.
- [ ] `wezterm ls-fonts` reports CaskaydiaCove Nerd Font at 14.0 on macOS.
- [ ] Running `tinty apply` twice with different schemes changes the colours
      both times — the check that fails if `require` is substituted for
      `dofile`.
- [ ] Palette entries are identical across two console sessions opened either
      side of a reload.
- [ ] `grep -rn 'agave\|/src/colors\|font-sub-pixel-rendering\|scroll-margin\|status-bar-height\|target-os' home/dot_config/wezterm`
      returns nothing — the implementation surface names none of the six
      refuted strings. This is the half a grep can decide.
- [ ] Under `.mi/prd/02-terminal` the same six strings appear **only where
      they are named as refuted**: R2's retirement line, R3's and R5's
      counter-facts, and the `## Findings` and `## Notes` sections, which are
      the evidence for the re-spec and must keep every one of them. Checked by
      running the grep over `.mi/prd/02-terminal` and reading each hit; a hit
      inside a requirement or acceptance box that **prescribes** one of them
      is a failure, a hit that **refutes** one is the record. The board-wide
      form of this check cannot be a bare grep returning nothing: the same
      plan that forbids these strings orders the evidence carrying them
      preserved byte for byte — 12 matching lines in this file today — so a
      grep-returns-nothing box would be unsatisfiable by construction and
      would sit `[ ]` forever while reading as rigour.
- [ ] `bash tests/gates/terminal.sh` exits 0.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Tabs, windows and the nine-tab floor —
  [`02-startup-layout`](../02-startup-layout/prd.md).
- Key tables and modal input — [`03-f5-jump-mode`](../03-f5-jump-mode/prd.md).
- launchd PATH seeding: its own requirement says the seeded set is derived
  from the provisioning layer's installed set, and only
  [`05-platform/03-shell-init-generation`](../../05-platform/03-shell-init-generation/prd.md)
  knows that set.
- Whether tinty stays as palette owner — that is
  [`decisions/tinty`](../../00-delivery/decisions/tinty/prd.md), and this node
  reads the answer rather than making it.
- Wallpaper cycling and the opacity toggle: both are excluded on the README
  list (`DO NOT PORT` at line 143, `DEFER` at 165-166), so `Ctrl+Shift+B` is
  free for capsule.
- Scroll margins and status-bar height. WezTerm has no such concept; see the
  retirement of R2.

## Notes
«PRESERVE: ## Notes»
      (the damaged line is left byte-for-byte in place: it is evidence for
      "rewrite from the inventory" over "adjust in place", per the
      escalation's own instruction)

## Findings

### The escalation of 2026-08-21, and its resolution
«PRESERVE: ## Escalation»
      (the entire existing `## Escalation` section moved here verbatim,
      heading demoted to `###`, including "What I hit" items 1–6, "What change
      is needed", "Why no workaround was taken", "Corrections recorded for the
      re-spec" and "Material W0.2 should not have to rediscover")

Resolved 2026-08-21: **the re-spec is applied here, in this file.** The
requirements above are that rewrite, written from `capabilities-terminal.md`
and the deployed `wezterm.lua`. Consequently
[`w0-2-terminal-respec`](../../00-delivery/corrections/w0-2-terminal-respec/prd.md)
re-specs the other five terminal children and explicitly not this one — its R8
and R9, which stated this node's R1 and R4 a second time, are retired as gaps
there — and this node's `deps` edge on W0.2 is cut, because a node may not
wait on the node that would overwrite it with what it already contains.
`decisions/tinty` remains a real gate and stays in `deps`.
`decisions/wallpaper-opacity` is **not** closed: the README refuses the
wallpaper *cycler* and defers the opacity *picker*, which frees
`Ctrl+Shift+B`, but the static `window_background_opacity` value (live: 0.95,
with `macos_window_background_blur = 30`) and the base00 tint are still the
human's. This node carries no opacity requirement until that answer lands;
that is a stated wall, not an omission.
```

### 24 · `03-editor/01-options` — REWRITE

Current: 0 / 16 / 0; after: 0 / 27 / 0. Absorbs `02-keymaps` (11),
`03-autocmds` (8) and `04-plugin-manager` (11) — one directory, one load-order
contract: `mapleader` must be set before any plugin spec is evaluated, because
a spec declaring `keys = { "<leader>x" }` resolves leader at declaration time.
**Requirement numbers from the three absorbed nodes are not carried across**,
because `01-options` already has R1–R12 and reusing those integers would make
28 existing commit citations describe work they did not do. The absorbed
requirements land under a fresh prefixed block (`K1`, `A1`, `A2`, `L1`), each
naming its origin, so a `git log --grep` on the old citation still finds the
text.

```markdown
--- .mi/prd/03-editor/01-options/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
priority: 80
verify: "nvim --headless '+Lazy! sync' +qa exits 0"
---

# Options baseline

Parent: [Neovim epic](../prd.md) · C 2 · U 9 · sources: "Options baseline",
"Core keymaps", "Editor autocmds", "lazy.nvim bootstrap"

Purpose: Everything that must be true before the first plugin spec is
evaluated, plus the manager that evaluates them: `init.lua`, `options.lua`,
`keymaps.lua`, `autocmds.lua`, `lazy.lua`. These were four nodes and they are
one file-set with one contract — the load order is load-bearing, and the four
files are meaningless apart from each other — so splitting them serialised
`lua/config/` for a boundary that does not exist in the code. Every other
editor node depends on this one and none depend on each other.

## Requirements
- [ ] **R1** — **Leader first.** `mapleader` / `maplocalleader` = space, set
      before any plugin spec is evaluated.
- [ ] **R2** — **UI.** `number` + `relativenumber`, `cursorline`,
      `signcolumn=yes`, `termguicolors`, `showmode=false`, `laststatus=3`,
      `pumheight=10`, `fillchars.eob=" "`.
- [ ] **R3** — **Centered editing.** `scrolloff=999`, `sidescrolloff=8`,
      `wrap=false`. The requirement is that the cursor line stays centred; the
      claim "at all times" is an overclaim (M-1) — the first and last
      half-screen are uncentred, measured — and the requirement says so.
- [ ] **R4** — **Splits.** `splitright`, `splitbelow`.
- [ ] **R5** — **Indent.** `expandtab`, `shiftwidth`/`tabstop`/`softtabstop` =
      2, `smartindent`, `breakindent`.
- [ ] **R6** — **Search.** `ignorecase` + `smartcase`, `incsearch`,
      `hlsearch=false`. Because `hlsearch` is false, an `<Esc>` →
      `nohlsearch` map is inert (L-6); the decision is recorded — keep
      `hlsearch = false`, drop the map — with its reason and its rejected
      alternative.
- [ ] **R7** — **Files.** No `swapfile`, no `backup`, `undofile` on.
- [ ] **R8** — **Responsiveness.** `updatetime=250`, `timeoutlen=400`.
- [ ] **R9** — **Integration.** `clipboard=unnamedplus` — the premise of
      [14-shift-select](../14-shift-select/prd.md) — `mouse=a`,
      `completeopt=menu,menuone,noselect`, `virtualedit=block`.
- [ ] **R10** — **Whitespace rendering.** `list` on with `listchars` = `eol
      ↵`, `tab "→ "`, `multispace ·`, `trail ·`, `nbsp ␣`. `multispace` (not
      `space`) is deliberate: dots appear only on runs of 2+ spaces, matching
      VS Code's `renderWhitespace=boundary`.
- [ ] **R11** — **LSP log kill-switch.** `vim.lsp.log.set_level(OFF)`.
      Constraint, not preference: Neovim mirrors every LSP stderr line into
      `~/.local/state/nvim/lsp.log` with no rotation, and a chatty
      rust-analyzer once grew it to 17 GB.
- [ ] **R12** — **Filetypes.** Register `.jd` as markdown, in `init.lua`.
- [ ] **K1** — *from [`02-keymaps`](../02-keymaps/prd.md) R1–R8; numbers not
      reused.* Core maps, none of which references a plugin: window motion
      `<C-h/j/k/l>`, resize `<C-Up/Down/Left/Right>` ±2, splits `<leader>|`
      and `<leader>-`; buffer `<S-h>`/`<S-l>` and `<leader>bd`; line move
      `<A-j>`/`<A-k>` re-selecting and re-indenting with `gv=gv`; stay-centred
      `<C-d>`/`<C-u>` with `zz` and `n`/`N` as `nzzzv`/`Nzzzv`; visual indent
      `<`/`>` keeping the selection; `<leader>w` and `<leader>q`;
      register-safe visual `<leader>p` as `"_dP`.
- [ ] **K2** — Every map carries a `desc`, except the centred-jump and
      visual-indent maps, which deliberately carry none — that exemption class
      is what `06-help`'s drift check needs (M-15) and it is named here.
- [ ] **A1** — *from [`03-autocmds`](../03-autocmds/prd.md) R1–R4; numbers not
      reused.* Highlight on yank at 150 ms via `vim.hl.on_yank` —
      `vim.highlight.on_yank` is deprecated on the live 0.12.4 binary (M-3).
      Restore the last cursor position on `BufReadPost` under `pcall`,
      excluding `gitcommit`. Trim trailing whitespace on `BufWritePre` with
      `keeppatterns %s/\s\+$//e` bracketed by `winsaveview`/`winrestview`.
      Close help, qf, man, lspinfo, checkhealth and startuptime buffers with
      buffer-local `q`, unlisted so they never appear in `:bnext`.
- [ ] **A2** — Every autocmd is registered in its own cleared augroup, so a
      config reload never stacks duplicates. Stated once here and binding on
      the treesitter `FileType` and shift-select `ModeChanged` autocmds as
      well, which are ungrouped live (L-8).
- [ ] **L1** — *from [`04-plugin-manager`](../04-plugin-manager/prd.md) R1–R8;
      numbers not reused.* `init.lua` requires `config.options` →
      `config.keymaps` → `config.autocmds` → `config.lazy`, in that order.
      lazy.nvim bootstraps itself if absent (`--filter=blob:none
      --branch=stable`) and on clone failure echoes the error and exits rather
      than continuing into a broken state. Specs load via
      `{ import = "plugins" }`, one directory per concern under
      `lua/plugins/` — `ui/`, `lsp/`, `nav/`, `edit/` — so a later node adds a
      file rather than editing a shared one; `plugins/editor.lua` appears
      nowhere in the live tree though three PRDs write it (7 hits) and is not
      created. Defaults `lazy=false`, `version=false`, `rocks.hererocks` off,
      with specs opting into lazy-loading individually. `lazy-lock.json` is
      committed. Checker on with `notify=false`; change detection silent.
      `install.colorscheme` is the base16 scheme. gzip, tarPlugin, tohtml,
      tutor, zipPlugin and netrwPlugin disabled.

## Acceptance
- [ ] Open a file mid-document: the cursor line sits centred and stays centred
      while moving.
- [ ] A line with two trailing spaces shows dots; single interior spaces do
      not.
- [ ] Edit, quit, reopen: undo history survives and no swap or backup file
      appears.
- [ ] After an LSP session, `lsp.log` has not grown.
- [ ] `nvim_get_keymap` lists every map in K1 with a `desc`, except the
      exemption class named in K2, and none resolves into a plugin.
- [ ] `<A-k>` on a visual block moves it and leaves it selected and
      re-indented.
- [ ] Yanking flashes the region; reopening a file returns the cursor; a git
      commit opens at line 1; saving strips trailing spaces without moving the
      view; `:help x` then `q` closes it and it never appears in `:bnext`.
- [ ] Sourcing the config twice leaves exactly one autocmd per augroup,
      counted with `nvim_get_autocmds`.
- [ ] `rm -rf ~/.local/share/nvim/lazy` then launching reinstalls everything
      to the lockfile versions unattended; launching with networking off gives
      a clear error and no hang; `:Lazy` shows lazy-loaded plugins as
      not-yet-loaded until their trigger.
- [ ] `nvim --headless '+Lazy! sync' +qa` exits 0.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Any plugin configuration. Plugin specs live in their own nodes under
  `lua/plugins/`.
- Shift-to-select, which is
  [`14-shift-select`](../14-shift-select/prd.md) and gated on a decision.
- Commenting plugins — Neovim 0.10+ provides `gc`, `gcc` and `gc{motion}`.
- Re-mapping what 0.11 provides by default: `grn`, `gra`, `grr`, `gri`, `gO`.
```

### 25 · `04-shell/01-core-config` — REWRITE

Current: 0 / 13 / 0; after: 0 / 23 / 0. Absorbs `02-aliases-utilities` (7 of
its 9 — R4 goes to the shell correction lane as a removal, and its duplicate
`rr` box is retired) and `08-claude-launchers` (5). All three write
`config.nu`, which the parallelization node already names as a contended file
and resolves by serialising Track S: three nodes there means three workers
waiting on one file for about fifteen lines. Absorbed requirements keep origin
prefixes (`A1`, `CC1`) rather than reusing `01-core-config`'s R1–R9.

```markdown
--- .mi/prd/04-shell/01-core-config/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/05-platform/03-shell-init-generation
priority: 80
verify: ""
---

# Core config

Parent: [Nushell epic](../prd.md) · C 3 · U 9 · sources: "Core shell config",
"Aliases and small utilities", "Claude launchers", "Dirstack"

Purpose: The foundation every other feature assumes — a nushell that works as
a login shell on macOS, remembers where you were, and funnels all navigation
through one place — plus the aliases and small launchers that are one line
each in the same file. It carries the OSC constraint that cost real debugging
to find.

## Requirements
- [ ] **R1** — **PATH repair.** Nushell never runs macOS `path_helper`, so
      `env.nu` prepends `~/.local/bin` + `~/.cargo/bin` and appends homebrew +
      system dirs, with `uniq` so it is a no-op when the parent shell provided
      them.
- [ ] **R2** — **Environment.** `EDITOR`/`VISUAL` = nvim, `SHELL` = nu,
      `XDG_CONFIG_HOME`, `RIPGREP_CONFIG_PATH`.
- [ ] **R3** — **Shell behaviour.** No banner, emacs edit mode, `rm` → trash,
      fuzzy case-insensitive completions, binary filesize units.
- [ ] **R4** — **History store.** Sqlite, 100k entries, `isolation: false` so
      all panes share one merged history — the precondition for the
      directory-scoped queries in
      [`04-television`](../04-television/prd.md).
- [ ] **R5** — **Terminal integration.** OSC 133/633 off, OSC 7 on.
      OSC 133 is off because WezTerm already marks prompts and double-marking
      produces phantom blank lines with a two-line starship prompt.
      `use_kitty_protocol` stays off: it leaks `^[[?0u` through the WezTerm
      pty. **This is the single statement of both reasons on the board**; the
      other copies (8 hits measured) become references.
- [ ] **R6** — **`mkcd` funnel.** `cd` aliased to a wrapper that passes `` and
      `-` through, offers to `mkdir` a non-existent target on a single-key
      confirm, and records every successful move to `startdir.txt`. All
      navigation reaches the shell through this funnel or the PWD hook.
- [ ] **R7** — **Start dir.** New interactive shells open in the last
      directory navigated to by any means, falling back to `~/dev`;
      non-interactive `nu -c` keeps its caller's cwd.
- [ ] **R8** — **Dirstack.** The PWD `env_change` hook pushes every move onto
      `dirs.txt` (newest first, deduped, cap 100, dead paths dropped on read).
      It is the single registration on that event; nothing else subscribes.
- [ ] **R9** — **Zero-work startup.** Generated integrations (starship, zoxide
      init, tv init) are produced at chezmoi-apply time and only sourced at
      launch.
- [ ] **A1** — *from [`02-aliases-utilities`](../02-aliases-utilities/prd.md)
      R1–R3, R5, R6; numbers not reused.* Tool aliases `cat`→`bat
      --paging=never`, `grep`→`rg`, `g`→git, `lg`→lazygit, `nv`/`vi`→nvim,
      `nn`→nvim ~/notes.md, `cdi`→`zi` (defined once, in the zoxide node, and
      referenced here). Quit muscle memory `q`, `:q`, `/exit` → exit. Dotfiles
      sync `rr` → `chezmoi update --force`, **stated here and nowhere else**.
      `cf <file>` copies file contents to the system clipboard, picking
      pbcopy/wl-copy/xclip by session type and guarding on display vars so it
      never hangs headless. `pass` completion via an extern signature
      completing subcommands and live entry names without the `.gpg` suffix,
      with undeclared flags passing through.
- [ ] **A2** — No burrito aliases. `bb`/`ba` are not defined: they invoked
      `brr`, not `burrito` (M-7), and burrito was deleted 2026-08-20.
- [ ] **CC1** — *from
      [`08-claude-launchers`](../08-claude-launchers/prd.md) R1–R3; numbers
      not reused.* `cc [...args]` runs Claude with
      `--dangerously-skip-permissions`; `cr [...args]` adds `--resume`. With a
      single profile `cc` launches directly with no picker; the multi-login
      machinery (`_claude_share` seeding, keychain-aware profile detection,
      `.last-login` ordering) activates only once a second profile exists, and
      the picker it offers is a television channel.
- [ ] **U1** — Live behaviour the audit found uncovered is specified here or
      recorded as dropped with a reason: the `ollama-host` probe on every
      interactive start, starship, `$env.ENV_CONVERSIONS`, `esc_clear`, and
      the `cursor_shape` / `table` / `sync_on_enter` / `completions.external`
      blocks.
- [ ] **U2** — `help` is sourced from `config.nu` as one line; the module
      itself is [`06-help/02`](../../06-help/02-help-command/prd.md)'s.
- [ ] **U3** — Every alias, command and binding added here has its `help`
      entry in the same change.

## Acceptance
- [ ] `chsh` to nu + GUI-launched WezTerm: `bat`, `rg`, `tv`, `starship` all
      resolve.
- [ ] `cd some/new/nested/dir` + Enter creates and enters it after confirm.
- [ ] Navigate anywhere by any means, open a new pane: it starts in that dir;
      `nu -c 'pwd'` from another dir prints that dir, not the start dir.
- [ ] Each alias resolves in a fresh shell; `cf` errors cleanly on a missing
      file and copies on a real one; `pass <tab>` lists both verbs and store
      entries without the `.gpg` suffix.
- [ ] `nu -c 'bb'` errors as an unknown command.
- [ ] Fresh machine with one login: `cc` starts Claude immediately with no
      prompt; after a second profile exists, `cc` offers the picker, last-used
      first, and a bare Enter relaunches it.
- [ ] `nu -l -c '$env.config.hooks.env_change.PWD | length'` returns 1.
- [ ] `bash tests/gates/shell.sh` exits 0.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Zoxide, listing and the bare-word fallback —
  [`03-zoxide`](../03-zoxide/prd.md).
- television, history pickers and the quicklist —
  [`04-television`](../04-television/prd.md).
- `bb`/`ba` and anything else that invoked burrito.
- Generating the starship, zoxide or television init files, which happens at
  apply time in
  [`05-platform/03`](../../05-platform/03-shell-init-generation/prd.md).
- `cl <task>` — goal-loop seeding via `cl.py` under a pty — and `jj`, the
  zoxide-resolved journal launcher. Both `DEFER`.
- `zc`, which stays but is specced with the zoxide suite.
```

### 26 · `05-platform/02-package-provisioning/packages-installer` — REWRITE

Current: 0 / 7 / 0; after: 0 / 15 / 0. Absorbs `homebrew-bootstrap` (its R3 is
four lines in the same script directory) and the `02-package-provisioning`
parent's four acceptance boxes, which are this node's own end-to-end
conditions stated one level up. R1, R2, R4–R7 keep their numbers; R3 arrives
from the bootstrap node **keeping its own number**, which is free — this node
has no R3 today and R3 is what that requirement has always been called.

```markdown
--- .mi/prd/05-platform/02-package-provisioning/packages-installer/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/decisions/fzf
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
priority: 80
verify: ""
---

# packages.yaml + run_onchange installer

Parent: [`../prd.md`](../prd.md) · source: [`02-package-provisioning`](../prd.md)
requirements R1, R2, R3, R4, R5, R6, R7

Purpose: Everything the other epics assume is installed, as data, plus the two
scripts that install it. The Homebrew bootstrap is folded in because it is
four lines in the same `.chezmoiscripts/` directory and a separate node for it
would only serialise a worker. It runs behind the repo skeleton because
chezmoi's phase ordering is what makes `run_once_before` precede
`run_onchange`, and ahead of shell-init generation for the same reason.

## Requirements
- [ ] **R1** — **Tools as data.** `.chezmoidata/packages.yaml` holds the
      package set; the installer is a renderer over it and contains no package
      names.
- [ ] **R2** — **Re-run only on change.** The installer embeds `include
      ".chezmoidata/packages.yaml" | sha256sum` in a comment so `run_onchange`
      re-runs it when — and only when — the list changes.
- [ ] **R3** — *from [`homebrew-bootstrap`](../homebrew-bootstrap/prd.md).*
      **Homebrew first.** `run_once_before` installs Homebrew on a fresh macOS
      machine and is a no-op where it is already present; later stages
      re-`eval "$(brew shellenv)"` because the new brew is not yet on PATH in
      the same apply.
- [ ] **R4** — **macOS path is the supported one.** brew for everything
      available there. The Linux ladder (distro package → prebuilt GitHub
      release tarball → cargo) exists for capsule containers; keep it, but
      macOS is what the gates test.
- [ ] **R5** — **Never abort.** A failed package warns and continues
      (`command -v` guards keep it idempotent). A partial machine beats a dead
      apply.
- [ ] **R6** — **Neovim version gate.** ≥ 0.11 is required for native
      `vim.lsp.enable` and blink.cmp; the live machine runs 0.12.x. Distro
      packages ship too-old builds, so on Linux override with the official
      release tarball when nvim is missing or older than the floor. **The
      floor is recorded here and nowhere else**, and
      [`03-editor`](../../../03-editor/prd.md) references it.
- [ ] **R7** — **Required set.** nushell, television, zoxide, starship,
      neovim, git, ripgrep, fd, bat, eza, lazygit, chezmoi, tinty, docker, gh,
      just — plus `fzf` if and only if
      [`decisions/fzf`](../../../00-delivery/decisions/fzf/prd.md) keeps it,
      with no "whether or not it is wanted" hedge either way. `burrito`/`brr`
      are not in the set; burrito was deleted 2026-08-20.
- [ ] **R8** — **Removing a package from the list does not uninstall it.**
      Documented non-behaviour, stated so nobody implements it later as a fix:
      an uninstaller that runs on every apply is a foot-gun with no owner.
- [ ] **R9** — Every generated script and binding introduced here has its
      `help` entry in the same change.

## Acceptance
- [ ] Fresh macOS machine: one apply installs every tool in the required set.
- [ ] Editing `packages.yaml` triggers exactly one installer re-run; touching
      anything else triggers none.
- [ ] Simulating one failed package still completes the apply, with a warning
      naming the package.
- [ ] Removing a package from the list leaves it installed, and the log says
      so.
- [ ] `nvim --version` reports ≥ 0.11 after an apply, or the apply warns
      explicitly that the floor is unmet.
- [ ] `grep -rn 'burrito\|brr' home/.chezmoidata home/.chezmoiscripts` returns
      nothing, and no package name appears in the installer script itself.

## Out of scope
- The sibling node's requirements. This document held two contracts and was
  split; the parent lists which requirement went where.
- Uninstalling anything, ever.
- Non-macOS hosts as a supported target. Linux matters only inside capsule
  containers.
- Generating shell init files — that is the `run_after` phase and
  [`03-shell-init-generation`](../../03-shell-init-generation/prd.md) owns it.
- Deciding fzf.
```

### 27 · `01-capsule/01-container-lifecycle` — REWRITE

Current: 0 / 11 / 0; after: 0 / 19 / 0. Absorbs `03-credential-propagation`
(8) and `04-recent-workspaces` (6). All three describe decisions made at mount
time by one executable in one file: credential propagation is which flags the
mount command passes, and recency is one append per successful mount. The
picker's two **keybindings** are the exception and go to
`02-terminal/02-startup-layout`, which owns the key map; this node provides
the subcommands they invoke. Absorbed requirements keep origin prefixes (`C1`,
`W1`) rather than reusing R1–R7.

```markdown
--- .mi/prd/01-capsule/01-container-lifecycle/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/01-capsule/02-dev-image
priority: 80
verify: ""
---

# Container lifecycle (consolidates capsule + `mount` + justfile)

Parent: [Capsule epic](../prd.md) · C 9 · U 9 · sources: "Capsule"
(CONSOLIDATE, C9 U9 — dominant), "Credential propagation", "Recent-workspace
picker"

Purpose: One CLI entry point, `capsule [dir]`, that mounts a directory into a
per-directory dev container and attaches an interactive shell. The terminal
keybinding and any task-runner recipe are thin wrappers over this one command —
no parallel implementations. Lifecycle, credentials and recency are one node
because they are one executable and one file; every one of them is a decision
made at mount time.

## Requirements
- [ ] **R1** — **Naming.** Container name derived from the directory
      (`capsule-<dirname>`), stable across invocations, with collision
      handling for same-named dirs in different parents (short path hash
      suffix).
- [ ] **R2** — **Reuse.** If the container is running, exec into it — target
      well under one second, dominated by `docker exec` and not by the tool.
      If it exists but is stopped, start and attach.
- [ ] **R3** — **Rebuild detection.** Rebuild the image automatically when the
      image definition changed (content hash of the Dockerfile/context);
      otherwise never rebuild implicitly.
- [ ] **R4** — **Forced rebuild.** `capsule --rebuild`, bound to
      `Ctrl+Shift+B` in the terminal. That key is free: wallpaper cycling is
      `DO NOT PORT` and the opacity picker is `DEFER` on the README exclusion
      list, settled 2026-08-21.
- [ ] **R5** — **Mounting.** The target directory is mounted at `/workspace`
      and is the shell's initial cwd; edits inside are edits outside.
- [ ] **R6** — **Cleanup.** A subcommand lists capsules and removes
      stopped/all ones, absorbing the old `dk` force-remove alias for capsule
      containers.
- [ ] **R7** — **Recency hook.** Every successful mount records the directory
      for the recents picker.
- [ ] **C1** — *from
      [`03-credential-propagation`](../03-credential-propagation/prd.md)
      R1–R5; numbers not reused.* `~/.ssh` mounted read-only, with first-run
      setup copying keys to a container-local directory at 600/700 and
      pre-adding GitHub host keys to `known_hosts` — a read-only mount cannot
      satisfy ssh's permission check directly. `.gitconfig` mounted read-only
      so author, committer and aliases match the host. `git credential fill`
      output refreshed from the host keychain into `.cache/git-credentials` on
      every mount and wired as the container's credential store, so a rotated
      token heals on the next mount rather than requiring a rebuild. Claude
      Code and OpenCode auth/config directories mounted so the preinstalled
      agents work with no login flow. No secret is baked into an image layer;
      everything arrives by mount or by a mount-time write, never by `COPY` or
      `ARG`.
- [ ] **W1** — *from
      [`04-recent-workspaces`](../04-recent-workspaces/prd.md) R1, R4;
      numbers not reused.* Every successful mount appends the directory to a
      recency list (`.cache/recent`), deduplicated, capped at 20, newest
      first, written by this tool and not by the terminal layer. `capsule
      recent` prints it. Directories that no longer exist are skipped or
      pruned on read, and the list survives terminal restarts.
- [ ] **X1** — **This tool is the only caller of docker for this purpose.**
      The legacy `mount` function, the standalone justfile and the second
      image path are gone, and the legacy mount's behaviour is not the
      specification because it never worked (C-3).
- [ ] **X2** — Every command and flag added here has its `help` entry in the
      same change.

## Acceptance
- [ ] `capsule` in a fresh directory builds the image if needed, creates the
      container, and lands in zsh at `/workspace` with the directory contents
      visible.
- [ ] A second `capsule` in the same directory attaches to the running
      container with no rebuild and no recreate; `docker inspect` shows the
      same container id.
- [ ] Editing the Dockerfile then running `capsule` triggers exactly one
      rebuild; running it again triggers none.
- [ ] The WezTerm binding and the CLI produce identical containers, verified
      by a `docker inspect` diff.
- [ ] Inside a fresh capsule for a private repo: `git pull`, `git push` (SSH
      and HTTPS remotes) and `ssh -T git@github.com` succeed with no prompt;
      `claude` and `opencode` start authenticated.
- [ ] `docker history` shows no credential material, and `~/.ssh` inside the
      container is not writable back to the host copy.
- [ ] Mounting three directories then running `capsule recent` lists all three
      newest-first, and a deleted directory does not appear on the next read.
- [ ] `bash tests/gates/platform.sh` exits 0.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- The image contents — [`02-dev-image`](../02-dev-image/prd.md) owns the
  Dockerfile and this node never defines a second image.
- The keys themselves. This node provides subcommands;
  [`02-terminal/02-startup-layout`](../../02-terminal/02-startup-layout/prd.md)
  owns the bindings that invoke them, and the "Recent:" status indicator has
  no host today (C-5).
- Preserving anything the legacy `mount` did.
- Any picker UI of its own — `capsule recent` prints rows and television
  renders them.
```

### 28 · `06-help/02-help-command` — REWRITE

Current: 0 / 15 / 0; after: 0 / 26 / 0. Absorbs `03-browser` (8) and
`05-agent-interface` (13): four renderers over one schema, in one directory,
is the epic's own I1, and three nodes there means three workers re-deriving
the same resolution order and the same non-TTY rule. Absorbed requirements
keep origin prefixes (`B1`–`B3`, `AG1`–`AG3`). The `## The delegation contract
(read first)` section is preserved whole — it is the reason this command is
dangerous to get wrong.

```markdown
--- .mi/prd/06-help/02-help-command/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/06-help/01-content-model
priority: 80
verify: ""
---

# The `help` command

Parent: [Help epic](../prd.md) · C 5 · U 9 · net-new

Purpose: `help` renders the manual. It is a nushell custom command that
deliberately overrides the builtin — a documented extension point — and
therefore carries the builtin's duties as well as its own. One content source,
four renderers: the human tables, the fuzzy browser, the JSON document and the
markdown export. They are one node because that is the epic's own invariant.
It is scheduled early rather than late: the board's rule that every node
adding a binding writes its help entry in the same change is only enforceable
once there is something to write into.

## Requirements
- [ ] **R1** — **`help`** — the overview: the topic list, each with a one-line
      summary and entry count, the handful of keys worth knowing first
      (`Ctrl-Space`, `F5`, `Ctrl-R`, `<leader>ff`), and the ways to go deeper.
- [ ] **R2** — **`help <topic>`** — a nushell table of that topic's entries:
      key/cmd, title, use. Structured output, so `help find | where key =~
      'ctrl'` composes like any other nu pipeline.
- [ ] **R3** — **`help <query>`** — case-insensitive substring/fuzzy match
      across `key`, `cmd`, `title` and `use`, grouped by topic.
- [ ] **R4** — **`help <entry>`** — full detail for one entry: title, use,
      why, related (`also`), and the source field **as the content model's
      schema defines it**. The undefined "source PRD" reference is M-14; the
      schema defines `source` and this requirement names that field.
- [ ] **R5** — **`help --all`** — the entire manual, all topics, in reading
      order.
- [ ] **R6** — **`--mode <m>`** — filter to `shell` / `nvim` / `terminal` /
      `container`.
- [ ] **R7** — **Non-TTY behaviour.** Plain text, no colours, no pager, no TUI
      when stdout is not a terminal. This governs `--json` and `--md` too.
- [ ] **R8** — **Speed.** Rendering reads the content files and nothing else —
      never spawning nvim, wezterm or git. That machinery belongs to
      [`04-drift-check`](../04-drift-check/prd.md).
- [ ] **R9** — **Container parity.** `help` works inside a capsule; the
      content files ship or mount with it, and host-only entries are marked
      rather than hidden.
- [ ] **R10** — **Resolution order is stated once and every renderer obeys
      it**, including the builtin collision: `help ls` reaches nushell's
      builtin help for `ls` while `help listing` reaches ours, and the
      acceptance and the stated order agree rather than contradicting each
      other (M-13).
- [ ] **B1** — *from [`03-browser`](../03-browser/prd.md) R1–R2; numbers not
      reused.* `help --rows` emits one row per entry — topic, key/cmd, title —
      **in a format defined here, because no other PRD defines one**: the
      claim that it mirrors `04-shell/07-quicklist` is M-16, and that node
      specifies nuon and says nothing about channel row format. `help
      --preview <entry>` emits that entry's title, use, why and related.
      [`04-shell/04-television`](../../04-shell/04-television/prd.md)
      registers the channel that consumes them.
- [ ] **B2** — *from [`03-browser`](../03-browser/prd.md) R3–R4.*
      `help --fuzzy` opens that channel, and the `help` channel appears in the
      `Ctrl-Space` remote like any other. `enter` prints the entry's detail
      into the scrollback so it survives tv exiting; `ctrl-o` opens the
      entry's `source` in `$EDITOR`.
- [ ] **B3** — *from [`03-browser`](../03-browser/prd.md) R5.* tv requires a
      TTY, so `--fuzzy` guards and degrades to `help <query>` output rather
      than panicking when there is not one.
- [ ] **AG1** — *from
      [`05-agent-interface`](../05-agent-interface/prd.md) R1–R3; numbers not
      reused.* `help --json` emits the whole manual as one JSON document with
      stable field names — this is an interface, so renaming a field is a
      breaking change. `help --md` emits it as markdown grouped by topic.
      Both are plain under capture by R7, so an agent that just runs `help`
      gets something usable without knowing about a flag.
- [ ] **AG2** — *from [`05-agent-interface`](../05-agent-interface/prd.md)
      R4–R6.* Discovery, idioms and boundaries: entries name the tool actually
      installed — television (`tv`), `rg`, `fd`, not fzf, grep, find — so an
      agent stops reaching for what is not here; the manual carries the "do it
      this way here" rules (nushell pipelines return structured data, so
      `| where` not `| grep`; `cd` in this shell can create directories); the
      `agents` topic documents `cc`/`cr`, how capsules get credentials, and
      `help --json` itself; and every entry marks host-only versus
      container-available.
- [ ] **AG3** — Renaming a JSON field requires updating this node's field
      list in the same change, so the contract cannot drift silently. The
      field list lives here and in exactly one place.

## Acceptance
- [ ] `ls --help` and `git --help` behave exactly as before this command
      existed.
- [ ] `help` with no args prints the overview in under ~100 ms.
- [ ] `help navigate` lists the zoxide suite including the bare-word fallback;
      `help ctrl-r` explains the directory-scoped picker and mentions `Alt-R`.
- [ ] `help ls` reaches nushell's builtin help for `ls`, and `help listing`
      reaches ours — matching the stated resolution order.
- [ ] `help find | to json` produces valid JSON; `nu -c 'help' | complete`
      returns plain unstyled text.
- [ ] `help --fuzzy`, typing "select", shows the shift-select entries with a
      preview explaining collapse-on-motion; `enter` leaves the detail in the
      scrollback after tv exits; piping it in a non-interactive context falls
      back to plain search output instead of panicking.
- [ ] `help --json | jq '.topics | length'` works and a diff of entry keys
      between `help --all` and `help --json` is empty.
- [ ] `help --md > manual.md` produces a document readable top to bottom.
- [ ] A fresh agent session given only the output of `help` can navigate, find
      a file and start a capsule, without inventing a tool that is not
      installed.
- [ ] `bash tests/gates/help.sh` exits 0.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Content. Descriptions live only in
  `home/dot_config/nushell/help/*.nuon`; renderers contain layout only.
- Drift checking, which is [`04-drift-check`](../04-drift-check/prd.md) and is
  the only thing allowed to spawn nvim and wezterm.
- Registering the tv cable channel, which is a file
  [`04-shell/04-television`](../../04-shell/04-television/prd.md) owns; this
  node provides the two interfaces it calls.
- Shadowing anything that is not ours — an unknown query is delegated to the
  tool that owns it.
- **Owning `home/dot_config/nushell/help/*.nuon`.** Nobody owns it, and that
  is an unresolved contradiction rather than an oversight — see the stated
  wall below. This node owns the renderers, the loader and the resolution
  order; the content files are written by whichever node adds the binding.
- `AGENTS.md`'s own wording. It already states that `help` is the manual and
  must be consulted before suggesting a shell or editor workflow (`CLAUDE.md`
  lines 87 and 92), so that half of the old agent-interface acceptance is met
  by a file this node does not write.

## Stated wall: the help content surface has no single writer

This is written down rather than papered over, because it is a contradiction
between two rules the board already holds and neither of them is this plan's
to overturn.

- The board root's **I3** (and `00-delivery` **I4**) require that *every* node
  adding a binding, command or alias writes its own `help` entry **in the same
  change**. At priority 80 alone that is `02-terminal/01-appearance` (its R11
  says so explicitly), `03-editor/01-options`, `04-shell/01-core-config`,
  `01-capsule/01-container-lifecycle`, `packages-installer` and this node —
  six nodes writing into one directory in one tier.
- [`06-help/01-content-model`](../01-content-model/prd.md) **R1** is `[x]` and
  fixes the surface at exactly five shared files —
  `shell.nuon`, `nvim.nuon`, `terminal.nuon`, `capsule.nuon`, `topics.nuon` —
  so those six nodes are six writers of the same five files.
- `repo-skeleton` additionally asserts `git status --porcelain
  home/dot_config/nushell/help` is empty after an apply, which a concurrent
  writer breaks.

So the plan's claim "within a tier the footprints are disjoint, so the tier is
the width" **is not true of any implementation tier**, and this document says
so rather than asserting the opposite. Two resolutions exist and both cost
something this plan may not spend:

1. **A per-node entry directory** — `home/dot_config/nushell/help/entries/<node
   id>.nuon`, concatenated by the loader — makes each node write one file it
   alone owns. It contradicts `06-help/01-content-model` R1, which is a
   **closed** box, and reopening a closed box is not a restructure's call.
2. **One writer, entries filed as requests** — every other node records its
   entry text in its own PRD and this node lands them. That makes
   `06-help/02-help-command` a serialising bottleneck behind every
   implementation tier, and it inverts I3, which exists precisely so
   documentation is not a later phase.

**Unresolved.** Whoever answers it should answer it as a decision node with
both alternatives recorded, not inside an implementation lane.

## The delegation contract (read first)
«PRESERVE: ## The delegation contract (read first)»
```

### 29 · `02-terminal/02-startup-layout` — REWRITE

Current: 0 / 5 / 0; after: 0 / 17 / 0. Absorbs `05-tab-content-state` (12):
the tab floor and the tab colouring are the same code in the same file — what
creates a tab decides its initial classification, and the stale-state sweep
runs on the same status tick that redraws the bar. It also gains the two
capsule bindings, because this node owns the key map. Prefixes `S1`–`S7` for
the absorbed requirements; `02-startup-layout`'s R1–R3 keep their numbers.

```markdown
--- .mi/prd/02-terminal/02-startup-layout/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-2-terminal-respec
  - .mi/prd/02-terminal/01-appearance
priority: 70
verify: ""
---

# Startup layout — nine-tab maximized windows

Parent: [Terminal epic](../prd.md) · C 3 · U 7 · sources: "Nine-tab maximized
window", "Tab content-state coloring"

Purpose: The window and tab model and the tab bar are one file and one
contract: what creates tabs at startup, what re-creates one that dies, and
what colour each tab is given depending on whether anything is running in it.
Splitting the floor from its colouring would put two workers in `wezterm.lua`
at once for no gain. It reads the palette from
[`01-appearance`](../01-appearance/prd.md) and is what
[`03-f5-jump-mode`](../03-f5-jump-mode/prd.md) addresses.

## Requirements
- [ ] **R1** — **Startup.** `gui-startup` creates one maximized window with
      nine tabs, focus on tab 1. `gui-attached` does not exist in the live
      config and is not used (T-5); startup calls `toggle_fullscreen()`, not
      `maximize()`, and the requirement says which.
- [ ] **R2** — **More windows.** A new-window shortcut spawns another
      identically shaped window. `Cmd+N` is not it — no such binding exists
      (T-7); new windows get nine tabs from a reconciler on
      `window-config-reloaded`, and the binding is whatever
      `capabilities-terminal.md` records.
- [ ] **R3** — **Teardown.** `Ctrl+Shift+Q` closes every tab of the current
      window at once. It passes `confirm = false` explicitly and must
      `mark_closing()` first to defeat the tab-refill floor (T-6).
- [ ] **S1** — **Self-healing floor.** If a tab is closed while fewer than
      nine exist, one is re-created — per-window slot maps, `MoveTab`
      re-positioning, a re-entrancy guard and a 5 s heal tick. The bound that
      stops it recursing is stated.
- [ ] **S2** — *from
      [`05-tab-content-state`](../05-tab-content-state/prd.md) R1, R2;
      numbers not reused.* Spawn-time classification: a tab or pane is
      classified empty-or-occupied the moment it is created — a pane whose
      shell has not emitted a prompt is `empty`, one that has emitted a first
      prompt or received input is `occupied`, and a tab is the OR of its
      panes. Reclassify on pane creation, pane exit, first prompt emission,
      and any keystroke; a tab whose last empty pane runs a command flips
      before the command finishes.
- [ ] **S3** — *from
      [`05-tab-content-state`](../05-tab-content-state/prd.md) R3.* Two
      tab-bar colours derived from the active scheme, never hardcoded hex:
      `empty` reuses the inactive-tab colour already used for background tabs;
      `occupied` takes a distinct tint from the scheme's selection/active
      colour, legible against the bar without outshining the focused tab.
      Focused/inactive stays a separate signal from occupied/empty.
- [ ] **S4** — *from
      [`05-tab-content-state`](../05-tab-content-state/prd.md) R4.* No
      shell-side dependency. Classification must not require the shell to
      cooperate, because the same config runs with any `$SHELL` and the shell
      is replaced independently of the terminal. Detect prompt emission via
      the terminal stream, not a shell hook.
- [ ] **S5** — *from
      [`05-tab-content-state`](../05-tab-content-state/prd.md) R5.*
      Stale-state safety: a pane that dies without WezTerm learning about it
      returns its tab to `empty` within one `status_update_interval`. The
      periodic `update-status` tick reclassifies every tab against the live
      pane set.
- [ ] **S6** — **The capsule bindings are declared here**, because this node
      owns the key map: the recent-workspace picker key and the
      mount-in-new-tab key each invoke a `capsule` subcommand
      ([`01-capsule/01`](../../01-capsule/01-container-lifecycle/prd.md) W1),
      and `capsule --rebuild` gets `Ctrl+Shift+B`, which is free.
      `Ctrl+Shift+T` is WezTerm's own `SpawnTab` default and is overridden
      explicitly or left alone — claiming it silently is what made the help
      entry for it resolve for the wrong reason.
- [ ] **S7** — Every binding this node defines has its `help` entry in the
      same change, and the entry says which key is ours and which is a WezTerm
      default we rely on.

## Acceptance
- [ ] Launching WezTerm yields one maximized window with tabs numbered 1–9,
      focus on tab 1, all nine rendering in the `empty` colour.
- [ ] Closing a tab restores the floor to nine without recursing, shown by the
      tab count settling.
- [ ] The new-window shortcut reproduces the same shape; the quit shortcut
      closes all nine.
- [ ] Pressing Enter in tab 3 flips it to `occupied` before the prompt redraw
      completes; splitting a tab and running a command in the new pane flips
      the tab even though the sibling pane is still empty.
- [ ] Killing a pane's process from outside WezTerm (`kill -9` on the shell
      PID) returns its tab to `empty` within one `status_update_interval`.
- [ ] `tinty apply` with a different scheme recolours both states with no edit
      to this feature's code.
- [ ] `wezterm show-keys --lua` lists the new-window, quit-all and capsule
      bindings with no duplicate key, and every default we rely on is listed.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Palette definition — [`01-appearance`](../01-appearance/prd.md) owns it and
  this node reads it.
- Jump mode and copy mode key tables —
  [`03-f5-jump-mode`](../03-f5-jump-mode/prd.md).
- The capsule CLI itself; this node binds keys to subcommands that
  [`01-capsule/01`](../../01-capsule/01-container-lifecycle/prd.md) provides.
- Any classification that asks the shell to emit a marker.
```

### 30 · `02-terminal/03-f5-jump-mode` — REWRITE

Current: 0 / 7 / 0; after: 0 / 16 / 0. Absorbs `04-copy-mode` (11). Both are
one-shot key tables in the same region of the same file, governed by the same
constraint about modals and tab switches. The copy-mode text as written
describes a program that has never existed here — F3, a hand-built screen
freeze, a bright-cyan cursor — against a live mechanism of `Ctrl+Shift+X` plus
a single-key toggle and an OSC user-var (T-10); the intent survives against
the live mechanism, the invented design does not. **R4 is inverted**, because
it contradicts T-9 directly.

```markdown
--- .mi/prd/02-terminal/03-f5-jump-mode/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-2-terminal-respec
  - .mi/prd/02-terminal/02-startup-layout
priority: 65
verify: ""
---

# F5 one-shot jump mode

Parent: [Terminal epic](../prd.md) · C 6 · U 8 · sources: "F5 one-shot jump
mode", "Copy mode"

Purpose: Both of the terminal's modes are one-shot key tables in the same
region of the same file, and both are governed by the same hard-won constraint
about modals and tab switches. Keeping them as two nodes would put two workers
in `wezterm.lua` for a boundary that does not exist in the code. This node
comes last in the terminal lane because a jump target is a tab or a pane, and
the tab model is defined by the node before it.

## Requirements
- [ ] **R1** — **Key table.** A `one_shot = true` key table bound to `F5`;
      digits `1–9` map to tabs and letters `asdfghjkl` map to panes by
      indexing `tab:panes()` in **split-creation order, not geometry** (T-8).
      `b` is bound live but maps to nothing and rings the bell; the rewritten
      letter set is what the inventory records.
- [ ] **R2** — **Auto-pop.** Any key (mapped or not) exits the table; `Esc`
      cancels. After a jump the next keystroke types into the pane normally.
- [ ] **R3** — **Constraint.** Do **not** use `PaneSelect`: a Lua-opened
      modal cannot be dismissed across a tab switch, so a jump that changes
      tabs leaves an overlay nothing can close. That is a documented failure
      and the reason is the expensive part.
- [ ] **R4** — **Discoverability is a reverse-video letter painted into each
      pane, not a status-bar hint.** The "JUMP" hint was deliberately removed
      as noise (T-9); the previous text asking for one contradicted the
      backlog. Right status is clock-only.
- [ ] **R5** — **A miss gives visible feedback.** The live miss path rings
      BEL, but `audible_bell = "Disabled"` and no visual bell is set, so a
      mistyped jump letter produces nothing at all (L-11). This node names the
      feedback that replaces it.
- [ ] **C1** — *from [`04-copy-mode`](../04-copy-mode/prd.md) R1, R5; numbers
      not reused.* Copy mode is entered by the live binding the inventory
      records — `Ctrl+Shift+X` plus a single-key toggle — and uses WezTerm's
      own copy-mode key table plus the OSC user-var mechanism the live config
      uses. It is not a hand-built screen freeze on `F3`. Exiting restores
      normal terminal behaviour: input and output resume, the cursor returns
      to its normal shape, and the scrollback position is unchanged.
- [ ] **C2** — *from [`04-copy-mode`](../04-copy-mode/prd.md) R2–R3.* The
      copy-mode cursor is visually distinct from the normal cursor, with its
      colour taken from the active scheme rather than a literal. Navigation
      uses the standard motions the copy-mode table provides.
- [ ] **C3** — *from [`04-copy-mode`](../04-copy-mode/prd.md) R4.* Selection
      is copied to the system clipboard by the table's own binding, alongside
      the live `Ctrl+V` bracketed paste and `Ctrl+C` copy-or-SIGINT bindings
      (T-10).
- [ ] **C4** — Both modes behave identically at any terminal size, including
      after a resize while active; nothing depends on a fixed row or column
      count.
- [ ] **C5** — Mouse bindings are covered here or recorded as dropped:
      `StartWindowDrag` is the only window handle under `RESIZE` (T-10).
- [ ] **C6** — Every key and table this node defines has its `help` entry in
      the same change.

## Acceptance
- [ ] `wezterm show-keys --lua --key-table` lists the F5 table with the
      recorded letter set in the recorded order, and lists no `PaneSelect`
      action anywhere.
- [ ] `F5 3` lands on tab 3; `F5 <letter>` lands on the corresponding pane;
      the next keystroke reaches the pane rather than the table.
- [ ] `F5` then a tab digit while a multi-pane tab is open never leaves a
      stuck modal.
- [ ] A jump letter that matches nothing produces the specified feedback,
      recorded in `tests/gates/manual.md` rather than assumed.
- [ ] Entering copy mode, moving, copying and exiting leaves the clipboard
      holding the selection and the terminal in its normal state, across two
      terminal sizes.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- The tab and window model — [`02-startup-layout`](../02-startup-layout/prd.md).
- `PaneSelect`, in any form.
- A status-bar `JUMP` hint.
- Re-implementing copy mode in Lua when WezTerm provides the table.
```

### 31 · `03-editor/09-lsp` — REWRITE

Current: 0 / 9 / 0; after: 0 / 23 / 0. Absorbs `05-completion` (12),
`07-formatting` (8) and `10-treesitter` (7). One wiring problem, not four:
blink.cmp exports the capabilities table LSP consumes — completion R9 and LSP
R3 are the two halves of one handoff — conform falls back to the LSP
formatter, and treesitter supplies the indentexpr formatting leaves alone.
Four nodes in `lua/plugins/lsp/` negotiating one capabilities export is a
false boundary that also serialises the directory. Prefixes `C1`–`C4`,
`F1`–`F3`, `T1`–`T3`.

```markdown
--- .mi/prd/03-editor/09-lsp/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/03-editor/01-options
priority: 70
verify: ""
---

# LSP (mason + native 0.11)

Parent: [Neovim epic](../prd.md) · C 6 · U 9 · sources: "LSP (mason + native
0.11)", "Completion (blink.cmp)", "Format on save", "Treesitter"

Purpose: The four plugins that make the editor understand what you are
editing. They are one node because they are one wiring problem: language
servers install and enable themselves, completion exports the capabilities
every server is configured with, formatting falls back to the language server,
and treesitter supplies the indentexpr the formatter leaves alone.

## Requirements
- [ ] **R1** — **Plugins.** `neovim/nvim-lspconfig` for its bundled
      per-server `lsp/*.lua` defaults, lazy on `BufReadPre`/`BufNewFile`, with
      `mason-org/mason.nvim` (v2), `mason-org/mason-lspconfig.nvim` and
      `saghen/blink.cmp` as dependencies.
- [ ] **R2** — **Install + enable.** `mason-lspconfig.setup({ ensure_installed
      = … })` with lua_ls, bashls, pyright, rust_analyzer, tailwindcss — auto
      installed and auto enabled via `vim.lsp.enable()`.
- [ ] **R3** — **Capabilities.** `vim.lsp.config("*", { capabilities =
      require("blink.cmp").get_lsp_capabilities() })` — applied to every
      server in one place, so a new server inherits them without a per-server
      edit.
- [ ] **R4** — **Per-server settings** through `vim.lsp.config(<name>, …)`,
      merged over nvim-lspconfig's bundled config. lua_ls: `vim` as a known
      global, `checkThirdParty = false`, telemetry off. The other four run on
      defaults.
- [ ] **R5** — **Don't re-map what core provides.** 0.11 ships `grn`, `gra`,
      `grr`, `gri`, `gO`, `K`, `]d`/`[d`. Add only the familiar aliases,
      buffer-local on `LspAttach`: `gd`, `gI`, `<leader>rn`, `<leader>ca`.
- [ ] **R6** — **Diagnostics.** Virtual text with a `●` prefix,
      `severity_sort` on, float with a rounded border showing the source.
- [ ] **C1** — *from [`05-completion`](../05-completion/prd.md) R1–R2;
      numbers not reused.* `saghen/blink.cmp`, lazy on `InsertEnter`, version
      pinned to `1.*` — the tag ships the prebuilt Rust fuzzy library, so no
      local Rust toolchain is needed — with `rafamadriz/friendly-snippets` as
      a dependency. Note M-4: it is also a dependency of nvim-lspconfig
      (`BufReadPre`), so it loads at first buffer read regardless.
- [ ] **C2** — *from [`05-completion`](../05-completion/prd.md) R3–R4.* The
      `super-tab` preset plus `<CR>` = accept-or-fallback and `<Esc>` =
      cancel-or-fallback; the fallbacks are load-bearing, because with no menu
      open both keys must behave normally. Sources `lsp`, `snippets`, `path`,
      `buffer`, declared with `opts_extend` on `sources.default` so a later
      spec can add rather than replace.
- [ ] **C3** — *from [`05-completion`](../05-completion/prd.md) R5–R8.* Docs
      auto-show after 200 ms; signature help enabled; `nerd_font_variant =
      "mono"`; fuzzy `prefer_rust_with_warning` — use the Rust matcher, warn
      rather than fail if unavailable.
- [ ] **C4** — *from [`05-completion`](../05-completion/prd.md) R9.*
      Completion exports `blink.cmp.get_lsp_capabilities()`, which is what R3
      consumes. No nvim-cmp, LuaSnip or `cmp-*` plugin exists anywhere.
- [ ] **F1** — *from [`07-formatting`](../07-formatting/prd.md) R1–R2;
      numbers not reused.* `stevearc/conform.nvim`, lazy on `BufWritePre` +
      `ConformInfo`, with lua→stylua, rust→rustfmt, python→black,
      markdown/markdown.mdx→prettier.
- [ ] **F2** — *from [`07-formatting`](../07-formatting/prd.md) R3.* Markdown
      intent: prettier aligns table pipes and normalises lists, and prose
      stays unwrapped (`proseWrap: preserve`) — these PRD files are
      hand-wrapped and reflowing them would churn diffs.
- [ ] **F3** — *from [`07-formatting`](../07-formatting/prd.md) R4–R5.*
      `format_on_save` at a 500 ms timeout with `lsp_format = "fallback"`, so
      a filetype without a listed formatter is still formatted by its language
      server; `<leader>cf` formats asynchronously with the same fallback.
- [ ] **T1** — *from [`10-treesitter`](../10-treesitter/prd.md) R1–R2;
      numbers not reused.* `nvim-treesitter/nvim-treesitter`, `branch =
      "main"`, `build = ":TSUpdate"`, lazy on `BufReadPost`/`BufNewFile`, with
      an explicit parser list: odin, bash, c, lua, luadoc, markdown,
      markdown_inline, nu, python, query, rust, toml, vim, vimdoc, yaml, json.
- [ ] **T2** — *from [`10-treesitter`](../10-treesitter/prd.md) R3–R4.*
      Attach on `FileType` via `vim.treesitter.start` under `pcall` — a
      missing parser must not error — set `indentexpr =
      "v:lua.require'nvim-treesitter'.indentexpr()"`, and also iterate
      `nvim_list_bufs()` at config time, because the plugin lazy-loads on a
      buffer event and the `FileType` event has already fired for the
      triggering buffer.
- [ ] **T3** — The treesitter `FileType` autocmd lives in its own cleared
      augroup (L-8), per
      [`01-options`](../01-options/prd.md) A2. It is ungrouped live, so a
      reload stacks duplicates.
- [ ] **X1** — Each plugin lives in its own file under `lua/plugins/lsp/`, and
      each plugin-specific keymap lives in its spec's `keys` so it
      lazy-loads. Every map added here has its `help` entry in the same
      change.

## Acceptance
- [ ] Open a Lua file: lua_ls attaches, `vim` is not flagged undefined, and
      completion offers Neovim API members; `gd` jumps to a definition and `K`
      shows hover with no local mapping for either.
- [ ] A fresh machine installs all five servers unattended on the first
      relevant buffer.
- [ ] `<Tab>` accepts a completion and jumps through snippet placeholders;
      `<CR>` on an empty line with no menu inserts a newline; `<Esc>` with no
      menu leaves insert mode; no nvim-cmp, LuaSnip or `cmp-*` plugin appears
      in `:Lazy`.
- [ ] Saving a `.lua` file applies stylua within the timeout; saving markdown
      with a ragged table aligns the pipes and leaves paragraph breaks alone;
      saving a filetype with no configured formatter but an active LSP is
      formatted by the LSP.
- [ ] `nvim x.nu` from the command line is highlighted immediately, not after
      a buffer switch; a filetype with no installed parser opens without
      error; `=` re-indents a Lua block using the treesitter indentexpr.
- [ ] Sourcing the config twice leaves the treesitter augroup with one
      autocmd, not two.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- telescope, oil, gitsigns, which-key, autopairs and table mode —
  [`08-telescope`](../08-telescope/prd.md) and
  [`14-shift-select`](../14-shift-select/prd.md).
- Re-mapping the 0.11 default LSP keys.
- nvim-cmp and LuaSnip. One plugin per concern.
- Colours and the statusline, which read the palette and belong to
  [`11-colorscheme`](../11-colorscheme/prd.md).
```

### 32 · `03-editor/08-telescope` — REWRITE

Current: 0 / 8 / 0; after: 0 / 17 / 0. Absorbs `06-explorer` (6),
`12-small-plugins` (6) and `15-markdown-tables` (6): four small specs with no
wiring between them, sharing `lua/plugins/nav/`, so any split serialises
workers for a boundary that buys nothing. It also lands the L-7 and L-10
fixes. Prefixes `E1`, `G1`–`G3`, `M1`.

```markdown
--- .mi/prd/03-editor/08-telescope/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/03-editor/01-options
priority: 65
verify: ""
---

# Fuzzy finder (telescope)

Parent: [Neovim epic](../prd.md) · C 5 · U 9 · sources: "Fuzzy finder
(telescope)", "File explorer (oil.nvim)", "Git signs", "which-key",
"autopairs", "Markdown table mode"

Purpose: How you find things, see what changed, and discover what a key does.
Six small plugin specs with no wiring between them and none between them and
anything else. They share one directory, so any split serialises workers for a
boundary that buys nothing; together they are one node's worth of work.
Telescope is the editor's finder and is deliberately not unified with
television, which owns the shell's pickers.

## Requirements
- [ ] **R1** — **Plugins.** `nvim-telescope/telescope.nvim` with
      `plenary.nvim` and `telescope-fzf-native.nvim` (`build = "make"`);
      load the `fzf` extension under `pcall` so a failed native build degrades
      to the Lua sorter instead of breaking the finder.
- [ ] **R2** — **Lazy.** On `cmd = "Telescope"` plus the keys below.
- [ ] **R3** — **Keymaps.** `<leader>ff` and `<leader><space>` find_files,
      `<leader>fg` live_grep, `<leader>fb` buffers, `<leader>fh` help_tags.
- [ ] **R4** — **Multiselect → quickfix.** `<Tab>`/`<S-Tab>` toggle a mark and
      move; `<CR>` sends exactly the marked set to the quickfix list and opens
      it, or performs the normal single-entry open when nothing is marked.
- [ ] **R5** — **Same maps in both modes.** One shared read-only mapping table
      for insert and normal mode.
- [ ] **E1** — *from [`06-explorer`](../06-explorer/prd.md) R1–R3; numbers not
      reused.* `stevearc/oil.nvim` with `nvim-tree/nvim-web-devicons`,
      `view_options.show_hidden = true`, `<leader>e` → `:Oil`. It must be
      loaded early enough that `default_file_explorer` is installed before
      `:e some/dir`: lazy-loading on `keys` alone means netrw is disabled and
      oil is not yet present, so neither opens (L-7) — and this node's own
      third acceptance line asserts the behaviour that bug prevents.
- [ ] **G1** — *from [`12-small-plugins`](../12-small-plugins/prd.md) R1;
      numbers not reused.* `lewis6991/gitsigns.nvim`, lazy on
      `BufReadPre`/`BufNewFile`, with visible nerd-font glyphs for add,
      change, changedelete, delete and topdelete. The delete and topdelete
      glyphs are empty strings in the live config — a character was lost
      (L-10) — and this requirement carries the restored character as a
      literal, not as an intention.
- [ ] **G2** — *from [`12-small-plugins`](../12-small-plugins/prd.md) R2.*
      `folke/which-key.nvim` on `VeryLazy` with named leader groups:
      `<leader>f` find, `<leader>b` buffer, `<leader>c` code, `<leader>r`
      rename/refactor, `<leader>t` table. Group names stay in sync with the
      keymaps under them.
- [ ] **G3** — *from [`12-small-plugins`](../12-small-plugins/prd.md) R3.*
      `windwp/nvim-autopairs` on `InsertEnter`, default config. Explicitly not
      here: line/block commenting — Neovim 0.10+ ships `gc`, `gcc` and
      `gc{motion}` natively.
- [ ] **M1** — *from
      [`15-markdown-tables`](../15-markdown-tables/prd.md) R1–R4; numbers not
      reused.* `dhruvasagar/vim-table-mode`, lazy on markdown/markdown.mdx
      plus its `TableMode*`/`Tableize` commands, `g:table_mode_corner = "|"`
      for GFM tables, `g:table_mode_map_prefix = "<leader>t"` matching the
      which-key group, and a grouped `FileType` autocmd enabling it for
      markdown — plus a direct call at config time, because the `FileType`
      event that lazy-loaded the plugin has already fired for the triggering
      buffer.
- [ ] **X1** — Each plugin lives in its own file under `lua/plugins/nav/`, and
      each plugin-specific keymap lives in its spec's `keys`. Every map added
      here has its `help` entry in the same change.

## Acceptance
- [ ] `<leader>ff`, marking three files with `<Tab>` then `<CR>`, opens a
      quickfix list containing exactly those three; `<CR>` with nothing marked
      opens the highlighted entry.
- [ ] Deleting the compiled fzf-native artifact still leaves a working finder.
- [ ] `<leader>e` shows dotfiles; renaming a line and `:w` renames the file on
      disk; `nvim some/dir` on a cold start opens oil, not netrw and not an
      empty buffer.
- [ ] Editing a tracked file shows change signs, and a deleted hunk shows a
      visible glyph rather than nothing.
- [ ] `<leader>` then a pause lists the five named groups; `gcc` comments a
      line with no commenting plugin installed.
- [ ] Opening a markdown file directly and typing a table row aligns pipes
      live with `|` corners, and the result renders correctly on GitHub.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Unifying with television. Two finders is a decision already made:
  television in the shell, telescope in the editor.
- LSP, completion, formatting and treesitter — [`09-lsp`](../09-lsp/prd.md).
- Colours — [`11-colorscheme`](../11-colorscheme/prd.md).
- A commenting plugin.
- Shift-to-select — [`14-shift-select`](../14-shift-select/prd.md), gated on a
  decision.
```

### 33 · `03-editor/11-colorscheme` — REWRITE

Current: 0 / 9 / 0; after: 0 / 15 / 0. Absorbs `13-statusline` (9). Both
derive every colour from the same `tinted-nvim.get_palette()` call and both
must re-derive on the same `ColorScheme` event, in the same augroup;
duplicating that mechanism across two nodes is the exact failure the epic's
palette invariant exists to prevent. It also carries the constraint that cost
the most to learn. **M-12 is fixed here**: the acceptance said "all five
highlights" while R3 defines six.

```markdown
--- .mi/prd/03-editor/11-colorscheme/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/03-editor/01-options
priority: 60
verify: ""
---

# Colorscheme + mode-aware cursor

Parent: [Neovim epic](../prd.md) · C 5 · U 8 · sources: "Colorscheme +
mode-aware cursor", "Statusline (lualine)"

Purpose: Everything that reads the palette: the base16 colorscheme with
transparency so the terminal's background shows through, the cursor whose
colour states the current mode, and the statusline whose theme is built from
the same palette. The statusline's entire theme problem is "derive from
`get_palette()` and rebuild on `ColorScheme`", which is this node's own
invariant restated, so they are one node. The complexity here is a workaround,
documented so nobody simplifies it back into a broken state.

## Requirements
- [ ] **R1** — **Plugin.** `tinted-theming/tinted-nvim`, `priority = 1000`,
      `lazy = false` — a colorscheme must load before anything paints.
- [ ] **R2** — **Setup.** `default_scheme = "base16-gruvbox-dark-hard"`,
      `apply_scheme_on_startup = true`, `ui.transparent = true`, with the
      `blink` and `lualine` highlight integrations enabled.
- [ ] **R3** — **Palette-derived highlights.** One function reads
      `tinted-nvim.get_palette()` guarded by `pcall` and a nil check, and sets
      six groups: `CursorNormal` base0D, `CursorInsert` base0B, `CursorVisual`
      base0E, `CursorReplace` base08, and `Whitespace`/`NonText` base02 —
      which is what makes [`01-options`](../01-options/prd.md) R10's listchars
      unobtrusive. No highlight is a hex literal.
- [ ] **R4** — **Re-derive on change.** Run at config time and on every
      `ColorScheme` event in a cleared augroup; a scheme switch must never
      leave stale highlight colours behind.
- [ ] **R5** — **Cursor shapes.** `guicursor`: block for
      normal/command/showmatch, `ver25` insert, block visual, `hor20`
      replace/operator-pending, each bound to its `Cursor*` group, with
      `blinkwait700-blinkon400-blinkoff250`.
- [ ] **R6** — **Terminal coupling.** Transparency plus base16 is deliberate:
      WezTerm owns the background, so a live retint there is reflected here
      without touching the Neovim config. The palette-ownership statement
      lives in the [`02-terminal`](../../02-terminal/prd.md) epic and this
      node references it rather than restating it.
- [ ] **S1** — *from [`13-statusline`](../13-statusline/prd.md) R1–R2;
      numbers not reused.* `nvim-lualine/lualine.nvim` with
      `nvim-web-devicons` on `VeryLazy`, `globalstatus = true` (pairing with
      `laststatus=3`), no component or section separators, sections: mode /
      branch + diff + diagnostics / filename with `path = 1` / encoding +
      fileformat + filetype / progress / location.
- [ ] **S2** — *from [`13-statusline`](../13-statusline/prd.md) R3.* **Never
      use `theme = "auto"`.** Constraint with a real cause: `auto` collapses
      any `base16-*` colorscheme to lualine's bundled `base16` theme, which
      requires the separate `nvim-base16` plugin and errors when it is absent.
      tinted-nvim is not that plugin.
- [ ] **S3** — *from [`13-statusline`](../13-statusline/prd.md) R4–R6.* Build
      lualine's theme table directly from `tinted-nvim.get_palette()` — `a`
      background per mode (normal base0D, insert base0B, visual base0E,
      replace base08, command base0A) on base00 text, `b` base05 on base02,
      `c` base04 on base01, inactive base03 on base01 — so the mode colours
      match R5's cursor colours by construction. Fall back to lualine's
      builtin `gruvbox_dark` before the palette is available, a real theme
      file with no `nvim-base16` dependency, so the broken base16 path is
      never requested. Recompute the theme and re-run `lualine.setup` on every
      `ColorScheme` event, in R4's augroup.

## Acceptance
- [ ] The editor background matches the terminal's, including after a live
      background change in the terminal.
- [ ] The cursor uses the mode's colours — blue normal, green and thin insert,
      magenta visual, red underline replace — and the statusline mode section
      uses the same ones.
- [ ] `:colorscheme <other-base16>` re-derives **all six** highlights and the
      statusline theme with no stale colour left (M-12: the previous
      acceptance said five).
- [ ] One statusline for the whole window regardless of splits.
- [ ] `:checkhealth` and startup show no `nvim-base16` error, and none appears
      after switching base16 schemes.
- [ ] `grep -rn '#[0-9a-fA-F]\{6\}' home/dot_config/nvim` returns nothing.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Defining a palette. The terminal owns it; this node derives from it.
- Whether tinty stays as palette owner —
  [`decisions/tinty`](../../00-delivery/decisions/tinty/prd.md).
- The theme switcher UI and the smear cursor — both `DEFER`.
- Any other plugin's appearance settings.
```

### 34 · `03-editor/14-shift-select` — REWRITE

Current: 0 / 13 / 0; after: 0 / 16 / 0. R1–R8 keep their numbers and text; R9
is new and closes the fork. This stays its own node because it is the only
editor feature gated on a human answer, and folding it into a sibling would
drag that sibling behind the decision. `## Simplification option` is preserved
— it is where the decision writes its answer.

```markdown
--- .mi/prd/03-editor/14-shift-select/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/shift-select-scope
  - .mi/prd/03-editor/01-options
priority: 55
verify: ""
---

# Shift-to-select (SIMPLIFY)

Parent: [Neovim epic](../prd.md) · C 7 · U 7 · source: "Shift-to-select"

Purpose: The signature customisation: Shift+arrows select like a conventional
editor — including the part most vim configs get wrong, where a plain motion
after a shift-selection *collapses* the selection instead of extending it. A
`v`-started selection keeps full vim semantics. ~60 lines of mode feeding and
flag tracking, and the one SIMPLIFY on the board with a real fork.

## Requirements
- [ ] **R1** — **Premise.** `clipboard=unnamedplus` from
      [`01-options`](../01-options/prd.md) R9 — the system clipboard is the
      unnamed register, which is what makes the clipboard keys below behave as
      a GUI editor's.
- [ ] **R2** — **State flag.** A `shift_select` boolean, set whenever a
      selection begins via Shift, reset by a `ModeChanged` autocmd whenever
      visual mode is left (old mode matching `^[vV\22]`), **registered in its
      own cleared augroup** — it is ungrouped live, so a reload stacks
      duplicates (L-8). Without the reset, a later plain `v` selection would
      inherit collapse-on-motion behaviour.
- [ ] **R3** — **Start from normal.** `<S-Up/Down/Left/Right>` enter visual
      and apply the motion.
- [ ] **R4** — **Extend from visual.** `<S-arrows>` keep extending; the flag
      stays set.
- [ ] **R5** — **Start from insert.** `<S-arrows>` leave insert and start the
      selection; `<S-Right>` needs an extra `l` first so the character under
      the insert cursor is included.
- [ ] **R6** — **Collapse on plain motion.** In visual mode `h`/`j`/`k`/`l`
      and the unshifted arrows: if `shift_select` is set, clear it, leave
      visual and apply the motion; otherwise apply normally. Counts preserved
      in both branches (`vim.v.count`).
- [ ] **R7** — **Clipboard keys.** Visual `<C-c>` → `y`; visual `<C-v>` →
      `"_dP`. The `<C-v>` shadow of blockwise-visual is **intentional and
      ported as-is, with `<C-q>` left unbound** — decided and verified against
      a live nvim 0.12.4 (L-9): the map is `v`-mode only, so normal-mode
      `<C-v>` still enters blockwise, `virtualedit=block` still applies, and
      the unbound built-in `<C-q>` covers the one case lost.
- [ ] **R8** — **Feeding helper.** All of the above go through one
      `nvim_feedkeys` + `nvim_replace_termcodes` helper — not scattered
      `<cmd>` strings, and there is exactly one such helper.
- [ ] **R9** — The scope built is the one
      [`decisions/shift-select-scope`](../../00-delivery/decisions/shift-select-scope/prd.md)
      chose, and this node states which branch was taken with the decision's
      date. The downgrade branch drops R4–R6 and keeps R3 and R7 only, and the
      C/U header falls to roughly C 3 / U 5 with the inventory entry updated
      to match. One branch is built, not both behind a flag. The `help`
      entries for these keys describe the shipped behaviour.

## Acceptance
- [ ] From normal, `<S-Right><S-Right>` selects two characters, and pressing
      `l` then leaves visual and moves right one. (M-2 records that one
      `<S-Right>` already selects two characters — `v<Right>` — so the
      acceptance is written against the measured behaviour, not the assumed
      one.)
- [ ] From `v`, pressing `l` extends the selection, as in stock vim.
- [ ] From insert, `<S-Left>` selects the character just typed.
- [ ] `3j` in a shift-started selection collapses and moves three lines.
- [ ] `<C-c>` in visual copies to the system clipboard; `<C-v>` over a
      selection replaces it and the clipboard still holds the original.
- [ ] `nvim --headless -c 'lua print(vim.fn.maparg("<C-q>", "n"))' -c 'qa'`
      prints nothing.
- [ ] Sourcing the config twice leaves exactly one `ModeChanged` autocmd in
      the group.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Changing `clipboard` or any option — that is
  [`01-options`](../01-options/prd.md).
- Binding `<C-q>` to anything.
- Insert-mode-first modal inversion and its `<F24>` Karabiner dependency
  (`DO NOT PORT`).
- Making the behaviour configurable. One of the two branches is built.

## Simplification option
«PRESERVE: ## Simplification option»
```

### 35 · `04-shell/03-zoxide` — REWRITE

Current: 0 / 10 / 0; after: 0 / 18 / 0. Absorbs `06-listing` (7): the
auto-list hook and the navigation funnel are the same hook — the epic's own I2
says the PWD hook is the single reaction point, so listing and the dirstack
push are two consumers of one registration. A separate listing node would
either register a second hook, violating the invariant, or edit the funnel
node's file. It carries the `du` bug. Prefixes `LS1`–`LS4`. **M-5 is fixed
here**: the header says C 5 while its sources are C 4 (suite, dominant) and
C 7 (fallback); the dominant entry's rating is C 4.

```markdown
--- .mi/prd/04-shell/03-zoxide/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/fzf
  - .mi/prd/04-shell/01-core-config
priority: 70
verify: ""
---

# Zoxide navigation

Parent: [Nushell epic](../prd.md) · C 4 · U 9 · sources: "Zoxide navigation
suite" (C 4, dominant), "Bare-word directory fallback" (C 7), "Decorated ls +
auto-list" (C 5)

Purpose: Every way of changing directory and the one thing that happens
afterwards. Zoxide's wrappers, the bare-word fallback and the auto-listing
hook are three faces of the same invariant — `mkcd` is the single funnel and
the PWD hook is the single reaction point — and splitting them puts two
workers in the same nushell modules to negotiate one hook.

## Requirements
- [ ] **R1** — **`z`** wraps `__zoxide_z`: a single argument resolving to an
      existing *file* opens in `$EDITOR` instead of jumping; otherwise it is a
      dir query. Dir jumps log to quicklist recents only when PWD actually
      moved; file opens always log.
- [ ] **R2** — **`zi`** (and the `cdi` alias, defined here and nowhere else) —
      interactive picker, same recents logging. Whether it reaches fzf or a
      tv-backed picker follows
      [`decisions/fzf`](../../00-delivery/decisions/fzf/prd.md).
- [ ] **R3** — **Composed verbs.** `zz` = `cd -`, `zl` = jump then `la`,
      `zc` = jump then Claude (`cc`).
- [ ] **R4** — **Funnel compliance.** All jumps go through the `cd` alias →
      `mkcd` inside `__zoxide_z`, so start dir and dirstack update like any
      move.
- [ ] **R5** — **Trigger.** A line whose first token is not a known command,
      contains no shell/nu metacharacters, and is not path-shaped
      (`-`/`/`/`~` prefix, embedded `/`, bare `.`/`..`) is a zoxide query. A
      dot-NAME like `.files` stays a valid target.
- [ ] **R6** — **Jump only on a genuine match.** Query `zoxide query --exclude
      $PWD` directly, never `__zoxide_z`; a failed lookup leaves `$PWD` alone
      and logs nothing, and the normal "command not found" is untouched. M-8
      records that the no-match HOME hazard comes from `mkcd` treating `""` as
      "no argument", not from `__zoxide_z`.
- [ ] **R7** — **Mechanics.** Jump from `pre_execution` (cd persists there),
      mark `$env._NAV`, clear the screen in `pre_prompt` to bury the doomed
      error. Log dirstack and recents at jump time, because the PWD hook may
      not fire from `pre_execution`.
- [ ] **LS1** — *from [`06-listing`](../06-listing/prd.md) R1–R2; numbers not
      reused.* The builtin `ls` is captured as `core-ls` before shadowing
      (alias targets bind at parse time); the wrapper redeclares the builtin's
      flags explicitly and defaults the pattern to `.`; results sort by `type,
      modified` (dirs grouped, freshest nearest the prompt) with an `icon`
      column from an extension→glyph map plus dir and generic fallbacks.
- [ ] **LS2** — *from [`06-listing`](../06-listing/prd.md) R3.* `-D` is
      opt-in only and swaps each directory's inode size for its recursive
      on-disk size using a measurement macOS supports. `du -sb` is not one —
      macOS `du` has no `-b` and stderr is discarded, so sizes silently stay
      inode sizes (L-1). Use `-sk` or `gdu`, and make a failure visible rather
      than swallowed. Never on by default: `node_modules` would stall every
      listing.
- [ ] **LS3** — *from [`06-listing`](../06-listing/prd.md) R4.* Variants `l`,
      `ll`, `la`.
- [ ] **LS4** — *from [`06-listing`](../06-listing/prd.md) R5.* The auto-list
      hook runs `la` after every real directory change in an interactive
      shell, **from the single PWD hook
      [`01-core-config`](../01-core-config/prd.md) R8 defines**, not a second
      registration — skipping the first fire at startup, and skipping when the
      bare-word fallback is about to clear the screen. `stty sane` first, so a
      crashed full-screen TUI cannot staircase the table.
- [ ] **X1** — Every command and binding added here has its `help` entry in
      the same change, and the entry for the bare-word fallback says
      explicitly that it is a fallback.

## Acceptance
- [ ] `z somefile.txt` opens the editor; `z proj` jumps; a failed `z nomatch`
      leaves `$PWD` alone and logs nothing.
- [ ] `proj` ⏎ bare lands in the project dir with a clean screen; `zz`
      returns.
- [ ] `ls | something-unknown` and `./x` never trigger the fallback.
- [ ] `cd` anywhere — including via zoxide or a picker — prints the listing
      exactly once, correctly aligned right after quitting a TUI mid-render.
- [ ] Plain `ls` in a directory containing `node_modules` returns instantly;
      `ls -D` shows real recursive sizes and prints an error rather than wrong
      numbers if the size probe fails.
- [ ] `nu -l -c '$env.config.hooks.env_change.PWD | length'` still returns 1
      with this node loaded.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Environment, aliases and the `mkcd` implementation —
  [`01-core-config`](../01-core-config/prd.md).
- The quicklist log format, which
  [`04-television`](../04-television/prd.md) owns; this node calls the logger.
- Any hand-coded TUI. tv owns every picker screen, and the one exception, if
  the fzf decision keeps it, is recorded in the epic's I3.
```

### 36 · `04-shell/04-television` — REWRITE

Current: 0 / 13 / 0; after: 0 / 22 / 0. Absorbs `05-history` (7) and
`07-quicklist` (8): the quicklist explicitly reuses the finder's decoder and
opener, and the history picker is a tv channel over the same store with the
same reedline ordering constraint. Three nodes means three workers in
`finder.nu` sharing one decoder table and one binding-order rule. Specced from
the DEPLOYED 221-line `finder.nu` per decision 4. Prefixes `H1`–`H3`,
`Q1`–`Q3`. Its verify no longer names a wave gate.

```markdown
--- .mi/prd/04-shell/04-television/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/04-shell/01-core-config
  - .mi/prd/05-platform/03-shell-init-generation
priority: 65
verify: ""
---

# Television finder

Parent: [Nushell epic](../prd.md) · C 8 · U 9 · sources: "Television finder",
"Directory-scoped history", "Quicklist"

Purpose: television (`tv`) owns every picker screen in the shell, its typed
decoders, and the two logs that feed it. `finder` runs a channel and returns
typed nushell data; channel selection is itself a fuzzy channel; selections
open by type. The finder's decoder and opener are literally reused by the
quicklist and the history picker, so three nodes here would be three workers
sharing one decoder table. Specced from the **deployed** 221-line `finder.nu`;
the 345-line chezmoi-source version is a different stack-and-resume design and
is not ported (decision 4).

## Requirements
- [ ] **R1** — **`finder [--start <channel>]`.** Runs a tv channel (or the
      channels remote first), un-hijacks enter (`--keybindings
      'enter="confirm_selection"'` — the stock `text` channel binds enter to
      edit), tab = multi-select, returns structured data.
- [ ] **R2** — **Typed decode.** Channel → produced type → decoder:
      `files`/`dirs`/`recent-dirs` → FileList (expanded, existing paths);
      `text` → GrepList `{file, line, text}`; `git-log` → Commits
      `{hash, subject}`; `cht-query` → ChtSheet; unknown channels pass raw
      strings. The `Commits` decoder reads the field the channel actually
      emits: it currently reads field index 1 of a line already reduced to a
      bare hash and the `^[0-9a-f]{7,}$` guard then drops every row, so
      commit → `git show` has never once run (L-2). The channel is called
      `recent-dirs`; `rcwd` is not a channel name and never was (L-3).
- [ ] **R3** — **Open-by-type.** GrepList → `$EDITOR +line file`; Commits →
      `git show`; ChtSheet → cht.sh via pager; path → cd if dir, edit if file.
      `--env` so a cd reaches the shell.
- [ ] **R4** — **Keybindings.** `Ctrl+Space` / `F1` → `tv_remote`: pick a
      channel, run it, ACT on the result. `Ctrl+T` → `tv_finder`: same picker
      but INSERT the selection at the cursor, shell-quoted.
- [ ] **R5** — **Cable channels, curated.** files, dirs, text, zoxide,
      `recent-dirs` (sourced from the dirstack), quicklist, `nu-history` (the
      channel `Alt-R` depends on), git-log/git-files/git-branch, env, and the
      `help` channel [`06-help/02`](../../06-help/02-help-command/prd.md)
      provides. There is **no `burrito-sessions` channel**, which also
      dissolves the `cht.sh=f5` shortcut collision. M-9 records that three
      enter-hijacking channels exist, not one — `text`, `zoxide` →
      `actions:cd` spawning a nested shell, and `recent-files` →
      `actions:edit` — and that `text.toml` is a local override, not stock.
- [ ] **R6** — **Theming.** tv uses the `default` ANSI theme so it inherits
      the terminal's palette rather than baking hex values.
- [ ] **R7** — **Known tv limitations, encoded as guards.** tv panics without
      a TTY, so every entry point checks and returns or errors cleanly; the
      CLI `--keybindings` grammar is `key="action"`, the inverse of the
      config-file form; with `--expect`, stdout line 1 is the pressed key
      (empty = plain enter).
- [ ] **H1** — *from [`05-history`](../05-history/prd.md) R1; numbers not
      reused.* One shared helper returns this cwd's distinct commands,
      newest-first (sqlite `GROUP BY command_line ORDER BY max(id) DESC`,
      capped ~5000), reading the merged store
      [`01-core-config`](../01-core-config/prd.md) R4 configures.
- [ ] **H2** — *from [`05-history`](../05-history/prd.md) R2–R4.* `Ctrl-R` is
      a tv inline picker over local history, prefilled with the line up to the
      cursor; `Alt-R` is tv's global `tv_shell_history` — Alt and not
      Ctrl-Shift, because shift is indistinguishable on control+letter without
      the kitty protocol, which stays off. `Up`/`Down` cycle local history
      inline with the position tracked in `$env`, resetting to newest on any
      typing; `Shift+Up/Down` is reedline's native global traversal. All arrow
      bindings try `menuup`/`menudown` first in `until` chains, so a
      completion menu keeps the arrows.
- [ ] **H3** — *from [`05-history`](../05-history/prd.md) R5.* These bindings
      are appended **after** tv's generated init so they win reedline's
      last-entry-wins resolution over tv's own Ctrl-R. reedline has no chord
      trees, so ordering is the only mechanism available.
- [ ] **Q1** — *from [`07-quicklist`](../07-quicklist/prd.md) R1; numbers not
      reused.* `_recents_add kind value channel`: entries carry kind, value,
      channel, cwd and timestamp; dedup by channel+value, newest first, cap
      200, stored as nuon in XDG state.
- [ ] **Q2** — *from [`07-quicklist`](../07-quicklist/prd.md) R2.* Producers:
      the zoxide wrappers, the bare-word fallback **and finder picks**. Finder
      picks are never logged in the live config — the call site does not exist
      (L-4) — and that omission is not ported. A failed jump logs nothing.
- [ ] **Q3** — *from [`07-quicklist`](../07-quicklist/prd.md) R3–R4.*
      `Ctrl-Q` opens the quicklist channel, also reachable from the remote,
      with two confirm keys via `--expect`: `enter` opens by type, reusing R2
      and R3's decoder and opener rather than a second copy; `ctrl-r` replays,
      cd-ing to the cwd the pick was made in and re-running its originating
      channel there. An empty log prints a one-line hint instead of opening tv
      on nothing.
- [ ] **X1** — Every binding and channel added here has its `help` entry in
      the same change, and the entries name television so an agent reading the
      manual does not reach for fzf.

## Acceptance
- [ ] `Ctrl+Space`, type `fil`, enter, pick a file → opens in nvim; pick a dir
      via `dirs` → the shell cds and auto-lists.
- [ ] `Ctrl+T` on a path with spaces inserts it quoted; esc leaves the line
      untouched.
- [ ] A grep pick from `text` opens the editor at the matching line, and a
      commit pick reaches `git show` with a non-empty diff — the check that
      fails if the decoder reads the wrong field.
- [ ] `finder` in a non-tty context returns or errors cleanly, no panic.
- [ ] Run a command in dir A and another in B: in A, `Up` recalls A's command
      and `Ctrl-R` lists only A's history; `Shift+Up` reaches B's; with a
      completion menu open the arrows navigate the menu.
- [ ] `Alt-R` resolves to a defined command in a fresh shell.
- [ ] Jumping with `z`, opening a file via the finder, then `Ctrl-Q` shows
      both newest-first; `ctrl-r` on a `text` entry reopens the grep picker in
      the directory the original search ran in; an empty log prints the hint
      and does not open tv.
- [ ] `grep -rn 'rcwd\|burrito' home/dot_config` returns nothing, and
      `grep -c 'GrepList' home/dot_config/nushell` finds one decoder, not two.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Any hand-coded TUI. tv owns every picker screen in the shell.
- Telescope, the editor's finder, deliberately not unified with this one.
- Generating tv's own init file — that is
  [`05-platform/03`](../../05-platform/03-shell-init-generation/prd.md), which
  must produce it before these bindings are appended.
- The abandoned 345-line source `finder.nu` and its stack-and-resume design,
  including the `--resume`/`--fresh` flags the deployed finder never had, and
  `leadermode.nu`, a leftover of that design (L-5, `DO NOT PORT`).
- The long tail of git-* and app-specific channels (`DEFER`).
```

### 37 · `05-platform/03-shell-init-generation` — REWRITE

Current: 0 / 9 / 0; after: 0 / 16 / 0. Absorbs `02-terminal/06-launchd-path`
(5). Its own R2 requires the seeded PATH to be derived from the provisioning
layer's installed set rather than a hardcoded list — and this is the only node
that knows that set, at the only phase (`run_after`) where the tools are
resolvable. Left in the terminal epic it forces the package list to be
duplicated, which is the failure its own requirement forbids. Prefixes
`P1`–`P3`.

```markdown
--- .mi/prd/05-platform/03-shell-init-generation/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/05-platform/02-package-provisioning/packages-installer
priority: 70
verify: ""
---

# Shell-init generation

Parent: [Provisioning epic](../prd.md) · C 3 · U 9 · sources: "Shell-init
generation", "launchd PATH seeding"

Purpose: The `run_after` phase — everything that must be computed once at
apply time so that launching a shell or a GUI terminal costs nothing. The
launchd PATH seeding lives here because its own requirement says the seeding
must be derived from the provisioning layer's installed set, and this is the
only node that knows it.

## Requirements
- [ ] **R1** — **Runs last.** A `run_after` script, after the package
      installer, re-resolving brew shellenv and user bins first so it can use
      tools installed in the same apply.
- [ ] **R2** — **Generated files.** starship, zoxide and television init
      files. The live layout is inconsistent — two in `~/.cache`, one in
      `$HOME` — so pick one location for all three in the rebuild and update
      the [shell epic's](../../04-shell/prd.md) invariant to match rather than
      inheriting the split.
- [ ] **R3** — **Never break `source`.** Each file exists after the run; a
      missing tool yields an empty file, which is a harmless no-op, so
      `config.nu`'s `source` lines cannot fail on a machine where a tool is
      not installed yet.
- [ ] **R4** — **Regenerate every apply.** Derived artifacts: not committed,
      always rewritten, so a tool upgrade's new init is picked up.
- [ ] **R5** — **Version-sensitive output.** The generated television init
      defines the `tv_shell_history` command the shell binds to `Alt-R`
      ([`04-shell/04`](../../04-shell/04-television/prd.md) H2), so a tv
      upgrade that renames it breaks a keybinding. The gate checks the
      binding, not just the file.
- [ ] **P1** — *from
      [`02-terminal/06-launchd-path`](../../02-terminal/06-launchd-path/prd.md)
      R1; numbers not reused.* A GUI launch (Finder, Spotlight, Dock) resolves
      every tool the config assumes, not only those on launchd's default PATH.
      Recorded in T-10 as the one uncovered item whose absence is fatal.
- [ ] **P2** — *from `06-launchd-path` R2.* The seeded set is derived from
      `.chezmoidata/packages.yaml` rather than hardcoded, so adding a package
      cannot silently break a GUI launch.
- [ ] **P3** — *from `06-launchd-path` R3.* A terminal launch is unaffected:
      no doubled and no reordered PATH entries relative to an unseeded
      terminal session.
- [ ] **X1** — Every generated file that introduces a binding has its `help`
      entry in the same change — `Alt-R` in particular.

## Acceptance
- [ ] After an apply, all three init files exist and are non-empty on a
      machine with the tools installed.
- [ ] On a machine missing starship, the file exists, is empty, and launching
      `nu` produces no error.
- [ ] `Alt-R` resolves to a defined command after a fresh apply.
- [ ] Timing a cold `nu` start shows no init-generation cost.
- [ ] WezTerm launched from Finder resolves `nu`, `nvim`, `tv` and `zoxide`.
- [ ] The PATH in a GUI-launched session and a terminal-launched session
      differ only by ordering that does not change which binary wins, checked
      by sorting both.
- [ ] Adding a package to `.chezmoidata/packages.yaml` changes the seeded set
      without editing this node.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Installing anything — the installer already ran.
- Committing any generated file.
- Hardcoding a tool list anywhere, including in the launchd seed.
- Anything about shell startup files. The launchd half is the launchd
  environment only.
- Anything that costs time at shell launch rather than apply time.
```

### 38–43 · The six epic roll-ups — REWRITE

Each gains explicit invariants and loses nothing. Two of the six —
`02-terminal` and `05-platform` — have an `## Acceptance` heading with **zero
boxes under it** today, which means they owe nothing from it and could close
vacuously on their children alone; `w0-3-platform-rewrite` `## Findings`
records that as a defect and this is where it is fixed. Each epic's
`## Out of scope` lines are carried in full and extended.

```markdown
--- .mi/prd/02-terminal/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: Terminal (WezTerm)

Purpose: WezTerm is the daily driver and the owner of the palette every other
surface inherits. The old config mixed keepers with features marked
`DO NOT PORT`; this epic ports only the keepers, cleanly, and it was specced
from the wrong config once — `capabilities-terminal.md` and the deployed
1149-line `wezterm.lua` are the inputs now, not `capabilities.md`.

Goal: A WezTerm config that looks right on first launch, opens in the
nine-tab shape, and makes tab/pane navigation a single keystroke.

## Requirements
- [ ] **I1** — **The terminal owns the palette.** Neovim (base16 +
      transparent) and television (`default` ANSI theme) inherit it and
      hardcode no hex values. **This is the single statement of that fact on
      the board**; it appears twice today, in neither the terminal epic nor
      anywhere it belongs.
- [ ] **I2** — **The self-healing nine-tab floor is the tab/pane model.**
      There is no competing multiplexer: burrito was deleted 2026-08-20, which
      settles what was open decision 1.
- [ ] **I3** — **Every configuration key any child names is accepted by the
      installed WezTerm binary**, proven by loading the config, not by reading
      the docs.
- [ ] **I4** — **No child re-implements what WezTerm provides.** Copy mode,
      the tab bar and key tables are used, not rebuilt.

## Acceptance
- [ ] Loading the full config with `wezterm --config-file` produces no
      invalid-Config-field error.
- [ ] `grep -rn '#[0-9a-fA-F]\{6\}' home/dot_config/nvim home/dot_config/television`
      returns nothing.
- [ ] Every child is `done` or `out-of-scope`.
- [ ] Each of T-1 through T-11 is fixed in a child or recorded as accepted
      with a reason.

## Out of scope
- Anything on the `DO NOT PORT` list: three-pane split layout, quake dropdown,
  container-aware status bar, background image cycling, opacity toggle.
- burrito, in every form. It is deleted from the repo and no terminal
  capability is inherited from it.
- Any terminal other than WezTerm, and any non-macOS host.
- Porting from the chezmoi source's 339-line `wezterm.lua`; the deployed file
  is the input and the ~810-line delta is not pushed back.

## Note on children
«PRESERVE: ## Note on children»
```

```markdown
--- .mi/prd/03-editor/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: Neovim

«PRESERVE: the Purpose and Goal paragraphs, byte for byte — including
"~680 lines across 14 files", which is already correct (M-17 closes as
already-done).»

## Requirements

**Architecture invariants**

- [ ] **I1** — **Load order is load-bearing.** `options` → `keymaps` →
      `autocmds` → `lazy`. The leader key must be set before any plugin spec
      is evaluated.
- [ ] **I2** — **Lean on Neovim's built-ins.** 0.10+ has `gc` commenting; 0.11
      ships default LSP and diagnostic maps. Add only what is missing — never
      a plugin that duplicates core.
- [ ] **I3** — **One plugin per concern.** blink.cmp replaces the whole
      nvim-cmp stack; telescope is the editor's finder; conform owns
      formatting.
- [ ] **I4** — **Palette is derived, never duplicated.** Everything that needs
      colours reads tinted-nvim's live palette and re-derives on
      `ColorScheme`.
- [ ] **I5** — **Plugin-specific keymaps live in their spec** (`keys = …`) so
      they lazy-load; only general maps live in `keymaps.lua`.
- [ ] **I6** — **Every autocmd lives in its own cleared augroup**, so a
      reload never stacks duplicates (L-8).
- [ ] **I7** — *was the unnumbered "I (from `05-platform/02` req 6)" box.*
      This epic references the Neovim version floor recorded in
      [`packages-installer`](../05-platform/02-package-provisioning/packages-installer/prd.md)
      R6 rather than restating a version number.

## Acceptance
- [ ] `nvim --headless '+Lazy! sync' +qa` exits 0 on a clean machine.
- [ ] No hex colour literal appears anywhere under `home/dot_config/nvim/`.
- [ ] Sourcing the whole config twice leaves one autocmd per augroup.
- [ ] No map defined in `lua/config/keymaps.lua` references a plugin.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- The mini.nvim plugin set and its `mini.deps` bootstrap (`DO NOT PORT`).
- Insert-mode-first modal inversion and its `<F24>` Karabiner dependency
  (`DO NOT PORT` — Karabiner is out of scope entirely).
- Smear cursor (`DEFER` — pure eye candy).
- Unifying the editor finder with the shell's — two finders is a decision
  already made.
- Any commenting or LSP-mapping plugin that duplicates a built-in.

## Note on children
«PRESERVE: ## Note on children»
```

```markdown
--- .mi/prd/04-shell/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: Nushell daily driver

«PRESERVE: the Purpose and Goal paragraphs, byte for byte.»

## Requirements

**Architecture invariants**

These are what make the pieces compose; every child PRD leans on them:

- [ ] **I1** — **`mkcd` is the single navigation funnel.** Real `cd`, zoxide
      jumps, picker jumps and the bare-word fallback all flow through it — so
      start dir, the dirstack and recents update no matter how you move.
- [ ] **I2** — **The PWD hook is the single reaction point.** Auto-list and
      the dirstack push live there, not scattered per-navigation-command.
- [ ] **I3** — **tv owns every picker screen.** No hand-coded TUIs; new
      pickers are new cable channels plus a typed decode. If
      [`decisions/fzf`](../../00-delivery/decisions/fzf/prd.md) accepts fzf as
      an exception, the exception is named **here**, with its reason, rather
      than left implicit — otherwise the manual tells an agent to reach for a
      picker the invariant forbids.
- [ ] **I4** — **State lives in XDG state, generated integrations in cache.**
      Shell launch does zero setup work; chezmoi's apply step generates the
      starship/zoxide/tv init files.

## Acceptance
- [ ] `nu -l -c '$env.config.hooks.env_change.PWD | length'` returns 1.
- [ ] Timing a cold `nu` start shows no init-generation cost.
- [ ] No file under `home/dot_config/nushell/` renders a selection list
      itself.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- Leader mode and the nu-native overlay finder (`DO NOT PORT` — superseded by
  the tv remote on Ctrl+Space; `input listen` cannot do reliable modifiers).
- `overlay.nu` (explicit WIP, never sourced).
- Theme switcher and opacity picker (`DEFER` — cosmetic, revisit later).
- Porting any zsh/oh-my-zsh behaviour from the old `~/.files`; that ecosystem
  lives on only inside capsule containers.
- The `bb`/`ba` session aliases: burrito is deleted and they invoked `brr`
  (M-7).
- Windows, PowerShell and any drive-letter path abstraction.

## Note on children
«PRESERVE: ## Note on children»
```

```markdown
--- .mi/prd/05-platform/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: Provisioning — how the config reaches a machine

«PRESERVE: the Purpose and Goal paragraphs, byte for byte», with one appended
sentence: *"Decision 4 (2026-08-21) makes this a from-scratch deploy
mechanism, not a port of a working one: the chezmoi source and the deployed
tree were measured to be different programs, and applying the source as it
stands would destroy the configuration the inventories were written from
(L-13)."*

## Requirements

**Architecture invariants**

- [ ] **I1** — **Apply-time, not launch-time.** Anything that costs
      milliseconds at shell start is generated during `chezmoi apply` instead.
      The shell only `source`s.
- [ ] **I2** — **Idempotent by construction.** Every script is guarded
      (`command -v`, `run_once`, `run_onchange` hashes) so re-applying is safe
      and cheap.
- [ ] **I3** — **Tools are data.** The package set lives in
      `.chezmoidata/packages.yaml`; the installer is a renderer over it.
- [ ] **I4** — **Never fail the whole apply.** One unavailable package warns
      and continues; a partial machine beats an aborted one.

## Acceptance
- [ ] A second `chezmoi apply` on an unchanged source reports no changes.
- [ ] No package name appears in any file under `home/.chezmoiscripts/`, and
      no generated file is committed.
- [ ] An induced package failure leaves the apply's exit code at 0 with a
      warning printed.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- The legacy `conf/bootstrap.lua` checker and its `.cache/.bootstrap` stamp.
  Superseded; not ported.
- The legacy `~/.files` symlink deployer (`deploy.disabled`, `index`,
  `deleted`) — already `DO NOT PORT`, along with the `reload` sync command.
- Windows of any kind, including the live
  `run_after_mirror-config-to-windows.sh`.
- `wp-stat-overlay` provisioning and the published docs site (`DEFER`).
- Porting the abandoned chezmoi source's file contents; only its rated
  capabilities carry over.
- Uninstalling packages removed from the data.

## Note on children
«PRESERVE: ## Note on children»
```

```markdown
--- .mi/prd/01-capsule/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: Capsule — one consolidated dev-container tool

«PRESERVE: the Purpose and Goal paragraphs, byte for byte.»

## Requirements
- [ ] **I1** — **Build once.** One image definition, built once, reused; a
      rebuild happens only when the definition changed or is forced.
- [ ] **I2** — **No secret in a layer.** Credentials arrive by mount at run
      time, always.
- [ ] **I3** — **One entry point.** Everything the old `mount`, the two
      bindings and `just run` did is reachable from one command.
- [ ] **I4** — **Legacy `mount` behaviour is not the specification.** It never
      worked (C-3); its behaviour is evidence of a bug, not a contract.
- [ ] **I5** — **Every binding the epic claims is free, or its conflict is
      recorded with the resolution.** `Ctrl+Shift+B` is free because both
      wallpaper cycling and the opacity picker are excluded; `Ctrl+Shift+T` is
      WezTerm's own `SpawnTab` default and must be overridden explicitly or
      left alone.

## Acceptance
- [ ] One command, and one terminal keybinding that calls it, covers
      everything the old `mount`, `Ctrl+Shift+D`, `Ctrl+Shift+B` and `just
      run` did.
- [ ] Reconnecting to a running capsule feels instant; cold start is dominated
      by docker itself, not by the tool.
- [ ] `git push` and SSH work inside the container without any
      re-authentication.
- [ ] C-1 through C-5 are each fixed or recorded as accepted with a reason.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- Multiple images or per-project Dockerfile customization (later, if ever).
- Orchestrating more than one container per directory.
- Porting the old `mount`/`justfile`/keybinding implementations as-is; they
  are inputs to the design, not the design.
- zsh or oh-my-zsh on the host — they survive only inside capsules.

## Note on children
«PRESERVE: ## Note on children»
```

```markdown
--- .mi/prd/06-help/prd.md ---
---
state: open
mode: afk
deps: []
priority: 50
verify: ""
---

# Epic: `help` — the environment manual

«PRESERVE: the Purpose and Goal paragraphs, byte for byte.»

## Requirements

**Architecture invariants**

- [ ] **I1** — **One content source, many renderers.** Human tables, fuzzy
      browser, JSON and markdown all read the same data. A binding is
      described exactly once.
- [ ] **I2** — **Delegate, never shadow.** Anything that is not ours goes to
      the tool that owns it — builtin `help` for nu commands, `:help` for
      Neovim.
- [ ] **I3** — **Checkable or absent.** Every documented binding is verifiable
      against live introspection, or explicitly marked prose-only.
- [ ] **I4** — **Non-TTY output is plain.** No pager, no colours, no TUI when
      stdout is not a terminal.

## Acceptance
- [ ] A newcomer runs `help` and can use this environment: navigate, find,
      edit, containerize.
- [ ] An agent runs one command and gets the same knowledge as structured
      data.
- [ ] Adding a keybinding without documenting it fails the drift check.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- Replacing nushell's builtin `help` for nu commands, or `:help` in Neovim, or
  which-key's in-editor discovery.
- A hand-written document nobody updates. If it cannot be checked, it is not
  in scope.
- A web page or GUI. Terminal-first.
- Documenting plugin- and core-provided maps. They are not ours.
- A second copy of any description text outside the content model.

## Two findings that shape the design
«PRESERVE: ## Two findings that shape the design»

## Note on children
«PRESERVE: ## Note on children»
```

### 44 · `00-delivery/first-run` — NEW

The one node that means we shipped. It exists as its own address rather than
as a clause of the gate runner because the runner is built first and this is
proved last, and a node cannot be both. It owns four boxes that in the winning
plan were distributed across `verification-gates` and the root, where "the
last gate runs on a machine that has never seen this config" had no owner, no
script and no transcript — the exact shape of box that closes because someone
remembers doing it.

```markdown
--- .mi/prd/00-delivery/first-run/prd.md ---
---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/verification-gates
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
  - .mi/prd/05-platform/02-package-provisioning/packages-installer
  - .mi/prd/05-platform/03-shell-init-generation
  - .mi/prd/04-shell/01-core-config
  - .mi/prd/03-editor/01-options
  - .mi/prd/02-terminal/01-appearance
  - .mi/prd/06-help/02-help-command
priority: 45
verify: ""
---

# First run — the ship gate

Parent: [Delivery epic](../prd.md) · net-new

Purpose: This is the node that means we shipped. Everything before it is a
subsystem; this is the one command a person runs on a machine that has never
seen the repo, and the proof that what comes out the other side is a daily
driver rather than a collection of correct files. Everything else can pass on
a developer box that already has the tools installed and prove nothing.

## Requirements
- [ ] **R1** — **One command from a clean checkout.** `just install`
      bootstraps Homebrew if absent, installs the required package set,
      applies the managed tree, generates the shell inits, and exits 0 — with
      no interactive prompt beyond the ones macOS itself raises.
- [ ] **R2** — **On a host that has never seen this config.** A run on the
      author's machine does not satisfy it. The run is scripted at
      `tests/first-run/run.sh` so it can be repeated on a throwaway VM or a
      fresh user account, and its transcript is the evidence.
- [ ] **R3** — **The demo path works end to end** with no further setup: open
      WezTerm from Finder, land in nushell, `cd` into a directory that does
      not exist and have it created, list it, open a file in nvim, quit, and
      run `help` to see what else exists. Six steps, walked and recorded.
- [ ] **R4** — **`bash tests/gates.sh` passes on the freshly provisioned
      machine**, with the help surface reported as pass rather than pending.
- [ ] **R5** — **A second `just install` is a no-op**: chezmoi reports no
      changes and no package is reinstalled.
- [ ] **R6** — **Whatever the run needed that the repo did not provide is
      written back as a requirement in the node that owns it**, not patched
      into the run script. A run script that grows a workaround is a
      first-run gate that stops proving anything.

## Acceptance
- [ ] `bash tests/first-run/run.sh` on a fresh macOS user account exits 0, and
      its transcript is attached to the closing commit.
- [ ] The six-step demo in R3 is walked on that machine and each step is
      recorded pass or fail in `tests/gates/manual.md`.
- [ ] `bash tests/gates.sh` exits 0 on that machine.
- [ ] A second `just install` prints no changes.

## Out of scope
- Capsule, the television finder, LSP, the fuzzy browser and the drift check.
  None is on the first-run path; each is proved by its own gate afterwards.
- Multi-machine or multi-user provisioning.
- Restoring an existing machine's state. This proves a bare machine, not a
  migration.
- Building the gate scripts. [`verification-gates`](../verification-gates/prd.md)
  owns them; this node runs them.
```

### 45 · `06-help/04-drift-check` — REWRITE

Current: 0 / 15 / 0; after: 0 / 17 / 0. R1–R8 keep their numbers; R1's text is
sharpened to name its shell invocation, R9 and R10 are new. Its `deps` list is
the longest on the board and stays, minus one edge: `06-help/01-content-model`
is deleted because it closes a cycle (see the plan header). The drift check
needs the content **files**, which exist.

```markdown
--- .mi/prd/06-help/04-drift-check/prd.md ---
---
state: open
mode: afk
deps:
  «PRESERVE: the existing deps list, all 52 entries, minus exactly one:
   `.mi/prd/06-help/01-content-model`, deleted because it closes a cycle with
   `coverage` and the parent's readiness rule. Every other edge stands.»
priority: 40
verify: "help --check exits 0"
---

# Drift check

Parent: [Help epic](../prd.md) · C 5 · U 8 · net-new

Purpose: The feature that makes this manual trustworthy instead of
aspirational: `help --check` diffs the documented entries against the live
configuration, in both directions. Undocumented bindings and stale
documentation are both failures. It is the root node's second acceptance box
and the last gate in the runner, and it runs after everything that defines a
binding.

## Requirements
- [ ] **R1** — **Introspect the shell.** `$env.config.keybindings` — matched
      by keybinding `name`, which is why every binding in the config carries a
      meaningful one — plus `scope aliases` and `scope commands`. The check
      **names its invocation explicitly**: introspection runs in a
      *configured* shell. Measured 2026-08-21: `nu -c '$env.config.keybindings
      | length'` returns 0 while `nu -l -c` returns 13, so the naive probe
      reports every documented binding stale, every live binding absent, and
      still exits 0 — the exact false-green this node exists to prevent.
- [ ] **R2** — **Introspect Neovim.** `nvim --headless` +
      `nvim_get_keymap` per mode, emitted as JSON, matched by lhs and mode.
      Our maps carry `desc`, so the check compares descriptions as well as
      existence.
- [ ] **R3** — **Introspect the terminal.** `wezterm show-keys --lua`, plus
      `--key-table` for the F5 jump table.
- [ ] **R4** — **Report both directions**, naming each class: *undocumented*
      (exists live, no entry — the common failure), *stale* (documented, no
      longer live — the dangerous one, because it sends a reader to a key that
      does nothing), *mismatched* (in both, but `desc` and `title` disagree).
- [ ] **R5** — **Exempt prose.** Entries with `verify: prose` are skipped by
      existence checks and counted separately, so a prose entry can never be
      mistaken for a proven one.
- [ ] **R6** — **Allowlist noise.** Plugin- and core-provided maps are not
      ours to document and are excluded by an explicit list, not a heuristic —
      with one exception: the 0.11 LSP defaults we *chose* not to re-map
      (`grn`, `gra`, `grr`, `gri`, `gO`, `K`, `]d`, `[d`) ARE documented,
      because they are part of how you use this editor. The desc-exemption
      class is defined too, so the check does not false-positive on the
      centred-jump and visual-indent maps that deliberately carry no `desc`
      ([`01-options`](../../03-editor/01-options/prd.md) K2, M-15).
- [ ] **R7** — **Exit code.** Non-zero when anything is undocumented, stale or
      mismatched — so it can gate a commit or run in CI.
- [ ] **R8** — **Not on the hot path.** `--check` spawns nvim and wezterm;
      plain `help` never does, asserted by timing rather than by intent.
- [ ] **R9** — **Unowned-match report.** An entry whose live counterpart is
      supplied by the tool's own default rather than by our config is listed
      as *unowned*, not as documented. `Ctrl+Shift+T` resolves today only
      because `CTRL|SHIFT+T` is WezTerm's built-in `SpawnTab`, so its check
      passes whether or not a capsule binding is ever written — the named
      blind spot [`coverage`](../01-content-model/coverage/prd.md) R3 records.
- [ ] **R10** — **Empty-surface guard.** A surface that returns zero handles
      **fails the run and names itself**. Silence is the failure mode R1's
      measurement already produced once, and a check that exits 0 on an empty
      surface proves nothing while reading as proof — the same defect class
      [`verification-gates`](../../00-delivery/verification-gates/prd.md) R2
      legislates against.

## Acceptance
- [ ] Adding a keybinding to the nushell config without a manual entry is
      reported as undocumented and exits non-zero.
- [ ] Deleting a documented Neovim map is reported as stale; changing a map's
      `desc` but not the manual is reported as mismatched.
- [ ] A clean tree exits zero and prints per-surface counts (documented,
      prose-only, allowlisted, unowned).
- [ ] A zero-binding invocation (`nu -c` without config) fails the run instead
      of passing it, and any surface returning zero handles fails.
- [ ] `Ctrl+Shift+T` appears in the unowned list with WezTerm's default named
      as the provider.
- [ ] Renaming a documented key table to one that does not exist is reported —
      which the content-model schema gate alone does not catch.
- [ ] Timing `help` shows no nvim or wezterm process spawned.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
- Fixing the drift it finds. It reports; the owning node fixes.
- Rendering the manual — [`02-help-command`](../02-help-command/prd.md).
- Judging whether an entry is well written; that is the content model's
  writing rules.
- Documenting plugin- and core-provided maps.
```

### 46 · `06-help/01-content-model/coverage` — REWRITE

Current: 0 / 7 / 0; after: 0 / 10 / 0. R1–R5 and both acceptance boxes keep
their text — they are precise and each carries the measurement that makes it
honest. R6 is new: the direction of authority, which is decision 4 applied to
documentation.

```markdown
--- .mi/prd/06-help/01-content-model/coverage/prd.md ---
---
state: open
mode: afk
deps:
  «PRESERVE: the existing deps list, all 35 entries, unchanged.»
priority: 30
verify: ""
---

# Coverage

«PRESERVE: the `Parent:` line and both Purpose paragraphs, byte for byte —
including "Everything here is blocked by construction", which is the honest
record of why it is last.»

## Requirements
«PRESERVE-BOX: - [ ] **R1** — **Coverage — shell.** … »
«PRESERVE-BOX: - [ ] **R2** — **Coverage — Neovim.** … »
«PRESERVE-BOX: - [ ] **R3** — **Coverage — terminal.** … »
«PRESERVE-BOX: - [ ] **R4** — **Coverage — capsule.** … »
«PRESERVE-BOX: - [ ] **R5** — **`verify` targets resolve.** … »
      (all five, with their full parenthetical evidence bodies, byte for byte)
- [ ] **R6** — **Direction of authority is recorded in this node.** The live
      surface is the source, the manual is derived from it, and a PRD is
      evidence only where it agrees with the surface. This is decision 4
      applied to documentation, and without it the next transcription
      reintroduces the same fiction: R3 already records two entries
      transcribed from the known-invalid `02-terminal` PRDs that match nothing
      live.

## Acceptance
«PRESERVE-BOX: - [ ] Every keybinding defined in the shell, Neovim, and
terminal configs has an entry, confirmed by `04-drift-check`. »
«PRESERVE-BOX: - [ ] No description text exists anywhere else in the repo … »
- [ ] The drift check reports zero undocumented, zero stale, zero mismatched
      across all three surfaces, and no entry claims a live-handle `verify`
      kind for a surface that does not exist on this machine.
- [ ] Reverting one fixed terminal binding makes `help --check` exit
      non-zero.

## Out of scope
- The schema, the file format, the topic spine, the concept entries and the
  writing rules. Those are the parent's, and they close on their own gate.
- Building the drift check — that node comes first, and this one consumes it.
- Changing the entry schema; if the schema is wrong the drift check will have
  said so and this node escalates rather than reshaping it.
- Documenting anything the rebuild has not built yet, other than as `prose`.

## Note on `deps`
«PRESERVE: ## Note on `deps`», with one appended paragraph: *"Resolved
2026-08-21: the parent is `state: open` with R5 `[~]`, which is exactly the
reopened case this note warns about, so the `06-help/01-content-model` edge
has been deleted from `04-drift-check`'s deps. The chain now runs surfaces →
drift-check → coverage → content-model, with no cycle."*
```

### 47 · `06-help/01-content-model` — KEEP (frontmatter and one amendment)

Current: 13 `[x]`, 0 `[ ]`, 1 `[~]`; after: **13 / 0 / 1, unchanged**. This is
the only node on the board with a real implementation to check against, and
its 13 closed boxes carry the most evidence per line of anything here. Nothing
is rewritten. R5 keeps its `[~]` and its full amendment body; the only change
is the frontmatter and one appended clause naming the two adversary passes
that would close it.

```markdown
--- .mi/prd/06-help/01-content-model/prd.md ---
---
state: open
mode: afk
deps: []
priority: 25
verify: "nu tests/help-content-model.nu exits 0"
---

«PRESERVE: the entire file from the `# Content model` title to end of file,
byte for byte — Purpose, R1–R4 and all their nested `[x]` sub-boxes, R5 with
its `[~]` mark and its full "Amended 2026-08-20" body, the `[x]` acceptance
box, `## Children` with its renumbering table, all three `## Evidence` blocks,
`## Findings`, and `## Out of scope`.»

Appended to R5's body, as a new final bullet (the box stays `[~]`):

  - What would close it, named rather than left to care. Two adversary passes,
    each by a reader who did not write the claims, each recording what it
    rejected: (1) the imperative-MOOD check, because the first-word-opener
    heuristic passes all 84 live titles yet lets three constructed escapes
    through at exit 0; (2) the why-restates-use clause, because word
    containment scores the known `Ctrl+V` defect at 0.097 — rank 28 of 51,
    below the corpus mean — so any threshold that catches it fires on over
    half the manual, and no viable mechanical proxy exists. The residual a
    second reader already caught (`terminal.nuon` `[Ctrl+C]`) is fixed in the
    same change. A pass that rejected nothing is not a pass.
```

### 48 · `00-delivery` — REWRITE

Current: 0 / 8 / 0; after: 0 / 9 / 0. `I2` and `I3` become pointers rather
than independent restatements (they have checkable homes now), `b1` moves to
`first-run`. **`## Note on children` is preserved.**

```markdown
--- .mi/prd/00-delivery/prd.md ---
---
state: open
mode: afk
deps: []
priority: 20
verify: ""
---

# Epic: Delivery — the workload plan

«PRESERVE: the Purpose and Goal paragraphs, byte for byte.»

## Requirements

**Execution invariants**

- [ ] **I1** — **A task is one PRD, or a slice of one.** Task IDs are PRD
      paths, so there is never ambiguity about the spec for a task — and a
      node id is an address: renaming or moving one breaks every commit that
      referenced it.
- [ ] **I2** — *pointer.* **One writer per file.** The checkable form of this
      rule lives in [`work-breakdown`](work-breakdown/prd.md) R4, which
      refuses to emit a colliding wave. This line references it and does not
      restate it: the rule is stated three times at three levels today with no
      cross-link, and an ungated copy goes lossy at exactly the clause that
      mattered.
- [ ] **I3** — *pointer.* **Definition of done is executable** — acceptance
      criteria are run, not read. The runner that makes that possible is
      [`verification-gates`](verification-gates/prd.md) R9.
- [ ] **I4** — **Documentation is part of the task, not a phase.** Every task
      that adds a keybinding or command writes its `help` entry in the same
      change, which is what makes
      [`06-help/04-drift-check`](../06-help/04-drift-check/prd.md) able to
      prove completeness. It collides with one-writer-per-file over
      `home/dot_config/nushell/help/*.nuon`; the collision is stated, with
      both candidate resolutions, in
      [`06-help/02-help-command`](../06-help/02-help-command/prd.md)'s
      `## Stated wall`, and is not resolved by this restructure.
- [ ] **I5** — **Correct the spec, don't work around it.** An agent that finds
      the PRD wrong stops and files the correction into
      [`corrections`](corrections/prd.md); it does not implement the wrong
      thing or silently improvise a different one.
- [ ] **I6** — **Every requirement number this board has issued stays
      issued.** A re-homed requirement lands under a fresh number in the
      receiving node and leaves a pointer behind, because commit messages cite
      requirements by number — 28 such citations exist in this repository's
      log today.

## Acceptance
- [ ] The critical path is explicit and computed, and no task sits on it that
      did not have to.
- [ ] Any agent can pick up a task from the breakdown and know its spec, its
      dependencies, its files and how its completion is proven, checked by
      opening three at random and finding all four.
- [ ] Every child is `done` or `out-of-scope`.

## Out of scope
- Re-litigating scope. What gets built is settled by the other epics and the
  README's exclusion list; this epic only orders and parallelizes it.
- Calendar dates. Estimates are in agent-hours and wave positions.
- Managing the human's time. This plans the work, not the person.
- Restating a rule that has a checkable home elsewhere. This node points; the
  owning node enforces.
- Holding schedule state — `plan.json` and the ledger do, and the prose views
  are folds of them.
- Any capability rating. Meta-epics carry no C/U.

## Note on children
«PRESERVE: ## Note on children»
```

### 49 · `.` (board root) — REWRITE

Current: 0 / 5 / 0; after: 0 / 4 / 0. `I2` becomes a pointer, `b1` moves to
`first-run`. `max-workers: 3` is preserved.

```markdown
--- .mi/prd/prd.md ---
---
state: open
mode: afk
deps: []
priority: 10
verify: ""
max-workers: 3
---

# Dotfiles rebuild

Purpose: rebuild the dotfiles as a minimal daily-driver configuration, taking
over only the capabilities a rating says earn their place. The board is the
work surface; [`.mi/gantt/plan.json`](../gantt/plan.json) is the schedule that
orders it, and [`../SYSTEM.md`](../SYSTEM.md) is the working contract. The
numbered epic prefixes order by value ratio, not by build order; the two
disagree and the schedule is the one that binds.

## Requirements
- [ ] **I1** — Every epic child is covered before this node closes.
- [ ] **I2** — *pointer.* One writer per file. Two nodes never name the same
      path in the same wave; the checkable form is
      [`work-breakdown`](00-delivery/work-breakdown/prd.md) R4, which refuses
      to emit a colliding wave.
- [ ] **I3** — Every node that adds a binding, command or alias writes its own
      `help` entry in the same change, so
      [`06-help/04-drift-check`](06-help/04-drift-check/prd.md) can prove
      completeness. **Known conflict, recorded not resolved:** this rule and
      one-writer-per-file cannot both hold over
      `home/dot_config/nushell/help/*.nuon`, whose file set is fixed at five
      shared files by [`06-help/01-content-model`](06-help/01-content-model/prd.md)
      R1, a closed box. Six nodes in the priority-80 tier alone write into it.
      The two candidate resolutions and their costs are stated in
      [`06-help/02-help-command`](06-help/02-help-command/prd.md)'s
      `## Stated wall`. Until one is chosen, this box cannot close and the
      tier is not disjoint.

## Acceptance
- [ ] `help --check` exits 0.

## Out of scope
- Windows, PowerShell, and any drive-letter path abstraction. macOS host only;
  Linux matters only inside capsule containers.
- Everything on the exclusion list in [`README.md`](README.md).
- Restating one-writer-per-file, which now has exactly one checkable home.
- Porting anything because it exists rather than because a rating earned it.
```

### 50–77 · The 28 ABSORB stubs

Each dissolved node keeps its address. Law 1: deletion is not expressible, and
a node id is what commits point at. Each file is rewritten to a redirect stub
with `state: out-of-scope`, zero boxes, and a pointer naming the requirement
its content became. `out-of-scope` is the only word in the lifecycle
vocabulary that means "resolved without a proof", which is what a fold is —
`done` would be a false claim, because nothing was run.

All 28 take this shape:

```markdown
--- .mi/prd/<path>/prd.md ---
---
state: out-of-scope
mode: afk
deps: []
priority: 0
verify: ""
---

# <original title, unchanged>

Purpose: folded into [`<destination>`](<relative path>) on 2026-08-21,
because <the one-line reason>. Its requirements became <the named
requirements there>. This address stays because commits point at it; the
node holds no work.

## Out of scope
- Everything. The boxes that were here are named above and live in the
  destination node. Reopening this node would create a second writer of a
  file that already has one.
```

The 28, with title, destination and the requirement each became:

| Path | Title | Folded into | Became |
|---|---|---|---|
| `00-delivery/parallelization` | Parallelization | `00-delivery/work-breakdown` | R4 (wave/footprint check), R5 (agent count), and the adversarial-verify naming inside R12 |
| `00-delivery/corrections/w0-4-s2-corrections/capsule` | 01-capsule corrections | `00-delivery/corrections/w0-5-capsule-rebase` | R3 (C-3, legacy mount) and R5 (binding owner); both nodes wrote `.mi/prd/01-capsule/` |
| `01-capsule/03-credential-propagation` | Credential propagation into containers | `01-capsule/01-container-lifecycle` | C1 — credentials are flags the mount passes, refreshed on every mount |
| `01-capsule/04-recent-workspaces` | Recent-workspace picker | `01-capsule/01-container-lifecycle` (recency) and `02-terminal/02-startup-layout` (the two keys) | W1 and S6 |
| `02-terminal/04-copy-mode` | Copy Mode | `02-terminal/03-f5-jump-mode` | C1–C5; both are one-shot key tables in the same file region |
| `02-terminal/05-tab-content-state` | Tab content-state coloring | `02-terminal/02-startup-layout` | S2–S5; what creates a tab decides its colour |
| `02-terminal/06-launchd-path` | launchd PATH seeding | `05-platform/03-shell-init-generation` | P1–P3; only that node knows the installed set R2 requires |
| `03-editor/02-keymaps` | Core keymaps | `03-editor/01-options` | K1, K2; same directory, same load phase |
| `03-editor/03-autocmds` | Autocmds | `03-editor/01-options` | A1, A2 |
| `03-editor/04-plugin-manager` | Plugin manager (lazy.nvim) | `03-editor/01-options` | L1; it is `init.lua`, the file that requires the other three in order |
| `03-editor/05-completion` | Completion (blink.cmp) | `03-editor/09-lsp` | C1–C4; it exports the capabilities table LSP consumes |
| `03-editor/06-explorer` | File explorer (oil.nvim) | `03-editor/08-telescope` | E1 |
| `03-editor/07-formatting` | Format on save (conform.nvim) | `03-editor/09-lsp` | F1–F3; its LSP fallback is a contract with the LSP spec |
| `03-editor/10-treesitter` | Treesitter | `03-editor/09-lsp` | T1–T3 |
| `03-editor/12-small-plugins` | Git signs, discovery, autopairs | `03-editor/08-telescope` | G1–G3 |
| `03-editor/13-statusline` | Statusline (lualine) | `03-editor/11-colorscheme` | S1–S3; both derive from one `get_palette()` call |
| `03-editor/15-markdown-tables` | Markdown table mode | `03-editor/08-telescope` | M1 |
| `04-shell/02-aliases-utilities` | Aliases and small utilities | `04-shell/01-core-config` | A1, A2; one line each in the same `config.nu` |
| `04-shell/05-history` | Directory-scoped history | `04-shell/04-television` | H1–H3; a tv picker plus reedline bindings ordered against tv's own init |
| `04-shell/06-listing` | Decorated ls + auto-list | `04-shell/03-zoxide` | LS1–LS4; it hangs off the same single PWD hook |
| `04-shell/07-quicklist` | Quicklist — cross-channel recents | `04-shell/04-television` | Q1–Q3; it reuses the finder's decoder and opener verbatim |
| `04-shell/08-claude-launchers` | Claude launchers (SIMPLIFY) | `04-shell/01-core-config` | CC1 |
| `05-platform/01-deploy-mechanism` | Deploy mechanism | `05-platform/01-deploy-mechanism/repo-skeleton` | R6 (script ordering) and the three acceptance boxes, which were the child's own restated one level up |
| `05-platform/01-deploy-mechanism/managed-config` | Managed config surface + dot_gitconfig.tmpl | `05-platform/01-deploy-mechanism/repo-skeleton` | R2; the managed surface is a table in the layout the skeleton defines |
| `05-platform/02-package-provisioning` | Package provisioning | `05-platform/02-package-provisioning/packages-installer` | the four acceptance boxes, which are the installer's own end-to-end conditions |
| `05-platform/02-package-provisioning/homebrew-bootstrap` | run_once homebrew bootstrap | `05-platform/02-package-provisioning/packages-installer` | R3; four lines in the same script directory |
| `06-help/03-browser` | Fuzzy browser | `06-help/02-help-command` | B1–B3; one content source, many renderers is the epic's own I1 |
| `06-help/05-agent-interface` | Agent interface | `06-help/02-help-command` | AG1–AG3; the JSON field list is only enforceable in one node |

Two notes on this table.

**`05-platform/01-deploy-mechanism` and `02-package-provisioning` are parents
with surviving children.** Setting a parent `out-of-scope` while its child is
open is coherent under §1: the parent is *resolved*, its subtree is *covered*
only when the child closes, and the epic's readiness needs the subtree. No
work is orphaned.

**`04-shell/08-claude-launchers`'s out-of-scope lines travel.** `cl`, `jj` and
the note that `zc` is specced with the zoxide suite are recorded decisions and
appear in `04-shell/01-core-config`'s `## Out of scope`, not only in the stub.
The same holds for `02-terminal/04-copy-mode`'s complements note and
`06-help/03-browser`'s row-format claim, which becomes B1's correction.

---

## The migration map

One row per inventory id. **Every id in the inventory appears in this table
exactly once.** Sorted by destination, then by id.

### The arithmetic

| | count |
|---|---|
| ids in the inventory | **551** |
| — boxes (519 open + 3 stubbed) | 522 |
| — overlap-cluster ids | 14 |
| — dependency-order ids | 10 |
| — unplaced-work ids | 5 |
| ids placed in this table | **551** |
| — absorbed (stay in the node, body rewritten around them) | 304 |
| — merged (moved into another node) | 237 |
| — retired (with quoted evidence) | 10 |
| duplicate ids | **0** |
| ids in the inventory but not in this table | **0** |
| ids in this table but not in the inventory | **0** |
| **lost** | **0** |

Checked mechanically: the id column was extracted, sorted, and compared to the
inventory id list with `comm` in both directions; both difference sets are
empty and `uniq -d` returns nothing.

**And separately, the board's own count.** The board carries 519 open + 3
stubbed = **522** boxes, measured at drafting with
`grep -cE '^[ \t]*- \[[ ~]\]'` across all 77 `prd.md` files. The inventory
carries 522 box ids. **They agree.** The inventory's closed-box aggregate does
not agree with its own per-file table — it says 16 where the table sums to 23,
and 23 is what the tree returns — but no closed box is in scope for this plan
except to be preserved, and all 23 are (7 + 1 + 2 + 13 across four files).

### Departures, per file

Every per-file fall in the box census must be explained by rows below. These
are the files that lose boxes, and the count each loses:

| File | loses | to |
|---|---|---|
| `00-delivery/verification-gates` | 2 ids | `first-run` (its box count rises 13 → 21) |
| `00-delivery` | 1 | `first-run` |
| `.` (root) | 1 | `first-run` |
| `00-delivery/corrections/w0-3-platform-rewrite` | 3 | `delivery` (1), `docs-inventories` (1), `verification-gates` (1); 1 retired |
| `00-delivery/corrections/w0-6-live-bugs` | 2 | `editor` (1); 1 retired |
| `00-delivery/corrections/w0-2-terminal-respec` | 2 | `delivery` (1); 1 retired |
| `00-delivery/corrections/w0-4-s2-corrections/delivery` | 5 | `work-breakdown` (3), `w0-4-s2-corrections` (2) |
| `00-delivery/corrections` | 1 | `decisions` |
| `00-delivery/parallelization` | 3 | `work-breakdown` |
| `00-delivery/decisions/wallpaper-opacity` | 2 | retired (both close `[x]`) |
| `02-terminal/01-appearance` | 2 | retired |
| `04-shell/02-aliases-utilities` | 9 | `01-core-config` (7), `w0-4/shell` (1); 1 retired |
| the 26 other ABSORB stubs | all | their destination in the stub table above |

Every other file's counts hold or rise.

| id | old node | where it goes | merged-with | kind |
|---|---|---|---|---|
| `root-b2` | `.` | `.` | — | reworded |
| `root-i1` | `.` | `.` | — | reworded |
| `root-i3` | `.` | `.` | — | reworded |
| `00-delivery-b2` | `00-delivery` | `00-delivery` | — | reworded |
| `00-delivery-b3` | `00-delivery` | `00-delivery` | — | reworded |
| `00-delivery-i1` | `00-delivery` | `00-delivery` | — | reworded |
| `00-delivery-i4` | `00-delivery` | `00-delivery` | — | reworded |
| `00-delivery-i5` | `00-delivery` | `00-delivery` | — | reworded |
| `corrections-b1` | `00-delivery/corrections` | `00-delivery/corrections` | — | reworded |
| `corrections-b3` | `00-delivery/corrections` | `00-delivery/corrections` | — | reworded |
| `corrections-b4` | `00-delivery/corrections` | `00-delivery/corrections` | — | reworded |
| `terminal-prerespec-vs-corrections` | `00-delivery/corrections/w0-2-terminal-respec (cluster)` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-b1` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-b2` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-r1` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-r2` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-r3` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-r4` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-2-terminal-respec-r5` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | — | reworded |
| `w0-6-l11` | `00-delivery/corrections/w0-6-live-bugs (unplaced)` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-2-terminal-respec` | reworded |
| `cycle-w03-w04ag` | `00-delivery/corrections/w0-3-platform-rewrite (dep)` | `00-delivery/corrections/w0-3-platform-rewrite` | — | reworded |
| `hardest-edge-w03` | `00-delivery/corrections/w0-3-platform-rewrite (dep)` | `00-delivery/corrections/w0-3-platform-rewrite` | — | reworded |
| `delivery-r5` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections` | `00-delivery/corrections/w0-4-s2-corrections` | reworded |
| `delivery-r6` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections` | `00-delivery/corrections/w0-4-s2-corrections` | reworded |
| `w0-4-s2-corrections-b1` | `00-delivery/corrections/w0-4-s2-corrections` | `00-delivery/corrections/w0-4-s2-corrections` | — | reworded |
| `w04-parent-subsumption` | `00-delivery/corrections/w0-4-s2-corrections (cluster)` | `00-delivery/corrections/w0-4-s2-corrections` | `00-delivery/corrections/w0-4-s2-corrections` | reworded |
| `delivery-b1` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | — | reworded |
| `delivery-r4` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | — | reworded |
| `w0-2-terminal-respec-b3` | `00-delivery/corrections/w0-2-terminal-respec` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | reworded |
| `w0-3-platform-rewrite-r2` | `00-delivery/corrections/w0-3-platform-rewrite` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | reworded |
| `docs-inventories-b1` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `docs-inventories-r1` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `docs-inventories-r2` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `docs-inventories-r3` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `docs-inventories-r4` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `docs-inventories-r5` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | — | reworded |
| `w0-3-platform-rewrite-r3` | `00-delivery/corrections/w0-3-platform-rewrite` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | `00-delivery/corrections/w0-4-s2-corrections/docs-inventories` | reworded |
| `autocmds-onyank-vs-m3-fix` | `03-editor/03-autocmds (cluster)` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `editor-b1` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `editor-r1` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `editor-r2` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `editor-r3` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `editor-r4` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `editor-r5` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | — | reworded |
| `grouping-gap-treesitter-shiftselect` | `00-delivery/corrections/w0-4-s2-corrections/editor (cluster)` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `smallplugins-glyph-vs-l10-fix` | `03-editor/12-small-plugins (cluster)` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `w0-6-l7` | `00-delivery/corrections/w0-6-live-bugs (unplaced)` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `w0-6-l9` | `00-delivery/corrections/w0-6-live-bugs (unplaced)` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `w0-6-live-bugs-r3` | `00-delivery/corrections/w0-6-live-bugs` | `00-delivery/corrections/w0-4-s2-corrections/editor` | `00-delivery/corrections/w0-4-s2-corrections/editor` | reworded |
| `help-b1` | `00-delivery/corrections/w0-4-s2-corrections/help` | `00-delivery/corrections/w0-4-s2-corrections/help` | — | verbatim |
| `help-r1` | `00-delivery/corrections/w0-4-s2-corrections/help` | `00-delivery/corrections/w0-4-s2-corrections/help` | — | verbatim |
| `help-r2` | `00-delivery/corrections/w0-4-s2-corrections/help` | `00-delivery/corrections/w0-4-s2-corrections/help` | — | verbatim |
| `help-r3` | `00-delivery/corrections/w0-4-s2-corrections/help` | `00-delivery/corrections/w0-4-s2-corrections/help` | — | verbatim |
| `help-r4` | `00-delivery/corrections/w0-4-s2-corrections/help` | `00-delivery/corrections/w0-4-s2-corrections/help` | — | verbatim |
| `packages-r7-burrito-vs-correction` | `05-platform/02-package-provisioning/packages-installer (cluster)` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | reworded |
| `platform-b1` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | — | reworded |
| `platform-r1` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | — | reworded |
| `platform-r2` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | — | reworded |
| `platform-r3` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | — | reworded |
| `w0-6-l12` | `00-delivery/corrections/w0-6-live-bugs (unplaced)` | `00-delivery/corrections/w0-4-s2-corrections/platform` | `00-delivery/corrections/w0-4-s2-corrections/platform` | reworded |
| `02-aliases-utilities-r4` | `04-shell/02-aliases-utilities` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | reworded |
| `shell-b1` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r1` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r2` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r3` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r4` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r5` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell-r6` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | — | reworded |
| `shell02-r4-burrito-vs-correction` | `04-shell/02-aliases-utilities (cluster)` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | reworded |
| `w0-6-l2` | `00-delivery/corrections/w0-6-live-bugs (unplaced)` | `00-delivery/corrections/w0-4-s2-corrections/shell` | `00-delivery/corrections/w0-4-s2-corrections/shell` | reworded |
| `capsule-b1` | `00-delivery/corrections/w0-4-s2-corrections/capsule` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | reworded |
| `capsule-r1` | `00-delivery/corrections/w0-4-s2-corrections/capsule` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | reworded |
| `capsule-r2` | `00-delivery/corrections/w0-4-s2-corrections/capsule` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | reworded |
| `w0-5-capsule-rebase-b1` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-b2` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-b3` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-r1` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-r2` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-r3` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-r4` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `w0-5-capsule-rebase-r5` | `00-delivery/corrections/w0-5-capsule-rebase` | `00-delivery/corrections/w0-5-capsule-rebase` | — | reworded |
| `chain-w06-gates-hitl-decisions` | `00-delivery/decisions/tinty (dep)` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `cycle-w06-w04-children` | `00-delivery/corrections/w0-6-live-bugs (dep)` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `livebugs-routing-vs-actual-fixes` | `00-delivery/corrections/w0-6-live-bugs (cluster)` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `w0-6-live-bugs-b1` | `00-delivery/corrections/w0-6-live-bugs` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `w0-6-live-bugs-b2` | `00-delivery/corrections/w0-6-live-bugs` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `w0-6-live-bugs-r4` | `00-delivery/corrections/w0-6-live-bugs` | `00-delivery/corrections/w0-6-live-bugs` | — | reworded |
| `backlog-decisions-bullet-stale-vs-nodes` | `00-delivery/corrections (cluster)` | `00-delivery/decisions` | `00-delivery/decisions` | reworded |
| `corrections-b2` | `00-delivery/corrections` | `00-delivery/decisions` | `00-delivery/decisions` | reworded |
| `decisions-b1` | `00-delivery/decisions` | `00-delivery/decisions` | — | reworded |
| `decisions-parent-subsumption` | `00-delivery/decisions (cluster)` | `00-delivery/decisions` | `00-delivery/decisions` | reworded |
| `fzf-b1` | `00-delivery/decisions/fzf` | `00-delivery/decisions/fzf` | — | reworded |
| `fzf-b2` | `00-delivery/decisions/fzf` | `00-delivery/decisions/fzf` | — | reworded |
| `fzf-triple-mention` | `00-delivery/decisions/fzf (cluster)` | `00-delivery/decisions/fzf` | `00-delivery/decisions/fzf` | reworded |
| `odin-toolchain-b1` | `00-delivery/decisions/odin-toolchain` | `00-delivery/decisions/odin-toolchain` | — | reworded |
| `odin-toolchain-b2` | `00-delivery/decisions/odin-toolchain` | `00-delivery/decisions/odin-toolchain` | — | reworded |
| `shift-select-scope-b1` | `00-delivery/decisions/shift-select-scope` | `00-delivery/decisions/shift-select-scope` | — | verbatim |
| `shift-select-scope-b2` | `00-delivery/decisions/shift-select-scope` | `00-delivery/decisions/shift-select-scope` | — | verbatim |
| `tinty-b1` | `00-delivery/decisions/tinty` | `00-delivery/decisions/tinty` | — | reworded |
| `tinty-b2` | `00-delivery/decisions/tinty` | `00-delivery/decisions/tinty` | — | reworded |
| `00-delivery-b1` | `00-delivery` | `00-delivery/first-run` | `00-delivery/first-run` | reworded |
| `root-b1` | `.` | `00-delivery/first-run` | `00-delivery/first-run` | reworded |
| `verification-gates-b6` | `00-delivery/verification-gates` | `00-delivery/first-run` | — | reworded |
| `verification-gates-r7` | `00-delivery/verification-gates` | `00-delivery/first-run` | — | reworded |
| `00-delivery-i3` | `00-delivery` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | reworded |
| `verification-gates-b1` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-b2` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-b3` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-b4` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-b5` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r1` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r2` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r3` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r4` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r5` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `verification-gates-r6` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | — | reworded |
| `w0-3-platform-rewrite-b2` | `00-delivery/corrections/w0-3-platform-rewrite` | `00-delivery/verification-gates` | `00-delivery/verification-gates` | reworded |
| `00-delivery-i2` | `00-delivery` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `delivery-r1` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `delivery-r2` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `delivery-r3` | `00-delivery/corrections/w0-4-s2-corrections/delivery` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `missing-edge-gates-capsule` | `01-capsule/03-credential-propagation (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `missing-edge-gates-quicklist` | `04-shell/07-quicklist (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `onewriter-triplicate` | `00-delivery/parallelization (cluster)` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `parallelization-b1` | `00-delivery/parallelization` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `parallelization-b2` | `00-delivery/parallelization` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `parallelization-b3` | `00-delivery/parallelization` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `priority-contradiction-help-epic` | `06-help/01-content-model (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `priority-contradiction-terminal-epic` | `02-terminal/01-appearance (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `priority-nonuniform-w0-subtasks` | `00-delivery/corrections/w0-4-s2-corrections (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `root-i2` | `.` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | reworded |
| `sequencing-help-coverage-invisible` | `06-help/01-content-model/coverage (dep)` | `00-delivery/work-breakdown` | — | reworded |
| `work-breakdown-b1` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | — | reworded |
| `work-breakdown-b2` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | — | reworded |
| `work-breakdown-b3` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | — | reworded |
| `work-breakdown-b4` | `00-delivery/work-breakdown` | `00-delivery/work-breakdown` | — | reworded |
| `01-capsule-b1` | `01-capsule` | `01-capsule` | — | reworded |
| `01-capsule-b2` | `01-capsule` | `01-capsule` | — | reworded |
| `01-capsule-b3` | `01-capsule` | `01-capsule` | — | reworded |
| `01-container-lifecycle-b1` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-b2` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-b3` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-b4` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r1` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r2` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r3` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r4` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r5` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r6` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `01-container-lifecycle-r7` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | — | reworded |
| `03-credential-propagation-b1` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-b2` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-b3` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-r1` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-r2` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-r3` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-r4` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `03-credential-propagation-r5` | `01-capsule/03-credential-propagation` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-b1` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-b2` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-r1` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-r2` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-r3` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `04-recent-workspaces-r4` | `01-capsule/04-recent-workspaces` | `01-capsule/01-container-lifecycle` | `01-capsule/01-container-lifecycle` | reworded |
| `02-dev-image-b1` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-b2` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-b3` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r1` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r2` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r3` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r4` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r5` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `02-dev-image-r6` | `01-capsule/02-dev-image` | `01-capsule/02-dev-image` | — | reworded |
| `01-appearance-b1` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `01-appearance-b2` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `01-appearance-b4` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `01-appearance-b5` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | — | reworded |
| `01-appearance-r1` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `01-appearance-r3` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `01-appearance-r4` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | `02-terminal/01-appearance` | reworded |
| `02-startup-layout-b1` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | — | reworded |
| `02-startup-layout-b2` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | — | reworded |
| `02-startup-layout-r1` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | — | reworded |
| `02-startup-layout-r2` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | — | reworded |
| `02-startup-layout-r3` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | — | reworded |
| `05-tab-content-state-b1` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b2` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b3` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b4` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b5` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b6` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-b7` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-r1` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-r2` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-r3` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-r4` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `05-tab-content-state-r5` | `02-terminal/05-tab-content-state` | `02-terminal/02-startup-layout` | `02-terminal/02-startup-layout` | reworded |
| `03-f5-jump-mode-b1` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-b2` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-b3` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-r1` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-r2` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-r3` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `03-f5-jump-mode-r4` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | — | reworded |
| `04-copy-mode-b1` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-b2` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-b3` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-b4` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-b5` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-b6` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-r1` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-r2` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-r3` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-r4` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `04-copy-mode-r5` | `02-terminal/04-copy-mode` | `02-terminal/03-f5-jump-mode` | `02-terminal/03-f5-jump-mode` | reworded |
| `03-editor-b1` | `03-editor` | `03-editor` | — | reworded |
| `03-editor-i1` | `03-editor` | `03-editor` | — | reworded |
| `03-editor-i2` | `03-editor` | `03-editor` | — | reworded |
| `03-editor-i3` | `03-editor` | `03-editor` | — | reworded |
| `03-editor-i4` | `03-editor` | `03-editor` | — | reworded |
| `03-editor-i5` | `03-editor` | `03-editor` | — | reworded |
| `01-options-b1` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-b2` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-b3` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-b4` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r1` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r10` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r11` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r12` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r2` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r3` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r4` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r5` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r6` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r7` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r8` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `01-options-r9` | `03-editor/01-options` | `03-editor/01-options` | — | reworded |
| `02-keymaps-b1` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-b2` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-b3` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r1` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r2` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r3` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r4` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r5` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r6` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r7` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `02-keymaps-r8` | `03-editor/02-keymaps` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-b1` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-b2` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-b3` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-b4` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-r1` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-r2` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-r3` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `03-autocmds-r4` | `03-editor/03-autocmds` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-b1` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-b2` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-b3` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r1` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r2` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r3` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r4` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r5` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r6` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r7` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `04-plugin-manager-r8` | `03-editor/04-plugin-manager` | `03-editor/01-options` | `03-editor/01-options` | reworded |
| `06-explorer-b1` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `06-explorer-b2` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `06-explorer-b3` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `06-explorer-r1` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `06-explorer-r2` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `06-explorer-r3` | `03-editor/06-explorer` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `08-telescope-b1` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-b2` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-b3` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-r1` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-r2` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-r3` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-r4` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `08-telescope-r5` | `03-editor/08-telescope` | `03-editor/08-telescope` | — | reworded |
| `12-small-plugins-b1` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `12-small-plugins-b2` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `12-small-plugins-b3` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `12-small-plugins-r1` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `12-small-plugins-r2` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `12-small-plugins-r3` | `03-editor/12-small-plugins` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-b1` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-b2` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-r1` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-r2` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-r3` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `15-markdown-tables-r4` | `03-editor/15-markdown-tables` | `03-editor/08-telescope` | `03-editor/08-telescope` | reworded |
| `05-completion-b1` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-b2` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-b3` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r1` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r2` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r3` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r4` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r5` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r6` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r7` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r8` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `05-completion-r9` | `03-editor/05-completion` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-b1` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-b2` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-b3` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-r1` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-r2` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-r3` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-r4` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `07-formatting-r5` | `03-editor/07-formatting` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `09-lsp-b1` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-b2` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-b3` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r1` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r2` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r3` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r4` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r5` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `09-lsp-r6` | `03-editor/09-lsp` | `03-editor/09-lsp` | — | reworded |
| `10-treesitter-b1` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-b2` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-b3` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-r1` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-r2` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-r3` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `10-treesitter-r4` | `03-editor/10-treesitter` | `03-editor/09-lsp` | `03-editor/09-lsp` | reworded |
| `11-colorscheme-b1` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-b2` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-b3` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r1` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r2` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r3` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r4` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r5` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `11-colorscheme-r6` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | — | reworded |
| `13-statusline-b1` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-b2` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-b3` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r1` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r2` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r3` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r4` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r5` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `13-statusline-r6` | `03-editor/13-statusline` | `03-editor/11-colorscheme` | `03-editor/11-colorscheme` | reworded |
| `14-shift-select-b1` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-b2` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-b3` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-b4` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-b5` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r1` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r2` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r3` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r4` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r5` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r6` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r7` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `14-shift-select-r8` | `03-editor/14-shift-select` | `03-editor/14-shift-select` | — | reworded |
| `04-shell-i1` | `04-shell` | `04-shell` | — | reworded |
| `04-shell-i2` | `04-shell` | `04-shell` | — | reworded |
| `04-shell-i3` | `04-shell` | `04-shell` | — | reworded |
| `04-shell-i4` | `04-shell` | `04-shell` | — | reworded |
| `01-core-config-b1` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-b2` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-b3` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-b4` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r1` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r2` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r3` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r4` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r5` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r6` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r7` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r8` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `01-core-config-r9` | `04-shell/01-core-config` | `04-shell/01-core-config` | — | reworded |
| `02-aliases-utilities-b2` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-b3` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-r1` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-r2` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-r3` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-r5` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `02-aliases-utilities-r6` | `04-shell/02-aliases-utilities` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `08-claude-launchers-b1` | `04-shell/08-claude-launchers` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `08-claude-launchers-b2` | `04-shell/08-claude-launchers` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `08-claude-launchers-r1` | `04-shell/08-claude-launchers` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `08-claude-launchers-r2` | `04-shell/08-claude-launchers` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `08-claude-launchers-r3` | `04-shell/08-claude-launchers` | `04-shell/01-core-config` | `04-shell/01-core-config` | reworded |
| `03-zoxide-b1` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-b2` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-b3` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r1` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r2` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r3` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r4` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r5` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r6` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `03-zoxide-r7` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | — | reworded |
| `06-listing-b1` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-b2` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-r1` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-r2` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-r3` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-r4` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `06-listing-r5` | `04-shell/06-listing` | `04-shell/03-zoxide` | `04-shell/03-zoxide` | reworded |
| `04-television-b1` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-b2` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-b3` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-b4` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-b5` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-b6` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r1` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r2` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r3` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r4` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r5` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r6` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `04-television-r7` | `04-shell/04-television` | `04-shell/04-television` | — | reworded |
| `05-history-b1` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-b2` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-r1` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-r2` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-r3` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-r4` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-history-r5` | `04-shell/05-history` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-b1` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-b2` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-b3` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-b4` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-r1` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-r2` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-r3` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `07-quicklist-r4` | `04-shell/07-quicklist` | `04-shell/04-television` | `04-shell/04-television` | reworded |
| `05-platform-i1` | `05-platform` | `05-platform` | — | reworded |
| `05-platform-i2` | `05-platform` | `05-platform` | — | reworded |
| `05-platform-i3` | `05-platform` | `05-platform` | — | reworded |
| `05-platform-i4` | `05-platform` | `05-platform` | — | reworded |
| `01-deploy-mechanism-b1` | `05-platform/01-deploy-mechanism` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `01-deploy-mechanism-b2` | `05-platform/01-deploy-mechanism` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `01-deploy-mechanism-b3` | `05-platform/01-deploy-mechanism` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `01-deploy-mechanism-r6` | `05-platform/01-deploy-mechanism` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `managed-config-b1` | `05-platform/01-deploy-mechanism/managed-config` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `managed-config-r2` | `05-platform/01-deploy-mechanism/managed-config` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | reworded |
| `repo-skeleton-b1` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | — | reworded |
| `repo-skeleton-r1` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | — | reworded |
| `repo-skeleton-r3` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | — | reworded |
| `repo-skeleton-r5` | `05-platform/01-deploy-mechanism/repo-skeleton` | `05-platform/01-deploy-mechanism/repo-skeleton` | — | reworded |
| `02-package-provisioning-b1` | `05-platform/02-package-provisioning` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `02-package-provisioning-b2` | `05-platform/02-package-provisioning` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `02-package-provisioning-b3` | `05-platform/02-package-provisioning` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `02-package-provisioning-b4` | `05-platform/02-package-provisioning` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `homebrew-bootstrap-b1` | `05-platform/02-package-provisioning/homebrew-bootstrap` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `homebrew-bootstrap-r3` | `05-platform/02-package-provisioning/homebrew-bootstrap` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | reworded |
| `packages-installer-b1` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r1` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r2` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r4` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r5` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r6` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `packages-installer-r7` | `05-platform/02-package-provisioning/packages-installer` | `05-platform/02-package-provisioning/packages-installer` | — | reworded |
| `03-shell-init-generation-b1` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-b2` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-b3` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-b4` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-r1` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-r2` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-r3` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-r4` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `03-shell-init-generation-r5` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | — | reworded |
| `06-launchd-path-b1` | `02-terminal/06-launchd-path` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | reworded |
| `06-launchd-path-b2` | `02-terminal/06-launchd-path` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | reworded |
| `06-launchd-path-r1` | `02-terminal/06-launchd-path` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | reworded |
| `06-launchd-path-r2` | `02-terminal/06-launchd-path` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | reworded |
| `06-launchd-path-r3` | `02-terminal/06-launchd-path` | `05-platform/03-shell-init-generation` | `05-platform/03-shell-init-generation` | reworded |
| `06-help-b1` | `06-help` | `06-help` | — | reworded |
| `06-help-b2` | `06-help` | `06-help` | — | reworded |
| `06-help-b3` | `06-help` | `06-help` | — | reworded |
| `06-help-i1` | `06-help` | `06-help` | — | reworded |
| `06-help-i2` | `06-help` | `06-help` | — | reworded |
| `06-help-i3` | `06-help` | `06-help` | — | reworded |
| `06-help-i4` | `06-help` | `06-help` | — | reworded |
| `01-content-model-r5` | `06-help/01-content-model` | `06-help/01-content-model` | — | verbatim |
| `coverage-b1` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-b2` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-r1` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-r2` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-r3` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-r4` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `coverage-r5` | `06-help/01-content-model/coverage` | `06-help/01-content-model/coverage` | — | verbatim |
| `02-help-command-b1` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-b2` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-b3` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-b4` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-b5` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-b6` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r1` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r2` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r3` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r4` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r5` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r6` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r7` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r8` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `02-help-command-r9` | `06-help/02-help-command` | `06-help/02-help-command` | — | reworded |
| `03-browser-b1` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-b2` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-b3` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-r1` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-r2` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-r3` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-r4` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `03-browser-r5` | `06-help/03-browser` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b1` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b2` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b3` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b4` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b5` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b6` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-b7` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r1` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r2` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r3` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r4` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r5` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `05-agent-interface-r6` | `06-help/05-agent-interface` | `06-help/02-help-command` | `06-help/02-help-command` | reworded |
| `04-drift-check-b1` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b2` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b3` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b4` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b5` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b6` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-b7` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r1` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r2` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r3` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r4` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r5` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r6` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r7` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `04-drift-check-r8` | `06-help/04-drift-check` | `06-help/04-drift-check` | — | reworded |
| `01-appearance-b3` | `02-terminal/01-appearance` | **RETIRED** | — | retired |
| `01-appearance-r2` | `02-terminal/01-appearance` | **RETIRED** | — | retired |
| `02-aliases-utilities-b1` | `04-shell/02-aliases-utilities` | **RETIRED** | — | retired |
| `m17-already-fixed-but-still-tracked` | `03-editor/prd.md (cluster)` | **RETIRED** | — | retired |
| `shell02-rr-literal-dup` | `04-shell/02-aliases-utilities (cluster)` | **RETIRED** | — | retired |
| `w0-2-terminal-respec-r6` | `00-delivery/corrections/w0-2-terminal-respec` | **RETIRED** | — | retired |
| `w0-3-platform-rewrite-b1` | `00-delivery/corrections/w0-3-platform-rewrite` | **RETIRED** | — | retired |
| `w0-6-live-bugs-r2` | `00-delivery/corrections/w0-6-live-bugs` | **RETIRED** | — | retired |
| `wallpaper-opacity-b1` | `00-delivery/decisions/wallpaper-opacity` | **RETIRED** | — | retired |
| `wallpaper-opacity-b2` | `00-delivery/decisions/wallpaper-opacity` | **RETIRED** | — | retired |

---

## What is deliberately not done

**No closed node is touched.**
`00-delivery/corrections/w0-1-terminal-inventory` is `state: done` with all
seven boxes `[x]` and is not re-planned, renamed, moved or reworded. Its
output, `.mi/docs/capabilities-terminal.md`, is the input W0.2 rewrites the
terminal epic from, and this plan cites it rather than re-deriving it. No
node is proposed for REOPEN: no surviving finding of severity `lie` was
produced, so there is nothing to quote.

**No node is under a live claim, and this was re-checked rather than
inherited.** The constraint handed to the planner — "nodes under a live claim,
untouchable" — arrived once as a list naming all 77 nodes, which is the
census's title column mis-rendered, and once as `(none)`. Taken literally the
first form forbids every plan, including doing nothing; taken as intended it
forbids none, and the difference is the whole apply. Measured at `de38255`:
`grep -rn '^claim:' .mi/prd --include=prd.md` returns **nothing**,
`grep -rn '^state: claimed' .mi/prd --include=prd.md` returns **nothing**, and
the board root's frontmatter carries no `claim:` field — so **no node is
claimed and constraint 3 binds nothing here.** An applier must re-run both
greps immediately before step 2a and stop if either returns a line: a claim
taken between this drafting and the apply is a lock this document cannot see,
and the node it names must be read, left untouched, and appear in no apply
commit. This is recorded as a check the applier owns, not as a fact this plan
can vouch for at apply time.

**No node id is renamed or moved.** Every one of the 77 existing addresses
survives — 49 as working nodes, 28 as `out-of-scope` redirect stubs. One
address is new (`00-delivery/first-run`) because the work is genuinely new.
Renaming or moving a node breaks every commit that referenced it, and the
board's history has 28 such references.

**No requirement number is reused, and thirteen are deliberately spent.** They
stay in `## Requirements` as non-box pointer lines and are never reassigned:
`w0-3-platform-rewrite` R2, R3 · `w0-6-live-bugs` R2, R3 ·
`w0-2-terminal-respec` R6, R8, R9 · `w0-4-s2-corrections/delivery` R1, R2, R3,
R5, R6 · `02-terminal/01-appearance` R2. Thirteen, not eleven: R8 and R9 were
added to the spent list when the `w0-2-terminal-respec` /
`02-terminal/01-appearance` double-write was cut, and the count is restated
here rather than left at its drafting value. Every new box in this document
takes the next free integer above the highest number its node has ever used,
so a vacated number stays a gap and the 28 existing commit-message citations
still resolve to what they meant.

**The `.mi/workflows/` tree is not touched.** It is mid-migration with
uncommitted changes (`lib/` deleted, scripts moved to the root) and was
declared out of scope. This plan reports one finding about it and proposes no
edit: `plan.json` is internally consistent — 63 tasks, no duplicate ids, no
dangling deps, and no `T.5` — while the last run reported 44 tasks, listed a
`T.5`, omitted `T.7` and the whole `W0.4a`–`W0.4g` fan-out, and dispatched a
task it called `T.2` against the node `plan.json` calls `T.1`. **The defect is
in the runner, not in the plan record.** `00-delivery/work-breakdown` R1 and
its acceptance establish that mechanically rather than assuming it; repairing
the runner is somebody else's node.

**None of the five hitl decisions is answered, wallpaper/opacity included.**
They are `mode: hitl` and this plan neither answers them nor guesses. An
earlier draft of this document closed `decisions/wallpaper-opacity` as met
against the README exclusion list and set it `state: done`; **that close is
withdrawn**, and the reason is recorded in
[block 13](#13--00-deliverydecisionswallpaper-opacity--narrowed-and-it-stays-open)
rather than dropped. The README refuses a wallpaper *cycler* and defers an
interactive opacity *picker*; the node decides the static
`window_background_opacity` value (live: `0.95`, with
`macos_window_background_blur = 30`) and the base00 tint. Those are different
questions, and closing a fork against evidence for a narrower one is the false
record §6 forbids. What the lookup does settle is the binding half — the
cycler is `DO NOT PORT`, so `Ctrl+Shift+B` is free for `capsule --rebuild`
immediately — and the node stays `open`, `hitl`, both boxes `[ ]`, narrowed to
one question so the human round-trip is cheap.

**No box is marked `[x]` against text a later step of this apply writes.**
The withdrawn close also carried that defect: its second box was `[x]` on the
strength of `02-terminal/01-appearance`'s `## Out of scope` naming the cycler
and the toggle, while at that commit the section still read the boilerplate
line and step 2f — three commit groups later — was what would write it. A
close whose evidence does not exist yet at the commit that claims it is not a
close, and the rule is general: an applier that finds itself citing text from
a later step must leave the box open.

**Nothing is implemented.** No source file is edited by anyone in this
workflow, and this document is the only file written.

**One thing I could not fix, and the honest form it takes instead.** There is
no runnable per-node gate on this repo today, and no amount of planning
manufactures one. An earlier draft papered over that by giving 45 nodes
`verify: node .mi/workflows/mi-reconcile.js`; re-profiled 2026-08-21, all six
workflow scripts exit **1** with `SyntaxError: Illegal return statement`,
because they are harness modules the dispatcher loads and not programs — so
that field would have made every node it touched permanently uncloseable under
§6, which is the opposite of this plan's purpose. It is removed everywhere; no
block in this document names any of the six.

What replaces it is not a better command but an honest empty field. Five
nodes carry a `verify:` that names something which exists and exits 0 today,
measured: `bash tests/live-bugs.sh` on `w0-6-live-bugs`,
`nu tests/help-content-model.nu` on `06-help/01-content-model`,
`help --check exits 0` on `06-help/04-drift-check` (pre-existing prose, not a
command, and left as found), `nvim --headless '+Lazy! sync' +qa exits 0`
carried onto `03-editor/01-options` with `04-plugin-manager`'s absorbed
content, and `chezmoi apply on a scratch target is idempotent…` kept verbatim
on `repo-skeleton`. The last two are **carried forward rather than regressed
away** — an earlier draft replaced two working checks with the broken one, and
that is repaired. Every other node takes **`verify: ""`**, the format's own
word for unproven, plus the `**Gate.**` paragraph in its body naming the
per-surface gate it will adopt and the commit at which it may. Until
`tests/gates.sh` lands, the real proofs live in the acceptance boxes — `wezterm
--config-file … ls-fonts`, `nvim --headless`, `chezmoi apply` twice, `nu -l -c`
— run by hand and recorded. That is why the gate runner is priority 100 and
first: it is the only node on the board whose output turns those boxes into
something a machine can judge.

---

## The first ready set

Applied on top of `de38255`, these become ready immediately — `open`, `afk`,
unclaimed, no `## Escalation`, every child covered. The board root's
`max-workers` is 3, so the runner takes the first three by priority then
depth; the fourth waits one slot.

| Node | Priority | Source directories it owns |
|---|---|---|
| `00-delivery/verification-gates` | 100 | `tests/gates/`, `tests/gates.sh` |
| `00-delivery/work-breakdown` | 100 | `.mi/gantt/`, `.mi/docs/delivery-gantt.md` |
| `00-delivery/corrections/w0-3-platform-rewrite` | 100 | `.mi/prd/00-delivery/corrections/w0-3-platform-rewrite/` |
| `00-delivery/corrections/w0-6-live-bugs` | 100 | `.mi/prd/00-delivery/corrections/w0-6-live-bugs/`, `tests/live-bugs.sh` |
| `00-delivery/corrections/w0-2-terminal-respec` | 95 | `.mi/prd/02-terminal/` |

**They do not collide, and two collisions an earlier draft had here are cut
rather than argued away.** `tests/gates/` and `tests/gates.sh` versus
`tests/live-bugs.sh` are distinct paths under a shared parent, not a shared
file — declare footprints at file granularity there and the collision check is
clean; `verification-gates` R13 registers `tests/live-bugs.sh` and is
forbidden from editing it, which is why registration is not a second writer.
Everything else is a distinct directory. The two nodes that could have
collided under the winner's original tiering — `w0-4-s2-corrections` with
`.mi/prd/` nesting `.mi/prd/00-delivery/corrections/` — are separated into
tiers 90 and 88 for exactly that reason.

The two that are cut, both at p100, both stated because an earlier draft of
this document asserted non-collision while its own node text refuted it:

- **`.mi/gantt/plan.json`.** `verification-gates` R11 used to end "and the
  edges to this node are written into `plan.json`", which is
  `work-breakdown`'s declared footprint. The clause is deleted; the edges are
  `work-breakdown` **R6**, and R11 now says in its own text that this node
  writes nothing under `.mi/gantt/`.
- **`.mi/prd/04-shell/` and `.mi/prd/01-capsule/`.** R11 also used to require
  `verification-gates` to replace the two wave-numbered `verify:` strings in
  files owned by `w0-4-s2-corrections/shell` and `w0-5-capsule-rebase`, both
  downstream of it — the write-a-file-your-own-downstream-task-owns deadlock
  that walled W0.3 and W0.6, rebuilt at the top of the frontier by the plan
  that exists to cut it. R11 now **decides the replacement form and names the
  two owners**; those two lanes make the edit under their own R9 and R6, and
  `verification-gates`' acceptance box says so explicitly.

**The p80 tier is not disjoint, and that is a stated wall rather than a
claim.** Six p80 nodes write `home/dot_config/nushell/help/` under root I3
while a closed box fixes that surface at five files. It is unresolved, it is
written into `06-help/02-help-command`'s body, and it is the one place where
"the tier is the width" does not hold. It does not affect this first ready
set, which is entirely `00-delivery` nodes with no help entries between them.

**In parallel, needing no agent slot at all:** the four `hitl` decisions
(`tinty`, `fzf`, `shift-select-scope`, `odin-toolchain`), asked as one
numbered round with a recommendation each. They have no `deps` after this
plan; today three of them are gated behind `w0-6-live-bugs`, an afk node stuck
in a footprint deadlock, so three human-answerable questions are not being
asked at all.

**Why W0.3 and W0.6 are ready and are not today:** each currently carries an
`## Escalation`, which takes a node off the work surface under §2 and adds 1
to what it owes under §1. The apply folds both sections into `## Findings`
with every byte intact, which is the move the protocol calls "fold in the
escalation" — not a deletion, and not a workaround.

**The tier after that is eight wide and one directory each:**
`w0-4-s2-corrections/{editor,shell,platform,docs-inventories,help,delivery}`,
`w0-5-capsule-rebase`, and `w0-2-terminal-respec` — `.mi/prd/03-editor/`,
`04-shell/`, `05-platform/`, `06-help/`, `.mi/docs/`, `.mi/prd/README.md`,
`.mi/prd/01-capsule/`, `.mi/prd/02-terminal/`. Eight disjoint directories
against a cap of 3 is slack, which is the point: the cap becomes the
constraint rather than the board.

---

## How to apply it

**Step 0, before anything else: verify HEAD.**

```
test "$(git rev-parse HEAD)" = de3825547380fbde62ff74dc0dd99278dbbefa41 \
  || { echo "HEAD moved — re-inventory before applying"; exit 1; }
git status --porcelain -- .mi/prd    # must be empty
```

A plan is a statement about a tree at a moment, and it goes stale in the one
direction nobody checks. If HEAD has moved, re-run the census and the
migration map against the new tree before touching a file.

**Step 1: take the box census.**

```
for f in $(find .mi/prd -name prd.md | sort); do
  printf '%s\tx=%s\topen=%s\tstub=%s\n' "$f" \
    "$(grep -cE '^[ \t]*- \[x\]' "$f")" "$(grep -cE '^[ \t]*- \[ \]' "$f")" \
    "$(grep -cE '^[ \t]*- \[~\]' "$f")"
done > /tmp/boxes.before
git log --format=%s%n%b | grep -nE 'requirement [0-9]|\bR[0-9]+\b' > /tmp/cites.before
```

Expected: 519 open, 3 stubbed, 23 closed, 77 files, 28 citations.

**Step 2: one node per commit, in an order where the tree is never broken.**
The order below never leaves a link pointing at a node that does not yet hold
what the link claims, and never leaves a requirement re-homed with no
destination. Commit messages follow the board's own convention
(`<verb> <path>: <session>`), with the session id computed once as
`cc-$(date +%s)`.

```
# 2a — receivers first, so no pointer dangles
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md: <sid> — receive W0.3 R2 as R7, README becomes a fold"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/prd.md: <sid> — receive W0.3 R3 as R6, propagate decision 4"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/editor/prd.md: <sid> — receive W0.6 R3 as R6 [~], place L-7 and L-9"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/shell/prd.md: <sid> — place L-2 as R7, de-duplicate rr as R8"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/platform/prd.md: <sid> — place L-12 as R4, from-scratch as R5"

# 2b — then the two walled nodes, whose escalations fold in
git commit -m "amend .mi/prd/00-delivery/corrections/w0-3-platform-rewrite/prd.md: <sid> — close on R1, re-home R2/R3, fold in the escalation"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-6-live-bugs/prd.md: <sid> — retire R2, re-home R3, fold in the escalation"

# 2c — the spine
git commit -m "amend .mi/prd/00-delivery/verification-gates/prd.md: <sid> — the gate runner, cut the repo-skeleton dep"
git commit -m "add .mi/prd/00-delivery/first-run/prd.md: <sid> — the ship gate"
git commit -m "amend .mi/prd/00-delivery/work-breakdown/prd.md: <sid> — the schedule becomes a fold"

# 2d — decisions: the answered one, then the four addresses, then the parent
git commit -m "close .mi/prd/00-delivery/decisions/wallpaper-opacity/prd.md: <sid> — answered by the README exclusion list"
git commit -m "amend .mi/prd/00-delivery/decisions/{tinty,fzf,shift-select-scope,odin-toolchain}/prd.md: <sid> — live paths, cut the afk deps"
git commit -m "amend .mi/prd/00-delivery/decisions/prd.md: <sid> — one numbered round"

# 2e — the remaining correction lanes and roll-ups
git commit -m "amend .mi/prd/00-delivery/corrections/w0-2-terminal-respec/prd.md: <sid> — retire R6, place L-11 as R7"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-5-capsule-rebase/prd.md: <sid> — absorb the capsule lane"
git commit -m "amend .mi/prd/00-delivery/corrections/w0-4-s2-corrections/prd.md: <sid> — cross-tree dedup and the wrap rule"
git commit -m "amend .mi/prd/00-delivery/corrections/prd.md: <sid> — the register, not the fixer"

# 2f — merge destinations before their sources are stubbed, one commit each
#      (a stub whose destination does not yet hold the text is a lost box)
git commit -m "amend .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton/prd.md: <sid> — absorb managed-config and the parent"
git commit -m "amend .mi/prd/05-platform/02-package-provisioning/packages-installer/prd.md: <sid> — absorb the bootstrap and the parent"
git commit -m "amend .mi/prd/05-platform/03-shell-init-generation/prd.md: <sid> — absorb launchd PATH seeding"
git commit -m "amend .mi/prd/01-capsule/01-container-lifecycle/prd.md: <sid> — absorb credentials and recents"
git commit -m "amend .mi/prd/01-capsule/02-dev-image/prd.md: <sid> — build once, close the odin fork"
git commit -m "amend .mi/prd/02-terminal/01-appearance/prd.md: <sid> — re-spec, retire R2, fold in the escalation"
git commit -m "amend .mi/prd/02-terminal/02-startup-layout/prd.md: <sid> — absorb tab-content-state and the capsule keys"
git commit -m "amend .mi/prd/02-terminal/03-f5-jump-mode/prd.md: <sid> — absorb copy mode, invert R4"
git commit -m "amend .mi/prd/03-editor/01-options/prd.md: <sid> — absorb keymaps, autocmds, lazy"
git commit -m "amend .mi/prd/03-editor/09-lsp/prd.md: <sid> — absorb completion, formatting, treesitter"
git commit -m "amend .mi/prd/03-editor/08-telescope/prd.md: <sid> — absorb oil, small plugins, table mode"
git commit -m "amend .mi/prd/03-editor/11-colorscheme/prd.md: <sid> — absorb the statusline, fix M-12"
git commit -m "amend .mi/prd/03-editor/14-shift-select/prd.md: <sid> — record L-9, add the fork box"
git commit -m "amend .mi/prd/04-shell/01-core-config/prd.md: <sid> — absorb aliases and launchers"
git commit -m "amend .mi/prd/04-shell/03-zoxide/prd.md: <sid> — absorb listing, fix the du bug"
git commit -m "amend .mi/prd/04-shell/04-television/prd.md: <sid> — absorb history and quicklist"
git commit -m "amend .mi/prd/06-help/02-help-command/prd.md: <sid> — absorb the browser and the agent interface"

# 2g — only now, the 28 stubs (one commit, they are pure redirects)
git commit -m "board: fold 28 nodes into their siblings, addresses kept: <sid>"

# 2h — the tail: drift check, coverage, content-model, epics, meta, root
git commit -m "amend .mi/prd/06-help/04-drift-check/prd.md: <sid> — cut the content-model dep cycle, add R9/R10"
git commit -m "amend .mi/prd/06-help/01-content-model/coverage/prd.md: <sid> — add R6, record the cycle cut"
git commit -m "amend .mi/prd/06-help/01-content-model/prd.md: <sid> — name the two adversary passes R5 needs"
git commit -m "amend .mi/prd/{01-capsule,02-terminal,03-editor,04-shell,05-platform,06-help}/prd.md: <sid> — epic invariants and non-empty acceptance"
git commit -m "amend .mi/prd/00-delivery/prd.md: <sid> — I2/I3 become pointers, add I6"
git commit -m "amend .mi/prd/prd.md: <sid> — I2 becomes a pointer"
```

**Step 3: the check, and it is the point of the whole exercise.**

```
for f in $(find .mi/prd -name prd.md | sort); do
  printf '%s\tx=%s\topen=%s\tstub=%s\n' "$f" \
    "$(grep -cE '^[ \t]*- \[x\]' "$f")" "$(grep -cE '^[ \t]*- \[ \]' "$f")" \
    "$(grep -cE '^[ \t]*- \[~\]' "$f")"
done > /tmp/boxes.after
diff /tmp/boxes.before /tmp/boxes.after
git log --format=%s%n%b | grep -nE 'requirement [0-9]|\bR[0-9]+\b' > /tmp/cites.after
```

Then, by hand and per file, not in aggregate:

1. **Closed boxes.** `w0-1-terminal-inventory` = 7, `w0-3-platform-rewrite` =
   1, `w0-6-live-bugs` = 2, `06-help/01-content-model` = 13. Any other value
   is a destroyed record and the apply is reverted.
2. **Stubs.** Exactly three `[~]` exist before, and exactly three exist
   after — none is downgraded. `w0-6-live-bugs` R3's `[~]` is now
   `w0-4/editor` R6 `[~]`; `w0-3-platform-rewrite`'s link-check `[~]` is now
   `verification-gates`' last acceptance box `[~]`;
   `06-help/01-content-model` R5 is still `[~]` where it was. Any `[~]` that
   became `[ ]` is a lost record and the apply is reverted.
3. **Every fall is explained.** For each file whose open count fell, the
   departing ids must appear as migration-map rows with a named destination,
   and that destination's count must have risen. Files with no migration rows
   must not fall at all.
4. **Requirement citations still resolve.** `diff /tmp/cites.before
   /tmp/cites.after` is empty (the log is append-only, so it must be), and
   each of the 28 citations is opened and checked against the node it names:
   `w0-3` R1/R2/R3, `w0-6` R1–R5 and `06-help/01` R1–R5 are the ones that
   matter, and none of them is reassigned.
5. **The tree still resolves.** Every relative link in a rewritten file
   points at a file that exists — checked with a multi-line-aware walker,
   because this repo's ~78-column wrap manufactures links split across lines
   and a per-line walker silently passes one.

If any of the five fails, revert the whole apply. The commits are one node
each precisely so that a revert is surgical, but a plan whose ledger does not
balance is not a plan that should be half-applied.
