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
cockpit_wired)
    # F1: tmux.conf parses and binds F1 to cockpit; every cockpit.tsv row has
    # four fields and sits under a group row; every `wez` action it sends is
    # one wezterm.lua maps — else the key silently does nothing.
    t=home/dot_config/tmux/cockpit.tsv
    tmux -L orly-cockpit -f /dev/null new -d || exit 2
    tmux -L orly-cockpit source-file home/dot_config/tmux/tmux.conf; rc=$?
    tmux -L orly-cockpit list-keys | rg -q '^bind-key +-T root +F1 +run-shell .*cockpit' || { echo "cockpit: F1 does not run cockpit"; rc=1; }
    tmux -L orly-cockpit kill-server
    # A digit must select by exact index (`:=N`): plain `:N` prefix-matches a
    # window *named* `2.1.280` (Claude's version) when index N is missing.
    rg -q 'select-window -t "\$s:=\$\{key#w\}"' home/dot_local/bin/executable_cockpit || { echo "cockpit: digit target is not exact (:=N)"; rc=1; }
    awk -F'\t' 'NF != 4 { print FILENAME ":" NR ": want 4 fields"; bad = 1 }
        $2 == "" { print FILENAME ":" NR ": no icon"; bad = 1 }
        $4 == "" { g[$1] = 1 }
        length($1) > 1 && !(substr($1, 1, length($1) - 1) in g) { print FILENAME ":" NR ": no group row"; bad = 1 }
        END { exit bad }' "$t" || rc=1
    for a in $(rg -o 'printf [a-z]+ \| base64' "$t" | awk '{print $2}' | sort -u); do
        rg -q "^\s*$a = act\." home/dot_config/wezterm/wezterm.lua || { echo "wezterm.lua: no cockpit action '$a'"; rc=1; }
    done
    exit $rc ;;
cockpit_whichkey)
    # F1 is laid out as which-key.nvim, read off the frames it draws: in every
    # menu actions come before `+`groups, keys sit in more than one column
    # where they fit, each row is `k ➜ icon label` with the key's letter lit in
    # the label when it occurs there, a group shows a `»` breadcrumb, and a
    # group key and Backspace move between menus.
    python3 - home/dot_config/tmux/cockpit.tsv <<'PY'
import re, subprocess, sys
tsv = sys.argv[1]
rows = [l.rstrip("\n").split("\t") for l in open(tsv)]
def frame(keys):
    out = subprocess.run(["bash", "home/dot_local/bin/executable_cockpit", "--pick", tsv, "115", "/dev/null"],
                         input=keys, capture_output=True, text=True).stdout
    return out.split("\x1b[?2026h")[-1]
bad = 0
for p in [""] + [r[0] for r in rows if r[3] == ""]:
    f = frame(p)
    plain = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", f)
    lines = plain.splitlines()
    kids = [r for r in rows if len(r[0]) == len(p) + 1 and r[0].startswith(p)]
    cells = re.findall(r"(\S) ➜ \S+ (\+?)", plain)
    if len(cells) != len(kids): print(repr(p), "shows", len(cells), "of", len(kids)); bad = 1
    if len(kids) > 3 and max(l.count("➜") for l in lines) < 2: print(repr(p), "one column"); bad = 1
    if p and "»" not in lines[0]: print(repr(p), "no » breadcrumb"); bad = 1
    if "esc close" not in lines[-1]: print(repr(p), "help line not last"); bad = 1
    for r in kids:
        k, label = r[0][-1], r[2]
        if k.lower() in label.lower():
            i = label.lower().index(k.lower())
            if "\x1b[1;4;34m" + label[i] + "\x1b[22;24;39m" not in f: print(repr(r[0]), "key not lit in label"); bad = 1
    groups = [r[0][-1] for r in kids if r[3] == ""]
    grid = [re.findall(r"(\S) ➜", l) for l in lines if "➜" in l]
    colmajor = [g[c] for c in range(max(map(len, grid))) for g in grid if c < len(g)]
    if [k in groups for k in colmajor] != sorted(k in groups for k in colmajor): print(repr(p), "group before action"); bad = 1
strip = lambda f: re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", f)
if "»" in strip(frame("g\x7f")) or "» git" not in strip(frame("gx")): print("group key / Backspace do not move"); bad = 1
sys.exit(bad)
PY
    ;;
*)
    echo "invariants.sh: unknown invariant '$1'" >&2; exit 2 ;;
esac
