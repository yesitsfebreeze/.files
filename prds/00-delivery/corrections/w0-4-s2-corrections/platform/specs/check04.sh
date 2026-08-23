#!/usr/bin/env bash
# spec04 — packages-installer: burrito strip (W0.4f R2) + re-spec R1/R2/R4 against install.sh.
set -uo pipefail
F=prds/05-platform/02-package-provisioning/packages-installer/prd.md
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
chk('burrito' not in low, "R2: 'burrito' still appears in the required set")
chk('brr' not in re.sub(r'[^a-z]', ' ', low).split(), "R2: 'brr' still appears in the required set")
chk('install.sh' in low, "the installer being specced is install.sh")
chk('packages.yaml' not in low, "packages.yaml was deleted by 8fe3a71")
chk('sha256' not in low, "the run_onchange sha256 gate went with the template")
chk(re.search(r'withdraw', low) is not None,
    "R1 and R2 are withdrawn on the record, not silently deleted — the numbers are cited elsewhere")
chk('fzf' in low, "R3 is discharged and must stay discharged: fzf remains in the required set")
chk('decisions/fzf' in low, "the fzf exception must keep its link to the decision node")
chk('0.11' in low, "the Neovim floor survives")
chk(re.search(r'\*\*R5\*\*', n) is not None, "never-abort (R5) survives")
chk(re.search(r'\*\*R7\*\*', n) is not None, "the required set (R7) survives")
sys.exit(0 if ok else 1)
PY
