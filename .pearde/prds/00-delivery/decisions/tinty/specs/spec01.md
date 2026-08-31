# spec01 — Record the answer in the corrections backlog, decision item 2

est: 0.5h

## Goal

This node's own acceptance says the answer is recorded, with a date, in the
file this node names as its spec — and `.mi/gantt/plan.json` names exactly one
file for D.1b: `.mi/prds/00-delivery/corrections/prd.md`. Today that file's
numbered open-decisions list still asks the question as open ("2. **Does tinty
stay?**"), and the S1 terminal table's T-3 row still ends "Resolve
deliberately". A settled fork left standing as an open question is an
invitation for the next agent to answer it a second time, differently.

Decision item 4 in the same list already established the recorded shape — a
bold **Decided <date> (user)** headline followed by "What the decision
settles". Item 2 is rewritten into that shape, and the two other sentences in
this file that the answer makes **false** are corrected with it.

**Footprint warning — read before dispatching.** Three decision tickets record
into this one numbered list: D.1b (this one, item 2), D.1c (`fzf`, item 3) and
D.1d (`wallpaper-opacity`, whose subject is the T-11 row and the C-1
`Ctrl+Shift+B` collision). They cannot run concurrently; the orchestrator must
serialise them. This spec is deliberately confined to **decision item 2, the
T-3 row, and one parenthetical in the S2 coverage-gaps list** — nothing else
in the file is touched, and the verify below asserts that item 3 and the T-11
row survive byte-intact so a concurrent sibling's work cannot be silently
clobbered. If a sibling has already landed, re-read the list and keep its
text; only item 2 is ours.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — body only, three places.
  **Do not edit the frontmatter block.**

Nothing else. In particular do **not** touch
`.mi/prds/02-terminal/01-appearance/prd.md` (see "Why T.1 is not edited"
below), the inventories in `.mi/docs/` (spec02), `.mi/prds/README.md` or
`.mi/SYSTEM.md` (spec03), or the four gated feature PRDs (spec04, spec05).

## What to write

### 1. Replace open-decision item 2 in full

The current item is:

> 2. **Does tinty stay?** It owns the palette that WezTerm, Neovim, and tv all
>    inherit (T-3), but it is `DEFER`red as cosmetic. If it goes, something
>    else must own the palette; if it stays, it is not cosmetic.

Replace it with, keeping the `2.` numbering and the list's indentation, and
wrapping at ~78 columns:

> 2. **Does tinty stay?** **Decided 2026-08-21 (user): tinty stays as palette
>    owner, and the `DEFER` "cosmetic" verdict on it is withdrawn.** It is
>    infrastructure, not decoration. Recorded from
>    [`00-delivery/decisions/tinty`](../prd.md), where the
>    fork was put to the human.
>
>    What the decision settles:
>    - (a) **The chain, top to bottom.** `tinty apply` writes both
>      `~/.config/wezterm/colors.lua` and its cached tinted-shell artifact.
>      WezTerm `dofile`s the former (never `require`, which caches by module
>      name and would return the *first* palette on a second apply) and
>      re-tints every window, tab and pane, because `config.colors` is
>      WezTerm-wide. `config.nu` sources the latter so a new shell re-asserts
>      the active scheme's OSC escapes. F6 delegates the switch to nushell's
>      `theme.nu` (`_theme_toggle`), bound in WezTerm rather than the shell so
>      it works under a full-screen TUI. Neovim (base16 + transparent) and
>      television (`default` ANSI theme) inherit downstream. Nothing below
>      WezTerm hardcodes hex values.
>    - (b) **This resolves T-3 in T-3's favour.** Palette ownership is not
>      WezTerm's: WezTerm *reads* what tinty writes. Where a document says
>      "the terminal owns the palette", that wording is now a defect to
>      correct, not an invariant to preserve.
>    - (c) **Nodes reconciled against this answer:**
>      `04-shell/01-core-config` (S.1) — the tinty palette re-assert in
>      `config.nu` is **kept**, not orphaned, and becomes a requirement;
>      `03-editor/11-colorscheme` (E.5) and `03-editor/13-statusline` (E.13) —
>      the palette they derive from is tinty's, and E.5 records how far the
>      inheritance actually reaches; `02-terminal/01-appearance` (T.1) — see
>      (e).
>    - (d) **The inventory verdicts move off `DEFER`:** the theme switcher in
>      `capabilities-nushell.md` (to `SIMPLIFY` — the palette-owning core is
>      minimal base, the background-override ladder/tuner is not), and the F6
>      theme toggle and per-pane OSC retint in `capabilities-terminal.md` (to
>      no marker). No `C`/`U` number changes: the ratings measure intricacy
>      and daily value, the marker records membership, and it is the marker
>      the human overrode.
>    - (e) **What this opens.** The switcher now needs a home. `theme.nu` (the
>      A/B slots, `_theme_toggle`, the tv scheme picker) has no node in
>      `04-shell`, and the F6 binding has no node in `02-terminal`; the latter
>      is inside `w0-2-terminal-respec` R5's remit ("give the ~230 uncovered
>      lines a home"); the former now has a node, `04-shell/09-theme-switcher`
>      (S.9), created by the orchestrator on 2026-08-21 once this answer
>      landed. Neither is specced here — this node records a decision, it does
>      not implement one — but they are missing work now, not deferred work.
>      `06-help` will owe the resulting command and keybinding a manual entry.

Do not renumber items 1, 3 or 4, and do not edit their text. Item 1 (burrito)
reads as open here although the README records it decided 2026-08-20; that
mismatch is real but belongs to `w0-2-terminal-respec` / W0.4g, not to this
spec.

### 2. Correct the T-3 row in the S1 terminal table

Its last sentence, "Resolve deliberately.", is now discharged. Replace only
that sentence with:

> **Resolved 2026-08-21 (D.1b): tinty stays and owns the palette — see open
> decision 2.**

Leave the rest of the row, and every other row, alone. Tables are exempt from
the wrap rule — do not re-wrap it.

### 3. Correct the S2 coverage-gaps parenthetical

Under `## S2 — coverage gaps found`, the **Shell** bullet reads "the tinty
palette re-assert in `config.nu` (orphaned if theme is dropped)". The
condition is now settled the other way. Replace the parenthetical with
`(kept — open decision 2; specified as `04-shell/01-core-config` R10)`.

Do not otherwise edit that bullet: `ollama-host`, `starship`,
`$env.ENV_CONVERSIONS` and the rest are `w0-4-s2-corrections/shell` R6's.

Do not mark any box `[x]` or `[~]`. Nothing here is implemented.

## Why T.1 is not edited in place

`02-terminal/01-appearance/prd.md` is listed as gated on this decision, and it
is the one gated node whose requirements must **not** be reconciled in place:
its own escalation section records that four of the five config fields it
names are rejected by the installed WezTerm, that its palette source `/src/colors`
does not exist, and that `.mi/gantt/plan.json` already says "real requirements
come from W0.2's rewrite, not this file as it stands today".
`w0-2-terminal-respec` owns that file and rewrites it from
`.mi/docs/capabilities-terminal.md`. Editing it here would fork a spec that is
scheduled for deletion.

T.1's reconciliation therefore lands on W0.2's **inputs** — the T-3 row above,
and the two inventory entries spec02 corrects — so that the rewrite cannot be
performed against a stale deferral. That is the reconciliation, and it is why
the verify below asserts T.1's file is untouched.

## Acceptance

- [ ] Open-decision item 2 carries the literal `Decided 2026-08-21 (user)`,
      says tinty **stays**, and states that the `DEFER` verdict is withdrawn.
- [ ] Item 2 records the mechanism chain by name: `colors.lua`, `dofile`,
      `theme.nu`, `F6`, and "Nothing below WezTerm hardcodes hex values".
- [ ] Item 2 names all four gated nodes — `04-shell/01-core-config`,
      `03-editor/11-colorscheme`, `03-editor/13-statusline`,
      `02-terminal/01-appearance`.
- [ ] Item 2 links the decision node `decisions/tinty`.
- [ ] Item 2 records what the decision opens: that the switcher needs a home
      node and that W0.2 R5 owns the F6 half.
- [ ] Item 2 no longer contains the conditional phrasing `If it goes` — the
      question is not restated as live.
- [ ] The T-3 row contains `Resolved 2026-08-21` and no longer says
      `Resolve deliberately`.
- [ ] The S2 coverage-gaps Shell bullet no longer says `(orphaned if theme
      is dropped)` — note it is wrapped across two lines in the file today.
- [ ] Decision item 3 (fzf) is byte-intact: it still reads
      `fzf is an accepted, documented exception`.
- [ ] The T-11 row (D.1d's subject) still contains
      `background image cycling` and is otherwise untouched.
- [ ] `02-terminal/01-appearance/prd.md` carries no decision record from this
      spec and still has its `## Escalation` section. (It cannot be guarded
      with `git diff --quiet`: that file already has uncommitted changes from
      another lane in the working tree.)
- [ ] The node-level acceptance box "The three open decisions have a recorded
      answer, in this file, with a date" is **still open**. It cannot close on
      this spec: decision item 1 (burrito) is still written as an open
      question in this file even though it was settled 2026-08-20, and
      recording that is `w0-2-terminal-respec`/W0.4g's, not ours. A `[x]` we
      did not prove is a false record.
- [ ] This spec closes no box. (Note: the file already carries one `[x]` — the
      "Every S1 item is either fixed or converted into a task" box, closed by
      the `wallpaper-opacity` lane while it held the file. That one is not
      ours to reopen.)
- [ ] The frontmatter block is byte-identical: `shasum -a 256` of the leading
      `---` fence of `prds/00-delivery/corrections/prd.md`, equal before and
      after, both quoted. The original clause was dead twice over — its
      pathspec was `.mi/prds/00-delivery/corrections/prd.md`, a path removed
      with the `.mi` tree, and the live file is untracked (`git ls-files --error-unmatch`, 2026-08-23)
      so a diff over it is silent anyway. Unprovable in retrospect: the
      pre-edit state was untracked, so git never held a copy and no `cp` aside
      was kept. What would have proved it: that fence hash, taken before the
      first write.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/00-delivery/corrections/prd.md; rc=0; I2() { awk "/^2\\. \\*\\*Does tinty stay/{i=1} /^3\\. /{i=0} i" "$f"; }; for s in "Decided 2026-08-21 (user)" "stays as palette owner" "verdict on it is withdrawn" "colors.lua" "dofile" "theme.nu" "F6" "Nothing below WezTerm hardcodes hex values" "04-shell/01-core-config" "03-editor/11-colorscheme" "03-editor/13-statusline" "02-terminal/01-appearance" "decisions/tinty" "w0-2-terminal-respec" "R5"; do I2 | grep -qF "$s" || { echo "FAIL: decision item 2 lacks: $s"; rc=1; }; done; I2 | grep -qF "If it goes" && { echo "FAIL: item 2 still restates the open question"; rc=1; }; grep -qF "Resolve deliberately" "$f" && { echo "FAIL: T-3 still says Resolve deliberately"; rc=1; }; grep -qF "Resolved 2026-08-21" "$f" || { echo "FAIL: T-3 carries no dated resolution"; rc=1; }; grep -qF "(orphaned" "$f" && { echo "FAIL: coverage-gap parenthetical not corrected"; rc=1; }; grep -qF "fzf is an accepted, documented exception" "$f" || { echo "FAIL: the fzf decision item was disturbed"; rc=1; }; grep -qF "background image cycling" "$f" || { echo "FAIL: the T-11 row was disturbed"; rc=1; }; grep -qF "[ ] The three open decisions have a recorded answer" "$f" || { echo "FAIL: the three-decisions acceptance box was closed or reworded; item 1 (burrito) is still unrecorded here"; rc=1; }; t=prds/02-terminal/01-appearance/prd.md; grep -qF "Decided 2026-08-21 (user)" "$t" && { echo "FAIL: a decision record was written into T.1; W0.2 owns that rewrite"; rc=1; }; grep -qF "tinty" "$t" || { echo "FAIL: T.1 no longer names tinty as the palette owner"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

Proven RED against the current tree before being written here: it reports all
fifteen missing strings in decision item 2, `item 2 still restates the open
question`, `T-3 still says Resolve deliberately`, `T-3 carries no dated
resolution`, and `coverage-gap parenthetical not corrected`, exiting 1. The
four negative guards (fzf item, T-11 row, and the two on T.1) pass today and
exist to fail if the implementer strays outside item 2.
