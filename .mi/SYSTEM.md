Working contract for agents in this repo. Read this before touching anything.

## What this repo is

A **rebuild** of the dotfiles that currently live in `~/.files` (legacy,
zsh-era) and `~/.config/*` (current, chezmoi-managed). The point is not to
copy either one across. It is to **rate every existing capability and take
over only what is actually useful**, producing a minimal configuration that
still works as a good daily-driver basis.

Nothing is ported because it exists. Everything is ported because a rating
says it earns its place. A few things are net-new because the rebuild needs
them: [`06-help`](.mi/prd/06-help/00-epic.md) and the
[`00-delivery`](.mi/prd/00-delivery/00-epic.md) meta-epic.

**Verify against the live config, always.** A four-agent audit on 2026-08-20
found that the terminal epic had been specced entirely from the legacy
inventory and was wrong in almost every requirement, and that several
behaviors the PRDs described as working are in fact broken upstream
(macOS `du -sb`, the git-log commit decoder, the `rcwd` channel name). Read
[`04-corrections-backlog`](.mi/prd/00-delivery/04-corrections-backlog.md)
before trusting any PRD you did not just check yourself.

**Current state: planning only.** The repo holds the rated inventories and the
PRD tree. No configuration has been implemented yet, and it is not yet a git
repo — so "gate a commit" style requirements in the PRDs describe the intended
end state, not something running today.

## Where things live

The split is strict: **`.mi/prd/` holds PRDs and nothing else; every other
markdown document goes in `.mi/docs/`.**

| Path | What it is |
|---|---|
| `.mi/prd/` | The PRD tree — epics (`NN-<area>/00-epic.md`) + feature PRDs |
| `.mi/prd/README.md` | Index, build order, and the canonical exclusion list |
| `.mi/docs/capabilities.md` | Rated inventory of the legacy `~/.files` repo |
| `.mi/docs/capabilities-nushell.md` | Rated inventory of the live nushell daily driver |
| `.mi/docs/capabilities-nvim.md` | Rated inventory of the live Neovim config |
| `.mi/docs/capabilities-provisioning.md` | Rated inventory of the chezmoi provisioning layer |
| `.mi/docs/delivery-gantt.md` | The build schedule — waves, critical path, agent counts |
| `.mi/docs/research-*.md` | Background research (e.g. dotfile managers) |
| `AGENTS.md` | This file — the working contract, at the repo root |

Live sources to read when specifying (never edit them as part of PRD work):
`~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
`~/.config/wezterm/`, `~/.files/`, and the chezmoi source at
`~/.local/share/chezmoi`.

## The PRD tree

| Epic | Covers | Children |
|---|---|---|
| [`00-delivery`](.mi/prd/00-delivery/00-epic.md) | Meta: work breakdown, waves, agent fan-out, gates | 4 |
| [`01-capsule`](.mi/prd/01-capsule/00-epic.md) | One consolidated dev-container tool | 4 |
| [`02-terminal`](.mi/prd/02-terminal/00-epic.md) | WezTerm appearance, startup, jump mode | 3 |
| [`03-editor`](.mi/prd/03-editor/00-epic.md) | Neovim (lazy.nvim stack) | 15 |
| [`04-shell`](.mi/prd/04-shell/00-epic.md) | Nushell daily driver | 8 |
| [`05-platform`](.mi/prd/05-platform/00-epic.md) | macOS dependency bootstrap | 1 |
| [`06-help`](.mi/prd/06-help/00-epic.md) | `help` — the environment manual (net-new) | 5 |

**Working on the build?** [`00-delivery`](.mi/prd/00-delivery/00-epic.md) is
the operational plan: every task with its size, files, and dependencies; the
wave layout that says what runs in parallel; and the gates that must pass. Its
rules bind you — one writer per file, one PRD per agent, and a task is done
only when its acceptance criteria have been *executed*. If you find a PRD
wrong, stop and file it in
[`04-corrections-backlog`](.mi/prd/00-delivery/04-corrections-backlog.md)
rather than implementing the wrong thing.

The README's build order is the human summary; the wave layout is the
operational one. Start here for "how do I work in this repo".

## `help` — read the environment before acting on it

Once [`06-help`](.mi/prd/06-help/00-epic.md) is built, **`help` is the manual
for this environment** — every custom keybinding, command, alias, and idiom,
with what it does and how to use it. `help --json` gives the same content as
structured data.

Consult it before suggesting or writing any shell/editor workflow. It is what
prevents the standard failure mode: reaching for `fzf` when television is what
is installed, `grep` when `rg` is, or `find` when `fd` is. If you add a
keybinding or command, add its manual entry in the same change — otherwise
`help --check` reports it as undocumented and exits non-zero.

Until it exists, read the inventories in `.mi/docs/` for the same knowledge.

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
  [`01-capsule/01`](.mi/prd/01-capsule/01-container-lifecycle.md)).
- **Net-new capabilities** have no inventory entry. Rate them in the PRD
  header and write `net-new` where other PRDs name their source.
- **Meta-epics are exempt.** [`00-delivery`](.mi/prd/00-delivery/00-epic.md)
  plans the work rather than describing a capability, so its PRDs carry no
  C/U. It lives in `prd/` because it has requirements and acceptance criteria;
  the Gantt lives in `docs/` because it is a schedule with neither.

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
  ([`04-shell/04`](.mi/prd/04-shell/04-television.md)), telescope in the
  editor ([`03-editor/08`](.mi/prd/03-editor/08-telescope.md)). They are not
  to be unified.
- **The terminal owns the palette.** WezTerm's scheme is the base; Neovim
  (base16 + transparent) and television (`default` ANSI theme) inherit it.
  Nothing downstream hardcodes hex values.
- **Minimal base first.** Cosmetic and WIP surfaces are out of the initial
  cut. The canonical list of what's excluded and why is the exclusion section
  of [`.mi/prd/README.md`](.mi/prd/README.md) — don't duplicate it here.

## Known gaps

Real, recorded so nobody mistakes them for finished work:

- **`02-terminal` is invalid as written.** The audit confirmed the mismatch:
  wrong font, wrong palette, inverted palette ownership, non-existent
  `Cmd+N` and `gui-attached`, wrong F5 letter set and ordering, plus ~230
  lines of uncovered live machinery (self-healing tab floor, grid centering,
  copy mode). It needs `docs/capabilities-terminal.md` (covering WezTerm **and
  burrito**) and a from-scratch re-spec — tasks W0.1/W0.2.
- **Three scope decisions are blocked on the human** (task D.1): does burrito
  or WezTerm own tabs/panes, does tinty stay (it owns the palette everything
  else inherits, yet is deferred as cosmetic), and is fzf an accepted
  exception to "tv owns every picker" or replaced.
- **`01-capsule/02` has an open question** — whether the Odin-from-source and
  pi/pi-oilrig toolchain survives into the consolidated image. Recommendation
  recorded in the PRD; not decided.
- **`03-editor/14` (shift-to-select) is the one `SIMPLIFY` with a real
  fork** — port with tests, or consciously downgrade. The PRD holds both
  paths; record the choice there when made.

## How to write a PRD

Feature PRDs are short and testable. Structure:

```markdown
# Feature: <name>

Parent: [<epic>](00-epic.md) · C <n> · U <n> · source: <capability entry>
                                              (or: · net-new)

## Summary          one paragraph, what it is and why it earns its place
## Requirements     numbered, specific, each one implementable
## Acceptance criteria   observable checks, not restated requirements
```

Rules that keep this tree useful:

- **Preserve the hard-won why.** The live config is full of workarounds for
  real constraints (tv needs a TTY; reedline has no chord trees; OSC 133
  double-marking causes phantom prompt lines; `use_kitty_protocol` leaks an
  escape through the WezTerm pty; lualine's `auto` theme breaks on base16;
  an unrotated LSP log once hit 17 GB). Carry those into requirements as
  constraints *with their reason* — they are the expensive part of the
  knowledge, and rediscovering them costs days.
- **Cross-link, don't duplicate.** Relative links between PRDs; each fact
  lives in exactly one file.
- **Record exclusions where they'd be looked for.** A `DO NOT PORT` decision
  belongs in the epic's Non-goals and the README's exclusion list, not just
  in the inventory.
- **Epics own the invariants.** Shared architecture (e.g. "`mkcd` is the
  single navigation funnel", "tv owns every picker screen") goes in
  `00-epic.md`, and children reference it rather than restating it.
- **Prefer built-ins over plugins.** Where the platform already does it
  (Neovim 0.10+ `gc` commenting, 0.11 LSP maps), document the built-in
  instead of adding a dependency.

## Conventions

- Numbered prefixes (`01-`, `02-`) order by build priority / value ratio.
- Markdown wrapped at ~78 columns, matching the existing files. Tables are
  exempt — don't mangle a table to fit.
- Don't reorganize the tree without updating `.mi/prd/README.md` in the same
  change — the index, the tree diagram, and the build order all live there.
- New capability inventories are `capabilities-<area>.md` in `.mi/docs/`, and
  get an epic in `.mi/prd/` — never a doc inside `prd/` or a PRD inside
  `docs/`.
- When an epic's children change, update three places together: the epic's
  children table, the README tree, and the README build order.
