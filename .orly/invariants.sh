#!/bin/bash
# Repo invariants, one per name: `bash .orly/invariants.sh NAME`. Each prints
# what broke it and exits non-zero; silence and 0 means it holds.
cd "$(dirname "$0")/.." || exit 2
case $1 in
nu_parses)
    # Every tracked nushell file parses. Run from the config dir so relative
    # `source` lines resolve the way they do at startup.
    cd home/dot_config/nushell || exit 2
    rc=0
    for f in $(git ls-files . | grep '\.nu$'); do
        nu --ide-check 50 "$f" | grep -q '"severity":"Error"' && { echo "$f"; rc=1; }
    done
    exit $rc ;;
lua_parses)
    rc=0
    for f in $(git ls-files home | grep '\.lua$'); do
        luajit -bl "$f" >/dev/null || { echo "$f"; rc=1; }
    done
    exit $rc ;;
no_hex_below_tinty)
    # tinty owns the palette; nothing downstream of it spells a colour.
    ! rg -n '#[0-9a-fA-F]{6}\b' home --glob '!**/help/**' \
        --glob '!**/tinted-theming/**' --glob '!**/lazy-lock.json' ;;
fzf_confined)
    # fzf is reached only through tv-go (and zoxide, which invokes it itself).
    bad=$(rg -n '(^|[|(;&] *)fzf\b' home install.sh --glob '!**/help/**' \
        | grep -v 'executable_tv-go:' | grep -vE '^[^:]+:[0-9]+:\s*#')
    echo "$bad"; [ -z "$bad" ] ;;
hard_constraints)
    # The CLAUDE.md "hard-won constraints" that a grep can hold.
    rc=0
    rg -q 'use_kitty_protocol: false' home/dot_config/nushell/config.nu \
        || { echo "nushell: use_kitty_protocol must stay false"; rc=1; }
    rg -n "theme *= *[\"']auto[\"']" home/dot_config/nvim && { echo "lualine: auto theme breaks on base16"; rc=1; }
    rg -q 'lsp\.log\.set_level\(vim\.log\.levels\.(OFF|ERROR|WARN)\)' home/dot_config/nvim \
        || { echo "nvim: LSP log level must be capped"; rc=1; }
    rg -q "terminal-features\[[0-9]+\] '\*:[^']*sync" home/dot_config/tmux/tmux.conf \
        || { echo "tmux: the sync feature keeps header redraws from flickering"; rc=1; }
    rg -n 'set -a[a-z]* terminal-features' home/dot_config/tmux/tmux.conf \
        && { echo "tmux: set -a on terminal-features grows the list on every reload"; rc=1; }
    rg -n 'local/share/chezmoi' home install.sh justfile scripts --glob '!**/help/**' \
        && { echo "chezmoi source must come from chezmoi source-path"; rc=1; }
    exit $rc ;;
bash_32)
    # /bin/bash on macOS is 3.2 and is what `#!/bin/bash` and tmux run-shell
    # get: no mapfile/readarray, associative arrays, case-folding expansions
    # or `&>>`.
    bad=$(for f in $(git ls-files home install.sh | grep -E '(\.sh$|/executable_|install\.sh$)'); do
        head -1 "$f" | grep -q bash || continue
        rg -n --with-filename -e '\b(mapfile|readarray)\b' -e 'declare -A' -e '\$\{[A-Za-z_]+(,,|\^\^)' -e '&>>' "$f"
    done | grep -vE '^[^:]+:[0-9]+:\s*#')
    echo "$bad"; [ -z "$bad" ] ;;
size_budget)
    # Complexity ceiling on code (not data like kern.toml): no file over 500
    # lines, all of it under 4100.
    git ls-files -z home install.sh justfile scripts | grep -z -v /help/ \
        | grep -zE '(\.(sh|nu|lua|py|mjs|conf)|/executable_[^/]*|justfile|install\.sh)$' \
        | xargs -0 wc -l \
        | awk '{ n = $1; sub(/^ *[0-9]+ /, "") }
               $0 != "total" { t += n; if (n > 500) { print "over 500:", $0; bad = 1 } }
               END { print "total=" t; exit bad || t > 4100 }' ;;
*)
    echo "invariants.sh: unknown invariant '$1'" >&2; exit 2 ;;
esac
