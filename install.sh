#!/usr/bin/env bash
# install.sh — turn a fresh clone of this repo into a working machine.
#
#   ./install.sh                      install everything, then `chezmoi apply`
#   INSTALL_DRY_RUN=1 ./install.sh    print what would run; execute nothing
#
# Covers 05-platform/02-package-provisioning/packages-installer (gantt P.2):
# R4 the platform ladder, R5 never abort, R6 the Neovim floor, R7 the required
# set, R8 re-runnable by guard. Its gate is tests/provisioning.sh.
#
# THE DRY-RUN SEAM, and it is not a convenience.
# On 2026-08-21 a prototype gate isolated this script the way the chezmoi
# gates isolate chezmoi: a scratch HOME, and a scratch bin holding a `brew`
# shim first on PATH. It ran the REAL Homebrew anyway. It upgraded nushell,
# lazygit and gh, installed a formula nobody asked for, and broke the user's
# login shell — and the run still exited 0. The cause was one line the live
# script still carries: a bare `eval` of `brew shellenv` addressed by
# ABSOLUTE path. An absolute path defeats a PATH shim, and the shellenv it
# evaluates then PREPENDS the real Homebrew prefix to PATH, displacing the
# shim, so every later `brew install` in the run was real. The isolation was
# not merely leaky; it was switched off by the thing it was meant to isolate.
#
# Two rules follow, and tests/provisioning.sh enforces both structurally:
#   1. Every MUTATING command goes through run(). Under INSTALL_DRY_RUN it
#      prints what it would do and executes nothing.
#   2. Every EXTERNAL call that could rewrite PATH, reach the network, or be
#      answered by a shim has an explicit dry branch — brew_shellenv() and
#      latest_tag() below. A comment is not protection.
# A command that is not wrapped is not dry-runnable.
#
# `set -e` is deliberately ABSENT (R5: a failed package warns and the run
# continues; a partial machine beats a dead apply). Do not "fix" it.
set -uo pipefail

# ── diagnostics ─────────────────────────────────────────────────────────────
# Everything diagnostic goes to stderr, including the DRY lines. Two reasons,
# both load-bearing: a command substitution such as `tag="$(latest_tag …)"`
# would otherwise swallow the log line into the value, and the gate asserts on
# the ORDER of lines — mixing a buffered stdout with an unbuffered stderr in
# one transcript reorders them.
log()  { printf '\033[1;34m::\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

DRY="${INSTALL_DRY_RUN:-}"

# Every mutating command goes through run(). Under INSTALL_DRY_RUN it prints
# what it would do and returns without executing.
#
# INSTALL_DRY_FAIL is the one test-only hook: it makes run() return 1 for any
# command whose argv contains the given WORD, so the gate can prove R5 without
# a real failure. It only ever makes a run less effective, never more.
run() {
  if [ -n "$DRY" ]; then
    printf 'DRY %s\n' "$*" >&2
    case " $* " in *" ${INSTALL_DRY_FAIL:-__no_such_word__} "*) return 1 ;; esac
    return 0
  fi
  "$@"
}

# ── constants ───────────────────────────────────────────────────────────────
BREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
GITHUB_API="https://api.github.com"
# The tag latest_tag reports under INSTALL_DRY_RUN, so the URL builders
# downstream still have a value without the run touching the network.
DRY_TAG="v0.0.0-dry"

# The Neovim floor. 03-editor's config needs native vim.lsp.enable and
# blink.cmp, and neither exists below it. THIS CONSTANT IS THE RECORD
# (05-platform/02 R6): other documents cite install.sh:NVIM_MIN_MINOR rather
# than repeating the number, and every message below interpolates it so no
# message can disagree with it.
NVIM_MIN_MINOR=11

# The required set (R7), plus four tools a scheduled node needs by name.
# Each entry is `formula=binary`: the name the package manager knows, and the
# name that must resolve on PATH afterwards. They differ often enough
# (gnupg/gpg, git-delta/delta) that a guard keyed on the package name is
# wrong, and R8's guard is only cheap if it is correct.
PKGS=(
  # R7's required set. `tinty` is also in R7 and is in NO package manager —
  # it is on the release rung in section 2, on both platforms.
  nushell=nu television=tv zoxide=zoxide starship=starship neovim=nvim
  git=git ripgrep=rg fd=fd bat=bat eza=eza fzf=fzf lazygit=lazygit
  chezmoi=chezmoi gh=gh
  # docker here is the CLI FORMULA, not a container runtime. It satisfies R7
  # literally. Choosing the daemon — Docker Desktop, OrbStack, colima — is a
  # licence-and-taste call that belongs to 01-capsule, not to a package list.
  # Do not "fix" this by adding a GUI cask to an unattended installer.
  docker=docker
  # Not in R7's list, required by a scheduled node:
  just=just         # this repo's own task runner: the justfile, and the gate
                    # recipes imported into it
  jq=jq             # 06-help/05 acceptance shells out to it
  gnupg=gpg         # the backend pass stores secrets in
  pass=pass         # 04-shell/02 R6 ships a nushell completion for it
  git-delta=delta   # the diff pager the platform rung table lists under brew
  # 07-multiplexer makes tmux a HOST dependency, not a container one. It was
  # in the capsule Dockerfile and nowhere else until 2026-08-29, so the epic
  # named a hard dependency that no host rung installed. This row installs
  # nothing on its own — PKGS is read at :291/:298 when install.sh runs.
  tmux=tmux
  # 03-editor/07-formatting's four formatters (its R2). conform.nvim names
  # them by binary; a configured-but-absent formatter is SILENT when a
  # language server is attached (lsp_format = "fallback" substitutes it),
  # so absence is not a state to ship.
  stylua=stylua prettier=prettier black=black
  rust=rustfmt      # rustfmt is no formula of its own; it ships with rust
)
CASKS=(
  # 02-terminal's font, per docs/capabilities-terminal.md: the live answer is
  # CaskaydiaCove Nerd Font. The two other fonts named in the tree are the
  # ones the 2026-08-20 audit found wrong.
  font-caskaydia-cove-nerd-font
)

# Distro subsets: what each distro actually carries. Whatever it does not
# carry falls through to the release rung in section 2.
APT_PKGS="neovim ripgrep fd-find fzf bat zoxide git git-delta jq gnupg pass eza tmux"
PACMAN_PKGS="neovim nushell television ripgrep fd fzf bat zoxide starship jq git git-delta lazygit github-cli just gnupg pass eza docker chezmoi tmux"
DNF_PKGS="neovim ripgrep fd-find fzf bat zoxide jq git git-delta gh just gnupg2 pass eza tmux"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)  ARCH=x86_64 ;;
    aarch64|arm64) ARCH=aarch64 ;;
esac

# Homebrew's own variable, honoured as the environment sets it. brew_shellenv
# fills it in when it is empty. Used for the Caskroom read below.
BREW_PREFIX="${HOMEBREW_PREFIX:-}"

# PATH FIRST, before anything installs. The release rung writes binaries into
# ~/.local/bin; the live script never puts that directory on PATH during the
# run, so a tool it installed in section 2 is invisible to section 3 and to
# the final `chezmoi apply` — the exact failure 01-deploy-mechanism R6 exists
# to forbid.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ── helpers ─────────────────────────────────────────────────────────────────

# Put Homebrew on PATH for the rest of THIS run. The one call that can rewrite
# PATH, so it is the one the seam must cover: under INSTALL_DRY_RUN it prints
# and returns, and evaluates nothing.
brew_shellenv() {
  local b p env_out
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] || continue
    p="${b%/bin/brew}"
    if [ -n "$DRY" ]; then
      printf 'DRY eval %s shellenv\n' "$b" >&2
      BREW_PREFIX="${BREW_PREFIX:-$p}"
      return 0
    fi
    env_out="$("$b" shellenv)"   # NOT-MUTATING (prints env assignments; changes nothing on disk)
    eval "$env_out"
    # bash caches resolved command paths. A PATH that changed mid-run is not
    # otherwise guaranteed to be re-searched. The live script omits this.
    hash -r
    BREW_PREFIX="${HOMEBREW_PREFIX:-$p}"
    return 0
  done
  warn "Homebrew installed but found at neither prefix"
  return 1
}

# A cask is installed iff its Caskroom entry exists. A directory test rather
# than `brew list --cask`: it needs no Homebrew process at all, so the dry-run
# seam covers it for free, and it works before shellenv has put brew on PATH.
cask_installed() {
  [ -n "$BREW_PREFIX" ] && [ -d "$BREW_PREFIX/Caskroom/$1" ]
}

# Resolve the latest release tag for <repo>, or warn and return 1.
#
# An empty tag MUST warn. Unauthenticated api.github.com is rate limited to 60
# requests an hour and answers with a JSON error body, in which
# grep '"tag_name"' finds nothing. The live script's `[ -n "$tag" ] &&` guard
# then skips the tool SILENTLY — a machine that quietly lacks tv and nu, with
# a zero exit code. R5 says a failure warns.
latest_tag() {
  local repo="$1" url t
  url="$GITHUB_API/repos/$repo/releases/latest"
  if [ -n "$DRY" ]; then
    printf 'DRY-READ tag %s\n' "$url" >&2
    case "$url" in
      *"${INSTALL_DRY_FAIL:-__no_such_word__}"*) t="" ;;
      *) t="$DRY_TAG" ;;
    esac
  else
    t="$(curl -fsSL "$url" 2>/dev/null | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"   # NOT-MUTATING (an HTTP GET whose body is parsed; writes nothing, and the dry branch above means it is never reached under INSTALL_DRY_RUN)
  fi
  if [ -z "$t" ]; then
    warn "$repo: could not resolve a latest release tag (GitHub rate limit?)"
    return 1
  fi
  printf '%s' "$t"
}

# fetch_release <binary> <url> — install <binary> from a release tarball into
# ~/.local/bin unless it already resolves on PATH (R8). Non-fatal (R5).
fetch_release() {
  local bin="$1" url="$2"
  have "$bin" && return 0
  run fetch_release_do "$bin" "$url" || warn "$bin: could not install from $url"
  return 0
}

fetch_release_do() {   # DRY-SEALED
  local bin="$1" url="$2" td found
  td="$(mktemp -d)" || return 1
  if curl -fsSL -o "$td/a.tar" "$url" && tar -xf "$td/a.tar" -C "$td" 2>/dev/null; then
    found="$(find "$td" -type f -name "$bin" 2>/dev/null | head -n1)"
    if [ -n "$found" ]; then
      mkdir -p "$HOME/.local/bin"
      cp "$found" "$HOME/.local/bin/$bin" && chmod +x "$HOME/.local/bin/$bin" \
        && log "installed $bin"
    else
      warn "$bin: binary not found in release asset"
      rm -rf "$td"
      return 1
    fi
  else
    rm -rf "$td"
    return 1
  fi
  rm -rf "$td"
  return 0
}

brew_bootstrap_do() {   # DRY-SEALED
  local script
  script="$(curl -fsSL "$BREW_INSTALLER_URL")" || return 1
  NONINTERACTIVE=1 /bin/bash -c "$script"
}

nvim_release_do() {   # DRY-SEALED
  local tag="$1" plat="$2" arch="$3" nd url
  url="https://github.com/neovim/neovim/releases/download/$tag/nvim-$plat-$arch.tar.gz"
  nd="$(mktemp -d)" || return 1
  if curl -fsSL -o "$nd/nvim.tar.gz" "$url" && tar -xzf "$nd/nvim.tar.gz" -C "$nd" 2>/dev/null; then
    # The rm of the old tree stays INSIDE the download-succeeded branch: a
    # failed download must not leave the machine without the editor it had.
    rm -rf "$HOME/.local/opt/neovim"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    cp -r "$nd/nvim-$plat-$arch" "$HOME/.local/opt/neovim"
    ln -sf "$HOME/.local/opt/neovim/bin/nvim" "$HOME/.local/bin/nvim"
    log "installed neovim (release $tag)"
  else
    rm -rf "$nd"
    return 1
  fi
  rm -rf "$nd"
  return 0
}

# The installed Neovim's MINOR version, normalised so every path ends in a
# number. Two defects of the live parser at ~/.files/install.sh:128 this
# replaces:
#   * its regex is anchored to major version 0. A Neovim 1.x prints
#     "NVIM v1.0.0", matches nothing, and is therefore treated as BELOW the
#     floor: the script would install an older release tarball over a newer
#     editor. The live machine runs 0.12.x, so the bug is dormant — which is
#     exactly why it will not be noticed when it stops being.
#   * its result is fed straight to a numeric test. A non-numeric value makes
#     `[` fail with "integer expression expected" and the `if` reads as false
#     — a silent skip.
nvim_minor_now() {
  local raw major minor
  have nvim || { printf '0'; return 0; }
  raw="$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')"   # NOT-MUTATING (reads the version banner)
  major="${raw%% *}"
  minor="${raw#* }"
  case "$major" in
    ''|*[!0-9]*) printf '0' ;;                                  # unparseable: treat as absent
    0) case "$minor" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$minor" ;; esac ;;
    *) printf '99' ;;                                            # major >= 1: above any 0.x floor
  esac
}

# --- 1. Package manager -----------------------------------------------------
if [ "$OS" = "Darwin" ]; then
    if ! have brew; then
        log "installing Homebrew from $BREW_INSTALLER_URL"
        run brew_bootstrap_do || warn "Homebrew: bootstrap failed — install it by hand and re-run"
    fi
    # Unconditional, not only after a fresh bootstrap: the rest of the run
    # needs brew's prefix on PATH whether this run installed it or not.
    brew_shellenv || warn "Homebrew: could not resolve a prefix — brew installs will be skipped"

    # One batch, so dependency resolution happens once…
    names=()
    for p in "${PKGS[@]}"; do names+=("${p%%=*}"); done
    run brew install "${names[@]}" || warn "brew batch incomplete — retrying the stragglers individually"

    # …then the stragglers, one at a time. The batch is NOT enough on its own
    # for R5: `brew install` aborts on an unknown formula and never attempts
    # the names after it, so one bad entry silently costs every later one.
    # This loop is have-guarded, so on a provisioned machine it is silent (R8).
    for p in "${PKGS[@]}"; do
        have "${p##*=}" && continue
        run brew install "${p%%=*}" || warn "${p%%=*}: brew install failed"
    done

    for c in "${CASKS[@]}"; do
        cask_installed "$c" && continue
        run brew install --cask "$c" || warn "$c: cask install failed"
    done
else
    if have apt-get; then
        run sudo apt-get update -y || warn "apt-get update failed"
        run sudo apt-get install -y $APT_PKGS || warn "apt-get: some packages failed"
    elif have pacman; then
        run sudo pacman -S --needed --noconfirm $PACMAN_PKGS || warn "pacman: some packages failed"
    elif have dnf; then
        run sudo dnf install -y $DNF_PKGS || warn "dnf: some packages failed"
    else
        warn "no supported package manager (apt/pacman/dnf) — install tools manually"
    fi

    # Debian/Ubuntu ship bat and fd under other names; give them the names the
    # rest of the configuration expects.
    run mkdir -p "$HOME/.local/bin" || warn "could not create $HOME/.local/bin"
    if have batcat && [ ! -e "$HOME/.local/bin/bat" ]; then
        run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat" || warn "bat: symlink failed"
    fi
    if have fdfind && [ ! -e "$HOME/.local/bin/fd" ]; then
        run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd" || warn "fd: symlink failed"
    fi

    # Build tools — lazy.nvim's `build` steps need them.
    if ! have make; then
        if have apt-get; then
            run sudo apt-get install -y build-essential || warn "build-essential: install failed"
        elif have pacman; then
            run sudo pacman -S --needed --noconfirm base-devel || warn "base-devel: install failed"
        elif have dnf; then
            run sudo dnf install -y make gcc || warn "make/gcc: install failed"
        fi
    fi
fi

# --- 2. GitHub-release binaries --------------------------------------------
# tinty is in R7, is in no package manager, and the live script does not
# install it AT ALL — a real gap, and load-bearing since tinty owns the
# palette four scheduled nodes inherit from. Release rung, both platforms.
case "$OS" in
    Darwin) tinty_triple="$ARCH-apple-darwin" ;;
    *)      tinty_triple="$ARCH-unknown-linux-gnu" ;;
esac
if ! have tinty; then
    tag="$(latest_tag tinted-theming/tinty)"
    [ -n "$tag" ] && fetch_release tinty \
        "https://github.com/tinted-theming/tinty/releases/download/$tag/tinty-$tinty_triple.tar.gz"
fi

# Linux-only rungs: Debian/Ubuntu carry none of these. macOS got them from
# brew above, and each call is have-guarded anyway.
if [ "$OS" != "Darwin" ]; then
    tag="$(latest_tag alexpasmantier/television)"
    [ -n "$tag" ] && fetch_release tv "https://github.com/alexpasmantier/television/releases/download/$tag/tv-$tag-$ARCH-unknown-linux-musl.tar.gz"
    tag="$(latest_tag nushell/nushell)"
    [ -n "$tag" ] && fetch_release nu "https://github.com/nushell/nushell/releases/download/$tag/nu-$tag-$ARCH-unknown-linux-musl.tar.gz"
    tag="$(latest_tag cli/cli)"
    [ -n "$tag" ] && fetch_release gh "https://github.com/cli/cli/releases/download/$tag/gh_${tag#v}_linux_$ARCH.tar.gz"
    tag="$(latest_tag jesseduffield/lazygit)"
    [ -n "$tag" ] && fetch_release lazygit "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${tag#v}_linux_$ARCH.tar.gz"
    fetch_release starship "https://github.com/starship/starship/releases/latest/download/starship-$ARCH-unknown-linux-musl.tar.gz"
    tag="$(latest_tag dandavison/delta)"
    [ -n "$tag" ] && fetch_release delta "https://github.com/dandavison/delta/releases/download/$tag/delta-$tag-$ARCH-unknown-linux-gnu.tar.gz"
    # chezmoi is in R7 and the live script never installs it — section 7 there
    # only warns when it is missing, so a genuinely fresh machine finishes with
    # its configs unapplied.
    tag="$(latest_tag twpayne/chezmoi)"
    [ -n "$tag" ] && fetch_release chezmoi "https://github.com/twpayne/chezmoi/releases/download/$tag/chezmoi_${tag#v}_linux_$ARCH.tar.gz"
fi

# --- 3. Neovim floor (R6) ---------------------------------------------------
# Gated on the VERSION, not on the OS. The live script wraps this whole check
# in `[ "$OS" != "Darwin" ]`, which is why the floor is never asserted on the
# supported platform at all. R6's "macOS gets a current one from brew" says
# which rung supplies it; it is not a licence to skip the check.
if [ "$OS" = "Darwin" ]; then
    nvim_platform=macos
    nvim_arch="$ARCH"
    [ "$nvim_arch" = aarch64 ] && nvim_arch=arm64
else
    nvim_platform=linux
    nvim_arch="$ARCH"
fi
nvim_minor="$(nvim_minor_now)"
if [ "$nvim_minor" -lt "$NVIM_MIN_MINOR" ]; then
    log "neovim below the 0.$NVIM_MIN_MINOR floor (found minor '$nvim_minor') — installing the official release"
    tag="$(latest_tag neovim/neovim)"
    if [ -n "$tag" ]; then
        run nvim_release_do "$tag" "$nvim_platform" "$nvim_arch" \
            || warn "neovim: could not install the $tag release tarball"
    fi
fi

# The closing assertion. Installing a current Neovim and having an older one
# earlier on PATH is the common macOS shape — a /usr/local/bin/nvim from an
# old manual install ahead of the brew prefix — and nothing in the live script
# would say a word about it. Warns rather than aborts, per R5.
if ! have nvim; then
    warn "neovim: still not on PATH after install — 03-editor's config will not load"
elif [ "$(nvim_minor_now)" -lt "$NVIM_MIN_MINOR" ]; then
    warn "neovim: $(command -v nvim) is below the 0.$NVIM_MIN_MINOR floor — an older nvim is shadowing the installed one on PATH"
fi

# --- 4. Apply the configs (the epic's I1: chezmoi apply LAST) ---------------
# Everything is installed by now, so chezmoi's script stages run with every
# tool on PATH. chezmoi is in PKGS, so a real run has it here; a dry run
# installed nothing, which is why the seam still shows the call it would make.
#
# MASON_SEED is 01-deploy-mechanism R7, and it is exported rather than passed
# so this stays the LAST line of the script (the epic's I1, asserted by
# tests/provisioning.sh as "'DRY chezmoi apply' is the LAST DRY line"). R7's
# own sentence puts :MasonUpdate "after §1-§4", which is after this line and
# therefore after the end of install.sh; home/run_after_seed-mason-registry.sh
# is where it actually runs, invoked by the apply below. Off by default, so a
# plain apply, an `rr`, and every gate's scratch target stay cheap.
export MASON_SEED=1
if have chezmoi || [ -n "$DRY" ]; then
    log "applying configs with chezmoi"
    run chezmoi apply || warn "chezmoi apply failed"
else
    warn "chezmoi not found — install it, then re-run this script"
fi

log "done."
# R5: the run reports its exit status as success even when individual packages
# failed. Every failure has already warned on its own line.
exit 0
