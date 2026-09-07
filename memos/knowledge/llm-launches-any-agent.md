---
kind: knowledge
description: `llm -a <program>` starts any agent on the proxy — the program is never registered, only its default args and env are
read_when: "launching an agent through the proxy, or adding one to agents.json"
---

# llm-launches-any-agent

`llm -a <program> [args…]` starts any agent on the proxy. The program itself
is never looked up or registered: whatever is on PATH runs. What `agents.json`
registers under its `launch` key is the plumbing — per program:

- `args` — the default flags that wire it to the proxy, templated with
  `{model}` (`LLM_MODEL`, default `auto:free`), `{base}`, `{key}`, `{home}`;
  the caller's args are appended after them.
- `env` — the credential pair or key the agent reads, e.g. `OPENAI_API_KEY`
  for codex, `LITELLM_MASTER_KEY` for pi.
- `unset` — variables to drop before adding `env`'s, so a parent session's
  stale route cannot win.

An unregistered program still launches — no default args, no env, the proxy
started and reachable by whatever env the caller already carries. Registered
or not, the proxy is started if it is not answering, and the key is loaded
from `credentials.env`.

Measured 2026-09-07: codex through the launch path answers through the proxy
(`wire_api="responses"` — litellm's `/v1/responses` is served; `wire_api=
"chat"` was refused by codex 0.153.4, and a TOML-braced `-c` arg needs the
`braces="re"` substitution, because `str.format` reads `model_providers.{…}`
as a format field). pi answers with `auto:free` through the launch path; a
paid alias 402s because OpenRouter credits are spent — the router's walk
happens inside the proxy, so the launch spec only needs one key.

pi's provider block in `~/.pi/agent/models.json` carries
`apiKey: "$LITELLM_MASTER_KEY"` (a `$VAR` template pi resolves from env), so
the launch spec exports that name; the retired `!litellm-env` resolver was
the thing breaking `llm pi` after `08-litellm-out` deleted its script.

`llm <agent>` (the registered-agents path) is unchanged: `cmd`, `profile`,
`native` — the launch key is the third, lighter way in.