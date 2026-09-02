#!/usr/bin/env bash
# chezmoi run_after — wire Claude Code's state hooks into every profile's
# settings.json, so a Claude pane tints its window digit. The script they call
# is ~/.local/bin/tmux-claude-state. See internals/tmux for the colours.
#
# TRAP: these files are NOT chezmoi-managed and must not become so. They hold
# the statusline, the theme, the enabled plugins and whatever the human changed
# since — the same reason register-mcp shells out instead of writing
# ~/.claude.json itself. So the block is MERGED in, and only entries naming
# tmux-claude-state are ever replaced.
#
# TRAP: EVERY profile, not just the root. `cc` runs Claude under
# CLAUDE_CONFIG_DIR=~/.claude/<profile>, and `_claude_share` COPIES settings.json
# into a profile at creation rather than symlinking it — so a hooks block written
# only to the root file reaches no session that `cc` ever starts. A profile is a
# directory holding a settings.json, the same rule claude.nu enumerates by.
set -u

log()  { printf '\033[1;34m::\033[0m claude-hooks: %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m claude-hooks: %s\n' "$*" >&2; }

cmd="$HOME/.local/bin/tmux-claude-state"

if ! command -v jq > /dev/null 2>&1; then
    warn "jq is not on PATH — hooks stay unwired (install jq, then re-run \`chezmoi apply\`)"
    exit 0
fi

root="$HOME/.claude/settings.json"
[ -f "$root" ] || { mkdir -p "$(dirname "$root")"; printf '{}\n' > "$root"; }

# UserPromptSubmit and Stop bracket a turn. Notification is the only event that
# fires while nothing is running: with --dangerously-skip-permissions there is no
# permission prompt to raise it, so here it means the idle nudge — a finished
# turn nobody has come back to. Both session events CLEAR, because a pane
# outlives the Claude in it and a green digit over a bare shell is worse than no
# colour at all.
wire() {
    local f=$1 out tmp
    jq -e . "$f" > /dev/null 2>&1 || { warn "~${f#$HOME} is not valid JSON — left alone"; return; }

    out=$(jq --arg cmd "$cmd" '
      def keep(ev):
          ((.hooks[ev] // [])
           | map(.hooks |= map(select((.command // "") | test("tmux-claude-state") | not)))
           | map(select((.hooks | length) > 0)));
      def wire(ev; state):
          .hooks[ev] = (keep(ev) + [{hooks: [{type: "command",
              command: (if state == "" then $cmd else $cmd + " " + state end)}]}]);
      (.hooks //= {})
      | wire("UserPromptSubmit"; "working")
      | wire("Notification";     "waiting")
      | wire("Stop";             "done")
      | wire("SessionStart";     "")
      | wire("SessionEnd";       "")
    ' "$f") || { warn "jq failed on ~${f#$HOME} — left alone"; return; }

    [ "$out" = "$(cat "$f")" ] && return

    # Through a temp file beside it: a settings.json truncated by a redirect that
    # then fails takes a whole Claude profile's config with it.
    tmp=$(mktemp "${f}.XXXXXX") || { warn "mktemp failed for ~${f#$HOME}"; return; }
    printf '%s\n' "$out" > "$tmp" && mv "$tmp" "$f" \
        && log "wired ~${f#$HOME}" \
        || { warn "write failed for ~${f#$HOME}"; rm -f "$tmp"; }
}

wire "$root"
for f in "$HOME"/.claude/*/settings.json; do
    [ -f "$f" ] && wire "$f"
done

# Explicit, and load-bearing: a non-zero run_after fails the whole apply.
exit 0
