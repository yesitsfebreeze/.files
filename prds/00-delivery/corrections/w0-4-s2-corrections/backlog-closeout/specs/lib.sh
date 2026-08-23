# Shared helpers for W0.4h's checks.
#
# GREP IS /usr/bin/grep, ALWAYS, and this is not pedantry.  On this host an
# interactive shell function shadows grep with ugrep, under which the exact-id
# matcher `(^|[^A-Za-z0-9])M-17([^0-9]|$)` matches NOTHING — the `$` inside the
# alternation is not treated as an anchor.  gates/audit-findings.sh is safe
# because it runs under `bash script`, where the function does not exist; a
# check sourced or pasted into an interactive shell is not.  Pinning the path
# removes the difference.  BSD grep's `\b` is unusable here, which is why the
# matcher is spelled out by hand (R8).
G=/usr/bin/grep
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
BL="$REPO/prds/00-delivery/corrections/prd.md"
TK="$REPO/prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/prd.md"
rc=0
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
# Whitespace-normalised text of stdin: newlines to spaces, runs collapsed.
# Every content assertion below runs through this, because the file is wrapped
# at ~78 columns and a phrase straddles a line break.
norm() { tr '\n\t' '  ' | tr -s ' '; }
# One table row by exact id, or empty.
row() { $G -E "^\| *$1 *\|" "$BL"; }
# The exact-id matcher (R8). Proven both ways in check04.
id_re() { printf '(^|[^A-Za-z0-9])%s([^0-9]|$)' "$1"; }
# Numbered open-decision item n, up to item m (or the next `## ` heading).
item() { awk -v n="$1" -v m="$2" 'BEGIN{p=0} $0 ~ "^"n"\\. \\*\\*"{p=1} $0 ~ "^"m"\\. \\*\\*"{p=0} /^## /{p=0} p' "$BL"; }
has() { norm <<<"$2" | $G -qF "$1"; }
