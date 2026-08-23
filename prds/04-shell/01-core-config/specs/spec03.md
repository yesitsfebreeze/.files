# spec03 — `home/dot_config/nushell/config.nu`

Covers **R3**, **R4**, **R5**, **R6**, the hook half of **R8**, **R9**,
**R10** and **R11** of [`../prd.md`](../prd.md) — and, because this is the
gateway node, the **ordering contract** every later shell task appends into.

## Goal

The one `config.nu` the whole epic shares: the `$env.config` record, the
`mkcd` funnel, the PWD reaction point, the three generated-init `source`
lines, the tinty palette re-assert and the `esc_clear` binding — laid out in
an order that is load-bearing, with named anchors so `S.2`–`S.9` can append
without re-deriving it.

## Exact files touched

- **create** `home/dot_config/nushell/config.nu` → deploys to
  `~/.config/nushell/config.nu`

## The file is shared, and the gantt says so

`.mi/gantt/plan.json` lists `home/dot_config/nushell/config.nu` in the `files`
of **S.1, S.2, S.3, S.4, S.5, S.6** (and the later shell tasks). This node
does **not** invent a module-per-node layout to avoid that — the schedule
already decided the file is co-written, serially, and inventing a different
layout here would contradict it.

Two alternatives were measured and rejected:

- **nushell autoload.** `$nu.user-autoload-dirs` on this host resolves to
  `~/Library/Application Support/nushell/autoload` — *outside* `~/.config`,
  which would split the managed tree across two roots. Measured.
- **Pre-declared `source` lines for files siblings will create later.** A
  `source` of a missing file is a **parse error**, measured:
  `Error: nu::parser::sourced_file_not_found`. So `config.nu` can only ever
  source files that already exist at the moment it is deployed, and this node
  may not write source lines for `finder.nu`, `theme.nu`, `pass.nu` or
  `quicklist.nu`.

What this node owes the epic instead is **S3.14**: named anchor comments, in
order, that make "where does my block go" a lookup rather than a judgement
call — and a gate that fails when the order is broken.

## Decisions this spec makes, with the evidence

**D1 — the `cd` alias must be parsed BEFORE the generated zoxide init is
sourced, and getting it wrong fails silently.** The generated
`~/.cache/nushell/init/zoxide.nu` calls `cd` in two places (live equivalent,
`~/.zoxide.nu:43` `cd $path` and `:48` `cd $'(^zoxide query --interactive …)'`),
and nushell resolves a def body's command calls at parse time. Measured, two
otherwise identical configs:

```
# alias cd = mkcd  BEFORE  source .../zoxide.nu
MKCD-SAW /tmp
/tmp
# alias cd = mkcd  AFTER   source .../zoxide.nu
/tmp
```

Both jumped. Only the first went through the funnel. The wrong order does not
error, does not warn, and does not change where you land — it just stops
`startdir.txt` and the dirstack from ever updating for zoxide jumps, which is
epic invariant **I1** quietly failing. That is why S3.14 makes the order a
checked artefact and not a convention.

**D2 — `let ans` is banned by name.** `config.nu:279` of the live config binds
`let ans` inside `mkcd`. On **nushell 0.115**, `ans` is a builtin variable
name, and an agent upgrading nushell broke this machine's login shell with it
today. The pinned version is **0.114.1** (measured: `/opt/homebrew/bin/nu` →
`../Cellar/nushell/0.114.1/bin/nu`, `version` → `0.114.1`). The rebuild binds
`let reply` and the gate greps for `let ans` — a name that costs nothing to
avoid and cost a login shell to keep.

**D3 — R10's numbers, measured here rather than inherited.** 2026-08-21, five
runs each:

| what | total | per call |
|---|---|---|
| `bash ~/.local/share/tinted-theming/tinty/artifacts/tinted-shell-scripts-file.sh` | 0.026 s | **~5 ms** |
| `tinty init` | 0.641 s | **~128 ms** |

R10(b) says "~65 ms" for `tinty init`; the measured figure on this machine is
about twice that. The direction of the requirement is right and the margin is
larger than stated. The artifact exists right now
(`…/artifacts/tinted-shell-scripts-file.sh`, 5097 bytes, alongside
`current_scheme`), so the fast path is the normal path and `tinty init` really
is only the fresh-machine fallback.

**D4 — `esc_clear` is an unconditional `edit: clear`, and R11's first clause
is not implementable as written.** R11 says "closes an open menu when one is
open and otherwise clears the line (an `edit: clear` event)". The parenthetical
names a single event that has no menu branch, and the live config is exactly
`event: { edit: clear }` under a comment that claims the two-stage behaviour —
the comment is aspirational, the code is not. The tie is already broken by
this node's own dependency: `06-help/01` landed
`home/dot_config/nushell/help/shell.nuon` today with the `Esc` entry reading
*"It is an unconditional clear with no menu-close branch, so the line goes
whether or not a completion or history menu is open — this is not a two-stage
escape."* Implementing the two-stage form would make the shipped manual wrong
on the day it shipped. So: unconditional `edit: clear`, modes
`[emacs vi_insert]`, and R11's wording goes to the corrections backlog
(Hand-offs).

**D5 — the PWD hook is a list of closures, and this node appends exactly
one.** R8 (dirstack push) is this node's; the auto-list is
[`04-shell/06`](../../06-listing/prd.md) R5's, and the `$env._NAV` screen-clear
guard is [`04-shell/03`](../../03-zoxide/prd.md) R5–R7's. The live config fuses
all three into one closure. Splitting them is not cosmetic: `hooks.env_change.PWD`
is a *list*, three nodes co-write this file, and three appends to a list cannot
conflict the way three edits to one closure body can. `stty sane` goes with the
auto-list closure that needs it, not here.

**D6 — this node writes no `source` line for a sibling's module.** See "The
file is shared" — the parse-error measurement makes it impossible, not merely
unwise. Anchors, not source lines.

## Requirements — boxes a real check can fail

### `$env.config` (R3, R4, R5)

- [x] **S3.1** — The record is one literal `$env.config = { … }` assignment at
      the top of the file, and it parses clean on 0.114.1 with no deprecation
      output. (Verified for the exact record below by running it: `CONFIG-OK`,
      no warnings.)
- [x] **S3.2** — **Shell behaviour (R3).** `show_banner: false`,
      `edit_mode: emacs`, `rm: { always_trash: true }`,
      `filesize: { unit: binary }`, `completions:` `case_sensitive: false`,
      `quick: true`, `partial: true`, `algorithm: fuzzy`, and
      `external: { enable: true, max_results: 100 }`. Each readable back from
      a `nu -c` run against the deployed file.
- [x] **S3.3** — **`cursor_shape: { emacs: block }`** with the comment R3
      demands: a solid block, and the **terminal** supplies the blink — this
      file does not restate the terminal's setting.
- [x] **S3.4** — **`table: { mode: rounded, index_mode: auto,
      header_on_separator: true }`.**
- [x] **S3.5** — **History store (R4).** `history:` `max_size: 100_000`,
      `file_format: sqlite`, `sync_on_enter: true`, `isolation: false`. The
      comment states that `isolation: false` is what
      [`05-history`](../../05-history/prd.md) requires — one merged sqlite the
      Ctrl-R channel reads in full — and that `sync_on_enter: true` is what
      makes a command from another pane arrive without opening a new shell.
- [x] **S3.6** — **Terminal integration (R5).** `shell_integration:`
      `osc133: false`, `osc633: false`, `osc7: true`, each with its reason in
      the comment: the two-line starship prompt re-emits the OSC 133
      prompt-start mark on every reedline repaint and the terminal renders it
      as a phantom blank line above the input; OSC 7 stays **on** because it
      is what reports the cwd the terminal's status line reads, so the
      disables above are not mistaken for turning all integration off.
      Measured that the default is on: a bare `nu -n` REPL under a pty emits
      both `ESC]7;file://…` and `ESC]133;D;0`.
- [x] **S3.7** — **`use_kitty_protocol: false`** with its reason: with it on,
      reedline fires the kitty support query twice at startup and the WezTerm
      pty returns the reply too late to consume, so it leaks `^[[?0u` above
      the prompt. The comment also records what turning it off costs —
      Ctrl-Shift-R is indistinguishable from Ctrl-R, which is why
      [`05-history`](../../05-history/prd.md) R2 uses **Alt-R**.
- [x] **S3.8** — **`hooks: { env_change: { PWD: [] } }`** is declared empty in
      the record, so every consumer appends (D5).

### The funnel (R6) and the reaction point (R8)

- [x] **S3.9** — `source ~/.config/nushell/dirstack.nu` appears **before**
      `mkcd` is defined, so `_startdir_save` is in scope at parse time, and
      before the PWD hook append, so `_dirstack_push` is.
- [x] **S3.10** — **`mkcd` (R6).** `def --env mkcd [dir?: path]`. No argument →
      `$env.HOME`; `-` → passed straight through; anything else →
      `path expand`. A target that does not exist prompts with
      `input --numchar 1`; a **blank** keypress confirms and `mkdir`s it, any
      non-blank keypress prints `aborted` and returns without moving. Then
      `cd $target`, then `_startdir_save $env.PWD`.
- [x] **S3.11** — **No `let ans` (D2).** A grep for `let ans` in this file
      returns nothing; the confirm binding is `let reply` (or any name that is
      not a nushell builtin), and the comment records that `ans` became a
      builtin variable in 0.115 and broke this machine's login shell.
- [x] **S3.12** — **`alias cd = mkcd`** is written *after* the `def`, so the
      `cd $target` inside the body still resolves to the builtin and does not
      recurse — with the comment saying so.
- [x] **S3.13** — **The PWD append (R8, D5).** Exactly one closure is appended
      to `$env.config.hooks.env_change.PWD`, and it calls `_dirstack_push
      $after` only when `$before != null` (skip the startup fire),
      `$after != $before` (a real move) and `is-terminal --stdout`. It does
      **not** call `la` and does **not** run `stty sane`.

### The ordering contract (R9, and the epic's shared file)

- [x] **S3.14** — **Named anchors, in this order, each a single comment line
      of the form `# ── <ANCHOR> ──`, and the gate asserts both their
      presence and their relative order:**

      1. `CONFIG` — the `$env.config` record (S3.1).
      2. `ALIASES` — where [`S.2`](../../02-aliases-utilities/prd.md) puts the
         tool/quit/`rr` aliases and `cf`; empty when this node lands.
      3. `LISTING` — where [`S.3`](../../06-listing/prd.md) puts `core-ls`,
         the `ls` shadow and `l`/`ll`/`la`; empty when this node lands.
         **Before** `FUNNEL`, because the auto-list closure appended at
         `HOOKS` names `la` and nushell resolves it at parse time.
      4. `FUNNEL` — `dirstack.nu` source, `mkcd`, `alias cd = mkcd`
         (S3.9–S3.12).
      5. `HOOKS` — the PWD appends (S3.13, plus S.3's auto-list and S.4's
         `_NAV` guard).
      6. `GENERATED` — the three `source` lines (S3.15).
      7. `MODULES` — where later nodes source their own new files
         (`finder.nu`, `quicklist.nu`, `pass.nu`); empty when this node lands,
         and it must stay empty here because a `source` of a file that does
         not exist yet is a parse error (D6).
      8. `PALETTE` — the tinty re-assert (S3.17). Before `THEME` per R10(e).
      9. `THEME` — where [`S.9`](../../09-theme-switcher/prd.md) sources
         `theme.nu`; empty when this node lands.
      10. `KEYBINDINGS` — the append block (S3.18), last, because reedline
          resolves a duplicate `(modifier, keycode)` to the **later** entry and
          [`05-history`](../../05-history/prd.md) R5 depends on beating the
          generated television init's own Ctrl-T and Ctrl-R.

- [x] **S3.15** — **The three generated sources (R9).** Exactly, and in this
      order:
      `source ~/.cache/nushell/init/starship.nu`,
      `source ~/.cache/nushell/init/zoxide.nu`,
      `source ~/.cache/nushell/init/television.nu`. These are the literal
      paths [`05-platform/03`](../../../05-platform/03-shell-init-generation/prd.md)'s
      generator writes (`INIT_DIR="$HOME/.cache/nushell/init"`). None of the
      three superseded live paths (`~/.zoxide.nu`, `~/.cache/starship/init.nu`,
      `~/.cache/television/init.nu`) appears anywhere in this file.
- [x] **S3.16** — **`XDG_CACHE_HOME` is not honoured, and the comment says
      why:** nushell resolves `source` at **parse** time and cannot read
      `$env`, so `source ($env.XDG_CACHE_HOME | path join …)` is not
      expressible. One literal path on both sides cannot diverge; a generator
      that honoured the variable while the shell could not would produce three
      failing `source` lines at every shell start. Measured: a missing sourced
      file is `Error: nu::parser::sourced_file_not_found`, which is why the
      generator's guarantee that all three files always exist is load-bearing
      for this node.

### The palette (R10)

- [x] **S3.17** — **The re-assert.** Guarded on `is-terminal --stdout`; resolves
      `$env.XDG_DATA_HOME?` defaulted to `$nu.home-dir/.local/share`; joins
      `tinted-theming/tinty/artifacts/tinted-shell-scripts-file.sh`; if that
      exists, `try { ^bash $palette e> /dev/null }`; else, only if
      `which tinty | is-not-empty`, `try { ^tinty init e> /dev/null }`. The
      comment carries R10's five reasons **(a)–(e)** with D3's measured
      numbers, and states that this is the deliberate exception to R9 because
      the active scheme changes at runtime and nothing generated at apply time
      can carry it. Checks: with a poison `bash` and a poison `tinty` on PATH,
      `nu -c 'print hi'` spawns neither and emits no escape byte; with a stub
      `bash` that prints a marker and an artifact file present, an
      interactive-guarded run reaches the artifact and not `tinty init`; with
      the artifact absent and a stub `tinty`, it reaches `tinty init`; with
      both absent, it does nothing and does not error.

### The binding (R11)

- [x] **S3.18** — **`esc_clear`.** One keybinding record appended under the
      `KEYBINDINGS` anchor: `name: esc_clear`, `modifier: none`,
      `keycode: escape`, `mode: [emacs vi_insert]`, `event: { edit: clear }`
      (D4). Readable back: `$env.config.keybindings | where name == esc_clear`
      returns exactly one row with those modes.
- [x] **S3.19** — **The manual already covers it, and stays true.** The `Esc`
      entry in `home/dot_config/nushell/help/shell.nuon` carries
      `verify: [{kind: "keybinding", name: "esc_clear"}]` and describes the
      unconditional clear. This node ships the binding **and changes no
      `.nuon` file** — the `06-help/01` obligation is discharged by the entry
      already being right, not by editing 06-help's tree. A check reads
      `esc_clear` out of both the shipped `config.nu` and `shell.nuon` and
      fails if either loses it. The same check confirms the `cd <path>` and
      `mkcd` entries still match S3.10's confirm semantics (blank keypress
      confirms, any non-blank cancels — the manual already says so, including
      that the reflex `y` is a cancel).

## Out of scope

- Every alias, `ls`, finder, history keybinding, theme command, quicklist and
  Claude launcher in the live `config.nu`. They belong to S.2–S.9 and arrive
  at the anchors S3.14 reserves.
- `burrito` in any form — `DO NOT PORT`, README exclusion list.
- The `cl.py` goal-loop launcher and `_claude_*` profile machinery
  ([`04-shell/08`](../../08-claude-launchers/prd.md)).

## Hand-offs

- **Corrections backlog (a new row):** R11's "closes an open menu when one is
  open and otherwise clears the line" is not what `edit: clear` does and not
  what the shipped manual says (D4). Requirement wording, not behaviour.
- **Corrections backlog (a second row):** R10(b) cites `tinty init` at ~65 ms;
  measured here at ~128 ms (D3). The requirement holds a fortiori.
- **[`04-shell/03`](../../03-zoxide/prd.md) R6** — `mkcd` reads an empty-string
  argument as "no argument" and targets `$env.HOME`. S3.10 keeps that (R6 says
  `` passes through) and it is exactly the hazard backlog row **M-8** names, so
  the zoxide node must never hand `mkcd` an unmatched `zoxide query` result.
- **[`04-shell/06`](../../06-listing/prd.md) R5** — the auto-list closure and
  its `stty sane` append at `HOOKS`, and `la` must be defined at `LISTING`
  above it (S3.14 item 3), because the closure's `la` binds at parse time.
- **The scheduler** — `S.3` and `S.4` are both gated only through `S.2` and
  `S.8` respectively and can therefore run concurrently, and the gantt gives
  both `home/dot_config/nushell/config.nu`. Two agents appending at different
  anchors is still two writers on one file.

## Implementation record

Built 2026-08-21. All nineteen boxes ticked against
`bash tests/nushell-core.sh` (147 PASS / 0 FAIL).

**S3.13 and S3.17 ship `$nu.is-interactive` where they specify
`is-terminal --stdout`.** Measured on 0.114.1 under a real pty: in the `if (…)`
position both this file and `env.nu` use, `is-terminal --stdout` is false
interactively *and* under `nu -c`, because a parenthesised sub-expression
captures stdout and the command reports the current pipeline's redirection
state. With the specified guard the PWD push (R8) and the palette re-assert
(R10) would both be dead code — as they are in the live config today. The
substitution keeps the `nu -c` half exactly (gate S4.20, S4.21, S4.27's `nu -c`
arm). Full argument and hand-off in [`../prd.md`](../prd.md)'s Implementation
record.

**Everything else landed as specified**, including D1's ordering (gate S4.11
asserts the two line numbers and its counterfactual proves the check bites),
D2's banned binding (S4.12; the banned name is kept out of the file entirely so
a grep hit is proof of a regression rather than of a comment), D4's
unconditional `edit: clear`, D5's single appended closure and D6's empty
`MODULES` anchor.
