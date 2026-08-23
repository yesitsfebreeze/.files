#!/usr/bin/env bash
# spec07 — homebrew-bootstrap: same mechanism swap; the capability survives, the stage does not.
set -uo pipefail
F=prds/05-platform/02-package-provisioning/homebrew-bootstrap/prd.md
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
chk(re.search(r'\*\*R3\*\*', n) is not None, "R3 must survive — the capability is kept, only its mechanism moved")
chk('run_once' not in low, "the run_once_before stage was deleted by 8fe3a71")
chk('install.sh' in low, "Homebrew bootstrap now lives in install.sh; name it")
chk('shellenv' in low, "the PATH re-resolve reason is the expensive part and must survive")
chk('8fe3a71' in low, "cite the commit that moved it, so the change is auditable")
# the node title must no longer promise a chezmoi stage
title = re.search(r'^#\s+(.+)$', t, re.M)
chk(title is not None and 'run_once' not in title.group(1).lower(),
    "the heading still names a chezmoi stage that does not exist")
sys.exit(0 if ok else 1)
PY
