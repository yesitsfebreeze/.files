---
state: done
claim: 
priority: 24
est: 0.75h
actual: 10m
mode: afk
needs:
  - 00-delivery/corrections/sibling-gates-copymode-staging
verify: ""
origin: derived
from: 00-delivery/corrections/cdi-manual-source
---

# `shell-zoxide`'s entry count says six; the corpus now has seven

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/shell-zoxide.sh` asserts `tree: exactly six entries name this
PRD as their source` with a hardcoded `-eq 6`. `shell.nuon` now holds
**seven** entries citing `prds/04-shell/03-zoxide/prd.md`, because
[`cdi-manual-source`](../cdi-manual-source/prd.md) reassigned the `cdi` entry
to that owner — correctly, and that node is `done`. The gate is the stale
side.

**This is a self-inflicted wound worth reading twice.** `cdi-manual-source`
was a two-file, one-field correction whose whole point was to repair a
provenance link. It did that, its own gate
(`nu tests/help-content-model.nu`) passed, and it broke a *sibling* gate that
counts citations of the PRD it repointed to. Nothing connected the two: the
content-model gate validates the corpus, and the count lives in the zoxide
node's gate. A correction with a green verify can still land a red gate
elsewhere.

**And it went unnoticed for exactly the reason the copymode outage exists.**
`tests/shell-zoxide.sh` was already red — 28 FAILs from the missing
`copymode.nu` staging — so a 29th changed nothing anyone could see. It
surfaced only when
[`sibling-gates-copymode-staging`](../sibling-gates-copymode-staging/prd.md)'s
analyst measured the gate's *post-fix* verdict and found one residual FAIL.
That node cannot fix it: its R3 forbids changing any assertion, which is the
right rule and the reason this is a separate node.

Deps on that node because the count is only observable once the gate runs.

## Requirements
- [x] **R1** — The check passes against the corpus as it stands. Read the
      actual citation count rather than trusting this PRD's "seven" — more
      entries may have been reassigned by the time this runs.
- [x] **R2** — **The count stops duplicating a list that already exists.**
      Settled by the analyst, 2026-08-23, and recorded so no implementer
      re-takes it: the defect is not the literal, it is the **duplication**.
      Line 396 already declares the roster as a six-name presence loop, and
      line 401 restates that list's *length* as `6`, free to drift from it.

      **What lands:** one declared roster (`ZOXIDE_HELP_IDS`), the expected
      count derived from it (`${#ZOXIDE_HELP_IDS[@]}`), and the assertion
      becomes **set equality** between "ids citing this PRD" and the roster,
      with failure printing `counted [...]; MISSING [...]; UNEXPECTED [...]`
      and a line telling the reader that an UNEXPECTED id means another node
      reassigned an entry here. A relationship, not an absolute.

      **Deriving the count from the corpus was considered and rejected**,
      and the reason generalises: counting `source:` occurrences and
      comparing that to anything computed from the same field of the same
      file is `n == n`. Repoint an entry and *both* sides move together, so
      the check that exists to notice reassignment becomes the one thing
      blind to it. The counterfactual dies. A derived expectation needs an
      **independent** declaration, and outside the gate there is none — the
      PRD body is prose, and `shell.nuon`'s `source:` field is the artifact
      under test. This PRD's own R2 offered "derive from the corpus" as an
      option; it was wrong to.

      Exhaustiveness is kept deliberately. `tests/theme-switcher.sh:461`
      uses the weaker set-filtered-length form, which **cannot see a foreign
      entry arriving** — and that arrival is exactly the event that fired
      here.
- [x] **R3** — Nothing else in `tests/shell-zoxide.sh` changes, and no
      corpus file is touched. The corpus is right; the gate is wrong.
- [x] **R4** — **Census the other gates for the same shape.** Any gate
      asserting a hardcoded count of corpus entries by source is the same
      tripwire. List them with their literals, and report — a second one is
      its own node.

## Acceptance
- [x] `bash tests/shell-zoxide.sh` reaches `EXIT=0` with 0 FAIL, run
      **alone**, the command and its tally quoted. The measured pre-fix
      baseline was 71 PASS / 1 FAIL, and that 1 is this node's. The PASS
      count after is **quoted, not asserted** — 74 is the expectation, not
      the contract. Pinning a fresh absolute would re-commit the exact error
      this node corrects.
- [x] A counterfactual: the check still fails when it should — repoint one
      entry away in a scratch copy and quote the gate going red. A count
      check that cannot fail is worse than a wrong one.
- [x] The R4 census is in the report, listing every hardcoded corpus-count
      assertion found in `tests/` with its literal.

## Proof

Run alone, 2026-08-23. `bash tests/shell-zoxide.sh` — before: 71 PASS /
1 FAIL, `EXIT=1`, the FAIL being `tree: exactly six entries name this PRD as
their source`. After: **74 PASS / 0 FAIL, `EXIT=0`**. The count is quoted,
not asserted anywhere.

The check now names the ids:

```
PASS  tree: exactly 7 entries name this PRD as their source, and they are
      the ones it owns: <word> cdi z <query> zc <query> zi zl <query> zz
PASS  tree: counterfactual one-entry-repointed-away FAILS the citation-set
      check
```

Both counterfactual directions go red on a scratch copy of the corpus, the
corpus itself unwritten (`shell.nuon` sha unchanged at `600dde9d…`):

```
A: one entry repointed away
counted [<word> cdi zc <query> zi zl <query> zz]; MISSING [z <query> ];
UNEXPECTED []                                                    [rc=1]
B: the foreign `grep` entry (02-aliases-utilities) repointed in
counted [<word> cdi grep z <query> zc <query> zi zl <query> zz];
MISSING []; UNEXPECTED [grep ]                                   [rc=1]
```

Scope: `tests/shell-zoxide.sh` is untracked, so `git diff` over it is empty
by construction. Proven against a `cp`-aside baseline taken before the edit —
`diff -u` shows five hunks, all in that one file.

R4 census — every hardcoded count of corpus entries by source in `tests/`:

| Gate | Literal | State |
|---|---|---|
| `tests/shell-zoxide.sh:401` | `-eq 6` | fixed here; now set equality against `ZOXIDE_HELP_IDS` |
| `tests/shell-claude.sh:237` | `-eq 2` | accurate today, latent — same shape, own node |
| `tests/shell-history.sh:427` | `-eq 4` | accurate today, latent — same shape, own node |

`tests/theme-switcher.sh:461` is the weaker filter-then-length form: it
cannot see a foreign entry arriving. Not adopted here.

## Out of scope
- `shell-television`'s three residual FAILs, which are a television-lane
  defect recorded on
  [`04-shell/04-television`](../../../04-shell/04-television/prd.md).
- Re-reassigning the `cdi` entry. `cdi-manual-source` was correct; this is
  the gate catching up.
