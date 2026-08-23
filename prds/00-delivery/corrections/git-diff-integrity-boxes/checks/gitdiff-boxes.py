#!/usr/bin/env python3
"""gitdiff-boxes.py — classify every acceptance box on the board that leans on
`git diff`, and fail when one of them cannot observe what it claims.

Why this exists: most of this repo is untracked (99 tracked files; `prd.md` is
7 of 144), so `git diff` over a board path reports nothing and a box asserting
"the diff is empty" passes by observing nothing.  The class had been noticed
and hand-patched 28 times before it was ever named.  This script names it.

THE PREDICATE — seven rules, stated so the next person does not invent a worse
one.  Two earlier predicates were measured wrong and both are guarded against
here; see rules 2 and 6.

  1. POPULATION.  Every checkbox item under `prds/**/*.md` whose text contains
     `git diff`.  An item is its `- [ ]` / `- [x]` / `- [~]` line plus every
     following line indented deeper than the marker, blank lines included when
     a deeper-indented line follows — these boxes routinely run six lines and
     carry their pathspec in a continuation paragraph, so a line-at-a-time
     grep splits one box into fragments and loses the target.  The section
     heading the box sits under is recorded.

  2. TARGET = A PATHSPEC OF THE INVOCATION, NOTHING ELSE.  Inside each
     backticked span, find `git diff`, cut at the first shell separator, drop
     `-...` flags, honour a bare `--`, and take what is left.  A path named in
     the surrounding PROSE is not a target.  (First wrong predicate: scanning
     the box for path-shaped tokens scored a box whose prose mentioned a
     tree-wide `.mi/prd/` -> `prds/` rename against all 424 files under
     `prds/`, and turned three clean boxes into PARTIAL.)

  3. TRACKEDNESS IS PER FILE, NEVER PER DIRECTORY.  Membership in
     `git ls-files`.  `gates/` looks tracked and `gates/lib.sh`, the file
     every gate sources, is not.  Directories expand to their files, globs to
     their matches.

  4. CLASS.  REAL every target tracked · PARTIAL some tracked · VACUOUS none
     tracked · STALE a pathspec names a path that does not exist · NOTARGET
     the invocation carries no pathspec at all.

  5. POLARITY DECIDES THE VERDICT.  A NEGATIVE claim ("is empty", "shows
     nothing", "insertions only", "names it nowhere") over an untracked target
     passes by observing nothing — vacuous.  A POSITIVE claim ("names exactly
     these nine files", "touches only ...") over an untracked target is
     IMPOSSIBLE: the diff cannot name the file, so a `[x]` against it is a
     false record, not an optimistic one.  The two are reported apart.

  6. NOTARGET IS NOT DECIDABLE BY SCRIPT — it is listed, never guessed.  A
     bare `git diff` takes its subject from the prose ("that file", "the
     backlog", "over the footprint").  (Second wrong predicate: falling back
     to the spec's `footprint:` labelled two boxes REAL whose footprint is
     tracked while their actual subject, `tests/nvim-plugin-manager.sh`, is
     not.)  NOTARGET therefore never drives the exit code.

  7. ASSERTING VERSUS MENTIONING.  A box is load-bearing only if one of its
     backticked spans BEGINS with `git diff` — the span is then the command
     and not a reference to one.  All 72 board boxes qualify, so the rule
     costs nothing there.  It does not save this node, whose boxes name the
     class in prose and quote other boxes' commands verbatim, so:
     # rule 7 path exemption: this node's own folder is excluded from --check,
     # because 13 of its boxes quote or describe the very commands it censuses.
     Weakening the predicate to get green would unmake the node.

--check exits non-zero when a box is VACUOUS, STALE, or a POSITIVE claim over
a PARTIAL target, UNLESS the box disclaims `git diff` in its own text — that
last clause is what keeps the 28 already-defused boxes green.
"""

import os
import re
import subprocess
import sys

# ---------------------------------------------------------------- repo layout

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=HERE,
                      capture_output=True, text=True, check=True).stdout.strip()

# rule 7 path exemption: this node's own folder is excluded from --check,
# because 13 of its boxes quote or describe the very commands it censuses.
EXEMPT_PREFIX = "prds/00-delivery/corrections/git-diff-integrity-boxes/"

BOX_RE = re.compile(r"^(\s*)- \[( |x|~)\] ")
SPAN_RE = re.compile(r"`([^`]*)`", re.S)
SEPARATORS = ("|", "&&", "||", ";", ">", "<", ")", "$(", " piped", " and ", ",")


def sh(*args):
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True).stdout


TRACKED = set(p for p in sh("git", "ls-files").split("\n") if p)


def all_files():
    out = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for fn in filenames:
            out.append(os.path.relpath(os.path.join(dirpath, fn), ROOT))
    return out


ALL_FILES = all_files()

# --------------------------------------------------------------- rule 1: boxes


def boxes():
    """Yield (relpath, lineno, state, heading, text) for every git-diff box."""
    md = []
    for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, "prds")):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for fn in filenames:
            if fn.endswith(".md"):
                md.append(os.path.join(dirpath, fn))
    for path in sorted(md):
        rel = os.path.relpath(path, ROOT)
        with open(path) as fh:
            lines = fh.read().split("\n")
        heading, i = "", 0
        while i < len(lines):
            if lines[i].startswith("#"):
                heading = lines[i].strip()
            m = BOX_RE.match(lines[i])
            if not m:
                i += 1
                continue
            indent, body, j = len(m.group(1)), [lines[i]], i + 1
            while j < len(lines):
                if lines[j].strip() == "":
                    k = j
                    while k < len(lines) and lines[k].strip() == "":
                        k += 1
                    deeper = (k < len(lines)
                              and len(lines[k]) - len(lines[k].lstrip()) > indent)
                    if deeper:
                        body.extend(lines[j:k + 1])
                        j = k + 1
                        continue
                    break
                if len(lines[j]) - len(lines[j].lstrip()) > indent:
                    body.append(lines[j])
                    j += 1
                    continue
                break
            text = "\n".join(body)
            if "git diff" in text:
                yield rel, i + 1, m.group(2), heading, text
            i = j


# ------------------------------------------------- rules 2 and 7: the pathspec


def invocation_pathspecs(text):
    """Return (pathspecs, load_bearing).  Rule 2 for the first, rule 7 for the
    second: only a span that BEGINS with `git diff` is a command."""
    specs, load_bearing = [], False
    for raw in SPAN_RE.findall(text):
        span = re.sub(r"\s+", " ", raw.strip())
        if "git diff" not in span:
            continue
        if span.startswith("git diff"):
            load_bearing = True
        else:
            continue                      # rule 7: a mention, not a command
        tail = span[len("git diff"):]
        cut = len(tail)
        for sep in SEPARATORS:
            k = tail.find(sep)
            if k != -1:
                cut = min(cut, k)
        tail = tail[:cut]
        toks = [t.strip("\"'") for t in tail.split() if t.strip("\"'")]
        if "--" in toks:                  # honour an explicit pathspec fence
            toks = toks[toks.index("--") + 1:]
        for t in toks:
            if t.startswith("-"):
                continue                  # a flag, not a pathspec
            specs.append(t)
    seen, uniq = set(), []
    for s in specs:
        if s not in seen:
            seen.add(s)
            uniq.append(s)
    return uniq, load_bearing


# ------------------------------------------------- rules 3 and 4: the verdict


def expand(spec):
    """Resolve one pathspec to its files.  Returns None when it names nothing."""
    if "<" in spec or ">" in spec:
        return None                       # a placeholder, not a path
    p = spec.rstrip("/")
    full = os.path.join(ROOT, p)
    if "*" in p or "?" in p:
        import glob
        hits = [os.path.relpath(h, ROOT) for h in glob.glob(full)
                if os.path.isfile(h)]
        return hits or None
    if os.path.isfile(full):
        return [p]
    if os.path.isdir(full):
        return [f for f in ALL_FILES if f == p or f.startswith(p + "/")]
    return None


def classify(specs):
    if not specs:
        return "NOTARGET", 0, 0, []
    files, stale = [], []
    for s in specs:
        got = expand(s)
        if got is None:
            stale.append(s)
        else:
            files.extend(got)
    if stale:
        return "STALE", 0, 0, stale
    files = sorted(set(files))
    n_tracked = sum(1 for f in files if f in TRACKED)
    if not files:
        return "STALE", 0, 0, specs
    if n_tracked == len(files):
        return "REAL", n_tracked, len(files), []
    if n_tracked == 0:
        return "VACUOUS", 0, len(files), []
    return "PARTIAL", n_tracked, len(files), []


# ------------------------------------------------------------ rule 5: polarity

def norm(text):
    return re.sub(r"\s+", " ", text.replace("*", "").replace("`", "")).lower()


POSITIVE_CUES = (
    "shows exactly", "names exactly", "touches exactly", "shows only",
    "names only", "touches only", "and nothing else", "shows one hunk",
    "shows one contiguous", "shows two added", "shows the", "shows five",
    "shows changes to", "names it and", "shows every changed",
    "and no other", "names that one",
)
NEGATIVE_CUES = (
    "is empty", "empty by construction", "empty at the end", "shows nothing",
    "names nothing", "names it nowhere", "no hunk", "insertions only",
    "0 lines", "is unmodified", "untouched", "unchanged", "byte-identical",
    "byte-unchanged", "no change", "no line matching", "no box", "is silent",
    "touches no", "names no", "shows no", "is not empty",
)

# A box that BOTH enumerates what the diff must show AND says nothing else
# changed is scored POSITIVE: the enumeration is the part the diff cannot do
# over an untracked path.


def polarity(text):
    n = norm(text)
    pos = any(c in n for c in POSITIVE_CUES)
    neg = any(c in n for c in NEGATIVE_CUES)
    if pos:
        return "POSITIVE"
    if neg:
        return "NEGATIVE"
    return "UNCLEAR"


# ------------------------------------------------------- the disclaimer clause

DISCLAIMERS = (
    "empty by construction",
    "reworded by the orchestrator",
    "is not runnable", "not runnable as stated", "not runnable in this tree",
    "cannot answer", "cannot name", "cannot prove", "cannot be guarded",
    "cannot isolate",
    "proves nothing", "and proves nothing",
    "not the measure", "not usable here",
    "false-fail",
    "are untracked", "untracked tree",
    "not git diff guards",
    "same rewording, same reason",
    "rather than by git diff",
    "not by git diff",
)


def disclaims(text):
    n = norm(text)
    return [d for d in DISCLAIMERS if d in n]


# ------------------------------------------------------------------- the sweep

class Row(object):
    pass


def sweep():
    rows = []
    for rel, ln, state, heading, text in boxes():
        r = Row()
        r.file, r.line, r.state, r.heading, r.text = rel, ln, state, heading, text
        r.exempt = rel.startswith(EXEMPT_PREFIX)
        r.specs, r.load_bearing = invocation_pathspecs(text)
        r.cls, r.tracked, r.total, r.missing = classify(r.specs)
        r.polarity = polarity(text)
        r.disclaimers = disclaims(text)
        if not r.load_bearing:
            r.cls = "MENTION"
        rows.append(r)
    return rows


def fails(rows):
    """VACUOUS, STALE, or POSITIVE over PARTIAL — minus disclaimers, minus the
    rule 7 exemption, minus boxes that only mention the command."""
    out = []
    for r in rows:
        if r.exempt or r.disclaimers or r.cls == "MENTION":
            continue
        if r.cls in ("VACUOUS", "STALE"):
            out.append(r)
        elif r.cls == "PARTIAL" and r.polarity == "POSITIVE":
            out.append(r)
    return out


def review(rows):
    return [r for r in rows
            if not r.exempt and not r.disclaimers and r.cls == "NOTARGET"]


def describe(r):
    tgt = " ".join(r.specs) if r.specs else "-"
    if r.cls == "STALE" and r.missing:
        tgt = " ".join(r.missing) + " (absent)"
    frac = "%d/%d" % (r.tracked, r.total) if r.total else "-"
    tag = "EXEMPT " if r.exempt else ""
    disc = " DISCLAIMED" if r.disclaimers else ""
    return "%s:%-4d [%s] %s%-8s %-8s %-7s %s" % (
        r.file, r.line, r.state, tag, r.cls, r.polarity, frac, tgt) + disc


def prose_token_specs(text):
    """THE RETIRED PREDICATE, kept only to show what it does — do not use it.
    It harvests every path-shaped token in the box's backticked spans, so a box
    whose PROSE mentions `prds/` is scored against all 426 files under prds/.
    Rule 2 exists because of this; it is reproduced here so the next person can
    see the difference instead of re-deriving it."""
    specs = []
    for raw in SPAN_RE.findall(text):
        for tok in re.split(r"[\s,;()|]+", re.sub(r"\s+", " ", raw)):
            tok = tok.strip("\"'`.:")
            if not tok or tok.startswith("-"):
                continue
            if "/" in tok or re.search(r"\.(md|sh|lua|nu|nuon|json|yaml|tsv|py)$", tok):
                specs.append(tok.split(":")[0])
    return [s for s in dict.fromkeys(specs)]


PROBES = ["gates/lib.sh", "gates/retired-phrases.sh", "gates/waves.tsv",
          "tests/nushell-core.sh", "tests/nvim-plugin-manager.sh", "justfile",
          "home/dot_config/nushell/config.nu",
          "home/dot_config/nushell/help/capsule.nuon"]


def main(argv):
    mode = argv[1] if len(argv) > 1 else ""
    rows = sweep()
    board = [r for r in rows if not r.exempt]
    own = [r for r in rows if r.exempt]

    if mode == "--selftest":
        print("rule 3 — trackedness resolved per file, not per directory:")
        for p in PROBES:
            print("    %-42s %s" % (
                p, "tracked" if p in TRACKED else "UNTRACKED"))
        for d in ("gates", "tests", "home", "docs", "prds"):
            files = [f for f in ALL_FILES if f.startswith(d + "/")]
            print("    %-42s %d/%d tracked" % (
                d + "/", sum(1 for f in files if f in TRACKED), len(files)))
        print("    %-42s %d/%d tracked" % (
            "whole repo", len(TRACKED), len(ALL_FILES)))
        n_prd = len([f for f in ALL_FILES
                     if f.startswith("prds/") and f.endswith("/prd.md")])
        t_prd = sorted(f for f in TRACKED
                       if f.startswith("prds/") and f.endswith("/prd.md"))
        print("`prd.md` on the board: %d files, %d tracked" % (n_prd, len(t_prd)))
        for f in t_prd:
            print("    tracked %s" % f)
        qual = [r for r in board if r.load_bearing]
        print("rule 7 — board boxes whose span begins with `git diff`: "
              "%d of %d" % (len(qual), len(board)))
        under_rule2 = [r for r in own if r.cls != "MENTION"]
        print("rule 7 exemption — this node's own boxes: %d in population, "
              "%d load-bearing by rule 7, all %d NOTARGET under rule 2, so "
              "without the exemption they would crowd the REVIEW list rather "
              "than the FAIL list" % (len(own), len(under_rule2), len(under_rule2)))
        trip = []
        for r in own:
            cls, tr, tot, miss = classify(prose_token_specs(r.text))
            if cls in ("VACUOUS", "STALE") or (
                    cls == "PARTIAL" and polarity(r.text) == "POSITIVE"):
                trip.append((r, cls, tr, tot))
        print("    under the RETIRED prose-token predicate, %d of this node's "
              "boxes trip the check — which is why the exemption is written "
              "into the spec:" % len(trip))
        for r, cls, tr, tot in trip:
            print("        %s:%d %s %d/%d" % (r.file, r.line, cls, tr, tot))
        return 0

    if mode == "--check":
        f, rv = fails(rows), review(rows)
        print("FAIL — %d load-bearing box(es) cannot observe what they claim"
              % len(f))
        for r in sorted(f, key=lambda r: (r.cls, r.file, r.line)):
            why = ("impossible: positive claim, no tracked target"
                   if r.cls == "VACUOUS" and r.polarity == "POSITIVE" else
                   "vacuous: passes by observing nothing"
                   if r.cls == "VACUOUS" else
                   "stale: pathspec names nothing on disk" if r.cls == "STALE"
                   else "impossible in part: positive claim over %d/%d tracked"
                   % (r.tracked, r.total))
            print("  %s:%d [%s] %s %s -> %s" % (
                r.file, r.line, r.state, r.cls,
                " ".join(r.specs or r.missing) or "-", why))
        print("REVIEW — %d bare-`git diff` box(es), target is in the prose; "
              "rule 6 forbids guessing (exit code unaffected)" % len(rv))
        for r in sorted(rv, key=lambda r: (r.file, r.line)):
            print("  %s:%d [%s] NOTARGET" % (r.file, r.line, r.state))
        print("exempt by rule 7: %d box(es) under %s" % (len(own), EXEMPT_PREFIX))
        return 1 if f else 0

    # default: the full listing
    for r in rows:
        print(describe(r))
    print("")
    print("%d boxes cite `git diff` across %d files under prds/"
          % (len(rows), len(set(r.file for r in rows))))
    print("  %d exempt by rule 7 (this node's own folder), %d board boxes"
          % (len(own), len(board)))
    disc = [r for r in board if r.disclaimers]
    print("  %d board boxes disclaim `git diff` in their own text, "
          "%d are load-bearing" % (len(disc), len(board) - len(disc)))
    lb = [r for r in board if not r.disclaimers]
    for c in ("REAL", "PARTIAL", "VACUOUS", "STALE", "NOTARGET", "MENTION"):
        sel = [r for r in lb if r.cls == c]
        if not sel:
            continue
        pos = sum(1 for r in sel if r.polarity == "POSITIVE")
        print("    %-9s %2d   (positive claim: %d, negative/unclear: %d)"
              % (c, len(sel), pos, len(sel) - pos))
    tk = [r for r in lb if r.state == "x"]
    print("  of the load-bearing, %d are already `[x]`" % len(tk))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
