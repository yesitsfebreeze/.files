#!/usr/bin/env bash
# Emit OSC 11 to force the terminal background to background-override from
# config.toml, overriding the scheme's base00 that tinted-shell just applied via
# its own OSC 11. Run right after any palette retint (config.nu shell-start, the
# tinty apply hook). No-op when the key is absent/blank, so the scheme's own
# background stands. stdout IS the retint — must reach the tty, never redirect it.
CFG="$HOME/.config/tinted-theming/tinty/config.toml"
bg=$(grep -iE '^[[:space:]]*background-override[[:space:]]*=[[:space:]]*"#[0-9A-Fa-f]{6}"' "$CFG" 2>/dev/null \
    | head -n1 | sed -E 's/.*"#([0-9A-Fa-f]{6})".*/\1/' | tr 'A-F' 'a-f')
[[ -n "$bg" ]] && printf '\033]11;#%s\033\\' "$bg"
exit 0
