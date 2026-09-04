Verdict: SPECCED

# every derived node names the prd whose work surfaced it — report

## Build

Ran `pearde doctor pearde` — baseline `origin broken · 312 derived · 6 with
no from:` (the purpose line's `106 derived · 4 with no from:` had already
drifted since the PRD was filed; see Findings). Read
`resources/doctor.sh`'s origin check directly rather than trusting the
prose: it flags any `prd.md` whose frontmatter has `origin: derived` and no
`from:` line. `grep -rl '^origin: derived'` plus a per-file frontmatter scan
over the canonical `pearde/prds/` tree found exactly four such nodes:

1. `09-simplify/retire-the-unmanaged-television-channels`
2. `09-simplify/propagate-a-tinty-apply-into-a-running-nvim`
3. `09-simplify/silence-the-chezmoi-config-template-drift-warning`
4. `09-simplify/retire-the-two-unmanaged-television-preview-scripts`

Each node's own text carries an "Established ... by ... on `<prd>`" sentence
naming its source, and each named PRD directory exists on disk. Added
`from: <prd>` under `origin: derived` in each of the four files (see
`specs/spec01.md`). Re-ran the doctor check: the canonical tree's no-from:
count is 0.

## Findings

- **`pearde doctor`'s origin check double-counts through stale lane
  worktrees, outside this PRD's footprint.** `find "$BOARD" -type f -name
  prd.md` recurses into `.lanes/*`. The worktree
  `.lanes/09-simplify-retire-the-unmanaged-television-channels` -- for a PRD
  already `state: done` and merged at `bb86993` -- was never removed and
  still carries a pre-rename `.pearde/prds` tree, duplicating two of the
  four fixed nodes without `from:`. After this spec, whole-board `pearde
  doctor` still reads `2 with no from:`, both stranded copies of nodes
  already fixed above. Removing (or re-syncing) that stale worktree is a
  lane-hygiene defect, not a naming-provenance one, and is outside this
  PRD's footprint. Recorded on the board's knowledge record:
  `[[260904-a2b8]]`.
- The PRD's own Purpose line (`106 derived · 4 with no from:`) was already
  stale by the time of this build (`312 derived · 6 with no from:`) -- same
  stale-worktree cause, worsening as more lanes accumulate.

## Scores

complexity: 3
blast-radius: low
workflow: name-the-surfacing-prd-from-its-own-record

## Route

## Use when

- A derived PRD's own body already names the work that surfaced it, in
  prose, and the frontmatter's `from:` link to that work is what a check
  reads and the PRD text does not supply.
- Not when the naming has to be inferred or guessed from context the node's
  own text does not state -- that is a QUESTION, not this workflow.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `locate-the-check-that-flagged-it` | the purpose line was already stale (106/4 vs the live 312/6); reading the doctor script's own condition rather than the prose is what kept the fix aimed at the real check | `stop` |
| 2 | `census-the-class-not-the-instance` | one grep over every `prd.md`'s frontmatter found all four flagged nodes at once, and incidentally surfaced two stranded duplicates the check also counts | `→ 1` |
| 3 | `read-the-provenance-from-the-nodes-own-text` | all four nodes carry their own "Established ... by ... on `<prd>`" sentence; reading it, and confirming the named directory exists, is what the contract requires instead of a guess | `stop` |
| 4 | `write-the-traced-value-into-frontmatter` | added `from: <prd>` under `origin: derived` in each of the four files | `→ 3` |
| 5 | `rerun-the-flagged-check` | re-ran `pearde doctor` and watched the no-from: count fall by exactly four on the canonical tree, which is what separated "fixed" from "counted elsewhere" | `→ 1` |

### atomic locate-the-check-that-flagged-it

## Do

1. Find the script or command that produced the exact wording in the PRD's
   Purpose line (here, `grep -rn '<the phrase>' resources/*.sh`).
2. Read its condition directly -- the exact frontmatter keys and comparison
   it makes -- rather than the paraphrase in the PRD body, which can go
   stale between when it was written and when the fix lands.

## Done when

- The condition you will fix against is quoted from the check's own source,
  not from the PRD's prose description of it.

### atomic read-the-provenance-from-the-nodes-own-text

## Do

1. For each flagged node, read its own body for the sentence recording
   what surfaced it -- a fixed phrase such as "Established ... by ... on
   `<prd>`" is common in this board's derived nodes.
2. Confirm the named PRD directory exists on disk before using it as a
   value; a name in prose that resolves to nothing is not a trace, it is a
   guess with a citation.

## Done when

- The traced value is a real, existing PRD directory, and the sentence it
  came from is quoted in the spec or report that uses it.

### atomic write-the-traced-value-into-frontmatter

## Do

1. Add the traced key (here, `from: <prd>`) immediately after the
   frontmatter key that required it (`origin: derived`), one line per node.

## Done when

- Every flagged node's frontmatter carries the new line, in the same
  position, with no other frontmatter line disturbed.

### atomic rerun-the-flagged-check

## Do

1. Re-run the exact check located in step 1 against the same scope it
   originally read.
2. Compare the new count against the baseline: it must fall by exactly the
   number of nodes fixed. A smaller drop means something outside the fixed
   set is still being counted -- read what, before declaring done.

## Done when

- The check's count drops by exactly the number of nodes fixed; any
  remaining count is attributed to a specific, named cause rather than left
  unexplained.
