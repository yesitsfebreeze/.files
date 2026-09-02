---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 20        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/06-neovim-television
footprint:
  - home/dot_local/bin/executable_cll
  - home/dot_local/bin/executable_litellm-gen-config
  - home/dot_local/bin/executable_llm-quota
  - home/dot_local/bin/executable_litellm-env
  - home/dot_local/bin/executable_litellm-up
  - home/dot_config/litellm
  - home/dot_config/nushell/litellm.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nvim/lua/plugins/claude.lua
---

# 08-litellm-out — the one thing here that is not a dotfile

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: the litellm / `cll` / `llm-quota` stack is about 980 lines across
six scripts. It is a multi-provider LLM router driven by another tool's
credential store (`~/.pi/agent/auth.json`), it hardcodes nineteen Claude
Code state directories to symlink (`cll:230-232`), and on 2026-09-01 every
paid hop returned 402. It is a product with its own lifecycle living in a
dotfiles repo. This child moves it out, to the destination the user picks.

## Requirements

- [ ] **R1** — The user chooses the destination; the analyst puts it as the
      one question with three answers: (a) its own repo under `~/dev/`,
      deployed by its own install step and recommended; (b) an opt-in
      subtree of this repo excluded by `.chezmoiignore` unless a flag file
      exists; (c) deleted outright, `cc` and `cr` launching Claude Code
      directly.
- [ ] **R2** — The five scripts, `home/dot_config/litellm/` and
      `litellm.nu` leave `home/` per the answer. `config.nu` stops sourcing
      `litellm.nu`; the `cll`, `llm` and `llm regen` entries leave
      `shell.nuon`.
- [ ] **R3** — `claude.lua`'s `terminal_cmd` points at what remains: `cll`
      if it is still on PATH from its new home, `claude` otherwise.
- [ ] **R4** — The `decisions/fzf-model-picker` node gains one line saying
      where the picker now lives.
- [ ] **R5** — `just manual` is run after the `shell.nuon` edit.

## Acceptance

- [ ] `rg -l 'litellm|cll' home/ | wc -l` prints 0, or only `claude.lua` when answer (a) keeps `cll` on PATH
- [ ] `nu -l -c 'which cll'` answers per the chosen destination
- [ ] `<leader>xc` in nvim opens Claude Code
- [ ] `cc` in the shell opens Claude Code

## Out of scope

- Fixing the 402s or the auth-store coupling — that is the stack's own work
  in its new home.
