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

## Audit findings — unrepaired

The adversary returned **REPAIR FIRST**. These findings are recorded verbatim and have **not** been fixed in the plan above. Read them before trusting the schedule.

### Lost — specced work that no task implements

- `.mi/prd/02-terminal/05-tab-content-state.md` is a complete feature PRD with 5 requirements and 5 acceptance criteria and NO task implements it. "Tabs whose panes are all freshly initialized (nothing running yet) render in a dim \"empty\" color; any tab with at least one pane running a command renders in a lit \"occupied\" color." W0.2 lists the file as something to re-spec, but there is no T.x that builds it. This also breaks 01-work-breakdown's own acceptance criterion: "Every feature PRD outside `00-delivery` appears exactly once as a task."
- The gate scripts themselves are unbuilt and unassigned. 03-verification-gates req 5: "keep every gate as a script so the whole set is one command"; acceptance: "Each gate is a script that exits non-zero on failure, runnable in one command." No task in the plan produces a gate script or a runner; 44 of 49 tasks carry `verify: ""`. The repo profile confirms it ("no gate runner; gates specified in ... but not yet implemented"). The run will report wave success with nothing having been executed — law 3's wish rung exactly.
- The per-wave interactive checklist has no owner. 03-verification-gates req 3: "Some criteria genuinely need a human at a terminal ... These are enumerated per wave as a short manual checklist rather than pretended to be automated." The plan scatters ad-hoc `manual:` strings on 6 tasks; no task produces the enumerated per-wave checklist artifact, and no task carries the manual check for the ones the source names explicitly ("whether the bare-word jump *feels* instant" — S.4 has no such manual line; "the shift-select collapse under real keyboard timing").
- The launchd PATH seeding is in no task. T-10: "...and the launchd-PATH seeding without which a GUI launch dies." T.1 is appearance, T.2 tabs, T.3 F5, T.4 "grid centering, copy mode, mouse + paste bindings". Nothing owns the one item on that list whose absence kills a GUI launch outright.
- The `nu-history` cable channel is in no task and in no PRD. 04-corrections-backlog S2 coverage gaps: "**Television:** the `nu-history` channel — **`Alt-R` depends on it** — plus `alias`, `cht`/`cht-query` naming, `recent-files`, `channels`; the in-tv shortcut keys (with `cht.sh=f5` colliding with `burrito-sessions=f5`); and the non-cable assets (`bg-preview.sh`, `theme-preview.sh`)." 04-shell/04 req 5's curated channel list does not include nu-history, and `.mi/prd/04-shell/04-television.md` is NOT in W0.4's file list — so the gap is neither specced nor scheduled to be specced, while S.6's `Alt-R` requirement depends on it.
- The rest of the S2 coverage gaps are equally unplaced. "**Shell:** `ollama-host` probe on every interactive start; `starship` (in no inventory entry at all); the tinty palette re-assert in `config.nu` (orphaned if theme is dropped); `$env.ENV_CONVERSIONS`; the `esc_clear` binding; `cursor_shape` / `table` / `sync_on_enter` / `completions.external` config blocks." and "**Neovim:** `cmdheight`". These live only in the backlog file; W0.4's footprint omits every PRD that would have to absorb them (`04-shell/04`, `03-editor/01`, `04-shell/02`), so after Wave 0 they are still uncovered and no S/E task is asked to build them.
- The capsule's terminal keybinding is in no task. 01-capsule/01 req 4: "An explicit flag (`capsule --rebuild`, bound to `Ctrl+Shift+B` in the terminal)", and the epic's success criterion: "One command (and one terminal keybinding that calls it) covers everything the old `mount`, `Ctrl+Shift+D`, `Ctrl+Shift+B`, and `just run` did." C.1 writes `Dockerfile`, C.2/C.3 write `capsule-tool/`; only C.4 lists `wezterm.lua`, and its spec is the recents picker. Nobody binds the capsule launch/rebuild keys.
- The Neovim version floor's editor-side half is unplaced. 05-platform/02 req 6: "**Record the floor in one place** and have [`03-editor`](../prd/03-editor/prd.md) reference it rather than restating a version." P.2 owns `.chezmoidata/packages.yaml` and `run_onchange_*`; no task footprints `03-editor/00-epic.md`, and M-3 ("Baseline is stated as native 0.11 but the live binary is 0.12.4") is not in W0.4's file list for that epic either.
- The generated-init location decision and its downstream edit are unplaced. 05-platform/03 req 2: "**Note the inconsistency in the live layout**: two live in `~/.cache`, one in `$HOME`. Pick one location for all three in the rebuild and update the [shell epic's](../prd/04-shell/prd.md) invariant to match, rather than inheriting the split." P.4's files are `run_after_*` only; `.mi/prd/04-shell/00-epic.md` is in no task's footprint.
- T-11 is neither fixed nor converted into a task, violating the backlog's own acceptance criterion ("Every S1 item is either fixed or converted into a task"). T-11: "The epic's Non-goals list 'background image cycling' and 'opacity toggle' as never-port, but both exist live in new form (`Ctrl+Shift+B` sets a blurred desktop wallpaper; opacity via OSC-1337 user var over `window_background_opacity = 0.95`)." No T task builds them, no task drops them on the record, and D.1 does not ask the human about them — yet C-1 hands `Ctrl+Shift+B` to capsule, which silently deletes the live wallpaper feature as a side effect.
- The index update that AGENTS.md requires as part of the same change is unowned. AGENTS.md: "When an epic's children change, update three places together: the epic's children table, the README tree, and the README build order." W0.2 writes `02-terminal/00-epic.md` and adds/rewrites children (the README and epic both still list 3 terminal children while disk holds 5), but `.mi/prd/README.md` is in no task's file list — it is on the profile's shared-owned-by-nobody list.

### Invented — tasks with no spec behind them

- T.4 carries requirements that exist in no spec. Its `spec` is `.mi/prd/02-terminal/04-copy-mode.md`, which contains only copy mode (freeze screen, bright-cyan cursor, F3) — the plan's own notes admit that file "does not match any of this and is pre-re-spec". Three of T.4's four deliverables (dynamic grid centering, `Ctrl+V` bracketed paste / `Ctrl+C` copy-or-SIGINT, mouse bindings + `StartWindowDrag`) come from audit finding T-10, which is a defect note with no requirements and no acceptance criteria. T.4 therefore has nothing to verify against until W0.2 writes it — and W0.2's file list does not include any new file for grid centering / mouse bindings, so the re-spec is not obliged to produce a home for them.
- T.5 has no spec at all: `spec` points at `04-corrections-backlog.md` (a defect register), `files: []`, `size: ""`. The source is a single work-breakdown row reading "| T.5 | burrito integration (scope set by D.1) | ? | TBD | D.1 |". A task whose requirements, acceptance criteria, size and footprint are all absent is not a task; it is a placeholder that will be closed by whatever the agent decides burrito means.
- W0.3 and W0.6 are scheduled to do work the plan's own notes say is already done — W0.3: "Marked [x] fixed in corrections backlog's coverage-gaps section; current 05-platform files already reflect the rewrite"; W0.6: "The S2 'bugs in the live config' table (L-1..L-12) is this task's output; already populated in the current file." Dispatching them re-derives a completed artifact, and W0.3 sits at the head of the critical path (`W0.3 → P.1 → ...`), so the path's first 2 hours are fictional. They should enter the ledger as already-satisfied, not as work.

### Edges — dependencies missing, invented, or mislabelled

- MISSING, and the plan proves it knows the pattern: W0.5 rewrites `01-capsule/00-epic.md`, `01-container-lifecycle.md`, `02-dev-image.md`, `04-recent-workspaces.md` — which are verbatim the specs of C.1, C.2 and C.4 — yet C.1 deps [P.2], C.2 deps [C.1], C.4 deps [C.2, T.1]. None depends on W0.5. The plan correctly wired W0.2 → T.1/T.2/T.3/T.4 and W0.3 → P.1 for exactly this reason. Add W0.5 → C.1, C.2, C.4.
- MISSING, same class: W0.4 rewrites `04-shell/01`, `04-shell/03`, `04-shell/06`, `04-shell/07`, `03-editor/03`, `03-editor/11`, `03-editor/12`, `06-help/02`, `06-help/03`, `01-capsule/01` — the specs of S.1, S.4, S.3, S.7, E.4, E.5, E.12, H.2, H.3, C.2. Not one of those tasks depends on W0.4, and E.1/E.4 have deps that reach no Wave-0 task at all, so an E.4 agent can be dispatched against `03-editor/03-autocmds.md` while a W0.4 agent is rewriting it (M-3: it currently "prescribes the deprecated API"). Add W0.4 → each of those ten.
- MISSING, and it breaks the definition of done for ~30 tasks: 03-verification-gates req 1 — "A task is done when: its PRD's acceptance criteria have been executed and passed; **its `help` entries exist**" — plus 00-epic invariant 4 and 02-parallelization rule 4 ("Every agent writes its own `help` entries"). H.1 builds the schema and is the only task that lists `help/*.nuon`. H.1 deps S.1 ← P.4 ← P.2 ← P.1 ← W0.3, so all of Track E (E.1 deps []), Track T and C.1 run before the schema exists. Either add H.1 → every binding-adding task, or move H.1 off the S.1 chain; as written the drift check (H.4) is guaranteed to fail on tasks that had nowhere to write.
- MISSING: S.8 → S.4. `04-shell/03-zoxide.md` req 3: "**Composed verbs.** `zz` = `cd -` ..., `zl` = jump then `la`, `zc` = jump then Claude (`cc`)." `cc` is S.8. S.4 deps [S.1, P.4]; the Gantt puts S.4 in wave 4 and S.8 in wave 5, so `zc` gets written against a command that does not exist yet and its box can only honestly be `[~]`.
- MISSING: D.1 → S.4 and D.1 → P.2. Open decision 3 is "**fzf.** `zi`/`cdi` shell out to `zoxide query --interactive`, which spawns **fzf** ... Either accept fzf as a documented exception or replace `zi` with a tv-backed picker." That answer decides what S.4 req 2 implements, and 05-platform/02 req 7 already hard-codes the consequence ("`fzf` is required whether or not it is wanted"). D.1's own notes claim it "Blocks W0.2, W0.5, T.2, T.5" — S.4 and P.2 are missing from that list.
- MISSING: D.1 → T.1, E.5, E.13, S.1. Open decision 2 is "**Does tinty stay?** It owns the palette that WezTerm, Neovim, and tv all inherit (T-3), but it is `DEFER`red as cosmetic. If it goes, something else must own the palette." That is the input to T.1 (palette), E.5 (`11-colorscheme`, tinted-nvim), E.13 (lualine theme built from the palette) and S.1 (the "tinty palette re-assert in `config.nu` (orphaned if theme is dropped)"). Only T.2 carries a D.1 edge in the terminal track.
- MISSING: the config.nu serial chain. 00-epic invariant 2: "Where that's impossible (`config.nu` is touched by most shell tasks), the tasks are serialized into one track"; 02-parallelization's contention table: "`config.nu` | most of Track S | Serialize Track S. One writer, in order." The plan instead fans S.2, S.3, S.4 and S.8 out of S.1 in parallel, and S.5/S.7 also need config.nu (see collisions). Wave 4 as written puts S.2, S.3, S.4 and S.5 on `config.nu` simultaneously — the precise failure invariant 2 exists to prevent.
- MISSING: T.2, T.3, T.4 all write `wezterm.lua` off the same W0.2 edge, and the source's own contention rule is narrower than reality — "`wezterm.lua` | T.1, T.2, and C.4's binding | T.1 then T.2; C.4 appends only after T.1" — written before T.3/T.4 existed as wezterm.lua writers. Serialize T.1 → T.2 → T.3 → T.4, and re-point C.4's edge at the *last* writer, not T.1.
- MISSING: H.4 ↔ H.5 and H.3 → help.nu. H.2, H.4 and H.5 all list `help.nu`; H.4 deps H.2 and H.5 deps H.2, with no edge between them, so both can be dispatched into the same file. (H.3 also needs it — see collisions.)
- MISSING: P.5 vs S.5 / H.3 / C.4 on `home/dot_config/`. P.5 deps [P.1] only and owns the whole managed surface including `home/dot_config/television/`, which S.5 and H.3 also write; C.4 lists `home/dot_config/` outright. Nothing orders P.5 against them.
- INVENTED/preference: E.15 → E.11. `03-editor/15-markdown-tables.md` (vim-table-mode) has no functional dependency on conform.nvim; the edge exists only because both write `plugins/editor.lua`, and 02-parallelization's own resolution for that file is "Split into one file per plugin (cheaper than serializing)." The pair is also internally inconsistent: if the edge is for contention it must also exist between E.11 and E.12, which write the same file with no edge at all. Split the file and drop the edge, or serialize all three.
- LIKELY preference, worth re-deriving: S.5 → S.6. `04-shell/05-history.md`'s tv coupling is to the *generated* init, not to `finder.nu` — req 5: "these bindings are appended AFTER tv's generated init so they win reedline's last-entry-wins resolution" (that is P.4), and `Alt-R` is "tv's global `tv_shell_history`", also P.4's artifact per 05-platform/03 req 5. If the real edge is P.4, then S.6 comes off the S.5 tail — and S.5 is the fulcrum the whole schedule is built around, so this edge is worth being sure about.
- PREFERENCE dressed as dependency: C.4 → T.1. Nothing in `04-recent-workspaces.md` needs the appearance work; the edge is the file rule "C.4 appends only after T.1." Keep it if the contention rule is kept, but say so — as an unlabelled dependency it will survive the file being split and cost parallelism for nothing.

### Collisions — footprints that overlap or omit what the task must write

- S.5 — `04-shell/04-television.md` req 4 defines keybindings (`Ctrl+Space` / `F1` → `tv_remote`, `Ctrl+T` → `tv_finder`), which live in `$env.config.keybindings` in `config.nu`. S.5's files are `finder.nu` and `home/dot_config/television/` only. S.5 shares wave 4 with S.2, S.3 and S.4, all of which do list `config.nu`.
- S.7 — `04-shell/07-quicklist.md` req 3: "**`Ctrl-Q`** opens the quicklist tv channel". S.7's files are `quicklist.nu`, `finder.nu`; `config.nu` is missing. It also writes `finder.nu` concurrently with nothing else only because S.5 precedes it — but the file is shared and unlabelled as such.
- W0.4 — its footprint omits most of the checklist it is given. The S2/S3 items require edits to `.mi/prd/04-shell/04-television.md` (L-3 `rcwd`, M-9 three enter-hijacking channels, the opacity DEFER/spec contradiction, the tv coverage gaps), `.mi/prd/04-shell/02-aliases-utilities.md` (M-7 `bb`/`ba` invoke `brr`), `.mi/prd/03-editor/00-epic.md` (M-17 "13 files; there are 14"), `.mi/prd/03-editor/01-options.md` (M-1 scrolloff overclaim), `.mi/prd/06-help/00-epic.md` (M-15 desc exemption), `.mi/prd/06-help/01-content-model.md` (M-14 the undefined "source PRD" field), `.mi/prd/04-shell/00-epic.md`, `.mi/prd/02-terminal/00-epic.md` (S3 duplicated-facts) and `.mi/prd/README.md` ("README stated exclusions twice"). None is in `files`.
- W0.4 and W0.2 both need `.mi/prd/02-terminal/00-epic.md` (S3: "the terminal epic (which has no invariants section)"), and W0.4 has `deps: []` while W0.2 waits on W0.1+D.1 — so they are schedulable together on a file W0.2 is rewriting from scratch.
- D.1 and W0.6 both write `.mi/prd/00-delivery/04-corrections-backlog.md` with `deps: []` on both — two concurrent writers of the same file in Wave 0. W0.4 additionally writes `.mi/prd/00-delivery/01-work-breakdown.md`. Both files are on the profile's "shared files, owned by no task" list, and there is no git lock in this repo to catch the overlap.
- E.2 — `04-plugin-manager.md` req 5: "**Lockfile.** `lazy-lock.json` is committed" (and its acceptance criterion "everything reinstalls to the lockfile's versions"). `lazy-lock.json` is not in E.2's files. Req 1 also makes E.2 a writer of `init.lua` ("`init.lua` requires `config.options` → `config.keymaps` → `config.autocmds` → `config.lazy`"), which is E.1's file; E.3 and E.4 need the same two require lines and all three depend only on E.1, so `init.lua` has three unlisted concurrent writers.
- E.11, E.12, E.15 all list `plugins/editor.lua`. E.11 and E.12 both depend only on E.2 and share wave 4, so they collide with no edge between them. (Also: the path is wrong — the work-breakdown says "every task is a separate file under `lua/plugins/`", and E.1 uses the `lua/config/...` form, so the E.5–E.15 footprints are one directory short and cannot be grepped against the real tree.)
- P.1 claims `home/` wholesale while P.5 claims `home/dot_config/`, S.5 and H.3 claim `home/dot_config/television/`, and C.4 claims `home/dot_config/`. Nested footprints defeat the "no two concurrent tasks name the same file" check entirely — the check compares strings, and `home/` never equals `home/dot_config/television/`.
- P.5 — its own title is "Managed config surface + dot_gitconfig.tmpl" and 05-platform/01 req 1 puts `dot_gitconfig.tmpl` at the `home/` root, not under `dot_config/`. `home/dot_gitconfig.tmpl` is not in its files.
- H.3 — `06-help/03-browser.md` req 3: "**Entry points.** `help --fuzzy`, and the `help` channel appearing in the `Ctrl-Space` channels remote". That is a flag on `help.nu` (H.2/H.4/H.5's file) plus a change to the channels remote (S.5's `finder.nu`). H.3's files list only `home/dot_config/television/`.
- S.1 — `04-shell/01-core-config.md` reqs 6–8 write `startdir.txt` and `dirs.txt` and req 4 the sqlite history store; the files list (`env.nu`, `config.nu`, `dirstack.nu`) carries no path prefix at all, so it cannot be checked against P.1/P.5's `home/` tree. The same is true of every S and E task: bare `config.nu`, `init.lua`, `Dockerfile`, `capsule-tool/`, `setup-script` are not repo-relative paths.
- T.5 — `files: []`, which violates 01-work-breakdown's own acceptance criterion "Every task names its files". A task with an empty footprint can collide with anything and be detected by nothing.
