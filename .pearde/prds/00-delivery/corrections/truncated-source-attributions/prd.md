---
state: done
claim: 
priority: 11
est: 0.5h
actual: 10m
mode: afk
needs:
verify: ""
origin: derived
---

# Nine PRD headers cite a `source:` entry name that is cut off mid-string

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: E.7's analyst noticed (2026-08-23) that its own PRD header reads
`source: "LSP (mason + native` and stops — the opening quote is never closed
and the inventory entry name is incomplete. A census of the tree found
**nine** PRDs with the same defect, which makes it an artifact of the
2026-08-20 board conversion rather than a slip in one file.

**Amended 2026-08-23 by the orchestrator: seven became nine.** This node was
filed off an unbalanced-quote census, and its analyst showed that check is a
proper *subset* of the defect R1 describes — two more paragraphs break after
the closing quote and before the inventory link, leaving a balanced quote and
a dangling connector `in`. The census command is therefore two-dimensional:
an odd `"` count **or** a paragraph ending on a dangling connector. That
flags exactly nine over all 93 files. The two the original filing missed are
marked below.

A third dimension was tested and rejected — "quotes an entry name but names
no inventory file" flags six further PRDs that are not truncated at all (the
four `01-capsule` headers, `04-shell/08-claude-launchers`, and
`05-platform/01-deploy-mechanism/repo-skeleton`, which sources a sibling PRD
rather than an inventory). A complete name with no link is a style question,
not this defect.

| PRD | header ends at |
|---|---|
| [`03-editor/04-plugin-manager`](../../../03-editor/04-plugin-manager/prd.md) | `source: "lazy.nvim bootstrap` |
| [`03-editor/05-completion`](../../../03-editor/05-completion/prd.md) | `source: "Completion` |
| [`03-editor/07-formatting`](../../../03-editor/07-formatting/prd.md) | `source: "Format on save" in` — **balanced quote, dangling `in`** |
| [`03-editor/08-telescope`](../../../03-editor/08-telescope/prd.md) | `source: "Fuzzy finder` |
| [`03-editor/09-lsp`](../../../03-editor/09-lsp/prd.md) | `source: "LSP (mason + native` |
| [`03-editor/10-treesitter`](../../../03-editor/10-treesitter/prd.md) | `source: "Treesitter" in` — **balanced quote, dangling `in`** |
| [`03-editor/13-statusline`](../../../03-editor/13-statusline/prd.md) | `source: "Statusline` |
| [`03-editor/15-markdown-tables`](../../../03-editor/15-markdown-tables/prd.md) | `source: "Markdown table` |
| [`04-shell/05-history`](../../../04-shell/05-history/prd.md) | `source: "Directory-scoped` |

Why it matters rather than being cosmetic: [`AGENTS.md`(../../../../../AGENTS.md)
makes the header the provenance link — the `source:` names the inventory entry
whose `C`/`U` the header must match, and the rating rules exist so a later
reader can go check that the numbers were not invented. A name cut off
mid-phrase breaks that link in exactly the seven places a reader would follow
it, and six of the nine PRDs are still unbuilt, so the next analyst to open one
cannot verify its rating.

Distinguish this from the ~78-column wrap, which is correct and must survive:
most `Parent:` lines wrap onto a continuation line and finish the attribution
there. These nine never finish it. Two near misses were checked and are
deliberately excluded — `01-capsule/04-recent-workspaces`
(`"Recent-workspace picker"`) and `04-shell/08-claude-launchers`
(`"Claude launchers"`) name complete entries and stop.

## Requirements
- [x] **R1** — Each of the nine headers names the complete inventory entry,
      with the quote closed, wrapped at ~78 columns per the repo convention.
      The full name comes from the inventory the header points at — the
      `capabilities-*.md` in [`docs/`(../../../../../docs) — not from a guess
      at what the phrase was going to say.
- [x] **R2** — Each restored name resolves to an entry that actually exists
      in the named inventory, and that entry's complexity and usefulness
      numbers **match the header's `C`/`U`**. A mismatch is a second finding:
      report it, do not silently edit either side to agree.
- [x] **R3** — Nothing else in any of the nine files changes. No
      requirement, acceptance box, or frontmatter key is touched.

## Acceptance
- [x] The two-dimensional census over the whole tree finds zero `Parent:`
      paragraphs with an odd `"` count and zero ending on a dangling
      connector — the check that found these nine, re-run, with its output
      quoted. The one-dimensional quote check is **not** sufficient: the two
      extras satisfy it while still being truncated.
- [x] For each of the nine, the restored entry name is quoted alongside the
      inventory heading it matched and both `C`/`U` numbers, so the match is
      on the record rather than asserted.
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken **and** its link
      count rises by exactly **9** — one new inventory link per file —
      measured as a before/after pair in the same session, not against a
      fixed number. "Still green" would pass on nine links that all resolve
      nowhere; the delta is what proves a wrong `../../../` depth was not
      shipped. Tier B's 114 broken links are pre-existing, live entirely
      under `specs/**`, and never gate.

      *The absolute baseline moved after this box was written:* the analyst
      measured Tier A at 621 links, and orchestrator cross-links added
      during the same session took it to 654. That is exactly why the box
      now names a delta — an absolute count in a tree several lanes are
      writing is stale before the implementer reads it.

## Out of scope
- Rewriting any header that is merely wrapped. A closed quote on a
  continuation line is correct.
- Correcting a `C`/`U` that turns out not to match its inventory entry. R2
  makes that a reported finding, and it is its own correction with its own
  rating argument — silently moving either number is how a rating stops
  meaning anything. **R2 came back with no finding:** the analyst resolved
  all nine against the inventories and every `C`/`U` pair already agrees, so
  nothing is expected to trip this. The clause stays because a later reader
  should know the check was run, not skipped.
- The "complete name, no inventory link" style question the third census
  dimension surfaced. Six PRDs read that way and none of them is truncated.
