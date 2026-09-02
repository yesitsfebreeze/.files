#!/usr/bin/env python3
"""Delete whole entry records from a .nuon surface by their `cmd:`/`key:` id.

An entry is a `{` ... `}` record at one indent level. This walks brace depth
(skipping braces inside strings, and nushell's `($x)` interpolation is not a
brace so it needs no special case) to find the record enclosing the matched
line, then removes it whole. Prints one line per removal so a run that matched
nothing is visible rather than silent.
"""
import sys

def drop(text, ids):
    lines = text.split("\n")
    removed = []
    for wanted in ids:
        needle = f'"{wanted}"'
        hit = None
        for n, ln in enumerate(lines):
            s = ln.strip()
            if (s.startswith("cmd:") or s.startswith("key:")) and s.endswith(needle):
                hit = n
                break
        if hit is None:
            print(f"MISS {wanted}")
            continue
        start = hit
        while start >= 0 and lines[start].strip() != "{":
            start -= 1
        depth, end = 0, start
        for n in range(start, len(lines)):
            inq = esc = False
            for ch in lines[n]:
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == '"':
                    inq = not inq
                elif not inq and ch == "{":
                    depth += 1
                elif not inq and ch == "}":
                    depth -= 1
            if depth == 0:
                end = n
                break
        del lines[start:end + 1]
        removed.append(wanted)
        print(f"DROP {wanted} ({end - start + 1} lines)")
    return "\n".join(lines), removed

path, ids = sys.argv[1], sys.argv[2:]
out, _ = drop(open(path).read(), ids)
open(path, "w").write(out)
