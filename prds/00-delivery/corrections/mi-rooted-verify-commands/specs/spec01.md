---
est: 1.5h
footprint:
  - prds/00-delivery/decisions/fzf/specs/
  - prds/00-delivery/decisions/odin-toolchain/specs/
  - prds/00-delivery/decisions/shift-select-scope/specs/
  - prds/00-delivery/decisions/tinty/specs/
  - prds/00-delivery/decisions/wallpaper-opacity/specs/
  - prds/00-delivery/corrections/gate-home-isolation/specs/
  - prds/00-delivery/corrections/stale-framework-links/specs/
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/
  - prds/00-delivery/corrections/w0-3-platform-rewrite/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/delivery/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/
  - prds/00-delivery/corrections/w0-4-s2-corrections/docs-inventories/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/
  - prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/
executor: implementer
---

# spec01 — repoint every strip-resolvable `.mi/` path, then measure all 62

Rewrite the dead `.mi/` prefix out of the 62 board `verify:` carriers and out
of the 16 check scripts those commands invoke, using one rewrite map whose
every target is asserted to exist on disk first. Then **run all 62 and record
the exit code of each**. This spec repoints and measures; it disposes of
nothing. What the measurement leaves red or dead is spec02's contract.

The rewrite invents nothing: it is the same map
[`stale-mi-paths`](../../stale-mi-paths/specs/spec01-mi-path-sweep.md)
already proved for the help corpus (`.mi/prds/` → `prds/`, `.mi/docs/` →
`docs/`, `.mi/SYSTEM.md` → `AGENTS.md`), and the analyst confirmed that
**every** `.mi/`-rooted token in a board `verify:` resolves through it to a
path that exists — zero exceptions, measured 2026-08-23. The one prefix with
no successor, `.mi/gantt/`, appears in no `verify:` value at all; it appears
only *inside* three check scripts, and those are spec02's.

## The rewrite map, and nothing else

```
.mi/prds/  -> prds/
.mi/docs/  -> docs/
.mi/prds   -> prds        (bare, no trailing slash)
.mi/docs   -> docs        (bare, no trailing slash)
.mi/SYSTEM.md -> AGENTS.md
.mi/gantt/ -> LEAVE ALONE — no successor file; spec02 disposes of it
```

Apply it to two file classes and no others:

1. **The `verify:` value** in the 61 spec files listed below, plus the one
   fenced `## Verify` block in
   `prds/00-delivery/corrections/stale-framework-links/specs/spec01.md`
   (`F=.mi/prds/06-help/01-content-model/prd.md` → `F=prds/…`). That file
   carries **no** `verify:` key, which is why a grep for `^verify:` alone
   misses it — do not let the same one-dimensional sweep happen twice.
2. **The 16 scripts a `verify:` invokes**, because repointing the command
   without repointing the script it runs leaves the command failing for the
   same reason one level down. Measured: six spec verifies stay red purely
   because of this.

   `w0-4-s2-corrections/backlog-closeout/specs/check01.sh`, `check02.sh`;
   `…/delivery/checks/arith.py`, `tables.py`, `tree.py`, `wrap.py`;
   `…/platform/specs/check01.sh` … `check07.sh`;
   `…/provisioning-rerate/specs/check01.sh` … `check03.sh`.

Nothing else in any of those files changes. In particular: no `state`, no
frontmatter of any `prd.md`, no `est`, no acceptance box, no prose. The
board's remaining ~838 `.mi/` references in `prds/**` are execution-record
narrative that `stale-mi-paths` deliberately keeps — leave each one.

## The 61 spec-file carriers

`decisions/fzf` spec01, spec02, spec04 · `decisions/odin-toolchain` spec01,
spec02 · `decisions/shift-select-scope` spec01 · `decisions/tinty`
spec01–05 · `decisions/wallpaper-opacity` spec01, spec02 ·
`corrections/gate-home-isolation` spec03 ·
`corrections/w0-2-terminal-respec` spec01–09 ·
`corrections/w0-3-platform-rewrite` spec01, spec02 ·
`w0-4-s2-corrections/backlog-closeout` spec01–05 ·
`w0-4-s2-corrections/capsule` spec01–03 ·
`w0-4-s2-corrections/delivery` spec01–06 ·
`w0-4-s2-corrections/docs-inventories` spec01–04 ·
`w0-4-s2-corrections/editor` spec01–08 ·
`w0-4-s2-corrections/platform` spec01–07 ·
`w0-4-s2-corrections/provisioning-rerate` spec01–03.

Regenerate the list rather than trusting it — the sweep below is the
authority, and a hand-kept list beside it goes stale:

```sh
grep -rln --include='*.md' '^[[:space:]]*verify:.*\.mi/' prds | sort
```

## Two false positives that must NOT be rewritten

- `prds/02-terminal/05-tab-content-state/specs/spec03.md:37` — the line
  `verify: [{kind: "prose"}]` is a **help-corpus entry field** inside a nuon
  block, not a spec's verify command. It names no path and needs no change.
  Any future gate on `^verify:` has to exclude it — one of the two reasons
  the analyst's R5 answer is that such a gate can only ever be advisory.
- `prds/00-delivery/corrections/gate-home-isolation/specs/spec03.md` — the
  `.mi/` token here does need rewriting, but note the value is a
  YAML **double-quoted** scalar carrying `\"` and `\\n` escapes. Rewrite the
  path inside it and leave every escape byte-identical; a naive unescape
  changes the command.

## Acceptance

- [ ] `grep -rn --include='*.md' '^[[:space:]]*verify:.*\.mi/' prds` returns
      nothing, and the `stale-framework-links` spec named below carries no
      `.mi/` token either.
- [ ] Every path named in a board `verify:` value exists on disk. Prove with
      the sweep in *Verify and Proof* below: `missing=0`.
- [ ] The 16 scripts carry no `.mi/prds/`, `.mi/docs/` or `.mi/SYSTEM.md`
      reference. `.mi/gantt/plan.json` still appears in exactly three of
      them (`arith.py`, `tables.py`, `tree.py`) — that is spec02's, and
      rewriting it here is a failure of this box.
- [ ] All 62 carriers were executed after the rewrite and each exit code is
      quoted in the report. The analyst's measurement is the expected shape,
      so a delta is a finding, not a discrepancy to smooth over: **18 exit 0
      on the command rewrite alone**, **6 more exit 0 once their check
      script is rewritten too** (`platform` spec02, spec03, spec05, spec06;
      `provisioning-rerate` spec01, spec03), **32 exit non-zero**, **4 die
      inside a script on `.mi/gantt/plan.json`**, and **1 was not measured**
      (`gate-home-isolation` spec03 — its escaped scalar defeated the
      analyst's harness, and its proof appends 40 probe lines to a board
      spec file and restores them from a `mktemp` copy, so it must be run
      deliberately and a crash mid-run leaves that file dirty).
- [ ] `bash gates/tree-links.sh` Tier A is still 0 broken, asserted as a
      delta against the baseline **with these specs in place**: 835 links in
      135 files, 0 broken (measured 2026-08-23; it read 795 links in 130
      files before the three spec files were written, and Tier B's 114 broken
      links are pre-existing and not gating).
- [ ] Only the 61 spec files, the one `stale-framework-links` spec and the 16
      scripts were written, and no `prd.md` among them: the mtime of every
      file under `prds/` newer than the run's start, listed and compared
      against that roster, with `MISSING`/`UNEXPECTED` both empty. This is a
      **positive** claim — it says the diff *names* a set — so `git diff
      --stat -- prds` cannot satisfy it even in principle: `prds/` is 23 of
      426 tracked (`git ls-files --error-unmatch`, 2026-08-23), so at most 23 of the 78 files could
      ever appear and the assertion is impossible rather than merely vacuous.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: the
      mtime roster above, or `git status --porcelain --untracked-files=all`
      captured before and after.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

! grep -rq --include='*.md' '^[[:space:]]*verify:.*\.mi/' prds
p "no verify: value names a .mi/ path" $?

! grep -rq '\.mi/' \
  prds/00-delivery/corrections/stale-framework-links/specs/spec01.md
p "the fenced ## Verify block is repointed too" $?

n=$(grep -rl '\.mi/gantt/plan\.json' \
      prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks \
      | wc -l | tr -d ' ')
[ "$n" = 3 ]; p "the three plan.json readers are left for spec02 (got $n)" $?

! grep -rqE '\.mi/(prds|docs|SYSTEM\.md)' \
    $(find prds -name 'check*.sh' -o -name '*.py')
p "no invoked script names a resolvable .mi/ path" $?

# every path a verify: names now exists
python3 - <<'PY'
import os, re
roots = {'prds','docs','tests','gates','home','.claude','install.sh',
         'justfile','AGENTS.md','CLAUDE.md','.gitignore'}
tok = re.compile(r'[A-Za-z0-9_.@-]+(?:/[A-Za-z0-9_.@-]+)+/?')
missing = 0
for dp, dn, fns in os.walk('prds'):
    for fn in fns:
        if not fn.endswith('.md'):
            continue
        p = os.path.join(dp, fn)
        for line in open(p, encoding='utf-8'):
            m = re.match(r'^\s*verify:\s*(.*)$', line)
            if not m:
                continue
            for t in tok.findall(m.group(1)):
                t = t.rstrip('/,;:)"\'')
                if t.split('/')[0] not in roots:
                    continue
                if not os.path.exists(t):
                    print('MISSING', p, t)
                    missing += 1
print('missing=%d' % missing)
raise SystemExit(1 if missing else 0)
PY
p "every path named in a verify: exists" $?

bash gates/tree-links.sh > /tmp/tl.txt 2>&1
grep -q '0 broken' /tmp/tl.txt; p "tree-links Tier A: 0 broken" $?

exit $rc
```

Then run all 62 carriers and quote the table. The analyst's harness, for
reuse:

```sh
grep -rln --include='*.md' '^[[:space:]]*verify:' prds \
  | grep -v '/prd\.md$' \
  | while read -r f; do
      c=$(sed -n 's/^verify:[[:space:]]*`\(.*\)`$/\1/p' "$f" | head -1)
      [ -n "$c" ] || continue
      bash -c "$c" > /dev/null 2>&1
      printf '%-3s %s\n' "$?" "$f"
    done
```

It does not handle the escaped double-quoted form, which is the one case
above that went unmeasured. Run that one by hand.
