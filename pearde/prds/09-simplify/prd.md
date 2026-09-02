---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 35        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius:      # analyst, at spec time — high|mid|low. What breaks if this is wrong
repo:
time:
  est:
  actual:
needs:
footprint:
  - docs/simplification-plan.md
---

# Epic: Simplify — smaller and more straightforward, everywhere

Parent: the board root · meta-epic, no C/U · net-new

Purpose: the rebuild is built. The week of 2026-08-26 measured what grew
around it: a 7.2 MB board beside 1.3 MB of configuration, a 6,185-line manual
for one reader, config files that are two-thirds comment, and 58 of 78
commits that never touched `home/`. The user's standing rule, given
2026-09-02: **the smaller and more straightforward everything is, the
better.** This epic applies that rule to every part of the repo. The full
audit with file and line references is
[`docs/simplification-plan.md`](../../../docs/simplification-plan.md); each
child below is one phase of it, turned into boxes.

**When this is done:** `home/` is about 6,300 lines instead of 10,800, the
board holds every `prd.md` and no spec, `AGENTS.md` is about 60 lines, and
no file in the repo cites `tests/`, `gates/` or `docs-site/` as if they
existed. Every gesture the daily driver uses still works, and the four it
loses are named in `08-litellm-out` and `04-nushell`.

## Invariants

**I1** — No changelog in a config. A comment says what a line does, or the
one trap that breaks it. Never "used to", "removed on", "stood here",
"Corrected". Git blame is the history.

**I2** — A board node is filed only when it changes a file under `home/`,
`scripts/`, `install.sh` or `justfile`. Anything else is a commit message.

**I3** — No count in prose. A number in a paragraph is stale the day after it
is written; the command that produces it is written instead.

**I4** — A built-in beats a wrapper. Where nushell, Neovim, tmux or
television already does the thing, the config calls the built-in and the
wrapper is deleted.

**I5** — Every child closes by deploying and using. `chezmoi apply`, open a
terminal, press the keys named in its acceptance. There is no other gate.

## Constraints

- The PRDs are the record. No `prd.md` is deleted by this epic; only the
  scaffolding around them (`specs/`, process memos, dangling `verify:`).
- One writer per file. The `needs:` chain below is serial where two children
  touch one file — `config.nu` is touched by `03` and `04`, `wezterm.lua` by
  `05` after `04` removed the command its keys call.
- Nothing is deleted from a file that was not read whole first. Each child's
  line references were measured on 2026-09-02 and drift as earlier children
  land; the implementer re-reads before cutting.
- `just manual` runs after every `.nuon` edit, and `help --json` still
  parses.

## Children

| child | contract | needs |
|---|---|---|
| `01-hygiene` | Land the 2026-09-01 state as one commit over the paths R1 names, then remove the duplicates, the generated artifact, the stale ignore rules and the one-time recipe. | — |
| `02-board` | Every `prd.md` stays; every `specs/` goes; process memos are archived; `AGENTS.md` becomes ~60 lines; no `verify:` names a deleted script. | 01-hygiene |
| `03-help-system` | Delete the drift checker, the review files and the redundant renderers. One corpus, one generator, one search. Sweep the internals of dead test citations. | 01-hygiene |
| `04-nushell` | `config.nu` and the modules: built-in `ls --du`, one keybinding append, no tombstones, no second-machine branches, four small commands deleted. | 03-help-system |
| `05-terminal` | `tmux.conf` to ~250 lines, generated F5 tables, `tv-all` on `command-prompt`, `wezterm.lua` without dead machinery, one palette path. | 04-nushell |
| `06-neovim-television` | Six channels deleted, built-ins over `shift-select.lua` and the hand-built lualine theme, `claude.lua` trimmed, the mason hook decided. | 03-help-system |
| `07-provisioning` | `install.sh` becomes a `Brewfile` plus ~60 lines; the three `run_after` scripts lose their test seams. | 01-hygiene |
| `08-litellm-out` | The litellm / `cll` stack leaves the dotfiles repo, by the user's choice of destination. | 06-neovim-television |

## Out of scope

- Any new capability. This epic only removes and replaces with built-ins.
- `docs/capabilities-*.md`: kept as the rating record, no longer edited.
- The pearde tooling itself (`~/dev/infra/pearde`).
