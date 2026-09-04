#!/usr/bin/env bash
# ask-whether-the-tool-already-refuses, run against the PreToolUse Bash hook.
# Two nodes, one shared path, node-a claimed — does `guard.py pre` deny a
# `git add` of the shared path from a session with no claim on it?
# Usage: bash claim-staging-fixture.sh
set -euo pipefail
GUARD=/Users/feb/dev/dotfiles/.claude/skills/pearde/resources/guard.py
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q .
git config user.email test@test.com
git config user.name test
mkdir -p .pearde/prds/node-a .pearde/prds/node-b shared
cat > .pearde/prds/node-a/prd.md <<'EOF'
---
state: claimed
origin: requested
priority: 0
complexity: 5
blast-radius: low
claim: worker-a 2026-09-04 00:00
footprint:
  - shared/thing.txt
---
# node a
EOF
cat > .pearde/prds/node-b/prd.md <<'EOF'
---
state: analyzing
origin: requested
priority: 0
complexity: 5
blast-radius: low
---
# node b
EOF
echo original > shared/thing.txt
git add -A && git commit -q -m init
echo "changed by node-b" > shared/thing.txt

out=$(echo '{"tool_name":"Bash","tool_input":{"command":"git add shared/thing.txt"},"cwd":"'"$TMP"'"}' \
  | PEARDE_GUARD_STATE="$(mktemp -d)" python3 "$GUARD" pre 2>&1)

if [ -z "$out" ]; then
  echo "RESULT: not refused — guard.py pre allowed staging a path a live claim holds"
  exit 1
else
  echo "RESULT: refused — $out"
  exit 0
fi
