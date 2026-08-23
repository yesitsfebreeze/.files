---
state: open
claim: 
priority: 12
est:
mode: afk
needs:
  - 01-capsule/03-credential-propagation
verify: "nu tests/help-content-model.nu"
origin: derived
from: 00-delivery/corrections/capsule-creds-refresh-wording
---

# Three claims about capsule credentials that the code does not support

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: three findings recorded in the `why-review.nuon` row by
[`capsule-creds-refresh-wording`](../capsule-creds-refresh-wording/prd.md)'s
reader, all outside that node's one-sentence scope. Each is a documented
claim that the shipped `home/dot_config/capsule/executable_setup-credentials.sh`
does not support.

1. **`600/700` does not describe every copied key.** `*.pub` is installed at
   **644** (`setup-credentials.sh:67`), which is correct for a public key —
   the defect is the documentation saying the copy preserves `600/700`
   throughout, not the mode.
2. **The no-prompt guarantee rests on the wrong mechanism.** It actually
   comes from `StrictHostKeyChecking accept-new` (`:115`), not from the
   best-effort `ssh-keyscan -T 5` pre-add (`:121-130`). The keyscan is an
   optimisation; `accept-new` is the guarantee. Documenting the optimisation
   as the guarantee means a later reader can delete the guarantee and keep
   what looks like the reason.
3. **The `why` is silent on agent auth**, which is half of what its `use`
   promises. The entry says credentials reach the capsule; it explains the
   git and SSH halves and never says how `claude` and `opencode` come up
   authenticated — the keychain export and the deliberate symlink into the
   read-only mount.

Why these matter beyond tidiness: item 2 is a **security-relevant** reason
attached to the wrong line, and item 3 is the half of the feature an agent
reading `help` before working inside a capsule most needs. This is also the
review ritual working as designed — a reader with no stake in the wording
found three things the author and the spec both missed.

## Requirements
- [ ] **R1** — The entry describes the actual mode set, distinguishing
      private keys and directories (600/700) from public keys (644), with
      the line reference. If the *code* is wrong rather than the prose, say
      so and stop — changing `setup-credentials.sh` is C.3's, not this
      node's.
- [ ] **R2** — The no-prompt guarantee is attributed to
      `StrictHostKeyChecking accept-new`, with the `ssh-keyscan` pre-add
      described as the optimisation it is. Both line references present.
- [ ] **R3** — The agent-auth half is documented: the keychain export, and
      that the tokens are **symlinked** into the read-only mount so a
      container cannot run its own OAuth refresh and rotate the host's
      refresh token out from under it. That reason is the expensive part —
      carry it, do not summarise it away.
- [ ] **R4** — Word budget respected. The corpus maximum is 156 words
      (`terminal.nuon [lit and dim tabs]`) and this entry's `why` is now
      153. R3 adds material, so something has to give: either the entry
      splits, or the existing prose tightens. Say which and why rather than
      quietly exceeding the ceiling.
- [ ] **R5** — Every edited entry re-digests through the gate's own helper,
      with a reader-reviewer distinct from the author, per the ritual
      [`cdi-manual-source`](../cdi-manual-source/prd.md) R2 established. The
      `why-review.nuon` note carrying these three findings is retired in the
      same change — a note must not outlive its own fix.

## Acceptance
- [ ] `nu tests/help-content-model.nu` passes, output quoted.
- [ ] Each of the three claims is quoted beside the `setup-credentials.sh`
      line that justifies it.
- [ ] The word count of every `why` touched is stated, and none exceeds 156.
- [ ] `why-review.nuon` carries no note describing a defect this change
      fixed.

## Out of scope
- Changing `setup-credentials.sh`. If a mode or a mechanism is genuinely
  wrong rather than mis-documented, that is a finding to report and C.3's to
  fix.
- Whether `help` should run inside a capsule — it cannot, and
  [`06-help/02-help-command`](../../../06-help/02-help-command/prd.md) R9
  records why.

## Questions

All three claims hold against the shipped script, so the fork is not about
truth. It is about R4. Four measurements, taken 2026-08-23 against the tree,
frame it:

- **Nothing gates length.** `tests/help-content-model.nu` holds `use` to a
  five-word floor (`USE_MIN_WORDS`) and holds `why` to presence, shape and a
  current row in `why-review.nuon`. 156 is the corpus maximum, not a rule.
- **One entry cannot carry R1, R2 and R3 under 156 words.** Measured on
  minimal replacement sentences that drop no fact: hygiene 16, SSH modes 28,
  `accept-new` 27, `.gitconfig` 9, the HTTPS refresh block 71, the directory
  bind 26, agent auth 46 — 223 words. Reaching 156 means deleting the
  71-word HTTPS block, which
  [`capsule-creds-refresh-wording`](../capsule-creds-refresh-wording/prd.md)
  landed after two independent readings.
- **A two-way split at the agent seam still lands at 177.** Every reviewed
  word intact, minus the agent material.
- **`topics.nuon`'s `agents` topic already promises "what a capsule hands an
  agent", and no entry delivers it.** R3's material has a home in the spine
  already.

---

Question *Q1*: **How does the entry split, and what pays for R4?**

Three routes, each spending something different.

**A — two entries, ceiling kept.** `credentials in a capsule` keeps SSH, git
identity and the HTTPS refresh; a new entry carries agent auth. The concept
entry reaches ~152 words only by recompressing the hygiene sentence, the
directory-bind sentence and the two new R1/R2 sentences. Cost: a session
that did not take the measurements rewrites prose two readers just settled.

**B — two entries, ceiling raised.** The same split, no compression. The
concept entry lands at ~177 words and becomes the corpus maximum. Cost: the
only quantitative norm R4 leans on is reset, and the hub `why` is a wall of
six mechanisms.

**C — three entries, one mechanism each.** `credentials in a capsule` keeps
hygiene, git identity, the HTTPS refresh and the directory bind (~122
words); a new SSH entry carries the modes and the `accept-new` guarantee
(~71); a new agents entry carries the keychain export and the symlink
(~46–105). Nothing exceeds the current maximum and no reviewed word is
touched. Cost: the manual grows by two entries and four review rows, two
readings are needed rather than one, and one question a reader asks ("how do
my credentials get in") is answered across three entries linked by `also`.

Recommendation **C**. It is the only route that keeps both the ceiling and
every reviewed word, and it ends the collision instead of deferring it: the
next correction against C.3 hits the same 156 words under A and B. The
counter-argument is surface — a correction node growing the manual by two
entries — which is why this is the user's call and not the analyst's.

---

Question *Q2*: **What are the new entries called?**

Ids are cited by `also`, by `help <entry>` and by both review files, so the
id is the interface. The file's concept ids are lower-case phrases:
`credentials in a capsule`, and `mkcd`, `<word>`, `tv channel` elsewhere.

For the agent entry: `agents in a capsule` (recommended), `agent auth in a
capsule`, or `claude and opencode in a capsule`. Title: "Understand how an
agent comes up authenticated"; `understand` is already on the gate's
`IMPERATIVE_VERBS`. Topic `agents`, which the spine already promises;
`mode: "container"`.

For the SSH entry, under route C only: `ssh in a capsule`, title
"Understand how SSH works inside a capsule", topic `containers`,
`mode: "container"`.

Recommendation `agents in a capsule` and `ssh in a capsule` — they parallel
`credentials in a capsule`, which is what a reader scanning the topic sees.

---

Question *Q3*: **Does `credentials in a capsule` keep promising the agents
in its `use`?**

Its `use` today names four outcomes: `git pull`, `git push`, `ssh -T`,
`claude` and `opencode`. Under any split, the mechanism for some of them
moves to a sibling entry.

Keeping the `use` byte-identical keeps `use-review.nuon:215`'s reading valid
— that digest keys on `use` and `source`, both unchanged, so the row stays
`d922b7e911810476` and no second reading is owed. `also` carries the reader
to the sibling entries, and `also` is in neither digest.

Narrowing the `use` to what the entry now explains costs a fresh reading
against [`01-capsule/03`](../../../01-capsule/03-credential-propagation/prd.md)
R4 and a new `use-review.nuon` digest, for every entry whose `use` changes.

Recommendation keep the `use` untouched and add the new ids to `also`. The
sentence is a true outcome statement, and the README's rule is to cross-link
rather than duplicate.

## Answers

Answered 2026-08-23 by the user, in the round the analyst asked.

- **Q1 — route C: three entries, one mechanism each.** `credentials in a
  capsule` keeps hygiene, git identity, the HTTPS refresh and the directory
  bind; a new SSH entry carries the modes (600/700 for private keys and
  directories, 644 for `*.pub`) and the `accept-new` guarantee with the
  `ssh-keyscan` pre-add named as the optimisation it is; a new agents entry
  carries the keychain export and the read-only symlink, with the reason
  intact — a container must not run its own OAuth refresh and rotate the
  host's refresh token out from under it. **R4 is satisfied by the split, not
  by compression:** no entry exceeds the current 156-word maximum, and no
  word two readers already settled is rewritten. Two extra entries and four
  review rows are the accepted cost.
- **Q2 — the new ids are `agents in a capsule` and `ssh in a capsule`.**
  Titles "Understand how an agent comes up authenticated" and "Understand how
  SSH works inside a capsule"; `understand` is already on the gate's
  `IMPERATIVE_VERBS`. Topics `agents` and `containers` respectively — the
  `agents` topic in `topics.nuon` already promises "what a capsule hands an
  agent" and no entry delivers it. Both `mode: "container"`.
- **Q3 — `credentials in a capsule` keeps its `use` byte-identical.** The
  sentence is a true outcome statement, so the reading at
  `use-review.nuon:215` stays valid and its digest `d922b7e911810476` is not
  reopened; `also` carries the reader to the two new ids, and `also` is in
  neither digest. Cross-link, do not duplicate.

R5 still binds: every edited or new entry re-digests through the gate's own
helper with a reader distinct from the author, and the `why-review.nuon` note
carrying these three findings retires in the same change.
