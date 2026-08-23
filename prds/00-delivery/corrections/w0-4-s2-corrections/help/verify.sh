#!/usr/bin/env bash
# verify.sh — the composite gate for W0.4 s2 (`06-help` corrections).
#
# Usage:  bash prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh
#         bash …/help/verify.sh <spec.md> [<spec.md> …]   # ad-hoc, for testing
#
# IT RESTATES NO CHECK. Like its sibling `../editor/specs/verify-all.sh`, this
# runner reads the checks out of the specs and executes them, so the gate
# cannot drift from the specs it gates — editing a spec's `## verify` fence
# edits the gate. The difference is only in where the command lives: the editor
# ticket put one command in each spec's frontmatter `verify:` key, this one has
# them in fenced blocks under a `## verify` heading, because they contain both
# `'` and `"` and will not survive a YAML scalar intact.
#
# A block that yields nothing is a FAIL, not a silent pass: a runner that
# extracted zero blocks would otherwise exit 0 while proving nothing, which is
# the exact failure this family of corrections exists to stop.
#
# `specs/spec05.md` is excluded BY NAME: its first fenced block is a spent
# one-shot assertion pinned to a marker convention the board retired (see that
# file's `## Spent proof` section), and its other two blocks print rather than
# assert. Including it would make this gate red for a reason that is recorded
# rather than fixable.
#
# The repo root is derived from this script's own location, five levels up, and
# never from a marker directory in the tree — the previous generation of these
# gates walked up from $PWD looking for `.mi`, and resolved to `/` the day that
# directory was deleted.
#
# Exit 0 only when every extracted block exits 0. Reads only; never writes.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 1

if [ "$#" -gt 0 ]; then
  specs=("$@")
else
  specs=("$DIR"/specs/spec01.md "$DIR"/specs/spec02.md \
         "$DIR"/specs/spec03.md "$DIR"/specs/spec04.md)
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

rc=0
total=0
for spec in "${specs[@]}"; do
  name="$(basename "$spec" .md)"
  if [ ! -f "$spec" ]; then
    echo "FAIL  $name: no such file: $spec"
    rc=1
    continue
  fi

  # Extract every fenced block inside this file's `## verify` section. The
  # section runs from the `## verify` heading to the next heading of the same
  # or higher level.
  rm -rf "$WORK/blocks"
  mkdir -p "$WORK/blocks"
  SPEC="$spec" OUT="$WORK/blocks" python3 - <<'PY'
import os, re, pathlib
t = pathlib.Path(os.environ["SPEC"]).read_text(encoding="utf-8")
out = pathlib.Path(os.environ["OUT"])
m = re.search(r"(?m)^(#{1,6})[ \t]+verify[ \t]*$", t)
if m:
    lvl = len(m.group(1))
    rest = t[m.end():]
    nxt = re.search(r"(?m)^#{1,%d}[ \t]" % lvl, rest)
    body = rest[:nxt.start()] if nxt else rest
    for i, blk in enumerate(re.findall(r"(?ms)^```[^\n]*\n(.*?)^```[ \t]*$", body), 1):
        (out / f"{i:02d}.sh").write_text(blk, encoding="utf-8")
PY

  n=0
  for blk in "$WORK"/blocks/*.sh; do
    [ -e "$blk" ] || break
    n=$((n + 1))
    total=$((total + 1))
    label="$name block $n"
    if out="$(bash -c "$(cat "$blk")" 2>&1)"; then
      echo "PASS  $label"
    else
      echo "FAIL  $label"
      printf '%s\n' "$out" | sed 's/^/        /'
      rc=1
    fi
  done

  if [ "$n" = 0 ]; then
    echo "FAIL  $name: 0 blocks extracted from a '## verify' section"
    rc=1
  fi
done

echo
echo "blocks=$total"
if [ "$rc" = 0 ]; then
  echo "OK — every fenced verify block in this ticket exits 0."
else
  echo "RED — see above."
fi
exit "$rc"
