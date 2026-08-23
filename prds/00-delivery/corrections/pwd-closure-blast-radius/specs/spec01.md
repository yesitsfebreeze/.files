---
est: 0.5h
footprint:
  - home/dot_config/nushell/config.nu
verify: "bash tests/nushell-core.sh"
---

# spec01 — the `try` bullet states the blast radius that reproduces

Replace lines 386-390 of `home/dot_config/nushell/config.nu` — the
`* the `try` is the last line of defence …` bullet inside the LISTING comment
block — with the two bullets in **The replacement block** below, verbatim.
Nothing else in the file changes. No other file changes in this spec.

The analyst re-measured every claim the replacement text makes. The
measurements are in **The measurements**. Do not re-derive them; run the
commands in **Verify and Proof** to confirm the file reads as specified, and
re-run M6 because one acceptance box in the PRD depends on reading it right.

`R3` binds this spec: the `try` is not removed, narrowed, or moved. The
closure body is byte-unchanged. This spec writes comment lines only.

## What is wrong

Lines 386-390 read:

```
#   * the `try` is the last line of defence for whatever else the render can
#     throw: an error inside ONE PWD closure stops EVERY PWD closure firing
#     for the rest of the session (driven with a hook body made to throw —
#     the dirstack stopped recording moves from that point on). A failed
#     listing must never take the dirstack down with it.
```

Two defects.

**Defect 1 — "for the rest of the session" is false.** The abort is
per-fire. The failing closure re-fires and re-errors at every `cd`, and every
closure appended before it keeps firing forever. Measured twice, M1 and M2.

**Defect 2 — "EVERY PWD closure" is false, and the true scope is the
interesting one.** The abort reaches the remainder of the failing closure and
every closure appended *after* it. Closures appended before it are untouched.
That makes the protection here dependent on **append order**, and nothing in
the tree enforces the order. Measured, M4 and M5.

The original observation was real. Had the dirstack append sat *after* the
throwing hook, "the dirstack stopped recording" is exactly what its author
saw. The generalisation is what is wrong.

## The replacement block

Lines 386-390 become exactly the 24 lines below. Every line is at or under 78
characters. The bullet above them (the 0-columns hang, lines 381-385) and the
bare `#` separator below them (line 391) are untouched. Net delta: **+19
lines**, so the `AND ON `which`` block that starts at 392 starts at 411 and
the first `$env.config.hooks.env_change.PWD = (` of the auto-list at 424
moves to 443.

```
#   * the `try` is the last line of defence for whatever else the render can
#     throw, and its reach is NARROWER THAN A SESSION-WIDE LATCH. Measured
#     2026-08-23 on the pinned 0.114.1 under a real pty with a three-closure
#     config — a logger, a thrower, a second logger — driven twice: once with
#     `error make`, once with A MISSING EXTERNAL, and the two runs are
#     INDISTINGUISHABLE. The logger appended BEFORE the thrower recorded
#     every fire; the thrower's own tail and the logger appended AFTER it
#     recorded NOTHING, EVER; and one error box arrived per fire —
#     FOUR FIRES, FOUR BOXES. So an error aborts the REMAINDER OF ITS OWN
#     CLOSURE and every closure appended AFTER it, on EVERY fire. It does
#     not latch for a session, and it never touches a closure appended
#     before it.
#   * WHICH MAKES THE `try` LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION,
#     AND NOTHING ENFORCES THAT ORDER. The dirstack survives an unguarded
#     throw in this closure only because its own append at the HOOKS anchor
#     above is the FIRST one — it has already run by the time this body is
#     reached. Measured the same day against this very file, with one extra
#     PWD closure whose body is a missing external: appended AHEAD of the
#     dirstack push, DIRS.TXT IS NEVER CREATED AT ALL (two cds, two error
#     boxes); the identical closure appended after both, dirs.txt recorded
#     both moves. Same error, opposite outcome, decided only by position. A
#     failed listing must never take the dirstack down with it — and a later
#     node appending a PWD closure ahead of the dirstack push would move the
#     damage without touching a line of this block.
```

## The measurements

All on nushell 0.114.1, macOS, 2026-08-23, under the DSR-answering pty runner
this repo's gates use (`tests/nushell-core.sh:125`, `write_pty_runner`), with
the machine layout `mk_machine` builds.

**M1 — three closures, `error make`.** A scratch config resets
`hooks.env_change.PWD` to `[]`, then appends three closures: `c1` logs
`$after`; `c2` runs `error make {msg: "boom"}` and *then* logs `c2-tail`;
`c3` logs. Driven `cd a`, `cd b`, `cd c`, `exit`.

```
log.txt:
  c1 <startup dir>
  c1 …/a
  c1 …/b
  c1 …/c
counts: c1=4  c2-tail=0  c3=0
Error: nu::shell::error × 4, each citing config.nu:8:16 (the `error make`)
```

**M2 — three closures, missing external.** The same config with
`^definitely-not-a-binary e> /dev/null` in place of the `error make`.

```
counts: c1=4  c2-tail=0  c3=0
nu::shell::external_command × 4
```

Indistinguishable from M1. Per-fire, not a latch; forward-only.

**M3 — the real config, baseline, `stty` unresolvable.** A machine with the
real `config.nu` and `env.nu`, `$env.PATH = ["/usr/bin"]` typed in the REPL
before two `cd`s.

```
dirs.txt: …/s2|…/s1
nu::shell::external_command: 0
Command `stty` not found: 0
```

The `which stty` guard holds. This reproduces
[`unguarded-startup-externals`](../../unguarded-startup-externals/prd.md)'s
result, and is the control M4 and M5 are measured against.

**M4 — order, AHEAD.** The real `config.nu` plus one extra
`$env.config.hooks.env_change.PWD = (… | append {|before, after| …})`
inserted immediately *before* the `# ── HOOKS ──` anchor, under the same
three guards, body `^definitely-not-a-binary e> /dev/null`. It is therefore
the FIRST append.

```
dirs.txt: <absent — never created>
nu::shell::external_command: 2   (two cds; the startup fire is skipped by
                                  `$before != null`)
```

**M5 — order, AFTER.** The byte-identical closure appended at the end of
`config.nu` instead, so it is the LAST append.

```
dirs.txt: …/s2|…/s1
nu::shell::external_command: 2
```

M4 and M5 differ in nothing but the insertion point.

**M6 — the `try` still catches.** `try { la | print }` replaced with
`try { error make {msg: "listing boom"} }`, run under a pty whose master sets
a real winsize (40×120) so `term size` reports columns and the listing branch
is actually reached. The gate's own runner sets no winsize, reports 0 columns,
and the closure's width guard skips the branch entirely — measure this one
with the winsize variant or it passes for the wrong reason.

```
try KEPT:    nu::shell::error 0   dirs.txt …/s2|…/s1
try REMOVED: nu::shell::error 2   dirs.txt …/s2|…/s1
```

**Read M6 carefully — the PRD's acceptance box for it does not
discriminate.** The PRD's second acceptance box asks for "a counterfactual
with a throwing listing body leaves the dirstack recording". The dirstack
records in **both** branches, for the very reason this spec exists: it is the
first append and has already run. What the `try` measurably buys is two error
boxes going to zero, plus the survival of anything appended after this
closure. Tick that box against the numbers above and say in the report which
half of it the measurement supports. Do not edit `prd.md` — flag it and let
the orchestrator rewrite the box.

**M7 — the neighbouring claim, checked and left alone.** Lines 381-385 say
`la | print` on a 0-column terminal "HANGS the shell inside the hook — no
prompt ever paints again". With the width guard *and* the `try` removed and no
winsize set, that reproduces exactly: after the first `cd` no further prompt
marker appears, the runner hits its 40 s ceiling and emits `<NUPTY-TIMEOUT>`,
and `dirs.txt` holds only the first move because the second `cd` was never
read. That bullet is exact. Do not touch it.

## Acceptance

- [x] The retired claim is gone. `/usr/bin/grep -cF 'stops EVERY PWD closure
      firing' home/dot_config/nushell/config.nu` → `0`, and
      `/usr/bin/grep -cF 'for the rest of the session'
      home/dot_config/nushell/config.nu` → `0`.
- [x] The corrected bullets are in, each phrase exactly once:
      `NARROWER THAN A SESSION-WIDE LATCH`, `A MISSING EXTERNAL`,
      `FOUR FIRES, FOUR BOXES`,
      `LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION`,
      `AND NOTHING ENFORCES THAT ORDER`,
      `DIRS.TXT IS NEVER CREATED AT ALL`.
- [x] Both measurement halves are named in the text: `error make` and
      `A MISSING EXTERNAL`.
- [x] **R3** — the mechanism is byte-unchanged. Match the **indented code
      lines**, not the bare phrases: `try { la | print }` occurs twice in
      this file (line 376 is the comment that introduces it, line 430 is the
      code), so a bare count proves nothing.
      `/usr/bin/grep -cF '                try { la | print }'
      home/dot_config/nushell/config.nu` → `1`;
      `/usr/bin/grep -cF 'if ($env._NAV? | default "" | is-empty) and (term
      size).columns > 0 {' …` → `1`; and
      `/usr/bin/grep -cF 'if (which stty | is-not-empty) { ^stty sane e>
      /dev/null }' …` → `1`.
- [x] The two PWD appends are still in their original order, dirstack first.
      `/usr/bin/grep -n '_dirstack_push $after' …` reports a lower line
      number than `/usr/bin/grep -n 'try { la | print }' …`.
- [x] The file grew by exactly 19 lines. `wc -l` before and after, both
      quoted.
- [x] No replaced line exceeds 78 **characters** (not bytes — the block uses
      em dashes, and `awk 'length'` on this machine counts bytes):
      `python3 -c "…"` over lines 386-409 reports a max of `77`.
- [x] M6 is re-run with the winsize variant and quoted, with the caveat
      above stated: `try` kept → 0 error boxes, `try` removed → 2, dirstack
      recording in both.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, **run alone**. It is
      ~180 checks; a parallel run empties the pty output and produces false
      reds. `gates/waves.tsv:24` already lists
      `external bash tests/nushell-core.sh` in wave 3 — confirmed by
      reading the file, so no orchestrator-owned file needs an entry.

## Out of scope

- The `AND ON `which`, BECAUSE THE REDIRECT IS NOT A GUARD` block below line
  391 and the `ST.5`/`ST.6` checks that gate it. They already carry the
  corrected reading and belong to
  [`unguarded-startup-externals`](../../unguarded-startup-externals/prd.md).
- The 0-columns hang bullet at lines 381-385. Measured accurate (M7).
- Gating the new wording. That is spec02.
- Building the ordering check R5 asks about. It belongs to
  [`04-shell/01-core-config`](../../../../04-shell/01-core-config/prd.md).
- The other carriers of this same retired claim, in
  [`04-shell/06-listing`](../../../../04-shell/06-listing/prd.md). spec02
  reports them; each is its own node.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
C=home/dot_config/nushell/config.nu

# the retired claim is gone
/usr/bin/grep -cF 'stops EVERY PWD closure firing' "$C"
/usr/bin/grep -cF 'for the rest of the session'    "$C"

# the corrected phrases are in, once each
for p in 'NARROWER THAN A SESSION-WIDE LATCH' 'A MISSING EXTERNAL' \
         'FOUR FIRES, FOUR BOXES' \
         'LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION' \
         'AND NOTHING ENFORCES THAT ORDER' \
         'DIRS.TXT IS NEVER CREATED AT ALL'; do
  printf '%-46s %s\n' "$p" "$(/usr/bin/grep -cF "$p" "$C")"
done

# R3 — the mechanism is untouched. The INDENTED code lines, not the phrases:
# `try { la | print }` also appears in the comment at line 376.
/usr/bin/grep -cF '                try { la | print }' "$C"
/usr/bin/grep -cF 'if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {' "$C"
/usr/bin/grep -cF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$C"

# the two appends are still in order, dirstack first
/usr/bin/grep -n '_dirstack_push $after' "$C"
/usr/bin/grep -nF 'try { la | print }'   "$C"

# the wrap, in CHARACTERS
python3 -c "
ls=[l.rstrip(chr(10)) for l in open('$C')][385:409]
print('max chars', max(len(l) for l in ls))
print([i+386 for i,l in enumerate(ls) if len(l)>78])
"

# the gate, ALONE
bash tests/nushell-core.sh
```
