#!/usr/bin/env bash
# probe harness — stage the repo's nushell tree into an isolated HOME, the way
# tests/shell-help.sh's mk_machine does, so introspection runs in a CONFIGURED
# shell (04-drift-check R1's constraint). Fixtures live in $M, made at run time,
# never under prds/.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
NUSHELL_SRC="$REPO/home/dot_config/nushell"
MODULES="pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help.nu"
M="${1:-$(mktemp -d)}"
mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
cp "$NUSHELL_SRC/env.nu" "$NUSHELL_SRC/config.nu" "$NUSHELL_SRC/dirstack.nu" "$NUSHELL_SRC/theme.nu" "$M/home/.config/nushell/"
for f in $MODULES; do cp "$NUSHELL_SRC/$f" "$M/home/.config/nushell/$f"; done
# help-check.nu is optional: absent before the build lands.
[ -f "$NUSHELL_SRC/help-check.nu" ] && cp "$NUSHELL_SRC/help-check.nu" "$M/home/.config/nushell/"
cp -R "$NUSHELL_SRC/help" "$M/home/.config/nushell/help"
for p in starship zoxide television; do printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"; done
echo "$M"
# nvim, seeded offline, so the check's headless spawn sees the REAL config.
NVIM_SRC="$REPO/home/dot_config/nvim"
SEED="/tmp/dc-nvim-seed"
if [ ! -d "$SEED" ]; then
  mkdir -p "$SEED/data/nvim/lazy"
  for name in $(python3 -c 'import json,sys;print("\n".join(json.load(open(sys.argv[1])).keys()))' "$NVIM_SRC/lazy-lock.json"); do
    [ -d "$HOME/.local/share/nvim/lazy/$name" ] && cp -R "$HOME/.local/share/nvim/lazy/$name" "$SEED/data/nvim/lazy/$name"
  done
fi
cp -R "$NVIM_SRC" "$M/home/.config/nvim"
mkdir -p "$M/home/.local/share"
cp -R "$SEED/data/nvim" "$M/home/.local/share/nvim"
