#!/usr/bin/env bash
# chezmoi run_after hook — macOS only. Make every EXTERNAL keyboard that
# Karabiner-Elements has registered disable the laptop's built-in keyboard while
# that external keyboard is connected. This lets you rest a physical keyboard on
# top of the MacBook without the built-in keys ghosting keystrokes underneath.
#
# SAFE BY DESIGN: Karabiner's `disable_built_in_keyboard_if_exists` only silences
# the built-in keyboard *while the external one is present* — unplug the external
# and the built-in instantly comes back, so you can never lock yourself out. Touch
# ID is a separate Secure Enclave sensor (not a HID key), so fingerprint unlock
# keeps working regardless.
#
# Karabiner OWNS karabiner.json — it rewrites the file whenever a device connects
# or a setting changes. So we PATCH it with jq each apply instead of letting
# chezmoi template the whole file (which would fight Karabiner and churn forever).
# Runs every `chezmoi apply` so a newly-seen external keyboard gets flagged on the
# next `just`. Idempotent: only writes when something actually changed.
set -uo pipefail

# Not macOS? Karabiner is mac-only; nothing to do on Linux/WSL.
[ "$(uname -s)" = "Darwin" ] || exit 0

warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }

cfg="$HOME/.config/karabiner/karabiner.json"

command -v jq >/dev/null 2>&1 || { warn "karabiner: jq missing — skipping built-in-keyboard rule"; exit 0; }

# Karabiner not configured yet (app never launched / permissions not granted).
# Once you open Karabiner-Elements, grant Input Monitoring + approve the driver
# extension, and connect the external keyboard, re-run `just` and this kicks in.
[ -f "$cfg" ] || { warn "karabiner: $cfg not found — launch Karabiner-Elements once, then re-run \`just\`"; exit 0; }

# For every keyboard device that is NOT the built-in keyboard, set
# disable_built_in_keyboard_if_exists = true. The built-in is excluded two ways so
# we never disable the laptop keyboard based on itself:
#   - is_built_in_keyboard != true   (Karabiner's own flag, when present)
#   - vendor_id != 0                 (the Apple-Silicon built-in reports vendor 0)
tmp="$(mktemp)"
if ! jq '
  (.profiles[]?.devices[]?
    | select(
        (.identifiers.is_keyboard == true)
        and ((.identifiers.is_built_in_keyboard // false) != true)
        and ((.identifiers.vendor_id // 0) != 0)
      )
    | .disable_built_in_keyboard_if_exists
  ) |= true
' "$cfg" > "$tmp" 2>/dev/null; then
  warn "karabiner: could not parse $cfg — left untouched"
  rm -f "$tmp"
  exit 0
fi

if cmp -s "$cfg" "$tmp"; then
  rm -f "$tmp"
else
  cp "$cfg" "$cfg.bak"
  mv "$tmp" "$cfg"
  log "karabiner: external keyboards now disable the built-in keyboard while connected (backup: $cfg.bak)"
fi
