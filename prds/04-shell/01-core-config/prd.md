---
state: done
commit: c1c90d4
priority: 37
est: 9.75h
task: S.1
mode: afk
needs:
  - 05-platform/03-shell-init-generation
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/decisions/tinty
  - 06-help/01-content-model
verify: "bash tests/nushell-core.sh"
---

# Core config

Parent: [Nushell epic](../prd.md) · C 3 · U 9 · sources: "Core shell config"
(C 3 / U 9, dominant) + "Dirstack — directory recency" (C 3 / U 7), both in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

*Source list corrected 2026-08-21 from backlog row **M-6**: R7 and R8 are the
folded Dirstack entry, not Core shell config, and a merged PRD carries the
dominant entry's rating while listing every source with its own numbers. M-6's
other half — that the folded entry never got a table row — is moot: this
epic's `## Children` table was deliberately deleted, because membership is by
existence, so there is no table to add a row to.*

Purpose: The foundation every other feature assumes: a nushell that works as a
login shell on macOS, remembers where you were, and funnels all navigation
through one place.

## Requirements
- [x] **R1** — **PATH repair.** Nushell never runs macOS `path_helper`, so
      `env.nu` prepends `~/.local/bin` + `~/.cargo/bin` and appends homebrew +
      system dirs (with `uniq` so it's a no-op when the parent shell provided
      them).
- [x] **R2** — **Environment.** `EDITOR`/`VISUAL` = nvim, `SHELL` = nu,
      `XDG_CONFIG_HOME`, `RIPGREP_CONFIG_PATH` (shared ignore rules with fd).
      Three more that the live `env.nu` sets and no PRD covered:
  - [x] **`$env.ENV_CONVERSIONS` for `PATH` and `Path`.** A prerequisite of
        R1, not a decoration: this config overrides nushell's stock `env.nu`,
        which is where the string↔list conversion normally comes from, and
        without it `$env.PATH` is a plain string — so every `prepend`,
        `append` and `uniq` in R1 silently does the wrong thing.
  - [x] **`$env.STARSHIP_SHELL`.** starship is the prompt, sourced from the
        generated init of R9. R5 already rests on this — the
        phantom-blank-line workaround is specific to starship's *two-line*
        prompt — without the file ever saying so.
  - [x] **The `ollama-host` probe.** Runs `^ollama-host` through `complete`
        and sets `$env.OLLAMA_HOST` only on exit 0, guarded on
        `$nu.is-interactive` **and** on `which ollama-host` resolving,
        because `complete` does not catch a *missing* external. Record the
        cost with the capability: it is one external spawn on every
        interactive start, to be weighed against R9's zero-work startup.

        *Amended 2026-08-23 by the orchestrator, twice over.* This box said
        `is-terminal --stdout`, which the guard-deviation correction already
        retired in favour of `$nu.is-interactive` — see the note further
        down this file. The existence half is new:
        [`ollama-host-missing-binary`](../../00-delivery/corrections/ollama-host-missing-binary/prd.md)
        measured that without it, an absent binary raises
        `nu::shell::external_command` that **aborts the rest of `env.nu`**.
        Today's damage is only the message because the block happens to be
        last. The shell gates knew: six of them install a poison stub, and
        `tests/shell-listing.sh:301-303` says why in as many words — "a
        MISSING external inside its `do|complete` is a shell error that takes
        the config down, so the stub must exist". Nobody filed it.
- [x] **R3** — **Shell behavior.** No banner, emacs edit mode, `rm` → trash,
      fuzzy case-insensitive completions, binary filesize units — plus the
      four live config blocks no PRD covered: `cursor_shape` (a solid block
      in emacs mode; the **terminal** supplies the blink, so this node does
      not restate the terminal's own setting), `table` (rounded mode, auto
      index, header on separator), `history.sync_on_enter` (belongs beside
      R4's store settings — it is what makes R4's shared history arrive
      without opening a new shell), and `completions.external` (enabled, with
      `max_results: 100`), which is what makes external-command completion
      work at all.
- [x] **R4** — **History store.** Sqlite, 100k entries, `isolation: false` so
      all panes/sessions share one merged history (required by
      [05-history](../05-history/prd.md)).
- [x] **R5** — **Terminal integration.** OSC 133/633 off (phantom-blank-line
      fix with starship two-line prompt under WezTerm), OSC 7 on (cwd →
      WezTerm status). `use_kitty_protocol` stays off (leaks `^[[?0u` through
      the WezTerm pty).
- [x] **R6** — **`mkcd` funnel.** `cd` aliased to a wrapper that: passes `` /
      `-` through, offers to `mkdir` a non-existent target (single-key
      confirm), and records every successful move to `startdir.txt`. All
      navigation — zoxide, pickers, fallback — must reach the shell through
      this funnel or the PWD hook.
- [x] **R7** — **Start dir.** New interactive shells open in the last
      directory navigated to by any means (read from `startdir.txt`, fall back
      to `~/dev`); non-interactive `nu -c` keeps its caller's cwd.
- [x] **R8** — **Dirstack.** The PWD hook pushes every move onto `dirs.txt`
      (newest first, deduped, cap 100); the list drops dead paths on read. It
      feeds the **`recent-dirs`** tv channel and anything else that wants
      "recent dirs". Live bug **L-3**: the live decoder types `rcwd`, a name
      no cable file has ever had, so recent-dir picks were never decoded as
      paths — `rcwd` is the bug id, not a channel name. The decode itself
      belongs to [`04-television`](../04-television/prd.md) R2 and is not
      restated here.
- [x] **R9** — **Zero-work startup.** Generated integrations (starship, zoxide
      init, tv init) are produced at chezmoi-apply time and only sourced at
      launch.
- [x] **R10** — **Live palette re-assert.** An interactive shell re-asserts
      the active tinty scheme by sourcing tinty's cached tinted-shell artifact
      (`$XDG_DATA_HOME/tinted-theming/tinty/artifacts/tinted-shell-scripts-file.sh`,
      defaulting `XDG_DATA_HOME` to `~/.local/share`), falling back to
      `tinty init` only when that artifact does not exist yet. Constraints,
      each with its reason:
      **(a)** It is needed because WezTerm's own scheme is only the *base*
      palette — tinty persists the pick in `current_scheme` and tinted-shell
      delivers it as OSC sequences the terminal applies at runtime, and
      nothing re-emitted those at shell start, so every new terminal looked
      like plain gruvbox whatever had been applied.
      **(b)** Source the artifact, do not run `tinty init`: the artifact is
      the very file `init` sources, but `init` also spawns the tinty binary
      and its whole hook chain (~65 ms) for hooks that are no-ops on an
      unchanged scheme, against ~5 ms for one `bash` spawn — on every shell
      start. `init` survives only as the fresh-machine fallback.
      **(c)** Guard it on stdout being a terminal. The artifact writes its
      escapes to `$TTY` itself and no-ops when that is not a writable
      terminal, so this is already inert under `nu -c`; the guard is there to
      skip the spawn.
      **(d)** It is a no-op until something has been applied, so a machine
      that has never picked a scheme keeps the terminal's base scheme.
      **(e)** It runs *before* anything that defines the `theme` command, so
      the re-assert is what a new shell sees first.
      This is a deliberate exception to R9's "generated integrations are
      produced at chezmoi-apply time": the active scheme changes at runtime,
      so nothing generated at apply time can carry it.
- [~] **R11** — **`esc_clear`.** Escape closes an open menu when one is open
      and otherwise clears the line (an `edit: clear` event), bound in both
      `emacs` and `vi_insert`. It is a keybinding, so it owes a `help` manual
      entry in the same change:
      [`06-help/01`](../../06-help/01-content-model/prd.md) already lists
      `esc_clear` among the bindings it expects to find, so leaving it
      unspecified here is a gap on both sides.

## Acceptance
- [~] `chsh` to nu + GUI-launched WezTerm: `bat`, `rg`, `tv`, `starship` all
      resolve.
- [x] `cd some/new/nested/dir` + Enter creates and enters it after confirm.
- [x] Navigate anywhere by any means, open a new pane: it starts in that dir.
- [x] `nu -c 'pwd'` from another dir prints that dir, not the start dir.
- [~] `tinty apply base16-<some-other-scheme>`, then open a new pane: the new
      shell comes up in that scheme with no second apply, and an already-open
      pane is not left on the old one.
- [x] `nu -c 'print hi'` from a non-terminal stdout emits no escape sequence
      and spawns no `bash` for the artifact.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Decisions

**Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
verdict is withdrawn.** Recorded from
[`00-delivery/decisions/tinty`](../../00-delivery/decisions/tinty/prd.md);
the backlog's copy is open decision 2 of
[the corrections backlog](../../00-delivery/corrections/prd.md). R10 is what
that answer adds to this node — the re-assert was previously listed as an
uncovered live behaviour that would be orphaned if the theme surface was
dropped. The `theme` command itself is not this node's — it belongs to
[`04-shell/09-theme-switcher`](../09-theme-switcher/prd.md), which this node
only has to leave a working palette re-assert underneath.

**L-2 lands entirely in `04-television` (recorded 2026-08-21).** The backlog's
L-2 row names this node alongside
[`04-television`](../04-television/prd.md), but this PRD holds no git-log, no
decoder and no commit handling — the whole of the fix is `04-television` R2.
Recorded so the empty result reads as evidence that the row was checked here,
not as an oversight.

## Implementation record

Built 2026-08-21 by the S.1 implementer. Gate:
`bash tests/nushell-core.sh` — **147 PASS, 0 FAIL, EXIT=0**, three consecutive
full runs. Files created: `home/dot_config/nushell/env.nu`,
`home/dot_config/nushell/dirstack.nu`, `home/dot_config/nushell/config.nu`,
`tests/nushell-core.sh`.

**The interactivity guard is `$nu.is-interactive`, not `is-terminal --stdout`,
and the substitution is forced by measurement.** spec01 D4 and spec03 S3.13 /
S3.17 name `is-terminal --stdout`, on the strength of a measurement that only
tested the `nu -c` half. Measured here on nushell 0.114.1 under a real pty
allocated by `pty.fork` — where a `/bin/sh -c '[ -t 1 ]'` spawned from inside
nu answers **yes** — with the guard written exactly as the live config writes
it, inside an `if (…)` condition:

```
if (is-terminal --stdout) { … }   ->  SKIPPED interactively, SKIPPED under nu -c
if $nu.is-interactive     { … }   ->  FIRED   interactively, SKIPPED under nu -c
```

`is-terminal --stdout` reports the redirection state of the *current pipeline*,
and a parenthesised sub-expression captures stdout, so as an `if` condition it
is false unconditionally — on a terminal or off one. (A bare top-level
`is-terminal --stdout` statement in a REPL does print `true`; wrapping it in
parentheses to use it as a condition is what makes it false.) Consequences:

- With the specified guard, **R7's start dir, R8's dirstack push and R10's
  palette re-assert would all be dead code** — and they are dead in the live
  config today, which guards on it. This is a new live bug, not a spec defect
  the analyst could have seen; spec01 D4 itself names `$nu.is-interactive` as
  working "equally well for R7".
- The distinction R7 needs is preserved exactly: `$nu.is-interactive` is false
  for every `nu -c`, so `nu -c 'pwd'` keeps its caller's cwd (gate S4.20, also
  under a real pty) and `nu -c 'print hi'` emits the bytes `68690a` and spawns
  nothing (gate S4.21).
- Both files carry the measurement in a comment, and the gate asserts that
  they do.
- **Hand-off:** a corrections-backlog row — spec01 D4 and spec03 S3.13/S3.17
  name a guard expression that cannot fire, and the live `~/.config/nushell/`
  config has the same bug in `env.nu` and `config.nu`.

**R11 is `[~]`, deliberately.** Per spec03 D4, `esc_clear` ships as the
unconditional `edit: clear` the shipped manual already describes; R11's "closes
an open menu when one is open" clause names behaviour `edit: clear` does not
have and is not implementable as written. The help obligation is discharged
without touching `06-help`'s tree — `shell.nuon`'s `Esc` entry was already
correct, and the gate asserts it stays that way and that this gate only reads
the `.nuon` (S4.18).

**The two `[~]` acceptance lines** are the ones no automated check can reach
from here. `chsh` + a GUI-launched WezTerm is a live-machine act, so the PATH
repair is proved instead against an isolated `HOME` from a bare
`PATH=/usr/bin:/bin` (S4.24); `tinty apply` + a new pane is proved as the
four-way ladder against marker stubs (S4.27). Both are stub-grade evidence for
a real-machine claim, which is what `[~]` means.

**Other hand-offs for the corrections backlog**, each already argued in a spec:
spec01 D1 (R2's ENV_CONVERSIONS premise is false on 0.114.1 — the requirement
survives, its stated reason does not), spec03 D3 (R10(b) cites ~65 ms for
`tinty init`; measured ~128 ms, so the requirement holds a fortiori) and
spec03 D4 (R11's wording).

**One addition to the gantt's `files` for S.1:** `tests/nushell-core.sh`, the
gate spec04 specifies. Nothing else outside the four files was written.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `bash tests/nushell-core.sh` →
**147 PASS / 0 FAIL**, exit 0, re-run independently; the implementer reports it
stable across five consecutive runs. RED proved on a scratch copy with the three
managed files deleted (13 FAIL). All 80 spec boxes ticked; R1–R10 `[x]`, R11
`[~]`; four acceptance boxes `[x]`, two `[~]`. `verify:` set to the gate.
Re-checked: `alias cd = mkcd` at line 173 precedes the zoxide source, `let ans`
appears zero times, nushell 0.114.1, `~/.cache/nushell` absent.

**It found a live bug the analyst could not have seen, and it is the important
part of this ticket.** spec01 D4 and spec03 S3.13/S3.17 specified
`is-terminal --stdout` as the interactive guard. Measured under a real pty, in
the `if (…)` position the config actually uses, it **cannot fire in either
direction** — `is-terminal --stdout` reports the *current pipeline's*
redirection state, and a parenthesised sub-expression captures stdout. (Bare at
a REPL it prints `true`; wrapping it in parens to use it as a condition is what
makes it false.) `$nu.is-interactive` fires interactively and skips under
`nu -c`, which is the wanted behaviour.

The analyst's D4 measurement had tested only the `nu -c` half, where both
answers agree — so the spec was wrong in a way its own evidence could not
reveal. The implementer shipped `$nu.is-interactive` at every guard with the
measurement in a comment in both files and a gate check asserting it stays.

**This is also a defect in the live config being replaced.** `~/.config/nushell/config.nu`
guards on `is-terminal --stdout` at lines 399, 492, 662 and 707 — verified by
the orchestrator — so R7's start dir, R8's dirstack push and R10's palette
re-assert are dead there today. The rebuild fixes it by construction; nothing
needs doing to the live config, which is the artifact being superseded.
*Orchestrator caveat: the `nu -c` half and the four live guard sites were
confirmed independently; the pty half rests on the implementer's `pty.fork`
measurement and was not reproduced here.*

**R11 is `[~]` on purpose** — the binding ships as the unconditional
`edit: clear`, because "closes an open menu when one is open" is not something
`edit: clear` does. No `.nuon` was edited: `shell.nuon` already described the
unconditional form, so the shipped manual stays true. **The two `[~]` acceptance
lines are the ones nothing here can reach** — `chsh` plus a GUI WezTerm, and
`tinty apply` plus a new pane. Both were proved to stub grade instead, which is
exactly what `[~]` means rather than a softened `[x]`.

**The gate is unusually good.** Counterfactuals that bite rather than decorate:
a `PALETTE`-below-`THEME` copy fails, an alias-after-zoxide copy fails, and
removing one generated init reproduces `nu::parser::sourced_file_not_found` —
keeping P.4's always-exists guarantee load-bearing. A ~30-check **"hard-won
why"** block greps for every load-bearing reason (path_helper, the phantom blank
line, `^[[?0u`, the 0.115 builtin-variable collision that broke this machine's
login shell today, and R10's ~5 ms vs ~128 ms ladder) so the next editor cannot
silently delete them. And two debugging findings were written into the gate
rather than discarded: poisoning `bash` breaks the apply because the generator's
shebang is `#!/usr/bin/env bash`, and `input --numchar 1` raises an I/O error on
a pipe, so the confirm arm genuinely requires a pty.

It also made the pty interactions **marker-driven rather than sleep-driven**
after a fixed-sleep version flaked one run in three — a flake found and removed
rather than lived with.

**Recorded in the ticket's `## Implementation record`, not lost:** the dead-guard
defect above, R2's false `ENV_CONVERSIONS` premise on 0.114.1, R10(b)'s ~65 ms
citation against a measured ~128 ms, and R11's unimplementable wording.
