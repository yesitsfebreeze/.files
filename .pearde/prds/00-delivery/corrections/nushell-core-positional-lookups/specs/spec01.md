---
complexity: 30       # one file, mechanical anchoring swap + three precedented
                      # counterfactual blocks; the only real risk is getting a
                      # counterfactual's line-move awk wrong (measured below).
footprint:
  - tests/nushell-core.sh
---
<!-- Add your own keys freely; nothing outside complexity and footprint is read. -->

# spec01 — anchor `funnel_binds`, S3.9 and S4.13, each with a landed decoy-comment counterfactual

Swap the three remaining substring (`line_of`) positional lookups in
`tests/nushell-core.sh` — `funnel_binds`, the S3.9 block, and the S4.13
order block — to the start-anchored `line_of_decl`, matching the shape
already used by `textual_order_ok`/CP.9 in the same file and by
`order_ok`/T1 in `tests/shell-listing.sh`. Land one new counterfactual per
site that proves the fix actually matters: a decoy comment quoting the
target, injected, plus the real declaration moved to violate the order —
which must turn the (fixed) check red. All eight targets involved are
column-1, unindented, single-statement lines, so line-start anchoring is
the shape that fits every one of them; no comment-stripping or count
assertion is needed here (see the table below).

Current line numbers (2026-08-25; re-measure before editing — this file
has grown before and the PRD's own citations, `380-382`/`566-568`/
`594-596`, are already stale by this much):

- `funnel_binds()` — `tests/nushell-core.sh:501-506`, called with its
  PASS-label diagnostic at `:664-668` (the diagnostic calls `line_of`
  *again*, separately from the function — both must move or the label can
  print a different line than the boolean used, which is exactly the
  defusal `shell-listing.sh`'s T1 diagnostic had).
- S3.9 block — `:730-736` (`src_ln`, `mkcd_ln`, `hook_ln`).
- S4.13 order block — `:837-841` (`ls_ln`, `lz_ln`, `lt_ln`).

## Shape-and-why (R2), settled by direct measurement against
`home/dot_config/nushell/config.nu` (856 lines, 2026-08-25):

| site | target(s) | column-1? | occurs | shape chosen | why the other three don't fit |
|---|---|---|---|---|---|
| funnel_binds | `alias cd = mkcd` / `source ~/.cache/nushell/init/zoxide.nu` | yes, both | once each | line-start anchoring | not indented (rules out comment-stripping, which is for indented targets only — `nvim-statusline.sh`'s shape); whole-line match is equivalent here but anchoring is the file's own established idiom for this exact pair (`textual_order_ok`'s third `TEXTUAL_ORDER` row); no duplicate exists, so a count assertion adds nothing |
| S3.9 | `source ~/.config/nushell/dirstack.nu`, `def --env mkcd` | yes, both | once each | line-start anchoring | same reasoning as above |
| S3.9 | `$env.config.hooks.env_change.PWD = (` | yes | **twice** (:381 dirstack push, :493 auto-list) | line-start anchoring | the duplication is between two REAL declarations, not a comment-vs-code collision, and anchoring's first-match semantics already return the one S3.9 needs (:381, the dirstack-push closure) — a decoy comment can never win first-match because it starts with `#`, never with `$env`. A count assertion (the fourth shape) is for catching an *unexpected extra* arrival, which is `dirstack-append-order-gate`'s DO.2/DO.4 roster already covering this exact append point — duplicating that roster here would be scope creep, not a fit |
| S4.13 | `source ~/.cache/nushell/init/{starship,zoxide,television}.nu` | yes, all three | once each | line-start anchoring | same reasoning as the first row |

Measured directly (fixture: `home/dot_config/nushell/config.nu` at this
commit, a scratch copy per site, `awk`/`grep` run by hand, not the gate) —
**reproduced**, all three:

```
site 1 (funnel_binds): substring alias=1 zoxide=537 -> HOLDS (false pass)
                        anchored  alias=538 zoxide=537 -> BROKEN (correct)
site 2 (S3.9):          substring src=1 mkcd=336 -> HOLDS (false pass)
                        anchored  src=350 mkcd=335 -> BROKEN (correct)
site 3 (S4.13):         substring starship=1 zoxide=537 -> HOLDS (false pass)
                        anchored  starship=538 zoxide=537 -> BROKEN (correct)
```

**A trap measured while building the S3.9 fixture, worth recording so the
implementer doesn't re-fall into it**: the natural-looking "reinsert after
the next bare `}`" awk (the shape `DO.3`'s block-move already uses)
matches the *first* `/^}$/` line in the **whole file**, not the first one
*after* the deleted line — `config.nu` has bare `}` closers at lines 104,
146, 199, 270 and 300, all before `def --env mkcd` even starts at 335. An
unguarded `/^}$/ && !done` rule lands the moved line at 106, still above
`mkcd`, and the counterfactual silently fails to counterfactualize (it
still reads as correctly ordered, anchored or not — a check that can't go
red is the exact defect this PRD exists to remove). The fix is a `seen`
flag set at the deletion rule, so the `}` search only starts after the
line it's supposed to follow:

```sh
awk '
  /^source ~\/\.config\/nushell\/dirstack\.nu$/ { seen=1; next }
  { print }
  seen && /^}$/ && !done { print "source ~/.config/nushell/dirstack.nu"; done=1 }
' "$CONFIG_NU" > "$BASE"
```

## Acceptance

- [x] `funnel_binds()` (`:501-506`) computes both `alias_ln` and `zox_ln`
      with `line_of_decl`, not `line_of`. Verified by reading the function
      as it stands now:
      ```
      funnel_binds() {
        local f="$1" alias_ln zox_ln
        alias_ln="$(line_of_decl "$f" 'alias cd = mkcd')"
        zox_ln="$(line_of_decl "$f" 'source ~/.cache/nushell/init/zoxide.nu')"
        [ "$alias_ln" -gt 0 ] && [ "$zox_ln" -gt 0 ] && [ "$alias_ln" -lt "$zox_ln" ]
      }
      ```
- [x] The S4.11 PASS-label at `:665` (`chk "tree: S4.11 alias cd = mkcd
      (line $(line_of …))…"`) is switched to `line_of_decl` for both of its
      inline lookups too, so the printed line numbers can never diverge
      from the boolean `funnel_binds()` just computed. Line 665 now reads:
      `chk "tree: S4.11 alias cd = mkcd (line $(line_of_decl "$CONFIG_NU"
      'alias cd = mkcd')) is parsed before the zoxide init source (line
      $(line_of_decl "$CONFIG_NU" 'source ~/.cache/nushell/init/zoxide.nu'))"
      0`. `bash tests/nushell-core.sh --tree` prints: `PASS  tree: S4.11
      alias cd = mkcd (line 367) is parsed before the zoxide init source
      (line 537)`.
- [x] S3.9's `src_ln`, `mkcd_ln` and `hook_ln` (`:732-734`) are computed
      with `line_of_decl`, not `line_of`. Now reads: `src_ln="$(line_of_decl
      "$CONFIG_NU" 'source ~/.config/nushell/dirstack.nu')"`,
      `mkcd_ln="$(line_of_decl "$CONFIG_NU" 'def --env mkcd')"`,
      `hook_ln="$(line_of_decl "$CONFIG_NU"
      '$env.config.hooks.env_change.PWD = (')"`. `--tree` prints: `PASS
      tree: S3.9 dirstack.nu is sourced (line 311) before mkcd is defined
      (line 335) and before the PWD append (line 381)`.
- [x] S4.13's `ls_ln`, `lz_ln` and `lt_ln` (`:838-840`) are computed with
      `line_of_decl`, not `line_of`. Now reads: `ls_ln="$(line_of_decl
      "$CONFIG_NU" "source ~/$gen_rel/starship.nu")"`,
      `lz_ln="$(line_of_decl "$CONFIG_NU" "source ~/$gen_rel/zoxide.nu")"`,
      `lt_ln="$(line_of_decl "$CONFIG_NU" "source ~/$gen_rel/television.nu")"`.
      `--tree` prints: `PASS  tree: S4.13 the three sources are in
      starship, zoxide, television order (536 < 537 < 538)`.
- [x] A new S4.11 counterfactual, built from the existing `$REVERSED`
      (alias moved after the zoxide source) with this decoy comment
      prepended: `# see \`alias cd = mkcd\` below, which must run before
      the zoxide init`. `chk_ok` confirms the copy still holds exactly one
      real `alias cd = mkcd` (`grep -cxF` == 1, which a `#`-prefixed decoy
      can never satisfy). `chk_fail funnel_binds "$CF"` is the PASS box —
      the anchored function must reject the copy despite the decoy.
      `bash tests/nushell-core.sh --tree` prints:
      ```
      PASS  tree: S4.11 decoy-comment counterfactual copy still holds exactly one real alias cd = mkcd
      PASS  tree: S4.11 decoy-comment counterfactual (comment above, real alias after zoxide) FAILS the funnel check
      ```
- [x] A new S3.9 counterfactual: the real `source
      ~/.config/nushell/dirstack.nu` line deleted and reinserted directly
      after `def --env mkcd`'s closing `}` (the `seen`-guarded awk above,
      not a bare `/^}$/` match), with the same-style decoy comment
      (`# see \`source ~/.config/nushell/dirstack.nu\` below, which the
      funnel needs before mkcd`) prepended. `chk_ok` confirms exactly one
      real source line survives. `chk_fail` on `test "$src_ln" -gt 0 -a
      "$src_ln" -lt "$mkcd_ln" -a "$mkcd_ln" -lt "$hook_ln"` (all three via
      `line_of_decl` against the copy) is the PASS box.
      `bash tests/nushell-core.sh --tree` prints:
      ```
      PASS  tree: S3.9 decoy-comment counterfactual copy still holds exactly one real dirstack.nu source line
            S3.9 decoy copy: src=350 mkcd=335 hook=382 (was 311/335/381)
      PASS  tree: S3.9 decoy-comment counterfactual (source moved after mkcd) FAILS the order check
      ```
      The `seen`-guard was verified load-bearing by hand before landing:
      an unguarded `/^}$/ && !done` (no `next`/`seen` gate on the deletion
      rule) against `home/dot_config/nushell/config.nu` lands the
      reinserted line at 105 — measured directly:
      `grep -n 'source ~/.config/nushell/dirstack.nu\|def --env mkcd'
      /tmp/unguarded3.nu` → `105:source ~/.config/nushell/dirstack.nu` /
      `335:def --env mkcd […]` — still far above `mkcd`, exactly the trap
      the spec calls out. The `seen`-guarded version actually used in the
      gate lands it at 349/350 (the `}` that closes `mkcd`), confirmed
      against a scratch copy: `grep -n 'source ~/.config/nushell/dirstack.nu\|def
      --env mkcd' /tmp/base3.nu` → `334:def --env mkcd […]` /
      `349:source ~/.config/nushell/dirstack.nu`.
- [x] A new S4.13 counterfactual: the real `source
      ~/.cache/nushell/init/starship.nu` line deleted and reinserted
      directly after the zoxide source line, with a decoy comment quoting
      the starship target prepended. `chk_ok` confirms exactly one real
      starship source line survives. `chk_fail` on `test "$ls_ln" -lt
      "$lz_ln" -a "$lz_ln" -lt "$lt_ln"` (via `line_of_decl` against the
      copy) is the PASS box.
      `bash tests/nushell-core.sh --tree` prints:
      ```
      PASS  tree: S4.13 decoy-comment counterfactual copy still holds exactly one real starship source line
            S4.13 decoy copy: starship=538 zoxide=537 television=539 (was 536/537/538)
      PASS  tree: S4.13 decoy-comment counterfactual (starship moved after zoxide) FAILS the order check
      ```
- [x] `bash tests/nushell-core.sh`, run alone, reaches `EXIT=0`. PASS count
      is at or above **250** (the 2026-08-25 re-measured baseline — not the
      212 quoted at filing; the file grew from other corrections landing
      in between, e.g. `dirstack-append-order-gate`'s DO boxes and the PT.*
      pty-ceiling boxes; **unmeasured whether 212 ever matched anything
      live** — treat it as stale, not wrong) plus the boxes this spec adds
      (2 `chk_ok` sanity boxes + 3 `chk_fail` counterfactual boxes = 5).
      FAIL stays 0.

      Both the 212 and the 250 quoted in this box are themselves now stale
      readings from before this spec's edits — the true count at the time
      this box is closed, `bash tests/nushell-core.sh` run alone:
      ```
      $ grep -c '^PASS' /tmp/final_full.txt; grep -c '^FAIL' /tmp/final_full.txt; tail -1 /tmp/final_full.txt
      256
      0
      EXIT=0
      ```
      256 PASS / 0 FAIL / EXIT=0, comfortably at-or-above 250. Note: this
      working tree carries other in-flight, uncommitted corrections to the
      same file (the PT.1–PT.7 pty-ceiling boxes and the S4.30
      `pwd_class`/raw-capture rework, visible in `git diff` below but not
      authored by this node — they were already present when this node's
      work began, per `nushell-core-s430-stall`) — the tally above is the
      whole file as it stands, not this spec's boxes in isolation. This
      spec added 6 boxes at the three sites (2 per site: 1 `chk_ok` sanity
      + 1 `chk_fail` counterfactual), not the 5 the estimate above assumed;
      the arithmetic in this box's original text was written before the
      per-site count was pinned down in the Acceptance list above (3 sites
      × 1 `chk_ok` = 3, not 2) — flagged rather than silently corrected.
- [x] `git diff -- tests/nushell-core.sh` touches only: `funnel_binds`'s
      body, the S4.11 label, S3.9's three assignments, S4.13's three
      assignments, and the three new counterfactual blocks (plus their
      supporting `local` declarations). `textual_order_ok`, the file's own
      `line_of_decl`, `line_of`, `line_of_code`, and every other existing
      `chk`/`chk_ok`/`chk_fail` line are byte-identical to before.

      Verified by construction (four `Edit` calls made in this session,
      each confined to one of the four sites) and confirmed with:
      `git diff -- tests/nushell-core.sh | grep -E '^[+-]' | grep -E
      'textual_order_ok|^\+line_of_decl\(\)|^-line_of_decl\(\)|^\+line_of\(\)|^-line_of\(\)|line_of_code\(\)'`
      → no output — none of those four definitions appear in the diff at
      all. Caveat: `git diff` against `HEAD` also shows unrelated,
      pre-existing uncommitted hunks (the PT.1–PT.7 pty-ceiling machinery
      and the S4.30 raw-capture rework) that were already in the working
      tree — visible in `git status` at the start of this session — and
      not introduced by this node; this box is about *this node's own*
      edits, which the four targeted `Edit` calls and the grep above
      confirm are confined to the four named sites.
- [x] The report states, per site, the shape chosen and why the other
      three don't fit (the table above, ported into the report — this is
      R2, and it is the durable half of this node per the PRD's own
      framing). Ported verbatim into the final report of this session (see
      the DONE message returned to the orchestrator).

## Verify and Proof

```sh
# fast iteration while editing (tree stage only, no real nushell/chezmoi):
bash tests/nushell-core.sh --tree

# the PRD's actual verify — all three stages, run alone:
bash tests/nushell-core.sh
echo "EXIT=$?"

# footprint discipline:
git diff --stat -- tests/nushell-core.sh
```
