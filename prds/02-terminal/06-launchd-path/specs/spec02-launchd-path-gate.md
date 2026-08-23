---
est: 1.75h
footprint:
  - tests/wezterm-launchd-path.sh
---

# spec02 — the launchd-path gate: static, resolved, spawned, ordered

`tests/wezterm-launchd-path.sh`, four stages, proving spec01 by reading the
file, by reading the **resolved** config, by actually spawning
`default_prog` out of a launchd-shaped environment, and by computing what
`env.nu` does to the seeded PATH. Lands after spec01; every stage reads what
spec01 writes.

The point of the middle two stages is that greps cannot defend this node.
Three of the four seeded directories already appear in the file today (the
F6 line), so "the string is present" passes before the work is done —
negative control run, recorded below. And the whole subject is a *launch
environment*, which no grep observes at all.

House pattern, inherited from `tests/wezterm-grid-centering.sh` and
`tests/wezterm-appearance.sh`, not re-derived: `set -u`, source
`gates/lib.sh`, `GREP=/usr/bin/grep` (plain `grep` here is a shell function
over ugrep), scratch `HOME` for everything, `chk_ok`/`chk_fail` with a
message naming what failed, `snapshot_paths` over the live wezterm and
nushell files with `assert_unchanged` in the epilogue. Registered
`external`. `SRC="$REPO/home/dot_config/wezterm/wezterm.lua"`,
`NUSHELL_SRC="$REPO/home/dot_config/nushell"`.

Stage flags `--static`, `--config`, `--spawn`, `--path`; no argument runs
all four.

## Two safety rules this gate adds, both learned the hard way

1. **Never `pkill wezterm-mux-server`.** The developer runs WezTerm; a
   pattern kill would take down live sessions. The daemon writes its pid to
   `$HOME/.local/share/wezterm/pid` inside the scratch home — read it and
   `kill "$pid"` (measured: a plain `kill` shuts it down cleanly). Do it
   from a `trap` as well as at the end of the stage, so an early `exit`
   leaves nothing running.
2. **The spawn machine needs a SHORT root.** The mux socket is
   `$HOME/.local/share/wezterm/sock` and a unix socket path must be shorter
   than `SUN_LEN` (104). `gates_tmpdir` lives under `$TMPDIR`
   (`/var/folders/…`, 68 characters here) which leaves almost no budget, and
   an over-long path fails as `path must be shorter than SUN_LEN` — measured,
   from a first attempt under a long scratch root. Create the spawn machine
   under its own `mktemp -d /tmp/wzt7.XXXXXX` with its own cleanup trap, and
   `chk` that the computed sock path is under 104 bytes so a future longer
   root fails loudly instead of mysteriously.

## Stage `--static` — greps and shape over the source file

Each of these is satisfiable only after spec01, and the ones with a
pre-existing-hit risk are counted rather than merely found. The counts in
brackets are the measured values **before** spec01 lands, so a box that
would pass today is marked as such and is not used alone.

- `config.default_prog = { "nu", "--config"` present, and
  `^config\.default_prog` occurs exactly once. [0 before — clean]
- `^config\.set_environment_variables = {` occurs exactly once. Do **not**
  grep the bare word: it has a pre-existing hit in the header comment
  ("Deliberately absent: …"), 1 before spec01.
- `XDG_CONFIG_HOME` present. [0 before — clean]
- `os.getenv("PATH")` present. [0 before — clean]
- The line immediately **above** `config.set_environment_variables.PATH =`
  is exactly `if is_mac then`, and the line number of
  `config.set_environment_variables = {` is **lower** than the line number
  of that `if is_mac then` (the branch mutates the table; reversed, it
  indexes a nil).
- Each of `/opt/homebrew/bin`, `/opt/homebrew/sbin`, `.local/bin`,
  `.cargo/bin` occurs exactly **twice** — once in the launch prefix, once in
  the F6 `sh -lc` line. [1 each before spec01. This is the negative control
  that matters: "present" alone is already true today, so the check has to
  be a count.]
- `"sh", "-lc"` occurs exactly **once** (R4: one repetition, not two — the
  second subprocess was the wallpaper pipeline, refused by open decision
  5(a)). [1 before — pre-existing, and the assertion is that it stays 1.
  Note for whoever extends this gate: this is also why a file-wide "no
  shell name appears" assertion is unsatisfiable here.]
- `Deliberately absent: default_prog` occurs **zero** times. [1 before —
  red today, green after.]
- No comment claims the window dies: `dies on the spot`, `dies immediately`
  and `window dies` each occur zero times. The measured behaviour is a pane
  that stays open (spec01's finding 1), and a comment asserting otherwise is
  a false record for the next reader.
- The F6 comment carries the corrected reason: `path_helper` and
  `/etc/paths.d/homebrew` both appear in the file.
- Untouched-sibling guards, so this node's edit is caught if it drifts into
  another's region: `no #rrggbb constant anywhere`,
  `hide_tab_bar_if_only_one_tab = true`,
  `status_update_interval = 5000`, `enable_kitty_keyboard = false`,
  `window_padding = { left = 0, right = 0, top = 0, bottom = 0 }`,
  `grid_padding(`, `format-tab-title`, and `git ls-files
  home/dot_config/wezterm/` is exactly `home/dot_config/wezterm/wezterm.lua`.

## Stage `--config` — the resolved values, not the text

`wezterm --config-file <file>` executes arbitrary Lua and a config that
returns `{}` exits 0, so the pinned binary is the Lua interpreter — the same
trick `tests/wezterm-grid-centering.sh --math` uses. Here it goes one step
further and `dofile`s `$SRC` itself, then reads the values back out of the
`config_builder` table. Measured 2026-08-23: `dofile` of the real file under
a scratch `HOME` succeeds, and both `cfg.default_prog` and
`cfg.set_environment_variables` read back — the builder's proxy does not
hide them.

Precondition `chk`: `wezterm` on PATH; echo `wezterm --version` (the epic
pins `20240203-110809-5046fc22`).

The probe, written into the scratch dir:

```lua
local ok, cfg = pcall(dofile, os.getenv("SRC"))
local f = io.open(os.getenv("OUT"), "w")
if not ok then f:write("ERR\t" .. tostring(cfg) .. "\n"); f:close(); return {} end
f:write("default_prog\t" .. table.concat(cfg.default_prog or {}, "|") .. "\n")
for k, v in pairs(cfg.set_environment_variables or {}) do
  f:write("sev." .. k .. "\t" .. tostring(v) .. "\n")
end
f:close()
return {}
```

run as
`env -i HOME="$H" PATH=/usr/bin:/bin SRC="$SRC" OUT="$H/o.tsv" "$WEZTERM"
--config-file "$H/probe.lua" ls-fonts --list-system`. A missing or empty
`$OUT` is one FAIL saying the probe never ran — never a silent pass.

Assert, against `H="$SCRATCH/cfg"`:

| key | expected |
|---|---|
| `default_prog` | `nu\|--config\|$H/.config/nushell/config.nu\|--env-config\|$H/.config/nushell/env.nu` |
| `sev.XDG_CONFIG_HOME` | `$H/.config` |
| `sev.PATH` | `/opt/homebrew/bin:/opt/homebrew/sbin:$H/.local/bin:$H/.cargo/bin:/usr/bin:/bin` |

The `PATH` row is the whole of R2 in one string: the four directories, their
order, and `os.getenv("PATH")` appended as a separate entry. Also assert
`sev` has exactly two keys — an extra exported variable is scope creep this
node did not ask for.

Two counterfactuals, each on a `sed`ed copy in the scratch dir, never on
`$SRC`:

- The `if is_mac then` guard deleted so the assignment is unconditional →
  the shape checks in `--static` must FAIL against that copy. (The resolved
  value is identical on macOS, which is exactly why the guard needs a
  *static* check and not a value check. Say so in the script.)
- `home .. "/.config"` changed to `home .. "/.conf"` → the
  `sev.XDG_CONFIG_HOME` row must FAIL. This is the "a typo'd path still
  looks right" case.

Then a load probe, `tests/wezterm-appearance.sh`'s `probe_load` shape: with
`HOME` pointed at the scratch dir, `wezterm --config-file "$SRC" ls-fonts
--list-system` exits 0 and stderr carries neither `not a valid Config field`
nor `Configuration Error`.

## Stage `--spawn` — a real spawn out of a launchd-shaped environment

This is the stage that proves the node. `wezterm-mux-server` spawns
`default_prog` through the **same** mux code path the GUI uses, so a
launchd-shaped `env -i` launch can be observed with no GUI and no display.
Everything below was measured end to end on 2026-08-23 before this spec was
written.

**The one compromise, named rather than hidden: `wezterm.gui` is `nil` in
`wezterm-mux-server`.** Measured: a config calling
`wezterm.gui.default_key_tables()` — which `$SRC` does, for T.4's copy-mode
table — raises `attempt to index a nil value (field 'gui')`, WezTerm falls
back to its default config, and the pane comes up as the login shell. That
failure is silent: `cli list` just says `zsh`, which is indistinguishable
from R6 being absent. So the stage loads `$SRC` through a two-line shim that
supplies **only** that function, and the shim's own presence is asserted to
be exactly that:

```lua
local wezterm = require("wezterm")
if wezterm.gui == nil then
  wezterm.gui = { default_key_tables = function()
    return { copy_mode = {}, search_mode = {} }
  end }
end
return dofile(os.getenv("SRC"))
```

Everything else is the real file. Two consequences to state in the script,
because a reader will otherwise over-trust this stage: the nine-tab floor
does **not** run (it hangs off `window-config-reloaded`, a GUI event
`wezterm-mux-server` never emits, so the probe sees one pane), and the GUI's
own startup is not exercised. Those two are what the `gates/manual/wave4.md`
rows below are for.

Precondition `chk`s: `wezterm-mux-server` on PATH (it ships in the same
Homebrew formula as `wezterm`), and `nu` on PATH.

**The machine.** Under the short root: `$M/home/.config/nushell/` gets every
`*.nu` from `$NUSHELL_SRC` plus a copy of its `help/` directory;
`$M/home/.cache/nushell/init/` gets one-line stubs for `starship`, `zoxide`
and `television` (the shape `tests/shell-help.sh:mk_machine` uses);
`$M/home/.local/bin/ollama-host` gets an executable stub printing one line.
That last one is hygiene with a reason: `env.nu`'s interactive block runs
`^ollama-host` and a missing binary prints a runtime error into the pane on
every start — measured, and `~/.local/bin/ollama-host` is a live-machine
binary this repo does not deploy. Not this node's bug; staging the stub keeps
it out of the way, and its absence is not what any box here measures.

**The launch.** `env -i HOME="$M/home" PATH=/usr/bin:/bin TMPDIR="$M/tmp"
SRC="$CFG" wezterm-mux-server --config-file "$M/shim.lua" --daemonize`,
where `$CFG` is `$SRC` for the positive case and a `sed`ed copy for each
counterfactual. `PATH=/usr/bin:/bin` stands in for launchd's
`/usr/bin:/bin:/usr/sbin:/sbin` — measured: `launchctl getenv PATH` is
unset, so a GUI-launched app gets the hardcoded default.

**Reading the answer: write a file from inside the pane, do not scrape the
screen.** The pane is 80x24 and `cli get-text` returns it wrapped, which
silently truncates any value longer than 80 columns — the first attempt at
this lost half a PATH that way. So drive it with

```
wezterm cli send-text --pane-id 0 --no-paste \
  '{ dcd: $nu.default-config-dir, hp: $nu.history-path,
     xdg: $env.XDG_CONFIG_HOME,
     w: (which nu nvim tv zoxide | get path) }
   | to nuon | save -f ~/probe.nuon
'
```

(the trailing newline is the Enter; reedline submits on it) and then poll for
`$M/home/probe.nuon` for a bounded number of short sleeps, failing with "the
pane never answered" if it does not appear. `cli get-text` is used **only**
for the failure cases, where no shell ever runs and the text is WezTerm's
own. Assert:

- `dcd` is `$M/home/.config/nushell` — R7's export reached the launch
  environment. Measured value on the positive run:
  `/private/tmp/…/home/.config/nushell`, so compare against the resolved
  (`cd … && pwd -P`) form of the machine root.
- `hp` sits under that directory and ends `history.sqlite3` — the history db
  is inside the managed tree.
- `xdg` is `$M/home/.config`.
- `w` holds four paths and every one is under `/opt/homebrew/bin` — R1's
  acceptance box, `nu`, `nvim`, `tv` and `zoxide` all resolved from a launch
  PATH of `/usr/bin:/bin`. Measured:
  `/opt/homebrew/bin/{nu,nvim,tv,zoxide}`.
- A second `send-text` of `help | lines | first 2 | to nuon | save -f
  ~/help.nuon` yields a file whose text contains `Topics:` and at least two
  `— ` topic summaries: a launch out of a launchd-shaped environment renders
  **this environment's manual**. Measured: `Topics: / navigate — Zoxide
  jumps… (12 entries) / find — television in the shell… (12 entries)`.
- `$M/home/Library/Application Support/nushell` does **not** exist after the
  positive run. Same shape as the `~/.cache/nushell` leak check in
  `tests/shell-television.sh`'s epilogue, and it discriminates: it is
  created, holding `history.sqlite3`, in counterfactual 1 below.

**The three counterfactuals**, each on its own machine and its own daemon,
each one measured to produce exactly the stated observable:

1. **`XDG_CONFIG_HOME` removed from `set_environment_variables`.** The shell
   still starts; `dcd` is `$M/home/Library/Application Support/nushell` and
   `hp` is the `history.sqlite3` under it, and that directory now exists on
   disk. This is R7's box going red, and it is the whole reason R7 is a
   requirement rather than a nicety — the defect is invisible until you look
   for the database.
2. **The whole `if is_mac` PATH block removed.** No shell starts at all.
   `cli list` titles the pane `wezterm`, and `cli get-text --pane-id 0`
   carries `Unable to spawn nu because:` and
   `No viable candidates found in PATH "/usr/bin:/bin"` and
   `didn't exit cleanly`. Assert all three strings, and assert the pane still
   **exists** — that last one is spec01's finding 1 as a check, so the day
   someone "corrects" the comment back to "the window dies" the gate
   contradicts them.
3. **`config.default_prog` removed.** `cli list` titles the pane `zsh`, and
   `get-text` carries neither `Unable to spawn` nor a nushell prompt. Assert
   the title is `zsh` and that `probe.nuon` is never written. This is R6's
   box going red, and it is the measurement that corrects the recorded
   premise: the fallback is the passwd login shell, `/bin/zsh` here, not a
   configless `nu`.

There is deliberately **no** counterfactual for dropping only
`~/.local/bin` and `~/.cargo/bin` from the prefix, and the script says why
rather than leaving the gap to be read as an oversight: measured, nothing
WezTerm itself spawns lives in either directory (`nu` is
`/opt/homebrew/bin/nu`, and the F6 subprocess carries its own prefix), and
`env.nu` re-prepends both inside the shell before anything uses them. Those
two entries are defence in depth and the reason to keep them is that the
launch prefix and the F6 prefix stay identical; the `--config` stage pins
them by exact string, which is the honest level of proof for an entry with
no behavioural consequence.

## Stage `--path` — R5, and the F6 prefix

No GUI, no daemon; two hermetic computations.

**R5, the ordering.** R5 says a terminal launch is unaffected: no doubled or
reordered entry changes which binary wins. That is a property of `env.nu`'s
repair, and it is computable. Extract nothing — restate `env.nu`'s pipeline
by *running* `env.nu`'s own repaired value: launch
`nu --config <machine config.nu> --env-config <machine env.nu> -c '$env.PATH
| str join ":"'` twice under `env -i` with a scratch `HOME`, once with the
launch PATH set to the seeded prefix (as `--config` reports it) and once with
a terminal-shaped PATH that already carries the user dirs first. Assert, for
both:

- the index of `<home>/.cargo/bin` is lower than the index of
  `<home>/.local/bin`, which is lower than the index of `/opt/homebrew/bin`
  — `env.nu`'s order, under either launch shape. Measured both ways.
- no entry appears twice. Measured: `uniq` collapses the seeded duplicates
  completely, and the repaired PATH is nine entries either way. Note the
  trap that produced a false alarm the first time: the collapse depends on
  the seeded literal and `$nu.home-dir` spelling the home directory the same
  way, so a scratch `HOME` under a *symlinked* root (`/tmp` →
  `/private/tmp`) does **not** collapse. Resolve the machine root with
  `pwd -P` before using it, and say why in a comment.

Also assert, and this is the fact that makes R5 true rather than lucky: the
seeded prefix's own order (`/opt/homebrew/bin` first) is the **reverse** of
`env.nu`'s relative order for the user dirs, and it does not matter because
`prepend` + `uniq` puts the user dirs first regardless. Six basenames are
actually duplicated across the four seeded directories on this machine —
`burrito`, `node`, `npm`, `npx`, `tree-sitter`, `zoxide` — so this is a live
difference, not a hypothetical one, and the shell resolves every one of them
the same way under both launch shapes.

**The F6 prefix (R4).** Extract the export line from `$SRC` with
`sed -n 's/.*export PATH="\([^"]*\)".*/\1/p'` — assert exactly one match,
which is R4's "one repetition" as a byte fact — and run it under a scratch
`HOME` holding executable stubs at `.local/bin/probe-local` and
`.cargo/bin/probe-cargo`:

```sh
env -i HOME="$H" PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/sh -lc \
  'export PATH="<the extracted value>"; command -v probe-local; command -v probe-cargo'
```

Both must resolve. Then the negative control, without the export: **neither**
resolves, and `command -v nu` **does** — because `sh -lc` is a login shell,
`/etc/profile` runs `path_helper`, and `/etc/paths.d/homebrew` carries
`/opt/homebrew/bin`. Measured 2026-08-23, and it is the correction spec01
writes into the F6 comment: the prefix is load-bearing for `~/.local/bin`
(where `tinty` is) and `~/.cargo/bin`, not for `nu`. Assert the
`command -v nu` half explicitly, so the corrected reason is defended by a
check and not only by a comment.

One live-machine trap to guard against, not to depend on: this developer's
`~/.profile` sources `~/.cargo/env`, so a login shell with the *real* `HOME`
finds `~/.cargo/bin` with no export at all. This repo deploys no
`~/.profile`, so the negative control must run under a scratch `HOME` — with
the real one it passes for the wrong reason.

## Not this implementer's files

`gates/waves.tsv` and `gates/manual/wave4.md` are the orchestrator's on this
board — three lanes have appended to that one gates cell concurrently. Do
not edit either. The exact text is below so the orchestrator does not have to
re-derive it.

**`gates/waves.tsv`** — append this segment, verbatim, to the **wave-4**
gates cell (the row whose task list already contains `T.7`):

```
 | external bash tests/wezterm-launchd-path.sh
```

**`gates/manual/wave4.md`** — three rows, in the file's existing PASS/FAIL
style, every box `[ ]` (`gates/manual-coverage.sh` fails a pre-ticked box,
and `T.7` must appear in no other wave file). Each carries the measurement
that is the reason it cannot be automated:

```markdown
- [ ] **T.7** — a real GUI launch comes up as nine working nushell prompts.
      Launch WezTerm from the Dock or Spotlight (not from a terminal) and
      type `$nu.default-config-dir` in three different tabs.
      PASS: every tab has a nushell prompt and answers
      `~/.config/nushell`.
      FAIL: any tab showing `Unable to spawn nu because: No viable
      candidates found in PATH`, a `%` shell prompt (the passwd login shell,
      `/bin/zsh` — R6 absent), or an answer under `~/Library/Application
      Support`.
      Why a human: `tests/wezterm-launchd-path.sh --spawn` covers the spawn
      through `wezterm-mux-server`, but measured 2026-08-23 `wezterm.gui` is
      nil there — the config's `wezterm.gui.default_key_tables()` raises and
      WezTerm silently falls back to its defaults — so the probe loads the
      file through a `wezterm.gui` shim, and `window-config-reloaded` is a
      GUI event the mux server never emits, so the nine-tab floor never runs
      and the probe only ever sees one pane.
- [ ] **T.7** — F6 flips the theme from a GUI-launched window. In that same
      Dock-launched window press `F6`, wait, press it again.
      PASS: every window retints both times.
      FAIL: nothing happens — the inline prefix in the F6 `sh -lc` is what
      puts `~/.local/bin` on that subprocess's PATH.
      Why a human: `tinty` is the binary the prefix earns (measured: `sh -lc`
      recovers `/opt/homebrew/bin` on its own through `path_helper` and
      `/etc/paths.d/homebrew`, so `nu` resolves without it while `tinty` does
      not), and the observable is a colour change in a live GUI window.
      The automated stage proves only that the directory reaches the
      subprocess's PATH.
- [ ] **T.7** — a GUI launch and a terminal launch resolve the same
      binaries. In the Dock-launched window run `which -a nu nvim tv zoxide
      node npm`; then run `wezterm` from an existing terminal and run the
      same thing there.
      PASS: each name resolves to the same absolute path in both windows.
      FAIL: any name resolving differently — the launch prefix's order has
      leaked past `env.nu`'s repair.
      Why a human: two differently *launched* real windows is the whole
      subject, and it cannot be staged. Worth running on the listed names
      rather than a favourite: measured 2026-08-23, six basenames exist in
      more than one of the four seeded directories (`burrito`, `node`,
      `npm`, `npx`, `tree-sitter`, `zoxide`), so those are where a reorder
      would actually show.
```

## Acceptance

- [x] `bash tests/wezterm-launchd-path.sh` is ALL PASS, and each stage also
      runs alone via `--static`, `--config`, `--spawn`, `--path`.
- [x] Every counterfactual in this spec is asserted to FAIL, and the run
      quotes the observable: the unconditional-`is_mac` copy, the `.conf`
      typo copy, the missing `XDG_CONFIG_HOME` machine (`dcd` under
      `Library/Application Support` and that directory present on disk), the
      missing PATH block machine (`No viable candidates found in PATH` with
      the pane still alive), and the missing `default_prog` machine (pane
      title `zsh`, no `probe.nuon`).
- [x] The gate can fail for this node's defect: with spec01's block removed
      from a scratch copy of `wezterm.lua`, `--static` and `--config` report
      a non-zero failure count. Quote it.
- [x] No `pkill` anywhere in the script; every daemon is stopped by the pid
      from its own machine's `.local/share/wezterm/pid`, and no
      `wezterm-mux-server` process outlives the run (`ps` before and after,
      same count).
- [~] The script never names `$HOME/.config`, never writes outside its
      scratch roots, and the epilogue reports the live
      `~/.config/wezterm/wezterm.lua` and the live
      `~/.config/nushell/{config.nu,env.nu,history.sqlite3}` byte-identical,
      plus `~/.cache/nushell` and `~/Library/Application Support/nushell`
      absent (skipped, in the house shape, if either pre-existed).
- [x] **Closed by the orchestrator on the transition.** Appended
      `| external bash tests/wezterm-launchd-path.sh` to the wave-4 gates
      cell and the three `**T.7**` rows to `gates/manual/wave4.md`. Verified:
      `bash gates/manual-coverage.sh` → exit 0, 0 FAIL, `grep -c 'T\.7'` → 3,
      and `bash gates/wave-status.sh --validate` no longer names
      `wezterm-launchd-path.sh` — the sole remaining `unreferenced` entry is
      `nvim-treesitter.sh`, whose implementer is still `claimed`, so
      `gates/selftest.sh`'s one FAIL is that lane's and clears on its
      transition. Original box: `bash gates/manual-coverage.sh` is green once
      the orchestrator has
      added the three `T.7` rows, and `bash gates/wave-status.sh --run 4`
      is green once it has appended the wave-4 segment. Both are the
      orchestrator's boxes — record which of them had landed when this ran.
- [x] The six sibling wezterm gates stay green (all six were ALL PASS before
      this node started; that baseline is recorded here so a regression is
      attributable).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/wezterm-launchd-path.sh
for s in --static --config --spawn --path; do
  bash tests/wezterm-launchd-path.sh "$s" | tail -2
done

# the gate can fail for this defect
ps -eo command | /usr/bin/grep -c '[w]ezterm-mux-server'   # before
bash tests/wezterm-launchd-path.sh | tail -3
ps -eo command | /usr/bin/grep -c '[w]ezterm-mux-server'   # after: same

bash gates/manual-coverage.sh | tail -2
bash gates/wave-status.sh --run 4 | tail -3
for g in appearance startup-layout f5-tab-select copy-mode \
         tab-content-state grid-centering; do
  bash "tests/wezterm-$g.sh" | tail -1
done
ls "$HOME/Library/Application Support/nushell" ; ls "$HOME/.cache/nushell"
```

## Implemented 2026-08-23

`bash tests/wezterm-launchd-path.sh` — **94 checks, 94 passed, 0 failed, ALL
PASS**; each stage also runs alone (`--static` 34, `--config` 16, `--spawn` 35,
`--path` 16 — each count includes the four epilogue checks). `ps -eo command |
grep -c '[w]ezterm-mux-server'` is 0 before and 0 after, and the gate asserts
that equality itself.

**Three deviations, named rather than hidden.**

1. **The four-directory count is over CODE.** `exactly twice` is not
   satisfiable over the whole file: spec01's own block comment quotes
   `env.nu`'s `prepend` order and the repaired PATH, and the F6 comment repair
   spec01 mandates quotes the `path_helper` measurement — both name the
   directories in prose, which this repo's carry-the-reason convention
   requires. Raw hits on the finished file are 5 / 3 / 5 / 6; code hits are
   2 / 2 / 2 / 2. The negative control is untouched: before the block landed
   the CODE count was 1 each, the F6 line alone. `code_of()` strips full-line
   Lua comments and the gate's header records the reason.

2. **`$HOME/.config` is named, so that box is `[~]` and not `[x]`.** It cannot
   be both unnamed and hashed, and this spec's own epilogue box asks the gate
   to report the live `~/.config/wezterm/wezterm.lua` and
   `~/.config/nushell/{config.nu,env.nu,history.sqlite3}` byte-identical. The
   substance holds: those paths are read and never written, every `wezterm`,
   `wezterm-mux-server` and `nu` invocation pins `HOME` inside a scratch root,
   and the epilogue reports them byte-identical with `~/.cache/nushell` and
   `~/Library/Application Support/nushell` absent.

3. **The `--spawn` probe is ONE line.** Reedline submits on every newline, so
   the multi-line pipeline this spec shows is submitted as fragments: measured,
   the first run rendered a table into the pane and the continuation line
   failed as `| to nuon` with no input, and `probe.nuon` was never written. The
   `help` probe uses `first 3`, not `first 2`. `first 2` yields `Topics:` plus
   one topic summary, one short of the two this spec asserts.

4. **The counterfactual-2 pane text is matched through `squash`.** WezTerm
   rewraps the 80-column pane, and the error prints more than once: measured,
   the second copy came back as `Unable to spawn nu` with ` because:` on the
   next line, and a literal match on the raw bytes read as a missing message —
   one flaky FAIL in one full run out of five. `norm` cannot repair that, since
   the break carries no space to restore, so both haystack and needle have
   every space, tab and newline dropped before matching. Same helper and same
   reason as `tests/shell-help.sh`'s. Three consecutive full runs are ALL PASS
   after the change. This is the same 80-column trap this spec names for the
   positive run, which is why that one answers through a file.

**Also corrected in passing:** spec01's Verify snippet invokes a bare `wezterm`
under `env -i PATH=/usr/bin:/bin`, which fails as `env: wezterm: No such file
or directory` — `wezterm` is in `/opt/homebrew/bin`, which is the fact this
node exists for. The gate uses `"$WEZTERM"`, the absolute path, everywhere.

**The orchestrator's two boxes, as they stood when this ran.** Neither had
landed. `bash gates/manual-coverage.sh` is green and holds no `T.7` row in any
wave file (`grep -rn 'T\.7' gates/manual/` is empty). `bash
gates/wave-status.sh --run 4` is green and reports `wave 4 — PENDING 10/18`,
its gates cell not yet naming this script. `bash gates/wave-status.sh
--validate` is consequently red on `registry: every script under tests/ is
named by a row (unreferenced: nvim-telescope.sh wezterm-launchd-path.sh)`,
which is what also makes `gates/selftest.sh`'s `wave-status.sh` contract red —
that failure pre-existed this node (`nvim-telescope.sh`, another lane's, trips
it on its own) and clears when the wave-4 segment is appended.
