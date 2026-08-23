#!/bin/bash
# The composite gate for W0.4c (03-editor corrections).
#
# It does not restate any check. It reads the `verify:` line out of every
# specNN.md in this directory and runs it, so the gate cannot drift from the
# specs — editing a spec's verify edits the gate.
#
# Usage: bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh
# Exit 0 only when every spec's verify exits 0.
#
# Expected result before the specs are applied: every one RED. That is the
# point — they were each proven RED individually on 2026-08-21 before being
# written down.

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(git -C "$DIR" rev-parse --show-toplevel)" || exit 1

rc=0
shopt -s nullglob
for spec in "$DIR"/spec*.md; do
  name=$(basename "$spec" .md)

  # The verify line is `verify: ` followed by the command in backticks.
  # Strip the label and the surrounding backticks; the command itself is a
  # single line by construction.
  cmd=$(grep -m1 '^verify: ' "$spec" | sed 's/^verify: //')
  cmd=${cmd#\`}
  cmd=${cmd%\`}

  if [ -z "$cmd" ]; then
    echo "FAIL  $name: no verify: line found"
    rc=1
    continue
  fi

  out=$(eval "$cmd" 2>&1)
  st=$?
  if [ $st -eq 0 ]; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    printf '%s\n' "$out" | sed 's/^/        /'
    rc=1
  fi
done

echo
if [ $rc -eq 0 ]; then
  echo "OK — every spec in this ticket verifies."
else
  echo "RED — see above. Each block names the spec whose verify failed."
fi
exit $rc
