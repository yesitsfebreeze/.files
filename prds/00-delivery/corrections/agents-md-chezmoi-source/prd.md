---
state: open
claim:
priority: 34
est:
mode: afk
footprint:
  - AGENTS.md
verify: "bash gates/tree-links.sh"
origin: derived
---

# `AGENTS.md` sends every specifying agent to a two-month-stale chezmoi clone

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `AGENTS.md:55-58` — "Live sources to read when specifying (never edit
them as part of PRD work)" — ends its list with `~/.local/share/chezmoi`.
Finding **M-21** in this same backlog establishes that path is a **June clone,
two months stale**, and that measurement must go through
`chezmoi source-path` instead.

**This is the worst possible carrier for that error.** `AGENTS.md` is the file
every agent reads before touching anything, and this is the sentence that
tells them where the ground truth lives. An analyst following it specs against
a two-month-old snapshot — which is precisely the failure mode the whole
`02-terminal` re-spec exists to atone for, and which `AGENTS.md` itself warns
about four lines earlier ("Verify against the live config, always").

M-21 is recorded in the backlog as **unowned**. Found again by
`census-verdict-discipline`'s analyst while auditing the same file, which is
how an unowned finding usually surfaces: someone trips over it twice.

## Requirements
- [ ] **R1** — **Re-measure first.** Establish what `chezmoi source-path`
      returns now and whether `~/.local/share/chezmoi` is still stale, or
      still exists. M-21 was recorded some time ago and this node must not
      inherit its measurement — the board has been bitten twice this session
      by exactly that, and its own new rule says a cheap claim gets run.
- [ ] **R2** — The line names the way to find the source, not a literal path
      that can drift: `chezmoi source-path`, with the reason. If a literal
      path is worth keeping as an example, it is labelled as one.
- [ ] **R3** — **Census the other carriers.** M-21 is unowned and this is one
      more carrier; there are likely others. Sweep `prds/`, `docs/` and
      `AGENTS.md` for `~/.local/share/chezmoi` and for any other place a
      chezmoi source is named literally. Report each with its owner.
- [ ] **R4** — M-21's backlog row gets its disposition updated to name this
      node, so the finding stops being unowned. That row is the orchestrator's
      edit — report the wording.
- [ ] **R5** — The `## Conventions` and `## Where things live` sections are
      checked for the same claim, since both describe where things are read
      from. Report, do not widen.

## Acceptance
- [ ] R1's measurement quoted — `chezmoi source-path` output, and the state
      of `~/.local/share/chezmoi`.
- [ ] The corrected line quoted, with its reason.
- [ ] The R3 census in the report, one row per carrier with its owner.
- [ ] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count — the tree is written by several
      lanes and an absolute is stale before it is read.

## Out of scope
- Editing anything under `~/.local/share/chezmoi` or the live chezmoi source.
  They are read-only reference.
- Any other M-* finding.
