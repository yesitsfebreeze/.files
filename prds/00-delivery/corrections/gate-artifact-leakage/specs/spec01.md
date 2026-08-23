---
est: 1.5h
footprint:
  - gates/lib.sh
---

# spec01 — a scratch root that cannot be the repo root

`gates/lib.sh` hands every gate its scratch directory, and 41 scripts take it
(`grep -rl gates_tmpdir tests/*.sh gates/*.sh` → 41). Twenty-four of them then
write the same two lines:

```sh
SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
```

That second line is the leak. **Measured 2026-08-23, `bash -c 'cd ""; echo
"rc=$? pwd=$(pwd -P)"'` → `rc=0 pwd=/Users/feb/dev/dotfiles`**: in bash `cd ""`
succeeds and leaves you where you were, so an empty `$SCRATCH` resolves to
`$PWD` — and `gates/waves.tsv`'s header says gate commands run FROM THE REPO
ROOT. Every counterfactual the gate then writes to `"$SCRATCH/cf-…"` lands in
the repo root. That is how `listing-order-lookup-regression` leaked 7 files.

`set -u` does not catch it. Measured: with `gates_tmpdir` undefined the
substitution is a *command not found* (127), not an unset variable, and
`set -u` runs straight past it — `bash -c 'set -u; S="$(gates_tmpdir
2>/dev/null)"; S="$(cd "$S" && pwd -P)"; echo "$S"'` prints the repo root.
Only `set -e` aborts, and gates cannot use `set -e`: `chk_fail` exists
precisely to run commands that are *expected* to exit non-zero.

So the guard goes where every consumer already reaches: `gates_tmpdir` itself.

**And it has teeth on a reachable path, not a hypothetical one.** `GATES_TMP`
is settable from the environment via `GATES_KEEP_TMP`, which `selftest.sh`
sets per gate. Demonstrated in a scratch dir on 2026-08-23: a script sourcing
lib.sh, run with `GATES_KEEP_TMP=.`, resolved `SCRATCH` to its own cwd and
wrote `cf-demo.nu` there. Run from the repo root, that is the repo root.

## What to change

In `gates/lib.sh`, in the `GATES_TMP` block at the end of the file (the
`if [ -n "${GATES_KEEP_TMP:-}" ]` / `else mktemp -d` pair), after `GATES_TMP`
is set and before `gates_tmpdir` is defined:

1. Refuse an unusable scratch root, loudly, at source time. `lib.sh` is
   sourced at top level, so `exit 1` here stops the gate — that is the
   mechanism, not a side effect, and it must be commented as such.
   - empty
   - not a directory
   - resolves to `$REPO_ROOT`, or to any ancestor of `$REPO_ROOT`
2. Store the **physically resolved** path (`cd … && pwd -P`) in `GATES_TMP`,
   so the 24 hand-rolled re-resolutions in `tests/` become no-ops and cannot
   turn a good path into a bad one.

Shape (adapt to house style; the ancestor test is the load-bearing part):

```sh
_gates_scratch_fatal() {
  printf 'FATAL  gates/lib.sh: refusing a scratch root of [%s] — %s.\n' "$1" "$2" >&2
  printf 'FATAL  A gate whose scratch resolves into the repo writes its counterfactuals\n' >&2
  printf 'FATAL  into the repo. See prds/00-delivery/corrections/gate-artifact-leakage.\n' >&2
  exit 1
}
[ -n "${GATES_TMP:-}" ] || _gates_scratch_fatal "" "it is empty"
[ -d "$GATES_TMP" ]     || _gates_scratch_fatal "$GATES_TMP" "it is not a directory"
GATES_TMP="$(cd "$GATES_TMP" && pwd -P)" \
  || _gates_scratch_fatal "$GATES_TMP" "it does not resolve"
case "$REPO_ROOT/" in
  "$GATES_TMP"/*) _gates_scratch_fatal "$GATES_TMP" \
    "it is the repo root or an ancestor of it" ;;
esac
```

The `case` covers both directions that matter: `GATES_TMP` equal to
`$REPO_ROOT` (the `*` matches the empty tail) and `GATES_TMP` an ancestor such
as `/Users/feb/dev`. A scratch root *under* the repo is not matched and stays
legal — `scratch_tree` copies are not affected.

Do **not** touch anything under `tests/`. Those 24 files belong to other nodes
and are in flight; the whole point of putting the guard in `lib.sh` is that all
41 consumers inherit it with a one-file footprint.

Do **not** delete the three root artifacts here — spec03 owns that, after the
census records them.

## Acceptance

- [x] A scratch root equal to the repo root is refused: run from the repo
      root, `GATES_KEEP_TMP="$PWD" bash gates/probes.sh --selftest` exits
      non-zero and its stderr carries `FATAL` naming the path.
- [x] An **ancestor** of the repo root is refused too:
      `GATES_KEEP_TMP="$(dirname "$PWD")" bash gates/probes.sh --selftest`
      exits non-zero with the same `FATAL`.
- [x] **`/` — the ancestor that behaves differently — is refused too**, and it
      needs its own box because the box above cannot see it:
      `GATES_KEEP_TMP="/" bash gates/probes.sh --selftest` exits non-zero with
      `FATAL … refusing a scratch root of [/] — it is the repo root or an
      ancestor of it`. *(Added by the orchestrator's verification, 2026-08-23:
      the unstripped pattern `"$GATES_TMP"/*` expands to `//*` for `/`, which
      does not match a single-slash `"$REPO_ROOT/"`, so the guard fell through
      for exactly one ancestor. `${GATES_TMP%/}` closes it.)*
- [x] **And a scratch root UNDER the repo stays legal** — the property a
      careless fix breaks: `mkdir -p "$PWD/.gates-legal-probe"` then
      `GATES_KEEP_TMP="$PWD/.gates-legal-probe" bash gates/probes.sh
      --selftest` exits **0** with **0** `FATAL` lines and really writes there
      (3 entries under it), so `scratch_tree` copies are unaffected. Probe
      directory removed; the maxdepth-1 listing including directories is
      byte-identical before and after.
- [x] Neither refusal wrote anything: the root file listing
      (`find . -maxdepth 1 \( -type f -o -type l \) | sort`) is byte-identical
      before and after both commands, and the implementer quotes the diff as
      empty.
- [x] The guard is not blanket-red — a normal `bash gates/probes.sh
      --selftest` still exits 0.
- [x] `gates_tmpdir` returns a physically resolved path: from the repo root,
      `bash -c '. gates/lib.sh; T="$(gates_tmpdir)"; [ "$T" = "$(cd "$T" && pwd -P)" ]'`
      exits 0.
- [x] Every gate on the board still passes the meta-gate: `bash
      gates/selftest.sh` runs to completion and reports no new FAIL relative
      to the run recorded before the change (quote both summary lines).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
find . -maxdepth 1 \( -type f -o -type l \) | sort > /tmp/root-before.txt

GATES_KEEP_TMP="$PWD" bash gates/probes.sh --selftest; echo "rc=$?"
GATES_KEEP_TMP="$(dirname "$PWD")" bash gates/probes.sh --selftest; echo "rc=$?"
bash gates/probes.sh --selftest > /dev/null; echo "clean rc=$?"

find . -maxdepth 1 \( -type f -o -type l \) | sort > /tmp/root-after.txt
diff /tmp/root-before.txt /tmp/root-after.txt && echo "no leak"

bash -c '. gates/lib.sh; T="$(gates_tmpdir)"; [ "$T" = "$(cd "$T" && pwd -P)" ]' \
  && echo "resolved"

bash gates/selftest.sh; echo "selftest rc=$?"
```
