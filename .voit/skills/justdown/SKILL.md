---
name: justdown
description: Install and use justdown — the `jd` binary and its MCP server over a library of `.jd` files. justdown is an execution + knowledge + record tool in one — capture a proven procedure once, then run it deterministically as a shell dispatch (`jd get <ref> --justfile | just --justfile - <recipe>`) instead of re-reasoning it with the model. Use when the justdown MCP tools (mcp__*justdown*: search/get/ls/links/path/resolve) are missing or not yet installed, when `jd` is not on PATH, or when you need to look up `.jd` knowledge or call a `.jd` tool and the tools aren't available. Bootstraps the `jd` binary and registers the justdown MCP on first use, then teaches the lookup and execution verbs.
---

# justdown

justdown is **one tool, three jobs in one source** — execution, knowledge, and
record — built on a graph of **`.jd`** files (YAML frontmatter + Markdown +
runnable `just` blocks + `psaido` scaffolds). One file serves four readers without
copies: humans (Markdown), indexers (frontmatter), agents (body), runners (`just`
blocks).

The bet is to **take the LLM out of the hot path**. The first time you do a task an
agent reasons it out — slow, expensive, nondeterministic. Capture that proven
procedure into a `.jd` once, and every run after is a near-free shell dispatch:

- **execution** — the `just` recipe in the fenced block *is* the tool; call it via
  `jd ... --justfile | just`. No MCP-per-capability, no hand-written function to
  keep in sync with its docs.
- **knowledge** — searchable, graph-linked docs (the *why* and *when*) live next to
  the runnable *how*.
- **record** — a failure is a non-zero exit with real stderr: diagnose, add a guard,
  commit it back into the `.jd`. The system gets more reliable the more it runs.

`jd` is the binary; `.jd` are the files it reads; `jd mcp` is one lookup server over
the whole library. This skill bootstraps it **on demand**: install the binary if
missing, register the MCP if missing, then use it. Run the steps in order and stop
early once a step is already satisfied.

## 1 · Ensure the `jd` binary is installed and current

Check first — this prints the install path and the running version:

```sh
command -v jd && jd version
```

If it resolves, also check whether a newer release is out and update if you're
behind — compare `jd version` (e.g. `jd 0.6.0`) against the latest tag:

```sh
curl -fsSL --connect-timeout 10 --max-time 30 \
  https://api.github.com/repos/yesitsfebreeze/justdown/releases/latest \
  | grep -m1 '"tag_name"' | cut -d'"' -f4
```

To install (when missing) or update (when behind), follow the **current**
instructions in the live justdown README — that is the source of truth and can
change, so don't hardcode a command or path here, just read and follow it:

> <https://github.com/yesitsfebreeze/justdown> — see its **Installation** section
> (or `install.jd`).

Fetch that page, run its documented install step for this OS, then confirm
`jd version` reports the latest tag (add the install dir to `PATH` if needed).
Re-running the installer fetches the latest release and overwrites `jd` in place,
so the **same** step both installs and updates. Only if there is no network, fall
back to the bundled offline copy at `resources/install.sh` (Windows:
`resources/install.ps1`) — but prefer the live README, since the bundled copy can
drift from upstream.

## 2 · Ensure the justdown MCP is registered

If the `mcp__*justdown*` tools are already available this session, skip this step.
Otherwise register the server so it loads next session:

```sh
claude mcp add --scope user justdown -- jd mcp
```

Or add it by hand to `.mcp.json` (project) / user MCP config:

```json
{ "mcpServers": { "justdown": { "command": "jd", "args": ["mcp"] } } }
```

> MCP servers load at **session start**, so the `mcp__*justdown*` tools appear in the
> **next** session, not the current one. Until then, use the `jd` CLI (step 3) — it
> works the moment the binary is installed.

## 3 · Use it

**Look things up** (knowledge — works immediately after step 1):

| command | does |
|---------|------|
| `jd search "<what you need>"` | rank library `.jd` files by need (graph-aware) |
| `jd get <name\|key\|path>` | read a procedure as ordered sections |
| `jd ls` | list categories and their files |
| `jd links <ref>` | the `@links` out of a file |
| `jd path <a> <b>` | shortest `@link` path between two files |

**Call a `.jd` tool** (execution — the callable interface): emit the file's recipes
as a justfile and pipe them into `just`. The runner interface is uniform —
`just --justfile - <recipe> <args...>`, args mapping positionally to recipe params:

```sh
jd get <ref> --justfile | just --justfile - <recipe> <args...>
# e.g. jd get tools_gate --justfile | just --justfile - gate
```

Results come back per the frontmatter invocation mode: `run` (stdout),
`sidecar` (live streamed), or `artifact` (written to a path). A non-zero exit is a
real failure — root-cause it once.

**Record the fix** (record): when a recipe fails, diagnose, add a guard, and commit
it back into the `.jd` next to the failing recipe. Track the ratio of warm
dispatches (shell) to cold ones (agent) — every procedure you crystallize moves a
task from the model's hot path to a deterministic shell exec.

MCP (once loaded next session): the read verbs as
`mcp__plugin_voit_justdown__{search,get,ls,links,path,resolve}`. These are
deferred tools — load their schemas with `ToolSearch` `select:<name>` first, then
call them. **Prefer the MCP tools over shelling out to `jd`** for lookups when
they're available (dedicated tools over Bash); use the CLI for `--justfile`
execution.

## Notes

- Read docs/manual procedures through justdown, never by `cat`-ing files: `jd get <ref>`
  (CLI) or the `get`/`search` MCP tools.
- Other CLI verbs: `jd build` (regenerate the SQLite `@`-link graph), `jd lint`
  (validate `.jd` syntax), `jd explore` (in-browser explorer; first process hosts,
  later ones feed the same instance). `JD_ROOT` sets the searched root (default
  `$HOME`).
- A `.jd` file serves four readers from one source. See the justdown spec:
  <https://github.com/yesitsfebreeze/justdown>.
