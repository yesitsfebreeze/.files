---
est: 1.75h
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh
  - prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec01.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec02.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec03.md
executor: implementer
---

# spec01 — `w0-4-s2-corrections/shell`: repair the repo *derivation*, not the paths

`w0-4-s2-corrections/shell` is `done` and its gate,
[`verify.sh`](../../w0-4-s2-corrections/shell/verify.sh), exits 1 on every
argument with **42/42 FAIL, all `FileNotFoundError`**. Measured 2026-08-23 from
the repo root:

```
0/42 passed  (42 FAILED)
      ↳ FileNotFoundError: [Errno 2] No such file or directory: '/.mi/prds/04-shell/prd.md'
```

**The bug is the derivation, not the token.** The embedded python walks up from
`$PWD` looking for a `.mi` directory:

```python
here = pathlib.Path.cwd()
while not (here / ".mi").is_dir() and here != here.parent:
    here = here.parent
REPO = here
PRD = REPO / ".mi" / "prds" / "04-shell"
```

`.mi` was deleted by the mi retirement, so the loop runs to the filesystem root
and `REPO` becomes `/`. Rewriting `.mi/prds` → `prds` inside that expression
leaves it reading `/prds/04-shell/…` — still broken. This is the same shape
[`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md) hit in
`w0-4-s2-corrections/backlog-closeout/specs/lib.sh`, where a pure token rewrite
left every check reading `/Users/feb/dev/prds/…`. **Reuse that node's fix; do
not invent a second approach.** What it did there, verbatim:

```sh
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
```

— the root derived from the *script's own location*, not from a marker that no
longer exists. `verify.sh` sits one level shallower than `lib.sh`
(`…/w0-4-s2-corrections/shell/verify.sh`, not `…/backlog-closeout/specs/lib.sh`),
so the same expression takes **five** `..`, and the value has to reach the
heredoc, because `__file__` is `-` under `python3 -`.

## The change, in four places

1. **`verify.sh`, the derivation.** Compute `REPO` in bash from
   `${BASH_SOURCE[0]}` — five levels up — `export REPO`, and in the heredoc
   replace the whole cwd-walk with `REPO = pathlib.Path(os.environ["REPO"])`
   (adding `os` to the import line) and `PRD = REPO / "prds" / "04-shell"`.
   Keep a comment saying *why* the walk was replaced: the marker it looked for
   was deleted, so the walk resolved to `/`.
2. **`verify.sh` line 4, the usage comment** —
   `bash .mi/prds/…/shell/verify.sh` → `bash prds/…/shell/verify.sh`. It is
   prose, but it is prose telling the next reader to run a path that does not
   exist, and it is one of the two lines that make
   [spec04](spec04.md)'s script census red.
3. **`specs/spec01.md:161`, `specs/spec02.md:142`, `specs/spec03.md:117`** —
   the invoked command inside each `## verify` fence,
   `bash .mi/prds/…/shell/verify.sh specNN` → `bash prds/…/shell/verify.sh
   specNN`. **Only that line.** The `.mi/prds/04-shell/…` lines in each spec's
   "files this spec touches" list stay: they are execution record, the
   keep-list `stale-mi-paths` spec01 protects, and re-litigating it is
   [`stale-mi-keeplist-ruling`](../../stale-mi-keeplist-ruling/prd.md)'s, not
   this node's.
4. **Nothing else.** No check in `SPECS` is added, removed, reworded or
   renumbered. The 42 assertions are the `done` node's own contract.

## The one red that survives the fix, and why it is not blanked

Measured 2026-08-23 against a scratch copy of `prds/` with the derivation
fixed: **41/42 pass**, `spec02` and `spec03` exit **0**, and `spec01` exits 1
on exactly one assertion:

```
FAIL  TV-8  04-television/prd.md: S3: `opacity` appears only alongside the decision that settled it
      ↳ an occurrence of `opacity` at char 10464 has no `wallpaper-opacity` within 350 chars
```

That occurrence is `prds/04-shell/04-television/prd.md:199`, inside
`### Added 2026-08-23 by the orchestrator — a vacuous assertion in this gate`
— a section written **two days after this node closed**, whose sentence reads
*"It is the same defect class as the `T.4` `opacity` box…"*. It is a citation
of a box named `opacity`, not an opacity feature. The requirement TV-8 guards
(no opacity picker is specced here) still holds; the guard's subject — the
token anywhere in the file — is wider than what it means to check.

This is the shape `mi-rooted-verify-commands` classified four times over
(`editor/spec06`, `editor/spec08`, `platform/spec01`, `platform/spec04`):
*"In every case the guard is matching the record of the work it was checking
for."* So:

- **Do not narrow TV-8's predicate.** Tightening a guard so a node goes green
  is the manufactured proof R2 forbids, and the over-breadth is already on the
  record at the line that causes it.
- **Do not delete or reword TV-8.**
- Add a `## Spent assertion` section to `specs/spec01.md` naming the cause with
  its file, line and section heading, and stating that the other 12 checks in
  `spec01` pass. One sentence naming a cause — "stale" is not a cause.

## Acceptance

- [ ] `bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec02`
      exits **0** and prints `14/14 passed`.
- [ ] `bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec03`
      exits **0** and prints `15/15 passed`.
- [ ] `bash …/verify.sh all` prints `41/42 passed  (1 FAILED)` and **zero**
      `FileNotFoundError` lines. A count other than 41 is a finding to report,
      not a number to adjust.
- [ ] The gate works from a directory that is not the repo root — run it as
      `cd /tmp && bash /Users/feb/dev/dotfiles/prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec02`
      and it still exits 0. This is the box the old cwd-walk could never pass.
- [ ] The only FAIL is `TV-8`, and `specs/spec01.md` carries a
      `## Spent assertion` section naming
      `prds/04-shell/04-television/prd.md:199` and its section heading as the
      cause.
- [ ] The 42 assertions are unchanged. Prove by content, not by `git diff`
      (most of `prds/` and all of `home/` is untracked — a diff box over them
      passes by observing nothing): before editing, `cp verify.sh /tmp/v.orig`;
      after, `diff <(sed -n '/^# ── checks/,$p' /tmp/v.orig) <(sed -n '/^# ── checks/,$p' verify.sh)`
      prints nothing.
- [ ] `grep -c '\.mi/' prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh`
      is **0**, and each of `specs/spec01.md`, `spec02.md`, `spec03.md` has no
      `.mi/` token on the command line inside its `## verify` fence
      (`awk '/^## verify/,/^$/'` over each shows none).
- [ ] `bash gates/tree-links.sh` Tier A: **0 broken**, asserted as such.
      Baseline 2026-08-23 before this node: `checked 941 links in 152 files, 0
      broken`. Tier B's 118 broken are pre-existing and not gating.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
V=prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh

bash "$V" spec02 >/tmp/s2.txt 2>&1; p "spec02 exits 0" $?
grep -q '14/14 passed' /tmp/s2.txt; p "spec02: 14/14" $?
bash "$V" spec03 >/tmp/s3.txt 2>&1; p "spec03 exits 0" $?
grep -q '15/15 passed' /tmp/s3.txt; p "spec03: 15/15" $?

bash "$V" all >/tmp/sa.txt 2>&1
grep -q '41/42 passed' /tmp/sa.txt; p "all: 41/42 passed" $?
! grep -q FileNotFoundError /tmp/sa.txt; p "no FileNotFoundError remains" $?
[ "$(grep -c '^FAIL' /tmp/sa.txt)" = 1 ]; p "exactly one FAIL" $?
grep -q '^FAIL  TV-8' /tmp/sa.txt; p "the one FAIL is TV-8" $?

# the derivation, not the token: the gate must work from anywhere
( cd /tmp && bash "$(git -C "$OLDPWD" rev-parse --show-toplevel)/$V" spec02 ) >/dev/null 2>&1
p "gate exits 0 from a foreign cwd" $?

! grep -q '\.mi/' "$V"; p "no .mi/ token left in verify.sh" $?
for n in 01 02 03; do
  awk '/^## verify/{f=1} f&&/^```$/{n++} f&&n==1&&/^bash /{print}' \
    "prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec$n.md" \
    | grep -q '\.mi/' && rc=1
done
p "no spec's invoked command names a .mi/ path" $?

grep -q '^## Spent assertion' \
  prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec01.md
p "TV-8's spent-assertion record exists" $?

bash gates/tree-links.sh 2>&1 | head -5 | grep -q '0 broken'
p "tree-links Tier A: 0 broken" $?
exit $rc
```
