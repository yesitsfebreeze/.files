#!/usr/bin/env python3
"""box-audit.py — the R4 predicate, run over the whole board.

Predicate (from prds/00-delivery/corrections/done-nodes-with-unticked-boxes,
R4): a node is a DEFECT when `state: done` and any `- [ ]` survives in its
`## Requirements` or `## Acceptance` section.

Probe code for that node. Read-only: it opens prd.md files and prints. It
writes nothing, touches no frontmatter, and moves no state.

Usage:
  python3 tests/box-audit.py                 # board-wide census
  python3 tests/box-audit.py --epic 02-terminal
  python3 tests/box-audit.py --list <node-path>   # every box, with its line
  python3 tests/box-audit.py --selftest      # prove the predicate can go red
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRDS = os.path.join(ROOT, "prds")

SECTIONS = ("## Requirements", "## Acceptance")
BOX = re.compile(r"^\s*-\s+\[( |x|~|X)\]\s*(.*)$")


def parse(path):
    """Return (state, {section: [(lineno, mark, text)]})."""
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    state = None
    # frontmatter: first --- ... ---
    if lines and lines[0].strip() == "---":
        for ln in lines[1:]:
            if ln.strip() == "---":
                break
            m = re.match(r"^state:\s*(\S+)", ln)
            if m:
                state = m.group(1)
    boxes = {s: [] for s in SECTIONS}
    cur = None
    for i, ln in enumerate(lines, 1):
        if ln.startswith("## "):
            cur = ln.strip() if ln.strip() in SECTIONS else None
            continue
        if cur is None:
            continue
        m = BOX.match(ln)
        if m:
            boxes[cur].append((i, m.group(1).lower(), m.group(2)[:70]))
    return state, boxes


def nodes():
    out = []
    for dirpath, _dirnames, filenames in os.walk(PRDS):
        if "prd.md" in filenames:
            p = os.path.join(dirpath, "prd.md")
            out.append((os.path.relpath(dirpath, PRDS), p))
    return sorted(out)


def census(prefix=None):
    total_done = 0
    defects = []
    open_total = 0
    for nid, path in nodes():
        if prefix and not nid.startswith(prefix):
            continue
        state, boxes = parse(path)
        if state != "done":
            continue
        total_done += 1
        n_open = sum(1 for s in SECTIONS for b in boxes[s] if b[1] == " ")
        n_closed = sum(1 for s in SECTIONS for b in boxes[s] if b[1] != " ")
        if n_open:
            defects.append((nid, n_open, n_closed))
            open_total += n_open
    return total_done, defects, open_total


def main():
    args = sys.argv[1:]
    if args and args[0] == "--selftest":
        # The predicate must be able to say "clean" AND "defect". A census
        # that only ever reports defects proves nothing. Assert both halves
        # against nodes whose shape is known from the tree itself.
        rc = 0
        _t, defects, _o = census()
        ids = {d[0] for d in defects}
        # positive precondition: the sweep saw done nodes at all
        t_all, _d, _o2 = census()
        if t_all < 10:
            print("FAIL selftest: fewer than 10 done nodes found — sweep is blind")
            rc = 1
        else:
            print("PASS selftest: sweep sees %d done nodes" % t_all)
        # a node known to carry open boxes must be flagged
        if "02-terminal/04-copy-mode" in ids:
            print("PASS selftest: 02-terminal/04-copy-mode flagged as a defect")
        else:
            print("FAIL selftest: 02-terminal/04-copy-mode NOT flagged")
            rc = 1
        # a node known to be clean must NOT be flagged
        if "02-terminal/06-launchd-path" in ids:
            print("FAIL selftest: 02-terminal/06-launchd-path flagged, but it is clean")
            rc = 1
        else:
            print("PASS selftest: 02-terminal/06-launchd-path not flagged")
        sys.exit(rc)

    if args and args[0] == "--list":
        nid = args[1]
        path = os.path.join(PRDS, nid, "prd.md")
        state, boxes = parse(path)
        print("%s  state=%s" % (nid, state))
        for s in SECTIONS:
            print("  %s" % s)
            for lineno, mark, text in boxes[s]:
                print("    L%-4d [%s] %s" % (lineno, mark, text))
        return

    prefix = None
    if args and args[0] == "--epic":
        prefix = args[1]

    total_done, defects, open_total = census(prefix)
    for nid, n_open, n_closed in defects:
        print("DEFECT  %-58s open=%-3d closed=%d" % (nid, n_open, n_closed))
    print("---")
    print("done nodes scanned:      %d" % total_done)
    print("done nodes with open []: %d" % len(defects))
    print("open boxes under done:   %d" % open_total)


if __name__ == "__main__":
    main()
