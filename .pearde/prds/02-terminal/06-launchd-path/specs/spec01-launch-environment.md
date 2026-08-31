---
est: 0.75h
footprint:
  - home/dot_config/wezterm/wezterm.lua
---

# spec01 — the launch environment block in `wezterm.lua`

One contiguous block near the top of
`home/dot_config/wezterm/wezterm.lua`: `default_prog` (R6),
`set_environment_variables.XDG_CONFIG_HOME` (R7) and the macOS-only PATH
prefix (R2, R3, R5). Plus two comment repairs elsewhere in the same file —
the header's "deliberately absent" note, which this spec makes false, and
the F6 cross-link, whose stated reason is **wrong** and must not be
inherited. **R4 needs no new code**: the inline prefix in the F6 `sh -lc`
already landed with
[`01-appearance`](../../01-appearance/specs/spec01-wezterm-lua.md) (line
201 of that spec), so R4's work here is the comment and the gate's
assertion that it stays exactly one repetition.

Every measurement quoted below was taken on 2026-08-23 against the pinned
build `20240203-110809-5046fc22` and nushell 0.114.1, and is recorded where
it is used because each one is a thing the next reader would otherwise
assume.

## Three things the PRD says that measurement contradicts

Carry the corrected version into the file. Do not carry the PRD's wording.

1. **R1/R3: "the window dies on the spot" / "dies immediately" is
   false.** Measured with `wezterm-mux-server` under `env -i` with
   `PATH=/usr/bin:/bin` and `default_prog = { "nu", … }`: the pane is
   created and **stays open**, showing

   ```
   Unable to spawn nu because:
   No viable candidates found in PATH "/usr/bin:/bin"
   ⚠️ Process "nu --config …" in domain "local" didn't exit cleanly
   Exited with code 1.
   This message is shown because exit_behavior="CloseOnCleanExit"
   ```

   Neither this file nor the live one sets `exit_behavior`, so WezTerm's
   default `CloseOnCleanExit` applies and a *non*-clean exit keeps the pane.
   The failure is a terminal you cannot type into, not a window that
   disappears — which matters, because "it died" and "it is sitting there
   with an error" are diagnosed differently. The requirement itself stands;
   only its stated reason changes.

2. **The fallback is `zsh`, not "plain `nu`".** The recorded premise for R6
   was that a `default_prog`-less GUI launch falls back to a plain `nu`
   reading `~/Library/Application Support/nushell/config.nu`. Measured:
   `dscl . -read /Users/feb UserShell` is `/bin/zsh`, and a GUI-launched
   WezTerm exports no `SHELL` (launchd's GUI environment carries
   `SSH_AUTH_SOCK` and nothing else — already recorded in this file's own
   R10 comment). `wezterm-mux-server` with no `default_prog` under `env -i`
   spawns `-zsh`, and `cli list` titles the pane `zsh`. So R6's absence is
   worse than recorded: nushell does not run **at all**, none of
   [`04-shell`](../../../04-shell/prd.md) loads, and `help` — which
   [`AGENTS.md`(../../../../../AGENTS.md) makes the thing an agent reads
   before acting on this environment — does not exist as a command. The
   "builtin welcome text" shape is what a *terminal*-launched `nu` without
   the export gives, not what this file's absence gives.

3. **R4's reason is wrong about `nu`.** See the F6 comment repair below.

## Placement

Anchor on content, never on line numbers.

Insert the whole block immediately **after**

```lua
local home = os.getenv("HOME") or ""
```

and **before** the `-- ── 02-startup-layout: the self-healing nine-tab
floor` banner. That is the deployed file's own order (epic I4), and it has
to be after `local is_mac` and `local home`, which the block reads.

Touch nothing else. In particular leave `config.keys`,
`format-tab-title`, `config.window_padding`, `grid_padding`,
`config.status_update_interval` and the copy-mode key table exactly as they
are — four sibling nodes own regions of this file and this edit must leave
no change outside its own inserted block and the two comment repairs named
at the end.

## The block

```lua
-- ── 06-launchd-path: the launch environment ─────────────────────────────────

-- Nushell, with both config files named absolutely (R6). A GUI-launched
-- WezTerm gets no default_prog for free and WezTerm then falls back to the
-- passwd login shell. Measured 2026-08-23 on this machine: `dscl . -read
-- /Users/feb UserShell` is /bin/zsh, launchd's GUI environment exports no
-- SHELL (only SSH_AUTH_SOCK -- see the foreground-process comment further
-- down), and a wezterm-mux-server started under `env -i` with no
-- default_prog spawns `-zsh`. So without this line the terminal never starts
-- nushell at all: no aliases, no keybindings, no `help`.
--
-- Both files are named rather than left to discovery, because the config
-- directory nushell would discover is not the managed one -- see the
-- XDG_CONFIG_HOME comment below, which is the other half of the same fact.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"
config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }

-- XDG_CONFIG_HOME is exported at LAUNCH, and that is the whole point (R7).
-- $nu.default-config-dir is a launch-time CONSTANT, so env.nu's own
-- assignment runs too late to move it and everything nushell derives from it
-- drifts out of the managed tree. Measured 2026-08-23 on nushell 0.114.1:
-- with --config/--env-config but no export, $nu.default-config-dir is
-- ~/Library/Application Support/nushell and $nu.history-path is the
-- history.sqlite3 under it -- and reedline really does create it there, so
-- the shell history silently leaves ~/.config. history.nu's header records
-- the same lesson for that path; this line is what makes it come out right.
-- Not inside the is_mac branch: it is correct on every platform.
config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- PATH seeding, macOS only (R2, R3). default_prog above is spawned by
-- WezTerm itself -- execvp against the process PATH, never through a login
-- shell -- and a GUI launch inherits launchd's PATH. Measured 2026-08-23:
-- `launchctl getenv PATH` is unset, so that is the hardcoded
-- /usr/bin:/bin:/usr/sbin:/sbin, with no Homebrew in it. Without this prefix
-- the spawn fails with `No viable candidates found in PATH` and the pane
-- STAYS OPEN carrying that message plus "didn't exit cleanly" -- WezTerm's
-- default exit_behavior is CloseOnCleanExit, so the failure is a terminal
-- you cannot type into rather than a window that disappears.
--
-- Four DIRECTORIES, fixed, not a list computed from the installed package
-- set: it seeds directories, so adding a package to the provisioning set
-- needs no change here. Not seeded on Linux -- this is a macOS-host-only
-- configuration and nu is on PATH there already.
--
-- Getting the binary spawned is all this does; env.nu owns PATH inside the
-- shell, and it wins by construction (R5). env.nu `prepend`s ~/.cargo/bin
-- and ~/.local/bin, `append`s the Homebrew and system dirs and `uniq`s, so
-- the duplicates this prefix creates collapse and the shell's resolution
-- order is env.nu's under either launch shape. Measured both ways on
-- 0.114.1: the repaired PATH is
-- .cargo/bin:.local/bin:/opt/homebrew/bin:... whether the launch PATH was
-- this prefix or a terminal's inherited one.
if is_mac then
    config.set_environment_variables.PATH =
        "/opt/homebrew/bin:/opt/homebrew/sbin:"
        .. home .. "/.local/bin:" .. home .. "/.cargo/bin:"
        .. (os.getenv("PATH") or "")
end
```

Three shape constraints the gate checks, so do not reformat past them:

- The `XDG_CONFIG_HOME` assignment is **outside** the `is_mac` branch and
  the `PATH` assignment is **inside** it — `if is_mac then` is the line
  immediately above `config.set_environment_variables.PATH =`.
- `config.set_environment_variables = {` comes **before** `if is_mac then`;
  the branch mutates the table the assignment created, and reversing the two
  indexes a nil.
- `os.getenv("PATH")` is appended with an `or ""` guard, and the prefix ends
  with a `:` so the inherited value concatenates as a separate entry.

## The two comment repairs

**The header, lines 6-9.** It currently reads

```lua
-- Deliberately absent: default_prog, set_environment_variables and the launchd
-- PATH block — prds/02-terminal/06-launchd-path owns those and lands later;
-- until then WezTerm falls back to the login shell and this file loads
-- standalone.
```

which this spec makes false in every clause. Replace with a note that the
launch environment — `default_prog`, `set_environment_variables` and the
macOS PATH prefix — is `prds/02-terminal/06-launchd-path`'s and sits
immediately below. Keep the surrounding ownership lines untouched. The gate
asserts the string `Deliberately absent: default_prog` is gone, which is a
check that is red today and green after.

**The F6 cross-link, immediately above the `key = "F6"` entry.** It
currently claims the inline prefix exists because a GUI-launched WezTerm
inherits launchd's minimal PATH "where neither `nu` nor `tinty` resolves".
The `nu` half is **false**, measured 2026-08-23: `sh -lc` is a *login*
shell, so `/etc/profile` runs `path_helper`, `/etc/paths.d/homebrew`
carries `/opt/homebrew/bin`, and

```
env -i HOME=$HOME PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  /bin/sh -lc 'command -v nu; command -v tinty'
```

answers `/opt/homebrew/bin/nu` and `tinty: NOT FOUND`. What the prefix
actually earns is `~/.local/bin` — where `tinty` is installed — and
`~/.cargo/bin`, neither of which `path_helper` ever adds; `/opt/homebrew/sbin`
too, since `/etc/paths.d/homebrew` names only `bin`. Rewrite the comment to
say that, and to say explicitly that it must not be "simplified" away on the
grounds that `nu` is found without it: the toggle would then fail on
`tinty`, one layer further in, where the cause is much harder to see. Do
**not** touch the code of the F6 entry — it is already exactly right, and
[`01-appearance`](../../01-appearance/prd.md) R11 owns the binding.

One further live-machine trap, worth the line in that comment: on *this*
machine `~/.profile` sources `~/.cargo/env`, which is what puts
`~/.cargo/bin` into a login shell's PATH here. This repo deploys no
`~/.profile` (`git ls-files home` has no `dot_profile`), so that is a local
accident and nothing may rely on it.

## Acceptance

- [x] `config.default_prog` is assigned exactly once, at line start, and its
      five elements are `nu`, `--config`, `<home>/.config/nushell/config.nu`,
      `--env-config`, `<home>/.config/nushell/env.nu` — read back from the
      resolved config, not grepped.
- [x] `set_environment_variables.XDG_CONFIG_HOME` resolves to
      `<home>/.config`, and `set_environment_variables.PATH` resolves to
      `/opt/homebrew/bin:/opt/homebrew/sbin:<home>/.local/bin:<home>/.cargo/bin:`
      followed by the launching process's own PATH, in that order.
- [x] The `PATH` assignment's immediately preceding line is `if is_mac then`,
      and the `XDG_CONFIG_HOME` assignment is not inside that branch.
- [x] The string `Deliberately absent: default_prog` no longer appears in the
      file, and no comment in the file says the window "dies" for want of the
      prefix.
- [x] `"sh", "-lc"` still occurs exactly once in the file (R4: one
      repetition, not two — the second subprocess was the wallpaper pipeline,
      refused by open decision 5(a)), and the four seeded directories each
      occur exactly twice: once in this block, once in that one line.
- [x] `env HOME=<scratch> wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with no `Configuration Error` and no `not a valid Config field` on
      stderr.
- [x] `bash tests/wezterm-appearance.sh`,
      `bash tests/wezterm-startup-layout.sh`,
      `bash tests/wezterm-f5-tab-select.sh`, `bash tests/wezterm-copy-mode.sh`,
      `bash tests/wezterm-tab-content-state.sh` and
      `bash tests/wezterm-grid-centering.sh` all stay green — the block
      disturbs no sibling invariant.
- [x] The edit to `wezterm.lua` is one contiguous insertion plus the two
      comment repairs and nothing else, proved by reconstruction rather than
      by `git diff --stat`: strip the inserted range back out, re-apply it to
      the remainder, and `cmp` against the file on disk.
      `git diff --stat` cannot prove this here — the working tree carries
      several lanes' uncommitted work and `gates/lib.sh` says so in as many
      words.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d /tmp/t7.XXXXXX)"

env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/e" && echo load-ok; head -3 "$H/e"

# the resolved values, read out of the config_builder table
cat > "$H/p.lua" <<'LUA'
local cfg = dofile(os.getenv("SRC"))
local f = io.open(os.getenv("OUT"), "w")
f:write("default_prog\t" .. table.concat(cfg.default_prog, " | ") .. "\n")
for k, v in pairs(cfg.set_environment_variables) do
  f:write("sev." .. k .. "\t" .. tostring(v) .. "\n")
end
f:close()
return {}
LUA
env -i HOME="$H" PATH=/usr/bin:/bin SRC="$PWD/$SRC" OUT="$H/o.tsv" \
  wezterm --config-file "$H/p.lua" ls-fonts --list-system >/dev/null 2>&1
cat "$H/o.tsv"

/usr/bin/grep -c '"sh", "-lc"' "$SRC"                      # expect 1
/usr/bin/grep -c '/opt/homebrew/sbin' "$SRC"               # expect 2
/usr/bin/grep -c 'Deliberately absent: default_prog' "$SRC" # expect 0
/usr/bin/grep -B1 'set_environment_variables\.PATH' "$SRC" | head -2

for g in appearance startup-layout f5-tab-select copy-mode \
         tab-content-state grid-centering; do
  bash "tests/wezterm-$g.sh" | tail -1
done
rm -rf "$H"
```

## Implemented 2026-08-23

Two notes the boxes above need, because each one is a place a later reader
would otherwise measure something different.

**The four-directory count is over CODE, not over the whole file.** The
`exactly twice` box was ticked against the file with full-line Lua comments
stripped, which is what its own reason asks for ("once in this block, once in
that one line" — both code). It cannot hold over the whole file: this spec's
own block comment quotes `env.nu`'s `prepend` order and the repaired PATH, and
the F6 comment repair this spec mandates quotes the `path_helper` measurement
— both name the directories in prose, as this repo's carry-the-reason
convention requires. Measured on the finished file: 5 / 3 / 5 / 6 raw hits,
2 / 2 / 2 / 2 in code. The negative control survives intact — before the block
landed the CODE count was 1 each, the F6 line alone.
`tests/wezterm-launchd-path.sh` says the same thing in its header.

**The Verify snippet's probe cannot resolve `wezterm`.** It runs
`env -i … PATH=/usr/bin:/bin … wezterm --config-file …`, and `wezterm` lives
in `/opt/homebrew/bin` — the very fact this node exists for. It fails as
`env: wezterm: No such file or directory` and writes no result file. The
absolute path is what was run, and the gate's `--config` stage uses
`"$WEZTERM"` throughout.

**The reconstruction proof.** `git diff --stat` cannot prove this here, so the
edit was reconstructed instead: the block was sliced back out between its
banner and the `end` closing the `is_mac` branch, re-applied to the remainder,
and `cmp`'d against the file on disk — identical. Diffed against the staged
copy (`git show :home/dot_config/wezterm/wezterm.lua`) the whole edit is three
hunks and no more: `6,9c6,9` (the header repair), `20a21,82` (the one
contiguous insertion, 62 lines), `1027,1029c1089,1110` (the F6 comment
repair).
