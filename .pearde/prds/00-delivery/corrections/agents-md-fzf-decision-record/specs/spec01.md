---
complexity: 12
footprint:
  - AGENTS.md
---

# spec01 — Write the fzf decision into the working contract

`decisions/fzf` is `done` and the record it was to leave in `AGENTS.md` is
absent: the `## Scope decisions already made` section says nothing about fzf,
and the `help` section still teaches every agent that fzf is not installed.
This spec makes the two edits `decisions/fzf/specs/spec04.md` specified — R2 —
adapted to the tree the mi retirement left, and leaves `## Known gaps` alone
(R3). The exact replacement text below was applied to a scratch copy of
`AGENTS.md` at spec time and run against spec04's `verify:`; it clears all five
in-scope FAIL lines and leaves exactly the four the PRD names as spent.

## What to write

Two edits. Nothing else in `AGENTS.md` is touched — not `## Known gaps`, not
the `Live sources` paragraph (that is
[`agents-md-chezmoi-source`](../../agents-md-chezmoi-source/prd.md)'s, already
landed), not the rating system, the PRD-tree table, or the conventions list.

### 1. `## Scope decisions already made` — extend the two-finders bullet

The section carries the sibling fact already, so the fzf exception is folded
into that bullet rather than added as an eighth. Replace

```
  editor ([`03-editor/08`(../../../../../../prds/00-delivery/corrections/agents-md-fzf-decision-record/specs/prds/03-editor/08-telescope/prd.md)). They are not
  to be unified.
```

with

```
  editor ([`03-editor/08`(../../../../../../prds/00-delivery/corrections/agents-md-fzf-decision-record/specs/prds/03-editor/08-telescope/prd.md)). They are not
  to be unified. **fzf is a third picker and the one accepted exception** to
  "tv owns every picker screen": `zi`/`cdi` reach it through
  `zoxide query --interactive`, and owning that screen would mean owning
  zoxide's frecency ranking. Decided 2026-08-21 — see
  [`decisions/fzf`(../../../../../../prds/00-delivery/corrections/agents-md-fzf-decision-record/specs/prds/00-delivery/decisions/fzf/prd.md) and the invariant
  it amends, [`04-shell`(../../../../../../prds/00-delivery/corrections/agents-md-fzf-decision-record/specs/prds/04-shell/prd.md) I3.
```

Three traps, all of which cost a failing verify if ignored:

- **`zoxide query --interactive` must stay on one source line.** spec04's
  verify slices the section with `awk` and greps it line-wise with `-F`; a
  wrap between `query` and `--interactive` makes the assertion fail on text
  that reads correctly to a human.
- **The links are `prds/…`, not `.mi/prds/…`.** spec04 was written before the
  mi retirement and its draft names the old tree. The section's existing
  bullets are repo-root-relative against `prds/`; match them, or Tier A of
  `gates/tree-links.sh` gains two broken links.
- **Do not import the `--exclude $PWD` half of `04-shell` I3.** That clause is
  refuted on the record: `~/.zoxide.nu:40` puts `--exclude $env.PWD` on
  `__zoxide_z`, while `__zoxide_zi` at `:48` is a bare
  `zoxide query --interactive` — reproduced at spec time against
  `~/.zoxide.nu`, and recorded in `decisions/fzf`'s closing note. The frecency
  half stands alone and is the only half the bullet above claims.

### 2. The `help` section — stop asserting fzf is not installed

Replace

```
prevents the standard failure mode: reaching for `fzf` when television is what
is installed, `grep` when `rg` is, or `find` when `fd` is. If you add a
```

with

```
prevents the standard failure mode: reaching for `fzf` when television is the
picker this config drives, `grep` when `rg` is, or `find` when `fd` is. fzf is
installed — as `zi`'s dependency, not as a picker to reach for. If you add a
```

Two traps here:

- **The old-clause guard flattens newlines before matching**, so re-breaking
  the same words across different lines does not satisfy it. The words
  `television is what is installed` must be gone.
- **`` `grep` when `rg` is `` must remain on a single line** — that assertion
  is *not* flattened, and it is the guard R2 names as protecting the `rg`/`fd`
  half of the sentence.

The phrasing deliberately says `as \`zi\`'s dependency`, not *only* as its
dependency: `home/dot_config/capsule/Dockerfile:26` installs `fzf` inside the
capsule image too, so "only" would be an overclaim on a file every agent
reads. The normative half — never as a picker anything else reaches for —
matches `04-shell` I3 and P.2 R7.

## Acceptance

- [x] `## Scope decisions already made` still holds exactly seven `- **`
      bullets: the fact was folded into the two-finders bullet, not added as
      an eighth.
- [x] That section contains `fzf`, `2026-08-21`, `decisions/fzf` and
      `zoxide query --interactive`, the last one whole on a single line, and
      the bullet still opens `Two finders, deliberately`.
- [x] With newlines flattened, `AGENTS.md` no longer contains
      ``reaching for `fzf` when television is what is installed``, and
      ``` `grep` when `rg` is ``` still stands on one line.
- [x] `## Known gaps` is byte-identical to its pre-edit state — R3. Compare
      the extracted section against `git show HEAD:AGENTS.md`, or against a
      copy taken before the first edit.
- [x] `decisions/fzf/specs/spec04.md`'s `verify:` prints **none** of the five
      FAIL lines the PRD quotes, and every FAIL it does print is one of the
      four the PRD names as spent (`burrito fork was dropped`, `tinty fork was
      dropped`, `exactly 3 bullets`, `no longer symlinks`).
- [x] No sibling regression: `decisions/odin-toolchain/specs/spec02.md`'s
      `verify:` prints exactly its two pre-existing FAILs (`an unrelated
      Known-gaps bullet was disturbed`, `exactly 3 bullets after the
      removal`), and `decisions/tinty/specs/spec03.md`'s prints exactly its
      one (`a symlink at the repo root was replaced by a regular file`).
      Capture both before editing; the counts must not grow.
- [x] `bash gates/tree-links.sh` prints no `BROKEN AGENTS.md` line under
      `TIER A`, and the Tier A broken count is no higher after the edit than
      the baseline captured before it. Measured 2026-08-24 the baseline is
      **3**, all three in `corrections/capsule-r6-prefix-claim/prd.md` from a
      concurrent lane — see this spec's note below; assert the delta, not the
      absolute.
- [x] Every line this edit adds is at most 78 columns.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# 0. Baselines — capture BEFORE the edit, quote them in the report.
git show HEAD:AGENTS.md > /tmp/agents.before.md
bash gates/tree-links.sh 2>&1 | sed -n '/TIER A/,/TIER B/p' | grep -c '^BROKEN'

# 1. spec04's own verify — the five in-scope FAILs must be gone.
python3 - <<'PY' > /tmp/v.sh
import re, pathlib
t = pathlib.Path("prds/00-delivery/decisions/fzf/specs/spec04.md").read_text()
print(re.search(r'^verify: `(.*?)`\s*$', t, re.M | re.S).group(1))
PY
bash /tmp/v.sh; echo "exit=$?"
# expect exactly these four, and nothing else:
#   FAIL: the burrito fork was dropped from Known gaps
#   FAIL: the tinty fork was dropped from Known gaps
#   FAIL: Known gaps should still hold exactly 3 bullets
#   FAIL: AGENTS.md/CLAUDE.md are no longer symlinks

# 2. Sibling regression — same extraction, same expectation as the baseline.
for n in odin-toolchain/specs/spec02 tinty/specs/spec03; do
  python3 - "$n" <<'PY' > /tmp/s.sh
import re, pathlib, sys
t = pathlib.Path("prds/00-delivery/decisions/%s.md" % sys.argv[1]).read_text()
print(re.search(r'^verify: `(.*?)`\s*$', t, re.M | re.S).group(1))
PY
  echo "== $n"; bash /tmp/s.sh
done

# 3. Known gaps untouched, and the section/bullet shapes.
K() { awk '/^## Known gaps/{k=1;next} /^## /{k=0} k' "$1"; }
diff <(K /tmp/agents.before.md) <(K AGENTS.md) && echo "Known gaps: identical"
awk '/^## Scope decisions already made/{k=1;next} /^## /{k=0} k' AGENTS.md \
  | grep -c '^- \*\*'          # expect 7

# 4. Tree links and column width.
bash gates/tree-links.sh 2>&1 | sed -n '/TIER A/,/TIER B/p' | grep '^BROKEN'
diff /tmp/agents.before.md AGENTS.md | grep '^>' | cut -c3- \
  | awk 'length($0) > 78 { print "LONG " length($0) ": " $0 }'
```
