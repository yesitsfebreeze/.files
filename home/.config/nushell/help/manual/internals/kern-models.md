# Kern model service

Kern's machine hub owns model discovery, authentication, ranked routing and
verified recovery. Launching Kern starts this service; no separate router
executable or Python package is required.

```sh
kern
kern login chatgpt
kern login chatgpt --status
kern launch claude astra@chatgpt
kern launch codex auto:reasoning
kern launch pi auto
kern models
kern models frontier code --limit 10
kern models connections
kern models status
kern models sync
kern models paths
```

`kern launch` registers the project's routing policy with the machine service
and gives the agent a recording proxy and Kern MCP tools. Omitting a model
selects `auto:code`. Session credentials are isolated; management endpoints
require the machine credential. Dropping the launcher releases its session.

The service accepts OpenAI Chat Completions, OpenAI Responses and Anthropic
Messages, including streamed tool calls. The default listener is loopback
port 4140. `[models] listen` configures one or more loopback addresses. Health
reports the running build and configuration identity. All listeners share the
same routing engine, concurrency budget and durable incident store.

## Configuration and login

`kern models paths` prints the native configuration, inventory and credential
locations. On macOS they are beneath `~/Library/Application Support/kern`:
`kern.toml`, `models/` and `credentials/`. Provider API keys live in private
`credentials/credentials.json`; the generated local key is `master.key`.
API keys can be installed with `kern login <provider> --key-stdin`.
ChatGPT login uses the installed Codex credential authority. OAuth and API
credentials are read again on subsequent requests, including after re-login.
A login status check establishes credential availability, not inference rights.

Machine configuration declares `[models]` providers, aliases, agents,
frontiers and listeners. Discovery runs automatically and retains the last
successful inventory when a provider is unavailable. Reviewed frontier entries
carry their benchmark, source and date. `kern models sync` refreshes provider
inventories and public ranking snapshots.

Projects may override routing and the background model, but cannot replace
machine connections or credential locations:

```toml
[models.routing]
local_last = true
local_providers = ["ollama"]
max_attempts = 6
first_output_timeout_secs = 45
request_timeout_secs = 180
max_concurrent_requests = 8
```

Project request budgets cannot exceed the machine budgets. New sessions read
the current project policy. Restart the machine hub after changing machine
connections or listeners. Claude's background requests use the selected model;
`[models] background_model = "auto:text"` chooses another route for them.

`[reason] url = "kern"` sends Kern's own reasoning through the typed machine
RPC and the same routing engine. Embedding configuration remains tied to the
graph's embedding space.

## Routing and recovery

`auto` detects typed input modalities and tool requirements. Named frontiers
such as `auto:code`, `auto:reasoning` and `auto:vision` select a task directly;
`kern_task` provides the same request-level control. Prompt prose is not routing
configuration. Eligible routes are ordered by quality evidence and provider
chain, with local models last by default. Explicit model selection takes
precedence. Ollama cloud models count as remote.

A preferred `model@provider` is attempted first. Integration failures can
advance to another route; explicit quota and payment errors remain visible.
`kern_strict: true` disables fallback for diagnostics. Stateful Responses
requests retain their provider. Streaming never replays after output reaches
the caller. Headers report the actual route and requested model.

The recovery worker stores redacted structural probes, errors, retry times
and verified rules. It tests known parameter and role adjustments against the
failing provider. Unknown compatibility errors may be diagnosed by a healthy
model on another provider, within a bounded budget. Diagnosis can propose only
allowlisted adaptations, and the affected route must pass a probe before a
rule becomes active. The worker cannot rewrite source code or deploy changes.
Revoked credentials require a valid login; recovery cannot manufacture one.
Quota, payment and oversized-context errors are not cleared by tiny probes.

Overall deadlines include streaming, concurrency is bounded across sessions,
and loops are rejected. `kern models status` exposes incidents and recovery.
