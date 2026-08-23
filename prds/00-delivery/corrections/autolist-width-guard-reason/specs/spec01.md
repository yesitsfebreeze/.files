---
est: 1h
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
---

# spec01 — the 0-column bullet, rewritten to what reproduces

## Revised at implementation time, 2026-08-23

Edit 1's text below is **not** what this spec was written with, and the
difference is the point of the node. The block first carried
`A TYPED \`la\` AT 0 COLUMNS PRINTS NOTHING AT ALL, empty directory or full,
and never spins`. The implementer measured that claim before writing it and it
is false: at 0 columns a typed bare `la` prints `Couldn't fit table into 0
columns!` on a non-empty directory (3/3) and spins on an empty one (3/3),
exactly as `la | print` and `nu -e 'la'` do. **There is no typed/printed
asymmetry.** The retired parenthetical's first half was right; only its second
half ("the print path does not") was ever wrong.

So Edit 1 says `EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME`, and WG.6's second
grep reads that anchor instead. R2 in `prd.md` was rewritten to match — this
is the bullet's fourth wording and the third a measurement retired.

Every line number in the sections below was re-measured against the file as
`config-nu-parse-claims` left it: `config.nu` is 770 lines, the bullet is at
405-409, and the gate baseline is 202 PASS / 0 FAIL.

`config.nu:405-409` justifies the auto-list width guard with an unconditional
hang and an inverted parenthetical. Replace the bullet with what nine driven
sessions produce, and add ten `WG` checks to `tests/nushell-core.sh` so
neither retired reading returns.

## The measurement, re-run 2026-08-23

Every run: nushell 0.114.1, the DSR-answering pty runner extracted from
`tests/nushell-core.sh`, a machine built like `mk_machine`'s (isolated `HOME`
with the sibling modules, the three generated init stubs, poisoned `bin`,
`PATH=$M/bin:/usr/bin:/bin`, `--no-history`). `nupty0.py` sets no winsize, so
`term size` reports 0 columns; `nuptyW.py` is `tests/shell-listing.sh`'s
variant, which sets 40×120. "guard removed" means the closure's condition is
reduced to `if ($env._NAV? | default "" | is-empty) {`, one line changed and
the line count unchanged.

| # | cols | config | target | result |
|---|---|---|---|---|
| S1 | 0 | guard off, try on | 2 × empty | `<NUPTY-TIMEOUT>`, 0 messages, `dirs.txt` holds only the first move |
| S2 | 0 | guard off, try off | 2 × empty | identical to S1 |
| S3 | 0 | guard off, try on | 200-entry, then empty | 1 message for the 200-entry dir, then timeout on the empty one |
| T1 | 0 | guard off, try on | 2 × 1-entry | 2 messages, no timeout, both moves recorded |
| T3 | 0 | guard off, try on | 3 × 1-entry | 3 messages, no timeout, three moves recorded |
| T2 | 0 | guard off, try on | 1 × empty | timeout, 0 messages |
| U1 | 0 | guard off, try **off** | 1 × empty | timeout, 0 messages |
| U2 | 40×120 | guard off, try on | 1 × empty | no timeout, prints the `empty list` box |
| U3 | 0 | **live config, guard on** | 1 × empty | no timeout, no message, prompt returns |

Typed at a 0-column prompt on the unmodified config, one session each:

| cmd | directory | result |
|---|---|---|
| `la \| print` | 1 entry | one `Couldn't fit table into 0 columns!`, then the next statement |
| `la \| print` | empty | timeout; the statement after it never runs |
| `la` | 1 entry | nothing at all — no table, no message — then the next statement |
| `la` | empty | nothing at all, then the next statement |
| `[] \| print` | — | timeout |
| `print ([] \| table)` | — | timeout |
| `[{a: 1}] \| print` | — | one message, then the next statement |

The empty case is a **CPU spin**, not a block: `ps -o %cpu,state` on the `nu`
process at 12 s, 15 s and 18 s into the hang reports `98.4 R`, `99.1 R`,
`100.0 R`. Three independent repeats of the typed empty case all timed out.

Three facts follow. The listing at 0 columns prints one message per fire on a
non-empty directory and the session carries on. On an empty directory it
spins and never returns a prompt. The `try` changes neither outcome, and the
width guard prevents both — U3 is the only 0-column run that is silent and
still answers.

## Flag for the orchestrator: R1, R2, R3 and the Purpose are wrong as written

Do not edit `prd.md`. This spec implements the measurement, not the PRD's
wording, and the orchestrator owns the rewrite.

- **R1** requires the comment to say the guard "**suppresses noise** rather
  than preventing a hang". Falsified by T2, U1 and U3: on an empty directory
  the guard is the only thing standing between a `cd` and a 100% CPU spin.
  The corrected text below says the guard does both.
- **R2** claimed a typed/printed difference in each of its two wordings, and
  neither survived. There is none: at 0 columns a typed bare `la`,
  `la | print` and `nu -e 'la'` each print one message on a non-empty
  directory and each spin on an empty one, 3/3 per cell. The retired
  parenthetical's error is the difference itself, not which path it named.
- **R3**'s reasoning ("a later reader who tests the old claim, finds no hang")
  is the failure mode inverted. A reader who tests the old claim in a
  non-empty directory finds no hang and is wrong; the empty directory is the
  case nobody tested.
- The **Purpose** asserts "**Both halves are false**". The hang half is true
  under a condition it never stated, and the sibling's replacement for it is
  false. Two claims were measured; a third reading is what reproduces.

Nothing in the requirement set changes what gets built: the guard and the
`try` stay, the comment states what reproduces, and the gate grows two
symmetric `chk_fail` greps. R4 is satisfied below.

## Edit 1 — `home/dot_config/nushell/config.nu`

Replace lines **405-409** — the bullet from `#   * on a terminal reporting 0
columns, ` through `#     terminal with no width has nowhere to put it
anyway.` — with exactly these 28 lines. Nothing above line 405 or below the
old line 409 is touched. Measured: 770 lines in, 793 lines out, longest new
line 77 characters.

```
#   * on a terminal reporting 0 columns the listing has THREE OUTCOMES, and
#     the wording retired here named none of them. Measured 2026-08-23 on the
#     pinned 0.114.1 under the DSR-answering pty runner, width guard removed
#     so the branch is reached. A NON-EMPTY directory prints ONE MESSAGE PER
#     CD — `Couldn't fit table into 0 columns!` — AND THE SESSION CARRIES ON:
#     two cds two messages, three cds three, `exit` still read, a 200-entry
#     directory no different. An EMPTY DIRECTORY SPINS THE SHELL AT 100% CPU:
#     no message, no further prompt, the next cd never read, `ps` reporting
#     state R at 98-100% until the runner kills it at its 40 s ceiling. And
#     the `try` CHANGES NEITHER OUTCOME — kept or removed, the message is
#     still printed and the spin is still unrecoverable, so neither one is a
#     catchable error.
#   * THE SPIN IS THE EMPTY TABLE AT ZERO WIDTH, NOT `la`. `[] | print` and
#     `print ([] | table)` spin identically at 0 columns, `[{a: 1}] | print`
#     prints the message and returns, and three repeats of the empty case
#     timed out identically.
#   * SO `(term size).columns > 0` IS A HANG GUARD AND A NOISE GUARD AT ONCE,
#     and the only thing that stops either — the `try` cannot. It skips the
#     listing where the terminal has no width to put it in, so a cd into an
#     empty directory is silent and the prompt returns. TWO READINGS ARE
#     RETIRED HERE. The unconditional hang claim, true only for the empty
#     directory it never mentioned; and the parenthetical that split the
#     typed path from the printed one, which claimed a difference that does
#     not exist — EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME. A typed bare
#     `la` prints the message too, and so does `nu -e 'la'`; all three spin
#     on an empty directory, 3/3 per cell. `tests/shell-listing.sh:158-166`
#     has had the message half right for months, as the reason its runner
#     sets a winsize; it never reached the empty case.
```

**R4 — every anchor the gate reads survives, checked against the patched
copy.** No `ST` or `PB` anchor lives inside lines 405-409; the nearest are
line 402 to 404, which no check reads, and line 411 (`NARROWER THAN A
SESSION-WIDE LATCH`), which is PB.2's and is below the replaced range. Run
against the patched file, all fourteen present-anchors return 1 —
`there is no child process whose stderr could be redirected`,
`ONE FULL ERROR BOX PER CD`,
`every PWD closure appended AFTER it never runs either`,
`not a session-wide latch`, `~4 µs each`,
`NARROWER THAN A SESSION-WIDE LATCH`, `REMAINDER OF ITS OWN CLOSURE`,
`every closure appended AFTER it, on EVERY fire`,
`once with \`error make\`, once with A MISSING EXTERNAL`,
`FOUR FIRES, FOUR BOXES`, `LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION`,
`AND NOTHING ENFORCES THAT ORDER`, `DIRS.TXT IS NEVER CREATED AT ALL`,
`IT IS NOT THE ONE THE LIVE CONFIG USES`. PB.1's two absent-phrases stay 0.
PB.7's and ST.6's three code lines stay 1 each. The ten `S3.14` anchors stay
one apiece and increasing. No check moves.

## Edit 2 — `tests/nushell-core.sh`

Insert after PB.7's last line — **783**, with the blank line at 784 — and
before the `CP.1 – CP.7` comment that opens at 785.

```bash
  # WG.1 – WG.7 — 00-delivery/corrections/autolist-width-guard-reason R1/R2.
  # PB.2 – PB.6 gate the `try` paragraph; these gate the bullet above it, the
  # 0-column one, whose two readings were retired on 2026-08-23. THE GREPS
  # READ THE NORMALISED PROSE, NOT THE RAW FILE, and PB.1's shape is not
  # reusable here: the retired hang claim WRAPPED ACROSS TWO COMMENT LINES,
  # so a raw `grep -qF` for it returns 0 on a red file as readily as a green
  # one and would pass forever.
  chk_fail "why: WG.1 config.nu no longer claims the listing hangs the shell" \
           has . "$CFG_TXT" 'HANGS the shell inside the hook'
  chk_fail "why: WG.1 …nor that the print path is the unguarded one" \
           has . "$CFG_TXT" 'the print path does not'
  chk_ok "why: WG.2 the 0-column bullet names all THREE OUTCOMES" \
         has . "$CFG_TXT" 'THREE OUTCOMES'
  chk_ok "why: WG.3 …the non-empty case: one message per cd, session carries on" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ONE MESSAGE PER CD')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'AND THE SESSION CARRIES ON')"
  chk_ok "why: WG.4 …the empty case, which is the one that never returns" \
         has . "$CFG_TXT" 'EMPTY DIRECTORY SPINS THE SHELL AT 100% CPU'
  chk_ok "why: WG.5 …that the try changes neither outcome" \
         has . "$CFG_TXT" 'CHANGES NEITHER OUTCOME'
  chk_ok "why: WG.5 …and that the spin is the empty table, not the listing" \
         has . "$CFG_TXT" 'THE SPIN IS THE EMPTY TABLE AT ZERO WIDTH'
  chk_ok "why: WG.6 …so the guard is load-bearing for BOTH, with the retirement named" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'A HANG GUARD AND A NOISE GUARD AT ONCE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'TWO READINGS ARE RETIRED HERE')"
  chk_ok "why: WG.6 …including the parenthetical, corrected to no asymmetry at all" \
         has . "$CFG_TXT" 'EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME'
  chk_ok "why: WG.7 …and the gate that had the message half right is cited" \
         has . "$CFG_TXT" 'tests/shell-listing.sh:158-166'
```

Ten checks: two `chk_fail`, eight `chk_ok`. Expected tally after the change
is 212 PASS / 0 FAIL, from a **202 / 0** baseline measured on the day.

## R5 — where the carrier-side greps belong

**Neither this gate nor `04-shell/06-listing`'s.** The two `chk_fail` greps
added above guard `config.nu`, which is this node's own file. The carrier-side
sweep over `prds/**/prd.md` belongs to a tree-wide gate, and it is a separate
node.

Three reasons, in order of weight.

1. **A banned-phrase grep over PRD bodies red-lights the wrong lane.**
   `tests/nushell-core.sh` reads `config.nu`, `env.nu`, `dirstack.nu`,
   `shell.nuon` and the generator — files the shell loads. It runs in wave 3
   against the shell epic. A red from a PRD body sends an implementer to the
   configuration, where nothing is wrong. `04-shell/06-listing`'s gate,
   `tests/shell-listing.sh`, has the same problem and asserts no prose at all
   today.
2. **A gate asserting another node's PRD body is a cross-node write lock.**
   It makes `04-shell/06-listing/prd.md` un-editable without editing this
   node's gate, against the board's one-writer-per-file rule. Whoever owns
   the file owns the check.
3. **A naive tree-wide grep goes red on its own correction.** The retired
   wording appears legitimately in every node that quotes it as retired —
   `stale-pwd-latch-carriers/prd.md` still holds one `for the rest of the
   session` for exactly that reason, and its own report says so. A tree-wide
   sweep therefore needs an allow-list for correction bodies, which is design
   work, not two more greps bolted onto a config gate.

The same trap appears in miniature in Edit 1, and it is why the two banned
phrases are `HANGS the shell inside the hook` and `the print path does not`
rather than the looser `HANGS` or `typed`: the replacement text quotes both
retired readings in order to retire them, and a sloppier phrase would make
the gate red against the very edit that fixes it. Verified — both phrases
return 0 against the patched file.

Recommendation: file a backlog node for a tree-wide retired-claim sweep over
`prds/**/prd.md` and `docs/*.md`, in the shape of `gates/audit-findings.sh`,
which already walks every board `prd.md`. It carries the banned set, one
allow-list entry per correction node that quotes a retired claim, and a red
counterfactual per phrase. This is the seventh wrong reason the board has
found; a seventh hand-placed grep pair does not scale, and a table of banned
phrases does.

## Acceptance

- [x] `config.nu` lines 405-409 replaced by the 28-line block, byte-identical
      to Edit 1. `wc -l` before and after quoted: 770 → 793.
- [x] No replaced line exceeds 78 **characters**. The block uses em dashes,
      and `awk 'length'` counts bytes on this machine, so measure with
      `python3`. Expected maximum 77.
- [x] The guard, the `try` and the `stty` guard are byte-unchanged: the three
      indented code lines each still occur exactly once.
- [x] Every one of R4's fourteen present-anchors returns 1 against the edited
      file, and PB.1's two absent-phrases return 0. Counts quoted.
- [x] Ten `WG` checks inserted after line 783 of `tests/nushell-core.sh`.
- [x] Both `chk_fail` greps quoted **red** on a counterfactual copy that
      re-introduces one retired reading each — two copies, one phrase apiece.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, with the
      tally quoted, not asserted. Expected 212 PASS / 0 FAIL against a 202 / 0
      baseline. Two implementers are active; a parallel run empties the pty
      output and produces false reds. `gates/waves.tsv:24` already lists
      `external bash tests/nushell-core.sh` in wave 3 — confirmed by reading
      the file, so no orchestrator-owned file needs an entry.
- [x] The report carries R6: how a census about wrong reasons blessed a wrong
      reason, and what a census does instead when a claim is cheap to run.

Measured on the ticks, 2026-08-23:

```
wc -l config.nu                 770 -> 793
block lines / max width         28 / 77
try | width guard | stty guard  1 | 1 | 1
R4 present-anchors              14 of 14 -> 1
PB.1 absent-phrases             0 | 0
S3.14 anchors                   28 104 146 304 367 502 537 567 620 672
retired phrases, normalised     0 | 0   (raw 0 | 0 before the edit too)
counterfactual cf-hang.nu       chk_fail -> FAIL (red)
counterfactual cf-typed.nu      chk_fail -> FAIL (red)
bash tests/nushell-core.sh      EXIT=0, 212 PASS / 0 FAIL, from 202 / 0
```

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
C=home/dot_config/nushell/config.nu

# 1. shape and width
wc -l "$C"                                                       # 793
python3 -c "
import sys
ls=[l.rstrip('\n') for l in open('$C')][404:432]
print('lines',len(ls),'max',max(len(l) for l in ls))"            # 28 77

# 2. the mechanism is byte-unchanged (match the INDENTED code lines)
/usr/bin/grep -cF '                try { la | print }' "$C"                                          # 1
/usr/bin/grep -cF 'if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {' "$C"       # 1
/usr/bin/grep -cF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$C"                  # 1

# 3. the retired readings are gone, and the new anchors are in — over the
#    NORMALISED prose, the same predicate the gate uses
prose() { sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$1" \
        | tr '\n\r\t\f\v' '     ' | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//'; }
for p in 'HANGS the shell inside the hook' 'the print path does not'; do
  printf '0 expected: %s -> %s\n' "$p" "$(prose "$C" | /usr/bin/grep -coF "$p")"
done
for p in 'THREE OUTCOMES' 'ONE MESSAGE PER CD' 'AND THE SESSION CARRIES ON' \
         'EMPTY DIRECTORY SPINS THE SHELL AT 100% CPU' 'CHANGES NEITHER OUTCOME' \
         'THE SPIN IS THE EMPTY TABLE AT ZERO WIDTH' \
         'A HANG GUARD AND A NOISE GUARD AT ONCE' 'TWO READINGS ARE RETIRED HERE' \
         'EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME' \
         'tests/shell-listing.sh:158-166'; do
  printf '1 expected: %s -> %s\n' "$p" "$(prose "$C" | /usr/bin/grep -coF "$p")"
done

# 4. R4 — nothing the gate reads moved
for p in 'there is no child process whose stderr could be redirected' \
         'ONE FULL ERROR BOX PER CD' \
         'every PWD closure appended AFTER it never runs either' \
         'not a session-wide latch' '~4 µs each' \
         'NARROWER THAN A SESSION-WIDE LATCH' 'REMAINDER OF ITS OWN CLOSURE' \
         'every closure appended AFTER it, on EVERY fire' \
         'once with `error make`, once with A MISSING EXTERNAL' \
         'FOUR FIRES, FOUR BOXES' 'LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION' \
         'AND NOTHING ENFORCES THAT ORDER' 'DIRS.TXT IS NEVER CREATED AT ALL' \
         'IT IS NOT THE ONE THE LIVE CONFIG USES'; do
  printf '1 expected: %s -> %s\n' "$p" "$(prose "$C" | /usr/bin/grep -coF "$p")"
done
/usr/bin/grep -cF 'stops EVERY PWD closure firing' "$C"          # 0
/usr/bin/grep -cF 'for the rest of the session' "$C"             # 0

# 5. R5 — both chk_fail greps red on a counterfactual, one phrase each
# Each retired reading goes back WRAPPED ACROSS TWO COMMENT LINES, which is
# the shape a raw `grep -qF` cannot see. One phrase per copy.
T="$(mktemp -d)"
sed '404a\
#     `la | print` at 0 columns HANGS the shell inside\
#     the hook — no prompt ever paints again.' "$C" > "$T/cf-hang.nu"
sed '404a\
#     (The display path a TYPED `la` takes guards; the print\
#     path does not.)' "$C" > "$T/cf-typed.nu"
for f in cf-hang cf-typed; do
  for p in 'HANGS the shell inside the hook' 'the print path does not'; do
    printf '%-9s %-34s raw=%s normalised=%s\n' "$f" "$p" \
      "$(/usr/bin/grep -coF "$p" "$T/$f.nu")" \
      "$(prose "$T/$f.nu" | /usr/bin/grep -coF "$p")"
  done
done   # each copy: raw=0 for both, normalised=1 for its own phrase only
rm -rf "$T"

# 6. the gate, ALONE
bash tests/nushell-core.sh; echo "EXIT=$?"                       # EXIT=0, 212/0
```
