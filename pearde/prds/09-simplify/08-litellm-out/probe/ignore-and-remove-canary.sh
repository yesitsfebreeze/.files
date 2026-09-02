#!/usr/bin/env bash
# Canary for 08-litellm-out Q1. Answers the two mechanism questions the three
# destinations rest on, in an isolated chezmoi source/dest pair built at run
# time. Nothing here touches the real $HOME. Run twice; exit 0 twice.
#
#   1. Answer (b): does a .chezmoiignore gate on a marker file work, both legs?
#   2. Answers (a) and (c): when the source file leaves home/, does the
#      deployed copy leave $HOME? (No. .chezmoiremove is what removes it.)
set -euo pipefail
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
mkdir -p "$FX/src/dot_local/bin" "$FX/dest"
printf '#!/bin/sh\necho cll\n' > "$FX/src/dot_local/bin/executable_cll"
printf 'keep me\n' > "$FX/src/dot_keepme"
cz() { chezmoi "$@" --source "$FX/src" --destination "$FX/dest" 2>/dev/null; }

# .chezmoiignore is ALWAYS a template. .chezmoi.destDir, not .chezmoi.homeDir:
# homeDir is the real user's home even under --destination, so a marker written
# into the fixture would never be seen. In production the two coincide.
cat > "$FX/src/.chezmoiignore" <<'EOF'
{{ if not (stat (joinPath .chezmoi.destDir ".litellm-optin")) }}
.local/bin/cll
{{ end }}
EOF

# --- leg 1: no marker -> ignored, not deployed; the rest of the tree lands ---
cz apply
[ "$(cz ignored)" = ".local/bin/cll" ] || { echo "FAIL: gate did not ignore"; exit 1; }
[ ! -e "$FX/dest/.local/bin/cll" ] || { echo "FAIL: ignored file was deployed"; exit 1; }
[ -f "$FX/dest/.keepme" ] || { echo "FAIL: unignored sibling missing"; exit 1; }
echo "ok   no marker: gated out, siblings unaffected"

# --- leg 2: marker present -> deployed ---
touch "$FX/dest/.litellm-optin"; cz apply
[ -x "$FX/dest/.local/bin/cll" ] || { echo "FAIL: marker did not opt in"; exit 1; }
echo "ok   marker present: deployed"

# --- leg 3: marker removed -> the deployed copy STAYS. Opting out of a
# .chezmoiignore gate is not a retirement; it only stops future machines. ---
rm "$FX/dest/.litellm-optin"; cz apply
[ -x "$FX/dest/.local/bin/cll" ] || { echo "FAIL: expected the copy to survive"; exit 1; }
echo "ok   marker removed: deployed copy survives — opt-out never retires"

# --- leg 4: source deleted -> the deployed copy STAYS on PATH ---
rm "$FX/src/.chezmoiignore" "$FX/src/dot_local/bin/executable_cll"; cz apply
[ -x "$FX/dest/.local/bin/cll" ] || { echo "FAIL: expected the shadow to survive"; exit 1; }
echo "ok   source deleted: deployed copy survives — a shadow on PATH"

# --- leg 5: .chezmoiremove is what reaches the machine ---
printf '.local/bin/cll\n' > "$FX/src/.chezmoiremove"; cz apply
[ ! -e "$FX/dest/.local/bin/cll" ] || { echo "FAIL: .chezmoiremove did not remove"; exit 1; }
echo "ok   .chezmoiremove: gone from the machine"
echo PASS
