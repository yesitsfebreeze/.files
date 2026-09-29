---
kind: knowledge
description: an inactive pane recedes 45% and that dim is a COMPUTED COLOUR, because tmux 3.7c drops every style attribute and has no percentage in style syntax
read_when: "dimming inactive panes, touching window-style or window-active-style, or reaching for the `dim` attribute anywhere in tmux"
---

# inactive-panes-recede-by-a-computed-colour

**The dimming is a colour, because the attribute does not survive tmux.**
tmux merges **only the colours** of `window-style` into a cell, never the
attributes. Measured 2026-09-27 on 3.7c: with `window-style 'dim'` (and,
separately, `bold`, `underscore`, `reverse`, `italics`, `dim,noattr`) the
attached client receives no attribute escape in the inactive pane at all —
the text arrives after a bare `\e[m`. `infocmp tmux-256color` does advertise
`dim=\E[2m` and the terminal honours it when written directly, so the loss is
tmux's, not the emulator's. `capture-pane -e` cannot show this either: it
returns the application's own SGR and never reflects `window-style`, so the
only honest read is the bytes on a real client's pty.

**A percentage is not expressible either.** In 3.7c style syntax `dim=15%`,
`dim=0.15`, `bg=#ffffff%15`, `fg=#a87569%85` and `fg=default,dim=15%` all fail
with `invalid style: …` and leave the option at `default`. Only bare attribute
names and plain `fg=`/`bg=` colours parse. So 45% is computed per scheme:
base05 (the foreground) blended toward base00 (the background), each channel
`(c05*55 + c00*45)/100`. `theme.sh` derives it into `colors.conf` as
`setw -g window-style 'fg=$dim'` — the option tmux actually applies to an
inactive pane; for `base16-caroline` it is `#694842`. `tmux.conf` carries the
ANSI-slot fallback `set -gw window-style 'fg=colour8'` (colour8 is base03) for
a checkout that has never applied a theme and has no `colors.conf`. The
fallback is a fixed slot, not a blend: a fallback too subtle to see is
indistinguishable from no dimming.

**`window-active-style` MERGES over `window-style`, and `default` there is not
"no override".** With `window-style 'fg=#694842'` and
`window-active-style 'fg=default,bg=default'` the *active* pane takes the
dimming colour as well — every pane in the window dims, which is how this
first went in. `fg=terminal,bg=terminal` is the repair: `terminal` is the
emulator's own colour, so the active pane gets no override, and it leaves the
ground alone — any explicit `bg=` paints an opaque ground over every pane and
kills the window's opacity and blur.

**Only text that names no colour of its own recedes.** In every measurement a
red or green span in an inactive pane stayed exactly `\e[31m`/`\e[32m`. A
plain shell prompt dims fully; a syntax-highlighted buffer or a coloured
prompt in an inactive pane stays bright. There is no per-pane fade behind
this — it is one foreground colour for the pane's default-coloured text, and
that is the whole extent of the mechanism.

This is a constraint that took a measurement to find, so it is on the record
and the config carries a one-line `TRAP` pointing here
([[hard-won-constraints-belong-on-the-record]]). The colour is derived, never
hardcoded, because every reader of the palette is downstream of one
`tinty apply` ([[tinty-owns-the-palette-every-reader-follows]]).
