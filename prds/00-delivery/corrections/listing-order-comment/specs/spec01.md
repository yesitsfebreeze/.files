---
complexity: 8         # one comment block, one file, no logic touched; the
                       # only risk is getting the reasoning wrong, and that
                       # risk is retired below by two independent measurements
blast-radius: low     # comment-only; order_ok() and its four-value chain are
                       # byte-identical before and after — a run that goes red
                       # after this edit means the diff leaked into code
footprint:
  - tests/shell-listing.sh
---
<!-- Add your own keys freely; nothing outside complexity and footprint is read. -->

# spec01 — replace T1's "parse order" reason with the measured one

Rewrite the comment above the `T1` check in `stage_tree()`
(`tests/shell-listing.sh:412-413` as of 2026-08-25 — **re-grep before
editing**, per this PRD's own precedent of stale line references; find it
with `grep -n 'T1 — parse order' tests/shell-listing.sh`). The assertion
(`order_ok`, its counterfactual, and the `chk`/`chk_fail` calls around it)
does **not** change — this is a comment-only edit.

## What was measured

By the analyst, independently of `config-nu-parse-claims` — which agrees;
see Cross-check below.

The old comment labels the whole four-link chain "parse order," which
implies all four links share one mechanism. They don't, and the file
itself (`la` is currently a `def`, not an alias) makes only one of the
four links a real hazard today:

1. **`alias core-ls = ls` (204) before `def ls [` (280) — a live hazard,
   not a convention.** `def ls`'s body calls `core-ls`. An alias binds
   **textually**, not by predeclaration, so a def whose body calls an
   alias declared *below* it fails at the alias's first invocation.
   Measured directly, isolated from config.nu, `nu -n -c`:

   ```
   def myfn [] { myalias }
   alias myalias = ls
   myfn | ignore
   ```
   → `Error: nu::shell::external_command … Command \`myalias\` not found`

   Reversing the order (`alias` above `def`) runs clean. This is the exact
   shape of `core-ls`/`def ls`, and `config.nu:163-166` (the corrected
   LISTING-anchor comment landed by `config-nu-parse-claims`) states the
   same conclusion for the real names: reordering makes the *first* `ls`
   fail loudly with `` Command `core-ls` not found ``, not a parse error
   and not recursion.

2. **`def ls [` (280) before `def la [` (304) before the auto-list append
   (493) — a stability contract, not a hazard.** Nushell predeclares every
   `def` in a block before parsing any body, so a `def` or closure naming
   another `def` below it runs fine either way. Measured directly:

   ```
   let c = {|| mydef }
   def mydef [] { print "DEF-BELOW-WORKS" }
   do $c
   ```
   → `DEF-BELOW-WORKS`, exit 0 — no `nu::parser` error, in both
   declaration orders.

   `la` is `def la [path: string = "."] { ls -a $path }` today
   (`config.nu:304`) — a def, not an alias — so this half of the chain has
   no live parse/runtime hazard right now. **It would**, the moment `la`
   is replaced by an alias: a closure naming an alias declared below it
   fails the same way #1 does. Measured:

   ```
   let c = {|| myalias }
   alias myalias = ls
   do $c
   ```
   → `Command \`myalias\` not found`. (Declaring the alias *above* the
   closure runs clean — `ALIVE-ABOVE`, exit 0.)

So the honest reason is a hybrid, not one uniform mechanism: one real,
already-live textual-binding hazard (`core-ls` < `def ls`), plus a
stability contract for the rest of the chain (declared order matches
reading order; a future `la`-as-alias would make that link load-bearing
too, but nothing today does).

## Cross-check against `config-nu-parse-claims` (R3)

That node is `state: done`, and its `config.nu:148-169` LISTING-anchor
comment (landed at
`home/dot_config/nushell/config.nu`) states the identical mechanism:
predeclaration covers def bodies and closures but not alias targets or
`source`; `alias core-ls = ls` must precede `def ls` or the first `ls`
fails with `` Command core-ls not found ``; and "had the auto-list closure
named an ALIAS instead of the `la` def, this anchor order WOULD be
load-bearing." The two measurements agree — no disagreement to arbitrate,
so R3's tie-break ("the one verified against a running shell wins") is not
needed here; both are verified against a running shell and say the same
thing.

## The edit

Replace the two-line comment immediately above the `T1` `if order_ok
"$CONFIG_NU"; then` block with:

```sh
  # T1 — not one uniform "parse order": nushell PREDECLARES a block's defs,
  # so def ls < def la < the auto-list append is a stability contract, not
  # a hazard — both orders parse and run with zero nu::parser errors
  # (measured; matches config-nu-parse-claims and config.nu's own LISTING
  # comment). The one link that IS load-bearing today is alias core-ls <
  # def ls: an alias binds TEXTUALLY, not by predeclaration, and def ls's
  # body calls core-ls — reorder them and the first `ls` fails loudly with
  # `Command core-ls not found` (measured here too, and by config.nu).
  # Had the auto-list closure named an alias instead of the la def, that
  # link would be load-bearing the same way — it doesn't today, so the
  # chain is kept as a stability contract past that one real link.
```

Nothing else in `stage_tree()` moves. `order_ok`, its docstring at
`tests/shell-listing.sh:130-133` (a different comment — it justifies
*start-anchored* lookups, not the ordering itself, and is out of this
spec's scope), the `chk`/`chk_fail` calls, and the CF1 counterfactual are
untouched.

## Acceptance

- [x] The two-line "parse order" comment above `T1`'s `order_ok` call is
      replaced with the text above, verbatim. Confirmed by re-grepping the
      real line first (`grep -n 'T1 — ' tests/shell-listing.sh` →
      `412:  # T1 — parse order: core-ls captured before the shadow, the
      shadow before` — matched the PRD's own note that the stale `:104`
      reference is wrong and `:412-413` is current), then applying the
      exact replacement text from "## The edit" above via `Edit`, and
      confirming with `git diff` (below) that the new eleven-line comment
      landed verbatim in place of the old two-line one.
- [x] `order_ok()`, `line_of_decl()`, `line_of_2nd_decl()`, and every
      `chk`/`chk_ok`/`chk_fail` call in the file are byte-identical to
      before — `git diff -- tests/shell-listing.sh` touches only `#`
      comment lines. Ran the scope-check command verbatim:

      ```
      $ git diff -- tests/shell-listing.sh | grep -E '^[+-]' | grep -vE '^[+-]\s*#|^(---|\+\+\+)'
      $ echo $?
      1
      ```

      No output, exit 1 (grep found nothing to print) — proves every
      changed line is a `#` comment line. The full `git diff` shows only
      the T1 comment block replaced (2 lines removed, 11 lines added);
      `if order_ok "$CONFIG_NU"; then` and every line below it through the
      `chk_fail` counterfactual call are untouched context lines in the
      diff.
- [x] `bash tests/shell-listing.sh`, run alone, reaches `EXIT=0` with the
      same PASS/FAIL tally as the pre-edit baseline (36 PASS / 0 FAIL,
      measured by the analyst 2026-08-25 — reconfirmed here, unchanged).

      Baseline (before the edit):
      ```
      $ bash tests/shell-listing.sh > /tmp/before.log 2>&1; echo "before EXIT=$?"
      before EXIT=0
      $ grep -c '^PASS' /tmp/before.log; grep -c '^FAIL' /tmp/before.log
      36
      0
      ```

      After the edit, run alone:
      ```
      $ bash tests/shell-listing.sh > /tmp/after.log 2>&1; echo "after EXIT=$?"
      after EXIT=0
      $ grep -c '^PASS' /tmp/after.log; grep -c '^FAIL' /tmp/after.log
      36
      0
      $ diff <(grep -c '^PASS' /tmp/before.log) <(grep -c '^PASS' /tmp/after.log) && echo "tally unchanged"
      tally unchanged
      ```

      Tally unchanged (36 PASS / 0 FAIL both times), exit 0 both times —
      the edit did not leak past the comment.

## Verify and Proof

```sh
# 0 — locate the real line (do not trust "104" or "412" from prior reads)
grep -n 'T1 — ' tests/shell-listing.sh

# 1 — baseline, BEFORE editing
bash tests/shell-listing.sh > /tmp/before.log 2>&1; echo "before EXIT=$?"
grep -c '^PASS' /tmp/before.log; grep -c '^FAIL' /tmp/before.log

# 2 — make the edit (the comment block above), then:
git diff -- tests/shell-listing.sh
git diff -- tests/shell-listing.sh | grep -E '^[+-]' | grep -vE '^[+-]\s*#|^(---|\+\+\+)'
# ^ must print nothing — proves the diff is comment lines only

# 3 — the gate, run ALONE, AFTER editing
bash tests/shell-listing.sh > /tmp/after.log 2>&1; echo "after EXIT=$?"
grep -c '^PASS' /tmp/after.log; grep -c '^FAIL' /tmp/after.log
diff <(grep -c '^PASS' /tmp/before.log) <(grep -c '^PASS' /tmp/after.log) && echo "tally unchanged"
```
