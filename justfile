cwd := justfile_directory()

# `just` with no args = push (the first recipe is just's default — keep push here so
# bare `just` keeps meaning "apply + commit + push" as it always has).
#
# The whole apply→commit→rebase→push sequence runs under a single lock so two concurrent
# `just` invocations SERIALIZE instead of racing on the working tree. Without it, one run's
# `git pull --rebase --autostash` (which checks the tree out) could revert files out from
# under the other run's `git add --all`, committing a stale tree — that's the "concurrent
# just-push" clobber that twice stripped the Ctrl+Space overlay (commits d660eab, 1467324).
# Fixed literal lock path so every worktree's `just` contends on the same lock. The shell
# reload stays OUTSIDE the lock (exec replaces the process, so it must run last and unheld).
#
# Locking is portable: Linux always has `flock` (util-linux), which auto-releases the lock
# when the holding process exits. macOS has no `flock`, so we fall back to an atomic
# `mkdir` lock with an EXIT trap that removes the lock dir on any normal/error exit.
push:
  @bash -euc 'run() { chezmoi init --source "{{cwd}}" --force && chezmoi apply --force && git add --all && { git diff --cached --quiet || git commit -m "intermediate"; } && git pull --rebase --autostash && git push; }; lock=/tmp/dotfiles-push.lock; if command -v flock >/dev/null 2>&1; then exec 9>"$lock"; flock 9; run; else until mkdir "$lock.d" 2>/dev/null; do sleep 0.2; done; trap "rmdir \"$lock.d\" 2>/dev/null || true" EXIT; run; fi'
  # Bring the desktop stack up (macOS) after applying config, so a fresh apply lands
  # a running WM + bar. No-op if already running / off macOS (see `wm`).
  @just wm
  # Reload into a fresh nushell so just-applied config (theme.nu, etc.) takes effect.
  # Only when stdin is a real terminal — skip under non-TTY runs (CI, piped, `! just`).
  @test -t 0 && exec nu || true

# Pull remote first, then commit every local change, then merge the two together.
# Unlike `push` (which rebases local work onto the remote), this fetches and merges
# the remote into the local branch, so divergent histories are reconciled with a
# merge commit instead of being replayed. Use when both sides have moved and you want
# to preserve both lines of history rather than linearize them.
# Shares push's lock so merge and push can't race each other on the working tree either.
# Same portable flock/mkdir fallback as push (see the push comment above).
merge:
  @bash -euc 'run() { chezmoi init --source "{{cwd}}" --force && chezmoi apply --force && git fetch && git add --all && { git diff --cached --quiet || git commit -m "intermediate"; } && git merge --no-edit FETCH_HEAD && git push; }; lock=/tmp/dotfiles-push.lock; if command -v flock >/dev/null 2>&1; then exec 9>"$lock"; flock 9; run; else until mkdir "$lock.d" 2>/dev/null; do sleep 0.2; done; trap "rmdir \"$lock.d\" 2>/dev/null || true" EXIT; run; fi'

# Ensure the desktop stack is up on macOS: GlazeWM (the tiling WM, cross-platform since
# 3.x) plus Zebar (the bar that also renders the alt+tab picker overlay). The picker is
# a Zebar widget observing GlazeWM binding modes over IPC, so BOTH must run for alt+tab
# to do anything. Idempotent — each is started only if its process isn't already up.
#
# A no-op off macOS: GlazeWM autostarts via Task Scheduler on Windows, and there's no
# GlazeWM on Linux. Starting GlazeWM also brings up Zebar via its own startup_commands
# (`shell-exec zebar startup`), so we only revive Zebar directly in the case where
# GlazeWM is already running but its bar died — otherwise we'd race a second
# `zebar startup` and get a duplicate overlay window.
wm:
  @bash -euc '[ "$(uname)" = Darwin ] || exit 0; \
    if ! pgrep -x glazewm >/dev/null 2>&1; then open -ga GlazeWM; \
    elif ! pgrep -x zebar >/dev/null 2>&1; then zebar startup >/dev/null 2>&1 & fi'

# Headless unit tests for the nushell config (pure functions only; tty parts excluded).
test:
  @nu tests/nushell/run.nu

# Local quality gate: parse the nushell libs (load-check), then run every test suite.
# Run before pushing to catch regressions; `just gate && just`.
gate:
  @nu -c 'source home/dot_config/nushell/finder.nu; source home/dot_config/nushell/quicklist.nu'
  @nu tests/nushell/run.nu
