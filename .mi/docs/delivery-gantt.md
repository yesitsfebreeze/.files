> **GENERATED — do not edit by hand.** This is the human view of the plan
> record whose home is [`.mi/gantt/plan.json`](../gantt/plan.json) (tasks,
> specs, footprints, dependency edges) folded with
> [`.mi/gantt/ledger.jsonl`](../gantt/ledger.jsonl) (append-only status).
> Regenerate with `/mi-gantt`. Everything above the "Hand-written notes"
> heading is generated output; edits there are lost on the next run. The
> adversary's unrepaired findings live in
> [`.mi/gantt/plan.md`](../gantt/plan.md#audit-findings--unrepaired) — read
> them before trusting this schedule.

# Schedule

**Generated from `.mi/gantt/plan.json` and `.mi/gantt/ledger.jsonl`. Do not edit by hand** — regenerate with `/mi-gantt`. Progress is a fold of the ledger, so the numbers here are true as of the last run and nowhere else.

| | |
|---|---|
| Tasks | **49** (0 done, 39 scheduled, 1 held, 9 blocked) |
| Serial effort | **141 agent-hours** |
| Parallel wall-clock | **≈ 40 hours** at cap 3 |
| Critical path | `W0.3 → P.1 → P.2 → P.4 → S.1 → S.5 → S.6 → H.4` (≈ 33h) |
| Hard blocker | **D.1** — needs the human |

```mermaid
gantt
    title Schedule — parallel wall-clock (agent-hours)
    dateFormat X
    axisFormat %s
    todayMarker off

    section Wave 1
    W0.1 Inventory live ~/.config/wezterm + burri :W0_1, 0, 5
    W0.3 Rewrite 05-platform as the provisioning  :crit, W0_3, 0, 2.5
    W0.4 Apply S2 corrections across the tree :W0_4, 0, 2.5
    W0.6 Record live-config bugs so the rebuild f :W0_6, 0, 1
    E.1 Options + init.lua :E_1, 0, 2.5
    section Wave 2
    P.1 Repo skeleton  chezmoi source layout, ho :crit, P_1, 5, 2.5
    E.2 lazy.nvim bootstrap :E_2, 5, 2.5
    E.3 Core keymaps :E_3, 5, 1
    E.4 Autocmds :E_4, 5, 1
    section Wave 3
    P.2 packages.yaml + run_onchange installer :crit, P_2, 7.5, 5
    P.3 run_once homebrew bootstrap :P_3, 7.5, 1
    P.5 Managed config surface + dot_gitconfig.t :P_5, 7.5, 1
    E.5 Colorscheme + cursor :E_5, 7.5, 2.5
    E.6 blink.cmp completion :E_6, 7.5, 2.5
    E.8 Treesitter :E_8, 7.5, 2.5
    E.9 Telescope :E_9, 7.5, 2.5
    E.10 oil.nvim explorer :E_10, 7.5, 1
    E.11 conform.nvim formatting :E_11, 7.5, 1
    E.12 gitsigns/which-key/pairs :E_12, 7.5, 1
    E.14 Shift-to-select + tests :E_14, 7.5, 5
    section Wave 4
    P.4 run_after shell-init generator (starship :crit, P_4, 12.5, 2.5
    E.7 mason + native LSP :E_7, 12.5, 5
    E.13 lualine statusline :E_13, 12.5, 2.5
    E.15 Markdown table mode :E_15, 12.5, 1
    C.1 Dev image :C_1, 12.5, 5
    section Wave 5
    S.1 Core config, mkcd funnel, start dir :crit, S_1, 17.5, 5
    C.2 Container lifecycle CLI :C_2, 17.5, 8
    section Wave 6
    S.2 Aliases + cf + pass completion :S_2, 25.5, 1
    S.3 Decorated ls + auto-list :S_3, 25.5, 2.5
    S.4 zoxide wrappers + bare-word fallback :S_4, 25.5, 5
    S.5 Finder + cable channels (television) :crit, S_5, 25.5, 8
    S.8 cc/cr Claude launchers :S_8, 25.5, 1
    C.3 Credential propagation :C_3, 25.5, 5
    H.1 Content model + schema :H_1, 25.5, 2.5
    section Wave 7
    S.6 Directory-scoped history :crit, S_6, 33.5, 2.5
    S.7 Quicklist recents :S_7, 33.5, 2.5
    H.2 help command + delegation :H_2, 33.5, 5
    section Wave 8
    H.3 tv browser :H_3, 38.5, 1
    H.5 json/md + AGENTS.md wiring :H_5, 38.5, 1
    section Held
    D.1 needs the human :done, held_D_1, 0, 1
```

## Waves

| Wave | Tasks | Agents | Gate |
|---|---|---|---|
| 1 | W0.1, W0.3, W0.4, W0.6, E.1 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 2 | P.1, E.2, E.3, E.4 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 3 | P.2, P.3, P.5, E.5, E.6, E.8, E.9, E.10, E.11, E.12, E.14 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 4 | P.4, E.7, E.13, E.15, C.1 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 5 | S.1, C.2 | 2 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 6 | S.2, S.3, S.4, S.5, S.8, C.3, H.1 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 7 | S.6, S.7, H.2 | 3 | `no full-tree gate runner; implementation blocked (planning-only state)` |
| 8 | H.3, H.5 | 2 | `no full-tree gate runner; implementation blocked (planning-only state)` |

## Held — not scheduled, and blocking what follows

| Task | Why | Blocks |
|---|---|---|
| D.1 Human decisions: burrito vs nine-tab floor, tinty palette ownership, fzf exception | needs the human | W0.2, W0.5, T.2, T.5 |

## Checks that need a human at a terminal

- **D.1** — Human must choose: (1) does burrito or the nine-tab floor own panes/tabs, (2) does tinty stay as palette owner, (3) is fzf an accepted exception to tv-owns-every-picker or replaced. Answers recorded in 04-corrections-backlog.md with a date.
- **S.4** — Adversarial verify required (02-parallelization.md): confirm the bare-word fallback never hijacks a real command (`ls | something-unknown`, `./x` must not trigger it).
- **E.5** — Visual check that all six defined highlights (M-12: acceptance said five, spec defines six) render correctly under the base16 theme.
- **E.14** — Adversarial verify required (02-parallelization.md): a second agent must try to break the collapse semantics against the PRD's acceptance criteria before the wave gate. M-2: off-by-one corrections needed (S-Right already selects two chars via v<Right>; S-Left from insert selects two via yz).
- **T.3** — F5 jump landing on the intended pane needs a human at a terminal (03-verification-gates.md req 3); also confirm the miss-path feedback fix for L-11 (BEL rings but audible_bell is Disabled and no visual bell is set — currently a silent failure).
- **H.2** — Adversarial verify required (02-parallelization.md): a delegation regression breaks --help shell-wide, so a second agent must try to break it against the PRD's acceptance criteria before the wave gate.
- **H.4** — Fresh-machine run: clone -> apply -> working daily driver, on a machine that has never seen this config (03-verification-gates.md req 7). Also confirm ls --help still behaves.

---

# Hand-written notes — preserved, not generated

Kept from the authored version of this file because each paragraph carries a
*reason* the generated view above cannot express. **The arithmetic in them is
older than the generated table** (it predates the cap-3 worker limit): where a
number here disagrees with the table above, the table wins. The reasoning does
not expire.

## Provenance and units (why there are no dates)

The schedule covers the workload defined in
[`../prd/00-delivery/`](../prd/00-delivery/00-epic.md). Task IDs, sizes, and
dependencies come from
[`01-work-breakdown`](../prd/00-delivery/01-work-breakdown.md); the wave layout
from [`02-parallelization`](../prd/00-delivery/02-parallelization.md).

**Units are agent-hours, not calendar time.** The horizontal axis is
cumulative parallel wall-clock: how long the build takes if each wave's
independent tasks really do run at once. There are no dates here on purpose —
throughput depends on how many agents run and how fast review happens.

## Why Wave 0 exists

**Wave 0 grew after the 2026-08-20 audit.** The terminal epic is being
re-specced from scratch rather than adjusted, and three decisions gate parts of
it: see
[`04-corrections-backlog`](../prd/00-delivery/04-corrections-backlog.md). The
Tracks P/S/E/H schedule below is unaffected — only Tracks T and C wait.

## Why S.5 and C.2 are the tasks worth splitting

The critical path is only ~30h of the 41h, so the schedule is close to
path-bound: further parallelism buys little without splitting the path's own
tasks. The two worth splitting are **S.5** (television — cable channels vs.
typed decoder) and **C.2** (capsule lifecycle), which is why they appear split
below.

## Why the big tracks are free

Everything else is slack. The two biggest cost centres — **Track C (capsule,
~20h)** and **Track E (neovim, ~26h)** — are entirely off-path: run them
concurrently from wave 2 and they add nothing to wall-clock. Conversely,
delaying **S.1** or **S.5** by an hour delays delivery by an hour.

## Running it

Gate detail: [`03-verification-gates`](../prd/00-delivery/03-verification-gates.md).

Per wave, one fan-out of agents, then one gate. The pattern that fits each
wave is in
[`02-parallelization`](../prd/00-delivery/02-parallelization.md#fan-out-patterns-worth-using);
the mechanics:

1. **One agent per task**, given exactly its PRD path plus the epic file for
   invariants — never the whole tree.
2. **File assignment is the concurrency control.** The wave table guarantees
   disjoint files; no locks, no worktrees. Use worktree isolation only for
   agents running destructive experiments (capsule rebuild loops, applies).
3. **Adversarial verify** these three before their gate, because each is easy
   to implement plausibly and wrongly: **E.14** (collapse semantics),
   **S.4** (must not hijack real commands), **H.2** (a delegation regression
   breaks `--help` shell-wide).
4. **One reviewer per track** at the gate, reading that track's whole diff
   against its PRDs — better at catching sibling drift than per-task review.
5. **Applies are serialized.** No agent runs `chezmoi apply` against the live
   home directory; that happens once per gate, deliberately.

## Re-planning rule

Recompute the critical path whenever a task's dependencies change, and update
three things together: the breakdown table, the wave layout, and this chart.
A stale Gantt is worse than none — it hides the fulcrum tasks, which is the
only thing it exists to show.

*(Now that this file is generated, "update three things together" means:
change [`.mi/gantt/plan.json`](../gantt/plan.json), append to
[`.mi/gantt/ledger.jsonl`](../gantt/ledger.jsonl), and regenerate. The warning
stands — a stale chart hides the fulcrum.)*
