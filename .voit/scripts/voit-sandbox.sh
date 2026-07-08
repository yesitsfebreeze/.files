#!/usr/bin/env bash
set -eu

command -v bwrap >/dev/null 2>&1 || {
  echo "voit-sandbox: bwrap (bubblewrap) not found; install it to sandbox the vision" >&2
  exit 3
}

root="$(git rev-parse --show-toplevel)"
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$cfg" 2>/dev/null || true

binds=(--bind "$root" "$root")
case "$cfg/" in
  "$root"/*) ;;
  *) binds+=(--bind "$cfg" "$cfg") ;;
esac

exec bwrap \
  --ro-bind / / \
  --dev /dev --proc /proc --tmpfs /tmp \
  --die-with-parent --unshare-user \
  "${binds[@]}" \
  --setenv VOIT_SANDBOX 1 \
  --chdir "$root" \
  claude "$@"
