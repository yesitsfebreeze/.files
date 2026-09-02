#!/usr/bin/env bash
# Deploy THIS lane's home/ into a throwaway destination and assert the post
# state — without touching the real machine, which carries other lanes' work.
#
# The five ~/.local/bin scripts get NO .chezmoiremove entry, deliberately: the
# router project reinstalls at those exact names, and chezmoiremove-vs-external
# -install.sh shows an entry there would delete its install on every apply.
# Their one-shot removal is a `rm` in the deploy step, and a fresh machine
# never had them.
set -euo pipefail
LANE="/Users/feb/dev/dotfiles/.pearde/.lanes/09-simplify-08-litellm-out"
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
mkdir -p "$D/.local/bin" "$D/.config/nushell"
printf 'old\n' > "$D/.config/nushell/litellm.nu"

chezmoi apply --force --no-tty --source "$LANE/home" --destination "$D" >/dev/null 2>&1

fail=0
say() { echo "FAIL: $1"; fail=1; }
if [ -e "$D/.config/nushell/litellm.nu" ]; then say "litellm.nu still deployed"; fi
if grep -q 'litellm' "$D/.config/nushell/config.nu"; then say "config.nu still sources it"; fi
for n in cll litellm-env litellm-gen-config litellm-up llm-quota; do
  if [ -e "$D/.local/bin/$n" ]; then say "$n was deployed"; fi
done
# TRAP: `where cmd =~ '...'` answers 6 on this surface — some rows carry no
# `cmd` and the bare column form does not mean what it reads as. Default the
# cell first; this is the form that answers an empty list.
rows=$(nu -c "open $D/.config/nushell/help/shell.nuon \
  | where (\$in.cmd? | default '') =~ '^(cll|llm)\\b' | length")
if [ "$rows" != 0 ]; then say "$rows router rows survived in shell.nuon"; fi

echo "deployed files still naming litellm/cll:"
grep -rl 'litellm\|cll' "$D/.config" 2>/dev/null | sed "s|$D|~|" | sort
[ "$fail" = 0 ] && echo "OK: the router left the deployed tree"
exit "$fail"
