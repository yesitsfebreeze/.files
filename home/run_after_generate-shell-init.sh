#!/usr/bin/env bash
# chezmoi run_after — regenerate the shell-integration files Nushell *sources*.
#
# Covers 05-platform/03-shell-init-generation R1–R4. Nushell's config.nu only
# `source`s these files, so launching nu/WezTerm does zero setup work; the work
# happens here, once per `chezmoi apply`.
#
# WHY THE THINGS THAT LOOK ODD ARE THE WAY THEY ARE
#
# 1. The path is a LITERAL $HOME/.cache/nushell/init, and XDG_CACHE_HOME is
#    deliberately NOT honoured (decision D1a). Nushell resolves `source` at
#    PARSE time and cannot read `$env`, so config.nu physically cannot write
#    `source ($env.XDG_CACHE_HOME | path join ...)`. A generator that honoured
#    the variable while the shell could not would write to one directory and
#    source from another — three failing `source` lines at every shell start.
#    One hardcoded path on both sides cannot diverge.
#
# 2. PATH order follows the SHELL, not the installer (decision D2). Homebrew's
#    shellenv is evaluated FIRST and $HOME/.local/bin:$HOME/.cargo/bin is
#    prepended OVER it, which is the order 04-shell/01 R1 gives a login shell.
#    The generated init must describe the binary the shell will actually
#    launch. Measured on this machine 2026-08-21: ~/.local/bin/zoxide is 0.9.9,
#    /opt/homebrew/bin/zoxide is 0.10.0, and their `init nushell` output
#    differs (1998 vs 1966 bytes). install.sh ends up with the OPPOSITE
#    precedence; that disagreement is real and deliberate.
#
# 3. SHELL_INIT_BREW_PREFIXES is a test-only seam and it exists because a PATH
#    shim does NOT isolate this script (decision D5). Measured 2026-08-21: run
#    under `env -i HOME=<scratch> PATH=/usr/bin:/bin`, the previous version of
#    this script still produced a 2280-byte REAL starship init — because it
#    evaluated `/opt/homebrew/bin/brew shellenv` by ABSOLUTE path, and that
#    shellenv prepends the real Homebrew prefix back over the scratch PATH.
#    Same failure class as the install.sh incident that broke this machine's
#    login shell. The variable defaults to the two real prefixes and is never
#    set in normal use; the gate sets it EMPTY, which iterates zero times.
#
# 4. It ends in an explicit `exit 0`, and carries no `set -e`. Measured: a
#    run_after script exiting 3 makes `chezmoi apply` print
#    `chezmoi: <script>: exit status 3` and exit 1. A missing tool must be a
#    warning, never a dead apply (epic I4).

set -uo pipefail

# ── PATH re-resolve, in the shell's order (see 2 above) ─────────────────────
# Brew first: the first prefix in the list that actually has an executable
# bin/brew wins. `${VAR-default}` (not `:-`) so an explicitly EMPTY
# SHELL_INIT_BREW_PREFIXES iterates zero times and evaluates no brew at all.
# IFS word splitting rather than an array: /bin/bash on macOS is 3.2.57 and is
# what a `#!/usr/bin/env bash` shebang resolves to before Homebrew is on PATH.
_si_old_ifs="${IFS:- }"
IFS=:
for _si_prefix in ${SHELL_INIT_BREW_PREFIXES-/opt/homebrew:/usr/local}; do
    IFS="$_si_old_ifs"
    if [ -n "$_si_prefix" ] && [ -x "$_si_prefix/bin/brew" ]; then
        eval "$("$_si_prefix/bin/brew" shellenv)"
        break
    fi
    IFS=:
done
IFS="$_si_old_ifs"
unset _si_prefix _si_old_ifs

# User bins go OVER brew — this is the half that follows the shell, not the
# installer.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
# bash caches resolved command paths; without this, a tool installed earlier in
# this same apply can still resolve to the pre-install answer.
hash -r

# ── the one directory (decision D1) ────────────────────────────────────────
# All three files live here. The live layout's three-way split — two files
# under ~/.cache in per-tool directories and one loose in $HOME — is NOT
# inherited: R2 asked for one location, and 04-shell I4 already reads
# "generated integrations in cache". The three superseded paths are named in
# spec01 D1 and asserted absent by tests/shell-init.sh, deliberately NOT
# repeated here: S1.4 requires that none of them appears in this file at all,
# so that a grep for one is proof it is not written.
INIT_DIR="$HOME/.cache/nushell/init"
mkdir -p "$INIT_DIR"

# gen_init <out-file> <tool> <init args...>
#
# Guarantees <out-file> exists afterwards whatever happened — absent tool,
# failing tool, silent tool — because an empty file is a harmless no-op and a
# missing one is a `source` error at every shell start (R3).
#
# Output goes to a temp file in the SAME directory and is moved into place with
# `mv -f` (a same-directory rename, therefore atomic) and only when the tool
# exited 0. Half-written nushell would be a parse error in every shell, which
# is worse than nothing.
gen_init() {
    local out="$1"; shift
    local tmp="$out.tmp"
    rm -f "$tmp"
    if command -v "$1" > /dev/null 2>&1 && "$@" > "$tmp" 2> /dev/null; then
        mv -f "$tmp" "$out"
    else
        rm -f "$tmp"
        : > "$out"   # truncate-on-failure (S1.7): empty beats partial
    fi
}

gen_init "$INIT_DIR/starship.nu"    starship init nu
gen_init "$INIT_DIR/zoxide.nu"      zoxide init nushell
# `tv init nu` emits the Ctrl-T (autocomplete) and Alt-R/Ctrl-R (history)
# bindings, and defines the `tv_shell_history` command 04-shell/05 R2 binds
# Alt-R to. A tv upgrade that renames it breaks that keybinding, which is why
# tests/shell-init.sh --live checks the command, not just the file.
gen_init "$INIT_DIR/television.nu"  tv init nu

# Explicit, and load-bearing: see 4 in the header.
exit 0
