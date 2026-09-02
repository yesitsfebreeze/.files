Verdict: DONE

Resumed run, plus one scoped tail after review. An earlier
`implementer-neovim-tv` on this claim was cut off by a usage limit one turn
short of its report, leaving the whole build uncommitted in the working tree.
This pass re-ran every check in both specs against the tree as it stood
rather than trusting the ticks, deployed the paths still pending, measured
the acceptance clauses that only a real pty can answer, found and fixed one
live regression, and committed. The tail then landed the chezmoi retirement
this node owed, and rewrote two acceptance boxes that had been measuring the
wrong thing.

**14 of 14 spec acceptance boxes verified green by re-running both
`## Verify and Proof` blocks end to end** — `spec01-channels-and-lua OK`,
`spec02-mason-hook OK`, re-run once more after the tail and still green. No
box was found ticked-but-false, so none was unticked. **5 of 6 PRD acceptance
boxes are now ticked.** The one left red is box 1, and it is red at `23`
against a ceiling of `15` for a reason no work inside this footprint can
reach — see `## Findings` and `## Handed off`.

## What this pass changed

Two files: `home/dot_config/television/cable/theme.toml` and
`home/.chezmoiremove`.

### `home/.chezmoiremove` — R1's deletions reach the machine (tail)

R1 deleted five cable channels from the source tree, and that is all a source
deletion does: `chezmoi apply` never removes a file it has stopped managing,
so `alias`, `env`, `git-branch`, `git-files` and `zoxide` were still sitting
in `$HOME/.config/television/cable`, still listed by `tv`. In a chezmoi repo
"deleted" has to mean gone from the machine, and this repo already has the
mechanism for saying so: `home/.chezmoiremove`, added by `03-help-system` for
exactly this reason and reused by `04-nushell` one commit before this one,
from outside its own declared footprint. Five lines appended, then a
`chezmoi apply` naming the five target paths — never bare. All five are gone
from `$HOME`; the directory fell `28` → `23` and `tv list-channels` fell
`30` → `27`. Only three of the five names left the channel list, because
`env` and `git-branch` are also baked-in `tv` channel names, so deleting
those two files changes no count.

### `home/dot_config/television/cable/theme.toml` — a dead picker

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
- **Box 1 was measuring the wrong surface, and is now red honestly.** As
  dispatched it read `tv list-channels | wc -l` with no `XDG_CONFIG_HOME`
  named, which measures the machine's entire cable directory rather than the
  surface this repo owns — so it could be red for work no PRD here owns, and
  it was. Rewritten to name all three numbers it actually means: the isolated
  fixture (`16` channels over `10` files, green), the repo tree (`10`,
  green), and the machine (`23`, **red** against 15). The five
  `.chezmoiremove` lines closed this node's share of the gap. What remains is
  `23 - 10 = 13` files that were never managed by this repo at all — `bg`,
  `burrito-sessions`, `git-deletions`, `git-diff`, `git-reflog`,
  `git-remotes`, `git-repos`, `git-stash`, `git-submodules`, `git-tags`,
  `git-worktrees`, `opacity`, `opencode-sessions`. No source deletion and no
  `.chezmoiremove` entry written here can reach a file chezmoi never owned.
  The threshold was left at 15 rather than tuned to the number measured.
- **The `tinty apply` clause of box 3 is struck, not waived.** It could never
  have passed and this node never broke it: tinty's only hook is
  `tinty/config.toml` running `tmux-colors.sh`, and `grep -n nvim` over that
  script returns nothing, at HEAD and in the working tree — there is no nvim
  leg in the palette path. The autocmd R3 deleted
  (`7f98da4^:home/dot_config/nvim/lua/plugins/statusline.lua:51-57`) fires on
  `ColorScheme`, an in-process event, so it followed `:colorscheme` and never
  an outside `tinty apply`. Measured rather than argued: two real `tinty
  apply` calls against a live nvim left `colors_name` and `lualine_a_normal`
  unmoved, and the machine's scheme was restored to
  `base16-gruvbox-dark-hard` afterwards. What R3 replaced the autocmd with is
  proven green independently (three live `:colorscheme` changes, three
  distinct `lualine_a_normal` colours), so the deletion is a drop-in.
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

## Handed off

Two things leave this node named rather than dropped:

- **Thirteen unmanaged television channels in `$HOME`** —
  `09-simplify/retire-the-unmanaged-television-channels`. Listed above. They
  predate this repo's ownership of the cable directory and are the whole of
  box 1's remaining gap. Whoever takes them needs a decision first — adopt
  them into the source tree or delete them from the machine — because
  `.chezmoiremove` only speaks for paths this repo once managed.
- **The palette does not reach a running nvim** —
  `09-simplify/propagate-a-tinty-apply-into-a-running-nvim`. Struck from box 3
  above.
  Closing it needs a new leg in `tmux-colors.sh` (an `nvim --server …
  --remote-send`, or a watcher on `current_scheme` in `colorscheme.lua`).
  `tinty/executable_tmux-colors.sh` is `05-terminal`'s footprint and has a
  live implementer on it, so nothing here went near it.

### Box 1's machine clause, transferred by the orchestrator after this report

Written by the orchestrator, 2026-09-02, after the tail landed as `9b80a71`.

The implementer left acceptance box 1 red at `23` rather than tune its
threshold, which was right. `pearde collect` then refused `done` on the open
box, correctly — and the node that would make it green
(`retire-the-unmanaged-television-channels`) is gated on this one, so the board
deadlocked.

The skeptic that had ruled the clause stayed was asked again, and moved it. Its
test both times was the same one it used on box 3: can any work inside this
PRD's footprint move this number? Yesterday the answer was yes and this node
had not done it — so it stayed. After `9b80a71` the answer is no: the remaining
`23 - 10 = 13` files were never managed by this repo and nothing in this
footprint reaches them. And once they go, the machine count and the
isolated-fixture count measure the same ten files and the same `16`, so the
clause was never a check on this node.

So the clause left whole, with its measurements, and is now
`09-simplify/retire-the-unmanaged-television-channels`'s own acceptance box.
Box 1 keeps the two clauses this node controls, both green, and is ticked.

**The rule this sets:** a clause may leave a PRD only after the in-footprint
work that could have moved it has landed and been measured, with the commit
named. `9b80a71` is that receipt. Moving it before those five lines would have
been talking a red box green, and the skeptic said so at the time.

One correction it made to the derived node, recorded rather than acted on here:
the claim that `.chezmoiremove` only speaks for paths this repo once managed is
probably false — `03-help-system/probe/verify.sh:108-117` plants a canary at
`manual.toml` and watches chezmoi remove it while it has no source entry, which
is the condition the thirteen are in. That node now carries the premise as
something to test with a canary before it is specced, not as a constraint.

## Health floor

The brief listed no file in the footprint under the health floor, and this
pass added none: the only edit was six comment lines and one command string
in a 40-line TOML file.

## Workflow land-an-answered-fork

| # | step | outcome |
|---|------|---------|
| 1 | take-the-answers-not-the-stale-report | **pass**. Read `## Answers` first: Q1 → **Automatic**, answered 14:14. The `report.md` on disk read `Verdict: SPECCED` and described an analyst pass — exactly the history this atomic warns about; treated as history, not as this run's state. Both answered-fork consequences map to a spec that carries them: spec02 for R7/Q1's keep-the-hook half, and for the `MASON_SEED` removal the answer's own premise required. |
| 2 | apply-scoped-not-bare | **pass, run twice.** First pass: `chezmoi diff` first, 14 targets pending, only one of them mine. Applied by name — `chezmoi apply ~/.config/television/cable/theme.toml` — never bare. After it, all thirteen of `05-terminal`'s pending targets (`tmux.conf`, `wezterm.lua`, `tv-all`, `tmux-main`, the two tinty files, `config.nu`, `terminal.nuon`, the two `containers.md` pages) are still pending, untouched. The atomic's `## Fails when` shape appeared exactly as written: `chezmoi status` renders `generate-shell-init.sh`, `register-mcp.sh` and `seed-mason-registry.sh` as `R` at `$HOME` root. They are run-scripts chezmoi executes. Alarming, not a defect; not scoped around. **Re-run in the tail** for the `home/.chezmoiremove` retirement, which is the one shape this atomic does not warn about: a removal is applied by naming the *target* paths that should disappear, not the source file that lists them — `chezmoi apply ~/.config/television/cable/{alias,env,git-branch,git-files,zoxide}.toml`, five paths spelled out. Verified after: those five gone, the other eighteen files in that directory untouched, and all thirteen of `05-terminal`'s targets still pending — that node now has its own implementer on `tmux.conf`, `wezterm.lua`, `tv-all`, `tmux-main`, the tinty pair and the nushell surfaces, and nothing here went near them. |
| 3 | read-the-merged-config-not-the-source | **pass**, and it earned its place. `keymodel`, `termguicolors` and `mouse` all read correctly only in a real pty; lualine's theme had to come from `get_config()` and its colours from `nvim_get_hl(…, {link=false})` — `lualine_a_normal` is a linked group, and reading it without `link=false` returns an empty table that looks like "the theme is broken". `claudecode`'s `terminal_cmd` had to come from `state.config` after a forced lazy-load, since the plugin is not loaded at startup. No probe quits nvim; each kills its own tmux server after the read, and the pane list was captured before teardown. |
| 4 | rerun-the-drift-check | **fail — the command does not exist in this repo any more.** See `### Edits

One edit, and it is already landed: `rerun-the-drift-check` named
`help --check`, a command this repo retired along with
`.config/nushell/help-check.nu` (it is in `home/.chezmoiremove`), and whose
whole `## Fails when` list — the `HC_ALLOW` allowlist, the `undocumented:`
and `unresolved:` lines — describes a checker that no longer runs. The
replacement text this run proposed (`just manual` plus a `shasum` pair over
`guide/` and `reference/`, then both board guards) was applied verbatim to
the atomic by the orchestrator and the counters bumped, so it is not
re-proposed here. The tail found nothing further to edit: step 2 was re-run
against a shape its `## Fails when` does not list, and that observation is
recorded in the step's own row rather than as a change to the atomic, because
it is an addition to `#### Do` for removals specifically, not a correction to
anything the atomic gets wrong.

## Scores

complexity: 25
blast-radius: mid
workflow: land-an-answered-fork
