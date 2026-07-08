#!/usr/bin/env bash
set -u

cwd="$(pwd)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || exit 0
gitdir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || exit 0
[ "$branch" = "memory" ] && exit 0

common="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0
case "$common" in /*) ;; *) common="$cwd/$common" ;; esac
root="$(cd "$(dirname "$common")" && pwd)" || exit 0
mem="$root/.voit/memory"

role="vision"
case "$gitdir" in
  */worktrees/*)
    case "$branch" in
      organize-*)  role="organizer" ;;
      implement-*) role="worker" ;;
      tweak-*)     role="tweak" ;;
      *)           role="worker" ;;
    esac ;;
esac

dir="$cwd/.claude"
mkdir -p "$dir" 2>/dev/null || exit 0
printf '%s\n' "$role" > "$dir/role"
rm -f "$dir/scope"
case "$role" in
  vision)     printf '%s\n'     "$root"         > "$dir/scope" ;;
  organizer)  printf '%s\n'     "$mem"          > "$dir/scope" ;;
  worker)     printf '%s\n%s\n' "$cwd"  "$mem"  > "$dir/scope" ;;
  tweak)      : ;;
esac

id="$role"; [ "$role" = vision ] || id="$branch"
printf '%s\n' "$id" > "$dir/busid"

# Sync the installed plugin into <checkout>/.voit so every consumer-facing ref is the
# plain path .voit/<path>, identical whether the plugin is vendored (dev repo) or
# cache-installed, and valid in every worktree. Plain file copies - never a symlink
# (the old .claude/voit symlink self-looped when a voit script was invoked through
# it) and never a pointer file. pwd -P: physical path only. Re-synced each session,
# so it self-heals across plugin updates. memory/ and other project state in .voit
# are left untouched.
plugin="$(cd "$(dirname "$0")/.." && pwd -P)"
sync_voit() {
  target="$1/.voit"
  [ "$plugin" = "$target" ] && return 0
  mkdir -p "$target/.jd"
  for p in agents commands hooks scripts skills statusline.json plugins.json; do
    [ -e "$plugin/$p" ] || continue
    rm -rf "${target:?}/$p"
    cp -R "$plugin/$p" "$target/$p"
  done
  rm -rf "$target/.jd/library"
  cp -R "$plugin/.jd/library" "$target/.jd/library"
}
top="$(git rev-parse --show-toplevel 2>/dev/null)" || top="$root"
sync_voit "$root" 2>/dev/null || true
[ "$top" != "$root" ] && { sync_voit "$top" 2>/dev/null || true; }
# migrate: drop the retired .claude/voit symlink and .claude/voit-root pointer
if [ -L "$dir/voit" ]; then rm -f "$dir/voit" 2>/dev/null || true; fi
rm -f "$dir/voit-root" 2>/dev/null || true

python3 "$(dirname "$0")/../scripts/bus.py" register "$id" "$branch" >/dev/null 2>&1 || true

if [ "$role" = vision ] && [ -z "${VOIT_SANDBOX:-}" ] && command -v bwrap >/dev/null 2>&1; then
  printf '%s\n' '{"systemMessage":"VOIT: vision is running unsandboxed - run `just sandbox` to confine the tree (host read-only except this repo).","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This vision session is not inside a bwrap sandbox. Workers launch with --dangerously-skip-permissions and are contained only by the write-scope hook; `just sandbox` adds an OS-level boundary."}}'
fi
exit 0
