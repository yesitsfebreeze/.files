#!/usr/bin/env bash
# Does .chezmoiremove keep deleting a path after the entry has served its
# purpose — i.e. would it eat a binary that a DIFFERENT project installs at the
# same path on every later `chezmoi apply`?
#
# Fixture is built at run time under $TMPDIR; nothing here touches the machine.
set -euo pipefail

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
SRC="$W/src"; DST="$W/dst"
mkdir -p "$SRC" "$DST/.local/bin"

printf '.local/bin/cll\n' > "$SRC/.chezmoiremove"
printf 'echo managed\n' > "$SRC/dot_profile"

run() { chezmoi apply --force --source "$SRC" --destination "$DST" --no-tty; }

# 1. the orphan chezmoi itself deployed
printf 'old\n' > "$DST/.local/bin/cll"
run
[ -e "$DST/.local/bin/cll" ] && { echo "FAIL: orphan survived first apply"; exit 1; }
echo "pass 1: .chezmoiremove removed the deployed orphan"

# 2. a FOREIGN file another project installed at the same path, later
printf 'from the router project\n' > "$DST/.local/bin/cll"
run
if [ -e "$DST/.local/bin/cll" ]; then
  echo "pass 2: the foreign install SURVIVED — the entry is one-shot"
else
  echo "pass 2: the foreign install was DELETED — the entry fires every apply"
fi

# 3. and again, to show it is not a first-run effect
printf 'from the router project\n' > "$DST/.local/bin/cll"
run
if [ -e "$DST/.local/bin/cll" ]; then
  echo "pass 3: survived"
else
  echo "pass 3: deleted again"
fi

# 4. and as a SYMLINK, which is how an external project would install itself
printf 'router\n' > "$W/real-cll"; chmod +x "$W/real-cll"
ln -sf "$W/real-cll" "$DST/.local/bin/cll"
run
if [ -L "$DST/.local/bin/cll" ] || [ -e "$DST/.local/bin/cll" ]; then
  echo "pass 4: symlink survived"
else
  echo "pass 4: symlink DELETED too"
fi
