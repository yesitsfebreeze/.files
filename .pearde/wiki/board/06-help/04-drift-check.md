---
title: 06-help/04-drift-check
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
needs:
  - "[[01-capsule/02-dev-image]]"
  - "[[01-capsule/01-container-lifecycle]]"
  - "[[01-capsule/03-credential-propagation]]"
  - "[[01-capsule/04-recent-workspaces]]"
  - "[[00-delivery/decisions/tinty]]"
  - "[[00-delivery/decisions/fzf]]"
  - "[[00-delivery/decisions/wallpaper-opacity]]"
  - "[[03-editor/01-options]]"
  - "[[03-editor/06-explorer]]"
  - "[[03-editor/07-formatting]]"
  - "[[03-editor/12-small-plugins]]"
  - "[[03-editor/13-statusline]]"
  - "[[03-editor/14-shift-select]]"
  - "[[03-editor/15-markdown-tables]]"
  - "[[03-editor/04-plugin-manager]]"
  - "[[03-editor/02-keymaps]]"
  - "[[03-editor/03-autocmds]]"
  - "[[03-editor/11-colorscheme]]"
  - "[[03-editor/05-completion]]"
  - "[[03-editor/09-lsp]]"
  - "[[03-editor/10-treesitter]]"
  - "[[03-editor/08-telescope]]"
  - "[[00-delivery/verification-gates]]"
  - "[[06-help/01-content-model]]"
  - "[[06-help/02-help-command]]"
  - "[[06-help/03-browser]]"
  - "[[06-help/05-agent-interface]]"
  - "[[05-platform/01-deploy-mechanism/repo-skeleton]]"
  - "[[05-platform/02-package-provisioning/packages-installer]]"
  - "[[05-platform/02-package-provisioning/homebrew-bootstrap]]"
  - "[[05-platform/03-shell-init-generation]]"
  - "[[05-platform/01-deploy-mechanism/managed-config]]"
  - "[[04-shell/01-core-config]]"
  - "[[04-shell/02-aliases-utilities]]"
  - "[[04-shell/06-listing]]"
  - "[[04-shell/03-zoxide]]"
  - "[[04-shell/04-television]]"
  - "[[04-shell/05-history]]"
  - "[[04-shell/07-quicklist]]"
  - "[[04-shell/08-claude-launchers]]"
  - "[[02-terminal/01-appearance]]"
  - "[[02-terminal/02-startup-layout]]"
  - "[[02-terminal/03-f5-jump-mode]]"
  - "[[02-terminal/04-copy-mode]]"
  - "[[02-terminal/05-tab-content-state]]"
  - "[[02-terminal/06-launchd-path]]"
  - "[[00-delivery/corrections/w0-1-terminal-inventory]]"
  - "[[00-delivery/corrections/w0-2-terminal-respec]]"
  - "[[00-delivery/corrections/w0-3-platform-rewrite]]"
  - "[[00-delivery/corrections/w0-4-s2-corrections]]"
  - "[[00-delivery/corrections/w0-5-capsule-rebase]]"
  - "[[00-delivery/corrections/w0-6-live-bugs]]"
---

# Drift check

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/shell-y-entry-missing-review-row]]
- [[00-delivery/finish-line/drift-check-terminal-surface]]
- [[06-help/01-content-model/coverage]]

## Needs (gates this one behind)

- [[01-capsule/02-dev-image]]
- [[01-capsule/01-container-lifecycle]]
- [[01-capsule/03-credential-propagation]]
- [[01-capsule/04-recent-workspaces]]
- [[00-delivery/decisions/tinty]]
- [[00-delivery/decisions/fzf]]
- [[00-delivery/decisions/wallpaper-opacity]]
- [[03-editor/01-options]]
- [[03-editor/06-explorer]]
- [[03-editor/07-formatting]]
- [[03-editor/12-small-plugins]]
- [[03-editor/13-statusline]]
- [[03-editor/14-shift-select]]
- [[03-editor/15-markdown-tables]]
- [[03-editor/04-plugin-manager]]
- [[03-editor/02-keymaps]]
- [[03-editor/03-autocmds]]
- [[03-editor/11-colorscheme]]
- [[03-editor/05-completion]]
- [[03-editor/09-lsp]]
- [[03-editor/10-treesitter]]
- [[03-editor/08-telescope]]
- [[00-delivery/verification-gates]]
- [[06-help/01-content-model]]
- [[06-help/02-help-command]]
- [[06-help/03-browser]]
- [[06-help/05-agent-interface]]
- [[05-platform/01-deploy-mechanism/repo-skeleton]]
- [[05-platform/02-package-provisioning/packages-installer]]
- [[05-platform/02-package-provisioning/homebrew-bootstrap]]
- [[05-platform/03-shell-init-generation]]
- [[05-platform/01-deploy-mechanism/managed-config]]
- [[04-shell/01-core-config]]
- [[04-shell/02-aliases-utilities]]
- [[04-shell/06-listing]]
- [[04-shell/03-zoxide]]
- [[04-shell/04-television]]
- [[04-shell/05-history]]
- [[04-shell/07-quicklist]]
- [[04-shell/08-claude-launchers]]
- [[02-terminal/01-appearance]]
- [[02-terminal/02-startup-layout]]
- [[02-terminal/03-f5-jump-mode]]
- [[02-terminal/04-copy-mode]]
- [[02-terminal/05-tab-content-state]]
- [[02-terminal/06-launchd-path]]
- [[00-delivery/corrections/w0-1-terminal-inventory]]
- [[00-delivery/corrections/w0-2-terminal-respec]]
- [[00-delivery/corrections/w0-3-platform-rewrite]]
- [[00-delivery/corrections/w0-4-s2-corrections]]
- [[00-delivery/corrections/w0-5-capsule-rebase]]
- [[00-delivery/corrections/w0-6-live-bugs]]

## Children (derived from this)

- [[00-delivery/corrections/help-nvim-lsp-descs]]

## Decisions

- [[an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it]] — an invariant naming a defect must be re-measured before a child inherits it
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
