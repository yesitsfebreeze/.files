---
est: 2h
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec01.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec02.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec03.md
  - prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec04.md
executor: implementer
---

# spec02 — `w0-4-s2-corrections/help`: repoint four `## verify` blocks and give the node a runner

`w0-4-s2-corrections/help` is `done` with `verify: ""` and five fenced
`## verify` blocks that all read `.mi/prds/…`. Every one dies the same way:

```
Error: nu::shell::io::file_not_found
```

Unlike [spec01](spec01.md)'s carrier this one really is a token problem — the
commands derive nothing, they name paths. Measured 2026-08-23 with
`.mi/prds/` → `prds/` applied and nothing else changed:

| spec | repointed command | exit |
|---|---|---|
| spec01 | `nu -n -c '… open --raw prds/06-help/02-help-command/prd.md …'` | **0** (`ok`) |
| spec02 | `nu -n -c '… open --raw prds/06-help/03-browser/prd.md …'` | **0** (`ok`) |
| spec03 | `nu -n -c '… prds/06-help/01-content-model/prd.md` + `tests/help-content-model.nu` …' | **0** (`ok`) |
| spec04 | `nu -n -c '… open --raw prds/06-help/prd.md …'` | **0** (`ok`) |
| spec04 | `shasum -a 256 prds/06-help/04-drift-check/prd.md \| grep -q '^3d916f8a…'` | **0** — the 2026-08-21 digest still matches |

spec05 is **not** in this spec. It is the one file another node already claims
— see [spec03](spec03.md).

## The edits

Exactly **five lines**, each inside a fenced block, `.mi/prds/` → `prds/`:

| file | line | what |
|---|---|---|
| `help/specs/spec01.md` | 135 | `open --raw .mi/prds/06-help/02-help-command/prd.md` |
| `help/specs/spec02.md` | 88 | `open --raw .mi/prds/06-help/03-browser/prd.md` |
| `help/specs/spec03.md` | 91 | `open --raw .mi/prds/06-help/01-content-model/prd.md` |
| `help/specs/spec04.md` | 121 | `open --raw .mi/prds/06-help/prd.md` |
| `help/specs/spec04.md` | 130 | `shasum -a 256 .mi/prds/06-help/04-drift-check/prd.md` |

**Leave every `.mi/` token outside a fence alone** — the "Files touched" lists
(spec01:16, spec02:16 and :20, spec03:20, spec04:16, :18, :111). They are
execution record under the `stale-mi-paths` keep-list; whether that keep-list
survives is [`stale-mi-keeplist-ruling`](../../stale-mi-keeplist-ruling/prd.md)'s
question and not this node's to answer. Preserve the `"\\s+"` double backslash
byte-for-byte: it is a nushell double-quoted string carrying the regex `\s+`,
and collapsing it to `"\s+"` makes nu refuse to parse the command
(`unrecognized escape sequence '\s'`, measured).

## The runner, so the node gets a frontmatter-shaped proof

Four green commands in four fenced blocks are proof but not a `verify:` value:
they contain both `'` and `"` and will not survive a YAML scalar intact. Add
`prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh`, mirroring the
two runners the same parent already has — `../shell/verify.sh` at the node root
and `../editor/specs/verify-all.sh`.

**It must not contain a command.** Take `verify-all.sh`'s design and adapt it to
the fenced form: for `spec01.md`…`spec04.md`, extract every fenced block inside
that file's `## verify` section and `bash -c` it; exit 0 only if all exit 0.
Print one `PASS`/`FAIL` line per block. Then the runner cannot drift from the
specs, and it makes no claim of its own — which is R2's line: this node repairs
pointers and adds no proof.

`spec05.md` is excluded **by name, in a comment saying why**: its first block is
a spent assertion ([spec03](spec03.md)) and its other two blocks print rather
than assert.

## Acceptance

- [ ] `bash prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh`
      exits **0** and prints 5 `PASS` lines and 0 `FAIL` (4 spec files, 5
      blocks).
- [ ] The runner contains no `nu -n -c`, no `shasum` and no `open --raw`:
      `grep -cE 'nu -n -c|shasum|open --raw' help/verify.sh` is **0**. A runner
      that embeds its checks can disagree with the specs silently.
- [ ] Each of the four specs' `## verify` blocks, run standalone by hand from
      the repo root, exits 0 — quote each exit code. The runner passing is not
      a substitute: it would also pass if it silently ran zero blocks.
- [ ] The runner runs zero blocks for nobody: assert the extracted count is
      **5**, and prove the extractor can fail by pointing it at a file with no
      `## verify` section and seeing it report 0 rather than exit 0 quietly.
- [ ] `grep -rn '\.mi/' help/specs/spec0{1,2,3,4}.md` returns **only** lines
      outside a fenced block — 7 lines, at spec01:16, spec02:16, spec02:20,
      spec03:20, spec04:16, spec04:18, spec04:111. Any other line is a missed
      repoint or a repointed record.
- [ ] The `"\\s+"` literal survives: `grep -c '"\\\\s+"' help/specs/spec01.md`
      is 1, and the same for spec02, spec03 and spec04.
- [ ] Nothing but the five lines changed in the four spec files. Prove by
      content, not `git diff` — most of `prds/` is untracked, so a diff box
      over it passes by observing nothing: `cp` the four files aside first,
      then `diff` each pair and confirm the output is exactly the five expected
      `<`/`>` pairs.
- [ ] `prds/06-help/04-drift-check/prd.md` still hashes to
      `3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd`. If it
      does not, the spec04 digest guard is a *second* finding — report it, do
      not re-take the digest.
- [ ] `bash gates/tree-links.sh` Tier A: **0 broken** (baseline before this
      node, 2026-08-23: 941 links / 152 files / 0 broken).

## Out of scope

- `help/specs/spec05.md` — [spec03](spec03.md)'s, and contended.
- `help/prd.md` frontmatter. Its pre-resolved `verify:` is reported, not
  applied; frontmatter is the orchestrator's (PRD R5).
- Any assertion inside the four blocks. Repoint the path; touch no predicate.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
H=prds/00-delivery/corrections/w0-4-s2-corrections/help

bash "$H/verify.sh" >/tmp/h.txt 2>&1; p "help/verify.sh exits 0" $?
[ "$(grep -c '^PASS' /tmp/h.txt)" = 5 ]; p "5 PASS lines (got $(grep -c '^PASS' /tmp/h.txt))" $?
[ "$(grep -c '^FAIL' /tmp/h.txt)" = 0 ]; p "0 FAIL lines" $?

! grep -qE 'nu -n -c|shasum|open --raw' "$H/verify.sh"
p "the runner embeds no check of its own" $?

n=$(grep -rn '\.mi/' "$H"/specs/spec01.md "$H"/specs/spec02.md \
        "$H"/specs/spec03.md "$H"/specs/spec04.md | wc -l | tr -d ' ')
[ "$n" = 7 ]; p "exactly 7 .mi/ record lines remain, none in a fence (got $n)" $?

for f in 01 02 03 04; do
  grep -q '"\\\\s\+"' "$H/specs/spec$f.md" || rc=1
done
p "the \"\\\\s+\" nushell literal is intact in all four" $?

shasum -a 256 prds/06-help/04-drift-check/prd.md \
  | grep -q '^3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd '
p "spec04's digest guard subject is unchanged" $?

bash gates/tree-links.sh 2>&1 | head -5 | grep -q '0 broken'
p "tree-links Tier A: 0 broken" $?
exit $rc
```
