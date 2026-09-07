---
kind: reference
description: the placeholders `llm`'s `agents.json` substitutes — every agent's `cmd`, `env`, `unset`, `profile` template
read_when: "adding an agent to agents.json, or writing `args`/`env` that another agent's template needs to fill"
---

# llm-launcher-arg-fill

`llm`'s `agents.json` templates substitute these placeholders on
`str.format(**v)` — the same call applies to `cmd`, `env`, and `unset`:

| key | what it fills | example |
|---|---|---|
| `{model}` | the picked or passed model | `auto:free`, `opus-5`, `sonnet-5@opencode` |
| `{base}` | the proxy base URL | `http://127.0.0.1:4000` |
| `{key}` | the litellm master key | `sk-litellm-…` |
| `{context}` | the model's context window (sourced) | `200000`, `""` if unknown |
| `{home}` | the user's home directory | `/Users/feb` |
| `{args_json}` | the caller's args, JSON-encoded | `["--resume", "last"]` |

The `launch` section (for `llm -a <program>`) substitutes with `re`
regex instead of `str.format`, because a TOML-braced `-c` arg like
`model_providers.litellm={name="litellm",...}` collides with `format`'s
field-name parser. Every `launch.args` list is rendered with `re`; every
`agents.<name>.cmd`/`env` is rendered with `format`.

A program launched via `launch` exports the `env` keys after popping the
`unset` keys. The proxy is started if it is not answering, the
master key is loaded from `credentials.env`. The launch path does not
load the per-agent `profile` — that is for `llm <agent>`, not `llm -a`.