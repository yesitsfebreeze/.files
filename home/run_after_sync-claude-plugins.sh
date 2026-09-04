#!/usr/bin/env bash
# chezmoi run_after — make the plugin set identical across every Claude login
# profile. Plugins are installed once, globally (~/.claude/plugins is symlinked
# into every profile), but `enabledPlugins` and `extraKnownMarketplaces` live in
# each profile's own settings.json, which `_claude_share` COPIES at creation —
# so a plugin enabled in one login stays invisible to the others. This unions
# both maps across the root and every profile and writes the union back to all.
#
# Union means enabled-anywhere wins: there is deliberately no per-profile
# disable. Everything else in settings.json — model, statusLine, permissions —
# and the login itself (oauthAccount in .claude.json, credentials in the
# Keychain) is left untouched; same rule as install-claude-hooks.
set -u

log()  { printf '\033[1;34m::\033[0m claude-plugins: %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m claude-plugins: %s\n' "$*" >&2; }

if ! command -v jq > /dev/null 2>&1; then
    warn "jq is not on PATH — plugin sets stay unsynced (install jq, then re-run \`chezmoi apply\`)"
    exit 0
fi

files=()
for f in "$HOME/.claude/settings.json" "$HOME"/.claude/*/settings.json; do
    [ -f "$f" ] || continue
    jq -e . "$f" > /dev/null 2>&1 || { warn "~${f#$HOME} is not valid JSON — skipped"; continue; }
    files+=("$f")
done
[ "${#files[@]}" -ge 2 ] || exit 0

union=$(jq -s '{
    enabledPlugins: (map(.enabledPlugins // {}) | add // {}
        | with_entries(.value = true)),
    extraKnownMarketplaces: (map(.extraKnownMarketplaces // {}) | add // {})
}' "${files[@]}") || { warn "jq failed computing the union — nothing written"; exit 0; }

for f in "${files[@]}"; do
    out=$(jq --argjson u "$union" '. + $u' "$f") || { warn "jq failed on ~${f#$HOME} — left alone"; continue; }
    [ "$out" = "$(cat "$f")" ] && continue
    tmp=$(mktemp "${f}.XXXXXX") || { warn "mktemp failed for ~${f#$HOME}"; continue; }
    printf '%s\n' "$out" > "$tmp" && mv "$tmp" "$f" \
        && log "synced ~${f#$HOME}" \
        || { warn "write failed for ~${f#$HOME}"; rm -f "$tmp"; }
done

exit 0
