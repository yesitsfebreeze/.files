#!/usr/bin/env bash
# spec05 — this ticket: record R3 as already discharged, with its evidence.
set -uo pipefail
F=prds/00-delivery/corrections/w0-4-s2-corrections/platform/prd.md
python3 - "$F" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
n = ' '.join(t.split())
low = n.lower()
ok = True
def chk(cond, msg):
    global ok
    if not cond:
        print("FAIL: " + msg); ok = False
chk(re.search(r'r3[^.]{0,200}discharg', low) is not None,
    "R3 must be recorded as already discharged, not quietly ticked")
chk('packages-installer' in low, "name the file the fzf reconciliation actually landed in")
chk('decisions/fzf' in low, "cite the decision node that discharged it")
chk(re.search(r'whether or not it is wanted', low) is None or 'no longer' in low or 'replaced' in low,
    "if the old parenthetical is quoted, say it is gone")
sys.exit(0 if ok else 1)
PY
