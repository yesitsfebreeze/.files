#!/usr/bin/env bash
# chezmoi run_after — seed mason's package catalogue once, at apply time.
#
# Covers 05-platform/01-deploy-mechanism R7.
#
# WHY THIS IS A run_after AND NOT A LINE IN install.sh, which is what R7's
# sentence says. R7 places the seeding "after §1–§4", and §4 IS
# `chezmoi apply` — so taken literally R7 puts a command after the last line
# of install.sh, which `tests/provisioning.sh` asserts is `chezmoi apply`
# ("shape/fresh: 'DRY chezmoi apply' is the LAST DRY line"). Written into
# install.sh directly, R7 turns that gate red; measured 2026-08-29.
#
# The epic's I1 settles it and is the reason this file is the right shape:
# "Apply-time, not launch-time. Anything that costs milliseconds at shell
# start is generated during `chezmoi apply` instead." A run_after IS apply
# time, it runs in the same install.sh invocation that put the tools on PATH
# (R6's contract — install before use, in the run that installed it), and
# `run_after_generate-shell-init.sh` beside it is the same shape solving the
# same problem. install.sh still performs the seeding; it does it through the
# `chezmoi apply` it already ends with.
#
# WHY THE SEEDING IS OWED AT ALL. lua/plugins/lsp.lua carries
# `registry_cache = { refresh = false }`, so mason never fetches its catalogue
# on launch. That setting bought back a discarded first save: measured
# 2026-08-24, a BufWritePre handler that merely waits aborted 6 of 6 runs on
# the shipped config, the file's md5 and mtime unchanged and nvim still
# exiting 0 — mason-core/fetch.lua shuts down the stdin pipe of an
# already-exited curl and `a.scope` re-raises the ENOTCONN inside a libuv
# callback, so it surfaces out of whatever blocking call is pumping the loop.
# With the refresh off nothing creates the catalogue, so `ensure_installed`
# cannot resolve a server name on a cold <data>/mason. The full record is
# prds/memos/mason-refresh-off-trades-auto-bootstrap.md.
#
# WHY IT IS OFF UNLESS THE PROVISIONING RUN TURNS IT ON, which is the whole of
# MASON_SEED. A run_after runs on EVERY apply, and two of those must stay
# cheap: `rr` (04-shell/02 R3) is `chezmoi update --force`, and every gate that
# applies this source to a scratch target gets a cold $HOME by construction.
# A registry-absent guard alone is not enough — measured 2026-08-29, guarding
# only on the registry made `tests/deploy-skeleton.sh` red ("apply: no
# README.md in the target"), because a scratch target has no registry, so the
# guard opened and a full `Lazy! sync` ran inside the gate's apply. The
# cold-start guard is kept as the second condition, so even a provisioning run
# seeds once and never again.
#
# A ZERO-ATTEMPT CHECK PROVES NOTHING HERE, and R7 says so in as many words:
# zero network attempts equally describes a mason that is entirely broken. The
# paired probe lives in `tests/nvim-lsp.sh --headless`, which drives the count
# above zero in the same root — :MasonUpdate took it 0 -> 2 offline on a cold
# root, and online on a cold root left has_package("pyright") true.
#
# It warns and exits 0 on every failure path (epic I4): a run_after exiting
# non-zero makes `chezmoi apply` exit 1, and a machine with an unseeded
# catalogue is recoverable with one command while a dead apply is not.
set -u

log()  { printf '\033[1;34m::\033[0m mason: %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m mason: %s\n' "$*" >&2; }

# The seam. Never set in normal use; the gate sets it to a scratch root so the
# probe cannot read or write the real one. Same shape, and the same reason, as
# SHELL_INIT_BREW_PREFIXES in run_after_generate-shell-init.sh: a PATH shim
# does not isolate a tool that resolves its own data directory.
DATA="${MASON_SEED_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason}"

# The switch. install.sh exports it for the `chezmoi apply` it ends with, so
# the seeding happens in the run that installed the tools (R6's contract) and
# nowhere else. Absent, this script is a no-op — which is what a bare
# `chezmoi apply`, an `rr`, and every gate's scratch apply must get.
if [ -z "${MASON_SEED:-}" ]; then
    exit 0
fi

if ! command -v nvim >/dev/null 2>&1; then
    warn "nvim is not on PATH — the registry stays unseeded (05-platform/01 R7)"
    exit 0
fi

# The guard: a registry directory with something in it is a seeded one.
if [ -d "$DATA/registries" ] && [ -n "$(ls -A "$DATA/registries" 2>/dev/null)" ]; then
    exit 0
fi

log "cold registry at $DATA — syncing plugins, then seeding"

# Lazy first: :MasonUpdate is meaningless until mason.nvim is installed, and on
# a fresh machine nothing has installed it yet.
if ! nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1; then
    warn "lazy sync failed — mason may not be installed; skipping the seed"
    exit 0
fi

if nvim --headless "+MasonUpdate" +qa >/dev/null 2>&1; then
    if [ -d "$DATA/registries" ] && [ -n "$(ls -A "$DATA/registries" 2>/dev/null)" ]; then
        log "registry seeded"
    else
        # :MasonUpdate exiting 0 having written nothing is the failure R7
        # warns about: the exit code is not the predicate, the artifact is.
        warn "MasonUpdate exited 0 but wrote no registry — ensure_installed cannot resolve a server name. Re-run \`nvim --headless +MasonUpdate +qa\` when the network is back"
    fi
else
    warn "MasonUpdate failed (offline?) — the registry is unseeded. Re-run \`nvim --headless +MasonUpdate +qa\` when the network is back"
fi

exit 0
