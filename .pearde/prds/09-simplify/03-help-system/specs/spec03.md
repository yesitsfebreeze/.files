---
complexity: 14
footprint:
  - home/dot_config/nushell/help/README.md
  - home/dot_config/nushell/help/manual/internals
---

# spec03 — the internals stop describing machinery that is gone

The hand-written internals are the only part of the manual `just manual` does
not regenerate, so nothing corrects them but a person. Covers R6, R1's prose
half and R8. **This is the bulk of the work left.**

**Already stands**: `help/README.md` rewritten 366 → 64 lines — the schema
table, the three-step edit loop, and one paragraph saying the checker is gone
and nothing checks the manual now. `verify` and `source` are out of the schema
table with a line saying why. `internals/help.md`'s "this site" opener is
fixed.

**Left to finish**, and it is all editorial judgement rather than a pattern a
script can apply:

1. **`internals/help.md` — 691 lines, and R1 only accounts for half of it.**
   R1 says delete 333–691 (the `## help-check.nu` section, the checker's own
   design). True, and it goes. But 7–332 documents `help.nu` **as it was**:
   18 passages quote or explain `_help_md`, `_help_browse`, `_help_rows`,
   `_help_host_only`, `--fuzzy`, `--delegate`, `--all`, `verify` and
   `source`, none of which exist. Rewrite the section against the 198-line
   file. **Four constraints in it are load-bearing and must survive the
   rewrite verbatim in substance** — they are the expensive part:
   - `use std/help` and `def help` in ONE file fail at parse on 0.114.1;
     `core-help` must be an alias and must precede the shadow, which is why
     the three lines live in `config.nu` and not here.
   - The corpus is addressed by `$nu.home-dir | path join ".config"
     "nushell"` and nothing else, with the four-row launch-shape table that
     rejects `default-config-dir` and `config-path | path dirname`.
   - Every failure raises; an empty manual reads as "this environment has no
     custom bindings", the most expensive wrong answer `help` can give.
   - `ls --help` arrives here as `help` with rest `["ls"]`, indistinguishable
     from a typed `help ls`.
   Two of its recorded trades are now **false** and must be restated, not
   carried: the escape hatch is `core-help <name>`, not `help --delegate`;
   and "checking the manual against a live configuration is `--check`, which
   runs on demand" describes a deleted command.
2. **`internals/index.md:14`** still reads "How `help` and `help --check` are
   built." **Ordering hazard: a concurrent `09-simplify/07-provisioning`
   worker added a `provisioning.md` row to this same file on 2026-09-02.**
   One writer per file — take this line only after that node has landed, and
   edit the single line rather than rewriting the list.
3. **30 `tests/` / `gates/` / `docs-site` citations across six files**
   (`help.md` 7, `neovim.md` 9, `unverified.md` 5, `capsule.md` 4,
   `wezterm.md` 3, `nushell-modules.md` 2). Each is prose, and the reason
   around it is usually worth keeping when the citation is not — e.g.
   `neovim.md:133` records that key order in `install = { colorscheme = ...`
   is load-bearing *only because* a deleted gate grepped for the literal
   string, so the constraint dies with its reason and the sentence goes,
   whereas `capsule.md:15`'s "every docker call goes through `^docker`" is a
   real design rule that merely cited a gate as its beneficiary. Read each.
4. **`unverified.md` keeps its list and loses the gate vocabulary.** The 81
   interactive checks are the point of the file; `gates/manual/wave*.md` as
   their former home, and the PASS/FAIL framing borrowed from it, are not.
   **H.4 must go rather than be reworded**: it reads "`help --check` exits 0
   … the closest thing this build has to a completeness proof", and that
   command no longer exists, so it is a check that can never be run.

## Acceptance

- [x] `rg -l 'tests/|gates/|docs-site' home/dot_config/nushell` prints nothing —
      30 citations removed across the six files the spec named. **The job was
      larger than the path citations**: 51 further mentions of the bare word
      *gate* described the same deleted machinery as live ("the gate greps this
      file", "the gate rejected two of them"), and R8's "loses the gate
      vocabulary" reaches those too. 32 were rewritten in four files; the two in
      `tmux.md` and `nushell.md` are ordinary English ("gates the request") and
      stand.
- [x] no file under `manual/internals` names `help --check`, `--fuzzy`, `--md`,
      `--all`, `--entry`, `--topic`, `--delegate`, `_help_rows`,
      `_help_browse`, `_help_preview`, `_help_md` or `_help_host_only` — the
      spec's rg finds nothing. Two files outside the spec's list carried them:
      `nushell.md`'s `rm`/`always_trash` passage used the drift check as its
      worked example (the `-p` rule and the "a probe is not garbage" rule
      survive; the command that surfaced them is named in the past tense), and
      `neovim.md` documented the `HELP_CHECK` guard spec01 deleted from
      `lazy.lua`.
- [x] `internals/help.md` has no `## help-check.nu` section and every code
      block it quotes appears verbatim in the current `help.nu` — 691 → 314
      lines; the spec's python check reports `def blocks: 11 | not verbatim: 0`.
- [x] the four load-bearing constraints listed above are each still findable in
      `internals/help.md` — `use std/help`, `path join ".config"`, `no custom
      bindings` and `ls --help` all `found`. The two false trades are restated
      rather than carried: the escape hatch is now recorded as `core-help
      <name>` with a dated line saying the flag was a second spelling of it,
      and the drift-check sentence is replaced by one saying nothing checks the
      manual any more and what keeps it honest instead.
- [x] `unverified.md` still lists its interactive checks, and H.4 is gone — 81
      open checks still listed. **Two checks were deleted, not reworded**: H.4's
      completeness proof (it ran a command that no longer exists) and G.1
      ("prove each gate by breaking it"; `just gate-selftest` is gone with the
      gates). G.1 was Wave 0's only row, so that heading went with it.
- [x] `internals/index.md` describes `help.md` without naming a deleted flag,
      and still lists every file in the directory — line 14 now reads "How
      `help` and `?` are built, and the four constraints that shape them". The
      concurrent `07-provisioning` worker's `provisioning.md` row had already
      landed, so this was a one-line edit as the spec required.

## Three things this spec's verify block could not have passed as written

1. **`index.md` failed its own last assertion.** `for f in $I/*.md; do rg -qF
   "$(basename $f)" $I/index.md` iterates over `index.md` too, and the index is
   the one page that cannot sensibly link to itself — it was `UNLISTED` in
   itself. Fixed by a paragraph that names the file while saying something
   worth saying: `index.md` and every page it lists are hand-written, `guide/`
   and `reference/` are generated and cannot drift, so nothing but a person
   corrects these.
2. **`rg -q 'H\.4'` cannot tell a live check id from prose recording its
   retirement.** Wave 6 held three H.4 rows, and only one was dead. Writing
   down *which* id was retired would have failed the check. Resolved by naming
   the retired node by its path, `06-help/04-drift-check`, which is what the
   letter was always shorthand for and is unambiguous where the letter is
   local. The surviving `ls --help`-on-a-fresh-machine row is re-keyed to H.2,
   the node that actually owns the delegation; the third row was a signpost
   ("the fresh-machine run, below"), not a check, and went.
3. **The file's own count line was already false.** It read *81 checks still
   open across 7 waves*; `rg -c '^- ☐ \*\*open\*\*'` answered **84**. It now
   says 81 across 6 waves, computed from the file rather than carried in
   prose, and says what it replaced — the stale-number shape this board keeps
   correcting, found inside the file that documents unverified claims.

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
I=home/dot_config/nushell/help/manual/internals
if rg -q 'tests/|gates/|docs-site' home/dot_config/nushell; then echo "FAIL: rg -q 'tests/|gates/|docs-site' home/dot_config/nushell"; exit 1; fi
if rg -q 'help --(check|fuzzy|md|all|entry|topic|delegate)|_help_rows|_help_browse|_help_preview|_help_md|_help_host_only' $I; then echo "FAIL: rg -q 'help --(check|fuzzy|md|all|entry|topic|delegate)|_h"; exit 1; fi
if rg -q '^## .help-check' $I/help.md; then echo "FAIL: rg -q '^## .help-check' $I/help.md"; exit 1; fi
# Every fenced code block in help.md must be a real line of the file it documents.
python3 - <<'PY'
import re, sys
doc = open('home/dot_config/nushell/help/manual/internals/help.md').read()
src = open('home/dot_config/nushell/help.nu').read()
bad = [b.strip() for b in re.findall(r'```\n(.*?)```', doc, re.S)
       if b.strip().startswith('def ') and b.strip() not in src]
print('\n'.join(bad)); sys.exit(1 if bad else 0)
PY
for c in 'use std/help' 'path join ".config"' 'no custom bindings' 'ls --help'; do
  rg -qF "$c" $I/help.md || { echo "lost constraint: $c"; exit 1; }
done
if rg -q 'H\.4' $I/unverified.md; then echo "FAIL: rg -q 'H\.4' $I/unverified.md"; exit 1; fi
rg -q '☐' $I/unverified.md
for f in $I/*.md; do rg -qF "$(basename $f)" $I/index.md || { echo "unlisted: $f"; exit 1; }; done
echo spec03 OK
```
