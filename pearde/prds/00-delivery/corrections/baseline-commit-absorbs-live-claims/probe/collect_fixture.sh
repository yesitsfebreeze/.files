#!/usr/bin/env bash
# Does `collect` already refuse a cross-claim path? Two nodes, two claims,
# one shared footprint path, built in a directory made at run time and thrown
# away — the real tool, not an argument about it.
#
# Nothing here touches this repo: the fixture is its own git repository under
# $TMPDIR, and `collect --dry` stages nothing anywhere.
set -eu
PEARDE=/Users/feb/dev/dotfiles/.claude/skills/pearde/resources/pearde.py
W=$(mktemp -d)/fixture; mkdir -p "$W"; cd "$W"
trap 'rm -rf "$(dirname "$W")"' EXIT

git init -q .; git config user.name t; git config user.email t@t
mkdir -p .pearde/prds/alpha/specs .pearde/prds/beta src
printf 'language: English\n' > .pearde/settings.md
for n in alpha beta; do
  if [ "$n" = beta ]; then st=analyzing; else st=claimed; fi
  cat > ".pearde/prds/$n/prd.md" <<EOF
---
state: $st
priority: 10
complexity: 10
needs:
footprint:
  - src/shared.txt
verify: ""
claim: worker-$n 2026-09-02 12:00
---

# $n

## Acceptance

- [x] it works
EOF
done
cat > .pearde/prds/alpha/specs/spec01.md <<'EOF'
---
complexity: 5
footprint:
  - src/shared.txt
---

# spec01

## Acceptance

- [x] shared.txt says edited

## Verify and Proof

```sh
grep -q edited src/shared.txt
```
EOF
printf '# report\n\nVerdict: DONE\n\ndone.\n' > .pearde/prds/alpha/report.md

echo base > src/shared.txt
git add -A; git commit -qm base
echo edited > src/shared.txt

# `collect` exits non-zero when it refuses, which is the answer being asked
# for — so the status is captured, never allowed to kill the run.
out=$(python3 "$PEARDE" collect alpha --board "$W/.pearde" --dry 2>&1) || rc=$?
echo "$out"
echo "collect exit: ${rc:-0}"
case "$out" in
  *"is in beta's footprint too"*) echo "PASS: collect refuses the cross-claim path" ;;
  *) echo "FAIL: collect said nothing about beta's claim"; exit 1 ;;
esac
