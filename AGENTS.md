Working contract for agents in this repo. Read this before touching anything.

## What this repo is

A **rebuild** of the dotfiles that currently live in `~/.files` (legacy,
zsh-era) and `~/.config/*` (current, chezmoi-managed). The point is not to
copy either one across. It is to **rate every existing capability and take
over only what is actually useful**, producing a minimal configuration that
still works as a good daily-driver basis.

Nothing is ported because it exists. Everything is ported because a rating
says it earns its place. A few things are net-new because the rebuild needs
them: [`06-help`](prds/06-help/prd.md) and the
[`00-delivery`](prds/00-delivery/prd.md) meta-epic.

**Verify against the live config, always.** A four-agent audit on 2026-08-20
found that the terminal epic had been specced entirely from the legacy
inventory and was wrong in almost every requirement, and that several
behaviors the PRDs described as working are in fact broken upstream
(macOS `du -sb`, the git-log commit decoder, the `rcwd` channel name). Read
[`04-corrections-backlog`](prds/00-delivery/corrections/prd.md)
before trusting any PRD you did not just check yourself.

**Current state: the port is mostly built.** Corrected 2026-08-24 — this
paragraph said "planning only … no configuration has been implemented yet",
which was true when written and has been false for a while. Measured on
2026-08-24: **50 of 65 requested nodes are `done` (94% by est)**, and the
chezmoi source under `home/` carries the shipped WezTerm, Neovim, nushell,
television and capsule configuration. The editor epic is complete. Run
`python3 ~/dev/infra/pearde/resources/board/plan.py plan` for today's number rather
than trusting this sentence — a count in prose is a reading of the day it was
taken, and this board has corrected six of them in six documents on
2026-08-24 alone.

What is **not** built, so nobody reads the above as "finished": the whole of
[`08-claude-agent`](prds/08-claude-agent/prd.md) is `open` or `analyzing`, and
so is the board root. Measured 2026-08-31: **191 of 196 nodes `done`**, with 73
unticked `- [ ]` boxes and 43 `[~]` stubs still in the tree. `just cutover` has
**not** run, so `chezmoi source-path` still answers with the pre-rebuild repo
rather than this one — which means the `home/` tree here is not what this
machine is running. Ask it, per the live-sources rule below, rather than
assuming a path.

**There are no tests.** `tests/` and `gates/` were deleted on 2026-08-31 —
every `verify:` that pointed into them now reads `""`, the contract's value for
*unproven*, and 81 interactive checks were never run. The reasoning is in
[the memo](prds/memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md);
the 81 open checks are preserved at `docs-site` → Internals → Never verified by
a person. A change is verified by deploying it and using it.

The PRD tree was converted to board node form on 2026-08-20 so work can
actually be claimed; see the next section.

## Where things live

The split is strict: **`prds/` holds PRDs and nothing else; every other
markdown document goes in `docs/`.** Everything about a PRD — its state, its
schedule, its history — lives in the PRD itself; there is no side file.

| Path | What it is |
|---|---|
| `prds/` | The board — a tree of `<node>/prd.md` files. The path is the id and the parent link |
| `prds/**/prd.md` frontmatter | Also the plan: `est`, `needs`, and `priority` carry the schedule. `needs` are board node paths; a node implements only after every one is `done`. **The key is `needs`, in block form** — renamed from `deps` on 2026-08-24 because the tooling reads only `needs`, and only as a block list: an inline `needs: [a, b]` parses as one bogus path and an empty `needs: []` as the string `"[]"`. Write `needs:` bare when there are none |
| `.claude/skills/pearde/README.md` | The board protocol — states, the loop, the worker briefs, and who may write what. A symlink: the skill lives in its own repo (`~/dev/infra/pearde`) and is not vendored here |
| `prds/README.md` | Index, build order, and the canonical exclusion list |
| `docs-site/` | The searchable manual — a fumadocs site. `content/docs/guide/` (task order, from `tasks.nuon`) and `content/docs/reference/` (subject order, from `topics.nuon`) are both **generated** from the `.nuon` surfaces by `scripts/generate-manual.mjs`, so the site and `help` cannot drift; `content/docs/internals/` is hand-written and holds the constraints the configs used to carry as comments |
| `docs/capabilities.md` | Rated inventory of the legacy `~/.files` repo |
| `docs/capabilities-nushell.md` | Rated inventory of the live nushell daily driver |
| `docs/capabilities-nvim.md` | Rated inventory of the live Neovim config |
| `docs/capabilities-terminal.md` | Rated inventory of the live WezTerm config |
| `docs/capabilities-provisioning.md` | Rated inventory of the chezmoi provisioning layer |
| `docs/research-*.md` | Background research (e.g. dotfile managers) |
| `AGENTS.md` | This file — the working contract, at the repo root. `CLAUDE.md` symlinks to it |

The mi-era planning machinery (`.mi/gantt/plan.json`, its ledger, the
`delivery-gantt.md` fold, and the mi skills) is retired: its task data —
sizes, dependencies, footprints, manual verification steps — was folded
into the PRD frontmatter and bodies, and the files were removed. Git
history has them.

Live sources to read when specifying (never edit them as part of PRD work):
`~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
`~/.config/wezterm/`, and the legacy tree at `~/.files/` — a plain directory,
not a git repo (measured 2026-08-24), holding the zsh-era material
`docs/capabilities.md` rates.

**Find the chezmoi source by running `chezmoi source-path`. Never by literal
path.** It printed `/Users/feb/dev/.files/home` on 2026-08-24 — a reading of
that day, not a constant, because `just cutover` rewrites `sourceDir` and the
answer moves. Two traps live in that answer. `~/dev/.files` is **not**
`~/.files`: two different trees one path segment apart, and only the first is
the chezmoi source. And `~/.local/share/chezmoi` still exists but is **not**
the source — it is a stale June clone (HEAD `a2544e4`, a git *ancestor* of the
live `8e99f58`) whose readings produced findings L-12, L-13 and M-21, and per
Decision 4(a) no document may cite it as the chezmoi source; the only
permitted mention is as the stale clone, labelled as such. The full record is
in `docs/capabilities-provisioning.md`. Decision 4 also makes the deployed
`~/.config` tree canonical: read a source tree to explain how a file got where
it is, not to decide what it says.

## The PRD tree

| Epic | Covers | Children |
|---|---|---|
| [`00-delivery`](prds/00-delivery/prd.md) | Meta: work breakdown, waves, gates, and the open decisions | 5 (+19) |
| [`01-capsule`](prds/01-capsule/prd.md) | One consolidated dev-container tool | 4 |
| [`02-terminal`](prds/02-terminal/prd.md) | WezTerm — local chrome only since the 2026-08-30 cutover: appearance, launchd PATH, grid centering. Tabs, jump mode and copy mode moved to `07-multiplexer` | 7 |
| [`03-editor`](prds/03-editor/prd.md) | Neovim (lazy.nvim stack) | 15 |
| [`04-shell`](prds/04-shell/prd.md) | Nushell daily driver | 9 |
| [`05-platform`](prds/05-platform/prd.md) | chezmoi provisioning: deploy, packages, shell-init | 3 (+4) |
| [`06-help`](prds/06-help/prd.md) | `help` — the environment manual (net-new) | 5 (+1) |
| [`07-multiplexer`](prds/07-multiplexer/prd.md) | tmux — the portable layer: windows, panes, addressing, splits, copy, status, persistence (net-new) | 9 |
| [`08-claude-agent`](prds/08-claude-agent/prd.md) | Claude Code manages tmux panes and edits in nvim: the tmux MCP server, claudecode.nvim + claude-tmux.nvim, the tmux.conf additions, the help entries (net-new) | 4 |

Counts are direct children, with grandchildren in parentheses.
`find prds -name prd.md` is the index, because node membership is by existence
and a maintained list beside it goes stale — **as the number that stood here
had.** Corrected 2026-08-29: this paragraph opened "85 nodes in all" while
`find` answered **173**, so the sentence warning that a maintained count goes
stale was carrying one that had. No total is written here now; run the `find`.

**Working on the build?** [`00-delivery`](prds/00-delivery/prd.md) is
the operational plan: every task with its size, files, and dependencies in
its frontmatter; the dep graph that says what runs in parallel; and the gates
that must pass. Its rules bind you — one writer per file, one PRD per agent,
and a task is done only when its acceptance criteria have been *executed*. If
you find a PRD wrong, stop and file it in
[`04-corrections-backlog`](prds/00-delivery/corrections/prd.md)
rather than implementing the wrong thing.

The README's build order is the human summary; the frontmatter dep graph is
the operational one. Start here for "how do I work in this repo".

## `help` — read the environment before acting on it

Once [`06-help`](prds/06-help/prd.md) is built, **`help` is the manual
for this environment** — every custom keybinding, command, alias, and idiom,
with what it does and how to use it. `help --json` gives the same content as
structured data.

Consult it before suggesting or writing any shell/editor workflow. It is what
prevents the standard failure mode: reaching for `fzf` when television is the
picker this config drives, `grep` when `rg` is, or `find` when `fd` is. fzf is
installed — as `zi`'s dependency, not as a picker to reach for. If you add a
keybinding or command, add its manual entry in the same change — otherwise
`help --check` reports it as undocumented and exits non-zero.

Until it exists, read the inventories in `docs/` for the same knowledge.

## The rating system

Every capability entry in an inventory carries two numbers, in this order:

```
## <capability name>  [optional verdict marker]
- <description>
- <complexity 1–10>     how intricate the implementation is
- <usefulness 1–10>     how much day-to-day value it delivers
```

Value ratio = usefulness − complexity. Inventories are sorted best-ratio
first. Markers on the `##` heading are the verdict:

- *(no marker)* — take over as-is
- `SIMPLIFY` — take over a reduced version; the PRD says what gets dropped
- `CONSOLIDATE` — merge with overlapping capabilities into one tool
- `DEFER` — real but not part of the minimal base; revisit later
- `DO NOT PORT` — drop entirely, and record why

When you add a capability, rate it and give it a verdict. An unrated entry is
an incomplete entry.

Four rules for keeping ratings honest across the tree:

- **A PRD header's `C`/`U` must match its inventory entry** — single numbers,
  never a range.
- **A PRD that merges several entries** carries the dominant entry's rating
  and lists every source with its own numbers (see
  [`01-capsule/01`](prds/01-capsule/01-container-lifecycle/prd.md)).
- **A PRD that splits one entry** — where a recorded scope decision removed
  part of what the inventory rated — may carry numbers differing from its
  source, on three conditions: the node holds a **rating note** naming the
  decision, its date and who made it; the note says which number moved and
  which did not; and the **inventory entry is updated to point at the split**,
  so a reader arriving from the inventory is not left with the pre-decision
  numbers and a stale verdict marker. Without the third, the divergence is
  invisible from the side people actually read first. The worked case is
  [`02-terminal/03-f5-jump-mode`](prds/02-terminal/03-f5-jump-mode/prd.md):
  the 2026-08-21 answer took the digit half and dropped the self-painted
  pane-letter overlay, so `C` falls 9 → 6 and `U` does not move. Added
  2026-08-28 — the rules covered merging and not splitting, which left
  `02-terminal`'s acceptance with no honest tick available.
- **Net-new capabilities** have no inventory entry. Rate them in the PRD
  header and write `net-new` where other PRDs name their source.
- **Meta-epics are exempt.** [`00-delivery`](prds/00-delivery/prd.md)
  plans the work rather than describing a capability, so its PRDs carry no
  C/U.

## Scope decisions already made

- **macOS host only.** No Windows, no PowerShell, no `winget`, no cmd.exe or
  drive-letter path abstraction. Linux matters only inside containers.
- **Nushell is the host shell.** zsh/oh-my-zsh survives only inside capsule
  dev containers.
- **One container tool.** The old capsule keybinding, `mount` function,
  `justfile`, and standalone image consolidate into a single "Capsule" tool
  with one image definition.
- **The live config wins over the legacy inventory.** `capabilities.md`
  describes an older mini.nvim-based Neovim that is **not** what is installed;
  the live lazy.nvim config is rated separately in `capabilities-nvim.md` and
  is the one being ported. Expect the same trap elsewhere — verify against
  `~/.config` before trusting a legacy entry.
- **Two finders, deliberately.** television in the shell
  ([`04-shell/04`](prds/04-shell/04-television/prd.md)), telescope in the
  editor ([`03-editor/08`](prds/03-editor/08-telescope/prd.md)). They are not
  to be unified. **fzf is a third picker and the one accepted exception** to
  "tv owns every picker screen": `zi`/`cdi` reach it through
  `zoxide query --interactive`, and owning that screen would mean owning
  zoxide's frecency ranking. Decided 2026-08-21 — see
  [`decisions/fzf`](prds/00-delivery/decisions/fzf/prd.md) and the invariant
  it amends, [`04-shell`](prds/04-shell/prd.md) I3.
- **tmux is the multiplexer; WezTerm keeps only the local chrome.**
  Reversed 2026-08-30 and carried by
  [the memo](prds/memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md).
  The terminal opens into one tmux session `main` through
  `~/.local/bin/tmux-main`; tmux owns windows, panes, addressing, splits,
  copy, the status bar and persistence, and `wezterm.lua` binds nothing that
  addresses a tab or a pane — including WezTerm's own shipped defaults,
  which is why `disable_default_key_bindings = true` is load-bearing rather
  than tidy. What stays in WezTerm: font, grid centering, opacity and blur,
  the launchd PATH seeding, the capsule `SendString` keys. It is 449 lines,
  down from 1297.
- **tinty owns the palette; every reader is downstream of it.** `tinty
  apply` runs `tmux-colors.sh`, which writes `~/.config/tmux/colors.conf`
  for tmux's own surfaces (base02, the active window label's background, has
  no ANSI slot) and pushes OSC 4/10/11/12 straight to every attached
  client's tty — so one apply retints the terminal, tmux and every pane at
  once, over ssh included. `config.nu` sources tinty's tinted-shell artifact
  so a new shell re-asserts the same scheme; Neovim (base16 + transparent)
  and television (`default` ANSI theme) inherit downstream. Nothing below
  tinty hardcodes hex values. **Corrected 2026-08-30**: this bullet used to
  say WezTerm `dofile`s a generated `colors.lua` and retints from it. That
  file, its generator and the reload watch are deleted — the path worked on
  one emulator on one desk. The `dofile`-never-`require` trap it carried
  (`require` caches by module name and hands back the *first* palette on a
  second apply) is kept in the memo as history. The earlier correction of
  "the terminal owns the palette" — finding T-3, open decision 2 — still
  holds: tinty owns it.
- **Minimal base first.** Cosmetic and WIP surfaces are out of the initial
  cut. The canonical list of what's excluded and why is the exclusion section
  of [`prds/README.md`](prds/README.md) — don't duplicate it here.

## Known gaps

Real, recorded so nobody mistakes them for finished work:

*Both bullets that stood here on 2026-08-24 described work that had since
landed, and are corrected below rather than deleted — a gap that closed is
worth more as a record of how it closed than as a blank space.*

- **`02-terminal` was invalid as written; the re-spec landed.** Corrected
  2026-08-24. This bullet said the epic was invalid and the from-scratch
  re-spec was still task W0.2. `w0-2-terminal-respec` is `done`, and all
  seven children of [`02-terminal`](prds/02-terminal/prd.md) are `done`. The
  findings T-1 to T-11 that motivated it are in the
  [corrections backlog](prds/00-delivery/corrections/prd.md), where the
  history lives. What remains on that epic is **human verification, not
  work**: T.4, T.6 and T.7, now listed under `docs-site` → Internals → Never
  verified by a person.
- **`03-editor/14` (shift-to-select) is built, and the fork stays settled.**
  Corrected 2026-08-24. This bullet said "specified but unbuilt" and that
  E.14 had not been implemented; both were false by the time they were read.
  The node is `done` at `f9cb54b`, the code is
  `home/dot_config/nvim/lua/config/shift-select.lua`, and the fifteen spec
  boxes were closed against the test that used to live at
  `tests/nvim-shift-select.sh` before the suite was deleted. The fork itself
  is unchanged and still binding: decided 2026-08-21,
  full port *with* the tests, simplification declined on the record — so
  collapse-on-motion (R6) is not optional and the rating stays `C 7 · U 7`.
  See [`decisions/shift-select-scope`](prds/00-delivery/decisions/shift-select-scope/prd.md).
  An agent finding the tests burdensome does **not** get to re-take the fork;
  it files a correction. What remains is E.14, now under `docs-site` →
  Internals → Never verified by a person — a human watching the collapse under
  real keyboard timing, which no gate could ever have done.

## How to write a PRD

The board protocol, states, and worker briefs are defined in
`.claude/skills/pearde/README.md`; the frontmatter template is
`.claude/skills/pearde/references/templates/prd.md`, and a spec's is
`spec.md` beside it. **Both paths were corrected 2026-08-24**: this section
pointed at `.claude/skills/prd/README.md` and a `PRD_TEMPLATE.md` beside it,
and neither has existed since the mi-era skills were retired — the contract
was directing every agent at a missing file.

Feature PRDs are short and testable. Structure:

```markdown
---
state: open        # open|analyzing|refine|question|specced|claimed|done|failed
priority: 0        # higher first
est:               # hours of implementer work; filled at spec time
needs:             # board node paths that must be done before this implements.
                   # Block form only — one `  - path` per line; bare `needs:`
                   # when there are none. See the frontmatter row above.
mode: afk          # afk | hitl (needs the human: naming, taste, money)
verify: ""         # command proving this node; "" means unproven, never omit
---

# <name>

Parent: [<epic>](../prd.md) · C <n> · U <n> · source: <capability entry>
                                             (or: · net-new)

Purpose: one paragraph, what it is and why it earns its place

## Requirements
- [ ] **R1** — one verifiable behavior per line; the number is kept because
      other documents cite requirements by number

## Acceptance
- [ ] observable checks, not restated requirements

## Out of scope
- explicit; this is the line that stops drift
```

**Everything testable is a box.** Prose acceptance is invisible to the
scheduler and closes unmet, which is the whole reason the tree was converted.
`- [ ]` is open, `- [~]` is met against a stub, `- [x]` is met against the
real thing *with the check you ran*. A `[x]` you did not prove is not
optimism, it is a false record that outlives you.

Rules that keep this tree useful:

- **Preserve the hard-won why.** The live config is full of workarounds for
  real constraints (tv needs a TTY; reedline has no chord trees; OSC 133
  double-marking causes phantom prompt lines; `use_kitty_protocol` leaks an
  escape through the WezTerm pty; lualine's `auto` theme breaks on base16;
  an unrotated LSP log once hit 17 GB). Carry those into requirements as
  constraints *with their reason* — they are the expensive part of the
  knowledge, and rediscovering them costs days. A reason is only as good as
  the fixture it was measured on: record the fixture, never write that a
  mechanism is "exact", and run a cheap claim twice with a different input.
  Eight reasons on this board did not reproduce as stated — the rules are in
  the [corrections backlog](prds/00-delivery/corrections/prd.md).
- **Cross-link, don't duplicate.** Relative links between PRDs; each fact
  lives in exactly one file.
- **`from: tbd` is a value, not a blank.** A derived PRD names the PRD whose
  work surfaced it. Where that genuinely cannot be established — the work
  predates the board, or the trail is gone — write `from: tbd` rather than
  leaving the field empty or guessing a plausible path. Empty reads as "nobody
  filled this in" and a guess reads as a fact; `tbd` says "this was looked for
  and not found", which is the true statement, and a checker can tell the three
  apart. Say in the node's body what the real origin was. Settled 2026-08-28;
  the worked case is [`00-delivery/corrections`](prds/00-delivery/corrections/prd.md),
  surfaced by the four-agent audit that ran before the tree was board-shaped.
- **Record exclusions where they'd be looked for.** A `DO NOT PORT` decision
  belongs in the epic's Non-goals and the README's exclusion list, not just
  in the inventory.
- **Epics own the invariants, and an invariant is prose, not a box.** Shared
  architecture (e.g. "`mkcd` is the single navigation funnel", "tv owns every
  picker screen") goes in the epic's `prd.md`, and children reference it rather
  than restating it. Write it as `**I<n>** — …` in prose and keep the number,
  because other documents cite invariants by number. It is deliberately not a
  `- [ ]` box: an invariant is the architecture the children are built
  *inside*, not work anybody performs, so no run could ever close one — and
  when they were boxes they held eight epics and the board root `open`
  indefinitely, which is what the conversion on 2026-08-28 corrected. The
  "everything testable is a box" rule above governs requirements and
  acceptance; an invariant is not a testable claim, it is the frame the tests
  are written in.
- **Prefer built-ins over plugins.** Where the platform already does it
  (Neovim 0.10+ `gc` commenting, 0.11 LSP maps), document the built-in
  instead of adding a dependency.

## Conventions

- Numbered prefixes (`01-`, `02-`) order by build priority / value ratio.
- Markdown wrapped at ~78 columns, matching the existing files. Tables are
  exempt — don't mangle a table to fit.
- Don't reorganize the tree without updating `prds/README.md` in the same
  change — the index, the tree diagram, and the build order all live there.
- When an epic's children change, update three places together: the epic's
  children table, the README tree, and the README build order.
- New capability inventories are `capabilities-<area>.md` in `docs/`, and
  get an epic in `prds/` — never a doc inside `prds/` or a PRD inside
  `docs/`.
