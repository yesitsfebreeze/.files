---
state: claimed
priority: 21
est:
mode: afk
needs:
  - 00-delivery/corrections/pwd-closure-blast-radius
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
origin: derived
from: 00-delivery/corrections/pwd-closure-blast-radius
claim: implementer-3 2026-08-24T13:52Z
complexity: 40
blast-radius: low
---

# The dirstack survives by append order, and nothing checks the order

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)
established, by measurement, that an error in a PWD closure aborts the rest of
that closure and every closure appended **after** it, on every fire. The
dirstack keeps working today for exactly one reason: **its append comes
first**. Nothing in the file, the gates or the tree enforces that.

Measured on both sides: a throwing closure inserted *ahead* of the dirstack
push produces **no `dirs.txt`** at all; the byte-identical closure appended
last leaves `dirs.txt` recording both moves. Same error, opposite outcome,
decided only by position — and M4 emitted no warning about the dirstack, only
the external's own error box, which a reader attributes to the external.

That node's R5 answered "yes, this deserves a gate" and deliberately did not
build it, because `tests/nushell-core.sh`'s ordering contract belongs to
[`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md). This node
is where it lands, with the four assertions its analyst and implementer both
specified.

The precedent is in the same file: `config.nu:339-340` reads *"the gate asserts
the two line numbers, which is why this is a checked artefact and not a
convention."* Same hazard class, same answer.

## Requirements
- [x] **R1** — **Order.** Landed as `DO.1` in `stage_tree`: two lookups and
      a `-lt`, the `S3.9` shape. `PASS  tree: DO.1 the dirstack append (line
      385) is above the auto-list append (line 499)`. Two citation drifts
      corrected in passing, mechanisms intact: `S3.9` is at
      `tests/nushell-core.sh:566-570`, not 417-418. And the lookup is
      **`line_of_code`, not `line_of`** — both targets are indented, so
      `line_of_decl` answers 0 on each, and substring `line_of` answers 403,
      the PROSE quote of `try { la | print }` in the auto-list paragraph,
      rather than the code at 499. Measured 2026-08-24 on this `config.nu`
      (856 lines); `gates/lib.sh:98-183` records the trap and supplies the
      helper. The assertion R1 asks for is unchanged — only the lookup is the
      one that cannot be defused by a comment.
- [x] **R2** — **Count.** Landed as the `PWD_APPENDS` roster plus
      `pwd_append_tags` / `pwd_appends_ok`, and asserted by `DO.2` — ordered
      set equality against a declaration, never a bare `-eq 2`:
      `PASS  tree: DO.2 config.nu's PWD appends are exactly the roster, in
      order [_dirstack_push $after/try { la | print }]`. Rows are separated by
      `@@`, not `|`, because the auto-list's own token contains a pipe and
      `cut -d'|' -f1` truncates it to `try { la ` — **reproduced** on the
      prototype before the separator was changed (fixture:
      `scratchpad/proto.sh` against `config.nu`).
- [x] **R3** — **Counterfactual.** Two of them, both `chk_fail` in the
      established idiom. `DO.3` moves the dirstack block to EOF and proves its
      own mutation first — `DO.3 copy: block 381-388 moved to EOF; push=853
      try=491 (was 385/499)`, same line count, still exactly two appends —
      then goes red twice: `PASS  tree: DO.3 …so the DO.1 order predicate
      FAILS on it` and `PASS  tree: DO.3 …and the roster check FAILS on it
      [OUT OF ORDER [try { la | print }/_dirstack_push $after]]`. `DO.4`
      inserts a THIRD append ahead of the dirstack and is the one that
      justifies R2: the roster goes red and names the arrival —
      `MISSING []; UNEXPECTED [<unowned append at line 370>]` — while
      `PASS  tree: DO.4 …while the DO.1 order predicate still HOLDS on it
      (393 < 507)`. The order check alone is blind to that hazard;
      **reproduced** (fixture: `$SCRATCH/cf-three-appends.nu`).
- [x] **R4** — **The consequence, hermetically.** Lifted, not re-derived,
      and re-run in this gate's own `mk_machine` + `nu_pty` harness as `DO.6` –
      `DO.9` in `stage_hermetic`. `DO.7 AHEAD: external_command boxes=2, name
      hits=6, dirs.txt=<ABSENT>` beside `DO.8 AFTER: external_command boxes=2,
      name hits=6, dirs.txt=…/s2|…/s1`, with `DO.9 CONTROL: external_command
      boxes=0, dirs.txt=…/s2|…/s1`. Same error, same two boxes, opposite
      outcome, decided only by position — M4/M5 **reproduced** (fixture:
      `$SCRATCH/cfg-thrower-{ahead,after}.nu`, nu 0.114.1, two `cd`s then
      `exit`). `DO.6` guards the experiment itself: both copies 864 lines and
      three appends, thrower at 374 in one and 861 in the other, so an
      equal pair cannot pass as agreement. The extra closure is inserted from
      a FILE with `sed … r`; `awk -v x="$MULTILINE"` dies with `awk: newline
      in string` and silently writes a config with ZERO appends.
- [x] **R5** — `config.nu` gained exactly one line, 76 characters, at 375,
      inside the `# ── HOOKS ──` comment block under the `EXACTLY ONE closure`
      paragraph:
      `# THE DIRSTACK APPEND MUST STAY FIRST; tests/nushell-core.sh DO.1 checks it.`
      Length measured with `python3` (`len()` on the stripped line), not
      `awk 'length'`, which counts bytes on this machine and the file uses em
      dashes. `DO.5` asserts it from the NORMALISED prose, so a rewrap cannot
      defuse it: `PASS  why: DO.5 config.nu says the dirstack append must stay
      first` and `PASS  why: DO.5 …and names the check that asserts it`. The
      precedent the PRD cites as `config.nu:339-340` is at **365-366** today —
      the file grew, the mechanism did not.

## Acceptance
- [x] `bash tests/nushell-core.sh` run **alone** reaches `EXIT=0` with
      **233 PASS / 0 FAIL** in 15.4 s wall. A reading of 2026-08-24, not an
      absolute. The acceptance line's **187 is stale**: the pre-change
      baseline re-measured here before any edit, run alone, is
      **212 PASS / 0 FAIL, EXIT=0** — 212 quoted, matching what
      `nushell-core-positional-lookups` records. 212 + spec01's 13 checks +
      spec02's 8 = 233.
- [x] R1 green and R3 red, side by side:
      `PASS  tree: DO.1 the dirstack append (line 385) is above the auto-list
      append (line 499)`, against
      `PASS  tree: DO.3 …so the DO.1 order predicate FAILS on it` and
      `PASS  tree: DO.3 …and the roster check FAILS on it [OUT OF ORDER
      [try { la | print }/_dirstack_push $after]]` on the copy whose only
      change is the block's position (`push=853 try=491 (was 385/499)`, same
      line count, still two appends).
- [x] The roster form prints its members rather than counting them —
      `PASS  tree: DO.2 config.nu's PWD appends are exactly the roster, in
      order [_dirstack_push $after/try { la | print }]`, the auto-list token
      whole and not truncated at its pipe. `DO.4`'s third append is flagged by
      name: `PASS  tree: DO.4 …and the diagnosis NAMES the arrival [MISSING
      []; UNEXPECTED [<unowned append at line 370>]]`, while
      `PASS  tree: DO.4 …while the DO.1 order predicate still HOLDS on it
      (393 < 507), which is why R2 is a roster`.
- [x] The scope diff against a `cp`-aside baseline taken before the first
      edit is insertions only. `diff base-config.nu
      home/dot_config/nushell/config.nu` → `374a375 > # THE DIRSTACK APPEND
      MUST STAY FIRST; tests/nushell-core.sh DO.1 checks it.` and nothing
      else; `diff base-nushell-core.sh tests/nushell-core.sh` → **256 `>`
      lines, 0 `<` lines**.
      **The premise of this box is refuted.** Both files are *tracked and were
      clean at claim time*, so `git diff` is not empty by construction — it is
      the measurement, and it agrees: `1	0	home/dot_config/nushell/config.nu`
      and `256	0	tests/nushell-core.sh`.

## Out of scope
- Reordering anything. This node checks the order that exists.
- The corrected prose at `config.nu:386-409`, which is
  [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)'s and has
  landed.
