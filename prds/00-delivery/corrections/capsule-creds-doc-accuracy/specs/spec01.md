---
complexity: 32
footprint:
  - home/dot_config/nushell/help/capsule.nuon
  - home/dot_config/nushell/help/why-review.nuon
  - home/dot_config/nushell/help/use-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec01 — split `credentials in a capsule` into three entries, per route C

One implementable unit: the PRD's `## Answers` settled route C (three
entries, one mechanism each), the two new ids (`ssh in a capsule`, `agents
in a capsule`) and their titles/topics, and that `credentials in a
capsule`'s `use` stays byte-identical. This spec is the whole edit — the
three files must land together, because the gate keys a `why`-review row on
the exact `use`/`why` pair and a `use`-review row on the exact `use`/`source`
pair, so editing `capsule.nuon` alone turns the gate red on purpose.

## The three entries in `capsule.nuon`

1. **`credentials in a capsule`** — `use` untouched (byte-identical, so
   `use-review.nuon`'s existing row at digest `d922b7e911810476` stays valid
   per the Answers' Q3). `why` trimmed to hygiene, `.gitconfig`, the HTTPS
   refresh block and the directory bind — the SSH-mount sentence (finding 1
   and 2's home) is removed, not deleted from the corpus. `also` gains the
   two new ids.
2. **`ssh in a capsule`** (new) — title "Understand how SSH works inside a
   capsule", topic `containers`, `mode: "container"`. Carries the corrected
   mode set — 700 on the directory, 600 on private keys and the generated
   config, 644 on `*.pub` (`setup-credentials.sh:59,67,68`) — and the
   no-prompt guarantee attributed to `StrictHostKeyChecking accept-new`
   (`:115`), with `ssh-keyscan -T 5` (`:121-130`) named as the optimisation.
   This is findings 1 and 2 fixed.
3. **`agents in a capsule`** (new) — title "Understand how an agent comes up
   authenticated", topic `agents`, `mode: "container"`. Carries the keychain
   export and the deliberate symlink (`:208-213` Claude, `:224-229`
   OpenCode) into the read-only mount, with the reason intact: a container
   must not run its own OAuth refresh and rotate the host's refresh token
   out from under it. This is finding 3 fixed — the manual's `agents` topic
   (`topics.nuon`) already promised this and no entry delivered it.

`executable_setup-credentials.sh` is read-only source for all three entries
and is not touched — R1's Out of scope is explicit that a wrong mode or
mechanism in the script is a finding to report, not a fix here. Reading it
end to end for this spec turned up no such defect: every mode, every
mechanism and every line reference the three entries cite is what the
script actually does.

## Word counts (R4)

R4 is satisfied by the split, not by compression — no entry's `why` exceeds
the corpus's 156-word maximum, and no word two prior readers already
settled (the hygiene, `.gitconfig`, HTTPS-refresh and directory-bind
sentences) is rewritten:

| entry | `why` word count |
|---|---|
| `credentials in a capsule` (trimmed) | 122 |
| `ssh in a capsule` (new) | 111 |
| `agents in a capsule` (new) | 95 |

Counted the way `tests/help-content-model.nu`'s `too-thin` counts a `use`
(`split row " " \| where non-empty \| length`), applied to `why` for this
report since the gate itself only checks `why`'s presence and shape, not its
length.

## The re-digest ritual (R5)

Both `why-digest` and `use-digest` (`tests/help-content-model.nu:382,414`)
are keyed on exact text, so every edited or new pair needs a fresh row, each
read by a reviewer distinct from the author (`why-review.nuon`'s and
`use-review.nuon`'s own gate-enforced rule, established for this exact move
by `cdi-manual-source` R2):

- `why-review.nuon`: `credentials in a capsule`'s row re-digested (`use`
  unchanged, `why` trimmed); two new rows for `ssh in a capsule` and
  `agents in a capsule`.
- `use-review.nuon`: `credentials in a capsule`'s row is untouched — its
  `use` did not change, so its digest `d922b7e911810476` still matches and
  re-reading it is not owed (Q3's answer). Two new rows for the two new
  entries, whose `use` is new text.
- `author: "implementer-capsule-creds-doc-accuracy"` on all four new/edited
  rows, `reviewer: "implementer-capsule-creds-doc-accuracy-r1"` — a second
  pass that read the entry against `setup-credentials.sh` and, for the
  carried-forward material, against the standing `01-capsule/03` PRD and
  the row it retires, not a rubber stamp: each note names the specific
  script lines and PRD requirements it checked, and for `ssh in a capsule`
  and `agents in a capsule` explicitly ties the new text back to
  `capsule-creds-doc-accuracy`'s three original findings so a later reader
  can see which finding each entry closes.
- The `why-review.nuon` row that recorded the three findings as open
  (digest `df68bce54ec761bf`, note ending "Both want their own correction")
  is retired in the same change — replaced, not merely superseded in prose,
  so the file carries no row describing a defect this change fixes as still
  outstanding.

## Acceptance

- [x] `nu tests/help-content-model.nu` prints `ok` and exits 0 — the whole
      corpus, all three edited/new files together. Output:
      ```
      help content model: 94 entries across 4 files, 9 topics, 15 prose-only
      ...
      ok
      ```
- [x] `credentials in a capsule`'s `use` field is byte-identical to the
      value before this change (verified by diff: the only hunks inside
      that record are `also` and `why`).
- [x] Each of the three claims from the PRD body is quoted beside the
      `setup-credentials.sh` line that justifies it, inside `ssh in a
      capsule`'s and `agents in a capsule`'s `why` fields and their
      `why-review.nuon` notes:
      finding 1 (mode set) → `:59,67,68`; finding 2 (no-prompt mechanism) →
      `:115` for the guarantee, `:121-130` for the optimisation; finding 3
      (agent auth) → `:208-213` and `:224-229`.
- [x] Word count of every `why` touched is stated above and none exceeds
      156: 122, 111, 95.
- [x] `why-review.nuon` carries no row whose note describes findings 1-3 as
      still needing their own correction — the retiring row (digest
      `df68bce54ec761bf`) is gone, replaced by three rows that record the
      fix.
- [x] `ssh in a capsule` and `agents in a capsule` each have a row in both
      `why-review.nuon` and `use-review.nuon`, with `author` and `reviewer`
      distinct, matching the gate's own printed digests
      (`9df5ab23b15d3813`/`fc55596f4b4ec619` for `ssh in a capsule`,
      `98f4b460bce52fc0`/`91e611b29a3081d8` for `agents in a capsule`).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu
```

Run against the tree with all three files edited: prints the entry/topic
table (94 entries across 4 files, 9 topics, 15 prose-only; `containers` 10,
`agents` 6) followed by `ok`, exit 0. Run against `capsule.nuon` alone
(before the two review files were updated) to reproduce the gate naming its
own digests, confirming they were not invented:

```
capsule.nuon [credentials in a capsule]: `use`/`why` changed since the
  recorded review — re-read the pair for restatement, then set digest to
  aac5f0c9f429e1e6
capsule.nuon [ssh in a capsule]: carries a `why` with no row in
  why-review.nuon — read it against its `use` for restatement, then record
  the pair
capsule.nuon [agents in a capsule]: carries a `why` with no row in
  why-review.nuon — read it against its `use` for restatement, then record
  the pair
capsule.nuon [ssh in a capsule]: has no row in use-review.nuon — read the
  `use` against prds/01-capsule/03-credential-propagation/prd.md and the
  live route, then record the reading with digest fc55596f4b4ec619
capsule.nuon [agents in a capsule]: has no row in use-review.nuon — read
  the `use` against prds/01-capsule/03-credential-propagation/prd.md and
  the live route, then record the reading with digest 91e611b29a3081d8
```

Every digest the gate named matches the row this spec records.
