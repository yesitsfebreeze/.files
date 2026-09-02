#!/usr/bin/env python3
"""Strip `verify:` and `source:` from a .nuon surface.

Line-based deletion corrupts the file: 22 of the 116 `verify:` blocks in this
corpus span several lines (measured 2026-09-02), so the stripper tracks
bracket depth from `verify: [` until it balances, and skips brackets that sit
inside a double-quoted string. Idempotent: a file with no such field is
rewritten byte-identical.
"""
import sys

def strip(text):
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        s = lines[i].lstrip()
        if s.startswith("source:"):
            i += 1
            continue
        if s.startswith("verify:"):
            depth, inq, esc = 0, False, False
            while i < len(lines):
                for ch in lines[i]:
                    if esc:
                        esc = False
                    elif ch == "\\":
                        esc = True
                    elif ch == '"':
                        inq = not inq
                    elif not inq and ch == "[":
                        depth += 1
                    elif not inq and ch == "]":
                        depth -= 1
                i += 1
                if depth <= 0:
                    break
            continue
        out.append(lines[i])
        i += 1
    return "\n".join(out)

for p in sys.argv[1:]:
    src = open(p).read()
    open(p, "w").write(strip(src))
