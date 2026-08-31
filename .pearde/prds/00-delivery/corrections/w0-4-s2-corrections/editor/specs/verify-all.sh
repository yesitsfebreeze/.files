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
ran=0
skipped=0
shopt -s nullglob
for spec in "$DIR"/spec*.md; do
  name=$(basename "$spec" .md)

  # The verify line is `verify: ` followed by the command in backticks.
  # Strip the label and the surrounding backticks; the command itself is a
  # single line by construction.
  cmd=$(grep -m1 '^verify: ' "$spec" | sed 's/^verify: //')
  cmd=${cmd#\`}
  cmd=${cmd%\`}

  # Blank-verify guard. `verify: ""` is the board's encoding for a spent
  # (retired) verify — mi-rooted-verify-commands spec02 blanked seven specs
  # in this directory to exactly that. The value survives the sed and the
  # backtick strip as the TWO QUOTE CHARACTERS `""` (there is no backtick to
  # strip), so `[ -z "$cmd" ]` alone cannot catch it: the guard passed, the
  # shell evaluated `""` — the empty command name — and reported 127
  # `: command not found` for specs that say nothing about the tree. Do not
  # "simplify" this back to `[ -z ]` only. Also: `grep -m1` MUST stay
  # first-match — each blanked spec keeps a byte-identical copy of its
  # retired command in a `## Spent proof` fence further down the file, and
  # first-match semantics are what keep that copy inert.
  if [ "$cmd" = '""' ]; then
    echo "SKIP  $name: verify is blanked (spent — see its ## Spent proof)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ -z "$cmd" ]; then
    echo "FAIL  $name: no verify: line found"
    rc=1
    continue
  fi

  ran=$((ran + 1))
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

# Both counts always print: a summary that hides the skip count would report
# "N specs, N green" after silently passing over blanked ones — the same
# defect in the opposite direction. All-skipped is a legal green: every
# guard in this directory can legitimately be spent.
echo
if [ $rc -eq 0 ]; then
  echo "OK — $ran ran green, $skipped skipped (blanked)."
else
  echo "RED — $ran ran, $skipped skipped; see above. Each block names the spec whose verify failed."
fi
exit $rc
