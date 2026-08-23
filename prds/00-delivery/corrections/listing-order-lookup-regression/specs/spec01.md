---
est: 0.5h
footprint:
  - tests/shell-listing.sh
---

# spec01 — anchor the positional lookups, prove T1 red again

`tests/shell-listing.sh` compares line numbers with `line_of`, a first-match
substring grep. `config.nu:161` now quotes ``alias core-ls = ls`` in prose 41
lines above the real declaration at 202, so `order_ok` resolves `core` to the
**comment** and the swapped-order counterfactual reads as still holding. Port
`line_of_decl` from `tests/nushell-core.sh:401-410` — the start-anchored
lookup that node's implementer wrote after hitting the same hazard — add the
second-match twin `order_ok` also needs, and convert every **positional** call
site. R1, R2, R3, R4. No assertion changes what it concludes: the check count
stays at 36.

`tests/shell-listing.sh` belongs to
[`04-shell/06-listing`](../../../../04-shell/06-listing/prd.md) and that node
is `done` — this spec is the only writer. `tests/nushell-core.sh` is **read
only**: copy the helper, do not call into another node's file (the header of
`shell-listing.sh` already states that precedent for its anchors grep).

## What to write

**1. Two helpers, beside `line_of` / `line_of_2nd` at `:78-82`.** Port the
body verbatim from `tests/nushell-core.sh:401-410`, and carry the reason
retargeted to *this* file's measurement rather than restating the sibling's:

```sh
line_of_decl() {
  awk -v s="$2" 'index($0, s) == 1 { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}
```

and its second-match twin, needed because `order_ok`'s fourth position is a
`line_of_2nd` lookup and must anchor the same way:

```sh
line_of_2nd_decl() {
  awk -v s="$2" 'index($0, s) == 1 { n++; if (n == 2) { print NR; exit } }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}
```

The comment beside them keeps the "do not simplify this back" warning and the
measured numbers: `alias core-ls = ls` resolves to **161** by substring (the
LISTING prose) and **202** anchored (the declaration), and a comment line opens
with `#`, never with a declaration, which is why anchoring at the line start
reads only code.

**2. The positional call sites** — and *only* the positional ones:

| site | today | becomes |
|---|---|---|
| `order_ok` `core` / `defls` / `defla` (`:108-110`) | `line_of` | `line_of_decl` |
| `order_ok` `ln2` (`:111`) | `line_of_2nd` | `line_of_2nd_decl` |
| `autolist_ok` `ln2` (`:133`) | `line_of_2nd` | `line_of_2nd_decl` |
| `two_appends_ok` `ln1` / `ln2` (`:150-151`) | `line_of` / `line_of_2nd` | `line_of_decl` / `line_of_2nd_decl` |
| `stage_tree` `ln2` (`:396`) | `line_of_2nd` | `line_of_2nd_decl` |
| the T1 diagnostic (`:369`) | `line_of` ×3, `line_of_2nd` | the anchored four |

The T1 diagnostic matters on its own: it currently **prints 161**, so the one
line a reader would use to spot the defusal was itself reporting the comment.

**3. `autolist_ok`'s two in-block lookups (`:141-142`) read code lines only.**
`stty_ln` and `la_ln` search the extracted append block for `^stty sane` and
` la `. Both targets are indented, so line-start anchoring cannot be the fix;
filter the block through `$GREP -vE '^[[:space:]]*#'` before the two `grep -n`
calls and compare positions in that derived text. Measured reason to record
beside it: `config.nu:400` already quotes ``try { la | print }`` in prose, and
the only thing keeping that quote out of this lookup is that it sits *above*
the block at 490 — a comment added *inside* the closure would answer for the
code. The precedents are `tests/capsule-credentials.sh:143` ("a comment must
never be able to satisfy a presence check") and `nocomm()` in
`tests/nvim-statusline.sh:152`.

**4. Nothing else moves.** The two count assertions stay exactly as they are:
`two_appends_ok`'s `$GREP -cF "$PWD_APPEND" … -eq 2` and `anchors_ok`'s
`-cE "^# ── $a ──$"`. Anchoring a *count* would change what it concludes
(from "appears twice anywhere" to "twice at line start"), and R4 forbids that.
This is a lookup repair.

## Acceptance

- [x] `line_of_decl` and `line_of_2nd_decl` are in `tests/shell-listing.sh`,
      ported from `tests/nushell-core.sh:401-410`, with the "do not simplify
      this back" warning and this file's own measured pair (161 substring
      versus 202 anchored) beside them. No third variant invented, and
      `tests/nushell-core.sh` is unmodified (`git diff --stat` quoted).
- [x] All six positional sites in the table converted; `line_of` /
      `line_of_2nd` remain defined and are either unused or used only where
      the result is not compared with another line number. State which.
- [x] `two_appends_ok`'s `-cF … -eq 2` and `anchors_ok`'s `-cE` count checks
      are byte-identical to before (R4), and the gate's total check count is
      **36 before and 36 after** — no assertion added, removed, or
      retargeted.
- [x] The T1 PASS line prints **202**, not 161:
      `tree: T1 alias core-ls (line 202) < def ls (278) < def la (302) <
      second PWD append (490)`.
- [x] **The counterfactual is red again** (R3), with both lookups measured on
      the same `cf-order.nu` copy and both numbers quoted:
      substring reads `core=161 defls=277 defla=301 ln2=489` → the order
      *holds*, so `chk_fail` loses; anchored reads `core=793 defls=277` → the
      order is *broken*, so `chk_fail` wins. Quote the `chk_fail` line as
      PASS.
- [x] `autolist_ok` reads code lines only, and T3's counterfactual is still
      red (`tree: T3 counterfactual is-terminal guard FAILS the closure
      check` PASSes).
- [x] `bash tests/shell-listing.sh` reaches **EXIT=0, 36 PASS / 0 FAIL**, run
      **alone** (no concurrent gate, no shared scratchpad log name), and run
      **twice** — the tally quoted both times, not asserted.
- [x] `gates/waves.tsv` line 25 already registers
      `external bash tests/shell-listing.sh` in wave 4 — **confirmed by
      quoting the grep, and not edited**; `gates/waves.tsv` and
      `gates/manual/wave*.md` are the orchestrator's.
- [x] `tests/nvim-statusline.sh --headless` is **not** run and not reported:
      it is red from the `oil.nvim` lockfile widening and is explicitly out of
      this node's scope.

## Verify and Proof

```sh
# the node's verify, run alone, twice
bash tests/shell-listing.sh; echo "EXIT=$?"
bash tests/shell-listing.sh 2>&1 | grep -cE '^PASS'
bash tests/shell-listing.sh 2>&1 | grep -E '^FAIL|^EXIT'

# R3's before/after, on the counterfactual the gate itself builds
C=home/dot_config/nushell/config.nu
awk '/^alias core-ls = ls$/{next} {print} END{print "alias core-ls = ls"}' \
  "$C" > /tmp/cf-order.nu
for f in "$C" /tmp/cf-order.nu; do
  printf '%s\n' "$f"
  printf '  substring core=%s\n' \
    "$(/usr/bin/grep -nF -- 'alias core-ls = ls' "$f" | head -1 | cut -d: -f1)"
  printf '  anchored  core=%s\n' \
    "$(awk 'index($0,"alias core-ls = ls")==1{print NR;exit}' "$f")"
done

# the carve-out, confirmed not assumed
grep -n 'tests/shell-listing.sh' gates/waves.tsv
git diff --stat -- tests/nushell-core.sh gates/waves.tsv   # must be empty
```
