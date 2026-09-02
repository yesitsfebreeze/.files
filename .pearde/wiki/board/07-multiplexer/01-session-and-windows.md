---
title: 07-multiplexer/01-session-and-windows
type: prd
state: done
origin: requested
priority: 20
complexity: 32
blast: high
---

# 01-session-and-windows — The tmux base: one session `main` reached by an idempotent `new-session -A -s main`, stable window indices (`base-index 1`, `renumber-windows off`), and the terminal-integration floor every other child sits on — `tmux-256color` with a `screen-256color` fallback for minimal hosts, `*:RGB` and undercurl overrides, `escape-time 10` so Esc does not lag in nvim, `focus-events on`, OSC passthrough. `default-command` starts nushell resolved on PATH with a fallback, never the absolute launchd-era path, because a remote's nu is somewhere else. Lazily created windows start at `~` (Q14).

`state: done · origin: requested · priority 20 · complexity 32 · blast high`

## Fed by (needs this one)

- [[07-multiplexer/02-key-tables]]
- [[07-multiplexer/03-status-bar]]
- [[07-multiplexer/04-palette-delivery]]
- [[07-multiplexer/05-copy-and-clipboard]]
- [[07-multiplexer/07-persistence]]
- [[08-claude-agent/03-tmux-config]]

## Children (derived from this)

- [[00-delivery/corrections/done-nodes-with-unticked-boxes]]
- [[00-delivery/corrections/done-nodes-with-unticked-boxes/box-audit-check]]
- [[00-delivery/corrections/done-nodes-with-unticked-boxes/closing-guard-status]]
- [[00-delivery/corrections/done-nodes-with-unticked-boxes/drain-the-backlog]]
- [[00-delivery/corrections/retired-phrases-mention-vs-use]]
- [[00-delivery/wave-registry-keying]]
- [[05-platform/02-package-provisioning/tmux-not-installed-on-the-host]]

## Specs

- [[prds/07-multiplexer/01-session-and-windows/specs/spec01]]
- [[prds/07-multiplexer/01-session-and-windows/specs/spec02]]
- [[prds/07-multiplexer/01-session-and-windows/specs/spec03]]
