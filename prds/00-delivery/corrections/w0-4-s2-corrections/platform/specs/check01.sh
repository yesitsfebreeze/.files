#!/usr/bin/env bash
# spec01 — managed-config: burrito strip (W0.4f R1) + corrected L-12 (W0.4f R4).
# Content-based: the file is normalised to one whitespace-collapsed string first,
# so a phrase that straddles the 78-column wrap still matches.
set -uo pipefail
F=prds/05-platform/01-deploy-mechanism/managed-config/prd.md
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
chk('burrito' not in low, "R1: 'burrito' still appears in the managed-surface list")
chk('brr' not in re.sub(r'[^a-z]', ' ', low).split(), "R1: 'brr' still appears")
chk('background.png' in low, "R4: background.png — the one dead file actually in the live source — is not recorded")
chk('solo-window' in low, "R4: solo-window is not addressed at all")
chk('wsl-clip-prime' in low, "R4: wsl-clip-prime is not addressed at all")
chk('.local/share/chezmoi' in low, "R4: the stale clone must be named as the tree those files live in")
chk('/users/feb/dev/.files' in low, "R4: the live chezmoi source path is not named")
chk('wallpaper-opacity' in low, "R4: background.png's drop must cross-link decision 5(a), not restate a verdict")
chk(re.search(r'\bl-12\b', low) is not None, "R4: the backlog item being corrected is not cited by id")
sys.exit(0 if ok else 1)
PY
