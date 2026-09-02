---
state: done
claim: 
priority: 31
est: 1h
mode: afk
needs:
  - 00-delivery/corrections/stale-pwd-latch-carriers
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
verify: ""
origin: derived
from: 00-delivery/corrections/stale-pwd-latch-carriers
---

# `config.nu:381-385`'s hang claim is true under a condition it never states

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the comment justifying the auto-list width guard reads:

> on a terminal reporting 0 columns, `la | print` HANGS the shell inside the
> hook — no prompt ever paints again. (The display path a TYPED `la` takes
> guards with "Couldn't fit table into 0 columns!"; the print path does not.)

**This node was filed saying both halves are false. That was wrong, and the
correction is the point.** Rewritten 2026-08-23 by the orchestrator after a
third analyst re-ran it across sixteen driven pty sessions and varied the one
input nobody had varied: **whether the target directory is empty.**

| at 0 columns | result |
|---|---|
| `la \| print`, **non-empty** dir | one `Couldn't fit table into 0 columns!` per fire, session carries on — 2 cds → 2 messages, 3 → 3, `exit` still read, 200 entries no different |
| `la \| print`, **empty** dir | **spins the shell at 100% CPU** — no message, no further prompt, the next `cd` never read, killed at the runner's 40 s ceiling. `ps -o %cpu,state` at 12/15/18 s: `98.4 R`, `99.1 R`, `100.0 R`. Three repeats, three timeouts |
| `try` kept vs removed | changes neither outcome |
| typed bare `la`, either dir | prints **nothing at all**, never spins |
| `[] \| print`, `print ([] \| table)` | spin identically — so it is **the empty table at zero width**, not `la` |
| live config, guard intact, empty dir | silent, prompt returns |

So: **the "HANGS" claim is true**, under a condition it never stated. The
parenthetical is **inverted but not symmetric** — `la | print` emits the
message, a typed `la` emits nothing. And `tests/shell-listing.sh:158-166` was
right about the half it describes and never reached the empty case.

**Both previous analysts measured honestly and both generalised from one
directory.** `pwd-closure-blast-radius`'s M7 used empty scratch dirs, saw a
hang, and wrote "That bullet is exact. Do not touch it."
`stale-pwd-latch-carriers`' analyst used a one-entry and a 200-entry dir, saw
a message, and refuted it. Neither varied the input. The discriminator cost
two `touch`es.

## Requirements
- [x] **R1** — The comment states the **three-way** reading: at 0 columns a
      non-empty directory prints one `Couldn't fit table into 0 columns!` per
      `cd`, an **empty** directory spins the shell at 100% CPU with no
      message and no further prompt, and the `try` catches neither. The guard
      is therefore **the only thing between a `cd` and a CPU spin**, not a
      noise filter. *R1 originally said the opposite — "suppresses noise
      rather than preventing a hang" — and that is falsified.*
- [x] **R2** — **There is no typed/printed asymmetry at all.** The
      parenthetical's *first* half is right and its *second* half is wrong:
      a typed bare `la` **does** print `Couldn't fit table into 0 columns!`,
      and so does `la | print`. Neither is guarded and neither is silent.

      *Rewritten a second time, 2026-08-23, by the orchestrator — this is the
      **fourth** wording this bullet has had, and the third that a
      measurement retired.* R2 previously said "a typed bare `la` emits
      nothing". Falsified by 24 driven pty sessions on the live `config.nu`
      in an isolated `HOME`, with `term size` at that prompt returning
      `{"columns": 0, "rows": 0}`:

      | typed at a 0-column prompt | non-empty dir | empty dir |
      |---|---|---|
      | `la \| print` | 1 message, next statement ran — 3/3 | timeout, next statement never ran — 3/3 |
      | bare `la` | **1 message, next statement ran — 3/3** | **timeout — 3/3** |
      | `nu -e 'cd …; la'` | 1 message, no timeout | timeout |

      Raw excerpt from a typed bare `la`, message immediately after the echoed
      command with no hook involved:

      ```
      …/mm/full1> laCouldn't fit table into 0 columns!
      ```

      So the comment must say: **at 0 columns every route prints one message
      on a non-empty directory and spins on an empty one** — typed `la`,
      `la | print` and `nu -e 'la'` alike. The retired parenthetical's error
      is not that it named the wrong path; it is that it claimed a difference
      that does not exist.
- [x] **R3** — **The guard stays, and now for a much stronger reason than
      this node was filed with.** *R3's original reasoning was inverted:* a
      reader who tests the old claim finds no hang **because they tested a
      non-empty directory**. The comment must make the empty case impossible
      to miss, because that reader is the failure mode.
- [x] **R4** — `ST` and `PB` anchors survive. **Established: none lives
      inside 381-385.** The nearest are 378/380 (ungated) and 387
      (`NARROWER THAN A SESSION-WIDE LATCH`, PB.2's, below the range).
      Verified against a patched copy — all fourteen present-anchors → 1,
      PB.1's two absent-phrases → 0, PB.7/ST.6's three code lines → 1 each,
      `S3.14`'s ten anchors once apiece and increasing. **No check moves.**
- [x] **R5** — Two `chk_fail` greps guard **this file only**, over the
      **normalised** prose — PB.1's raw-grep shape is not reusable here,
      because the retired hang claim wraps across two comment lines and a raw
      `grep -qF` for it would pass on a red file forever. The banned phrases
      must be `HANGS the shell inside the hook` and `the print path does not`,
      **not** `HANGS` — the replacement text quotes both retired readings in
      order to retire them. The carrier-side sweep is **not** built here; see
      [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md).
- [x] **R6** — The report answers how a census about wrong reasons blessed a
      wrong reason, and what changes. **Answered at spec time; carry it
      forward rather than re-deriving it** — the three changes are in
      [`census-verdict-discipline`](../census-verdict-discipline/prd.md).

## Acceptance
- [x] The corrected comment quoted beside the **empty-directory** measurement
      — the `ps -o %cpu,state` readings and the three repeats — and beside
      the non-empty message case. Both, or the comment is back to describing
      one fixture.
- [x] `[] | print` and `print ([] | table)` shown to spin identically, so the
      record says the subject is the empty table at zero width and not `la`.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted. Measured **202 → 212 PASS / 0 FAIL**, `EXIT=0`,
      all ten `WG` checks green. The "187 → 197" this box carried was stale
      before the node was claimed; see the section below.
- [x] R5's two greps quoted red on a copy carrying each retired wording, and
      the wrap-across-lines case shown to be caught by the normalised form
      where a raw `grep -qF` is not.

## Out of scope
- Removing or narrowing the guard or the `try`.
- The two PRD carriers, already corrected by
  [`stale-pwd-latch-carriers`](../stale-pwd-latch-carriers/prd.md).
- `02-terminal/02-startup-layout` and `w0-2-terminal-respec/specs/spec03.md`,
  which match `for the rest of the session` about a **different** subsystem
  and were explicitly not asserted wrong.

## Numbers that were stale, measured on the transition

The implementer stopped before writing anything and re-measured. Carry these,
do not re-derive them:

- **Gate baseline is 202 PASS / 0 FAIL**, not the spec's 187 or this PRD's
  "expected 197". `config-nu-parse-claims` landed 15 checks in between.
- **`config.nu` is 770 lines**, not 730. The bullet is at **405-409**, not
  381-385, so a 28-line replacement lands 770 → 793.
- **R4's claim holds and only its line numbers were stale.** Re-verified
  against the file as it is: 405-409 hold only the retired bullet, the nearest
  above is an ungated bullet at 402-404, and PB.2's anchor is on line **411**,
  below the range. The CP anchors sit at 146-163, ST.5's at 435-462,
  CP.6/CP.7's at 498-516.
- **Edit 2's "after line 634" is stale**: PB.7 now ends at line **783**, blank
  at 784, the CP block starts at 785.

**R5's hazard is already red on the live file, which is the cleanest possible
demonstration.** Both retired phrases are present in `config.nu` right now and
both wrap across comment lines:

```
phrase HANGS the shell inside the hook    raw=0  normalised=1
phrase the print path does not            raw=0  normalised=1
```

A raw-grep `chk_fail` pair would have passed on a red file forever.

## Closed 2026-08-23 — and `actual:` is deliberately empty

`bash tests/nushell-core.sh` → **EXIT=0, 202 → 212 PASS / 0 FAIL**, re-run by
the orchestrator. All ten `WG` checks green; `grep -ci 'HANGS the shell inside
the hook'` over `config.nu` → **0**. `config.nu` has 33 changed lines and
**zero** of them are non-comment.

**No `actual` is recorded, and the reason is the rule.** Calibration requires
one dispatch with no BLOCKED round-trip, and this run had one — because **R2
was wrong when I wrote it.** The elapsed time measures my error and the
implementer's correction of it, not the cost of the work. A wrong number is
worse than none.

**The round-trip is the node's best outcome.** The implementer stopped before
writing anything, left both files byte-unchanged, and refused to put a
measured-false claim into `config.nu` and gate it — which is precisely the
failure this node exists to end. It then revised the spec's own text at
implementation time and said so in the file: Edit 1's `A TYPED \`la\` … PRINTS
NOTHING AT ALL` was measured false **before it was written**, so the block says
`EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME` and WG.6's grep reads that anchor
instead.

**R5's evidence is the cleanest on the board**, and it is a two-by-two rather
than an assertion. Both retired phrases wrap across comment lines, so a raw
`grep -qF` is blind to them:

```
before the edit   HANGS the shell inside the hook    raw=0  normalised=1
before the edit   the print path does not            raw=0  normalised=1

cf-hang.nu        HANGS the shell inside the hook    chk_fail -> FAIL (red)
cf-hang.nu        the print path does not            chk_fail -> PASS
cf-typed.nu       HANGS the shell inside the hook    chk_fail -> PASS
cf-typed.nu       the print path does not            chk_fail -> FAIL (red)
config.nu         both                               chk_fail -> PASS
```

Each counterfactual re-introduces **one** wrapped reading and only its own
grep goes red. A raw-grep pair would have passed on both red files forever —
and the replacement text names both retired readings without reproducing
either banned string, checked at normalised counts 0 and 0.

It also fixed the counterfactual snippet itself: the spec's version inserted
each retired reading on a **single line**, which a raw grep would have caught,
so it would have tested the wrong hazard. It now wraps them across two comment
lines, which is the shape that actually occurs.

**R6, in its own words, and it is one datum past what the process node
records:** the census asked each carrier "is this reason right?" and accepted
the first answer that reproduced. Both earlier analysts ran the bullet honestly
and both ran it in **one** directory, so each saw half the behaviour and
generalised — then a verdict travelled as settled fact. *"What a census owes a
claim this cheap is the varied input, not the second opinion."* Its own BLOCKED
report is that lesson applied one turn earlier: the third wording was retired
**before** it reached the file rather than after.
