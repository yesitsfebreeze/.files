#!/usr/bin/env python3
"""W0.4g spec03 — the totals and the critical path add up.

Nothing here is a hardcoded number. The critical path is recomputed from
`.mi/gantt/plan.json` on every run and compared with what the document
claims; the totals are checked against the document's own table rows. If the
schedule changes, this goes red — which is exactly what the file's fourth
acceptance criterion asks for ("The critical path is recomputed whenever a
task's dependencies change").
"""
import json
import os
import re
import subprocess
import sys

ROOT = subprocess.check_output(
    ["git", "rev-parse", "--show-toplevel"], text=True
).strip()
WB = os.path.join(ROOT, "prds/00-delivery/work-breakdown/prd.md")
PLAN = os.path.join(ROOT, ".mi/gantt/plan.json")

fails = []


def fail(msg):
    fails.append(msg)


text = open(WB, encoding="utf-8").read()
plan = json.load(open(PLAN, encoding="utf-8"))
sizeh = plan["sizeHours"]
tasks = {t["id"]: t for t in plan["tasks"]}

# --- the true critical path -------------------------------------------------
memo = {}


def longest(tid):
    if tid in memo:
        return memo[tid]
    t = tasks[tid]
    h = sizeh.get(t.get("size") or "", 0)
    best = (h, [tid])
    for dep in t["deps"]:
        if dep not in tasks:
            fail(f"plan.json: {tid} depends on unknown task {dep}")
            continue
        v, p = longest(dep)
        if v + h > best[0]:
            best = (v + h, p + [tid])
    memo[tid] = best
    return best


hours, path = max((longest(i) for i in tasks), key=lambda x: x[0])

# --- the section that must state it -----------------------------------------
sec = text.split("## Totals and the critical path")
if len(sec) != 2:
    fail("no single '## Totals and the critical path' section")
    body = ""
else:
    body = sec[1]

blocks = re.findall(r"```[a-z]*\n(.*?)```", body, re.S)
if not blocks:
    fail("the critical path is not stated in a fenced block")
else:
    stated = [s.strip() for s in re.split(r"->|→", blocks[0]) if s.strip()]
    if stated != path:
        fail("the stated critical path is not the longest path in plan.json\n"
             f"        stated:   {' -> '.join(stated)}\n"
             f"        computed: {' -> '.join(path)}")

# hours claimed after the block = the critical path; before it = the totals
pre, _, post = body.partition("```")
post = post.partition("```")[2]


def hours_in(s):
    return [float(m.replace(",", ".")) for m in
            re.findall(r"[≈~]\s*([0-9]+(?:[.,][0-9]+)?)\s*agent-hours", s)]


cp = hours_in(post)
if not cp:
    fail("no '≈ N agent-hours' figure follows the critical-path block")
elif abs(cp[0] - hours) > 0.05:
    fail(f"critical path is stated as {cp[0]} agent-hours; plan.json computes "
         f"{hours}")

# --- totals, checked against the document's own rows ------------------------
ID_RE = re.compile(r"^(W0\.\d+[a-z]?|[A-Z]\.\d+[a-z]?)$")
ids, doc_hours = set(), 0.0
for ln in text.splitlines():
    if not ln.startswith("|"):
        continue
    cells = [c.strip() for c in ln.strip().strip("|").split("|")]
    if cells and ID_RE.match(cells[0]):
        ids.add(cells[0])
        if len(cells) > 2 and cells[2] in sizeh:
            doc_hours += sizeh[cells[2]]

tot = hours_in(pre)
if not tot:
    fail("the totals paragraph states no '≈ N agent-hours' figure")
elif abs(tot[0] - doc_hours) > 5:
    fail(f"totals state ≈{tot[0]} agent-hours; the file's own Size cells sum "
         f"to {doc_hours}")

flat = re.sub(r"\s+", " ", pre)
m = re.search(r"([^.]*?)=\s*\*\*(\d+) tasks\*\*", flat)
if not m:
    fail("the totals paragraph does not state 'a <track> + b <track> ... "
         "= **N tasks**'")
else:
    addends = [int(x) for x in re.findall(r"(\d+)\s*[A-Za-z]", m.group(1))]
    claimed = int(m.group(2))
    if sum(addends) != claimed:
        fail(f"the totals arithmetic does not add up: {' + '.join(map(str, addends))} "
             f"= {sum(addends)}, stated {claimed}")
    if claimed != len(ids):
        fail(f"totals claim {claimed} tasks; the file's tables hold "
             f"{len(ids)} task rows")

# --- provenance and dead prose ---------------------------------------------
if "plan.json" not in body:
    fail("the section does not name plan.json as the source of the "
         "computation")
norm = re.sub(r"\s+", " ", text)
DEAD = {
    "hangs off S.1":
        "plan.json has H.1 with no dependencies at all, so H.2 hangs off "
        "nothing in Track S",
    "≈ 26 agent-hours":
        "the figure the backlog filed as arithmetically wrong",
    "130–145 agent-hours":
        "the old total, computed over 49 tasks",
}
for dead, why in DEAD.items():
    if dead in norm:
        fail(f"stale claim survives: {dead!r} — {why}")

for n, ln in enumerate(text.splitlines(), 1):
    if re.match(r"^\s*- \[[x~]\]", ln):
        fail(f"line {n} closes a box in work-breakdown/prd.md")

for f in fails:
    print("FAIL: " + f)
if not fails:
    print(f"OK (critical path {hours}h over {len(path)} tasks; "
          f"{len(ids)} rows, {doc_hours}h)")
sys.exit(1 if fails else 0)
