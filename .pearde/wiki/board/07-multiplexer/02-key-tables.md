---
title: 07-multiplexer/02-key-tables
type: prd
state: done
origin: requested
priority: 20
complexity: 34
blast: mid
needs:
  - "[[wiki/board/07-multiplexer/01-session-and-windows]]"
---

# 02-key-tables — F5 and F6 as tmux bindings and nothing in WezTerm. F5 pushes one table — the switcher — where an arrow splits in that direction with `-c "#{pane_current_path}"`, a digit selects window N or creates it at that index when absent (Q2), and `a`–`i` select pane index 1–9 (Q3). Every letter stays bound so a mistyped one cancels rather than leaking a character — the reason `02-terminal/03-f5-jump-mode` R2 gives still holds on the new mechanism. `bind -T jump F5 send-keys F5` is the double-tap that forwards a key to a nested session (Q10); F6 is never forwarded, because the palette belongs to the outermost terminal. Corrected 2026-08-31: the arrows moved into the F5 table and F4 was retired — one mode, not two. Corrected 2026-09-01, on the user's instruction: the switcher no longer stays armed after a pick, and gained `q` for kill-pane. A letter, an arrow and `q` re-arm nothing and so END the mode — `F5 b` is two keystrokes and you are typing again. A digit ends it too, unless the window it lands on holds more than one pane, in which case it pushes a SECOND table, `jump-pane`, carrying the nine letters and `Escape` and nothing else; `F5 1 b` is therefore the second pane of window 1 in two keys. The stay-or-leave test is read AFTER the jump (`if -F '#{==:#{window_panes},1}'` following the select), because the question is about the window you landed on. `q` is absent from `jump-pane` on purpose: a killed pane is unrecoverable, `F5` is a deliberate press and a `q` straight after it is deliberate too, while a `q` in the state a digit leaves you in is the first letter of a word — the table the key lives in is the only guard there is.

`state: done · origin: requested · priority 20 · complexity 34 · blast mid`

## Fed by (needs this one)

- [[07-multiplexer/08-wezterm-reduction]]
- [[07-multiplexer/09-manual-entries]]

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/01-session-and-windows]]

## Specs

- [[prds/07-multiplexer/02-key-tables/specs/spec01]]
- [[prds/07-multiplexer/02-key-tables/specs/spec02]]
