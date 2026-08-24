---
est: 0.75h
footprint:
  - gates/lib.sh
  - gates/selftest.sh
---

# spec01 — two positional-lookup helpers in `gates/lib.sh`, counterfactualled through a gate that sources it

`gates/lib.sh` provides seven things and **not one line-number lookup**,
measured: `grep -c line_of gates/lib.sh` → **0**, while **14 scripts under
`tests/`** each carry their own `line_of() { $GREP -nF -- "$2" … }`. That copy
is substring form on prose-bearing input, and the parent census found 25 such
groups over 55 target positions. This spec adds the two anchored/code-only
helpers to the one file all 49 consumers already source, proves they
discriminate through a gate, and produces the per-gate report the nine
follow-on nodes are specced from. **It converts no gate** — R4 holds, and the
nine gates belong to nine other nodes.

Everything below was re-measured on 2026-08-24. Where a number in the PRD did
not reproduce, the measured one is given and the PRD's is named as stale — the
mechanism reproduced in every case, the numbers did not.

## What lands in `gates/lib.sh`

Two helpers, one section, one reason comment. Neither is named `line_of`.

**`line_of_decl` — anchored at column 1.** The landed shape, byte-for-byte
from `tests/nushell-core.sh:413` and `tests/shell-listing.sh:100`:

```sh
line_of_decl() {
  awk -v s="$2" 'index($0, s) == 1 { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}
```

**`line_of_code` — comment-stripped, and it must keep the FILE's own line
numbers.** This is the trap, and it is measured. The obvious pipeline form
renumbers the file:

```
target: '^git credential fill' in home/dot_config/nushell/capsule.nu
  substring line_of                  → 219   (correct, but see below)
  line_of_decl (anchored)            → 0     (the target is INDENTED)
  grep -vE '^[[:space:]]*#' | grep -n → 102   (WRONG — renumbered)
  awk with a comment test            → 219   (correct)
```

102 is not a line of that file. Every consumer of these lookups compares one
line number against another, so one renumbered answer beside one real answer
corrupts the comparison silently and in the passing direction. The form that
survives:

```sh
line_of_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*#/ && index($0, s) { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}
```

**Both are needed, and `line_of_code` is the more general of the two.**
Measured on `home/dot_config/nushell/config.nu`, `line_of_code` also skips the
prose quote and answers **204**, the same as `line_of_decl`. So `line_of_decl`
is not the stronger tool for coverage — it is the stronger tool for
*intent*: `index($0, s) == 1` can only ever resolve a declaration that starts
a line, so a target mentioned inside a string, a heredoc or a nested block
cannot satisfy it. Prefer `line_of_decl` where the target is at column 1, and
`line_of_code` only where it is legitimately indented.

**Do not add `line_of` to `gates/lib.sh`.** Fourteen scripts define their own
after sourcing lib.sh, so a lib-level `line_of` would be shadowed in those
fourteen and live in any future gate that forgets to define one — a
same-named helper whose behaviour depends on source order is worse than no
helper.

## The reason comment (R2), with re-measured numbers

The comment must cite the one live instance as a **case**, not a rule, and the
numbers it cites must be the ones that reproduce today:

```
home/dot_config/nushell/config.nu — 855 lines, measured 2026-08-24
  line 163  #   * `alias core-ls = ls` below MUST precede `def ls`. …
  line 204  alias core-ls = ls
  line 280  def ls [

  substring line_of  → 163  (the COMMENT)
  line_of_decl       → 204  (the declaration)

On the swapped-order counterfactual copy (the real alias moved to the end):
  substring → 163, def ls → 279   ⇒ 163 < 279, order HOLDS, guard is decoration
  anchored  → 855, def ls → 279   ⇒ 855 > 279, order BREAKS, as it must
```

The PRD's citation reads `shell-listing.sh:108`, `core=161`, declaration at
`202`. None of those three reproduce: line 108 is inside `line_of_2nd_decl`
(the landed reason comment is at `tests/shell-listing.sh:95-104`, the
definitions at `:100` and `:105`), the comment is at **163**, and the
declaration at **204** — the file grew by two lines and `202` was never one of
the landed numbers anyway (`tests/shell-listing.sh:95-98` records `core=161
defls=277` substring and `core=793` anchored). Say so in the comment: the
mechanism survived re-measurement, the numbers did not, so a reader who finds
different numbers should re-measure rather than assume the mechanism moved.

## The counterfactual (R3), in `gates/selftest.sh`

`selftest()` already builds four synthetic gates in `$(gates_tmpdir)/meta` —
a stub, a liar, a vandal and an honest one. Add a **fifth**, in the same
idiom, because it makes the proof run *through a gate that sources lib.sh*
rather than through a bare subshell. A helper whose own probe passes while its
consumers break is the failure this node exists to close.

The fifth gate gets its own scratch dir holding **a copy of `lib.sh`**, so
`. "$(dirname "$BASH_SOURCE")/lib.sh"` resolves to the copy and the copy can
be mutated without touching the real file. Three things in one run:

1. **The discriminating fixture.** A file where a `#` comment quotes a
   declaration that appears later at column 1. Print both answers on one
   line; they must differ. Equal answers means the fixture stopped
   discriminating and the box goes red.
2. **The mutation is measured, not claimed.** `sed` the copy's
   `index($0, s) == 1` down to `index($0, s)`, and print the copy's sha256
   **before → after on one line**. An equal pair is the only interesting
   failure of a `sed`, and it must be visible rather than inferred — see
   [`a-counterfactual-proves-its-own-mutation`](../../../../memos/a-counterfactual-proves-its-own-mutation.md).
3. **Red before repair, green after.** With the anchor removed the synthetic
   gate answers the comment line and goes red; restored from the real
   `lib.sh`, it answers the declaration line and goes green.

## Acceptance

- [ ] `grep -c 'line_of_decl' gates/lib.sh` is non-zero and
      `grep -cE '^line_of\(\)' gates/lib.sh` is **0** — the helper landed and
      `line_of` deliberately did not.
- [ ] `line_of_decl` in `gates/lib.sh` and the two landed copies
      (`tests/nushell-core.sh:413`, `tests/shell-listing.sh:100`) return the
      **same three answers** for the same three inputs. Run all three against
      `home/dot_config/nushell/config.nu` with `alias core-ls = ls`, quote the
      three numbers, and show they agree (204). A divergence means dropping a
      local copy later would change that gate's verdict.
- [ ] `line_of_code gates`' own trap is closed: on
      `home/dot_config/nushell/capsule.nu` with `^git credential fill` it
      returns **219**, the file's line — not 102, and not 0. Quote all three
      of the numbers in the table above from your own run.
- [ ] The reason comment carries the case, the re-measured 163/204/280 and
      163-vs-855 pairs, and the note that the PRD's `:108`/`161`/`202` do not
      reproduce.
- [ ] The fifth synthetic gate exists in `selftest()` and its
      discriminating-fixture line shows **two different** answers
      (substring ≠ anchored), both printed.
- [ ] The mutation line prints `sha <before> -> <after>` with the two
      **unequal**, on one line.
- [ ] The fifth gate is **red before the repair** — the FAIL names the gate
      and the subject — and green after.
- [ ] `bash gates/selftest.sh --selftest` run **alone**: rc 0, **0 FAIL**, and
      PASS count **≥ 23 + the checks you added**. Baseline measured twice
      tonight at a quiet load (3.3): 23 PASS / 0 FAIL / rc 0, 6m24s. Floors
      are raised, never lowered.
- [ ] **R4 report** — the nine gates as a table, accounting for **every one of
      the 74 candidate sites** the census command below emits, each classified
      `line_of_decl` / `line_of_code` / already whole-line / not
      prose-bearing. Reconcile the per-gate totals against the PRD table's 32
      positions and **name every difference** rather than restating 32; the
      raw `line_of "` call count alone is 49, so the PRD's number is a
      filtered subset and your classification is what makes it checkable.
- [ ] **R5 recommendation** — nine nodes or one sweep, argued, with the
      sequencing named either way.
- [x] **Amended and closed 2026-08-24 by the orchestrator: this box could not
      hold as written, for two reasons the implementer reported honestly rather
      than ticking around.** First, **`gates/selftest.sh` was untracked in
      git**, so it can never appear in `git diff` at all — the meta-gate that
      holds every gate to its contract was not under version control, which the
      implementer found and which the orchestrator caused by excluding it from
      tonight's commits while another lane held it. It is committed now.
      Second, the shared tree carried 19 files modified by concurrent lanes and
      by the orchestrator, so a repo-wide `git diff --name-only` measures the
      board's activity rather than this node's write set — the same
      whole-workspace shape struck from six boxes this session.

      What closes it, and what was proven: this lane wrote **`gates/lib.sh`
      (+93/−1) and `gates/selftest.sh`**, no gate under `tests/` was converted
      (R4 is a report, not an edit), and nothing outside the footprint was
      touched. Scope a footprint box to `git diff --name-only -- <the footprint
      paths>` next time, never to the whole tree.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# 1. The helpers, direct — cheap, and it is the box-2/box-3 evidence.
bash -c '. gates/lib.sh
  F=home/dot_config/nushell/config.nu
  echo "decl  config.nu alias core-ls  = $(line_of_decl "$F" "alias core-ls = ls")"
  echo "code  config.nu alias core-ls  = $(line_of_code "$F" "alias core-ls = ls")"
  echo "subst config.nu alias core-ls  = $(grep -nF -- "alias core-ls = ls" "$F" | head -1 | cut -d: -f1)"
  G=home/dot_config/nushell/capsule.nu
  echo "decl  capsule.nu ^git cred     = $(line_of_decl "$G" "^git credential fill")"
  echo "code  capsule.nu ^git cred     = $(line_of_code "$G" "^git credential fill")"'

# 2. Cross-check against the two landed copies (box 2).
for f in tests/nushell-core.sh tests/shell-listing.sh; do
  bash -c ". gates/lib.sh; $(sed -n '/^line_of_decl()/,/^}/p' "$f")
    echo \"$f local copy = \$(line_of_decl home/dot_config/nushell/config.nu 'alias core-ls = ls')\""
done

# 3. The counterfactual, through a gate that sources lib.sh. ~6m30s, run ALONE
#    on a quiet board; record the load average beside the result.
uptime
bash gates/selftest.sh --selftest; echo "rc=$?"

# 4. The R4 candidate census — 74 sites over the nine gates, 2026-08-24.
for f in tests/capsule-lifecycle.sh tests/capsule-credentials.sh \
         tests/shell-television.sh tests/shell-claude.sh tests/shell-help.sh \
         tests/shell-history.sh tests/shell-zoxide.sh \
         tests/nushell-aliases.sh gates/tree-links.sh; do
  grep -nE 'line_of "|(GREP|grep) -n' "$f" \
    | grep -v '^[0-9]*:[[:space:]]*#' | sed "s|^|$f:|"
done | wc -l

# 5. Footprint discipline (box 11).
git diff --name-only
```

**Do not add a box for `bash gates/selftest.sh`** (no flag). That is the full
sweep over 14 real gates owned by other nodes, and it inherits every one of
their reds — six such boxes were struck this session. The PRD's `verify:`
field is the node's, not this spec's.

If a whole-tree check goes red — a `wrote nothing outside its scratch` FAIL, or
anything naming `prds` — **re-run it alone in a quiet window before believing
it**, and report the gate, the exact check text and both runs.
`prds/.plan.json`, `prds/.view.html` and `prds/.history.jsonl` are git-ignored
machinery state inside every deep hash of `prds/`, rewritten by the live
service and by the orchestrator on every state transition. See
[`a-tree-guard-must-not-guard-machinery-state`](../../../../memos/a-tree-guard-must-not-guard-machinery-state.md)
and
[`an-unattributed-red-has-no-owner`](../../../../memos/an-unattributed-red-has-no-owner.md):
report it, do not fix it, and do not absorb it into a box here.

## Out of scope

- **Converting any of the nine gates** (R4). Nine footprints, nine other
  nodes.
- `tests/nushell-core.sh` and `tests/shell-listing.sh` — their local
  `line_of_decl` copies stay, and stay *after* the `lib.sh` source line
  (measured: source at `:56` / `:49`, definitions at `:413` / `:100`), so the
  local definition wins and neither gate's verdict can move.
- `tests/nvim-keymaps.sh` (held by a live lane), and `gates/waves.tsv` plus
  `gates/manual/wave*.md` (the orchestrator's). Nothing here needs a row in
  either — `gates/lib.sh` is sourced, never registered.
- The `gates/lib.sh` scratch-directory leak and the untouched-tree guard's
  treatment of board machinery state. Both are real, both are `gates/lib.sh`,
  and both are a different contract — routed in this spec's analysis report.
