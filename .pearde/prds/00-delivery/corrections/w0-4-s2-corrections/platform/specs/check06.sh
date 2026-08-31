#!/usr/bin/env bash
# spec06 — 05-platform epic: bring I3 down, re-word Purpose, make box 3 closable.
set -uo pipefail
F=prds/05-platform/prd.md
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

# --- the deleted machinery must not be described as live anywhere ---
for dead in ('.chezmoidata', 'packages.yaml', 'run_onchange', 'run_once', 'sha256'):
    chk(dead not in low, "deleted by 8fe3a71, cannot be specced as live: %s" % dead)

# --- what replaced it must be named ---
chk('install.sh' in low, "install.sh is the capability now; name it")
chk('8fe3a71' in low, "cite the commit that deleted the old pipeline")
chk('run_after_generate-shell-init.sh' in low,
    "the one script left in the live home/ must be named — 04-shell/01 depends on it")
chk('04-shell/01' in low, "the load-bearing link to 04-shell/01 must survive the rewrite")

# --- invariants: all four boxes keep their numbers; I3 is withdrawn, not deleted ---
for inv in ('I1', 'I2', 'I3', 'I4'):
    chk(re.search(r'\*\*%s\*\*' % inv, n) is not None,
        "%s must keep its number — other documents cite invariants by number" % inv)
chk(re.search(r'\*\*I3\*\*[^|]{0,400}?withdraw', n, re.I) is not None,
    "I3 must be marked withdrawn in place, with its reason")

# --- acceptance: still four boxes, none deleted wholesale (W0.3 restored them today) ---
try:
    sec = t.split('## Acceptance')[1].split('## Out of scope')[0]
except IndexError:
    sec = ''
boxes = re.findall(r'^- \[[ x~]\]', sec, re.M)
chk(len(boxes) == 4, "expected 4 acceptance boxes, found %d — replace the unclosable one, do not delete" % len(boxes))

# --- the replacement box must be satisfiable: a single edit to a file that exists ---
asec = ' '.join(sec.split()).lower()
chk('install.sh' in asec, "the 'adding one tool' box must be re-pointed at install.sh")
chk('packages.yaml' not in asec, "no acceptance box may still turn on packages.yaml")
chk(re.search(r'exits? 0|warn', asec) is not None, "the I4 hostile-machine box must survive")
sys.exit(0 if ok else 1)
PY
