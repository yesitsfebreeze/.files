#!/usr/bin/env bash
# spec02 — 01-deploy-mechanism R6: drop the chezmoi three-stage framing, keep the reason.
set -uo pipefail
F=prds/05-platform/01-deploy-mechanism/prd.md
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
chk(re.search(r'\*\*R6\*\*', n) is not None, "R6 must still exist — it is narrowed, not deleted")
chk('run_onchange' not in low, "the run_onchange stage no longer exists in the live source; the framing must go")
chk('run_once_before' not in low, "the run_once_before stage no longer exists in the live source; the framing must go")
chk('run_after_generate-shell-init.sh' in low, "the one script that does exist in the live home/ must be named")
chk('path' in low, "the load-bearing reason (a tool installed this run is not yet on PATH) must survive")
chk('8fe3a71' in low, "cite the commit that removed the stages, so the change is auditable")
chk('install.sh' in low, "installation now happens in install.sh; say where it moved to")
chk('shellenv' in low, "keep the canonical case for the PATH re-resolve (brew shellenv)")
sys.exit(0 if ok else 1)
PY
