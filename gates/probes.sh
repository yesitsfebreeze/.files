#!/bin/bash
# shellcheck shell=bash
# gates/probes.sh — headless probes for the three surfaces this rebuild
# produces (R2).  Sourced like lib.sh; also runnable as `--selftest`.
#
# Each surface is scriptable, which is the only reason automated gates are
# realistic at all — and each carries a trap that costs an afternoon to
# rediscover.  Every technique here was RUN on this machine during analysis;
# the counterfactual that proves it is in the selftest below.  Do not
# re-derive them.
#
#   nu_probe <config-dir> <expr>     a CONFIGURED nushell
#   nvim_probe <init.lua> <lua>      a headless, isolated Neovim
#   wezterm_probe <config.lua>       the merged key table
#
# NOT IN SCOPE: the wave 1–6 gate scripts themselves. Their subjects do not
# exist yet — there is no nushell config, no Neovim config, no wezterm.lua, no
# capsule and no `help` in this repo. Each wave's own tasks write its gate into
# gates/ and register it in gates/waves.tsv; the ARMED-without-a-gate rule in
# gates/wave-status.sh is what stops that from being forgotten. This file is
# only the machinery those gates will call.
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

FIXTURES="$GATES_DIR/fixtures"

# A missing binary must fail loudly. An empty result reported as a pass is the
# whole failure class these gates exist to prevent.
_need() {
  local bin="$1"
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    return 127
  fi
  return 0
}

# ── shell ───────────────────────────────────────────────────────────────────
# A BARE `nu -c` LOADS NO CONFIG. Measured: `nu -c '$env.config.keybindings |
# length'` -> 0, the same expression with --config/--env-config pointed at the
# live config -> 13. A gate that runs a bare `nu -c`, finds no keybindings and
# reports a pass has proved nothing.
#
# Never point this at ~/.config/nushell: the gate must probe THIS REPO'S
# DEPLOYED config, not whatever the developer happens to be running.
nu_probe() {
  local dir="$1" expr="$2"
  _need nu || return 127
  nu --config "$dir/config.nu" --env-config "$dir/env.nu" -c "$expr" < /dev/null
}

# The vacuous half, kept next to it so the comparison is one call away.
nu_probe_bare() {
  local expr="$1"
  _need nu || return 127
  nu -c "$expr" < /dev/null
}

# ── editor ──────────────────────────────────────────────────────────────────
# Installed here: Neovim 0.12 (the corrections backlog's M-3 records that the
# PRDs claim "native 0.11" and prescribe the deprecated vim.highlight.on_yank;
# a gate must not inherit that assumption).
#
# Two rules baked in:
#   * results go to STDERR — `--headless` stdout is not a clean channel;
#   * NVIM_APPNAME and the XDG dirs point inside a scratch directory, so a
#     probe can never read or write the developer's real Neovim state.
# Keymap assertions go through nvim_get_keymap, not by grepping Lua source.
# Install integrity is `nvim --headless '+Lazy! sync' +qa` exit status; plugin
# health is :checkhealth.
nvim_probe() {
  local init="$1" lua="$2" scratch
  _need nvim || return 127
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/nvim-probe.XXXXXX")"
  NVIM_APPNAME=gate-probe \
  XDG_CONFIG_HOME="$scratch/config" XDG_DATA_HOME="$scratch/data" \
  XDG_STATE_HOME="$scratch/state" XDG_CACHE_HOME="$scratch/cache" \
    nvim --headless -u "$init" -c "$lua" -c 'qa' < /dev/null
  local st=$?
  rm -rf "$scratch"
  return $st
}

# Count normal-mode maps carrying a given desc, via introspection.
nvim_desc_count() {
  local init="$1" desc="$2"
  nvim_probe "$init" \
    "lua local n=0 for _,m in ipairs(vim.api.nvim_get_keymap('n')) do if m.desc == '$desc' then n = n + 1 end end io.stderr:write(n .. '\\n')" \
    2>&1 | tr -dc '0-9'
}

# ── terminal ────────────────────────────────────────────────────────────────
# `show-keys --lua` prints the MERGED set — WezTerm's defaults PLUS the config's
# keys — so assert grep-level PRESENCE of the intended bindings rather than
# diffing the whole list. It needs no display, so it runs in a headless gate.
wezterm_probe() {
  local cfg="$1"
  _need wezterm || return 127
  wezterm --config-file "$cfg" show-keys --lua 2>/dev/null < /dev/null
}

# ── the selftest ────────────────────────────────────────────────────────────
# Runs as `just gates`' wave-independent preflight, so a broken probe cannot
# make a later wave look green.
_path_without() {   # print a PATH with the directory holding $1 removed
  local bin="$1" dir
  dir="$(dirname "$(command -v "$bin")")"
  printf '%s' "$PATH" | tr ':' '\n' | grep -vx "$dir" | paste -sd: -
}

selftest() {
  local n_probe n_bare v_one v_zero
  echo "── gates/probes.sh --selftest ───────────────────────────────────────"
  echo "      MUTATION HOST: $(gates_tmpdir) (scratch fixtures; gates/fixtures/ is never written)"
  echo "      fixtures read from: $FIXTURES (nu · nvim · wezterm)"

  # shell — both halves. The second is what proves the probe is not vacuous.
  # The single quotes are nushell syntax, not a shell expansion mistake.
  # shellcheck disable=SC2016
  n_probe="$(nu_probe "$FIXTURES/nu" '$env.config.keybindings | where name == gate_probe | length' 2>/dev/null)"
  # shellcheck disable=SC2016
  n_bare="$(nu_probe_bare '$env.config.keybindings | where name == gate_probe | length' 2>/dev/null)"
  echo "      nu: configured -> ${n_probe:-<none>} · bare \`nu -c\` -> ${n_bare:-<none>}"
  chk_ok "nu_probe: the fixture's gate_probe keybinding is present (got ${n_probe:-<none>})" \
    test "$n_probe" = "1"
  chk_ok "nu_probe: a bare \`nu -c\` reports it absent — the probe is not vacuous (got ${n_bare:-<none>})" \
    test "$n_bare" = "0"

  # editor — one map with the desc, zero with an empty init.
  local empty_init; empty_init="$(gates_tmpdir)/empty-init.lua"
  : > "$empty_init"
  echo "      MUTATION: wrote an EMPTY init.lua at $empty_init — the counterfactual fixture"
  v_one="$(nvim_desc_count "$FIXTURES/nvim/init.lua" 'gate probe')"
  v_zero="$(nvim_desc_count "$empty_init" 'gate probe')"
  echo "      nvim: fixture -> ${v_one:-<none>} · empty init -> ${v_zero:-<none>}"
  chk_ok "nvim_probe: nvim_get_keymap finds exactly one 'gate probe' map" test "$v_one" = "1"
  chk_ok "nvim_probe: an empty init finds zero — the probe reads the editor, not the source" \
    test "$v_zero" = "0"

  # editor — and it leaves the developer's real Neovim state alone.
  snapshot_paths "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.config/nvim"
  nvim_desc_count "$FIXTURES/nvim/init.lua" 'gate probe' > /dev/null
  assert_unchanged "nvim_probe: ~/.local/share/nvim, ~/.local/state/nvim and ~/.config/nvim are untouched"

  # terminal — present, and absent when the keys table is emptied.
  local wz_empty; wz_empty="$(gates_tmpdir)/wezterm-empty.lua"
  grep -v "key = 'F20'" "$FIXTURES/wezterm/wezterm.lua" > "$wz_empty"
  echo "      MUTATION: copied the wezterm fixture to $wz_empty with its keys table emptied"
  chk_ok   "wezterm_probe: the fixture's binding shows in show-keys --lua" \
    grep -q 'gate_probe' <(wezterm_probe "$FIXTURES/wezterm/wezterm.lua")
  chk_fail "wezterm_probe: with the keys table emptied it does not" \
    grep -q 'gate_probe' <(wezterm_probe "$wz_empty")

  # every probe fails loudly when its binary is missing. Simulated with a
  # PATH that excludes only that binary's directory.
  local out st bin
  echo "      MUTATION: each probe below is re-run with its own binary's directory removed from PATH"
  for bin in nu nvim wezterm; do
    case "$bin" in
      nu)      out="$(PATH="$(_path_without nu)" bash -c ". '$GATES_DIR/probes.sh'; nu_probe '$FIXTURES/nu' '1'" 2>&1)"; st=$? ;;
      nvim)    out="$(PATH="$(_path_without nvim)" bash -c ". '$GATES_DIR/probes.sh'; nvim_probe '$FIXTURES/nvim/init.lua' 'lua print(1)'" 2>&1)"; st=$? ;;
      *)       out="$(PATH="$(_path_without wezterm)" bash -c ". '$GATES_DIR/probes.sh'; wezterm_probe '$FIXTURES/wezterm/wezterm.lua'" 2>&1)"; st=$? ;;
    esac
    echo "      $bin with its directory off PATH: rc=$st, said \"${out%%$'\n'*}\""
    if [ "$st" -eq 127 ] && grep -q 'PROBE-ERROR' <<< "$out"; then
      chk "probe: a missing $bin fails loudly (rc 127 + PROBE-ERROR, not an empty pass)" 0
    else
      chk "probe: a missing $bin fails loudly (rc 127 + PROBE-ERROR, not an empty pass)" 1
    fi
  done

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  "") : ;;   # sourced, or run with no arguments: define and return
  *) echo "usage: probes.sh [--selftest]  (otherwise: source it)" >&2; exit 2 ;;
esac
