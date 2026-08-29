#!/usr/bin/env bash
# run one nu -c inside a staged machine
set -u
M="$1"; shift
NU="$(command -v nu)"
exec /usr/bin/env -i HOME="$M/home" XDG_CONFIG_HOME="$M/home/.config" XDG_DATA_HOME="$M/home/.local/share" XDG_STATE_HOME="$M/home/.local/state" XDG_CACHE_HOME="$M/home/.cache" PATH="$M/bin:/usr/bin:/bin" \
  "$NU" --no-history --config "$M/home/.config/nushell/config.nu" --env-config "$M/home/.config/nushell/env.nu" -c "$@"
