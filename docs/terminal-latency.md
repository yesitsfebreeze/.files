# Terminal latency and double Space

In a Nushell prompt inside tmux, tap Space twice 60–200 ms apart to open the cockpit. The first Space is delivered immediately. The completed gesture removes that Space from the input; slower taps remain literal. F5 remains unchanged and works in other applications.

Tmux owns the short-lived key table and native timers. Nushell handles only the completed gesture, not normal Space or cursor keys: Reedline host-command bindings can discard later keys in the same input batch. Any intervening key falls back to the normal table. The gesture checks the client and visible cursor position before sending its private F13 sequence. Pasted text stays literal; a detected repeat train stays blocked until a 500 ms pause. Terminals do not reliably identify physical key releases, so this is timing-based repeat suppression.

Neovim handles Insert and command-line modes directly, validating the buffer, window, cursor, content, and change counter before removing exactly one Space. In Normal mode, Space–Space uses the existing Space leader. Failed cockpit launches restore literal spaces while the same input is still unchanged.

The cockpit reader uses unbuffered zsh `sysread` with a 20 ms escape-sequence continuation timeout. It consumes exactly one sequence, leaving following input untouched. Tmux's existing 10 ms escape timeout is retained.

The Git prompt uses one porcelain-v2 status query and a per-repository OS file lock shared across panes. Cache writes are atomic, freshness is 750 ms, and a failed refresh preserves the last good value. Locks release automatically when their process exits.

WezTerm uses WebGpu with the existing 60 FPS limits. This selects the alternative backend; it does not establish a measured rendering speedup. A new WezTerm process is needed to reliably switch renderers.

## Verification

Verified on 2026-10-06: all 30 behavioral tests passed in two consecutive runs (9.56 s and 10.35 s). Escape response measured 27.9 ms and 24.5 ms. The 12-worker Git test performed one shared Git probe. The real cockpit opened and closed with the input unchanged.

The Nu and Neovim adapters invoke the cockpit through its Bash interpreter explicitly. Fresh executable test scripts were observed taking 2.7–4.8 seconds on first direct execution; interpreter-based launches removed that delay without changing the gesture window or weakening the input assertions.

```sh
cd ~/dev/dotfiles
python3 scripts/test-latency.py
```

The suite uses isolated PTYs, tmux servers, Nushell prompts, Neovim processes, and temporary Git repositories. It covers input preservation, fast and slow taps, Unicode, cursor cancellation, pasting, repeated spaces, launch failure, real popup open/close, escape decoding, and concurrent Git refreshes.

After deployment, restart an existing Nushell with `exec nu`; reopen existing Neovim sessions to load their mappings. New panes and editor sessions load the new configuration automatically.
