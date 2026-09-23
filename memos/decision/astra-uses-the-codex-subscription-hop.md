---
kind: decision
date: 2026-09-07
status: decided
description: Astra is available to LiteLLM-compatible agents through the saved Codex Pro login, with an explicit subscription pin
read_when: "using Astra with another agent or maintaining the ChatGPT bridge"
---

# astra-uses-the-codex-subscription-hop

The `chatgpt` provider uses `codex_shim.py` to forward Responses requests
with the OAuth login in `~/.codex/auth.json`. The login on this host reports
Pro. `astra@chatgpt` pins that subscription route; bare `astra` is a normal
router preference and can fall back to other paid-tier models.

The bridge's declared shelf is read directly during sync, avoiding a
startup dependency on the running proxy. Astra's 272000-token context is
from the local Codex model catalog, not the larger general API window.
The provider is outside `auto:free`: a subscription has its own allowance.

The bridge requires the proxy master key locally. Upstream it removes
LiteLLM's `responses/` model prefix and unsupported `user`, `metadata`, and
`max_output_tokens` fields, supplies instructions, and forces streaming
and `store: false`. A collected response retains `response.output_item.done`
items when the terminal event omits output. This is a custom Codex backend
integration, whose compatibility must be checked when either side changes.

The shell manual documents Claude Code, pi, and the generic Codex launcher.
The routing decision belongs to [[the-model-router-is-a-dotfile-after-all]].
