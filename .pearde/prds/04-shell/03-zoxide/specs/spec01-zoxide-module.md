# spec01 — `zoxide.nu`: wrappers, composed verbs, bare-word fallback

Delivers R1–R7 as a new module, `home/dot_config/nushell/zoxide.nu`, sourced
at config.nu's MODULES anchor after `claude.nu`. The live implementation at
`~/.config/nushell/config.nu:422-531` is the model; what does NOT survive the
port: the unguarded no-match path that sends `z nomatch` (and a cancelled
`zi`) to `$env.HOME` via `mkcd`'s empty-argument reading (backlog **M-8** —
the PRD's first acceptance box names this work to prove), the
`is-terminal --stdout` guard (D3), and the live `_recents_add` binding, which
has no target in this tree yet (D2).

**Est:** 2.5h

**Footprint:** `home/dot_config/nushell/zoxide.nu` (create),
`home/dot_config/nushell/config.nu` (MODULES anchor: one `source` line;
CONFIG anchor: one comment correction),
`tests/nushell-core.sh` (one `cp` line in `mk_machine`; one phrase in the
S3.8 check),
`tests/nushell-aliases.sh` (one `cp` line in `mk_machine`),
`tests/shell-listing.sh` (one `cp` line in `mk_machine`; the H9 check
restructured)

## Exact files touched

- **create** `home/dot_config/nushell/zoxide.nu` → deploys to
  `~/.config/nushell/zoxide.nu` (distinct from the generated
  `~/.cache/nushell/init/zoxide.nu`; every gate names full paths, so the
  shared basename collides nowhere). Contents in parse order:
  1. A header comment carrying: the parse-order contract (this file is
     parsed after the generated zoxide init at GENERATED and after
     `claude.nu` at MODULES — `cc` in `zc`'s body binds at parse time, and
     an unresolved `cc` silently binds to `/usr/bin/cc`, the C compiler);
     the D2 seam and its hand-off to 04-shell/07; the M-8 mechanism with
     its correct attribution (the hazard is `mkcd` reading an empty
     argument as "no argument" and targeting `$env.HOME`, not
     `__zoxide_z`).
  2. `def _recents_add [kind: string, value: string, channel: string] {}` —
     the D2 no-op shim.
  3. `def --env _z_jump [rest: list<string>]` — the guarded jump, returns
     a bool (moved or not). The three literal arms of the generated
     `__zoxide_z` (`[]`, `['-']`, single arg expanding to an existing dir)
     delegate to `__zoxide_z ...$rest` directly and return true. Everything
     else is a query: `^zoxide query --exclude $env.PWD -- ...$rest |
     complete`; on non-zero exit, empty stdout, or a trimmed result that is
     not an existing dir, print the captured stderr (zoxide's own
     `no match found`) with `print -e` and return false — PWD untouched
     (R6, M-8). On a genuine match, `__zoxide_z ...$rest` (R1's wrap, R4's
     funnel: the `cd` inside it is the alias → `mkcd`) and return true.
  4. `def --env --wrapped _z_nav [...rest: string]` (R1) — a single arg
     that expands to an existing *file*: `_recents_add "FileList" $target
     "zoxide"`, then `^$env.EDITOR $target`. Otherwise capture
     `$before = $env.PWD`, run `_z_jump $rest` (bool consumed, never
     printed), and `if ($env.PWD != $before) { _recents_add "DirList"
     $env.PWD "zoxide" }` — dir jumps log only when PWD actually moved.
  5. `def --env --wrapped _zi_nav [...rest: string]` (R2) —
     `^zoxide query --interactive -- ...$rest | complete`; non-zero exit or
     empty trimmed stdout (Esc in fzf) → return without moving (the
     `zi`-shaped M-8 hole: live, a cancel hands `""` to `cd` → `mkcd` →
     HOME). Else `cd $path` (the alias → `mkcd`, R4) and the same
     moved-only recents log as R1. Direct query rather than `__zoxide_zi`:
     R2 names the command, `__zoxide_zi` adds nothing but the unguarded
     `cd`, and no `--exclude` is added — the live `__zoxide_zi` carries
     none (measured, recorded in decisions/fzf's closing note).
  6. `alias z = _z_nav`, `alias zi = _zi_nav`, `alias cdi = zi` (R2 —
     04-shell/02's spec01 explicitly left `cdi` to this node),
     `alias zz = cd -` (R3; `cd` is the funnel alias).
  7. `def --env --wrapped zl [...rest: string]` — `if (_z_jump $rest)
     { la }` (R3). `la` binds to the LISTING def, parsed above MODULES.
     On success the terminal shows the listing twice — `zl`'s own plus the
     PWD hook's — which is exactly what the shipped manual entry says.
  8. `def --env --wrapped zc [...rest: string]` — `if (_z_jump $rest)
     { cc }` (R3). No launch on a failed jump: launching Claude in the
     un-jumped-to dir is the M-8 failure wearing a different hat.
  9. `def --env _z_fallback []` (R5/R6/R7) — ported from live
     `config.nu:491-518` with two changes (D3's guard, D2's shim) and the
     rest carried verbatim WITH the live comments' reasons: guard
     `$nu.is-interactive`; empty `commandline` → return; any of the live
     metacharacter list → return; first token resolvable by `which` →
     return; leading `-`/`/`/`~`, embedded `/`, bare `.`/`..` → return (a
     dot-NAME like `.files` stays a valid target); then `^zoxide query
     --exclude $env.PWD -- ...$tokens | complete`, jump only when exit 0
     and the trimmed stdout is an existing dir (R6 — never via
     `__zoxide_z`, whose empty no-match hand-off is the M-8 route). On a
     jump: `cd $path` (funnel), `_dirstack_push $env.PWD` and
     `_recents_add "DirList" $env.PWD "zoxide"` at jump time (R7 — the PWD
     hook may not fire from pre_execution), `$env._NAV = "1"`.
  10. Append `{|| _z_fallback }` to `$env.config.hooks.pre_execution`
      (cd persists there; `command_not_found` discards env changes — the
      live comment's reason, carried).
  11. Append to `$env.config.hooks.pre_prompt`: if `$env._NAV?` is
      non-empty, reset it to `""` and `print -n` the `[2J[H`
      clear (bury the doomed "command not found"; a post-clear `la`
      cannot survive reedline's repaint, so the fresh prompt in the new
      dir is the confirmation — carried verbatim).
- **edit** `config.nu`, MODULES anchor:
  `source ~/.config/nushell/zoxide.nu` AFTER the `claude.nu` line —
  the placement is the 08-claude-launchers spec01 hand-off, and spec02
  carries the executable counterfactual (a reversed copy trips a poison
  `cc`). A `source` of a missing file is a parse error, so the module and
  the line land in one change; chezmoi deploys both in one apply.
- **edit** `config.nu`, CONFIG anchor comment (lines 90–97): it currently
  promises "three different nodes append a closure to it (… 04-shell/03's
  screen-clear guard)" — a third PWD append this node must NOT make: R7's
  reason (the PWD hook may not fire for a cd made in pre_execution) is
  why the guard lives in pre_execution/pre_prompt instead, and
  `tests/shell-listing.sh` gates exactly two PWD appends. Reword the
  parenthetical to name the two appending nodes (S.1's dirstack push,
  04-shell/06's auto-list) and state that 04-shell/03 sets/clears
  `$env._NAV` from pre_execution/pre_prompt and appends nothing to PWD;
  change "Three appends" to "Two appends" in the following sentence. This
  is a cross-lane edit to S.1's file, made because a stale comment
  instructing a future editor to add a PWD append is worse than no
  comment; the matching check-phrase edit is below.
- **edit** `tests/nushell-core.sh`, two lines:
  one `cp` of the repo's `zoxide.nu` beside `claude.nu` in `mk_machine`
  (the moment config.nu sources it, every hermetic check dies with
  `nu::parser::sourced_file_not_found` — fourth repetition of the pass.nu
  precedent), the line commented with this node's name; and the S3.8
  check's expected phrase updated from `Three appends to a list cannot
  conflict` to the corrected comment's wording, in the same change as the
  comment it checks. Nothing else in the file is touched.
- **edit** `tests/nushell-aliases.sh`: one `cp` of `zoxide.nu` in
  `mk_machine`, commented, nothing else.
- **edit** `tests/shell-listing.sh`: one `cp` of `zoxide.nu` in
  `mk_machine`, commented; and check **H9 restructured**, because this
  module makes the old script wrong: its first entry sets `$env._NAV`
  manually, and the new pre_prompt append consumes it (reset + clear)
  before the `cd` it was meant to suppress ever runs, so the canary count
  comes out 2 and the gate goes red for a reason that is correct behavior.
  Restructure H9 to drive suppression through the real route, which is
  also ordering-proof (pre_execution precedes both other hooks, so it
  holds whichever of env_change/pre_prompt fires first): give the H9
  machine a `zoxide` marker stub printing the fixture dir, type a bare
  unknown word (the fallback jumps to `~/fix`, sets `_NAV`, the auto-list
  is suppressed), then `cd ~`, then `cd ~/fix` (listed once). Same
  assertion, canary count exactly 1. The two-PWD-append count check (T4)
  is NOT adjusted: this module adds no PWD append, and spec02 gates that
  absence with its reason.

## Decisions

**D1 — a module at MODULES, not a block in config.nu.** The anchor map
gives every config.nu anchor to another node and names MODULES as where
later nodes source their own files; `pass.nu` and `claude.nu` are the
precedent, including the staging edits they forced. config.nu churn stays
at one source line plus the comment correction above.

**D2 — the recents seam: a no-op `_recents_add` shim, deleted by S.7.**
The PRD's logging clauses (R1, R2, R7) name the quicklist recents, and
[`07-quicklist`](../../07-quicklist/prd.md) R1 owns `_recents_add` — a node
that lands AFTER this one (it depends on S.5, which depends on S.6, which
depends on this node). Nushell binds a def body's calls at parse time: an
unresolved `_recents_add` would bind to an external and fail at runtime on
every jump, and a runtime `which` guard around it still binds the external
forever. So this file opens with a no-op `def _recents_add [kind, value,
channel] {}` and the four call sites are real and correctly placed.
**Hand-off to 04-shell/07's analyst, also written in the module header:**
quicklist's change must source `quicklist.nu` at MODULES *above* this
file's source line and delete the shim in the same change — this file's
call sites then re-bind to the real logger at parse, the exact mechanism
the live config uses (`finder.nu` sourced before the wrappers). Until
then the PRD's logging boxes close against a stub (`[~]`), never `[x]`.

**D3 — the fallback guard is `$nu.is-interactive`, not the live
`is-terminal --stdout`.** config.nu's PALETTE anchor records the
measurement: `is-terminal --stdout` as a parenthesised `if` condition
captures stdout and is false unconditionally, which is why the live
palette re-assert never fired. `$nu.is-interactive` is the guard every
shipped guard in this tree uses and draws the intended line: fallback
live in the REPL, inert under `nu -c`.

**D4 — no third PWD append, stated rather than implied.** The dispatch
for this node anticipated one. R7 forbids it: the PWD hook may not fire
for a cd made in pre_execution, so this node's reaction points are
pre_execution (jump + logs) and pre_prompt (clear), and
`shell-listing.sh` T4's "exactly two PWD append blocks" stays true and
untouched. spec02 gates the absence in this module.

**D5 — `z`'s query arm pre-flights, then still jumps via `__zoxide_z`.**
The guard (query through `complete`, validate dir) closes M-8; the jump
itself is delegated so R1's "wraps `__zoxide_z`" and R4's "mkcd inside
`__zoxide_z`" stay literally true. Cost: the matched query runs twice,
milliseconds, paid only on success.

## Hands off the manual

`home/dot_config/nushell/help/shell.nuon` already carries `z <query>`,
`zi`, `zz`, `zl <query>`, `zc <query>` and `<word>`, each with
`source: prds/04-shell/03-zoxide/prd.md`, describing exactly the behavior
above — including the failed-`z`-leaves-no-trace clause and `zl`'s
double listing. Do not edit them: a `use` or `source` edit invalidates
the entry's review digest in `use-review.nuon`. If the implementation is
forced to diverge, file a correction instead. (The `cdi` entry's
`source:` names 04-shell/02, which 02's own spec contradicts — reported
upward as a finding, not fixed here.)

## Acceptance

Hermetic = scratch HOME via `env -i`, the repo's managed nushell files at
the literal paths config.nu sources, a fixture zoxide init standing in
for the generated one, recording stubs on PATH. spec02's gate holds every
box; the inline runs below are the smoke check.

- [x] Hermetic: `z <query>` with the zoxide stub returning a fixture dir
      lands there, and `startdir.txt` holds the new dir (funnel proof).
- [x] Hermetic: `z nomatch` (stub exits 1) leaves PWD unchanged, does not
      land in HOME, and `startdir.txt` is unchanged — the M-8 box.
- [x] Hermetic: `z <existing-file>` invokes the `$env.EDITOR` stub with
      the expanded path and PWD does not move.
- [x] Hermetic: a cancelled `zi` (stub prints nothing, exits non-zero)
      moves nothing and errors nothing.
- [x] Hermetic: `zc <query>` runs the recording `claude` stub in the
      jumped-to dir with `--dangerously-skip-permissions`; on a no-match
      the stub is never invoked. A reversed-MODULES counterfactual copy
      trips a poison `cc` instead — the parse-order hand-off, executed.
- [x] Hermetic, pty: a bare unknown word jumps, exactly one `[2J`
      clear appears, `dirs.txt` holds the dir; `ls | nope-xyz` and `./x`
      never invoke the zoxide stub.
- [x] `/usr/bin/grep -c '$env.config.hooks.env_change.PWD' \
      home/dot_config/nushell/zoxide.nu` is 0, and config.nu still holds
      exactly two PWD append blocks.
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh` and
      `bash tests/shell-listing.sh` stay green after the staging edits,
      the S3.8 phrase edit and the H9 restructure.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-zoxide.sh          # spec02's gate; covers every box above
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
/usr/bin/grep -n 'zoxide.nu' home/dot_config/nushell/config.nu  # cache init at GENERATED + one MODULES line after claude.nu
```
