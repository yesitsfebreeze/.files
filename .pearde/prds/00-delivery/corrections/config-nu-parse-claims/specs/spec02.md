---
est: 1h
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
---

# spec02 — gate the corrected reasons, and arm the textual-binding roster

Two insertions into `tests/nushell-core.sh`, both in `stage_tree`. `CP.1` –
`CP.7` pin spec01's corrected reasons so the retired wordings cannot come
back. `CP.8` – `CP.9` are R4: the assertion that keeps claim 1's conclusion
from being "simplified", in the durable roster form.

Runs after spec01. Nothing else in the file changes; no other file changes.
This spec adds checks only — no existing check is retargeted here (spec01
owns the one line that had to move).

## Why R4 is a roster and not the one pair

R4 asks for one assertion: `alias core-ls = ls` precedes `def ls`, with a
swapped counterfactual. Two findings shape how it lands.

**That exact pair is already asserted — in a gate this node must not edit.**
`tests/shell-listing.sh:366-375` (`order_ok` / `T1`) compares
`alias core-ls = ls` < `def ls [` < `def la [` < the second PWD append and
carries the `core-ls`-after-`def ls` counterfactual. That file belongs to
`04-shell/06-listing`. The assertion R4 wants therefore has to be built here,
in `04-shell/01-core-config`'s gate, which is this node's `verify` and the
gate that owns config.nu's ordering contract (`S4.10`, `S4.11`, `S3.9`).
Cross-gate duplication of an ordering claim is the established pattern:
`tests/shell-listing.sh`'s own header says it greps the ten anchors itself
because "tests/nushell-core.sh belongs to 04-shell/01 and is not called
into". Do not "simplify" this by deleting the check and pointing at the
sibling gate.

**One pair is a tripwire with one tooth.** The ordering hazard is wider. The
census is in the report; two of its rows matter here:

- `def --env mkcd` before `alias cd = mkcd` is load-bearing and **nothing in
  the tree asserts it**. Measured: swapped, the first `cd` gives
  ``Command `mkcd` not found``.
- config.nu is co-written by `S.1`–`S.9` plus the terminal, help and capsule
  nodes, so the live hazard is a **new alias arriving un-classified**, which
  no pair comparison can see.

So the check is set equality against a declared roster, the form
`armed-count-tripwires` landed: `tests/shell-zoxide.sh:213-244`
(`cited_ids` / `owned_ids_ok`) and `tests/wezterm-f5-tab-select.sh:43-107`
(`bound_rows` / `rows_ok`). Set equality is what makes an **arrival** visible;
a count cannot see an arrival that replaces a departure, and deriving the
count from config.nu itself is `n == n`.

## Insertion 1 — the roster declarations

Beside `ANCHORS` (`tests/nushell-core.sh:78`), after the `ANCHORS=` line.

```bash
# ── the textual-binding roster (00-delivery/corrections/config-nu-parse-claims
# R4) ────────────────────────────────────────────────────────────────────────
# An alias is the one declaration in config.nu that binds TEXTUALLY: its
# target resolves where the parser meets the `alias` line, and unlike a def it
# is NOT predeclared. Measured 0.114.1: `alias core-ls = ls` after `def ls`
# gives ``Command `core-ls` not found`` on the first `ls`; `alias cd = mkcd`
# above `def --env mkcd` gives ``Command `mkcd` not found``. Both failures are
# loud, and both are invisible to any check that only reads one pair.
#
# WHY A ROSTER AND NOT THE PAIR. config.nu is co-written by S.1 through S.9
# plus the terminal, help and capsule nodes, so the hazard is a NEW alias
# arriving with nobody having asked whether its position matters. Set equality against a declaration made HERE makes an
# arrival red; a count cannot see an arrival that replaces a departure, and
# deriving the count from config.nu is `n == n`. Same reason, same shape as
# tests/shell-zoxide.sh's owned_ids_ok and tests/wezterm-f5-tab-select.sh's
# rows_ok.
#
# Each row is "<alias line>|<owner>". FREE means no name in this file resolves
# to it, so its position is free. Otherwise the owner names the check that
# asserts its ordering. Adding an alias without adding a row here FAILS, by
# design: that failure is the question being asked.
CONFIG_ALIASES=(
  'alias cat = bat --paging=never|FREE'
  'alias grep = rg|FREE'
  'alias g = git|FREE'
  'alias lg = lazygit|FREE'
  'alias nv = nvim|FREE'
  'alias vi = nvim|FREE'
  'alias nn = nvim ~/notes.md|FREE'
  'alias q = exit|FREE'
  'alias ":q" = exit|FREE'
  'alias "/exit" = exit|FREE'
  'alias rr = chezmoi update --force|FREE'
  'alias core-ls = ls|CP.9'
  'alias cd = mkcd|CP.9, and S4.11 for the zoxide half'
  'alias core-help = help|tests/shell-help.sh capture_ok'
)

# The order-sensitive pairs, "<earlier>|<later>|<why>". Compared by first-match
# line number, so each side must be a string that appears once.
TEXTUAL_ORDER=(
  'alias core-ls = ls|def ls [|the alias must capture the BUILTIN ls'
  'def --env mkcd|alias cd = mkcd|an alias target is not predeclared'
  'alias cd = mkcd|source ~/.cache/nushell/init/zoxide.nu|the init calls cd'
)
```

## Insertion 2 — the two checkers

Beside `funnel_binds` (`tests/nushell-core.sh:321-328`), after it, so a
counterfactual can run the same function against a broken copy.

```bash
# Set equality between config.nu's alias lines and CONFIG_ALIASES. Prints the
# count on success and MISSING/UNEXPECTED on failure — chk_ok discards output,
# so callers use `if diag="$(alias_roster_ok …)"`.
alias_roster_ok() {
  local f="$1" got want missing extra
  got="$($GREP -E '^alias ' "$f" | sort)"
  want="$(printf '%s\n' "${CONFIG_ALIASES[@]}" | cut -d'|' -f1 | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s aliases' "$(printf '%s\n' "$got" | $GREP -c .)"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

# Every TEXTUAL_ORDER pair holds in $1. Names the pair that fails on stderr.
textual_order_ok() {
  local f="$1" row a b la lb
  for row in "${TEXTUAL_ORDER[@]}"; do
    a="${row%%|*}"; b="${row#*|}"; b="${b%%|*}"
    la="$(line_of "$f" "$a")"; lb="$(line_of "$f" "$b")"
    if [ "$la" -gt 0 ] && [ "$lb" -gt 0 ] && [ "$la" -lt "$lb" ]; then :; else
      echo "      order fails: [$a]=$la is not above [$b]=$lb" >&2
      return 1
    fi
  done
  return 0
}
```

## Insertion 3 — CP.8 and CP.9

In `stage_tree`, straight after `S4.11`'s counterfactual (the block ending
`chk "tree: S4.11 counterfactual alias-after-zoxide FAILS the funnel check"`,
`tests/nushell-core.sh:401-408`). `S4.11` stays exactly as it is: its
counterfactual carries the measured silent-failure narrative and is the
stronger check of the two for that pair.

```bash
  # CP.8 / CP.9 — R4. The roster, then the orderings, each with a
  # counterfactual, because a guard with no failing counterfactual is
  # decoration.
  local diag
  if diag="$(alias_roster_ok "$CONFIG_NU")"; then
    chk "tree: CP.8 config.nu's aliases are exactly the declared roster ($diag)" 0
  else
    chk "tree: CP.8 config.nu's aliases are exactly the declared roster — $diag" 1
  fi
  local CFA="$SCRATCH/cf-extra-alias.nu"
  { cat "$CONFIG_NU"; printf 'alias undeclared-arrival = ls\n'; } > "$CFA"
  # chk_fail discards the command's output, so the diagnostic is printed
  # first — the naming is the whole value of the failure message.
  echo "      $(alias_roster_ok "$CFA" || true)"
  chk_fail "tree: CP.8 counterfactual an undeclared alias arriving FAILS the roster check" \
           alias_roster_ok "$CFA"

  if textual_order_ok "$CONFIG_NU" 2>/dev/null; then
    chk "tree: CP.9 both textual-binding pairs hold (core-ls $(line_of "$CONFIG_NU" 'alias core-ls = ls') < def ls $(line_of "$CONFIG_NU" 'def ls ['); def mkcd $(line_of "$CONFIG_NU" 'def --env mkcd') < alias cd $(line_of "$CONFIG_NU" 'alias cd = mkcd') < zoxide init $(line_of "$CONFIG_NU" 'source ~/.cache/nushell/init/zoxide.nu'))" 0
  else
    textual_order_ok "$CONFIG_NU"
    chk "tree: CP.9 both textual-binding pairs hold" 1
  fi
  # The counterfactual R4 names: core-ls moved BELOW def ls. Measured
  # consequence: ``Command `core-ls` not found`` on the first `ls`.
  local CFO="$SCRATCH/cf-core-ls-after-def-ls.nu"
  awk '
    /^alias core-ls = ls$/ { next }
    { print }
    /^def ls \[$/          { print "alias core-ls = ls" }
  ' "$CONFIG_NU" > "$CFO"
  chk_ok "tree: CP.9 counterfactual copy still holds exactly one core-ls alias" \
         test "$($GREP -cxF 'alias core-ls = ls' "$CFO")" -eq 1
  textual_order_ok "$CFO" 2>&1 1>/dev/null || true
  chk_fail "tree: CP.9 counterfactual core-ls-after-def-ls FAILS the order check" \
           textual_order_ok "$CFO"
  # …and the pair nothing asserted before this node: alias cd above def mkcd.
  local CFM="$SCRATCH/cf-alias-cd-above-mkcd.nu"
  awk '
    /^alias cd = mkcd$/ { next }
    /^def --env mkcd/   { print "alias cd = mkcd" }
    { print }
  ' "$CONFIG_NU" > "$CFM"
  chk_ok "tree: CP.9 counterfactual copy still holds exactly one cd alias" \
         test "$($GREP -cxF 'alias cd = mkcd' "$CFM")" -eq 1
  textual_order_ok "$CFM" 2>&1 1>/dev/null || true
  chk_fail "tree: CP.9 counterfactual alias-cd-above-def-mkcd FAILS the order check" \
           textual_order_ok "$CFM"
```

All four were run against the current `config.nu` by the analyst: green on
the real file (`14 aliases`, all three pairs), and red on all three
counterfactuals with the pair named —
`order fails: [alias core-ls = ls]=254 is not above [def ls []=253` and
`order fails: [def --env mkcd]=310 is not above [alias cd = mkcd]=309`, and
`MISSING []; UNEXPECTED [alias undeclared-arrival = ls]`.

## Insertion 4 — CP.1 to CP.7

In `stage_tree`'s "the hard-won why" section, after the `PB.7` block
(`tests/nushell-core.sh:631-635`), before the
`chk_ok "why: the guard deviation is recorded in BOTH files…"` line. Uses
that section's `$CFG_TXT` and `has`.

```bash
  # CP.1 – CP.7 — 00-delivery/corrections/config-nu-parse-claims R1/R2. Both
  # reasons this node corrected were RIGHT in conclusion and WRONG in
  # mechanism, which is the shape that gets the right thing undone. A reason
  # nothing checks is a reason the next editor rewrites back.
  chk_fail "why: CP.1 config.nu no longer says la has to be defined above the closure" \
           $GREP -qF 'has to be defined above it' "$CONFIG_NU"
  chk_ok "why: CP.2 the LISTING lead-in states that defs are predeclared" \
         has . "$CFG_TXT" 'PREDECLARES every def in a block'
  chk_ok "why: CP.3 …with both controls that show def order is free here" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'la.txt: LA-RAN')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'LATER-RAN')"
  chk_ok "why: CP.4 …and the mechanism that IS load-bearing, with the core-ls pair" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'WHAT BINDS TEXTUALLY IS AN ALIAS AND A `source`')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'MUST precede `def ls`')"
  chk_ok "why: CP.5 …and the asymmetry that would make the anchor order matter" \
         has . "$CFG_TXT" 'had the auto-list closure named an ALIAS'
  chk_fail "why: CP.6 config.nu no longer claims a failing source takes the whole shell down" \
           $GREP -qF 'takes the whole shell down' "$CONFIG_NU"
  chk_ok "why: CP.6 …and states the measured radius instead" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'A WORKING BUT NAKED REPL')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ALIVE=4')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ABOVE the failing line as well as the ones below')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'NEVER RUNS THE COMMAND, and exits 1')"
  chk_ok "why: CP.7 the MODULES anchor and the header bullet agree with GENERATED" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'DISCARDS THE WHOLE OF THIS FILE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'not a shell that refuses to start')"
```

`CP.1` targets `has to be defined above it` and not the longer sentence,
because `closure's command calls at PARSE time` also appears at the FUNNEL
anchor, which this node does not touch. `CP.6`'s `chk_fail` covers both
retired sites at once — GENERATED and MODULES — so neither can regress
alone.

## Acceptance

- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, with the
      tally quoted and not asserted as a fresh absolute. The pre-change
      baseline is 187 PASS / 0 FAIL; this spec adds 15 checks.
- [x] `CP.8` green with its member count in the label, and its counterfactual
      quoted red naming `alias undeclared-arrival = ls` as `UNEXPECTED`.
- [x] `CP.9` green with all five line numbers in the label, and **both**
      counterfactuals quoted red, each naming the pair that failed.
- [x] `CP.1` and `CP.6` quoted green — that is, the two retired phrases are
      absent from `config.nu`.
- [x] `CP.2` – `CP.5` and `CP.7` quoted green against spec01's prose.
- [x] The diff against a `cp`-aside baseline of `tests/nushell-core.sh` is
      **insertions only**. The file is untracked, so `git diff` is empty by
      construction; diff against the copy.
- [x] No number appears in `CONFIG_ALIASES` or `TEXTUAL_ORDER`, and
      `${#…[@]}` / `$GREP -c .` is the only place a count is computed.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# 1 — the gate, alone. Quote the tally.
bash tests/nushell-core.sh > /tmp/cp.log 2>&1; echo "EXIT=$?"
/usr/bin/grep -c '^PASS' /tmp/cp.log; /usr/bin/grep -c '^FAIL' /tmp/cp.log

# 2 — the new checks, by name.
/usr/bin/grep -E '^(PASS|FAIL) +(tree|why): CP\.' /tmp/cp.log

# 3 — insertions only.
diff "$BASE/nushell-core.sh" tests/nushell-core.sh | /usr/bin/grep -c '^<'

# 4 — no bare count in either roster.
/usr/bin/grep -nE "^\s*(CONFIG_ALIASES|TEXTUAL_ORDER)=\(" -A 20 tests/nushell-core.sh \
  | /usr/bin/grep -E "[0-9]" ; echo "digits in the rosters above: none expected"
```
