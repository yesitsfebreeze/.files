#!/usr/bin/env bash
# chezmoi run_after — seed mason's package catalogue on a cold machine.
#
# lsp.lua sets `registry_cache = { refresh = false }` so mason never fetches
# its catalogue on launch — that setting fixed a real bug: an unguarded
# refresh discarded the first buffer write on an offline launch (full
# record: memos/knowledge/mason-refresh-off-trades-auto-bootstrap.md). With
# the refresh off, nothing else ever creates the catalogue, so this script
# performs the one-time fetch instead. It runs on every `chezmoi apply` but
# is gated only on the catalogue being absent, so it is a no-op after the
# first successful seed — no separate switch needed; a cold registry IS
# "first run on a new machine". It warns and exits 0 on every failure path:
# a run_after that exits non-zero fails the whole apply, and an unseeded
# catalogue is recoverable with one command while a dead apply is not.
set -u

log()  { printf '\033[1;34m::\033[0m mason: %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m mason: %s\n' "$*" >&2; }

# The seam. Never set in normal use; a probe sets it to a scratch root so it
# cannot read or write the real one.
DATA="${MASON_SEED_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason}"

if ! command -v nvim >/dev/null 2>&1; then
    warn "nvim is not on PATH — the registry stays unseeded"
    exit 0
fi

# The guard: a registry directory with something in it is a seeded one.
if [ -d "$DATA/registries" ] && [ -n "$(ls -A "$DATA/registries" 2>/dev/null)" ]; then
    exit 0
fi

log "cold registry at $DATA — syncing plugins, then seeding"

# Lazy first: :MasonUpdate is meaningless until mason.nvim is installed, and
# on a fresh machine nothing has installed it yet.
if ! nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1; then
    warn "lazy sync failed — mason may not be installed; skipping the seed"
    exit 0
fi

if nvim --headless "+MasonUpdate" +qa >/dev/null 2>&1; then
    if [ -d "$DATA/registries" ] && [ -n "$(ls -A "$DATA/registries" 2>/dev/null)" ]; then
        log "registry seeded"
    else
        # :MasonUpdate exiting 0 having written nothing is the failure this
        # guards against: the exit code is not the predicate, the artifact is.
        warn "MasonUpdate exited 0 but wrote no registry — ensure_installed cannot resolve a server name. Re-run \`nvim --headless +MasonUpdate +qa\` when the network is back"
    fi
else
    warn "MasonUpdate failed (offline?) — the registry is unseeded. Re-run \`nvim --headless +MasonUpdate +qa\` when the network is back"
fi

exit 0
