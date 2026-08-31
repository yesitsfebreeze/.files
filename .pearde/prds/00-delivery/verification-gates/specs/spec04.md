# spec04 — headless probes for the three surfaces

Goal: R2. The three surfaces this rebuild produces are all scriptable, which
is the only reason automated gates are realistic at all — but each has a trap
that costs an afternoon to rediscover. Build the probe helpers now, with
fixture self-tests, so the wave 3–6 gates are three lines each instead of
three hours each. Every technique below was **run during analysis on this
machine** and the exact counterfactual is recorded; do not re-derive them.

## Files touched
- `gates/probes.sh` — new. Sourced, like `lib.sh`.
- `gates/fixtures/` — new. Minimal configs the self-tests probe.

## Not in scope

The wave 1–6 gate *scripts*. Their subjects do not exist yet: there is no
nushell config, no Neovim config, no `wezterm.lua`, no capsule and no `help`
in this repo. Each wave's own tasks write its gate into `gates/` and register
it in `gates/waves.tsv`; spec01's ARMED-without-a-gate rule is what stops that
from being forgotten. This spec builds only the machinery they will call.

## `nu_probe <config-dir> <expr>`

**A bare `nu -c` loads no config**, so a gate that runs one and finds no
keybindings has proved nothing. Measured: `nu -c '$env.config.keybindings |
length'` → `0`; the same expression with `--config`/`--env-config` pointed at
the live config → `13`.

Signature: launch `nu --config <dir>/config.nu --env-config <dir>/env.nu -c
<expr>`, with `stdin` closed. Never point it at `~/.config/nushell` — the gate
must probe *this repo's deployed* config, not whatever the developer happens
to be running.

## `nvim_probe <init.lua> <lua>`

`nvim --headless -u <init.lua> -c '<lua>' -c 'qa'`. Verified on the installed
binary: Neovim **0.12** (note: the corrections backlog's `M-3` records that
the PRDs claim "native 0.11" and prescribe the deprecated
`vim.highlight.on_yank`; the gate must not inherit that assumption).

Two rules baked into the helper:
- Write results to **stderr**, not stdout. `--headless` stdout is not a clean
  channel.
- Set `NVIM_APPNAME` and an `XDG_CONFIG_HOME` inside the scratch dir, so a
  probe can never read or write the developer's real Neovim state.

Keymap assertions go through `nvim_get_keymap`, not by grepping Lua source.
Plugin-install integrity is `nvim --headless '+Lazy! sync' +qa` exit status;
plugin health is `:checkhealth`.

## `wezterm_probe <config.lua>`

`wezterm --config-file <config.lua> show-keys --lua`. Verified working with an
isolated config file. Two facts for whoever writes the wave-2 gate: the output
is the merged set (defaults **plus** the config's keys), so assert
`grep`-level presence of the intended bindings rather than diffing the whole
list; and `show-keys` needs no display, so it runs in a headless gate.

## Acceptance
- [x] `gates/fixtures/nu/config.nu` defines one keybinding named
      `gate_probe`. Measured: configured -> 1, bare `nu -c` -> 0. `nu_probe` on the fixture reports it present;
      the same expression through a bare `nu -c` reports it absent. Both
      halves asserted — the second is what proves the probe is not vacuous.
- [x] `gates/fixtures/nvim/init.lua` sets one normal-mode map with
      `desc = "gate probe"`. Measured: fixture -> 1, empty init -> 0. `nvim_probe` finds exactly one such entry via
      `nvim_get_keymap`; with the fixture replaced by an empty file it finds
      zero.
- [x] `nvim_probe` leaves `~/.local/share/nvim`, `~/.local/state/nvim` and
      `~/.config/nvim` untouched, proved with `snapshot_paths` /
      `assert_unchanged` over their directory listings. Listing, not content:
      `~/.local/share/nvim` holds 60,956 files on this machine and hashing
      them all costs more than the probe does. `snapshot_paths --deep` exists
      for the places where an in-place edit must be caught.
- [x] `gates/fixtures/wezterm/wezterm.lua` binds one key. `wezterm_probe`
      shows it; with the fixture's `keys` table emptied it does not. The key
      carries a `SendString 'gate_probe'` payload, because the first fixture
      used `ShowDebugOverlay` — which WezTerm already binds by default, so
      the probe would have passed on the defaults alone.
- [x] Every probe fails loudly when its binary is missing (simulated with a
      `PATH` that excludes that binary's directory) rather than reporting an
      empty result as a pass: rc 127 and a `PROBE-ERROR:` line, for all
      three.
- [x] `just gates` runs the probe self-tests as its own wave-independent
      preflight, so a broken probe cannot make a later wave look green —
      before the meta-gate, the registry check and any wave.

verify: `bash gates/probes.sh --selftest`

Proved RED before writing this spec: `gates/` does not exist; `bash
gates/probes.sh --selftest` → exit 127.

Est: 1.25h
