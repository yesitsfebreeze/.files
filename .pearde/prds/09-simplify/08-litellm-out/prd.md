---
state: specced        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 20        # higher first
complexity: 32      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
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
workflow: cut-a-feature-its-readers-still-name
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

## Questions

### Q1: Where the model router lives

You are choosing where the model-router stack lives: its own project, a hidden
part of this one, or nowhere at all. It is around nine hundred lines with its
own release cycle, it reads another tool's credential file, and every paid
route is currently out of credit?

1. **Its own project** — the router moves to a folder of its own under your development directory and installs itself onto your path from there. (recommended)
2. **Kept here, opt-in** — the router stays here but a fresh machine only gets it if a marker file exists; this one keeps its copy.
3. **Deleted** — the router goes entirely; the editor and the shell both open the assistant directly, on its own plan, with no proxy and no picker.

<!-- for the board: 5 scripts under home/dot_local/bin (cll, litellm-env, litellm-gen-config, litellm-up, llm-quota) + home/dot_config/nushell/litellm.nu; config.nu:236 source line; help/shell.nuon rows cll/llm/llm quota/llm regen; help/nvim.nuon 4 refs; hand-written internals/nushell-modules.md §litellm.nu and internals/neovim.md; nvim/lua/plugins/claude.lua terminal_cmd; home/.chezmoiremove needed on ALL three answers; 00-delivery/decisions/fzf-model-picker gains the R4 line. Answer decides spec01's footprint entirely. -->

## Answers

**Q1** *(answered 2026-09-02 16:22)* — Its own project — the router moves to a folder of its own under the development directory and installs itself onto the path from there.
