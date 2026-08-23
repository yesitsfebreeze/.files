---
est: 1.5h
footprint:
  - prds/00-delivery/decisions/fzf/specs/
  - prds/00-delivery/decisions/odin-toolchain/specs/
  - prds/00-delivery/decisions/tinty/specs/
  - prds/00-delivery/decisions/wallpaper-opacity/specs/
  - prds/00-delivery/corrections/stale-framework-links/specs/
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/delivery/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/
executor: implementer
---

# spec02 — dispose of the 37 that a repoint cannot make true again

spec01 repoints and measures. This spec decides what the measurement means,
one carrier at a time. It is the spec where R2's rule bites: **do not invent
a plausible command**, and — the mirror of it, which the measurement makes
urgent — **do not blank a command that is correctly reporting a failure.**

The measurement says a mechanical repoint restores *executability* to all 62
and *truth* to only 24. The other 37 fall into three kinds, and each kind
gets a different disposition. Deciding which kind a carrier is, is the work;
the edits are minutes.

Depends on spec01 landing first: the exit codes it records are this spec's
input.

## Why a red verify is not automatically a bug to be blanked

The board's `verify:` field is carrying two different jobs, and the `.mi/`
rot hid the difference. Some values are **standing proofs** — run them
tomorrow and they still say something true about the node. Others are
**one-shot delta guards** written the day the node ran: "no acceptance box
in `03-editor/01-options` was closed", "`docs/capabilities-nvim.md` is
byte-unchanged", "the build order holds exactly 3 Known-gaps bullets". Those
were true when they ran and are false now *because later nodes legitimately
did the work they were guarding against*. A guard like that is spent. It
cannot be re-run and its red says nothing about the node it sits on.

Blanking a spent guard is honest. Blanking a standing proof that has gone
red because the node's own work is unfinished is a cover-up — the exact
failure this correction family exists to stop.

## The triage rule

For each of the 37, read the FAIL lines spec01 recorded and apply this test:

> Does the failing assertion name a file **this node owns and edited**, and
> restate a requirement from **this node's own** Requirements?

- **Yes → keep the repointed command.** It is a true, loud red about
  unfinished work. Leave `verify:` as spec01 left it, and file one
  correction node per affected node in
  [the backlog](../../prd.md), naming the failing assertion verbatim.
  Fixing the underlying work is out of scope here.
- **No → it is a spent one-shot guard.** Set the spec's `verify:` to `""`,
  and move the repointed command into a `## Spent proof` section in the same
  spec file, with one line saying when it was green and what made it stale.
  The command is not deleted — deleting it would destroy the execution
  record `stale-mi-paths` rightly protects. It just stops occupying a field
  whose contract is "the command that proves this node".

The reason line is one sentence and it must name the cause, not the symptom.
"Stale" is not a reason. "The `84 entries` count this pinned is 92 today,
because `06-help` kept adding manual entries after this node closed" is.

## The three kinds, with the evidence measured 2026-08-23

**Kind 1 — spent one-shot delta guards (15).** Every FAIL is of the form "a
box was closed in <another node>", "an inventory was modified", "a symlink
at the repo root was replaced", "requirement count is not 7", "an unrelated
Known-gaps bullet was disturbed". None names this node's own contract.

`decisions/odin-toolchain` spec01, spec02 · `decisions/tinty` spec02,
spec03, spec04, spec05 · `decisions/fzf` spec01, spec02 ·
`decisions/wallpaper-opacity` spec02 · `w0-4-s2-corrections/capsule`
spec01, spec02, spec03 · `w0-4-s2-corrections/editor` spec01, spec02,
spec04.

**Kind 2 — pinned content the board has legitimately moved past (13).** A
count, a line number, a byte digest or a "phrase X is gone everywhere"
sweep, all fixed at close time. Apply the triage rule per file; the analyst
expects most to land in Kind 1's disposition, but four are the ones to read
hardest because their FAIL text reads like unfinished work rather than
drift, and if it is, they are Kind 3:

- `w0-4-s2-corrections/editor` spec06 — "3 line(s) still prescribe
  nohlsearch without recording the non-port"
- `w0-4-s2-corrections/editor` spec08 — "4 line(s) in 03-editor reference
  C-q other than as deliberately unbound"
- `w0-4-s2-corrections/platform` spec01 — "R1: 'burrito' still appears in
  the managed-surface list"
- `w0-4-s2-corrections/platform` spec04 — "R2: 'burrito' still appears in
  the required set"

The rest of Kind 2: `w0-2-terminal-respec` spec01 ("burrito survives in
`prds/02-terminal/04-copy-mode/…`"), spec05, spec09 ("file is 577 lines,
want 550"; "line 220 is no longer `## Appearance baseline`") ·
`w0-4-s2-corrections/backlog-closeout` spec01–05 (17, 33, 62, 86 and 23
FAILs — the backlog's finding tables were restructured after these closed)
· `w0-4-s2-corrections/docs-inventories` spec04 ·
`w0-4-s2-corrections/platform` spec07 ("the run_once_before stage was
deleted by 8fe3a71") · `w0-4-s2-corrections/provisioning-rerate` spec02
("broken relative link -> `../prd/`").

Plus the fenced-block carrier spec01 repointed:
`corrections/stale-framework-links/specs/spec01.md`, whose `## Verify` block
pins "R3: node gate exit 0, **84 entries**". `nu tests/help-content-model.nu`
prints **92 entries** today and exits 0. Three of its four assertions pass;
only the pinned count fails. This is Kind 2 and its reason line writes
itself — but note the file has no `verify:` key, so the disposition is a
`## Spent proof` note beside the block, not a frontmatter edit.

**Kind 3 — unrepointable: the proof read a file with no successor (4).**
`w0-4-s2-corrections/delivery` spec02, spec03, spec05 and spec06 invoke
`checks/tables.py`, `arith.py` and `tree.py`, all three of which
`json.load()` **`.mi/gantt/plan.json`** — the schedule of record the mi
retirement deleted. Measured: `FileNotFoundError` even after the rest of the
script is repointed. There is no rewrite: the data moved into PRD
frontmatter in a different shape, so a working replacement would be a *new*
proof, and writing one is out of scope for this node and forbidden by R2.

These four get `verify: ""` and a reason naming `plan.json` explicitly.
`spec06` is the one to be careful with: it runs `wrap.py` (which is
repointable and exits 0) **and** `tree.py` (which is not), so its reason
must say that half of its proof survives and lives on in `wrap.py`.

Leave the three scripts on disk and untouched. They are the record of a
check that once ran; they are simply no longer runnable.

## Out of scope

- Writing any replacement proof, for any of the 37. A new command is a new
  claim, and this node fixes pointers.
- Fixing the work behind any red this spec decides to keep. That is a fresh
  correction node per affected node, filed and left.
- `prd.md` frontmatter. Every carrier here is a spec file or a fenced block;
  the five `prd.md` frontmatter cases are spec03's, and the orchestrator's.

## Acceptance

- [ ] Every one of the 37 carriers is disposed of: either `verify:` still
      holds spec01's repointed command **and** a correction node exists
      naming its failing assertion, or `verify:` is `""` **and** the same
      file carries a `## Spent proof` section holding the repointed command
      plus a one-sentence cause. No carrier is left in a third state.
- [ ] No carrier holds a command this node wrote. Prove it: every command
      appearing under a `## Spent proof` heading is byte-identical to what
      spec01 left in that file's `verify:` (`git log -p` on the two commits
      shows a move, not an edit).
- [ ] Every `verify: ""` in the 37 is accompanied by a reason line that
      names a cause — a file, a count, a commit or `plan.json`. A reason
      containing only "stale", "outdated" or "no longer applies" fails this
      box.
- [ ] The four Kind 3 carriers name `.mi/gantt/plan.json` in their reason,
      and `checks/tables.py`, `arith.py`, `tree.py` are byte-unchanged from
      spec01's state.
- [ ] Every carrier that kept a command exits non-zero, and the failing
      assertion quoted in its correction node matches the FAIL line the
      command actually prints. A correction node citing an assertion the
      command does not print is a fabricated finding.
- [ ] `bash gates/tree-links.sh` Tier A is 0 broken, and any new correction
      node's links resolve — a filed node with a broken parent link is worse
      than no node.
- [ ] No `prd.md` outside the newly created correction nodes was written:
      `find prds -name prd.md -newer <the run's start marker>` lists only
      those nodes, quoted. `git diff --name-only` cannot carry it — 7 of the
      144 `prd.md` files are tracked (`git ls-files --error-unmatch`, 2026-08-23), so it is blind to
      137 of them and would report clean after touching any of those.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: the
      mtime listing above, taken against a marker file created before the
      first write.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

# the 37 are listed here by the implementer, one path per line, from spec01's
# measurement — not re-derived, so the two specs cannot disagree silently
L=$(cat <<'EOF'
EOF
)
[ "$(printf '%s\n' "$L" | grep -c .)" = 37 ]
p "the disposition list holds exactly 37 carriers" $?

bad=""
for f in $L; do
  v=$(sed -n 's/^verify:[[:space:]]*//p' "$f" | head -1)
  if [ "$v" = '""' ]; then
    grep -q '^## Spent proof' "$f" || bad="$bad $f(no-spent-proof)"
  else
    grep -q '^## Spent proof' "$f" && bad="$bad $f(both)"
  fi
done
[ -z "$bad" ]; p "every carrier is in exactly one state ($bad)" $?

# no reason line hides behind a filler word
! grep -rn -A2 '^## Spent proof' $L \
  | grep -iqE '\b(stale|outdated|no longer applies)\b[.,]?$'
p "no reason line is filler" $?

for f in prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/tables.py \
         prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/arith.py \
         prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/tree.py; do
  grep -q '\.mi/gantt/plan\.json' "$f" || { echo "FAIL  $f was rewritten"; rc=1; }
done
p "the three plan.json readers are untouched" 0

bash gates/tree-links.sh > /tmp/tl2.txt 2>&1
grep -q '0 broken' /tmp/tl2.txt; p "tree-links Tier A: 0 broken" $?

git diff --name-only | grep '/prd\.md$' | grep -v 'corrections/' \
  && { echo "FAIL  a prd.md outside corrections/ was edited"; rc=1; }

exit $rc
```
