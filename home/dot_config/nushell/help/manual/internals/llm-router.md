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
llm -a <program>      any agent on the proxy — registered or not: the program
                      runs from PATH with the proxy env; agents.json's
                      `launch` section carries the default args and env per
                      program, nothing more.
```

One binary. `llm report <task> <model> <note…>` and `llm judge <task>
<model> [file]` add to the record by hand (a free-text note; a 1-5 score
from `minimax-m3-free`, or `auto:free` when it is rate-limited —
`LLM_JUDGE_MODEL` overrides).

`~/.config/litellm/agents.json` says what an agent is: its `cmd` and `env` (templated with
`{model}`, `{base}`, `{key}`, `{context}`, `{home}`), an optional
`profile` — a config dir of its own, linked and copied from the real one so
a model switch inside the agent can't rewrite the real settings, with the
in-session model picker written to `model_picker` — and `native`, the
no-proxy hop for the agent's own models. Claude Code and pi are in there;
add an agent, no code. The `launch` section is the lighter way in:
`llm -a <program>` runs anything from PATH with a `launch[<program>]`
entry's default `args` and `env` — an agent nobody registered still runs.

## The service

The proxy is a launchd agent (`~/Library/LaunchAgents/litellm.plist`,
`KeepAlive`): it is up from login, comes back within seconds of dying, and
litellm takes about two minutes to load the shelf's ~2000 deployments —
Claude Code's own retries cover that gap. `llm sync` runs nightly at 04:30
(`litellm-sync.plist`, log in `~/.local/state/litellm/sync.log`) so the
scores, the shelf and the windows are never older than a day; when the
generated config differs from the one the proxy loaded it restarts the
proxy (`launchctl kickstart -k`) — an un-restarted proxy was stale for
days once, silently. A manual `llm sync` does the same, so run it between
sessions. `chezmoi apply` (re)loads both agents only when the hook or a
plist changed, because loading restarts the proxy and cuts every request
in flight. The parked-model probe starts with the proxy, not with the
first request, and sweeps its batch concurrently — a minute a sweep. Under
launchd the proxy logs to `proxy.log` itself, rotated at 20 MB on start.
On a machine without the agent, `llm <agent>` still spawns the proxy
detached.

## Keys

Keys live in `~/.local/state/litellm/credentials.env`, plain
`export VAR=value` lines, mode 600, one per provider — the VAR names are
the `key` fields in `providers.json`. Nothing else's credential store is
read. The proxy's own master key is generated next to it on first use.
`llm serve` is the launch: litellm resolves every `os.environ/` before it
imports the hook, so a bare `litellm --config …` without the keys in its env
would park the whole shelf as "Missing credentials" within minutes — the
hook refuses to start instead.

## How a request is routed

`model: auto` (or `auto:free` / `auto:paid`) with `metadata.tags:
["task:<label>"]` naming the job; without a tag the request is ranked and
recorded under the job its shape says (a tools list is agent, an image is
vision, a document is document, else text) — "untagged" used to be a column
of its own that every Claude Code turn scored and no job read. The hook (`litellm_hooks.py`, loaded by
the proxy) does a lookup in `models.json`: filter by tier, by what the
request carries against the model's stated caps (an image or a PDF never
goes to a model that says text-only; a tools list never to one that says
no tools),
and by parked-state; drop any whose window is smaller than the request
plus the answer it asks for (`max_tokens`) — an unknown window is out, not
"fits"; the size is chars / 3.5 with every image or page counted flat at
1600 tokens, not by its base64 (six screenshots in tool results once
weighed in as 9.1M tokens, and no window holds that);
order by the job's precomputed score, best first — free carries a small
bonus so a tie goes to the cheaper model, and a local model (ollama) is the
last resort, it answers only when every remote one is gone, never because
it scored well; the first goes out and *every* other candidate rides as
litellm's per-request `fallbacks`, so a request fails only when the whole
shelf has (`max_fallbacks` in the generated config is the shelf size —
litellm stops after five hops otherwise). litellm walks that list
when a model refuses before its first byte; the hook walks it when a model
answers 200 and then puts its error in the stream (openrouter's "Provider
returned error" 429 does), as long as no content has reached the client —
the bridge's own `message_start` does not count, and a restart does not
repeat it (the client SDK ends the stream on a second one). The restart
carries the request, not what litellm hung on it in the first pass: re-sent
whole, a Deployment object went into the upstream body and the walk failed
in 17ms (2026-09-06). No model is asked how
to route — the request path is a sort, ~1ms. If nothing is eligible at all it
answers 503 "no model available right now" rather than hunting.

A bare alias (`glm-5.3-flash-cloud`, `opus-5`) is a preference, not a pin:
it goes out first, its own other hops ride behind it, then the walk of its
tier. Ollama went down for twenty minutes and a session on
`glm-5.3-flash-cloud` got 360 500s with nothing behind it (2026-09-04).
`alias@provider` is a pin and gets no walk.

The job score per model is computed at `sync`: our own record for that
exact label when there is one (success rate pulled toward the public prior
by three phantom calls — one 500 used to score a model 0 for good — averaged
with judge scores; a refusal for credit, quota, existence or size is parking,
not a verdict, and does not count), else the Arena rank for the nearest job (text / code / vision /
agent / document / search — a task label is mapped by keyword, an image
request is vision, a tools request is agent), else OpenRouter usage rank,
else unknown; free gets a small bonus so ties go to the cheaper model. One
request in ten leads with a model the task has no record for, so the record
grows.

Every call's outcome is appended to `performance.jsonl`. Every refusal
parks the model in `status.json` with the API's own reason, classified —
`no-credit` ("insufficient balance / credits", 402), `rate-limited`
("usage limit", 429), `unsupported` ("not supported"), `context` (the
window was too small), else `error` — a `since`, and an `until`: the reset
time the API itself named (openrouter's `X-RateLimit-Reset`, "try again in
30 seconds") when there is one, else a cooldown by kind (6h / 2m / 24h /
24h / 5m — a bare 429 is capacity, the same model answered 42s later). When
the reason names something the user can do, the park carries it as `fix`
("add credits: <url>", "opt in: <url>", "gone: drop it at sync") and
`llm status` sums those up under "to unlock". A parked model is off the walk while any live one exists — one
Claude Code turn used to try ~600 dead routes before it found a model —
and it does not come back by itself: once `until` has passed the proxy
asks it for one token (a sweep a minute, twenty models a sweep, no
fallbacks so a sibling hop cannot answer for it) and clears it on an
answer or parks it again on a refusal, so no user request leads with a
model that is still dead and `llm status`'s "probe in" is a check the
proxy will make. Nothing else drops a park — a mark used to sweep every
lapsed entry out with it, and those returned to the walk unprobed. Only when nothing else is left do the parked come
back, soonest-first and one sweep's worth (twenty), without a probe. A park
whose alias left the shelf at a sync is dropped by the next sweep. A real answer clears a park too.
`llm status clear [alias]` overrides.

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
| `num_ctx` | `ollama`: the window every route served on this machine gets; a `:cloud` model keeps its trained window |

Every model carries a window, never a blank: the hop states it, else
`sync` asks the sources that publish it — a huggingface hop's own
`config.json` (`max_position_embeddings`; gated repos 403), then litellm's
public model table matched by name core (the narrowest match) — else the
floor, 32768, printed by name so it is seen. A context refusal names the
real window; the hook records it and the next `sync` sizes the model by it
over anything stated. `llm needs` shows those. The window feeds the walk,
`max_input_tokens` in the litellm config, and `{context}` for the agent
(`CLAUDE_CODE_MAX_CONTEXT_TOKENS` for Claude Code — a pinned model's own;
`auto` leaves it unset, the walk sizes each turn).

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
- An ollama `:cloud` model reports its trained window in `/api/tags`
  (`details.context_length`, 1M for glm-5.3-flash) and runs at it on
  ollama.com; capped to `num_ctx` it launched Claude Code with a 32K
  limit, which stopped at 56K with "Prompt is too long" (2026-09-04).
  A blank window let the walk send a 67K request to a 32K model the same
  day — unknown meant "fits".
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
