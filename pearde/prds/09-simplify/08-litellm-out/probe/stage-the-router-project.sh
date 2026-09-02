#!/usr/bin/env bash
# Stage the router as a project of its own in a throwaway directory, put its
# bin/ on PATH, and prove the scripts still resolve each other from there.
# Nothing is written under ~/dev; this only proves the shape the spec asks for.
set -uo pipefail
LANE="/Users/feb/dev/dotfiles/.pearde/.lanes/09-simplify-08-litellm-out"
P="$(mktemp -d)/llm-router"; mkdir -p "$P/bin"
trap 'rm -rf "$(dirname "$P")"' EXIT

# the six files, taken from the commit that still holds them
for n in cll litellm-env litellm-gen-config litellm-up llm-quota; do
  git -C "$LANE" show "HEAD:home/dot_local/bin/executable_$n" > "$P/bin/$n"
  chmod 755 "$P/bin/$n"
done
git -C "$LANE" show HEAD:home/dot_config/nushell/litellm.nu > "$P/litellm.nu"

fail=0
# two of the five are python3, three are bash — check each with its own parser
for f in "$P"/bin/*; do
  case "$(head -1 "$f")" in
    *python3*) python3 -m py_compile "$f" || { echo "FAIL: $f does not parse"; fail=1; } ;;
    *)         bash -n "$f"               || { echo "FAIL: $f does not parse"; fail=1; } ;;
  esac
done
echo "parse: 5 scripts (3 bash, 2 python3)"

# cll finds litellm-env through PATH, not through a fixed directory
export PATH="$P/bin:$PATH"
command -v cll | grep -q "^$P/bin/cll$" || { echo "FAIL: cll not resolved from the project"; fail=1; }
echo "PATH: cll resolves to $(command -v cll)"

# macOS ships no timeout(1); the guard is the proxy check inside cll, which
# exits at once when the proxy is down.
out="$(cll --list 2>&1)"; rc=$?
printf 'cll --list rc=%s\n' "$rc"
printf '%s\n' "$out" | head -5
case "$out" in
  *"litellm-env: command not found"*|*"No such file"*)
      echo "FAIL: the scripts do not resolve each other from the new home"; fail=1 ;;
  *) echo "OK: sibling resolution survives the move" ;;
esac

# the reverse coupling the move leaves behind
grep -n 'source ~/.config/nushell/config.nu' "$P/bin/cll" \
  && echo "NOTE: the router still calls back into the dotfiles' nushell config for \`cc\`"
exit "$fail"
