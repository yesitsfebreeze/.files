---
title: 07-multiplexer/05-copy-and-clipboard
type: prd
state: done
origin: requested
priority: 20
complexity: 29
blast: mid
needs:
  - "[[wiki/board/07-multiplexer/01-session-and-windows]]"
---

# 05-copy-and-clipboard — Copy mode on `copy-mode-vi`: `Ctrl+Shift+X` enters with the selection and the per-pane toggle cleared, `c` cycles cell→word→line per pane, `y` copies (Q6). The sink is pbcopy when the pane is on this machine and OSC 52 when it is not (Q14), which is the only arrangement where copying works both at this desk and over ssh. Terminal.app ignores OSC 52 and will fail silently there; say so in the manual entry rather than papering over it.

`state: done · origin: requested · priority 20 · complexity 29 · blast mid`

## Fed by (needs this one)

- [[07-multiplexer/08-wezterm-reduction]]
- [[07-multiplexer/09-manual-entries]]

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/01-session-and-windows]]

## Specs

- [[prds/07-multiplexer/05-copy-and-clipboard/specs/spec01]]
- [[prds/07-multiplexer/05-copy-and-clipboard/specs/spec02]]
