# probe notes — 07-multiplexer/01-session-and-windows

Pass one. Host: macOS 25.2, tmux 3.7c (/opt/homebrew/bin/tmux), nu 0.114.1.
Every finding below was MEASURED on this host, not read from a man page.

## Environment

- `tmux -V` → 3.7c. `tmux-256color` AND `screen-256color` terminfo both
  present locally (`infocmp` exits 0 for each), so the fallback branch has to
  be forced with `false` to be exercised here.
- No `home/dot_config/tmux/` existed before this run. This node creates it.
- tmux appears nowhere in `install.sh`'s `PKGS`. It IS in the capsule
  `Dockerfile` apt list and `tests/dev-image.sh`'s `PATH_TOOLS`. See findings.

## F1 — `if-shell` in a config file is synchronous

`if-shell 'infocmp tmux-256color …' 'set -g default-terminal "tmux-256color"'
'set -g default-terminal "screen-256color"'` in a `-f` conf, then
`new-session -d` on the same command line: `show -g default-terminal` reads
`tmux-256color`. Replacing the test with `false` reads `screen-256color`.
The branch is taken BEFORE the command-line `new-session` runs, so this is
safe to write as a parse-time conditional. No `-b` (that would land late).

## F2 — option scopes on 3.7c, and `-g` resolves them

`show -s` (server): `default-terminal`, `escape-time` (default already **10**,
not 500), `focus-events` (default **off**), `terminal-overrides`,
`terminal-features`.
`show -gw` (window): `allow-passthrough` (default **off**), `pane-base-index`,
`automatic-rename`.
`show -g` (session): `base-index`, `renumber-windows` (default off),
`default-command` (empty), `default-shell` (`/bin/zsh` here),
`history-limit` (2000), `update-environment` (13 entries incl.
`SSH_AUTH_SOCK`; **no `XDG_CONFIG_HOME`**).

Measured: writing `set -g <opt>` for a server- or window-scoped option WORKS —
tmux resolves the scope from the name. A conf with `set -g focus-events on`
and `set -g allow-passthrough on` loads rc=0 and both read back set.

## F3 — `new-window` inherits the SESSION path, not the active pane's

Session created in `$D/sess`; pane 0 `cd`'d to `$D/elsewhere`
(`#{pane_current_path}` confirms). `tmux new-window` with no `-c` →
`#{pane_current_path}` = `$D/sess`, i.e. `#{session_path}`.

This is what makes Q14 ("a lazily created window starts at `~`") a property of
**how the session is created**, not of the conf: a bare `new-window` lands at
the session path. So the entry point must pass `-c "$HOME"`. `tmux.conf`
alone cannot deliver Q14 — there is no `default-path` option in tmux ≥1.9.

## F4 — `renumber-windows off` (the default) really is the stable-address floor

Created windows 1 and 4, added 2, killed 2 → `list-windows` still reads
`1:` and `4:`. Indices do not slide. This is the line that retires the
~320-line WezTerm `reconcile_tabs` ledger; stated explicitly in the conf
because the whole addressing scheme depends on it.

## F5 — `new-session -A -s main` is idempotent

Second `new-session -A -s main -d` against a live session: `list-sessions`
still shows exactly one `main`. Without `-d` in a non-tty it prints
`open terminal failed: not a terminal` and still exits having done nothing
harmful — headless gates must pass `-d`.

## F6 — `\E` in `terminal-overrides`: both quotings store the same bytes

`set -as terminal-overrides ",*:Smulx=\\E[…"` (double, tmux collapses `\\`→`\`)
and `set -as terminal-overrides ',*:Smulx=\E[…'` (single, no processing) read
back BYTE-IDENTICAL from `show -s terminal-overrides`. `show` re-escapes for
display, so the `\\E` you see in its output is the correct `\E` stored. The
conf uses the single-quote idiom. A gate must not assert on the raw file text
alone — assert on the loaded value.

## F7 — the built conf loads clean and every option lands

`tmux -L real -f home/dot_config/tmux/tmux.conf new-session -d -s main -c ~`
→ rc 0, no diagnostics. Read back:
`default-terminal tmux-256color`, `escape-time 10`, `focus-events on`,
`terminal-features[3] *:RGB`, `terminal-overrides[1..2]` Smulx + Setulc,
`base-index 1`, `pane-base-index 1`, `renumber-windows off`,
`allow-passthrough on`, `update-environment[13] XDG_CONFIG_HOME`,
`#{session_path}` = `/Users/feb`, `#{window_index}`/`#{pane_index}` = 1/1.

`#{pane_current_command}` reads **`nu`** — the `exec` in both arms of
`default-command` is what makes that true, and 03-status-bar's occupied/empty
tint is a format over exactly that value, so the `exec` is load-bearing for a
sibling node rather than a micro-optimisation.

## F8 — the XDG_CONFIG_HOME export in `default-command` works

Inside a pane spawned by the conf: `$env.XDG_CONFIG_HOME` = `/Users/feb/.config`
and `$nu.history-path` = `/Users/feb/.config/nushell/history.sqlite3`.
Without the export nushell resolves `$nu.default-config-dir` to
`~/Library/Application Support/nushell` (02-terminal/06-launchd-path measured
that on 0.114.1) and reedline writes history OUTSIDE the managed tree. WezTerm
supplied this through `set_environment_variables`; under tmux the pane is
spawned by the SERVER, so it has to come from the conf.

## F9 — the `screen-256color` fallback works end to end

With `infocmp` off PATH (`env PATH=<stub with sh, nu, tmux only>`), the real
conf loads rc 0, `show -s default-terminal` reads `screen-256color`, and a
pane's `$env.TERM` reads `screen-256color`. Both arms of the if-shell are
exercised, which is what makes the portability claim provable rather than
asserted.

## F10 — the `default-command` fallback arm works

With `nu` off PATH, the pane is alive (`#{pane_dead}` 0), runs
`${SHELL:-/bin/sh}`, and accepts input (`echo FALLBACK_OK` came back).
`#{pane_current_command}` reads `bash` there, because `/bin/sh` on macOS IS
bash in sh mode — a gate must not assert `sh` for that arm.

## F11 — the launcher, and the one thing a headless gate cannot do

`home/dot_local/bin/executable_tmux-main` → `~/.local/bin/tmux-main`
(`~/.local/bin` is on PATH; env.nu prepends it). `sh -n` clean.
First run creates `main` with `#{session_path}` = `/Users/feb`. Second run
prints `open terminal failed: not a terminal` — because with `-A` against an
EXISTING session tmux behaves like `attach-session`, and an attach needs a
tty. So a headless gate can prove the CREATE path directly and must drive the
ATTACH path through a pty (`script -q /dev/null …`) or assert the exec line
textually. The session count stays 1 either way, which is the property that
matters.

The no-tmux arm prints two lines naming tmux as a hard dependency and execs
nu (or `$SHELL`). It repeats tmux.conf's XDG_CONFIG_HOME export deliberately:
that arm runs when tmux.conf never gets read at all.

## F12 — cleanup discipline for gates

`sh tmux-main` with no `-L` touches the user's DEFAULT tmux socket. Every gate
must pass `-L <label>` and `kill-server` it. The one run that leaked a `main`
session on the default socket during this probe was killed.

## F13 — chezmoi target paths, proven in isolation

`chezmoi source-path` (run, not assumed) reads `/Users/feb/dev/.files/home` —
still the pre-cutover repo, per AGENTS.md. Untouched by this probe: the live
`~/.config/chezmoi/chezmoi.toml` sha256 and `source-path` are identical before
and after.

An isolated apply (copy of `home/` as `--source`, scratch `--destination`,
scratch `--config`/`--persistent-state`/`--cache`, and `HOME` pinned to the
destination — the `cz()` discipline from tests/deploy-skeleton.sh) deploys:

    home/dot_config/tmux/tmux.conf            -> ~/.config/tmux/tmux.conf
    home/dot_local/bin/executable_tmux-main   -> ~/.local/bin/tmux-main  (0755)

`~/.config/tmux/tmux.conf` is the path tmux reads with no `-f` (tmux >= 3.1),
and `~/.config/tmux/colors.conf` — 04-palette-delivery's file — is its sibling.
Two probe-only wrinkles, neither a defect: chezmoi's target arguments must be
ABSOLUTE destination paths (a repo-relative source path is rejected as "not in
destination directory"), and the destination's `.config` and `.local/bin` must
already exist or the apply fails with `mkdir … no such file or directory`.

## Findings for the report (defects and gaps OUTSIDE this node's scope)

- **tmux is in no package list.** `install.sh`'s `PKGS` has no `tmux=tmux`.
  It appears only in `home/dot_config/capsule/Dockerfile`'s apt list and
  `tests/dev-image.sh`'s `PATH_TOOLS` — i.e. inside the container, never on
  the host. The epic states tmux is now a hard dependency; the host install
  is `05-platform/02-package-provisioning`'s footprint, not this node's.
  `tmux-main`'s no-tmux arm makes the absence survivable, not correct.
- **`gates/waves.tsv` cannot register this node's gate.** Rows are keyed by
  `task:` ids read from each node's frontmatter, and no node in
  `07-multiplexer` carries a `task:`. Registering `tests/tmux-session-and-
  windows.sh` needs a wave row and a task id that the delivery epic owns.
  The gate runs standalone in the meantime.
- **`escape-time`'s default is already 10 on tmux 3.7c**, not the 500 that
  the reason-for-the-line usually cites. The line is still correct for the
  older tmux a minimal host ships, but any document claiming tmux defaults to
  500 is describing tmux < 3.4.
- Not re-checked, filed by the epic already:
  `prds/02-terminal/04-copy-mode/prd.md` is `state: done` with every
  requirement box `- [ ]`.

## Verdict

SPECCED. specs/spec01 (conf), spec02 (launcher), spec03 (gate).
spec01 and spec02 are BUILT and measured; spec03 is unwritten.

## F14 — CORRECTS F3. `new-window`'s default cwd depends on WHO ran it

F3 said "`new-window` inherits the session path". That was measured on a
fixture where the client cwd and the session path were the same directory, so
it could not tell them apart — the exact "run a cheap claim twice with a
different input" failure AGENTS.md warns about. Re-measured with all three
directories distinct (session `$HOME`, pane `/private/tmp`, client
`~/dev/dotfiles`):

| how `new-window` was run | resulting cwd | which directory that is |
|---|---|---|
| `tmux new-window` typed in a pane | `/private/tmp` | the PANE's cwd |
| `tmux new-window` from a shell outside tmux | `~/dev/dotfiles` | the CLIENT's cwd |
| `run-shell -t <pane> 'tmux new-window'` | `~/dev/dotfiles` | the SERVER's cwd |
| **a real key binding** (`bind -n F1 new-window`) | **`$HOME`** | **the SESSION's path** |

The fourth row is the one that matters and it is the only one a person ever
triggers: `F5 <digit>` is a key binding. It was measured by nesting — an outer
tmux on socket `outer` whose pane runs `tmux -L k attach`, so `send-keys` to
the outer pane delivers a real keystroke into the inner tmux's key dispatch.
`send-keys` alone cannot test a binding: it writes to the pane's pty, which
the shell reads, never tmux.

**So Q14 does hold, and `-c "$HOME"` at session creation is its mechanism** —
but the acceptance must say "via a key binding", not "a bare new-window", or
it asserts something that is false three ways out of four. 02-key-tables' own
`-c ~` on the digit binding remains correct as belt-and-braces for a session
someone else created.

## F15 — the nesting fixture, re-measured by the implementer (pass two)

Built as the `--session` stage's fixture and run before writing it, with all
three directories distinct (`$D/sess`, `$D/pane`, `$D/client`):

    inner: tmux -L in -f <conf> new-session -d -s main -c $D/sess
           tmux -L in bind-key -n F1 new-window
           tmux -L in new-window -c $D/pane        # active pane elsewhere
    outer: cd $D/client
           tmux -L out new-session -d -s outer -c $D/client "tmux -L in attach"
           tmux -L out send-keys -t outer F1

    inner list-windows -F '#{window_index} #{pane_current_path}'
      1  …/sess      2  …/pane      3  …/sess     ← 3 is the F1 one

F14 reproduces exactly: the key-binding window lands on the SESSION path
while the active pane sits in another directory and the client in a third.

**One trap the fixture must handle**: `#{session_path}` prints the UNRESOLVED
path (`/var/folders/…`) and `#{pane_current_path}` the resolved one
(`/private/var/folders/…`). Comparing the two raw strings fails on a
symlinked TMPDIR, which macOS always has. Every fixture directory is
normalised with `cd … && pwd -P` before it is compared.

Killing the servers: kill the OUTER first. Killing the inner ends the attach,
the outer window closes, the outer server exits on its own, and a later
`kill-server` on it prints `no server running` and returns 1.

## F16 — tmux 3.7c's DEFAULT `default-terminal` is already `tmux-256color`

Measured while writing the gate's `--selftest`, because the obvious mutation
for the TERM floor — delete the `if-shell` — produced no red:

    tmux -L x -f /dev/null new-session -d ; tmux -L x show -sv default-terminal
      → tmux-256color

So a conf with the conditional removed still reads the value `--load`
asserts, and "the if-shell is deleted" is NOT a falsifying mutation. F1 is
not wrong — it measured a `false` CONDITION, which does give
`screen-256color` — it simply says nothing about the built-in default, and
the two were conflated.

The discriminating mutation, and the one the gate now runs, is the failure
the conditional exists to prevent: collapse the `if-shell` to an
unconditional `set -g default-terminal "tmux-256color"` and run it on the
stub PATH with no `infocmp`. The real conf falls back to `screen-256color`
there; the hardcoded one reads `tmux-256color`, and on a host that genuinely
lacks the terminfo entry tmux refuses to create the session at all. One
mutation, red for both of `--fallback A`'s checks.

Same family, second instance, same run: `$GREP -q -- '-c "$HOME"'` against
the MUTATED launcher passed, because the launcher's header explains
`-c "$HOME"` in prose and the grep resolved the COMMENT — the silent-defusal
shape `gates/lib.sh`'s `line_of_code` exists for, in the passing direction.
Both structural greps in the gate now strip comment lines first.

## F17 — `script -q /dev/null` and stdin, both arrangements measured

The pty attach in `--session` needs a tty and a stdin that is neither the
gate's own nor an immediate EOF:

- `< /dev/null` — `script` reads EOF at once and forwards a literal `^D` into
  the pty. The client passes it to the pane's shell, the shell exits, the
  window closes and the SERVER exits with it. The stage read 0 clients and 0
  sessions and blamed the attach, which had worked: the same captured log
  holds tmux's alternate screen and a live `feb@mac ~ %` prompt before the
  exit.
- a fifo held open by a sleeping writer — the natural fix, and macOS `script`
  REFUSES it: `script: tcgetattr/ioctl: Operation not supported on socket`.
  The run never starts.

So stdin stays `/dev/null` and the `^D` is absorbed instead:
`set -g remain-on-exit on` on the session keeps the window when its shell
exits, leaving the session and the attached client alive for the assertion.
What is under test is the ATTACH, not the pane's shell.

## F18 — a `$( )` in a `chk` LABEL beside a bare `$?` is a guaranteed false PASS

Found while shellcheck-reading the finished gate (SC2319), then measured
directly:

    false; chk "label $(printf ok)" $?           → PASS
    false; st=$?; chk "label $(printf ok)" "$st" → FAIL

Argument-list expansions run left to right, so the substitution in the label
EXECUTES FIRST and its own exit status overwrites the one `$?` was meant to
carry. `gates/lib.sh` warns about the idiom in prose — "that idiom loses the
status the moment anything (a command substitution in the label, say) runs
between the two, and it has already produced a false PASS in this repo" — and
seven checks in the first draft of this gate were written that way, including
the Q14 assertion, the one the whole node turns on. All seven now take
`st=$?` first, and `status_lint` in the gate is the same warning with teeth,
proved by a planted counterfactual under `--selftest`.

The Q14 check was passing for the right reason: it stayed PASS after the fix,
and its `--selftest` red still goes red. But it was unfalsifiable until then.

## F19 — registering the gate is still blocked, and the meta-gate is already red

Re-measured 2026-08-29, since the earlier finding named only the mechanism.

`bash gates/wave-status.sh --validate` fails on
`registry: every script under tests/ is named by a row`, listing
`capsule-recents-gui.sh nvim-session.sh tmux-session-and-windows.sh`. The
FIRST of those is TRACKED at HEAD (`git ls-files` lists it) and appears zero
times in `gates/waves.tsv`, so the check was red before this node's gate
existed. This gate joins the list; it does not create it.

It cannot leave the list from inside this node. A row in `gates/waves.tsv` is
keyed by a `task:` id read from a node's frontmatter, no node in
`07-multiplexer` carries one, and both the frontmatter and `gates/waves.tsv`
are outside this node's footprint. So the gate runs standalone, and the box
for `bash gates/selftest.sh` exits 0 stays OPEN — honestly, with the reason.

Two other `gates/selftest.sh` failures, neither caused by this node:

- `tree-links.sh --selftest` — one broken link, and it is in another node's
  spec: `prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/
  spec03.md:182 -> ../g1-verify-still-red-on-just-gates/prd.md`. Every link
  in this node's own specs resolves.
- `manual-coverage.sh --selftest` — `boxes: no checklist box is ticked in the
  repo (ticked: wave4.md wave6.md)`. `gates/manual/` is untouched here.
- `retired-phrases.sh --selftest` — and this one is worth the epic's
  attention. The carrier is **this epic's own governing memo**:

      FAIL  RP7 CARRIER prds/memos/tmux-owns-multiplexing-wezterm-keeps-
            the-chrome.md carries `the terminal owns the palette` — retired
            by 00-delivery/decisions/tinty (done). Not exempt.

  The phrase was retired because it has the direction backwards: tinty owns
  the palette and the terminal is its first reader. The memo is uncommitted
  and the implementer brief forbids editing or committing it, so it is
  reported, not fixed. Either the memo drops the phrase or the allow-list
  gains the pair — both are somebody else's footprint.

A fourth, seen once and NOT real: `wezterm-config-fields.sh wrote nothing
outside its scratch` failed naming `tests/tmux-session-and-windows.sh`. That
was this implementer editing the gate while the sweep ran — the "run the
sweep on a QUIET board" case `gates/selftest.sh`'s own header documents. It
did not reproduce on the quiet re-run.

<!--
retired-phrase-mention: RP7 — probe notes recording the red this session hit.
-->
