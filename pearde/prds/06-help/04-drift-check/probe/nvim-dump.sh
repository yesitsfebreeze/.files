#!/usr/bin/env bash
# probe — stage the repo's nvim config with a seeded offline plugin store and
# dump nvim_get_keymap for every mode as JSON. R2's introspection, measured.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
NVIM_SRC="$REPO/home/dot_config/nvim"
ROOT="${1:-/tmp/dc-nvim}"
SEED="/tmp/dc-nvim-seed"
if [ ! -d "$SEED" ]; then
  mkdir -p "$SEED/data/nvim/lazy"
  for name in $(python3 -c 'import json,sys;print("\n".join(json.load(open(sys.argv[1])).keys()))' "$NVIM_SRC/lazy-lock.json"); do
    [ -d "$HOME/.local/share/nvim/lazy/$name" ] && cp -R "$HOME/.local/share/nvim/lazy/$name" "$SEED/data/nvim/lazy/$name"
  done
fi
rm -rf "$ROOT"; mkdir -p "$ROOT/config"
cp -R "$NVIM_SRC" "$ROOT/config/nvim"
cp -R "$SEED/data" "$ROOT/data"
DUMP="$ROOT/maps.json"
env HOME="$ROOT" XDG_CONFIG_HOME="$ROOT/config" XDG_DATA_HOME="$ROOT/data" \
    XDG_STATE_HOME="$ROOT/state" XDG_CACHE_HOME="$ROOT/cache" DC_DUMP="$DUMP" \
    nvim --headless -c 'lua local o={} for _,m in ipairs({"n","v","x","i","o","t","c","s"}) do for _,k in ipairs(vim.api.nvim_get_keymap(m)) do o[#o+1]={mode=m,lhs=k.lhs,desc=k.desc,buffer=0} end end local f=io.open(vim.env.DC_DUMP,"w") f:write(vim.json.encode(o)) f:close()' -c 'qa!' </dev/null >"$ROOT/out" 2>"$ROOT/err"
echo "rc=$? dump=$DUMP"; [ -s "$ROOT/err" ] && head -5 "$ROOT/err"
python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print("maps:",len(d));import collections;print(collections.Counter(x["mode"] for x in d))' "$DUMP"
