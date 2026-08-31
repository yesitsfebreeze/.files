#!/usr/bin/env bash
# spec03 — 02-package-provisioning: re-purpose, re-rate, re-cut acceptance against install.sh.
set -uo pipefail
F=prds/05-platform/02-package-provisioning/prd.md
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
m = re.search(r'·\s*C\s*(\d+)\s*·\s*U\s*(\d+)\s*·', n)
chk(m is not None, "header must carry single-number C and U (contract forbids ranges)")
if m:
    chk(int(m.group(1)) < 8, "C must come down from 8 — the 559-line renderer it rated is deleted")
chk('install.sh' in low, "the capability actually being ported is install.sh; name it")
chk('packages.yaml' not in low, "packages.yaml was deleted by 8fe3a71; it cannot be a source of truth")
chk('run_onchange' not in low, "the run_onchange installer no longer exists")
chk('sha256' not in low, "the sha256 re-run gate went with the run_onchange template")
chk('8fe3a71' in low, "cite the commit that deleted the machinery this node used to spec")
chk('0.11' in low, "the Neovim floor is one of the two properties kept; it must survive")
chk(re.search(r'exits? 0|warns? and continu|never abort', low) is not None,
    "never-abort is the other property kept; it must survive as a checkable box")
chk('declarative' not in low, "'declarative list' describes the deleted machinery")
sys.exit(0 if ok else 1)
PY
