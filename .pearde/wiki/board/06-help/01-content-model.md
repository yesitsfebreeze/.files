---
title: 06-help/01-content-model
type: prd
state: done
origin: requested
priority: 40
complexity: 0
blast: low
---

# Content model

`state: done · origin: requested · priority 40 · complexity 0 · blast —`

## Fed by (needs this one)

- [[01-capsule/01-container-lifecycle]]
- [[01-capsule/02-dev-image]]
- [[01-capsule/03-credential-propagation]]
- [[01-capsule/04-recent-workspaces]]
- [[02-terminal/01-appearance]]
- [[02-terminal/03-f5-jump-mode]]
- [[02-terminal/04-copy-mode]]
- [[03-editor/01-options]]
- [[03-editor/02-keymaps]]
- [[03-editor/03-autocmds]]
- [[03-editor/04-plugin-manager]]
- [[03-editor/05-completion]]
- [[03-editor/06-explorer]]
- [[03-editor/08-telescope]]
- [[03-editor/09-lsp]]
- [[03-editor/10-treesitter]]
- [[03-editor/11-colorscheme]]
- [[03-editor/12-small-plugins]]
- [[03-editor/13-statusline]]
- [[03-editor/14-shift-select]]
- [[04-shell/01-core-config]]
- [[04-shell/02-aliases-utilities]]
- [[04-shell/03-zoxide]]
- [[04-shell/04-television]]
- [[04-shell/05-history]]
- [[04-shell/06-listing]]
- [[04-shell/07-quicklist]]
- [[04-shell/08-claude-launchers]]
- [[06-help/01-content-model/coverage]]
- [[06-help/02-help-command]]
- [[06-help/04-drift-check]]
- [[06-help/06-manual-markdown]]

## Specs

- [[prds/06-help/01-content-model/specs/spec01]]
- [[prds/06-help/01-content-model/specs/spec02]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
