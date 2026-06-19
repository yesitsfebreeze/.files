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

# Skip dirs that aren't config any Windows app reads and would make the cross-FS
# copy pathological: ~/.config/assembly alone is ~910MB. Add to this list rather
# than mirror runtime caches / build output over the slow /mnt/c 9p bridge.
excludes=(assembly opencode go .git "*/cache" "*/Cache" "*.sock" node_modules)

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
