#!/usr/bin/env bash
# Canary: does .chezmoiremove reach a path chezmoi has NO state entry for?
# The PRD asks for exactly this before any spec is written.
# Run from the chezmoi source repo root (/Users/feb/dev/dotfiles).
set -uo pipefail

CABLE="$HOME/.config/television/cable"
CANARY="$CABLE/zz-canary-probe.toml"
REMOVE="home/.chezmoiremove"
LINE=".config/television/cable/zz-canary-probe.toml"

say() { printf '\n== %s\n' "$1"; }

say "0. state entry for the canary path BEFORE (expect none)"
chezmoi state dump 2>/dev/null | grep -c "zz-canary-probe" || true

say "1. plant the canary"
printf '[metadata]\nname = "zz-canary-probe"\n' > "$CANARY"
ls -l "$CANARY"

say "2. state entry for the canary path AFTER planting (expect 0 = never managed)"
chezmoi state dump 2>/dev/null | grep -c "zz-canary-probe" || true

say "3. append the tombstone to $REMOVE"
cp "$REMOVE" "$REMOVE.canarybak"
printf '%s\n' "$LINE" >> "$REMOVE"
tail -2 "$REMOVE"

say "4. scoped apply naming the TARGET path (not .chezmoiremove), no --force"
chezmoi apply "$CANARY" </dev/null
echo "exit=$?"

say "5. did it go?"
if [ -e "$CANARY" ]; then echo "CANARY STILL PRESENT"; else echo "CANARY GONE"; fi

say "6. restore $REMOVE"
mv "$REMOVE.canarybak" "$REMOVE"
rm -f "$CANARY"
tail -1 "$REMOVE"
