---
est: 0.5h
footprint:
  - prds/04-shell/06-listing/prd.md
  - prds/04-shell/06-listing/specs/spec02-autolist-hook.md
executor: orchestrator   # both files belong to 04-shell/06-listing
---

# spec01 — both carriers, corrected to the measured radius

Replace one passage in each carrier with the pre-resolved text below. Both
files belong to `04-shell/06-listing`, a `done` node, so **the orchestrator
makes this edit**; no implementer may write another PRD's body.

Nothing else in either file changes. No box changes. No file outside the
footprint changes — `home/dot_config/nushell/config.nu` in particular is the
parent node's, and its own 0-column bullet is a separate correction named in
**The residue** below.

The replacement text is final. Do not re-derive it and do not re-measure the
three-closure result: it is measured twice in
[`pwd-closure-blast-radius`](../../pwd-closure-blast-radius/prd.md)'s
[spec01](../../pwd-closure-blast-radius/specs/spec01.md) (M1, M2, M4, M5).
The measurements this spec adds are **D1** to **D7** below.

## The verdict on the three pty measurements

The carriers sell the retired claim as one of "three pty measurements on
0.114.1". Each was re-measured on 2026-08-23 against the pinned 0.114.1,
under the gate's own DSR-answering pty runner and a machine built like
`tests/nushell-core.sh`'s (`HOME` with the real modules, poisoned `bin`,
`PATH=$M/bin:/usr/bin:/bin`, `--no-history`).

**1. "the hook runner discards a closure's return value (bare `la` shows
nothing)" — STANDS.** Do not retire it.

- **D1, mechanism.** A minimal config whose only PWD closure logs the fire
  and then runs a bare `ls`; the same with `ls | print`. Winsize 40×120 so
  the width guard is out of the way. Bare: 2 fires logged, 0 table rows in
  the transcript, 0 errors. Piped to `print`: 2 fires, the table present.
- **D2, this config.** The real `config.nu` with `try { la | print }`
  replaced by a bare `la`, one `cd` into a directory holding one marked
  file. Bare: `dirs.txt` records the move — so the closure ran — and the
  marked filename never appears, with no error. Control, unmodified
  `config.nu`: the filename appears once.

**2. "`la | print` hangs the shell outright on a 0-column pty" — DOES NOT
REPRODUCE.** What reproduces is a graceful message, and the parenthetical in
`config.nu` that assigns the guard to the typed path only is backwards.

- **D3.** Width guard and `try` both removed, no winsize (so `term size`
  reports 0 columns): the transcript holds one
  `Couldn't fit table into 0 columns!`, no table, no `<NUPTY-TIMEOUT>`, and
  `dirs.txt` recorded the move. Ran twice, identical. Two `cd`s give two
  messages and the shell still reads `exit`.
- **D4.** Same config, winsize 40×120: the table prints, no message. So the
  0-column path is what produces D3.
- **D5.** Width guard removed, **`try` kept**: the message still appears. It
  is a display message, not a catchable error.
- **D6.** Typed at a 0-column prompt on the unmodified config: `la | print`
  and a bare `la` each print the same one line. The print path is not
  unguarded.
- **D7.** 200-entry directory, 0 columns, guard and `try` removed: one
  message, no hang. Not a size effect.
- Corroboration inside the carrier's own node:
  `tests/shell-listing.sh:158-166` records, as the reason its runner sets a
  winsize, that "pty.fork leaves the pty at 0 columns and nushell then
  prints `Couldn't fit table into 0 columns!` instead of any listing". The
  PRD bullet and the gate written for it disagree; the gate is right.

**3. "an error thrown in one PWD closure stops every PWD closure — dirstack
included — for the rest of the session" — RETIRED**, both halves. Per-fire
and forward-only (M1, M2: `c1=4 c2-tail=0 c3=0`, four error boxes, `error
make` and a missing external indistinguishable), and the dirstack is what
survives, because its append comes first (M3, M5) and nothing enforces that
order (M4: appended ahead of the dirstack push, `dirs.txt` is never created).

One of the three stands. The width guard and the `try` both keep their
place — the guard suppresses one noise line per `cd`, the `try` bounds an
abort to one closure onward.

## Edit 1 — `prds/04-shell/06-listing/prd.md`

Replace the bullet at **lines 112-117**, which begins
`- **The hook body is \`try { la | print }\` behind` and ends
`for the rest of the session.`, with:

```markdown
- **The hook body is `try { la | print }` behind
  `(term size).columns > 0`.** Three pty measurements on 0.114.1 stood
  behind it; re-measurement on 2026-08-23 kept one and rewrote two.
  - **Stands.** The hook runner discards a closure's return value: a bare
    `la` fires, displays nothing, and raises no error. Counterfactual on
    this config — `la` in place of `try { la | print }` records the move in
    the dirstack and prints no table, `try { la | print }` prints it.
  - **Rewritten.** `la | print` on a 0-column pty does not hang. It prints
    one `Couldn't fit table into 0 columns!` per fire and the session
    continues; a typed `la` prints the same line, and `try` does not
    swallow it, so it is a display message and not an error. The width
    guard suppresses one noise line per `cd`; it is not a hang guard.
    `config.nu`'s comment still reads HANGS — its own correction.
  - **Retired.** An error in one PWD closure does not stop every PWD
    closure for the rest of the session, and "dirstack included" is
    inverted. The abort reaches the remainder of the failing closure and
    every closure appended after it, on every fire, and the dirstack
    survives because its append comes first — nothing enforces that order.
    Measured twice with a three-closure config: `error make` and a missing
    external are indistinguishable, `c1=4 c2-tail=0 c3=0`, four boxes, one
    per fire.
    [`pwd-closure-blast-radius`(../../../../../../prds/00-delivery/corrections/00-delivery/corrections/pwd-closure-blast-radius/prd.md)
    holds the measurements; the `try` stays.
```

The two neighbouring findings bullets (`The live LS_ICONS glyphs do not
exist`, `gates/selftest.sh exits 1`) are untouched.

## Edit 2 — `prds/04-shell/06-listing/specs/spec02-autolist-hook.md`

Replace the paragraph at **lines 74-80**, which begins
`Two measured deviations from the closure as drafted above` and ends
`what the \`try\` prevents.`, with:

```markdown
Two measured deviations from the closure as drafted above, both forced by
the acceptance boxes and recorded in the block's own comment: the hook
runner discards a closure's return value, so the listing is
`try { la | print }`, and it sits behind `(term size).columns > 0` because
on a 0-column pty `la | print` prints one
`Couldn't fit table into 0 columns!` per fire instead of a table.
Re-measured 2026-08-23 on 0.114.1: the discard reproduces exactly; the
0-column line is a display message that `try` does not catch and a typed
`la` prints too, and the session survives it — the guard suppresses noise,
not a hang. The `try` catches whatever else the render throws, and its
reach is one closure onward on every fire, not the session: an error takes
the remainder of the failing closure and every closure appended after it,
while the dirstack survives because its append comes first. Measurements in
[`pwd-closure-blast-radius`(../../../../../../prds/00-delivery/00-delivery/corrections/pwd-closure-blast-radius/prd.md).
```

The acceptance boxes above that paragraph and the `## Verify` block below it
are untouched.

## Acceptance

- [ ] The retired claim is gone from both files. Over
      `prds/04-shell/06-listing/prd.md` and
      `prds/04-shell/06-listing/specs/spec02-autolist-hook.md`:
      `for the rest of the session` → 0 hits, `stops every PWD closure` → 0,
      `hangs the shell outright` → 0, `HANGS the shell on a 0-column pty`
      → 0.
- [ ] The corrected phrases are in, once per file:
      `Couldn't fit table into 0 columns!`,
      `every closure appended after it`, `because its append comes first`.
      `c1=4 c2-tail=0 c3=0` appears once in `prd.md`.
- [ ] **R3** — no box changed: `grep -c '^[[:space:]]*- \[[ x~]\]'` over
      every file under `prds/04-shell/06-listing` is identical before and
      after, totals quoted per file. `git diff -U0` cannot carry it — that
      directory holds 0 tracked files of 4 (`git ls-files --error-unmatch`, 2026-08-23), so the piped
      count is `0` for any edit at all, including one that rewrote every box.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: those
      per-file counts, taken before the first write.
- [ ] Nothing outside the footprint changed. `git status --porcelain` names
      exactly those two files plus this node's own directory.
- [ ] Tier A stays at 0 broken, as a delta: baseline
      `python3 gates/tree-links.py --tier a --count-only` → `0` before the
      edit and `0` after. Tier B stays at `114`, so the two new links
      resolve rather than adding breakage.
- [ ] `bash gates/tree-links.sh` exits 0.
- [ ] No replaced line exceeds 78 **characters** except the two link lines
      (the text uses em dashes, so count characters, not bytes).

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
P=prds/04-shell/06-listing/prd.md
S=prds/04-shell/06-listing/specs/spec02-autolist-hook.md

# retired wording, all four phrases, both files — every count must be 0
for pat in 'for the rest of the session' 'stops every PWD closure' \
           'hangs the shell outright' 'HANGS the shell on a 0-column pty'; do
  printf '%s: ' "$pat"; /usr/bin/grep -cF "$pat" "$P" "$S" | tr '\n' ' '; echo
done

# corrected wording
/usr/bin/grep -cF "Couldn't fit table into 0 columns!" "$P" "$S"   # 1 and 1
/usr/bin/grep -cF 'every closure appended after it' "$P" "$S"      # 1 and 1
/usr/bin/grep -cF 'because its append comes first' "$P" "$S"       # 1 and 1
/usr/bin/grep -cF 'c1=4 c2-tail=0 c3=0' "$P"                       # 1

# R3 — no acceptance or requirement box touched
git diff -U0 -- prds/04-shell/06-listing \
  | grep -cE '^[-+][[:space:]]*- \[[ x~]\]'                        # 0

# footprint
git status --porcelain

# links: Tier A delta 0, Tier B unchanged
python3 gates/tree-links.py --tier a --count-only                  # 0
python3 gates/tree-links.py --tier b 2>/dev/null | grep -c '^BROKEN '  # 114
bash gates/tree-links.sh > /dev/null; echo "tree-links exit=$?"    # 0

# 78 characters, link lines excepted
python3 - "$P" "$S" <<'PY'
import sys
for f in sys.argv[1:]:
    for n, l in enumerate(open(f), 1):
        l = l.rstrip("\n")
        if len(l) > 78 and "(../../../../../../prds/00-delivery/corrections/stale-pwd-latch-carriers/specs/" not in l:
            print(f"{f}:{n} {len(l)} chars")
print("length check done")
PY
```

## The residue — name it, do not fix it here

- **`config.nu`'s 0-column bullet is wrong.** Lines 381-385 say `la | print`
  "HANGS the shell inside the hook — no prompt ever paints again", and
  attribute the `Couldn't fit table into 0 columns!` guard to the typed path
  only. D3 – D7 contradict both halves, and
  [`pwd-closure-blast-radius`](../../pwd-closure-blast-radius/prd.md)'s
  spec01 blessed that bullet as exact (its M7), so the correction has to
  reopen it. `config.nu` is outside this footprint. **Needs its own backlog
  node**, and it is bigger than this one: it changes a comment `ST`/`PB`
  checks read, and the `(term size).columns > 0` guard keeps its place with
  a different reason — one suppressed noise line per `cd`, not a hang.
- **Nothing gates the wording in the two carriers.** `PB.1` keeps the
  retired reading out of `config.nu` only. The symmetric guard is two
  `chk_fail` greps in `tests/nushell-core.sh`'s `--tree` stage, next to
  `PB.1`, asserting `for the rest of the session` and
  `stops every PWD closure` appear in neither carrier. Do not add them
  here: that gate is ~187 checks and belongs to the `config.nu` node above,
  which must edit it anyway.
- **`prds/02-terminal/02-startup-layout/prd.md` and
  `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md`** also
  match `for the rest of the session`. Unread by this spec — a different
  claim about a different subsystem. Not this node's, and not asserted to be
  wrong.

## Out of scope

- `home/dot_config/nushell/config.nu`, in every part. The latch paragraph is
  the parent node's landed work; the 0-column bullet is the residue above.
- `tests/nushell-core.sh`, `tests/shell-listing.sh`, and every other gate
  file. This spec adds no check.
- Frontmatter of any `prd.md`, including `04-shell/06-listing`'s. It stays
  `done`.
- The requirements, acceptance boxes and `## Verify` block of either
  carrier.
