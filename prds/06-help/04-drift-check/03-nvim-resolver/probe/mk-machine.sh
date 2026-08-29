#!/usr/bin/env bash
# 03-nvim-resolver probe harness. Same shape as the parent's mk-machine.sh,
# with one difference that is the whole point: the nvim plugin store is seeded
# from an explicit SEED dir, so a machine can be built COMPLETE or DEGRADED
# (one plugin withheld) on purpose. Fixtures live under a run-time dir, never
# under prds/.
#   usage: mk-machine.sh <machine-dir> [plugin-to-withhold]
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
NUSHELL_SRC="$REPO/home/dot_config/nushell"
NVIM_SRC="$REPO/home/dot_config/nvim"
MODULES="pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help-check.nu help.nu"
M="${1:?machine dir}"; WITHHOLD="${2:-}"
rm -rf "$M"; mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
cp "$NUSHELL_SRC/env.nu" "$NUSHELL_SRC/config.nu" "$NUSHELL_SRC/dirstack.nu" "$NUSHELL_SRC/theme.nu" "$M/home/.config/nushell/"
for f in $MODULES; do cp "$NUSHELL_SRC/$f" "$M/home/.config/nushell/$f"; done
cp -R "$NUSHELL_SRC/help" "$M/home/.config/nushell/help"
for p in starship zoxide television; do printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"; done
cp -R "$NVIM_SRC" "$M/home/.config/nvim"
mkdir -p "$M/home/.local/share/nvim/lazy"
for name in $(ls "$HOME/.local/share/nvim/lazy"); do
  [ "$name" = "$WITHHOLD" ] && continue
  cp -R "$HOME/.local/share/nvim/lazy/$name" "$M/home/.local/share/nvim/lazy/$name"
done
echo "$M"
