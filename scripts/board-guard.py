#!/usr/bin/env python3
"""Three read-only checks over the board. Nothing here writes or stages.

    board-guard.py held --self <prd-rel> [paths...]   a path another node holds
    board-guard.py verify-blocks                      a spec that acts, not proves
    board-guard.py requirements                       a requirement asking for the tree

`00-delivery/corrections/baseline-commit-absorbs-live-claims`, R1 and R2. On
2026-09-02 a requirement written "commit the current working tree" was
implemented as `git add --all` with four exclusions, and swept up the
mid-flight files of a node another worker held. It ran five times, and two of
the five commits absorbed a live claim.

`held` reads the board — not only `.pearde/.claims/` — because the incident
proved the claim *directory* lags the claim itself: the victim
`08-claude-agent/02-nvim-plugin` was claimed at 11:17 and swept at 11:39, and
its `.pearde/.claims/.../at` was not written until 11:44:46. A guard reading
only the snapshot dir would have passed the very commit that caused the node
to exist.

Three sources, in the order they become true:

  1. `claim:` + `state:` in each `prd.md` frontmatter — true from the moment
     the orchestrator hands the node out. Held paths are the PRD's own folder
     plus every `footprint:` its specs and its `prd.md` declare.
  2. `.pearde/.claims/riders` — board state owed to the next collect.
  3. `.pearde/.claims/<prd>/` — where it exists, the snapshot of the claim.
"""
import argparse
import os
import re
import subprocess
import sys

CONTENDING = ("analyzing", "refine", "question", "specced",
              "claimed", "blocked", "failed")

# --- held ------------------------------------------------------------------


def frontmatter(path):
    """`(state, claim, footprint)` off a prd.md or spec.md. A hand parse on
    purpose: no yaml dependency, and the board's frontmatter is a flat map
    plus block lists."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None, None, []
    if not text.startswith("---"):
        return None, None, []
    body = text.split("\n---", 1)[0][3:]
    state = claim = None
    foot, in_foot = [], False
    for line in body.split("\n"):
        if re.match(r"^\s*#", line):
            continue
        m = re.match(r"^state:\s*([a-z]+)", line)
        if m:
            state = m.group(1)
        m = re.match(r"^claim:\s*(\S.*?)\s*(?:#.*)?$", line)
        if m:
            claim = m.group(1)
        if re.match(r"^footprint:", line):
            in_foot = True
            continue
        if in_foot:
            m = re.match(r"^\s+-\s+(\S+)", line)
            if m:
                foot.append(m.group(1).rstrip("/"))
                continue
            if line.strip() and not line.startswith(" "):
                in_foot = False
    return state, claim, foot


def held(board, self_rel):
    """{path -> [holder, ...]} — every path a live claim holds, other than
    `self_rel`'s own. Paths are board-relative."""
    out = {}

    def add(path, who):
        if not path:
            return
        out.setdefault(path.rstrip("/"), [])
        if who not in out[path.rstrip("/")]:
            out[path.rstrip("/")].append(who)

    prds = os.path.join(board, "prds")
    for root, dirs, files in os.walk(prds):
        if "prd.md" not in files:
            continue
        rel = os.path.relpath(root, prds)
        if rel == self_rel:
            continue
        state, claim, foot = frontmatter(os.path.join(root, "prd.md"))
        if state not in CONTENDING:
            continue
        who = f"{rel} ({state}" + (f", claim {claim}" if claim else "") + ")"
        # the node's own folder is its record and has one writer
        add(os.path.relpath(root, os.path.dirname(board)), who)
        specs = os.path.join(root, "specs")
        allfoot = list(foot)
        if os.path.isdir(specs):
            for s in sorted(os.listdir(specs)):
                if s.endswith(".md"):
                    allfoot += frontmatter(os.path.join(specs, s))[2]
        for f in allfoot:
            add(f, who)

    riders = os.path.join(board, ".claims", "riders")
    if os.path.isfile(riders):
        for line in open(riders, encoding="utf-8"):
            if line.strip():
                add(line.strip(), "riders (owed to the next collect)")
    return out


def staged_by_add_all(repo):
    """What a bare `git add --all` would stage, without staging it."""
    r = subprocess.run(["git", "-C", repo, "add", "--all", "--dry-run",
                        "--", "."], capture_output=True, text=True)
    paths = []
    for line in r.stdout.split("\n"):
        m = re.match(r"^\w+\s+'?(.+?)'?$", line.strip())
        if m:
            paths.append(m.group(1))
    return paths


def inside(path, holder):
    return path == holder or path.startswith(holder + "/")


def cmd_held(a):
    board = os.path.abspath(a.board)
    repo = os.path.abspath(a.repo)
    prefix = os.path.relpath(board, repo)
    prefix = "" if prefix == "." else prefix

    paths = list(a.paths)
    if a.stdin:
        paths += [line.strip() for line in sys.stdin if line.strip()]
    if not paths:
        paths = staged_by_add_all(repo)

    claims = held(board, a.self_rel)
    # board-relative holder paths -> repo-relative
    claims = {(os.path.join(os.path.dirname(prefix), h) if prefix and
               h.startswith(os.path.basename(board) + "/") else h): who
              for h, who in claims.items()}

    bad = []
    for p in sorted(set(paths)):
        for h, who in claims.items():
            if inside(p, h):
                bad.append((p, who))
                break
    if not bad:
        return 0
    print(f"{len(bad)} path(s) held by a live claim — none staged:",
          file=sys.stderr)
    for p, who in bad:
        print(f"  {p}\n      held by {', '.join(who)}", file=sys.stderr)
    print("\nName the paths instead of the tree, or pass the exclusion set "
          "this prints.", file=sys.stderr)
    return 1


# --- verify-blocks ---------------------------------------------------------

# A Verify block asserts the post-state. These act on it instead. A dry run
# is exempt because it performs no act — `git add -n .pearde/wiki` is a
# question, not a staging.
ACTS = re.compile(r"^\s*git\s+(add|commit|rm|reset|stash)\b(?P<rest>.*)$")
DRY = re.compile(r"(?:^|\s)(?:-n|--dry-run)(?:\s|$)")


def board_markdown(board):
    for root, dirs, files in os.walk(os.path.join(board, "prds")):
        for f in sorted(files):
            if f.endswith(".md"):
                yield os.path.join(root, f)


def verify_block_lines(path):
    """(lineno, line) for every line inside a fenced block under a
    `## Verify and Proof` heading."""
    inside_section = False
    fenced = False
    for i, line in enumerate(open(path, encoding="utf-8",
                                  errors="replace").read().split("\n"), 1):
        if line.startswith("## "):
            inside_section = line.strip().lower().startswith("## verify")
            fenced = False
            continue
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if inside_section and fenced:
            yield i, line


def cmd_verify_blocks(a):
    bad = []
    for path in board_markdown(os.path.abspath(a.board)):
        for i, line in verify_block_lines(path):
            m = ACTS.match(line)
            if m and not DRY.search(m.group("rest")):
                bad.append((os.path.relpath(path), i, line.strip()))
    if not bad:
        return 0
    print(f"{len(bad)} line(s) in a `## Verify and Proof` block act on the "
          f"repo instead of asserting its state:", file=sys.stderr)
    for path, i, line in bad:
        print(f"  {path}:{i}: {line}", file=sys.stderr)
    print("\nA Verify block is a proof, not a build script: assert the "
          "post-state. A dry run (-n, --dry-run) is exempt.", file=sys.stderr)
    return 1


# --- requirements ----------------------------------------------------------

# A numbered requirement line — `- [ ] **R3** — …` — and its indented
# continuations. Prose that quotes the defect is not a requirement and is
# never read here.
REQ = re.compile(r"^\s*- \[[ x~-]\]\s+\*\*R\d+\*\*")
BOX = re.compile(r"^\s*- \[[ x~-]\]")
# The shape, not one spelling: an act on the whole tree, in either word
# order, plus the bulk add that implements it. Proximity is the point — a
# requirement that happens to say "commit" in one clause and "working tree"
# in another is not asking for this.
SHAPE = re.compile(
    r"\b(?:commit|stage)(?:s|d|ed|ted|ting)?\s+(?:\S+\s+){0,3}"
    r"(?:(?:current|whole|entire)\s+)?(?:working[ -])?tree\b"
    r"|\b(?:(?:current|whole|entire)\s+)?working[ -]tree\s+(?:\S+\s+){0,3}"
    r"(?:is|are|be|gets?)\s+(?:\S+\s+){0,2}(?:committed|staged)\b"
    r"|git add\s+(?:--all|-A)\b", re.I)
# A requirement that forbids the shape is not written in it. The window is
# the clause before the match, not the whole line.
FORBIDS = re.compile(r"\bno\b|\bnot\b|\bnever\b|\bmay not\b|\bwithout\b"
                     r"|\binstead of\b|\bno longer\b", re.I)


def requirement_texts(path):
    """(lineno, text) per numbered requirement, continuations joined."""
    lines = open(path, encoding="utf-8",
                 errors="replace").read().split("\n")
    out, cur, start = [], None, 0
    for i, line in enumerate(lines, 1):
        if REQ.match(line):
            if cur is not None:
                out.append((start, " ".join(cur)))
            cur, start = [line.strip()], i
            continue
        if cur is not None:
            if line.startswith(" ") and line.strip() and not BOX.match(line):
                cur.append(line.strip())
            else:
                out.append((start, " ".join(cur)))
                cur = None
    if cur is not None:
        out.append((start, " ".join(cur)))
    return out


def cmd_requirements(a):
    bad = []
    for path in board_markdown(os.path.abspath(a.board)):
        if os.path.basename(path) != "prd.md":
            continue
        for i, text in requirement_texts(path):
            m = SHAPE.search(text)
            if m and not FORBIDS.search(text[max(0, m.start() - 80):
                                             m.start()]):
                bad.append((os.path.relpath(path), i, text[:110]))
    if not bad:
        return 0
    print(f"{len(bad)} requirement(s) ask for the tree instead of naming "
          f"paths:", file=sys.stderr)
    for path, i, text in bad:
        print(f"  {path}:{i}: {text}", file=sys.stderr)
    print("\nName the paths a requirement lands, or an exclusion set computed "
          "from the live claims — never the tree.", file=sys.stderr)
    return 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    h = sub.add_parser("held", help="paths another node holds under a claim")
    h.add_argument("--self", dest="self_rel", required=True)
    h.add_argument("--board", default=".pearde")
    h.add_argument("--repo", default=".")
    h.add_argument("--stdin", action="store_true")
    h.add_argument("paths", nargs="*")
    h.set_defaults(fn=cmd_held)

    v = sub.add_parser("verify-blocks",
                       help="a spec whose Verify block acts on the repo")
    v.add_argument("--board", default=".pearde")
    v.set_defaults(fn=cmd_verify_blocks)

    r = sub.add_parser("requirements",
                       help="a requirement asking for the working tree")
    r.add_argument("--board", default=".pearde")
    r.set_defaults(fn=cmd_requirements)

    a = ap.parse_args()
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
