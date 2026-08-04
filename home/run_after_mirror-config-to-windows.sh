#!/usr/bin/env bash
# chezmoi run_after hook — on WSL only, mirror the whole ~/.config tree to the
# Windows user profile so native-Windows apps (WezTerm, nushell, starship, nvim,
# bat, lazygit, …) read the same config chezmoi just deployed on the Linux side.
#
# WSL is the single source of truth. The copy is one-way and ADDITIVE: it never
# deletes Windows-only entries (scoop, pnpm, byobu, …), it only adds/updates.
set -euo pipefail

# Not WSL? Nothing to do — this is a no-op on Linux/macOS.
grep -qi microsoft /proc/version 2>/dev/null || exit 0

# Resolve the Windows profile dir (e.g. /mnt/c/Users/sayhe). cmd.exe warns about
# the WSL cwd on stderr but still prints %USERPROFILE%; we suppress and convert.
winhome="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n')" 2>/dev/null)" || exit 0
[ -n "$winhome" ] && [ -d "$winhome" ] || exit 0

src="$HOME/.config/"
dst="$winhome/.config/"
mkdir -p "$dst"

# GlazeWM reads its config from the default %USERPROFILE%\.glzr on Windows, not
# ~/.config. Mirror that tree too so the native-Windows GlazeWM picks up the same
# config chezmoi deployed on the WSL side. One-way, additive, same as below.
if [ -d "$HOME/.glzr" ]; then
  glzr_dst="$winhome/.glzr/"
  mkdir -p "$glzr_dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -rlt --no-perms --no-owner --no-group "$HOME/.glzr/" "$glzr_dst"
  else
    cp -rL "$HOME/.glzr/." "$glzr_dst"
  fi
  printf ':: WSL: mirrored ~/.glzr -> %s\n' "$glzr_dst"
fi

# pi (earendil-works coding agent) reads its config + auth from ~/.pi. Mirror the
# tree to the Windows profile so native-Windows pi authenticates with the same
# provider tokens (auth.json) and shares settings (open-tui, pi-goal, adhd-mode,
# trust, mcp, models). One-way, additive — same contract as .glzr above.
#
# Excluded:
#   sessions/ *.log *.jsonl   — per-session state, history, crash logs (huge,
#     WSL-specific, churns every run)
#   .kern .burrito            — on-disk knowledge graph + its peer store
#     (WSL-local DBs, not portable)
#   journal workflows         — WSL-local journals/workflow defs
#   splinter git              — code index + git helper (WSL paths)
#   cht-cache mcp-cache.json  — runtime caches (regenerate on Windows)
#   models-store.json         — large model-list runtime state
#   extensions npm            — installed npm packages (WSL node_modules paths;
#     Windows pi reinstalls its own)
#   claude-bridge.json        — carries a WSL pathToClaudeCodeExecutable
#     (~/.local/bin/claude) that's wrong on native Windows; the Windows leg needs
#     its own, so don't drag the WSL one across
if [ -d "$HOME/.pi" ]; then
  pi_dst="$winhome/.pi/"
  mkdir -p "$pi_dst"
  pi_excludes=(sessions "*.log" "*.jsonl" .kern .burrito journal workflows splinter git cht-cache mcp-cache.json models-store.json extensions npm claude-bridge.json)
  if command -v rsync >/dev/null 2>&1; then
    pi_args=()
    for e in "${pi_excludes[@]}"; do pi_args+=(--exclude "$e"); done
    rsync -rlt --no-perms --no-owner --no-group "${pi_args[@]}" "$HOME/.pi/" "$pi_dst"
  else
    # cp fallback: top-level + agent/ only, skipping excluded names.
    for item in "$HOME/.pi"/* "$HOME/.pi"/.*; do
      [ -e "$item" ] || continue
      name="$(basename "$item")"
      case " ${pi_excludes[*]} " in *" $name "*) continue ;; esac
      cp -rL "$item" "$pi_dst"
    done
    if [ -d "$HOME/.pi/agent" ]; then
      mkdir -p "$pi_dst/agent"
      for item in "$HOME/.pi/agent"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        case " ${pi_excludes[*]} " in *" $name "*) continue ;; esac
        cp -rL "$item" "$pi_dst/agent/"
      done
    fi
  fi
  printf ':: WSL: mirrored ~/.pi -> %s (auth + config; excluded: %s)\n' "$pi_dst" "${pi_excludes[*]}"
fi

# Skip dirs that aren't config any Windows app reads and would make the cross-FS
# copy pathological: ~/.config/assembly alone is ~910MB. Add to this list rather
# than mirror runtime caches / build output over the slow /mnt/c 9p bridge.
# `chezmoi`: its generated config pins sourceDir to the WSL repo path
# (/home/feb/dev/.files); on Windows that resolves to a nonexistent C:\home\... and
# breaks `chezmoi`. WSL is the single source of truth — Windows is never
# chezmoi-managed, so its config must not leak across.
excludes=(assembly opencode go .git chezmoi "*/cache" "*/Cache" "*.sock" node_modules)

if command -v rsync >/dev/null 2>&1; then
  args=()
  for e in "${excludes[@]}"; do args+=(--exclude "$e"); done
  # --no-perms/owner/group: DrvFs can't hold unix metadata, so syncing it churns
  # every file. We mirror content only. No --delete: keep Windows-only configs.
  rsync -rlt --no-perms --no-owner --no-group "${args[@]}" "$src" "$dst"
else
  for d in "$src".*/ "$src"*/; do
    [ -e "$d" ] || continue
    name="$(basename "$d")"
    case " ${excludes[*]} " in *" $name "*) continue ;; esac
    cp -rL "$d" "$dst"
  done
fi

printf ':: WSL: mirrored ~/.config -> %s (skipped: %s)\n' "$dst" "${excludes[*]}"
