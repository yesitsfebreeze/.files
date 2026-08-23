#!/usr/bin/env python3
"""W0.4g — the ~78-column wrap rule, with the exemptions stated rather than
quietly broken (S3 hygiene / R6).

`AGENTS.md` says "Markdown wrapped at ~78 columns... Tables are exempt —
don't mangle a table to fit." Two more exemptions are implicit and are made
explicit here, because a checker that flags them teaches people to mangle:

  * fenced code blocks — the README's tree diagram is aligned art, and
    rewrapping it destroys the alignment it exists for;
  * a line whose overrun is one unbreakable token (a markdown link, a path),
    which no amount of rewrapping shortens.

Usage: wrap.py <file> [<file> ...]   — measures characters, not bytes, so the
en-dashes, arrows and box-drawing characters in these files count as one.
"""
import re
import sys

LIMIT = 80          # "~78" with a two-column tolerance
TOKEN = 60          # a whitespace-free run this long is unbreakable

fails = []
for path in sys.argv[1:]:
    fenced = False
    for n, line in enumerate(open(path, encoding="utf-8").read().splitlines(), 1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if fenced or line.startswith("|"):
            continue
        if len(line) <= LIMIT:
            continue
        if max((len(t) for t in line.split()), default=0) >= TOKEN:
            continue
        fails.append(f"{path}:{n} is {len(line)} columns: {line.strip()[:60]}…")

for f in fails:
    print("FAIL: " + f)
if not fails:
    print("OK")
sys.exit(1 if fails else 0)
