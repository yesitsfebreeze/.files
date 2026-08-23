---
state: open
priority: 25
est:
mode: afk
needs:
  - 00-delivery/corrections/lsp-gate-parser-seed
verify: "bash gates/wave-status.sh --run 4"
origin: derived
---

# Nothing says which nvim gates are exposed to a load-time-fetching plugin

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `nvim-treesitter` entering `lazy-lock.json` broke three gates at once
and nobody knew which until someone read eight files. This node makes the
answer derivable instead of discoverable.

`lsp-gate-parser-seed`'s R4 census established the shape. **Eight gates launch
nvim; the other twenty-four are out by construction.** Of the eight:

| gate | status |
|---|---|
| `nvim-options`, `nvim-telescope` | repaired — call `seed_parsers` |
| `nvim-treesitter` | immune by design (it owns the subject) |
| `nvim-lsp` | was exposed; [`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md) repairs it |
| `nvim-completion` | unexposed — `doautocmd InsertEnter` + `setfiletype lua`, neither fires `BufReadPost`/`BufNewFile` |
| `nvim-colorscheme` | unexposed — verified by **reading both probe heredocs**, not by trusting its own line-62 claim |
| `nvim-plugin-manager` | unexposed — hermetic stages are `+qa`/`+luafile` only |
| `nvim-statusline` | unexposed — uses `noautocmd edit` throughout, **and is the only gate that asserts its own immunity** (`ts_loaded=false`) |

`gates/probes.sh`'s `nvim_probe` is out too: a `-u` fixture init with no lazy.

**Why a registry and not a helper.** R5 of that node considered a shared
`seed_parsers` in `gates/lib.sh` and rejected it, with the copymode R2
argument plus two more: the helper hardcodes 16 language names that already
exist twice, and `gates/lib.sh` is sourced by every gate — maximum blast
radius across other nodes' files. It also settled that `LOCK_KEYS` does **not**
make this case derivable, because the exposure has three conditions and only
the first derives cleanly:

1. seeds every lockfile key — greppable;
2. opens a file — **semantic**, since `setfiletype` and `doautocmd` look
   identical to a grep;
3. some lockfile plugin fetches at load time — **not derivable from the
   lockfile at all**. `nvim-treesitter` qualifies because its `config` calls
   `install()`; `telescope-fzf-native`'s `build = "make"` does not.

So the durable form is a **declaration per gate**, checked — which is the
pattern `nvim-statusline` adopted unprompted and is the reason it is the only
one whose immunity survives a refactor.

## Requirements
- [ ] **R1** — Every gate that launches nvim carries exactly one of: a call
      to `seed_parsers`, or a **greppable immunity claim** naming why it is
      unexposed (`noautocmd edit`, `setfiletype`, `+qa` only, or owning the
      subject). One line, machine-checkable.
- [ ] **R2** — A derived check asserts that set: the gates that launch nvim,
      each accounted for. Use the durable form the board settled — set
      equality against a declared roster with `MISSING`/`UNEXPECTED`
      diagnostics, never a bare count. Port from `tests/shell-zoxide.sh`'s
      `cited_ids`/`owned_ids_ok` or `tests/wezterm-f5-tab-select.sh`'s
      `bound_rows`/`rows_ok`.
- [ ] **R3** — **The check must be able to fail in both directions**: a gate
      that launches nvim with neither declaration, and a declaration whose
      claim is false. The second is the hard one — say plainly what it can
      and cannot verify. An immunity claim of `noautocmd edit` is checkable;
      one of "no probe opens a file" is a claim about semantics, and if the
      check can only take that on trust, say so rather than implying more.
- [ ] **R4** — No gate's assertions change, and no gate's probe changes.
      This node adds declarations and one check.
- [ ] **R5** — Say where the check lives and argue it. A cross-gate check has
      no obvious owner: `gates/` holds the cross-cutting ones
      (`nushell-module-staging.sh` is the precedent, and it derives both
      sides), while `tests/` gates own one node each. Recommend, and name the
      node that should own the file.

## Acceptance
- [ ] The check is green, and `bash gates/wave-status.sh --run 4` and
      `--run 3` are green — run **alone**, tallies quoted not asserted.
- [ ] Both R3 counterfactuals quoted red, each naming the offending gate.
- [ ] The eight-gate table re-derived by the check itself, not transcribed
      from this PRD.

## Out of scope
- Building a shared `seed_parsers` in `gates/lib.sh`, rejected with reasons
  in [`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md) R5.
- Repairing `nvim-lsp.sh`, which is that node's.
- The twenty-four gates that never launch nvim.
