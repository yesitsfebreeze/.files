#!/usr/bin/env bash
# Re-runnable proof for 09-simplify/07-provisioning. Asserts POST-STATE only:
# no `git add`, no `git commit`, no `grep -c` (which exits 1 on a count of 0).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0
ok()   { printf '  ok   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; fail=1; }

# R1 — the Brewfile parses and every name it holds resolves.
n="$(brew bundle list --file Brewfile --all 2>/dev/null | wc -l | tr -d ' ')"
[ "$n" -ge 28 ] && ok "Brewfile lists $n entries" || bad "Brewfile lists $n entries, expected >= 28"
brew info --formula $(brew bundle list --file Brewfile --formula 2>/dev/null) >/dev/null 2>&1 \
  && ok "every formula resolves" || bad "a formula in the Brewfile does not resolve"
brew info --cask $(brew bundle list --file Brewfile --cask 2>/dev/null) >/dev/null 2>&1 \
  && ok "every cask resolves" || bad "a cask in the Brewfile does not resolve"
brew bundle list --file Brewfile --all 2>/dev/null | grep -qx 'tinted-theming/tinted/tinty' \
  && ok "tinty is in the Brewfile" || bad "tinty is not in the Brewfile"

# R1 — tinty comes from brew, and no ~/.local/bin copy shadows it.
[ -x /opt/homebrew/bin/tinty ] && ok "brew owns tinty" || bad "brew does not own tinty"
[ -e "$HOME/.local/bin/tinty" ] && bad "~/.local/bin/tinty shadows the brew one" \
  || ok "no ~/.local/bin/tinty shadow"

# R2 — install.sh is small, parses, and runs `chezmoi apply` last.
l="$(wc -l < install.sh | tr -d ' ')"
[ "$l" -le 80 ] && ok "install.sh is $l lines" || bad "install.sh is $l lines, over 80"
bash -n install.sh && ok "install.sh parses" || bad "install.sh does not parse"
grep -q 'brew bundle install --file Brewfile' install.sh \
  && ok "install.sh runs brew bundle" || bad "install.sh does not run brew bundle"
grep -q 'brew trust --tap tinted-theming/tinted' install.sh \
  && ok "install.sh trusts the tinted tap" || bad "install.sh does not trust the tinted tap"
[ "$(grep -n 'chezmoi apply' install.sh | tail -1 | cut -d: -f1)" -gt \
  "$(grep -n 'brew bundle install' install.sh | tail -1 | cut -d: -f1)" ] \
  && ok "chezmoi apply comes after brew bundle" || bad "chezmoi apply is not last"

# R2-R5 — no file this PRD owns cites a deleted test, gate or seam.
# `!` because rg exits 1 when nothing matches, and nothing matching is success.
if ! rg -l 'tests/|gates/|INSTALL_DRY|SHELL_INIT_BREW_PREFIXES|MASON_SEED' \
     install.sh home/run_after_generate-shell-init.sh home/run_after_register-mcp.sh \
     home/dot_config/capsule/Dockerfile >/dev/null 2>&1; then
  ok "no deleted-test or seam citations"
else
  bad "a file still cites a deleted test, gate or seam"
fi

# R3 — the generated init: three non-empty files, from a real run of the script.
bash home/run_after_generate-shell-init.sh >/dev/null 2>&1
c=0; for f in starship zoxide television; do
  [ -s "$HOME/.cache/nushell/init/$f.nu" ] && c=$((c+1))
done
[ "$c" -eq 3 ] && ok "three non-empty init files" || bad "only $c init files are non-empty"

# R3 — a missing tool leaves an EMPTY file and the script still exits 0.
bash .pearde/prds/09-simplify/07-provisioning/probe/shell-init-missing-tool.sh \
  home/run_after_generate-shell-init.sh >/dev/null 2>&1 \
  && ok "a failing tool yields an empty file, exit 0" || bad "the missing-tool path regressed"

# R4/R5 — the two findings that must survive the prose cut.
grep -q 'claude.json' home/run_after_register-mcp.sh \
  && ok "the ~/.claude.json finding survives" || bad "the ~/.claude.json finding was lost"
grep -q 'No COPY/ADD' home/dot_config/capsule/Dockerfile \
  && ok "the empty-build-context rule survives" || bad "the build-context rule was lost"

# R6 — the internals page, in the source and deployed.
grep -q 'brew bundle' home/dot_config/nushell/help/manual/internals/provisioning.md \
  && ok "the internals page says brew bundle" || bad "the internals page is missing or wrong"
if ! rg -q 'wave|gate' home/dot_config/nushell/help/manual/internals/provisioning.md; then
  ok "the internals page names no wave or gate"
else
  bad "the internals page still names a wave or a gate"
fi
[ -f "$HOME/.config/nushell/help/manual/internals/provisioning.md" ] \
  && ok "the page is deployed" || bad "the page is not deployed"

# Nothing THIS PRD owns is left undeployed. Scoped to its own targets on
# purpose: a repo-wide `chezmoi status` also reports whatever a concurrent pass
# has in flight (measured 2026-09-02 — 09-simplify/04-nushell's config.nu and
# nushell-modules.md turned this red mid-run), and a verify that goes red for
# another node's work is not a check on this one. Run-scripts (` R `) are never
# a file target and stay pending by design.
# The four targets, named — not the internals/ directory, which other nodes
# also write into (nushell-modules.md, measured red here 2026-09-02).
pending="$(chezmoi status 2>/dev/null | grep -v '^ R ' | grep -E \
  '\.config/(capsule/Dockerfile|nushell/help/manual/internals/(provisioning|index|neovim)\.md)$')"
if [ -z "$pending" ]; then
  ok "no file target of this PRD left undeployed"
else
  bad "a file target is still pending: $(printf '%s' "$pending" | tr '\n' ' ')"
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL"
exit "$fail"
