---
est: 1.75h
footprint:
  - prds/00-delivery/corrections/mi-lowercase-verify-sections/prd.md
  - prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/
executor: implementer
---

# spec04 — the four-place census, committed as a script that can see all four

R3 and R4. The two survivors were not a slip: they are a **census dimension**.
`mi-rooted-verify-commands` swept `^verify:` over `*.md` case-sensitively and
`-name 'check*.sh' -o -name '*.py'` over scripts, and both selectors are shaped
like the pattern already known. This spec commits a sweep that is not, records
its counts in the node body, and gives the node a standing proof.

Run **after** [spec01](spec01.md), [spec02](spec02.md) and [spec03](spec03.md):
its assertion is that the carrier count is zero, so it is red until they land.

## The script

`prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py`,
run from the repo root. For every `prds/**/*.md` it classifies each recording
place and reports totals plus `.mi/`-rooted carriers:

1. **place 1** — a `verify:` key in a `prd.md` frontmatter block
2. **place 2** — a `verify:` key in any other `.md` frontmatter block (a spec)
3. **place 3** — a fenced section under a heading matching `^#{1,6} +Verify`
4. **place 4** — the same heading with a **lowercase** `v`

and separately, because it is the hole R4 turns on:

5. **scripts** — every `*.sh` and `*.py` under `prds/**`, not only the ones
   named `check*.sh`

Places 3 and 4 must be one case-insensitive regex split on the matched byte,
never two greps — writing them as two greps is how the fourth place was missed
in the first place. Section bodies run to the next heading of the same or higher
level. A carrier is a place whose value or section body contains the substring
`.mi/`.

The reference implementation, which produced the counts below and is what the
implementer should commit (add a shebang, `--check` handling and a docstring):

```python
import re, pathlib
root = pathlib.Path(".")
for f in sorted(root.glob("prds/**/*.md")):
    t = f.read_text(encoding="utf-8")
    fm = ""
    if t.startswith("---\n"):
        end = t.find("\n---", 4)
        if end > 0: fm = t[4:end+1]
    for m in re.finditer(r"(?im)^\s*verify:[ \t]*(.*)$", fm):
        place = 1 if f.name == "prd.md" else 2          # places 1 and 2
        ...
    for m in re.finditer(r"(?m)^(#{1,6})[ \t]+([Vv]erify[^\n]*)$", t):
        lvl = len(m.group(1)); rest = t[m.end():]
        nxt = re.search(r"(?m)^#{1,%d}[ \t]" % lvl, rest)
        body = rest[:nxt.start()] if nxt else rest
        place = 3 if m.group(2)[0] == "V" else 4        # places 3 and 4
        ...
```

Give it a `--check` mode that exits non-zero when any place has a carrier, and
prints one line per carrier. That is the node's `verify:`.

## The counts, measured 2026-08-23 before spec01–03

| place | what | total | `.mi/`-rooted carriers |
|---|---|---:|---:|
| 1 | `prd.md` frontmatter `verify:` | 145 | **0** |
| 2 | spec frontmatter `verify:` | 34 | **0** |
| 3 | fenced `## Verify` (upper `V`) | 154 | **2** — both false positives, below |
| 4 | fenced `## verify` (lower `v`) | 12 | **8** |
| — | `*.sh` / `*.py` under `prds/**` | 23 | **6** |

**Only the carrier column is assertable.** The totals move under other lanes:
place 1 went 144 → 145 while this node was being specced (a sibling added a
node), and place 3 went 150 → 154 the moment this node's own four specs landed
on disk, each carrying a `## Verify and Proof` heading. Reproduce them as a
*reading*, quote them with the run's timestamp, and assert only that no place
holds a real carrier. A box pinned to a total is the spent one-shot guard this
whole family of nodes exists to stop making.

**The fourth place turned up more than the two known carriers, and the extra is
not a carrier of the rot.** Place 4 holds 12 blocks in **three** directories,
not two: `w0-4-s2-corrections/shell/specs/spec01–03` (3),
`w0-4-s2-corrections/help/specs/spec01–05` (5), and — invisible to the parent
census and to this node's own PRD —
`05-platform/03-shell-init-generation/specs/spec01–04` (4). Those four name no
`.mi/` path, their target files exist, and two were run green on 2026-08-23
(`bash -c '…run_after_generate-shell-init.sh…'` exit 0; `bash
tests/shell-init.sh --gen` exit 0); the third's command is byte-equal to that
node's `prd.md` frontmatter `verify:`, so its proof is recorded in place 1 as
well. They are carriers of the **invisibility**, not of the rot — record them
that way, and record that the sweep found them, because "the fourth place holds
only the two we already knew" is a claim this node was written to distrust.

**Both of place 3's carriers are false positives, and the second one is this
node's.** The first is `mi-rooted-verify-commands/specs/spec01.md`'s own
`## Verify and Proof` block, whose `.mi/` tokens are the *patterns it asserts the
absence of* (`! grep -rq --include='*.md' '^[[:space:]]*verify:.*\.mi/' prds`).
The second appeared when [spec02](spec02.md) was written, for the same reason:
its proof greps for `.mi/` to assert none is left. Place 3's real carrier count
is 0. A census that cannot tell a path from a pattern over-reports — and a
census whose own text trips it is the cheapest possible demonstration that the
rule is needed. State the rule in the script (a token inside a `grep`/`!
grep`/`--include` argument is a pattern, not a path) rather than allowlisting
either file by name.

**The scripts' 6 split three ways** — and only one is a defect this node fixes:
`shell/verify.sh` (spec01's, the `.mi`-marker derivation);
`editor/specs/verify-all.sh` (a stale `.mi/prds/…` **usage comment** only — its
runtime derivation is `git rev-parse --show-toplevel` and is correct);
`delivery/checks/{arith,tables,tree}.py` (the three `.mi/gantt/plan.json`
readers `mi-rooted-verify-commands` spec02 deliberately left, whose nodes already
carry `verify: ""`); and `git-diff-integrity-boxes/checks/gitdiff-boxes.py`
(in flight — **do not touch**).

## R4 — the parent node's closing evidence

Record this in the node body. `mi-rooted-verify-commands` is `done`; **do not
reopen it.** Measured 2026-08-23 by extracting its spec01 `## Verify and Proof`
block and running it verbatim: **exit 1, four PASS and two FAIL** — the two
being the `.mi/`-token box on `stale-framework-links/specs/spec01.md` and
`missing=4` on the path-existence sweep. Both are boxes that node left `[ ]`
with stated reasons, so the sweep is *already* not green and honestly recorded
as such. **Nothing in this node makes it redder**, and after spec01 lands its
`missing=` count is unchanged (all four missing paths are forward-looking test
files and one tokenizer artifact, none of them ours).

The finding is the box that **passes and should not**:

```
! grep -rqE '\.mi/(prds|docs|SYSTEM\.md)' $(find prds -name 'check*.sh' -o -name '*.py')
p "no invoked script names a resolvable .mi/ path" $?
```

It reports **PASS today** while two invoked scripts carry `.mi/prds/…`. The
selector is the hole: `-name 'check*.sh' -o -name '*.py'` picks 20 of the 23
scripts under `prds/**` and misses `shell/verify.sh`, `editor/specs/verify-all.sh`
and `backlog-closeout/specs/lib.sh` — the last of which that node's implementer
found anyway, by chasing FAIL counts, which its own report records as *"the
implementer found a script the spec did not name."* Widen the same regex to
`-name '*.sh' -o -name '*.py'` and it fails on exactly two lines:

```
editor/specs/verify-all.sh:8:# Usage: bash .mi/prds/…/editor/specs/verify-all.sh
shell/verify.sh:4:# Usage:  bash .mi/prds/…/shell/verify.sh [spec01|spec02|spec03|all]
```

**What that box should have asserted:** every `*.sh` and `*.py` under `prds/**`
— or better, every script path a `verify:` value or a fenced verify block
actually *invokes*, resolved out of the command text rather than guessed from a
filename convention. A naming convention is a proxy for the set you care about,
and a proxy that excludes `verify.sh` from the verify-script census is not a
near miss, it is the wrong set.

**And its `.mi/`-token box should have enumerated, not named.** That node's own
R5 answer already listed "it cannot see the fenced form" as a limitation, yet
spec01 asserted the fenced dimension as a **single named file** — the one
carrier it happened to find by hand. Case-insensitive enumeration
(`grep -rniE '^#{1,6} +verify' prds`, 162 hits, 12 of them lowercase) would have
put all 12 lowercase blocks on the table that day and made this node
unnecessary. That is the R4 verdict: not a slip, a selector.

## Acceptance

- [ ] `checks/verify-census.py` exists, runs from the repo root, and prints all
      five places with a total and a carrier count each. Quote the totals with
      the run's timestamp; do **not** assert them — see the note under the
      table.
- [ ] `python3 checks/verify-census.py --check` exits **0** after spec01–03
      land, and its carrier count for **every** place is 0 — with place 3's two
      pattern-not-path false positives excluded by a rule the script states, not
      by either file being named in an allowlist.
- [ ] Place 2's total is **34** and its carriers **0** both before and after.
      This is the one total a lane cannot move without a new spec `verify:` key,
      so it is the cheap regression check that the sweep still parses
      frontmatter at all.
- [ ] The script fails when it should: run it against a scratch copy of `prds/`
      with `.mi/prds/x` planted inside a lowercase `## verify` fence and confirm
      `--check` exits non-zero naming that file. A census that cannot be made to
      fail has not been tested.
- [ ] Places 3 and 4 come from one case-insensitive match split on the matched
      byte. `grep -c "Verify" checks/verify-census.py` shows no second,
      separate uppercase-only pattern.
- [ ] The script covers `*.sh` and `*.py` under `prds/**` — assert it selects
      **23** files, and that `shell/verify.sh`, `editor/specs/verify-all.sh` and
      `backlog-closeout/specs/lib.sh` are among them. This is the exact set the
      parent's selector missed.
- [ ] The node body records: the five-row census table, the three-directory
      breakdown of place 4 with the platform four called out as
      invisible-but-green, place 3's false positive, the scripts' three-way
      split, and the R4 verdict including the quoted passing-but-hollow box.
- [ ] The node body records that **zero** of the 13 repaired proof commands use
      `git diff` as an instrument. Measured 2026-08-23: `help/spec04` and
      `help/spec05` are the only two whose verify sections contain the string,
      and both only to *reject* it in favour of a `shasum` content pin.
- [ ] `mi-rooted-verify-commands/` is byte-unchanged. Prove by content, not
      `git diff` (99 files in this repo are tracked; most of `prds/` is not, so
      a diff box there passes by observing nothing):
      `find prds/00-delivery/corrections/mi-rooted-verify-commands -type f | sort | xargs shasum -a 256`
      before and after, `diff -q` on the two listings.
- [ ] `bash gates/tree-links.sh` Tier A: **0 broken**, asserted as such.
      Baseline 2026-08-23 before this node: `checked 941 links in 152 files, 0
      broken`; Tier B's 118 broken are pre-existing and not gating.

## Out of scope

- Registering the census in `gates/waves.tsv`. `mi-rooted-verify-commands`' R5
  answer was **advisory, not gating**, and its fifth reason still holds:
  existence is not truth. It is a node-local check.
- `gates/lib.sh`, `gates/selftest.sh`, `gates/waves.tsv`, `gates/manual/*`.
- `git-diff-integrity-boxes/checks/gitdiff-boxes.py` and
  `03-editor/12-small-plugins` — in flight.
- Fixing `editor/specs/verify-all.sh`'s stale usage comment. It is the same
  class and a one-line fix, but that file is another node's and its runtime
  derivation is correct, so it is reported, not edited.
- Reopening `mi-rooted-verify-commands`, or editing any `prd.md` frontmatter.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
C=prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py
B=prds/00-delivery/corrections/mi-lowercase-verify-sections/prd.md

python3 "$C" > /tmp/cen.txt 2>&1; p "the census runs" $?
[ "$(grep -c '^place\|^(depth-1)\|^scripts' /tmp/cen.txt)" = 5 ]
p "all five places are reported" $?
grep -qE '^place 2 .* 34 ' /tmp/cen.txt
p "place 2's total is 34 (the one total no lane can move)" $?

python3 "$C" --check; p "--check exits 0: no place holds a carrier" $?

# it must be falsifiable
T=$(mktemp -d); cp -R prds "$T/prds"
printf '\n## verify\n\n```\ncat .mi/prds/x\n```\n' >> "$T/prds/README.md"
( cd "$T" && python3 "$C" --check ) >/dev/null 2>&1
[ $? -ne 0 ]; p "--check goes red on a planted lowercase carrier" $?
rm -rf "$T"

grep -q "'\*\.sh'" "$C" || grep -q '"\*\.sh"' "$C"
p "the script census is not limited to check*.sh" $?

for k in 'verify-census' 'invisible' 'false positive' 'git diff' 'selector'; do
  grep -qi "$k" "$B" || { echo "  missing from the body: $k"; rc=1; }
done
p "the body records the census, the R4 verdict and the git-diff measurement" $?

find prds/00-delivery/corrections/mi-rooted-verify-commands -type f | sort \
  | xargs shasum -a 256 > /tmp/parent.after
diff -q /tmp/parent.before /tmp/parent.after
p "mi-rooted-verify-commands is byte-unchanged" $?

bash gates/tree-links.sh 2>&1 | head -5 | grep -q '0 broken'
p "tree-links Tier A: 0 broken" $?
exit $rc
```

Take `/tmp/parent.before` with the same `find | xargs shasum` command **before**
the first edit of this node; there is no `git diff` fallback, because that tree
is untracked.
