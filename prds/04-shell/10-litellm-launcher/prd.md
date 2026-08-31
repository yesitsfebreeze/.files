---
state: done
priority: 26
est: 4h
task: S.10
mode: hitl
needs:
  - 04-shell/08-claude-launchers
verify: ""
origin: requested
---

# LiteLLM model launcher

Parent: [Nushell epic](../prd.md) · C 6 · U 8 · net-new

Purpose: `cc`/`cr` ([`08`](../08-claude-launchers/prd.md)) launch Claude Code on
the Max plan, which is one provider and one bill. This node adds `cll` — the
same launcher pointed at a local LiteLLM proxy — so any model we hold credit
for is one pick away, plus `llm` to see what exists and `llm quota` to see what
is left to spend. It is `hitl` because the routing order is a money decision:
which provider drains first is not a taste question, and the answer changes
whenever a balance does.

The proxy is an OpenAI-compatible gateway on `127.0.0.1:4000` fronting zenmux,
opencode-zen, opencode-go, openrouter and a local ollama. Claude Code speaks to
it through `ANTHROPIC_BASE_URL` and its Anthropic-shaped `/v1/messages`
endpoint; pi reaches the same routes through a `litellm` provider in
`~/.pi/agent/models.json`.

## Requirements

- [x] **R1** — `cll` with no argument opens a fuzzy picker of every reachable
      model; `cll <model>` skips it; `cll <model>@<provider>` pins one hop.
- [x] **R2** — The picker is **fzf**, grouped by provider: a dim header per
      group carrying that provider's balance, models indented beneath. This is
      the second named exception to epic invariant I3, decided 2026-08-25 and
      recorded in
      [`decisions/fzf-model-picker`](../../00-delivery/decisions/fzf-model-picker/prd.md).
      Flags that are load-bearing, not style: `--nth=1` (**not** 2 — `--with-nth`
      re-indexes, so `--nth` counts against the transformed line; `--nth=2`
      searched the chain column and `opus` matched nothing, fzf 0.74.3),
      `--accept-nth=1` to return the bare key, and `--ansi` for the weights.
      fzf has no unselectable row, so a header's key is a sentinel and Enter on
      one re-opens the picker.
- [x] **R3** — Every row carries its **own** provider column, not merely the
      group header above it. fzf drops non-matching lines, so a header cannot
      stay pinned over its group once a query is typed — filtering to `opus`
      would otherwise leave a column of models with no way to tell which router
      each came from. The header gives the shape at rest; the column is what
      survives the query. A proxied model also shows its remaining fallback
      chain, because the first provider is only the first attempt.
- [x] **R3b** — The picker lives in `cll`, not in the nushell module, so every
      shell gets the same one. An earlier split (nushell picker, script
      launcher) let a stale shell call the script with no model and land in a
      fallback path nothing had exercised — which is how the `mapfile` bug
      below reached a real terminal.
- [x] **R4** — `native:*` rows run Claude Code's own default models on the Max
      plan with **no proxy env set** — unset, not merely not-set: launched
      from inside a cll session the parent exports `ANTHROPIC_BASE_URL`,
      and an inherited pair would route this "native" hop through the proxy
      anyway (caught live 2026-08-25 when a native test inside a cll-launched
      session answered from zenmux instead of Anthropic). The Max plan
      authenticates by OAuth, not an API key, so there is no credential
      LiteLLM could forward. On a TTY the launch is delegated to **cc** —
      its login picker chooses the profile and `_claude_run` supplies the
      `--dangerously-skip-permissions` launch, so a native hop is
      `cc --model <m>` in fact rather than in spirit, and there is one
      implementation of "launch Claude on a login", not two (decided
      2026-08-25, user: "essentially when running native, we need to run the
      cc or cr command, same spirit"). Args travel through the environment
      as JSON, because splicing argv into a nu command string is a quoting
      bug waiting for the first space. Without a TTY, cc's `input list`
      picker cannot run; the hop then resolves the login itself — an
      inherited profile that actually holds OAuth, else the last one cc
      recorded in `~/.claude/.last-login` — and execs claude directly.
- [x] **R5** — `cll` runs under `CLAUDE_CONFIG_DIR=~/.claude/litellm`, seeded
      the way `_claude_share` seeds a profile. This is load-bearing, not
      tidiness: `/model` **persists its choice** into that dir's settings.json,
      so without the split a mid-session switch to `gpt-5.6-sol` would silently
      become the default model of every later Max-plan `cc`.
- [x] **R6** — `cll` regenerates `modelPicker` in the profile's settings.json on
      each launch, so `/model`'s in-session list is the same catalogue as the
      launch picker. Only that key is rewritten; `model` and every other setting
      survive.
- [x] **R7** — No credential is committed. `litellm-env` reads provider keys at
      runtime from `~/.pi/agent/auth.json` (already the machine-local source of
      truth) and generates the proxy's own master key on first use into
      `~/.local/state/litellm/master.key`.
- [x] **R8** — `llm quota` reports remaining balance per provider, refreshing
      what has an API and recording by hand what does not. Only OpenRouter
      publishes one (`/api/v1/credits`); zenmux 404s on all six documented
      balance paths (measured 2026-08-25), and opencode-zen exposes none. A
      manual figure carries its age, so a stale reading is never read as live.
- [x] **R9** — `litellm-gen-config` rebuilds `config.yaml` from live provider
      inventories, emitting a deployment only where that provider actually
      serves the model, so a chain never contains a hop that 404s.
- [x] **R10** — Ollama models are **enumerated, not hand-listed**, because
      ollama serves ollama.com **cloud** models alongside local weights — a
      `:cloud` tag, e.g. `deepseek-v4-flash:cloud` at 304B — and the set changes
      whenever something is pulled. Embedding models are excluded rather than
      offered as broken chat routes.
- [x] **R11** — `thinking`/`reasoning_effort` are dropped for **local** ollama
      deployments only. A small local model rejects them outright ("does not
      support thinking", granite4:3b), and the global `drop_params` does not
      cover it: the param is valid upstream, it is the deployment that cannot
      take it. Cloud models are the opposite — `deepseek-v4-flash:cloud`
      answered a `reasoning_effort` request with a populated `reasoning` field
      (measured 2026-08-25) — so dropping there would discard the capability.
- [x] **R12** — Every script runs on **bash 3.2**. macOS ships `/bin/bash`
      3.2.57 and this machine has no newer one, so a bash-4 builtin is a runtime
      failure, not a portability nicety: `mapfile` in the no-argument picker
      shipped once and died as `mapfile: command not found` the first time it
      was run from a non-nu shell. The gate greps for that class.
- [x] **R13** — cll launches Claude Code with `--dangerously-skip-permissions`,
      exactly as `cc`/`cr` do (decided 2026-08-25, user). The proxied path
      passes it on its own `exec claude`; the native path gets it from
      `_claude_run` when delegating to cc and passes it explicitly on the
      no-TTY fallback. The permission prompts cll would otherwise raise are
      aimed at a model the user picked from a catalogue, not at a shell they
      are watching — same call `cc` already made.

## Acceptance

- [x] `bash tests/shell-litellm.sh` exits 0 — 29 checks, tree + hermetic.
- [x] A real request through the proxy returns from the primary provider:
      `haiku-4.5` → zenmux, `granite4-3b` → local ollama.
- [x] A pinned hop reaches the provider named: `haiku-4.5@openrouter` returns
      OpenRouter's own `402 Insufficient credits`, which is the account's state
      rather than a routing fault — and is why zenmux is primary.
- [x] `cll <model> -p` completes a non-interactive Claude Code turn.
- [x] The Max-plan `~/.claude/settings.json` is not written by a `cll` session.
- [x] The native hop's TTY branch builds cc's call correctly: a stub `nu`
      first on PATH receives `source ~/.config/nushell/config.nu` plus
      `CLL_NATIVE_MODEL`/`CLL_NATIVE_ARGS` with argv JSON round-tripped
      intact (`say "hi" now` survives quoting).
- [x] The native hop's no-TTY fallback reaches the real Anthropic API under
      an OAuth'd profile: run from inside a cll session (inherited
      `CLAUDE_CONFIG_DIR=~/.claude/litellm`, which holds no OAuth) it
      resolved to the last-login `priv` profile and drew Anthropic's own
      weekly-limit reply — real endpoint, real auth, no proxy in the way
      (the plan itself was out of quota that day, which is a quota fact,
      not a routing one).

## Out of scope

- Proxying the Max plan itself. See R4 — no forwardable credential exists.
- Cost accounting per request. `llm quota` reports balances, not spend.
- Auto-topping-up or switching provider on a 402 at runtime. The chain is
  static; a spent provider is fixed by editing the order, not by magic.
- `pi`'s own model config, which the capsule epic already
  [`DO NOT PORT`s](../../01-capsule/02-dev-image/prd.md) for containers. The
  host `models.json` entry is written by this node but pi itself stays out.

## Provenance

Implemented ahead of the board on 2026-08-25 at the user's explicit direction
("code now, PRD after"), so this node was written from working code rather
than the code from this node. Recorded here because a `done` that skipped
`open → specced → claimed` is exactly the kind of thing a board should not
have to infer. The `[x]` boxes are checks that were run, not intentions.

R4's cc delegation and R13 landed the same day, after the node was marked
done — same mode: user direction in session, code first, this record after.
R4's original text said only "no proxy env set"; the amendment records that
"no proxy" must survive an inherited environment, and that the launch itself
is cc's to make.
