---
memo: tests-and-gates-retire-a-dev-setup-is-not-a-product
kind: decision
status: decided
tags:
  - memo
  - kind/decision
  - status/decided
subject: tests/ and gates/ are deleted and the configs are stripped of their board scaffolding; the knowledge they carried moves into a generated, searchable docs site, because this tree is one person's dev setup and not a shipped product
date: 2026-08-31
prds:
  - 00-delivery
  - 00-delivery/corrections
  - 06-help
---

# tests-and-gates-retire-a-dev-setup-is-not-a-product — the manual is the record now

## Decision

`tests/` (53 scripts) and `gates/` (26 files, including the eight
`gates/manual/wave*.md` check sheets) are **deleted**. The `verify:` field on
every board node that pointed into them stops resolving, and no replacement
runner is written.

The comments in `home/` are cut back to what a person needs while editing the
file. Everything board-shaped goes: anchor markers, node ids, spec-file
references, `THIS FILE IS CO-WRITTEN`, schedule prose, the running commentary
about which node appends where. What survives in-file is the short
constraint-with-reason note where getting it wrong breaks the file —
sourcing a missing `.nu` is a parse error, tv needs a TTY, leader must be set
before any plugin spec is evaluated.

The long-form *why* is not thrown away. It moves to **`docs-site/`**, a
fumadocs site generated from the four `.nuon` surface files, where the 103
entries are searchable and cross-linked by topic rather than buried at line
340 of a config nobody scrolls.

**Superseded in part, later the same day.** The site was deleted and the same
content became plain markdown under `home/dot_config/nushell/help/manual/`,
searched by the `docs` television channel and read with `?`. The knowledge
moved exactly as this memo says; only the renderer changed. See
[the-manual-is-markdown-a-site-you-must-start-is-not-read](the-manual-is-markdown-a-site-you-must-start-is-not-read.md).

Taken by the user on 2026-08-31, against a measurement: `tmux.conf` was 108
lines of configuration under 537 lines of prose, and `config.nu` 326 under
529.

## Why

**The tests were proving the wrong property.** A gate that greps
`home/dot_config/nushell/config.nu` for a setting asserts that a file in a
git repository contains a string. It does not assert that the shell works,
because — measured the same day — `chezmoi source-path` answers
`/Users/feb/dev/.files/home`, `just cutover` has never run, and the tree
these 53 scripts guard **is not the tree deployed to this machine**. Every
green was green about a file the machine does not read.

**The real gate is using it.** For a product, a test suite is how you learn a
change broke something for someone who is not in the room. For one person's
shell, the feedback loop is opening a terminal. That loop is faster than the
suite, and it tests the deployed artifact rather than its source.

**Comments at that density stop being read.** Five lines of prose per line of
config is not documentation, it is an unreviewed second copy of the spec
living where nobody looks for a spec. It goes stale silently — `wezterm.lua`
carried its 1297-line-era commentary for a week after the file fell to 568 —
and it makes the actual configuration hard to find. A searchable site is
where someone would look; the top of `tmux.conf` is not.

## What this costs, honestly

- **The 81 unticked human checks in `gates/manual/` go with the files.** They
  were the record of what had never been verified by a person. That record
  now exists only in git history and in this memo.
- **118 `verify:` fields become dangling.** They are rewritten to `""` — the
  contract's value for *unproven* — rather than left pointing at deleted
  paths, so the board says "unproven" instead of lying.
- **A regression will be found by hitting it**, not by a gate. Accepted: the
  blast radius is one machine and one user, and `git revert` is the recovery.

## What replaces them

`docs-site/` — the same knowledge, searchable, generated from the `.nuon`
manual rather than hand-maintained beside it. (Read that as
`~/.config/nushell/help/manual/` and `?` from 2026-08-31 onwards; the memo
named above records why the site itself did not last the day.) `help` in the shell keeps
working from the same source files, so the site and the shell manual cannot
drift apart: there is one set of entries and two renderers.
