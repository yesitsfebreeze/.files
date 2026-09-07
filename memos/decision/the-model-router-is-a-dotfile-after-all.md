---
kind: decision
date: 2026-09-04
status: decided
description: the model router lives in home/ as one binary plus a registry; the 2026-09-02 answer that moved it to its own project is reversed
read_when: "touching the llm router, or asking where it lives"
---

# the-model-router-is-a-dotfile-after-all

## Decision

The model router is a dotfile. It is `home/dot_local/bin/executable_llm`
(one python3 file, no dependency beyond litellm on PATH) and
`home/dot_config/litellm/` — `providers.json`, `aliases.json`,
`agents.json`, `litellm_hooks.py`. `llm sync` builds the shelf
(`~/.local/state/litellm/models.json`) and litellm's config; `llm serve`
runs the proxy; `llm status` reads the record; `llm <agent> [model]` starts
an agent on a model; bare `llm` asks model, then agent. The manual page is
`internals/llm-router.md`.

## Why

- A thing every session starts through belongs where every session's config
  lives. Out of tree it was a second install step, a second repo to keep
  green, and a path nothing in the dotfiles could name.
- The reasons for moving it out were properties of the old code, not of the
  job: the credential coupling is gone (`credentials.env`), the state layout
  snapshot is data (`agents.json`), the release cycle collapsed into
  `llm sync`.
- `09-simplify` I2 (no PRD node for anything outside `home/`) holds again
  without an exception: the router is under `home/`.

## Consequences

- One binary, four JSON files, one launchd service pair. A new provider is a
  `providers.json` entry; a new agent is an `agents.json` entry; no code
  either way.
- The shelf and the record live in `~/.local/state/litellm/` — machine
  state, never deployed.
- `llm sync` restarts the proxy when the generated config changed; run it
  between sessions, not mid-conversation.