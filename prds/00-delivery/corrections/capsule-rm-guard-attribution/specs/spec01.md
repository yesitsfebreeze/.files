---
est: 1h
footprint:
  - home/dot_config/nushell/capsule.nu
  - tests/capsule-lifecycle.sh
---

# spec01 — three `docker rm` sites, three named guards, one roster

`home/dot_config/nushell/capsule.nu:453` claims

```
# There is no code path that reaches `docker rm` outside the _capsule_owned set.
```

There are three `^docker rm` sites and only two of them read that set. The
third — `:405`, `^docker rm -f $name` on the `--rebuild` path — takes its
name from `_capsule_name` and is covered by an entirely different guard, the
`dir_label` emptiness refusal at `:399-401`.

This spec replaces the universal claim with a per-site enumeration, says in
`_capsule_state` that `dir_label` guards the `--rebuild` removal, and arms
the gate two ways: set equality between the sites in the file and a roster
the gate declares, and a hermetic scenario that goes red if the `dir_label`
refusal is ever dropped. Two files change. No guard changes.

## R3 first — the safety property, measured, both routes

Done at spec time, 2026-08-23, against `capsule.nu` as it stands. **The
property holds.** Re-run the scenario the spec adds; do not re-derive the
rest.

### Route A — `:405`, the `--rebuild` removal from `_capsule_name`

Five runs of the real CLI under `nu 0.114.1` against a recording docker
shim, no daemon, `PATH` = shim + `/usr/bin:/bin`:

| Input | Result |
|---|---|
| `--rebuild`, container exists, `capsule.dir` **empty** | exit 1, `capsule: a container named capsule-proj-3318c311 exists but was not created by capsule`, **0 `rm` lines** |
| `--rebuild`, container absent (`inspect` non-zero) | exit 0, 0 `rm` lines — the create path |
| `--rebuild`, container exists **with** a `capsule.dir` value | exit 0, exactly one `rm -f capsule-proj-59047f35`, equal to the independently derived name |
| no `--rebuild`, container exists, label empty (auto path) | exit 1, same refusal, 0 `rm` lines |
| `--rebuild`, label empty, **guard neutered in a scratch copy** | `rm -f capsule-proj-87c9751e` — the foreign container is removed |

The last row is why R2 matters: the refusal is the only thing between a
forced rebuild and a foreign container of the same name, and **no existing
check in either capsule gate notices its removal.** The new scenario 12
below is that check.

Two supporting facts, both measured rather than assumed:

- `_capsule_name` always prepends `$CAPSULE_PREFIX`, so `:405`'s target
  always carries the `capsule-` prefix. Prefix plus a non-empty
  `capsule.dir` is exactly the `_capsule_owned` predicate, which is why the
  old sentence's *conclusion* was right while its stated mechanism was
  false.
- `dir_label` is empty precisely when the label is absent. `index
  .Config.Labels "capsule.dir"` prints the empty string, never `<no
  value>` — confirmed against docker 29.4.0 (`docker network inspect bridge
  --format '[{{index .Labels "capsule.dir"}}]'` → `[]`) and against Go
  `text/template`'s `index` on a nil map, an empty map, a map with other
  keys, and a key present with an empty value (all four print empty). A
  `<no value>` would read as non-empty and open the guard; it does not
  happen.

### Route B — `:459`/`:461`, the two `clean` removals

Same harness, against the gate's own mixed fixture (two capsules, one
label-bearing container without the prefix, one prefix-bearing container
without the label, one `postgres`):

| Input | Removed |
|---|---|
| `capsule clean` | `rm capsule-old-deadbeef` only |
| `capsule clean --all` | `rm -f capsule-proj-abcd1234`, `rm capsule-old-deadbeef` |
| either, `--filter label=capsule.dir` dropped in a scratch copy | also `rm capsule-handmade` |

The victim set is read from exactly one command, `docker ps -a --filter
label=capsule.dir`, and `_capsule_owned` then filters on the prefix. This
route is already covered durably by scenario 9 and control 2.

### The one seam, recorded and out of scope

The two guards do not implement the same predicate. `_capsule_owned` is
label-**key** plus prefix; `:399-401` tests the label's **value**. They
agree on every container this tool can create, because the create line at
`:411` always writes `capsule.dir=$target` and `$target` is a verified
directory path. They diverge on a single input: a container named
`capsule-*` carrying `capsule.dir` with an empty value. Measured — `capsule
list` shows it with `dir: ""` and `capsule clean` removes it, while
`--rebuild` refuses it as foreign.

Nothing in this tool can produce that container; only a deliberate imitator
of the ownership marker can. Under the label-as-marker convention the file
already states, such a container has declared itself capsule's, so this is a
definitional seam rather than a destructive reach on a genuinely foreign
container, and the node's premise stands. **Do not "fix" it here** — this
spec changes no guard. The corrected comment states both predicates plainly
so the seam is visible instead of hidden, which is the whole point of the
node.

## The measured baseline

Both gates, run alone, 2026-08-23, before any edit:

| Gate | Before | Wall |
|---|---|---|
| `bash tests/capsule-lifecycle.sh` | 49 PASS / 0 FAIL, `EXIT=0` | 5.7 s |
| `bash tests/capsule-credentials.sh` | 102 PASS / 0 FAIL, `EXIT=0` | 12.9 s |

`tests/capsule-lifecycle.sh` is registered in **wave 3** and
`tests/capsule-credentials.sh` in **wave 4** (`gates/waves.tsv:24,25`). Both
are already there; this spec needs no row in `gates/waves.tsv` and none in
`gates/manual/wave*.md`. The credentials gate is in the acceptance because
six of its check functions read `capsule.nu` as text and a comment edit can
break them — see the forbidden-strings table.

## The design decision, already taken

Do not re-take it.

**Set equality against a declared roster, never a count.** `-eq 3` is the
exact shape [`armed-count-tripwires`](../../armed-count-tripwires/prd.md)
just removed from four checks: it passes while naming nothing, and it cannot
say *which* site arrived or left. Port the form landed in
`tests/shell-zoxide.sh` (`cited_ids`/`owned_ids_ok`) and
`tests/wezterm-f5-tab-select.sh` (`bound_rows`/`rows_ok`): extract the rows,
compare sets, print `MISSING`/`UNEXPECTED`.

**Rows are scoped by their enclosing `def`, not by text alone.** A fourth
`^docker rm -f $name` added inside `_capsule_build` has byte-identical
command text to the site at `:405`; a text-only set would absorb it in
silence. `rm_sites` therefore emits `<def> :: <command>`, exactly as
`bound_rows` scopes a keybinding by its key table. Verified: the
`_capsule_build` mutation reports `UNEXPECTED [_capsule_build :: ^docker rm
-f $name]`.

**Row identity carries no line numbers.** The comment edits move every site
down by ~38 lines; a roster of line numbers would need rewriting for a
change that alters no behavior.

**Comment lines are skipped by the extractor.** The corrected comment quotes
`^docker rm -f $name` — with comments included, that quotation becomes a
fourth row and the check fires on prose. `tests/capsule-credentials.sh:146-148`
records the same rule in the other direction ("a comment must never be able
to satisfy a presence check"); a comment must not be able to fake a site
either.

**The prose gets its own check.** Set equality proves the site count; it
cannot tell whether the comment still names the right guard for each site.
`attribution_ok` pins the tokens that carry the attribution and the absence
of the claim that was false.

## What to change — 1 of 2: `capsule.nu`, comments only

Three comment edits. **No code line changes**: after the edit, `diff <(grep
-vE '^[[:space:]]*#' <baseline>) <(grep -vE '^[[:space:]]*#' capsule.nu)`
must be empty.

**A. Replace the three-line `_capsule_state` header comment** (`:103-105`)
with:

```
# _capsule_state: {exists, running, dir_label} for one container name.
# dir_label empty on an existing container means it is NOT ours (R6's
# ownership marker) — never adopt it, never remove it.
#
# dir_label is load-bearing: it is what guards the `--rebuild` REMOVAL. Step
# 6 of `capsule` refuses on an empty dir_label, and step 7's
# `^docker rm -f $name` never consults _capsule_owned — so nothing else
# stands between a forced rebuild and a container this tool did not create.
# Measured 2026-08-23: with the emptiness test neutered, `--rebuild` against
# a same-named container carrying no capsule.dir label asks docker to remove
# it. The foreign-rebuild scenario in tests/capsule-lifecycle.sh and its
# control hold that down; a refactor that drops the refusal turns them red.
#
# Empty here really does mean "no marker": `index .Config.Labels` prints the
# empty string for a container that has no such label — measured against
# docker 29.4.0 and against text/template's `index` on a nil map, an empty
# map and a missing key. It never prints <no value>, which would read as
# non-empty and open the guard.
```

This is R2. The sentence `dir_label is load-bearing` is pinned by
`attribution_ok`; keep it verbatim. It names no scenario number on purpose —
the gate's numbering is the gate's business, and a renumbering must not make
this comment wrong.

**B. Add three lines to step 7's comment** (`:402-404`), directly above the
`if $rebuild and $state.exists` line, so the attribution sits at the site an
auditor actually reads:

```
    # The removal below is covered by step 6's dir_label refusal, NOT by
    # _capsule_owned — the site roster and both guards are enumerated at
    # `capsule clean`.
```

**C. Replace the `capsule clean` header comment** (`:450-453`) — the last
sentence is the false claim — with:

```
# capsule clean [--all] (R6): remove the STOPPED capsules; a bare invocation
# never kills a running container — the cheap mistake has to be the safe one.
# --all additionally stops and removes the running ones. Returns the removed
# names; an empty set returns an empty list and touches nothing.
#
# THE THREE `docker rm` SITES, AND THE GUARD OVER EACH. Enumerated, never
# claimed universally: what stood here was a universal claim, and it was
# measurably false — it said every removal went through the _capsule_owned
# set, and the `--rebuild` recreate never reads that set at all.
#   * `capsule` step 7, the `--rebuild` recreate — guarded by step 6's
#     dir_label refusal. See _capsule_state for why that field is
#     load-bearing.
#   * the stopped branch below — guarded by _capsule_owned.
#   * the running branch below, --all only — guarded by _capsule_owned.
#
# The two guards are not the same test. _capsule_owned is label-key AND name
# prefix; step 6 tests the label's VALUE. They agree on every container this
# tool can create, because the create line always writes a non-empty
# capsule.dir. They diverge on one input nothing here can produce: a
# container someone else named capsule-* and labelled with an EMPTY
# capsule.dir. Step 6 refuses that one; clean removes it.
#
# tests/capsule-lifecycle.sh declares this list as RM_SITES and asserts set
# equality against the file, so a fourth site turns that gate red until the
# roster and this comment are updated with it.
```

This is R1. Four strings are pinned by `attribution_ok` and must stay
verbatim: the enumeration heading (`THE THREE ... SITES, AND THE GUARD OVER
EACH`, backticks around `docker rm` included), `guarded by step 6's`, and
both occurrences of `guarded by _capsule_owned`.

**Note the near-miss on purpose.** The paraphrase says *"it said every
removal went through the `_capsule_owned` set"* and never the words `no code
path`, because `attribution_ok` asserts that phrase is gone. Do not restore
the original wording as a quotation — the check cannot tell a quotation from
a claim.

### Forbidden strings — check the text before running the gates

Both gates count these over the whole file, comments included. All three
comments above were validated against every one of the eight text-level
check functions in the two gates; if you reword, re-check.

| Must stay at zero | Asserted by |
|---|---|
| the word `cd` (`grep -cwE 'cd'`) | `c3_ok`, `tests/capsule-lifecycle.sh:132` |
| `just ` | `c3_ok` |
| `~/docker` | `c3_ok` |
| `($target)/workspace` | `c3_ok` |
| `sudo`, case-insensitive | `setup_exec_ok`, `tests/capsule-credentials.sh:157` |
| `-u root` | `setup_exec_ok` |
| `no code path`, case-insensitive | `attribution_ok`, new |

And two presence counts a comment can inflate: `def <name> [` must appear
exactly once each (`defs_ok`, `creds_defs_ok`) — so never spell a `def`
signature in prose — and `guarded by _capsule_owned` must appear exactly
twice.

## What to change — 2 of 2: `tests/capsule-lifecycle.sh`

**1. Declare the roster** after the `ANCHORS=` line (`:56`), with the reason:

```sh
# THE `docker rm` SITES, and why this is a roster and not a count: RM_SITES
# declares every removal site in capsule.nu, once, and stage --tree asserts
# SET EQUALITY between it and the file. Never `-eq 3`. A count passes while
# naming nothing, which is the shape prds/00-delivery/corrections/
# armed-count-tripwires just removed from four checks. Rows are scoped by
# the enclosing def, because a fourth `^docker rm -f $name` added inside
# _capsule_build has identical command text to the one in `capsule` and a
# text-only set would absorb it in silence. No line numbers: a comment edit
# moves every site and must not move this list.
#
# The guard over each site — the whole point of the node this check serves:
#   capsule            step 7, --rebuild -> step 6's dir_label refusal
#   capsule clean      the stopped branch -> _capsule_owned
#   capsule clean      the running branch -> _capsule_owned
RM_SITES=(
  'capsule :: ^docker rm -f $name'
  'capsule clean :: ^docker rm -f $row.name'
  'capsule clean :: ^docker rm $row.name'
)
```

**2. Add three functions** after `c3_ok` (`:133`), before `stage_tree`:

```sh
# Every `^docker rm` site, scoped by the def it sits in: "<def> :: <cmd>".
# COMMENT LINES ARE SKIPPED: the corrected prose quotes `^docker rm -f
# $name`, and a comment must no more be able to fake a site than to satisfy
# a presence check (tests/capsule-credentials.sh:146-148, the same rule in the
# other direction).
rm_sites() {
  awk '
    /^[[:space:]]*#/ { next }
    /^def / { d = $0; sub(/^def /, "", d); sub(/ *\[.*$/, "", d); gsub(/"/, "", d) }
    /\^docker rm/ {
      c = $0
      sub(/^.*\^docker rm/, "^docker rm", c)
      sub(/ \| ignore.*$/, "", c)
      gsub(/[[:space:]]+/, " ", c)
      print (d == "" ? "<no-def>" : d) " :: " c
    }
  ' "$1"
}

# Set equality between the `docker rm` sites in $1 and the roster named in
# $2 (an array name). Prints the count on success and MISSING/UNEXPECTED on
# failure, so one function serves the check and both counterfactuals.
# chk_ok discards output, so callers use `if diag="$(sites_ok ...)"`.
sites_ok() {
  local f="$1" arr="$2[@]" got want missing extra
  got="$(rm_sites "$f" | sort)"
  want="$(printf '%s\n' "${!arr}" | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s sites' "$(printf '%s\n' "$got" | wc -l | tr -d ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

# The guard attribution, as prose. Set equality proves the site COUNT; it
# cannot say whether the comment still names the right guard for each site,
# and naming the wrong one is the defect this node corrects. Comment lines
# only. The absence pin matters most: the sentence that stood at :453 said
# no code path reached a removal outside the _capsule_owned set, which was
# measurably false, and it must not come back as prose or as a quotation.
attribution_ok() {
  local f="$1" c
  c="$($GREP -E '^[[:space:]]*#' "$f")"
  printf '%s\n' "$c" | $GREP -qiF 'no code path' && return 1
  printf '%s\n' "$c" | $GREP -qF 'THE THREE `docker rm` SITES, AND THE GUARD OVER EACH' || return 1
  printf '%s\n' "$c" | $GREP -qF "guarded by step 6's" || return 1
  [ "$(printf '%s\n' "$c" | $GREP -cF 'guarded by _capsule_owned')" -eq 2 ] || return 1
  printf '%s\n' "$c" | $GREP -qF 'dir_label is load-bearing'
}
```

**3. Add the checks to `stage_tree`**, after the C-3 block (`:199`) and
before `guard_end`:

```sh
  # The `docker rm` roster (R4), as a set, plus both counterfactuals.
  local diag
  if diag="$(sites_ok "$CAPSULE_NU" RM_SITES)"; then
    chk "tree: the \`docker rm\` sites are exactly the ${#RM_SITES[@]} RM_SITES, def-scoped ($diag) — capsule step 7 guarded by the dir_label refusal, both clean branches by _capsule_owned" 0
  else
    chk "tree: the \`docker rm\` sites are not the ${#RM_SITES[@]} RM_SITES — $diag. An UNEXPECTED site is a NEW destructive path: name its guard in the \`capsule clean\` comment and add it here. A MISSING one means a removal moved or went away" 1
  fi
  local CF_RM_A="$SCRATCH/cf-rm-site-dropped.nu"
  awk '!/\^docker rm \$row.name/' "$CAPSULE_NU" > "$CF_RM_A"
  chk_ok "tree: counterfactual copy really dropped the stopped-branch removal" \
         test "$($GREP -vE '^[[:space:]]*#' "$CF_RM_A" | $GREP -cF '^docker rm $row.name')" -eq 0
  chk_fail "tree: counterfactual rm-site-dropped FAILS the site-set check" \
           sites_ok "$CF_RM_A" RM_SITES
  local CF_RM_B="$SCRATCH/cf-rm-site-in-another-def.nu"
  awk '/^def _capsule_build \[\] \{$/ { print; print "    ^docker rm -f $name | ignore"; next } { print }' \
      "$CAPSULE_NU" > "$CF_RM_B"
  chk_ok "tree: counterfactual copy really added a fourth removal inside _capsule_build" \
         test "$($GREP -vE '^[[:space:]]*#' "$CF_RM_B" | $GREP -cF '^docker rm -f $name')" -eq 2
  chk_fail "tree: counterfactual rm-site-in-another-def FAILS the site-set check — identical command text, different def" \
           sites_ok "$CF_RM_B" RM_SITES

  # The guard attribution as prose (R1, R2), plus the restored-claim
  # counterfactual.
  chk_ok "tree: each removal site's comment names the guard that covers IT — step 6's dir_label refusal for --rebuild, _capsule_owned twice for clean — and the universal claim is gone" \
         attribution_ok "$CAPSULE_NU"
  local CF_CLAIM="$SCRATCH/cf-universal-claim-restored.nu"
  awk '/^#   \* the stopped branch below/ { print "# There is no code path that reaches `docker rm` outside the _capsule_owned set." } { print }' \
      "$CAPSULE_NU" > "$CF_CLAIM"
  chk_ok "tree: counterfactual copy really restored the universal claim" \
         $GREP -qiF 'no code path' "$CF_CLAIM"
  chk_fail "tree: counterfactual universal-claim-restored FAILS the attribution check" \
           attribution_ok "$CF_CLAIM"
```

`if diag="$(sites_ok ...)"` keeps the function's status on the `if`. Never
write `sites_ok ...; chk "..." $?` — `gates/lib.sh:72` records that idiom
producing a false PASS in this repo.

**4. Add the new scenario's function** after `clean_foreign_ok` (`:331`),
before `no_docker_ok`:

```sh
# Scenario 12's rebuild guard as a function (control 4 re-runs it on a copy
# with the dir_label refusal neutered): `--rebuild` against an existing
# container of the derived name that carries NO capsule.dir label must exit
# non-zero, say so, and reach `docker rm` NEVER. Nothing else in either
# capsule gate notices if that refusal is dropped, and dropping it removes a
# foreign container — measured.
rebuild_foreign_ok() {
  local mod="$1" M="$2" dir name prc
  mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  # Exists, running, capsule.dir EMPTY — the shim prints "true\t".
  printf 'running\n\n' > "$M/ctl/ct-$name"
  nu_cap_with "$mod" "$M" "capsule --rebuild $dir" > "$M/rf.out" 2> "$M/rf.err"
  prc=$?
  [ "$prc" -ne 0 ] || return 1
  $GREP -qF 'was not created by capsule' "$M/rf.err" || return 1
  [ "$(log_n "$M" '^rm ')" -eq 0 ]
}
```

**5. Add it as scenario 12** in `stage_hermetic`, after scenario 11 (`:511`)
and before the controls block:

```sh
  # ── scenario 12: --rebuild never removes a foreign container ──────────────
  chk_ok "hermetic: s12 --rebuild against a same-named container with NO capsule.dir label: non-zero exit, an error naming the container, ZERO rm lines — step 6's refusal, not _capsule_owned" \
         rebuild_foreign_ok "$CAPSULE_NU" "$SCRATCH/h12"
```

`$SCRATCH/h12` is free: the controls block uses `h12a`, `h12b`, `h12c`.

**6. Renumber the controls block to 13 and add the fourth control.** The
block header at `:513` becomes

```sh
  # ── scenario 13: selftest controls — each mutation must FAIL its scenario ──
```

and every `chk` label inside it reads `s13 control …`, so the new scenario
keeps the sequence and the controls stay last. Rename the three existing
controls with a substitution over that block only (`s12 control` → `s13
control`, six labels — each control is a `chk_ok` copy-really-mutated pair
with a `chk_fail`), then append the fourth, after the
`record-before-the-checks` control (`:538`) and before the live-tree
assertion:

```sh
  MUT="$SCRATCH/mut-noguard.nu"
  awk 'index($0, "if $state.exists and ($state.dir_label | is-empty) {") { print "    if false {"; next } { print }' \
      "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s13 control copy really neutered the dir_label refusal" \
         test "$($GREP -cF 'dir_label | is-empty' "$MUT")" -eq 0
  chk_fail "hermetic: s13 control dir_label-refusal-neutered FAILS scenario 12 — the foreign container is removed" \
           rebuild_foreign_ok "$MUT" "$SCRATCH/h13b"
```

`if false {` keeps the block structure, so the copy still parses under `nu
-n` — verified. Deleting the three guard lines instead leaves a stray
`error make` body and fails for the wrong reason.

**7. Update the stage description** in the file header. The `--tree` bullet
(`:11-14`) gains the roster, and the `--hermetic` bullet's `Eleven
scenarios plus three selftest controls` (`:20-21`) becomes `Twelve scenarios
plus four selftest controls`. Keep the sentence after it —
"a check that cannot fail proves nothing".

Nothing else in either file changes. `home/dot_config/nushell/` changes in
`capsule.nu`'s comments only.

## Acceptance

- [x] `bash tests/capsule-lifecycle.sh`, run **alone**, reaches `EXIT=0`
      with **0 FAIL**. `capsule-lifecycle: 60 pass, 0 fail`, `rc=0`, against
      the measured baseline `capsule-lifecycle: 49 pass, 0 fail`. Eleven
      checks added, exactly as predicted.
- [x] `bash tests/capsule-credentials.sh`, run **alone**, reaches `EXIT=0`
      with **0 FAIL**. `capsule-credentials: 102 pass, 0 fail`, `rc=0` —
      identical to the before-run, so none of its six text-level checks
      moved.
- [x] The site-set check PASSes naming the sites and their guards:
      `PASS  tree: the \`docker rm\` sites are exactly the 3 RM_SITES,
      def-scoped (3 sites) — capsule step 7 guarded by the dir_label
      refusal, both clean branches by _capsule_owned`.
- [x] Counterfactual A: `PASS  tree: counterfactual rm-site-dropped FAILS
      the site-set check`. Re-derived by hand through the gate's own
      `sites_ok`: `MISSING [capsule clean :: ^docker rm $row.name];
      UNEXPECTED []`.
- [x] Counterfactual B: `PASS  tree: counterfactual rm-site-in-another-def
      FAILS the site-set check — identical command text, different def`.
      Re-derived: `MISSING []; UNEXPECTED [_capsule_build :: ^docker rm -f
      $name]` — def scoping earns its place, a text-only set would pass.
- [x] `attribution_ok`: `PASS  tree: each removal site's comment names the
      guard that covers IT — step 6's dir_label refusal for --rebuild,
      _capsule_owned twice for clean — and the universal claim is gone`, and
      `PASS  tree: counterfactual universal-claim-restored FAILS the
      attribution check`.
- [x] Scenario 12 and control 4:
      `PASS  hermetic: s12 --rebuild against a same-named container with NO
      capsule.dir label: non-zero exit, an error naming the container, ZERO
      rm lines — step 6's refusal, not _capsule_owned` and
      `PASS  hermetic: s13 control dir_label-refusal-neutered FAILS scenario
      12 — the foreign container is removed`. From a by-hand run of the
      control's machine, the destructive line the refusal prevents:
      `rm -f capsule-proj-d5f03d78` in `invocations.log` — against a
      container carrying no `capsule.dir`. The unmutated file on the same
      machine logs zero `rm` lines and errors with `capsule: a container
      named capsule-proj-dcdb3051 exists but was not created by capsule`.
- [x] The renumbering left no stale label: `/usr/bin/grep -c 's12 control'`
      prints `0`, `/usr/bin/grep -c 's13 control'` prints `8`, and the three
      renamed controls still name their scenarios:
      `PASS  hermetic: s13 control mount-target-($target)/workspace FAILS
      scenario 6`, `PASS  hermetic: s13 control rm-outside-the-owned-set
      (label filter dropped) FAILS scenario 9`, `PASS  hermetic: s13 control
      record-before-the-checks FAILS scenario 11`.
- [x] Comment-only: `diff <(/usr/bin/grep -vE '^[[:space:]]*#'
      /tmp/capsule-baseline.nu) <(/usr/bin/grep -vE '^[[:space:]]*#'
      home/dot_config/nushell/capsule.nu)` printed nothing. Baseline taken
      with `cp` before editing.
- [x] `PASS  hermetic: capsule.nu parses standalone under nu -n` in the run
      above; also confirmed directly with `nu -n -c "source …/capsule.nu"`.
- [x] No forbidden string arrived. Over
      `home/dot_config/nushell/capsule.nu`: `-cwE 'cd'` → `0`,
      `-ciF sudo` → `0`, `-cF -- '-u root'` → `0`, `-cF 'just '` → `0`,
      `-cF '~/docker'` → `0`, `-ciF 'no code path'` → `0`,
      `-cF '($target)/workspace'` → `0`, and
      `-cF 'guarded by _capsule_owned'` → `2`. Every one of the ten
      `def <name> [` signatures still counts `1`.
- [x] `bash gates/wave-status.sh --run 3` exits `rc=0` with
      `/usr/bin/grep -c '^FAIL'` → `0`.
- [x] Nothing outside the footprint moved. Only
      `home/dot_config/nushell/capsule.nu` and
      `tests/capsule-lifecycle.sh` were edited; `~/.config/nushell/capsule.nu`
      and `~/.cache/capsule` do not exist on this host and were never
      created. The gate's own guards agree:
      `PASS  hermetic: live ~/.cache/capsule and ~/.config/nushell/capsule.nu
      untouched`, and `guard[tree]`/`guard[hermetic]` report the same sha256
      `02d5d4ee…` in and out.

## Verify and Proof

Run each gate **alone**. Parallel gate runs produce false reds, and another
implementer is on the board.

```sh
cp home/dot_config/nushell/capsule.nu /tmp/capsule-baseline.nu   # BEFORE editing

bash tests/capsule-lifecycle.sh 2>&1 | tee /tmp/cap-life.log; echo "rc=$?"
grep -c '^PASS' /tmp/cap-life.log; grep -c '^FAIL' /tmp/cap-life.log
grep -nE 'RM_SITES|rm-site-dropped|rm-site-in-another-def|guard that covers IT|universal-claim-restored|s12 |s13 control' /tmp/cap-life.log

bash tests/capsule-credentials.sh 2>&1 | tee /tmp/cap-creds.log; echo "rc=$?"
grep -c '^PASS' /tmp/cap-creds.log; grep -c '^FAIL' /tmp/cap-creds.log

diff <(/usr/bin/grep -vE '^[[:space:]]*#' /tmp/capsule-baseline.nu) \
     <(/usr/bin/grep -vE '^[[:space:]]*#' home/dot_config/nushell/capsule.nu)

/usr/bin/grep -cwE 'cd' home/dot_config/nushell/capsule.nu
/usr/bin/grep -ciF sudo home/dot_config/nushell/capsule.nu
/usr/bin/grep -cF -- '-u root' home/dot_config/nushell/capsule.nu
/usr/bin/grep -cF 'just ' home/dot_config/nushell/capsule.nu
/usr/bin/grep -cF '~/docker' home/dot_config/nushell/capsule.nu
/usr/bin/grep -ciF 'no code path' home/dot_config/nushell/capsule.nu
/usr/bin/grep -cF 'guarded by _capsule_owned' home/dot_config/nushell/capsule.nu

bash gates/wave-status.sh --run 3; echo "rc=$?"
```

## Out of scope

- **Every guard.** `:399-401`, `_capsule_owned`'s label-and-prefix filter,
  and the `docker ps` filter stay exactly as they are. This spec corrects
  prose and adds assertions.
- The empty-valued-`capsule.dir` seam recorded under R3. It is a
  definitional divergence between two guards over an input this tool cannot
  produce; closing it means changing a guard, which belongs to C.1 or C.2,
  not here.
- That the `dir_label` refusal fires *after* `_capsule_build` and the
  synchronous credential export, so a foreign container costs a wasted
  build. Measured, harmless, and a behavior change to move it.
- `gates/waves.tsv` and `gates/manual/wave*.md`. Both gates are already
  registered (waves 3 and 4) and everything here is machine-checkable; no
  row is needed and neither file is the implementer's to edit.
- Every other assertion in `tests/capsule-lifecycle.sh`, and all of
  `tests/capsule-credentials.sh` — run, never edited.
- Any real `docker rm`. Both routes are proven against the recording shim;
  no scenario may reach a daemon.
