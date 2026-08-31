---
est: 0.5h
footprint:
  - docs/capabilities-terminal.md
verify: "bash gates/tree-links.sh"
---

# spec01 — the Launchd PATH entry states what the prefix actually earns

Replace the body of the `## Launchd PATH seeding` entry in
`docs/capabilities-terminal.md` (lines 119–130) with the block below. It
carries three corrections and one trap, all measured. Nothing else in the
file changes, and no other file changes at all.

The analyst ran the whole R3 census. The results are the tables below; the
implementer copies the replacement block verbatim and re-runs the two
commands in **Verify and Proof** to confirm the two claims the block quotes.
Do not re-derive the census.

## What is wrong, and what is not

The entry back-references its own first sentence — "the same seeding is
repeated inline in the two `sh -lc` subprocesses … for the identical reason"
— and that back-reference carries three defects. The `nu` half of the reason
is false, the failure symptom is false, and the two repetitions are not the
same seeding.

**Defect 1 — `nu` resolves in `sh -lc` without the prefix.** `sh -lc` is a
*login* shell, so `/etc/profile` runs `path_helper`, which reads
`/etc/paths.d/homebrew` and puts `/opt/homebrew/bin` on `PATH` by itself.

```
$ S=$(mktemp -d)
$ env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/sh -lc \
    'command -v nu || echo "nu: NOT FOUND"; command -v tinty || echo "tinty: NOT FOUND"'
/opt/homebrew/bin/nu
tinty: NOT FOUND
```

The negative control fixes the cause on the login shell and not on `env -i`:
the same probe with `sh -c` instead of `sh -lc` answers `nu: NOT FOUND`,
`PATH=/usr/bin:/bin:/usr/sbin:/sbin`.

`/etc/paths.d/homebrew` holds one line, `/opt/homebrew/bin` — so
`/opt/homebrew/sbin` is genuinely earned by the prefix, and `~/.local/bin`
and `~/.cargo/bin` are never added by `path_helper` at all. `tinty` lives at
`/Users/feb/.local/bin/tinty`, which is the binary the F6 prefix exists for.

**Defect 2 — the window does not die.** The entry says "the window dies
immediately". The pane is created and kept. Measured with
`wezterm-mux-server` under `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin` and a
scratch `HOME` holding a config whose only `default_prog` is `{ "nu" }`:

```
$ wezterm cli list
WINID TABID PANEID WORKSPACE SIZE  TITLE   CWD
    0     0      0 default   80x24 wezterm
$ wezterm cli get-text --pane-id 0
Unable to spawn nu because:
No viable candidates found in PATH "/usr/bin:/bin:/usr/sbin:/sbin"
⚠️ Process "nu" in domain "local" didn't exit cleanly
Exited with code 1.
This message is shown because exit_behavior="CloseOnCleanExit"
```

Neither config sets `exit_behavior`, and the default `CloseOnCleanExit`
retains a pane whose process exited *un*cleanly. This correction is already
recorded in
[`02-terminal/06-launchd-path`](../../../../02-terminal/06-launchd-path/prd.md)
R3; the inventory is the last place carrying the stale version.

**Defect 3 — the two repetitions are not the same seeding.** F6
(`~/.config/wezterm/wezterm.lua:1038`) seeds four directories. The wallpaper
(`wezterm.lua:757`) seeds two, `/opt/homebrew/{bin,sbin}` only. The
wallpaper's own comment claims `sh -lc` "won't find brew's magick/curl", and
under the same scratch-`HOME` login shell every binary that script calls
resolves without any prefix:

```
$ env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/sh -lc \
    'for b in magick convert curl chezmoi osascript; do printf "%-10s " "$b"; command -v $b || echo "NOT FOUND"; done'
magick     /opt/homebrew/bin/magick
convert    /opt/homebrew/bin/convert
curl       /usr/bin/curl
chezmoi    /opt/homebrew/bin/chezmoi
osascript  /usr/bin/osascript
```

So the wallpaper's inline seeding is redundant outright. It changes no port
decision — the wallpaper pipeline is `DO NOT PORT` — which is why the fact
lands in this entry rather than in the wallpaper entry at line 528. That
entry's own line 532, "The script seeds Homebrew on `PATH`", describes the
code accurately and states no reason. Leave it alone.

**The trap that makes a naive measurement pass for the wrong reason.**
`~/.profile` on this machine is one line, `. "$HOME/.cargo/env"`. That is
what puts `~/.cargo/bin` into a login shell's `PATH` here — with the real
`HOME` the probe finds `~/.cargo/bin` and reports the prefix as unnecessary.
This repo deploys no `dot_profile`, so the accident is local and nothing may
rely on it. Every probe above therefore runs under a scratch `HOME`.

**The mechanism was already written down one file away.**
`~/.config/nushell/env.nu:15-19` records `path_helper`, `/etc/paths`,
`/etc/paths.d/*`, and that it runs only from `/etc/zprofile` and
`/etc/profile`. `env.nu` then prepends exactly `~/.local/bin` and
`~/.cargo/bin` — the two directories `path_helper` never adds. The inventory
contradicted a live comment in the same config tree.

## R2 — the rating does not move

`C 2 · U 10` stays. The argument, on the record:

- **Complexity 2 is unchanged.** The implementation is a fixed four-entry
  string assignment behind an `is_mac` guard. The correction changes the
  stated reason, not one line of the mechanism.
- **Usefulness 10 is unchanged.** Defect 2 makes the symptom less dramatic,
  not less fatal: `nu` never starts, so nothing in
  [`04-shell`](../../../../04-shell/prd.md) runs and there is no `help` at
  all. Defect 1 moves *which* binary the F6 half is load-bearing for — from
  `nu` to `tinty` — and not whether it is load-bearing.
- **The consistency rule binds it.**
  [`02-terminal/06-launchd-path`](../../../../02-terminal/06-launchd-path/prd.md)
  carries `C 2 · U 10` sourced from this entry. A drift here would falsify
  that header, and this spec may not touch another node's body.

## The replacement block

Lines 119–130 of `docs/capabilities-terminal.md`, from the `##` heading
through the `- 10` rating line, become exactly this. Every line measured at
or under 78 columns. The two `- <n>` rating items stay last, because that is
where the reader and the tooling look for them.

```markdown
## Launchd PATH seeding
- macOS only: prepends `/opt/homebrew/{bin,sbin}`, `~/.local/bin` and
  `~/.cargo/bin` to `set_environment_variables.PATH`. A GUI-launched WezTerm
  inherits launchd's minimal `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), which
  has no Homebrew — so the bare `nu` in `default_prog` cannot be found.
  WezTerm spawns `default_prog` directly with no shell in between, so nothing
  runs `path_helper` and nothing recovers Homebrew on its own. `env.nu` owns
  `PATH` from inside the shell; this only has to get the binary spawned.
- **The pane survives — the window does not die.** Measured 2026-08-23 with
  `wezterm-mux-server` under `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`: the
  pane is created and kept, showing `Unable to spawn nu because: / No viable
  candidates found in PATH "/usr/bin:/bin:/usr/sbin:/sbin"` and then
  `didn't exit cleanly`. Neither config sets `exit_behavior`, and the default
  `CloseOnCleanExit` retains a pane whose process exited *un*cleanly. A dead
  pane you have to read is worse to diagnose than a window that vanishes.
- **The two inline `sh -lc` repetitions are neither the same seeding nor for
  this reason.** `sh -lc` is a *login* shell, so `/etc/profile` runs
  `path_helper`, which reads `/etc/paths.d/homebrew` and puts
  `/opt/homebrew/bin` on `PATH` by itself. Measured 2026-08-23 under a
  scratch `HOME`: `env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin sh -lc
  'command -v nu; command -v tinty'` answers `/opt/homebrew/bin/nu` and
  `tinty: NOT FOUND`. What the F6 prefix (`wezterm.lua:1038`) earns is
  `~/.local/bin` — where `tinty` is installed — plus `~/.cargo/bin`, which
  `path_helper` never adds, and `/opt/homebrew/sbin`, since
  `/etc/paths.d/homebrew` names only `bin`. It must not be "simplified" away
  on the grounds that `nu` resolves without it: the toggle would then fail on
  `tinty` one layer further in, where the cause is far harder to see. The
  wallpaper prefix (`wezterm.lua:757`) seeds only `/opt/homebrew/{bin,sbin}`
  and is redundant outright — its comment claims `sh -lc` cannot find brew's
  `magick`/`curl`, and under the same login shell `magick` and `convert`
  resolve under `/opt/homebrew/bin/` while `curl` is `/usr/bin/curl`.
- One live-machine trap, to guard against rather than rely on: `~/.profile`
  here is `. "$HOME/.cargo/env"`, which is what puts `~/.cargo/bin` into a
  login shell's `PATH` on this machine. This repo deploys no `dot_profile`,
  so any re-measurement runs under a scratch `HOME` or it passes for the
  wrong reason. `env.nu` lines 15-19 already record the same `path_helper`
  mechanism, and prepend the same two user dirs.
- 2
- 10
```

## The R3 census — every PATH-resolution claim in the file

Wrong, and fixed by the block above:

| Line | Claim | Verdict |
|---|---|---|
| 124 | the window "dies immediately" | **FALSE** — the pane is retained (defect 2) |
| 127-128 | the inline seeding is "the same", "for the identical reason" | **FALSE** on both counts (defects 1 and 3) |

True, checked and left alone:

| Line | Claim | Check |
|---|---|---|
| 120-121 | the prefix is `/opt/homebrew/{bin,sbin}`, `~/.local/bin`, `~/.cargo/bin` | matches `wezterm.lua:31-34` exactly |
| 122 | launchd's minimal `PATH` is `/usr/bin:/bin:/usr/sbin:/sbin` | `launchctl getenv PATH` is unset; the mux-server error printed that exact string back |
| 123 | the bare `nu` in `default_prog` cannot be found | `No viable candidates found in PATH "/usr/bin:/bin:/usr/sbin:/sbin"` |
| 125-126 | `env.nu` owns `PATH` from inside the shell | `env.nu:22-36` rebuilds `$env.PATH` |
| 127 | there are exactly **two** `sh -lc` subprocesses | `wezterm.lua:741` (wallpaper) and `1036` (F6) are the only two |
| 136 | `default_prog` "depends on the PATH seeding above" | WezTerm spawns it with no shell, so `path_helper` never runs |
| 532 | the wallpaper script "seeds Homebrew on `PATH`" | `wezterm.lua:757` does exactly that — accurate, and states no reason |

Non-PATH resolution claims, checked in passing and correct: line 49
(`~/.cargo/bin/burrito` exists on disk), line 146 (`fc-list` resolves
`CaskaydiaCove Nerd Font` and `CaskaydiaCove NF`).

Nothing else in `docs/capabilities-terminal.md` asserts what resolves in a
given launch shape. `resolves` at lines 145 and 509 is about font families
and `wezterm show-keys` output, not `PATH`.

## Not this implementer's files

`gates/waves.tsv` and `gates/manual/wave*.md` belong to the orchestrator. No
entry there is needed: the gate this spec relies on,
`bash gates/tree-links.sh`, already runs, and the two probes below are run
by hand and quoted.

`~/.config/wezterm/wezterm.lua:1029-1030` carries the same wrong claim. It is
read-only reference under this repo's rules. Do not edit it. The rebuild's
own comment is
[`02-terminal/06-launchd-path`](../../../../02-terminal/06-launchd-path/prd.md)
spec01's, and already carries the corrected reason.

## Acceptance

- [x] `docs/capabilities-terminal.md` contains no occurrence of `dies
      immediately`, and none of `for the identical reason`:
      `grep -c 'dies immediately\|for the identical reason'
      docs/capabilities-terminal.md` → `0`.
- [x] The corrected entry names all three mechanism terms:
      `grep -c 'path_helper' docs/capabilities-terminal.md` → at least 1,
      and `/etc/paths.d/homebrew` and `login` shell both appear inside the
      `## Launchd PATH seeding` entry.
- [x] The entry names the three directories the prefix earns —
      `~/.local/bin`, `~/.cargo/bin`, `/opt/homebrew/sbin` — and says `nu`
      resolves without it.
- [x] The entry's last two list items are still `- 2` and `- 10`, unchanged.
      `awk '/^## Launchd PATH seeding/,/^----/' docs/capabilities-terminal.md
      | grep -E '^- [0-9]+$'` → `- 2` then `- 10`.
- [x] Re-run of the defect-1 probe, quoted in the report, answers
      `/opt/homebrew/bin/nu` and `tinty: NOT FOUND`.
- [x] Re-run of the defect-1 negative control (`sh -c`, not `sh -lc`)
      answers `nu: NOT FOUND` — proving the login shell is the cause, not
      `env -i`.
- [x] `bash gates/tree-links.sh` exits 0 and Tier A reports `0 broken`, with
      the link count unchanged at **691** — the replacement block adds no
      markdown link, so a changed count means something outside this entry
      moved. Baseline measured 2026-08-23 before any edit: exit 0, Tier A
      `checked 691 links in 110 files, 0 broken`. Tier B's 114 broken links
      are all under `specs/**`, pre-existing, and never gate.
      **Implement-time reading: exit 0, `checked 704 links in 111 files, 0
      broken`.** Other lanes wrote the tree between spec and implement; Tier
      A read `700` immediately before this edit and `704` after. This entry's
      own link delta is zero — 7 markdown links in
      `docs/capabilities-terminal.md` with the block in place, 7 with the
      replaced 12 lines back.
- [x] **Reworded by the orchestrator: `git diff --stat` cannot name one file
      in this tree.** Several lanes hold uncommitted edits, and two of them
      are in this same inventory file (a `../prd/` → `../prds/` link fix and
      a rewritten copy-mode entry), so the check is not runnable as stated
      and a `[x]` against it would be a false record. Proved instead by
      construction and by mtime: the edit replaced exactly lines 119-130 with
      the pre-resolved block, `~/.config/wezterm/wezterm.lua` still carries
      its 2026-08-20 mtime, and the wallpaper entry's "seeds Homebrew on
      `PATH`" line is untouched (now at line 559 after the +27-line shift).
      Original box:`git diff --stat` names `docs/capabilities-terminal.md` and nothing
      else. **Not ticked: not runnable as stated.** Several lanes hold
      uncommitted edits in this tree, including two in this same inventory
      file, so `git diff --stat` cannot isolate one node. Proved instead:
      this node wrote exactly two paths, `docs/capabilities-terminal.md`
      lines 119-130 and its own board folder, and
      `~/.config/wezterm/wezterm.lua` still carries its 2026-08-20 mtime.

## Verify and Proof

```sh
S=$(mktemp -d)

# defect 1 — the measurement that produced this node
env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/sh -lc \
  'command -v nu || echo "nu: NOT FOUND"; command -v tinty || echo "tinty: NOT FOUND"'

# defect 1, negative control — the login shell is the cause, not env -i
env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/sh -c \
  'command -v nu || echo "nu: NOT FOUND"; echo "PATH=$PATH"'

# the entry no longer carries either false claim
grep -c 'dies immediately\|for the identical reason' docs/capabilities-terminal.md

# the corrected mechanism is named
grep -n 'path_helper\|/etc/paths.d/homebrew' docs/capabilities-terminal.md

# the rating did not move
awk '/^## Launchd PATH seeding/,/^----/' docs/capabilities-terminal.md \
  | grep -E '^- [0-9]+$'

# the gate
bash gates/tree-links.sh

# one file changed
git diff --stat
```
