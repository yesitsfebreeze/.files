#!/usr/bin/env python3
"""W0.4g spec02 — the work-breakdown task tables are complete and unduplicated.

Content-based, not grep-based: every assertion is derived from
`.mi/gantt/plan.json` (the schedule of record) and from the file's own table
structure, so it does not go stale when a sibling lane rewords a sentence.

Run from anywhere; resolves paths from the git root.
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

# Board nodes that exist but are not yet scheduled in plan.json. S.9 lived
# here until the conductor scheduled it on 2026-08-21; the set is kept so the
# next unscheduled node can be named rather than silently missed.
UNSCHEDULED = {}

ID_RE = re.compile(r"^(W0\.\d+[a-z]?|[A-Z]\.\d+[a-z]?)$")
HDR_RE = re.compile(r"^\|\s*ID\s*\|")

fails = []


def fail(msg):
    fails.append(msg)


text = open(WB, encoding="utf-8").read()
lines = text.splitlines()
plan = json.load(open(PLAN, encoding="utf-8"))

# --- rows, and the section each lives in -----------------------------------
rows = {}          # id -> list of (lineno, cells)
section = "(top)"
headers = {}       # section -> count of "| ID |" header rows
for i, ln in enumerate(lines, 1):
    if ln.startswith("## "):
        section = ln[3:].strip()
        headers.setdefault(section, 0)
    if HDR_RE.match(ln):
        headers[section] = headers.get(section, 0) + 1
    if ln.startswith("|") and not HDR_RE.match(ln):
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if cells and ID_RE.match(cells[0]):
            rows.setdefault(cells[0], []).append((i, cells, section))

# --- 1. one header row per section ------------------------------------------
for sec, n in headers.items():
    if n > 1:
        fail(f"section '{sec}' carries {n} '| ID |' header rows, expected 1")

# --- 2. no duplicated task row ----------------------------------------------
for tid, occ in rows.items():
    if len(occ) > 1:
        fail(f"task {tid} has {len(occ)} rows (lines "
             f"{', '.join(str(o[0]) for o in occ)})")

# --- 3. every scheduled feature task has a row ------------------------------
scheduled = {t["id"]: t for t in plan["tasks"]}
for tid, t in sorted(scheduled.items()):
    if t["node"].startswith("00-delivery"):
        continue          # the delivery PRDs are the plan, not planned work
    if tid not in rows:
        fail(f"no table row for {tid} ({t['node']}) — the file's own "
             f"acceptance requires every feature PRD to appear exactly once")

# --- 4. board nodes not yet in plan.json still need a row -------------------
for tid, node in sorted(UNSCHEDULED.items()):
    if tid not in rows:
        fail(f"no table row for {tid} ({node}) — the node exists on the "
             f"board even though plan.json has not scheduled it yet")

# --- 5. removed tasks must not come back ------------------------------------
for tid in ("T.5", "D.1", "D.1a"):
    if tid in rows:
        fail(f"{tid} is a removed task and must not have a table row")
if re.search(r"burrito", text, re.I) and not re.search(
        r"burrito", "\n".join(
            ln for ln in lines if not ln.startswith("|")), re.I):
    fail("burrito survives only inside a table row; it belongs in the prose "
         "record of its removal, not in a task")

# --- 6. M-18: the legacy conf/ layout is gone -------------------------------
for i, ln in enumerate(lines, 1):
    if re.search(r"(?<![\w/.-])conf/", ln):
        fail(f"line {i} still targets the legacy `conf/` layout: {ln.strip()}")

# --- 6b. the Depends-on column is gone, and plan.json is cross-linked -------
# Decided 2026-08-21 (user): 44 of 44 dependency cells had rotted against
# plan.json, which SYSTEM.md already declares owns the schedule. Deleting the
# column removes the drift by construction; re-syncing it only resets the
# clock.
for i, ln in enumerate(lines, 1):
    if HDR_RE.match(ln) and re.search(r"\|\s*Depends on\s*\|", ln):
        fail(f"line {i} still has a 'Depends on' column; the dependency graph "
             f"lives in plan.json and is cross-linked, not restated")
if not re.search(r"\]\(\.\./\.\./\.\./gantt/plan\.json\)", text):
    fail("the file does not cross-link ../../../gantt/plan.json, which now "
         "holds the dependency graph the deleted column used to restate")

# --- 6c. the acceptance box about that column was reworded, not orphaned ----
acc = re.search(r"^## Acceptance\n(.*?)(?=^## )", text, re.S | re.M)
if not acc:
    fail("no '## Acceptance' section")
else:
    boxes = re.findall(r"^- \[ \](.*?)(?=^- \[|\Z)", acc.group(1), re.S | re.M)
    if len(boxes) != 4:
        fail(f"'## Acceptance' holds {len(boxes)} open boxes, expected 4")
    flat = " ".join(re.sub(r"\s+", " ", b) for b in boxes)
    if "exist in the other tasks' rows" in flat:
        fail("an acceptance box still requires dependency edges to appear in "
             "the task rows, which no longer carry them — reword it, do not "
             "leave a box that cannot be satisfied")
    if "S.7 → H.2" not in flat:
        fail("the reworded box dropped the invented-edge example (S.7 → H.2); "
             "that is the hard-won why and it stays")
    if "plan.json" not in flat:
        fail("no acceptance box names plan.json as where the dependency graph "
             "now lives")

# --- 7. C.4 and P.2 name their real files -----------------------------------
if "C.4" in rows:
    files_cell = rows["C.4"][0][1][3] if len(rows["C.4"][0][1]) > 3 else ""
    for want in ("capsule", "wezterm.lua", "recents"):
        if want not in files_cell:
            fail(f"C.4 Files cell does not name '{want}': {files_cell!r} "
                 f"(plan.json has capsule/capsule-tool/, "
                 f"home/dot_config/wezterm/wezterm.lua, "
                 f"home/dot_config/capsule/recents.nuon)")

p2 = rows.get("P.2")
if p2:
    cell = p2[0][1][3] if len(p2[0][1]) > 3 else ""
    if "install.sh" not in cell:
        fail(f"P.2 Files cell is {cell!r}; commit 8fe3a71 deleted "
             f".chezmoidata/packages.yaml and the run_onchange installer and "
             f"replaced them with install.sh (plan.json agrees)")
for i, ln in enumerate(lines, 1):
    if ln.startswith("|") and re.search(r"packages\.yaml|run_onchange", ln):
        fail(f"line {i} still names a file commit 8fe3a71 deleted: "
             f"{ln.strip()[:70]}")

# --- 8. no row id invented out of thin air ----------------------------------
known = set(scheduled) | set(UNSCHEDULED)
for tid in sorted(rows):
    if tid not in known:
        fail(f"table row {tid} matches no task in plan.json and no known "
             f"unscheduled node")

# --- 9. no box was closed ---------------------------------------------------
for i, ln in enumerate(lines, 1):
    if re.match(r"^\s*- \[[x~]\]", ln):
        fail(f"line {i} closes a box in work-breakdown/prd.md")

for f in fails:
    print("FAIL: " + f)
if not fails:
    print("OK")
sys.exit(1 if fails else 0)
