---
est: 0.5h            # calibrated: raw 2h / 4.0x, this board's est:actual ratio
footprint:
  - gates/nushell-module-staging.sh
---

# spec01 — the GREEN half goes red by its own mutation before it goes green

Replace the GREEN half of `gates/nushell-module-staging.sh --selftest` with the
red-before-repair shape from `gates/audit-findings.sh:232-243`. Today the half
runs a `sed` that no longer matches, asserts an end state the unmutated file
already satisfies, and reports PASS twice while proving nothing. After this
change the half manufactures its own red in the copy, proves the copy is red,
repairs it, and proves the copy came back — and every edit is proved to have
changed the file, so a `sed` whose anchor stops matching goes loudly red.

## The measurement this spec is built on — analyst, 2026-08-23

| fact | measurement |
|---|---|
| the `sed` at `gates/nushell-module-staging.sh:311-316` | run against a copy of the live `tests/shell-television.sh`; `cmp` reports the two byte-identical |
| the guard at `:315-316` | `/usr/bin/grep -cE 'for m in .*copymode help; do' tests/shell-television.sh` → `1` on the **unmutated** file |
| `tests/shell-television.sh:471` | `  for m in dirstack pass theme claude zoxide history capsule finder copymode help; do` |
| `bash gates/nushell-module-staging.sh` (live) | 40 PASS, 0 FAIL, exit 0, **1.29s** |
| `bash gates/nushell-module-staging.sh --selftest` | 8 PASS, 0 FAIL, exit 0 — green, and vacuous |
| `bash gates/selftest.sh` | 37 PASS, **1 FAIL** — `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`, another node's |

Why `gates/selftest.sh` never caught it: its `contract: … really changed its
scratch tree` guard hashes **one** scratch root across the whole selftest, and
the RED half changes that root. A second half that changes nothing is invisible
to a single aggregate hash.

## The shape to write

Add one helper at file scope, immediately above `selftest()`. It is the
tripwire R3 demands — a no-op `sed` and a landed `sed` are indistinguishable
until something compares the bytes.

```sh
# edit_proved <label> <file> <sed -E expr>  — apply an in-place edit and PROVE
# it changed the file. A sed whose anchor stopped matching is indistinguishable
# from success, which is how this selftest's GREEN half went vacuous; the
# sha256 comparison is what makes the two distinguishable.
edit_proved() {
  local label="$1" f="$2" expr="$3" before after
  before="$(shasum -a 256 "$f" | awk '{print $1}')"
  LC_ALL=C sed -i '' -E "$expr" "$f"
  after="$(shasum -a 256 "$f" | awk '{print $1}')"
  chk_ok "$label (sha ${before:0:12} -> ${after:0:12})" test "$before" != "$after"
}
```

Replace the GREEN block (`gates/nushell-module-staging.sh:305-318`, from the
`# ── GREEN` banner to the `run_repo "$GREEN"` line before
`assert_unchanged`) with this. Executed end to end by the analyst against a
full scratch copy of the repo; every line below passed.

```sh
  # ── GREEN — red by this half's OWN mutation, then repaired ──────────
  # The MISS this half was built around (shell-television not staging help.nu)
  # was fixed on the live tree, so a repair-only half repaired nothing: the
  # copy was byte-identical to its source, the gate was green because it was
  # ALREADY green, and the end-state grep that guarded it matched the
  # unmutated file. The red-before is what earns the green-after.
  GREEN="$T/green"
  scratch_tree "$GREEN" > /dev/null
  local TV="$GREEN/tests/shell-television.sh"
  edit_proved "selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list" \
    "$TV" 's/^([[:space:]]*for m in [a-z ]*copymode) help(; do)/\1\2/'
  echo "      MUTATION: removed help from the \`for m in\` staging list in $TV"
  chk_fail "selftest GREEN: the copy is red before repair" run_repo "$GREEN"
  chk_ok   "selftest GREEN: and the FAIL names the gate and the module" \
    says "$GREEN" "does not stage help.nu"
  edit_proved "selftest GREEN: the repair changed the copy back" \
    "$TV" 's/^([[:space:]]*for m in [a-z ]*copymode)(; do)/\1 help\2/'
  echo "      MUTATION: repaired the copy by restoring help to the staging list"
  chk_ok "selftest GREEN: the repaired copy is byte-identical to the managed file — the repair is the exact inverse" \
    cmp -s "$TV" "$REPO_ROOT/tests/shell-television.sh"
  chk_ok "selftest GREEN: with the repair landed, the gate is green" \
    run_repo "$GREEN"
```

Constraints:

- `tests/shell-television.sh` is not edited. R4. The mutation lands in
  `$GREEN`, a `scratch_tree` copy, and `assert_unchanged` keeps proving it.
- The `local TV` line stays inside `selftest()`; `edit_proved` is a sibling of
  `selftest()`, not nested in it.
- Do not restore the retired MISS. The gate has zero misses on the live tree
  and must keep having zero.

## The header comment is now false

`gates/nushell-module-staging.sh:47-50` reads "Known state on 2026-08-23:
exactly one MISS — tests/shell-television.sh does not stage help.nu
(config.nu:450) … the red is CORRECT until it lands." Measured today: zero
misses, and `config.nu` sources `help.nu` at **line 565**. Rewrite that
paragraph to the present state. Leave line 10's historical account of the
outage alone — it records what happened, not what is.

## The tripwire demonstration

Validated by the analyst; reproduce it and quote the output.

```sh
W=$(mktemp -d)/trip; mkdir -p "$W"
for d in prds docs tests home gates; do cp -R "$d" "$W/"; done
for f in ./*; do [ -f "$f" ] || [ -L "$f" ] || continue; cp -R "$f" "$W/"; done
LC_ALL=C sed -i '' -E 's/for m in \[a-z \]\*copymode/for m in [a-z ]*nosuchmod/g' \
  "$W/gates/nushell-module-staging.sh"
cd "$W" && bash gates/nushell-module-staging.sh --selftest; echo "rc=$?"
```

Copy the whole tree, never symlink it: `scratch_tree` uses `cp -R`, which
copies a symlinked directory as a symlink, and the half's `sed -i` would then
write through it into the real `tests/`.

Expected — measured by the analyst on the patched gate:

```
FAIL  selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list (sha 6bba961f21d9 -> 6bba961f21d9)
FAIL  selftest GREEN: the copy is red before repair
FAIL  selftest GREEN: and the FAIL names the gate and the module
FAIL  selftest GREEN: the repair changed the copy back (sha 6bba961f21d9 -> 6bba961f21d9)
── selftest rc=1 ──────────────────────────────────────────────────
```

The equal sha pair on one line is the whole point: the FAIL says the file did
not move, not merely that something is wrong.

## R5 — the census

Scope: every script carrying a `--selftest)` case. Nine on 2026-08-23:

```
gates/audit-findings.sh   gates/manual-coverage.sh  gates/nushell-module-staging.sh
gates/probes.sh           gates/retired-phrases.sh  gates/selftest.sh
gates/tree-links.sh       gates/wave-status.sh      tests/managed-config.sh
```

Predicate, applied per mutation site inside each selftest — report the answer
for each of the three columns:

| column | question |
|---|---|
| no-op-capable | is the mutation a `sed -i`, a `grep -v` filter or another anchored rewrite that produces an unchanged file when its anchor stops matching? An append or a create is not. |
| end-state guard | is the "the mutation really landed" proof a match for the state the mutation is supposed to produce, rather than a comparison against the pre-mutation state? |
| silent | with the anchor broken, does the selftest still exit 0? A following `chk_fail`, or a precondition asserted on the pre-mutation state, makes it loud. |

A site is the same defect only when all three are yes. Report the count of
same-defect sites, the count of end-state guards that are loud anyway, and the
predicate text used, one line per site. Fix nothing outside
`gates/nushell-module-staging.sh` — one gate per node.

## Acceptance

- [x] `edit_proved` exists at file scope in `gates/nushell-module-staging.sh`
      and is the only path by which the GREEN half edits a file.
- [x] `bash gates/nushell-module-staging.sh --selftest` exits 0 and prints a
      GREEN half with, in this order: a `mutation changed the copy` PASS
      carrying two **different** sha prefixes, a `the copy is red before
      repair` PASS, a `repair changed the copy back` PASS, and a `the gate is
      green` PASS. Quote all of them.
- [x] The `red before repair` line is a `chk_fail` against `run_repo
      "$GREEN"`, and the FAIL it consumes names `does not stage help.nu`.
      Quote the `says` assertion's PASS line.
- [x] `grep -n 'for m in .*copymode help; do'` appears nowhere in
      `gates/nushell-module-staging.sh` — the vacuous guard is gone, not
      supplemented.
- [x] The tripwire is demonstrated by the recipe above: the selftest of the
      anchor-broken copy exits **non-zero** and prints a FAIL whose two sha
      prefixes are equal. Quote the FAIL lines and `rc=`.
- [x] `tests/shell-television.sh` is byte-identical to its committed state
      (`git diff --stat -- tests/shell-television.sh` empty), and the
      selftest's `assert_unchanged` line still PASSes.
- [x] `bash gates/nushell-module-staging.sh` (no flag) exits 0 with 0 FAIL,
      timing quoted. Analyst baseline: 40 PASS / 0 FAIL / 1.29s.
- [x] `gates/nushell-module-staging.sh:47-50` states the present zero-MISS
      state and cites `config.nu:565` for `help.nu`.
- [x] `bash gates/selftest.sh` FAIL count quoted before and after, and it is
      no higher after. Analyst baseline: 37 PASS / 1 FAIL, the FAIL being
      `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`.
- [x] `bash -n gates/nushell-module-staging.sh` is silent.
- [x] The R5 census is reported: one line per mutation site, the three-column
      verdict, the same-defect count, and the predicate used.

## Verify and Proof

```sh
bash -n gates/nushell-module-staging.sh
bash gates/nushell-module-staging.sh --selftest; echo "selftest rc=$?"
time bash gates/nushell-module-staging.sh; echo "live rc=$?"
git diff --stat -- tests/shell-television.sh
grep -n 'for m in .*copymode help; do' gates/nushell-module-staging.sh || echo "vacuous guard gone"
bash gates/selftest.sh 2>&1 | grep -cE '^FAIL'
```

The tripwire recipe above is the sixth check; run it last, in its own scratch
root, and quote its FAIL lines.
