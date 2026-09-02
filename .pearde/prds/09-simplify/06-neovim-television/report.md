Verdict: DONE

Resumed run. An earlier `implementer-neovim-tv` on this claim was cut off by
a usage limit one turn short of its report, leaving the whole build
uncommitted in the working tree. This pass re-ran every check in both specs
against the tree as it stood rather than trusting the ticks, deployed the one
path that was still pending, measured the acceptance clauses that only a real
pty can answer, found and fixed one live regression, and committed.

**14 of 14 spec acceptance boxes verified green by re-running both
`## Verify and Proof` blocks end to end** — `spec01-channels-and-lua OK`,
`spec02-mason-hook OK`. No box was found ticked-but-false, so none was
unticked. **4 of 6 PRD acceptance boxes are now ticked** (two closed this
pass by live measurement; two left red on purpose with the measurement
written into the box — see `## Findings`).

## What this pass changed

One file: `home/dot_config/television/cable/theme.toml`.

`tv theme` — the picker behind the `theme` shell command, and the subject of
PRD acceptance box 4 — listed **nothing at all**. Its source command is
`nu -n -c 'source ~/.config/nushell/theme.nu; _theme_list | to text'`, and
`nu -n` loads no config, so `theme.nu` is the only module in scope. But
`04-nushell` (commit `af791b3`) had rewritten `theme.nu:8` from a
self-contained `_theme_state_dir` to one that calls `_state_dir`, which lives
in `dirstack.nu`:

```
Error: nu::shell::external_command
   ,-[/Users/feb/.config/nushell/theme.nu:8:17]
 8 |     let dir = ((_state_dir) | path dirname | path join "tinted-theming")
   :                 ^^^^^|^^^^
   :                      `-- Command `_state_dir` not found
```

The channel returned zero rows. Fixed the way this repo already solves it —
`quicklist.toml:20` sources two modules in one command — by sourcing
`dirstack.nu` first. `_theme_list` now returns **911 entries**, the active
slot first. The file's header comment also still claimed "Both paths are
templated to ABSOLUTE paths rather than `~/…`", which the R2 rename had made
false; rewritten to say what the file now does and why the `dirstack.nu`
source is there. `theme.toml` is in this PRD's footprint and in spec01's, so
this is inside scope, not a widening.

Nothing else in the tree needed a change. Every other file the prior pass
left was re-read and re-measured, not rewritten.

## Verify and Proof — both blocks, re-run this pass

`spec01-channels-and-lua` (7/7): `ls home/dot_config/television/cable | wc -l`
→ `10`; no `border_type = "rounded"` in `config.toml`; `EDITOR:-nvim` appears
exactly `1` time in each of `files.toml`, `text.toml`, `recent-files.toml`;
`theme.toml` present and `theme.toml.tmpl` absent; `wc -l` on the three lua
files → `8 20 71` against ceilings `12 20 75`; no `provider = "auto"`,
`LspAttach`, `termguicolors`, `completeopt`, `incsearch` or `cmdheight`
survives; `nvim --headless "+Lazy! sync" +qa` and `nvim --headless +qa` both
exit 0 with no stderr; the `Re-take, 2026-09-02` paragraph is in
`decisions/shift-select-scope/prd.md`. Block printed
`spec01-channels-and-lua OK`.

`spec02-mason-hook` (7/7): no `tests/` citation; no `MASON_SEED` switch
(`MASON_SEED_DATA_DIR` is a different word and survives, as the spec says);
the memo path resolves to `.pearde/memos/…`; `bash -n` clean; mechanism lines
`26` of `55` total, under the 30 the requirement asked for; and the branch
probe's four cases all pass —

```
ok   warm registry: silent no-op
ok   no nvim on PATH: warns, exits 0
ok   cold + working nvim: seeds automatically, no switch needed
ok   cold + offline: warns, exits 0, tells you how to retry
PASS
spec02-mason-hook OK
```

The third of those is the one Q1's answer rests on: the seed fires from the
registry check alone, with `MASON_SEED` set nowhere in the environment.
Automatic is true again.

## What the pty measured that headless could not

Four probes, left in `probe/`. Each reads state out of a live nvim in a real
tmux pty and none of them quits nvim — the tmux server is killed after the
read, per the workflow's own warning.

- `live-merged-config.sh` — merged, not source: `keymodel=startsel,stopsel`,
  `termguicolors=true` (with `options.lua` no longer setting it),
  `mouse=nvi`, `completeopt=menu,popup`,
  `require("lualine").get_config().options.theme` → `tinted`, `grn` and `gra`
  both mapped, `<leader>xc` mapped. The pane was listed before teardown:
  `pane 0 200x50`.
- `live-shift-select.sh` — one fresh nvim per case, state captured by a timer
  armed *before* the keys so insert and visual mode are read without leaving
  them, and `<S-Down>` sent as the raw `CSI 1;2B` bytes because tmux's
  `send-keys S-Down` never reached nvim. From line 1: Shift-Down x3 →
  `v|4|1`; then a bare Down → `n|5|5`; from insert, `i` then Shift-Down x2 →
  `v|3|1`; `v` then `jj` → `v|3|1`, confirming `hjkl` does not collapse,
  which is what the re-take paragraph documents as the built-in's limit.
- `live-claude-config.sh` — `claudecode`'s own merged config after a forced
  load: `terminal_cmd=cll`. R4's deletion of the Lua profile resolver is
  safe; the spawn still goes through `cll`.
- `live-statusline-follows.sh` — three consecutive `:colorscheme` changes in
  one live nvim, `lualine_a_normal` resolved with `link=false` after each:
  `#665c54/#1d2021` → `#bdae93/#f9f5d7` → `#4c566a/#2e3440`, while
  `theme.normal.a` stays `nil/nil` throughout — proving spec01's claim that
  the `tinted` lualine theme is group-name based and needs no `ColorScheme`
  autocmd. R3's deletion is a drop-in.

`theme-preview.sh` was re-tested under `/bin/bash 3.2.57` against
`base16-gruvbox-dark-hard` and `base24-dracula`: both exit 0, 91 lines. And
`theme` itself was driven in a pty: three focused rows emitted three distinct
OSC 11 backgrounds and Esc emitted a fourth restoring the original, with
`current_scheme` unchanged.

## Findings

- **`tv theme` listed nothing — a live regression from `04-nushell`.** Fixed,
  above. The general shape is worth a look beyond this node: any cable
  channel whose source command runs `nu -n` and sources a single nushell
  module breaks the moment that module grows a cross-module call. Only
  `theme.toml` was affected today; `quicklist.toml` and `recent-dirs.toml`
  already source what they need.
- **`tv list-channels` prints 30 on this machine, not 16 — and no source
  deletion can change that.** `chezmoi apply` never removes a file it has
  stopped managing, so `$HOME/.config/television/cable` still holds all five
  channels R1 deleted (`alias`, `env`, `git-branch`, `git-files`, `zoxide`)
  plus thirteen older unmanaged ones. Against an isolated `XDG_CONFIG_HOME`
  holding only this repo's television configuration the count is exactly
  `16`, and an empty fixture gives `10`, so the PRD's correction reproduces
  precisely — the floor is real. The repair is the mechanism `04-nushell`
  already used for the same problem: append these five lines to
  `home/.chezmoiremove`, which already carries eight entries —

  ```
  .config/television/cable/alias.toml
  .config/television/cable/env.toml
  .config/television/cable/git-branch.toml
  .config/television/cable/git-files.toml
  .config/television/cable/zoxide.toml
  ```

  `home/.chezmoiremove` is outside this PRD's footprint, so this is reported,
  not done. Until it lands, R1 is true of the repo and false of the machine.
- **The `tinty apply` clause of acceptance box 3 cannot pass, and could not
  before this PRD either.** Nothing propagates a `tinty apply` into an
  already-running nvim: `tmux-colors.sh` has no nvim hook at HEAD or in the
  working tree, and `colorscheme.lua` configures `tinted-nvim` with
  `apply_scheme_on_startup` and no watcher. Measured: two real `tinty apply`
  calls against a live nvim left `colors_name` and `lualine_a_normal`
  unmoved. The autocmd R3 deleted listened to `ColorScheme`, an *in-nvim*
  event, so it followed `:colorscheme` and never `tinty apply`. R3 is not a
  regression — its replacement follows a scheme change more cheaply than the
  code it replaced. Closing the box needs a palette-delivery hook, which is
  `05-terminal`'s footprint (`tinty/executable_tmux-colors.sh`), not this
  node's. The machine's scheme was restored to `base16-gruvbox-dark-hard`
  after the measurement.
- **`manual.toml` gave a false alarm worth writing down.** The tree carried
  an unstaged deletion of `home/dot_config/television/cable/manual.toml` that
  no requirement names, and R1's list is exhaustive, so this pass restored it
  and applied it — at which point `chezmoi` refused with
  `inconsistent state (…/manual.toml, remove)`. `home/.chezmoiremove` already
  retires that path, added by `03-help-system` (`3f02c2c`), which had left
  the source file behind. The deletion is correct and completes that
  retirement; it is staged in this commit. The restore was reverted in both
  the source tree and `$HOME`.
- **spec01 cites a file that no longer exists.** Its bare-`~` justification
  points at `manual.toml:32`. The live precedents are `quicklist.toml:20`,
  `recent-dirs.toml:9` and `docs.toml:37`; the claim stands, the citation
  does not.
- **`lazy-lock.json` drifts every time this PRD is verified.** Running
  `nvim --headless "+Lazy! sync"` — which spec01's own verify block requires
  — updates `$HOME/.config/nvim/lazy-lock.json` and leaves `chezmoi status`
  reading `MM`. The source copy is unchanged and was not re-added: bumping
  plugin pins is in no requirement here. Pre-existing (the analyst's pass ran
  the same command), reported so the next reader does not read it as this
  node's doing.
- **`05-platform/01-deploy-mechanism` R7's prose is stale**, carried from the
  analyst's report and re-confirmed: it says the hook is "Gated on
  `MASON_SEED`, which `install.sh` exports". Neither half is true any more.
  Outside this footprint.

## Health floor

The brief listed no file in the footprint under the health floor, and this
pass added none: the only edit was six comment lines and one command string
in a 40-line TOML file.

## Workflow land-an-answered-fork

| # | step | outcome |
|---|------|---------|
| 1 | take-the-answers-not-the-stale-report | **pass**. Read `## Answers` first: Q1 → **Automatic**, answered 14:14. The `report.md` on disk read `Verdict: SPECCED` and described an analyst pass — exactly the history this atomic warns about; treated as history, not as this run's state. Both answered-fork consequences map to a spec that carries them: spec02 for R7/Q1's keep-the-hook half, and for the `MASON_SEED` removal the answer's own premise required. |
| 2 | apply-scoped-not-bare | **pass**. `chezmoi diff` first: 14 targets pending, only one of them mine. Applied by name — `chezmoi apply ~/.config/television/cable/theme.toml` — never bare. After it, all thirteen of `05-terminal`'s pending targets (`tmux.conf`, `wezterm.lua`, `tv-all`, `tmux-main`, the two tinty files, `config.nu`, `terminal.nuon`, the two `containers.md` pages) are still pending, untouched. The atomic's `## Fails when` shape appeared exactly as written: `chezmoi status` renders `generate-shell-init.sh`, `register-mcp.sh` and `seed-mason-registry.sh` as `R` at `$HOME` root. They are run-scripts chezmoi executes. Alarming, not a defect; not scoped around. |
| 3 | read-the-merged-config-not-the-source | **pass**, and it earned its place. `keymodel`, `termguicolors` and `mouse` all read correctly only in a real pty; lualine's theme had to come from `get_config()` and its colours from `nvim_get_hl(…, {link=false})` — `lualine_a_normal` is a linked group, and reading it without `link=false` returns an empty table that looks like "the theme is broken". `claudecode`'s `terminal_cmd` had to come from `state.config` after a forced lazy-load, since the plugin is not loaded at startup. No probe quits nvim; each kills its own tmux server after the read, and the pane list was captured before teardown. |
| 4 | rerun-the-drift-check | **fail — the command does not exist in this repo any more.** See `### Edits`. Back-edge to step 3 taken once; step 3 re-passed unchanged (the four pty probes above). Substituted this repo's actual gates, all clean: `just manual` is idempotent (`shasum` over `guide/` + `reference/` identical before and after — `aa7d0e8e49d0…`), closing R9; `just board-guard 09-simplify/06-neovim-television "<my paths>"` exits 0, so no path here is held under another node's live claim; `just board-guard-blocks` exits 0. |

### Edits

Step 4's atomic `rerun-the-drift-check` names a command this repo retired.
`help --check` is gone: `.config/nushell/help-check.nu` is listed in
`home/.chezmoiremove`, and running it now gives

```
Error: nu::parser::unknown_flag
  x The `help` command doesn't have flag `check`.
```

Its `## Fails when` list is unreachable as written too — there is no
`HC_ALLOW` allowlist anywhere in the tree to grep, and no `undocumented:` or
`unresolved:` line to read. All three traps describe a checker that no longer
runs. Replacement text for the atomic:

> #### Do
>
> 1. `just manual` — regenerate the manual's derived pages from the `.nuon`
>    surfaces. It writes into the tree; it does not deploy.
> 2. Take a `shasum` over `help/manual/guide/` and `help/manual/reference/`
>    before and after, and compare.
> 3. `just board-guard <prd> "<your paths>"` and `just board-guard-blocks`.
>
> #### Done when
>
> - The two shasums are identical — the generated pages already matched the
>   `.nuon` surfaces, so nothing in the manual is drifting behind the
>   configuration.
> - `git status` shows a changed page for every `.nuon` you edited and no
>   others.
> - Both guards exit 0.
>
> #### Fails when
>
> - You reach for `help --check`. It was retired with
>   `.config/nushell/help-check.nu` and is in `home/.chezmoiremove`;
>   `nu -c 'help --check'` returns `nu::parser::unknown_flag`, which reads as
>   a broken shell rather than a retired command. There is no `HC_ALLOW`
>   allowlist left to grep either.
> - `just manual` is run but its output is only eyeballed. It prints a page
>   and entry count on every run whether or not anything changed; the shasum
>   pair is the only thing that says "no drift".

## Scores

complexity: 25
blast-radius: mid
workflow: land-an-answered-fork
