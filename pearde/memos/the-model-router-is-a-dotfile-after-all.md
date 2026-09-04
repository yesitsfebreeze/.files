---
memo: the-model-router-is-a-dotfile-after-all
kind: decision
status: decided
tags:
  - memo
  - kind/decision
  - status/decided
subject: the model router lives in home/ as one binary plus a registry; the 2026-09-02 answer that moved it to its own project is reversed
date: 2026-09-04
prds:
  - 09-simplify/08-litellm-out
  - 00-delivery/decisions/fzf-model-picker
---

# the-model-router-is-a-dotfile-after-all — one binary, a registry, in `home/`

## Decision

The model router is a dotfile. It is `home/dot_local/bin/executable_llm`
(one python3 file, no dependency beyond litellm on PATH) and
`home/dot_config/litellm/` — `providers.json`, `aliases.json`,
`agents.json`, `litellm_hooks.py`. `llm sync` builds the shelf
(`~/.local/state/litellm/models.json`) and litellm's config; `llm serve`
runs the proxy; `llm status` reads the record; `llm <agent> [model]` starts
an agent on a model; bare `llm` asks model, then agent. The manual page is
`internals/llm-router.md`.

## What it beat

The 2026-09-02 answer to `08-litellm-out` Q1: *its own project under
`~/dev/`*. That answer was right about the thing it was looking at — six
scripts, ~980 lines, a nushell skin, another tool's credential store — and
that thing no longer exists. What replaced it on 2026-09-04 is one 750-line
binary reading four JSON files, with its own credential file, no LLM in the
request path, and a picker that nvim's `<leader>xc` and the shell share.
"Small and mature enough now, and always useful" — the user's words.

## Why

- A thing every session starts through belongs where every session's
  config lives. Out of tree it was a second install step, a second repo to
  keep green, and a path (`~/dev/llm-router`) nothing in the dotfiles could
  name.
- The reasons for moving it out were properties of the old code, not of
  the job: the credential coupling is gone (`credentials.env`), the state
  layout snapshot is data (`agents.json`), the release cycle collapsed into
  `llm sync`.
- `09-simplify` I2 (no PRD node for anything outside `home/`) now holds
  again without an exception: the router is under `home/`.

## Consequences

- `08-litellm-out` is `failed`, not `done`: its acceptance (`rg -l
  'litellm|cll' home/` prints 0) is false by design now. Its R2–R5 removals
  did happen — the six-file stack, `litellm.nu`, the four `shell.nuon` rows
  are gone — replaced, not restored.
- The lane `lane/09-simplify-08-litellm-out` must not merge: it deletes
  what is now the router's home.
- `~/dev/llm-router` is dead weight; nothing points at it.
