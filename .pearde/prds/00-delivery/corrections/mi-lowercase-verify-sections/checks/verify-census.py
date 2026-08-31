#!/usr/bin/env python3
"""verify-census.py — sweep all four places a node's proof can be recorded.

Run from the repo root:

    python3 prds/00-delivery/corrections/mi-lowercase-verify-sections/checks/verify-census.py
    python3 …/verify-census.py --check          # gate: exit 1 if any place has a carrier
    python3 …/verify-census.py --check-scripts  # also gate the script row

WHY THIS EXISTS. A node's executable proof lives in four places, and
`mi-rooted-verify-commands` swept three of them. It matched `^verify:` over
`*.md` case-sensitively and selected scripts by `-name 'check*.sh' -o -name
'*.py'`. Both selectors are shaped like the pattern that was already known, so
a lowercase heading and a script called `verify.sh` were both invisible, and
two `done` nodes kept a proof that had not run since the mi retirement.

The four places, plus the script row that the parent's selector missed:

  place 1  a `verify:` key in a `prd.md` frontmatter block
  place 2  a `verify:` key in any other `.md` frontmatter block (a spec)
  place 3  a fenced section under a heading `#{1,6} <V>erify…` — capital
  place 4  the same heading with a lowercase v
  scripts  every `*.sh` and `*.py` under `prds/**`, not only `check*.sh`

Places 3 and 4 come from ONE case-insensitive match, split on the byte that
was actually matched. Writing them as two greps is exactly how the fourth
place was missed, so the script must not be able to make that mistake: there
is one heading regex in this file and it is the only place a heading is
recognised. Likewise the frontmatter key regex is case-insensitive, because a
lowercase key is the same hole one level up.

Section bodies run to the next heading of the same or higher level — counted
only OUTSIDE fenced code blocks. A naive scan stops at the first `# ` at the
start of a line, which inside a fence is a shell comment, and truncates the
section before the commands it was meant to read. Two of this tree's own proof
blocks contain such a comment.

CARRIER RULE — a path, not a pattern. A place is a carrier when its value or
section body contains a dead reference rooted at the deleted `.mi` directory
that something would actually try to resolve. Four kinds of occurrence are NOT
carriers. The rule is stated here rather than allowlisting a file by name,
because three of this tree's own census blocks trip it, and a census that
cannot tell a path from a pattern over-reports forever:

  1. REGEX-ESCAPED — a backslash before the dot. No filesystem path is ever
     written that way; it is a matcher's pattern for the very thing this census
     looks for.
  2. A MATCHER'S QUOTED ARGUMENT — a single-quoted word in a `grep` / `egrep`
     / `fgrep` / `rg` / `--include=` command segment is a pattern. An unquoted
     or double-quoted path handed to `grep` as a FILE stays a carrier, which is
     the case that matters.
  3. A BARE MENTION — the token with no path segment after the slash, as in
     the English sentence `p "no ... token left in verify.sh"`, or a token that
     ends at a closing backtick or quote. There is nothing there to resolve.
  4. A WRITER'S PAYLOAD — an occurrence inside the string a `printf` / `echo` /
     `tee` / `cat >` writes. That is data being produced, not a path being
     read; this node's own spec04 plants exactly such a path in a scratch tree
     to prove the census can be made to go red, and its negative control must
     not read as the defect. This is the loosest of the four: a script that
     genuinely emits a dead path into a file would be missed, so it is stated
     as a known limit rather than sold as exact.

Everything else is a carrier: a quoted or bare token with a real path segment
after the slash, in any position a command would resolve.

GATING. `--check` gates places 1 to 4: those are the recording places, and a
carrier in one of them is a `done` node whose proof cannot run. The script row
is REPORTED, not gated, because four of its carriers are deliberately left by
other nodes (`editor/specs/verify-all.sh`'s usage comment is another node's
file with a correct runtime derivation; `delivery/checks/{arith,tables,tree}.py`
read a retired plan file and their nodes already carry an empty `verify:`) and
one more is in flight. `--check-scripts` gates that row too, for the day those
are cleaned up. Totals are a reading, never an assertion: they move whenever
another lane adds a node or a spec.
"""

import pathlib
import re
import sys

# The one heading regex. Places 3 and 4 are this single case-insensitive match
# split on group(2)'s first byte — there is deliberately no second, uppercase
# only pattern anywhere in this file.
HEADING = re.compile(r"(?m)^(#{1,6})[ \t]+([Vv]erify[^\n]*)$")
KEY = re.compile(r"(?im)^\s*verify:[ \t]*(.*)$")
FENCE = re.compile(r"^\s*(```|~~~)")
MATCHERS = re.compile(r"(?:^|[|;&(]|\s)(?:grep|egrep|fgrep|rg)\b|--include=")
WRITERS = re.compile(r"(?:^|[|;&(]|\s)(?:printf|echo|tee)\b|(?:^|\s)cat\s+>")
TOKEN = ".mi/"
CUT = "`'\"()[]{},;<>|\\ "


def fence_mask(text):
    """True for every line that sits inside a fenced code block."""
    inside = False
    mask = []
    for line in text.split("\n"):
        if FENCE.match(line):
            mask.append(True)          # the fence line itself belongs to it
            inside = not inside
            continue
        mask.append(inside)
    return mask


def section_body(text, match):
    """The body under `match`'s heading, to the next heading of the same or
    higher level. Headings inside a fenced block do not count — inside a fence
    a leading `#` is a shell comment."""
    mask = fence_mask(text)
    starts = [0]
    for line in text.split("\n"):
        starts.append(starts[-1] + len(line) + 1)
    end = len(text)
    lvl = len(match.group(1))
    same_or_higher = re.compile(r"^#{1,%d}[ \t]" % lvl)
    for i, line in enumerate(text.split("\n")):
        if starts[i] <= match.start():
            continue
        if mask[i]:
            continue
        if same_or_higher.match(line):
            end = starts[i]
            break
    return text[match.end():end]


def carriers_in(blob):
    """Every `.mi/`-rooted reference in `blob` that is a path, not a pattern.

    Returns a list of (line_text, word) pairs. See the CARRIER RULE above."""
    found = []
    for line in blob.split("\n"):
        if TOKEN not in line:
            continue
        matcher_line = bool(MATCHERS.search(line))
        writer_line = bool(WRITERS.search(line))
        for word in line.split():
            if TOKEN not in word:
                continue
            if "\\" + TOKEN in word:
                continue                      # rule 1: regex-escaped
            if matcher_line and word.count("'") >= 2:
                continue                      # rule 2: a matcher's own pattern
            if writer_line:
                continue                      # rule 4: a writer's payload
            # rule 3: the reference ends at the first delimiter, so a token
            # closed by a backtick or a quote has no path segment at all.
            tail = word.split(TOKEN, 1)[1]
            for ch in CUT:
                tail = tail.split(ch, 1)[0]
            if not tail.strip(".:*"):
                continue                      # rule 3: a bare mention
            found.append((line.strip(), TOKEN + tail))
    return found


def main(argv):
    check = "--check" in argv
    check_scripts = "--check-scripts" in argv
    root = pathlib.Path(".")

    totals = {1: 0, 2: 0, 3: 0, 4: 0}
    hits = {1: [], 2: [], 3: [], 4: []}

    for f in sorted(root.glob("prds/**/*.md")):
        text = f.read_text(encoding="utf-8")

        frontmatter = ""
        if text.startswith("---\n"):
            end = text.find("\n---", 4)
            if end > 0:
                frontmatter = text[4:end + 1]
        for m in KEY.finditer(frontmatter):
            place = 1 if f.name == "prd.md" else 2
            totals[place] += 1
            for line, word in carriers_in(m.group(1)):
                hits[place].append((f, word, line))

        for m in HEADING.finditer(text):
            place = 3 if m.group(2)[0] == "V" else 4
            totals[place] += 1
            for line, word in carriers_in(section_body(text, m)):
                hits[place].append((f, word, line))

    scripts = sorted(
        p for p in root.glob("prds/**/*")
        if p.is_file() and p.suffix in (".sh", ".py")
    )
    script_hits = []
    for p in scripts:
        for line, word in carriers_in(p.read_text(encoding="utf-8")):
            script_hits.append((p, word, line))

    labels = {
        1: "prd.md frontmatter `verify:`",
        2: "spec frontmatter `verify:`",
        3: "fenced heading, capital V",
        4: "fenced heading, lowercase v",
    }
    for n in (1, 2, 3, 4):
        print("place %d  %-32s total %d  carriers %d"
              % (n, labels[n], totals[n], len(hits[n])))
    print("scripts  %-32s total %d  carriers %d"
          % ('"*.sh" / "*.py" under prds/**', len(scripts), len(script_hits)))

    for n in (1, 2, 3, 4):
        for f, word, line in hits[n]:
            print("  CARRIER place %d  %s" % (n, f))
            print("      %s   in: %s" % (word, line[:120]))
    for f, word, line in script_hits:
        print("  CARRIER script (reported, not gating)  %s" % f)
        print("      %s   in: %s" % (word, line[:120]))

    if not check and not check_scripts:
        return 0
    bad = sum(len(hits[n]) for n in (1, 2, 3, 4))
    if check_scripts:
        bad += len(script_hits)
    if bad:
        print("RED — %d carrier(s)" % bad)
        return 1
    print("OK — no recording place holds a resolvable dead path")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
