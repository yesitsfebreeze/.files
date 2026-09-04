# llm — the model router

A local OpenAI/Anthropic route (litellm) in front of every model you can
reach, and one tool that keeps it honest. Lives in this repo:
`home/dot_local/bin/executable_llm` and `home/dot_config/litellm/`
(`providers.json`, `aliases.json`, `agents.json`, `litellm_hooks.py`).

```
llm sync              providers.json → every model, price, caps, window, public
                      rank, our own record → models.json + litellm config
llm serve             run the proxy on that config
llm status            what's parked and why; who is best at which job
llm <agent> [model]   an agent on a model — `llm claude auto:free`, `llm pi
                      big-pickle`, `llm claude native:opus` (the Max plan);
                      no model → fzf picker. `llm cc` = the default agent.
```

One binary. `llm report <task> <model> <note…>` and `llm judge <task>
<model> [file]` add to the record by hand (a free-text note; a cheap
model's 1-5 score).

`~/.config/litellm/agents.json` says what an agent is: its `cmd` and `env` (templated with
`{model}`, `{base}`, `{key}`, `{context}`, `{home}`), an optional
`profile` — a config dir of its own, linked and copied from the real one so
a model switch inside the agent can't rewrite the real settings, with the
in-session model picker written to `model_picker` — and `native`, the
no-proxy hop for the agent's own models. Claude Code and pi are in there;
add an agent, no code.

## Keys

Keys live in `~/.local/state/litellm/credentials.env`, plain
`export VAR=value` lines, mode 600, one per provider — the VAR names are
the `key` fields in `providers.json`. Nothing else's credential store is
read. The proxy's own master key is generated next to it on first use.

## How a request is routed

`model: auto` (or `auto:free` / `auto:paid`) with `metadata.tags:
["task:<label>"]` naming the job. The hook (`litellm_hooks.py`, loaded by
the proxy) does a lookup in `models.json`: filter by tier, by what the
request carries against the model's stated caps (an image never goes to a
model that says text-only; a tools list never to one that says no tools),
and by parked-state; drop any whose window is smaller than the request;
order **paid, then free, then local** — a local model (ollama) is the last
resort, it answers only when every remote one is gone, never because it
scored well — and within each of those by the job's precomputed score; the
first goes out and *every* other candidate rides as litellm's per-request `fallbacks`,
so a request fails only when the whole shelf has. No model is asked how to
route — the request path is a sort, ~1ms. If nothing is eligible at all it
answers 503 "no model available right now" rather than hunting.

The job score per model is computed at `sync`: our own record for that
exact task label when there is one (success rate averaged with judge
scores), else the Arena rank for the nearest job (text / code / vision /
agent / document / search — a task label is mapped by keyword, an image
request is vision, a tools request is agent), else OpenRouter usage rank,
else unknown; free gets a small bonus so ties go to the cheaper model. One
request in ten leads with a model the task has no record for, so the record
grows.

Every call's outcome is appended to `performance.jsonl`. Every refusal
parks the model in `status.json` with the API's own reason, classified —
`no-credit` ("insufficient balance / credits", 402), `rate-limited`
("usage limit", 429), `unsupported` ("not supported"), else `error` — a
`since`, and a cooldown (6h / 15m / 24h / 5m). A parked model is off the
walk while any live one exists — one Claude Code turn used to try ~600 dead
routes before it found a model — and returns, soonest-first, only when
nothing else is left; it comes back by itself when the cooldown lapses and
is cleared the moment it answers. `llm status clear [alias]`
overrides.

## The registry

`~/.config/litellm/providers.json` is the only place a provider exists. Push an entry, `llm
sync`, its models are on the shelf:

| field | |
|---|---|
| `name` | the provider's name in every alias, chain and record |
| `kind` | `openai` (OpenAI-compatible `/models` + `/chat/completions`), `openrouter` (same, routed as litellm's openrouter/), `ollama` (a local daemon) |
| `base` | URL; the `/v1` root for `openai`/`openrouter` |
| `key` | env var holding the credential; omit if none |
| `free` | `true` when the provider never charges (ollama); otherwise tier is per model from the price it publishes |
| `store` | for a provider whose `/models` carries no price or window: the key under `~/.pi/agent/models-store.json` that does (opencode) |
| `cap` | at most this many auto-enumerated models |
| `skip` | substrings of ids not to offer (embeddings) |
| `num_ctx` | `ollama`: the window every local route is served at |

List order is the tie-break within a price tier when a model is served by
several providers. `aliases.json` holds the curated names (`opus-5` → each
provider's id) and the canonical Claude ids Claude Code needs to size its
context; everything else every provider serves is enumerated on top, the
same raw id on several providers becoming one alias with all those hops,
cheapest hop first.

Tier is per model from the price the provider publishes: `$0` in and out
is free (openrouter's `:free` ids, opencode's `big-pickle`, huggingface's
`is_free` upstreams); a prepaid balance at zero refuses paid models and
answers free ones (measured 2026-09-04). huggingface is not free by being
huggingface — its `/models` lists the upstream serving each model with
`is_free` and a price.

## Things measured, so nobody re-measures them

- Ollama with `OLLAMA_CONTEXT_LENGTH=262144` loads a 3B at 12.8 GB of KV,
  ~170s a load, and reloads on every request whose window differs. Local
  routes go through litellm's native `ollama_chat/` with `num_ctx` from the
  registry for that reason. Local models also reject Claude Code's
  `thinking` param outright; it is dropped per deployment.
- litellm bridges `/v1/messages` to the Responses API by default;
  opencode.ai/zen/go answers that with 429/500 — bridged via chat instead.
- Claude Code replays its own `thinking` blocks every turn; only Claude
  wants them back, openai-compatible upstreams 400 — stripped elsewhere.
- litellm's fallback call carries the request's `user`, not its metadata;
  the task label rides in `user` so the record blames the right model.
- Two non-auth reads of `pi` remain: `models-store.json` supplies opencode's
  prices and windows (its `/models` has neither). Cut it if `pi` goes.
- The claude agent's native hop execs into the dotfiles repo's nushell `cc`
  (its login picker), and its profile's `link` list is a snapshot of one
  Claude Code version's on-disk state layout — a new state dir goes unlinked,
  silently. Both live in `agents.json` now, unchanged in substance.
