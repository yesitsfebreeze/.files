#!/usr/bin/env python3
"""W0.4g spec05 — README's tree diagram and build order match the board.

`SYSTEM.md`: "Don't reorganize the tree without updating `prds/README.md`
in the same change — the index, the tree diagram, and the build order all live
there." So all three are checked here against what actually exists on disk and
in `.mi/gantt/plan.json`, rather than against a remembered count.
"""
import json
import os
import re
import subprocess
import sys

ROOT = subprocess.check_output(
    ["git", "rev-parse", "--show-toplevel"], text=True
).strip()
README = os.path.join(ROOT, "prds/README.md")
PRDS = os.path.join(ROOT, "prds")
PLAN = os.path.join(ROOT, ".mi/gantt/plan.json")

# The build order's caption says it is generated from plan.json, so it is
# checked against plan.json alone. A board node plan.json has *not* scheduled
# still owes the tree diagram an entry (checked above) but cannot be given a
# wave here without inventing one — that is a routing item for the conductor,
# not a README edit. S.9 was such a node until 2026-08-21; W0.4h
# (backlog-closeout) is one now.

fails = []


def fail(msg):
    fails.append(msg)


text = open(README, encoding="utf-8").read()
plan = json.load(open(PLAN, encoding="utf-8"))

# --- the tree diagram --------------------------------------------------------
parts = text.split("```")
if len(parts) < 3:
    fail("no fenced tree diagram in README.md")
    sys.exit(1)
diagram = parts[1].splitlines()

LEAF = re.compile(r"^(.*?[├└]── ([A-Za-z0-9._-]+)/)(\s+)(\S.*)$")
drawn, columns = set(), set()
for ln in diagram:
    m = LEAF.match(ln)
    if m:
        drawn.add(m.group(2))
        columns.add(len(m.group(1)) + len(m.group(3)))

actual, dupes = set(), set()
for root, _dirs, files in os.walk(PRDS):
    if "prd.md" in files:
        rel = os.path.relpath(root, PRDS)
        if rel == ".":
            continue
        base = os.path.basename(rel)
        if base in actual:
            dupes.add(base)
        actual.add(base)

if dupes:
    fail(f"node directory names are no longer unique ({sorted(dupes)}); this "
         f"check compares the diagram by basename and needs rewriting")

for missing in sorted(actual - drawn):
    fail(f"the tree diagram does not list the node '{missing}/'")
for ghost in sorted(drawn - actual):
    fail(f"the tree diagram lists '{ghost}/', which is not a node on disk")

if len(columns) > 1:
    fail(f"tree-diagram descriptions start at {len(columns)} different "
         f"columns {sorted(columns)}; they are aligned art and must stay "
         f"aligned")

# --- the build order ---------------------------------------------------------
order = text.split("## Build order")
if len(order) != 2:
    fail("no single '## Build order' section")
    body = ""
else:
    body = order[1].split("## ")[0]

waves = {}
current = None
for ln in body.splitlines():
    m = re.match(r"^\s*(\d+)\.\s+(.*)$", ln)
    if m:
        current, rest = int(m.group(1)), m.group(2)
    elif current is not None and ln[:1].isspace() and ln.strip():
        rest = ln          # a wrapped continuation of the wave above
    else:
        current = None
        continue
    for tid in re.findall(r"[A-Z][0-9]?\.[0-9]+[a-z]?", rest):
        waves.setdefault(tid, []).append(current)

expected = {t["id"] for t in plan["tasks"]}
for tid in sorted(expected - set(waves)):
    fail(f"the build order does not place {tid}")
for tid in sorted(set(waves) - expected):
    fail(f"the build order places {tid}, which plan.json does not schedule")
for tid, ws in sorted(waves.items()):
    if len(ws) > 1:
        fail(f"{tid} appears in {len(ws)} waves {ws}; a task runs once")

# Every placement must sit strictly after every dependency plan.json gives it.
by_id = {t["id"]: t for t in plan["tasks"]}
for tid, ws in sorted(waves.items()):
    for dep in by_id.get(tid, {}).get("deps", []):
        if dep in waves and ws[0] <= waves[dep][0]:
            fail(f"{tid} is placed in wave {ws[0]}, at or before its "
                 f"dependency {dep} in wave {waves[dep][0]}")

# --- no box may be closed in the README -------------------------------------
for n, ln in enumerate(text.splitlines(), 1):
    if re.match(r"^\s*- \[[x~]\]", ln):
        fail(f"line {n} closes a box in README.md")

for f in fails:
    print("FAIL: " + f)
if not fails:
    print(f"OK ({len(actual)} nodes drawn, {len(waves)} tasks ordered)")
sys.exit(1 if fails else 0)
