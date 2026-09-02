---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 36        # higher first
complexity: 30      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual: 0.5h
needs:
  - 09-simplify/01-hygiene
footprint:
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/help
  - home/dot_config/nushell/config.nu
  - home/dot_config/nvim/lua/config/lazy.lua
  - home/dot_local/bin/executable_tv-all
  - home/.chezmoiremove
  - scripts/generate-manual.mjs
# Corrected by the orchestrator 2026-09-02, before dispatching the implementer.
# Removed: `home/dot_config/nushell/help-check.nu` (R1 deletes it) and
# `home/dot_config/television/cable/manual.toml` (R4 deletes it). `collect`
# resolves every footprint entry to a repo and refuses the whole call when one
# is gone — "footprint <path> is not under <repo> — repo_of matched no repo for
# it; nothing written". A node cannot keep a file it deletes in its own
# footprint and still be collectable; this refused two collects earlier today
# on `09-simplify/01-hygiene`. Added: `executable_tv-all`, which the analyst
# found holds a third, unnamed renderer of the corpus, live-bound from
# `tmux.conf` and killed by R4+R5 either way; and `home/.chezmoiremove`, which
# spec04 needs because `chezmoi apply` leaves deleted sources deployed.
workflow: cut-a-feature-its-readers-still-name
---

# 03-help-system — one corpus, one generator, one search

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: the manual is the one piece of process that survives as a feature:
four `.nuon` surfaces, a generator, `?` over the result. Around it grew a
497-line drift checker that spawns a headless nvim, a second tmux server and
a WezTerm probe to keep 191 `verify:` records true; two review files whose
only reader was a deleted test; and five renderers of the same corpus. This
child keeps nuon → markdown → `?` and plain `help <thing>`, and deletes the
rest. Measured 2026-09-02; line numbers drift, re-read before cutting.

## Requirements

- [x] **R1** — `help-check.nu` is deleted, with the `--check` flag on
      `def help` (help.nu:325, 357), the `source help-check.nu` line
      (config.nu:303), the `HELP_CHECK` branch in `nvim/lua/config/lazy.lua`
      (lines 5, 9-12, 32-33), and `internals/help.md` lines 333-691 (the
      checker's own design). **Done** — verified by `probe/verify.sh`. `internals/help.md` 691 → 314 lines; R1 named 333-691, but 7-332 documented `help.nu` as it was and was rewritten too.
- [x] **R2** — `use-review.nuon` and `why-review.nuon` are deleted, with
      their rows in `help/README.md` (lines 25-26). Nothing in `home/` or
      `scripts/` opens them; their only reader was
      `tests/help-content-model.nu`. **Done** — both files gone, README rows gone. Confirmed nothing in `home/` or `scripts/` opens them; the only hits left in the tree are plan documents and PRDs, which are mentions, not readers.
- [x] **R3** — The `verify:` field is removed from every entry in
      `shell.nuon`, `nvim.nuon`, `terminal.nuon`, `capsule.nuon`, and the
      `source:` field where it names a spec or test. `generate-manual.mjs`
      and `help.nu` stop reading them. **Done** — 116 `verify:` and 116 `source:` stripped. R3 says "the `source:` field where it names a spec or test"; **all 116 named `prds/<...>/prd.md` and the board is at `.pearde/prds/`**, so every one was already a dead path and the qualifier resolves to all of them.
- [x] **R4** — `help --fuzzy`, `_help_rows`, `_help_preview`, `_help_browse`
      (help.nu:227-288) and `cable/manual.toml` are deleted. `?` is the one
      search. The `help --fuzzy` entry leaves `shell.nuon`. **Done** — and a **third** renderer the requirement did not name went with it: `tv-all`'s `manual` lane, live-bound from `tmux.conf`, calling `_help_rows` and `help --entry`. Both of its dependencies were being deleted, so the lane could not have survived R4 either way.
- [x] **R5** — `help --md`, `--all`, `--entry`, `--topic`, `--delegate`
      (help.nu:168-203, 319-321, 365-378), the eight-branch flag ladder
      (:333-355) and `_help_host_only` (:164-166) are deleted. What stays:
      `help`, `help <topic>`, `help <thing>`, `help --json`. The five
      near-identical "run `chezmoi apply`" errors (help.nu:7-54) become one. **Done** — `help.nu` is 198 lines, four shapes, no ladder; the five `chezmoi apply` errors are one `_help_missing`.
- [x] **R6** — `help/README.md` becomes the schema table for an entry plus
      "edit the nuon, run `just manual`". Lines 53-106 and 200-366 describe
      the deleted checker and go. **Done** — `help/README.md` 366 → 64 lines.
- [x] **R7** — Stale claims are fixed at their source and regenerated:
      `tasks.nuon:92` ("this site"), `topics.nuon:37-38` (WezTerm owns jump
      mode), `shell.nuon:5-13` (four "not yet live" behaviours that are
      live), `help.nu:281` (cutover has not run), `internals/help.md:5`. **Done** — and the five anchors undercounted: **nine** stale claims existed. See spec02.
- [x] **R8** — Every `tests/`, `gates/` and `docs-site` citation leaves
      `manual/internals/*.md` (about 30 lines across `help.md`,
      `nushell-modules.md`, `neovim.md`, `capsule.md`, `wezterm.md`,
      `unverified.md`). `unverified.md` keeps its list of unverified
      behaviours and loses the gate vocabulary around it. **Done** — 30 citations across six files, and 32 further bare-word *gate* sentences that asserted deleted machinery as live. Two files R8 did not list also carried them: `nushell.md` (the `rm`/`always_trash` passage used the drift check as its worked example) and `neovim.md` (the `HELP_CHECK` guard). `unverified.md` keeps its 81 checks; **two were deleted rather than reworded** because the commands they name are gone.
- [x] **R9** — `just manual` is run last; `guide/` and `reference/` are
      regenerated and committed with the sources. **Done** — `just manual` run last; `reference: 9 pages, 113 entries`. Generation confirmed a fixed point: snapshot, re-run, `diff -r` silent.

## Acceptance

- [x] `nu -l -c 'help --json | from json | get entries | length'` prints a
      number and matches the corpus's entry count. **Ran: prints `113`**, and
      the six surfaces open as 45/40/21/7 rows (+ 9 topics, 14 tasks), so
      45+40+21+7 = 113. `just manual` independently reports
      `reference: 9 pages, 113 entries`.
      *Original note, kept:* Corrected 2026-09-02 by
      the orchestrator, from the analyst's F3: bare `help` returns a string
      (`describe` says `string (stream)`), so `help | length` always errors
      and could never have passed, before or after this change; `help --json
      | from json | length` answers 2 (the record's field count), not the
      entry count. Measured on this build: 113.
- [x] `nu -l -c 'help navigate'` and `nu -l -c 'help z'` render; `nu -l -c 'help --check'` fails with "unknown flag" — both render, exit 0. The
      third is met in substance and **not in wording**: nushell 0.115.1 answers
      `` help --check `` with ``the `help` command doesn't have flag `check`.``
      under a `nu::parser::unknown_flag` banner — the phrase "unknown flag" is
      the error's *code*, not its text, so a probe grepping the literal string
      would fail on the correct state. Asserted as `doesn't have flag`.
- [x] `rg -l 'tests/|gates/|docs-site' home/dot_config/nushell` prints nothing
      — 30 citations removed across six files, plus 32 bare-word *gate*
      sentences in four of them that described the same deleted machinery as
      live. See spec03.
- [x] `test ! -e home/dot_config/nushell/help-check.nu && test ! -e home/dot_config/nushell/help/use-review.nuon && test ! -e home/dot_config/television/cable/manual.toml`
      — all absent from the source tree, **and from the machine**: spec04 adds
      `home/.chezmoiremove`, without which `chezmoi apply` leaves a deleted
      source's target deployed.
- [x] `nvim --headless +qa` exits 0 with no `HELP_CHECK` reference in `lazy.lua`
      — both hold. `internals/neovim.md` documented that guard's code and was
      rewritten with it; `checker` is verified still ENABLED, so removing a
      drift check did not silently switch off plugin updates.
- [~] after `chezmoi apply`, `?` opens the picker and Enter lands in nvim at
      the hit — **the non-interactive half is proven; the paint needs a human.**
      Applied; `docs` is defined (`scope commands` → 1) and `?` expands to
      `docs` in a config-loaded shell; the deployed `manual/` tree is present
      and carries this pass's text; `cable/docs.toml:58` opens
      `${EDITOR:-nvim} '+<line>' <manual file>`, which is the "lands in nvim at
      the hit" half as a declaration. `docs` refuses under `nu -c` by design
      (`$nu.is-interactive` is false), so no script can drive the screen — this
      is the same class as the checks in `manual → internals/unverified`.
- [x] `wc -l home/dot_config/nushell/help.nu` prints at most 200. **Ran: 198.**
      *Original note, kept:* Corrected
      2026-09-02 by the orchestrator, from the analyst's F4: 180 is not
      reachable while AGENTS.md's "preserve the hard-won why" and the
      overview's curated first-keys block both hold; the built file is 198
      (152 code, 25 blank, 21 comment) after folding `_help_curated` and
      `_help_spine` into their single callers.

## Out of scope

- The `.nuon` entries for commands other children delete — each child
  removes its own entries and runs `just manual`.
- `docs.toml` — kept as is.

## Report

spec01: exit 0
spec01 OK

spec02: exit 0
spec02 OK

spec03: exit 0

spec03 OK

spec04: exit 0
spec04 OK
