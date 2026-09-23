# Nushell modules

> The sourced modules \u2014 history, finder, zoxide, capsule, theme, help and the rest.

Notes harvested from the module sources. Each block is anchored to the line it was written about.

## `env.nu`

```
$env.ENV_CONVERSIONS = {
```

env.nu — nushell's env-config. Nushell evaluates this file BEFORE config.nu, and WezTerm launches nu with an explicit `--env-config` pointing here, so this is the first of the two managed files to run in every shell.

It does three things and nothing else: repair PATH for a login shell macOS never ran `path_helper` for (R1), set the handful of variables the rest of the epic reads (R2), and open an interactive shell where the user last navigated while leaving `nu -c` in its caller's directory (R7).

It sources nothing. The generated shell integrations (starship, zoxide, television) are produced at chezmoi-apply time by `run_after_generate-shell-init.sh` and merely `source`d by config.nu (R9); nothing here does startup work beyond the one guarded probe at the bottom. See prds/04-shell/01-core-config/specs/spec01.md. ── PATH <-> list conversions ─────────────────────────────────────────────── Required in principle because this file overrides nushell's stock env.nu, which is where the string<->list conversion normally comes from.

MEASURED 2026-08-21 on the pinned nushell 0.114.1, with an empty env-config and no ENV_CONVERSIONS anywhere: `$env.PATH | describe` is ALREADY `list<string>` and it ALREADY round-trips to a colon-joined string for child processes. So on this version the PATH repair below does not depend on this block. It is kept because the requirement makes it a box and because it is cheap insurance if a future nushell drops that built-in special case — but do not repeat the older claim that without it `$env.PATH` is a plain string. It is not, here.

The closures are a PLAIN round trip. The live block ran each side through nushell's path-expansion command; that is deliberately dropped, and the command's name is kept out of this file so a grep for it is proof it is gone. Measured, both directions: expansion had no observable effect on a `~/...` entry (it is already expanded on the way in), and its ONE real effect was to make a RELATIVE PATH entry absolute against the CURRENT WORKING DIRECTORY — which would make the exported PATH change as you `cd`. That is a surprise, not a feature.

The "Path" key is the Windows spelling and is INERT on this host — the scope decisions declare macOS only. It costs one record entry, so it is kept to match the requirement's wording; it is not evidence of Windows support.

```
$env.PATH = (
```

── PATH repair (R1) ──────────────────────────────────────────────────────── macOS seeds Homebrew and the system dirs into a login shell's PATH via `path_helper` (which reads /etc/paths and /etc/paths.d/*), but path_helper is only ever invoked from /etc/zprofile and /etc/profile — i.e. from bash and zsh. NUSHELL NEVER RUNS IT. So when nu is the login shell (`chsh`) and WezTerm is launched from the GUI rather than from another terminal, /opt/homebrew/bin and the system dirs are simply absent, and bat, rg, starship, tv and lazygit all go missing. This block is not cargo-culting: delete it and a GUI-launched terminal loses Homebrew.

The user dirs are `prepend`ed (they win) and the system dirs are `append`ed (they lose), and `uniq` makes the whole thing a no-op whenever the parent process already provided them — so running nu inside nu changes nothing.

```
$env.XDG_CONFIG_HOME = ($nu.home-dir | path join ".config")
```

── Environment (R2) ────────────────────────────────────────────────────────

```
$env.RIPGREP_CONFIG_PATH = ($nu.home-dir | path join ".config" "ripgrep" "config")
```

RIPGREP_CONFIG_PATH is what makes `rg` share the ignore rules `fd` reads natively from ~/.config/fd/ignore (node_modules, target, build, …). Without this pointer the two finders disagree about what is worth searching, and the same query gives different answers depending on which tool you reached for.

```
$env.STARSHIP_SHELL = "nu"
```

STARSHIP_SHELL names the prompt. starship is the prompt for this shell, sourced from the generated init that config.nu picks up (R9), and it is specifically starship's TWO-LINE prompt that forces config.nu's OSC 133/633 disable — reedline repaints re-emit the prompt-start mark and the terminal renders it as a phantom blank line. The file that names the prompt and the file that works around it have to be readable together, so this is that name.

```
$env.SHELL = $nu.current-exe
```

SHELL advertises nu to anything that spawns "the user's shell" by $SHELL. This is a FALLBACK, not the primary path — nothing in this configuration relies on it — but anything that does fall back to $SHELL should land on nu.

```
if $nu.is-interactive {
```

── Start dir (R7) ────────────────────────────────────────────────────────── Open every interactive shell in the last directory navigated into by any means (real `cd`, zoxide, picker jump) — `mkcd`, the single funnel, records it in startdir.txt on every move — falling back to ~/dev on a fresh machine.

The startdir.txt path is computed HERE and again in dirstack.nu's `_startdir_file`. That is a deliberate MIRROR, not duplication by accident: env.nu runs before config.nu sources dirstack.nu, so this file cannot call that helper. The two must agree on the XDG_STATE_HOME default, the `nushell` segment and the filename. Nothing checks that they still do, so change one and you must change the other in the same edit — a divergence here loses the start dir silently.

THE GUARD IS `$nu.is-interactive`, AND IT IS NOT THE ONE THE LIVE CONFIG USES. Measured on nushell 0.114.1, 2026-08-21, in this very file, under a real pty allocated by python's `pty.spawn` (so the child genuinely has a terminal — a `/bin/sh -c '[ -t 1 ]'` spawned from inside nu answers yes):

```
  if (is-terminal --stdout) { ... }   ->  SKIPPED interactively
                                          SKIPPED under `nu -c`
  if $nu.is-interactive     { ... }   ->  FIRED   interactively
                                          SKIPPED under `nu -c`
```

`is-terminal --stdout` reports the redirection state of the CURRENT pipeline, and a parenthesised sub-expression captures stdout — so in an `if (...)` condition it is false unconditionally, on a terminal or off one. (A bare top-level `is-terminal --stdout` statement in a REPL does print `true`; the moment it is wrapped in parentheses to be used as a condition it is false.) The live config guards on it, which is why the start dir it describes has never actually fired. `$nu.is-interactive` is exactly the distinction R7 asks for and is what is used here and in config.nu.

~/dev is `mkdir`-ed first so the fallback `cd` cannot fail on a fresh machine.

```
if $nu.is-interactive and (which ollama-host | is-not-empty) {
```

── The Ollama endpoint probe (R2) ────────────────────────────────────────── Resolves the Ollama endpoint by running `ollama-host` and taking its stdout, and ONLY when it exits 0 — a missing or failing probe leaves OLLAMA_HOST unset rather than setting it to noise.

COST, measured on this machine 2026-08-21 (~/.local/bin/ollama-host is a sh script running one `curl -fs --max-time 0.4`): ~11 ms per call with Ollama listening on 127.0.0.1:11434, ~10 ms with nothing listening (a refused connection returns immediately), and a worst case bounded by curl's own --max-time at 400 ms, reachable only against a host that DROPS rather than refuses. Recorded here rather than described as "cheap", because it is one external spawn on every interactive start and R9's promise is a zero-work startup. For scale: config.nu's palette re-assert costs ~5 ms.

Guarded on the same `$nu.is-interactive` as the start dir (see the measurement there), so a scripted `nu -c ...` caller pays nothing and spawns nothing.

AND ON `which`, BECAUSE `complete` DOES NOT CATCH A MISSING EXTERNAL. This repo deploys no `ollama-host` — `git ls-files home` carries nothing under `.local/bin` and no package list names it — so on a fresh provision the binary is absent. Measured 2026-08-23 on 0.114.1 under a real pty with it absent, the unguarded `do { ^ollama-host } | complete` printed `nu::shell::external_command` / "Command `ollama-host` not found" at EVERY interactive start AND ABORTED THE REST OF THIS FILE: a `$env.X = ...` appended below this block never ran. The block being LAST is the only reason the visible damage is the message alone — anything appended below it would silently not run.

`complete` is not a presence check, and no redirect makes it one: `^missing e> /dev/null` raises the identical error, because there is no child whose stderr could be redirected. `do --ignore-errors { ^missing } | complete` is worse still — it fails with "Complete only works with external commands". `try { ... }` DOES catch it, which is what makes config.nu's `^bash <artifact>` safe at the PALETTE anchor, but wrapping this probe in `try` would throw away the exit code the next line reads. So the guard is `which`, the same idiom guarding `tinty init` one branch below that artifact.

COST of the guard, measured the same day in the same shell: 100 lookups of an ABSENT name take 0.49 ms (~5 µs each), 100 of a present one 0.94 ms (~9 µs each). Three orders of magnitude under the ~11 ms spawn it guards, so it does not dent R9's zero-work startup.

## `dirstack.nu`

```
const DIRSTACK_CAP = 100
```

dirstack.nu — directory-history STATE. Two files under XDG state, and the helpers that read and write them. This module is state, not a picker: no UI lives here.

1. dirs.txt — a recency-ordered stack of every directory visited. The PWD `env_change` hook in config.nu pushes every move onto it, whatever the move was: real `cd`, a zoxide jump, a picker jump. Newest first, deduped (one entry per directory, so the head is always "latest visited") and capped. `_dirstack_list` is the source the **recent-dirs** television channel draws from; the decode on the picker side belongs to 04-television R2, not here.

2. startdir.txt — a single line: the last directory moved into, by any means. `mkcd` is the single funnel every move flows through, so it writes this on every move, and env.nu reads it at shell start so a new shell opens wherever navigation last left off.

env.nu READS startdir.txt directly, because env.nu is evaluated before config.nu sources this module and so cannot call `_startdir_file`. Its path computation is a deliberate MIRROR of the one below — same XDG_STATE_HOME default, same `nushell` segment, same filename — and nothing checks that the two still agree, so they are changed together or not at all.

This file is `source`d rather than `use`d, and the defs are `export def`, so the names land unprefixed: config.nu needs `_startdir_save` in scope at PARSE time for `mkcd`'s body and `_dirstack_push` in scope for the PWD hook closure. See prds/04-shell/01-core-config/specs/spec02.md.

NO `--env` ON ANY DEF BELOW, and it is worth saying twice because adding one would look harmless: these helpers only write files. The `cd` that prompted the write has already happened in the caller, so an `--env` here would buy nothing and would silently change `mkcd`'s and the hook's env semantics. The cap, named rather than buried as a literal inside `take`.

```
export def _state_dir [] {
```

_state_dir: resolve (and create) the state directory, XDG-first. `$nu.home-dir`, not `$env.HOME`: on this host the two differ under a symlinked TMPDIR (`/private/var/...` vs `/var/...`), and env.nu's mirror uses `$nu.home-dir`, so the two must agree.

```
export def _dirstack_file [] {
```

_dirstack_file: the recency stack. Derived from `_state_dir`, so there is exactly one definition of the directory.

```
export def _startdir_file [] {
```

_startdir_file: the single-line start-dir marker, alongside the stack.

```
export def _startdir_save [dir: string] {
```

_startdir_save: persist `dir` as the directory the next new shell opens in. Overwrites — this file holds one path and only the newest. No --env (see the header).

```
export def _dirstack_push [dir: string] {
```

_dirstack_push: move `dir` to the head, drop any earlier occurrence of the same path, cap the list, persist newest-first one path per line. No --env (see the header).

```
export def _dirstack_list [] {
```

_dirstack_list: the stored dirs, newest first, dropping blank lines and paths that no longer exist.

The filter is on READ, deliberately, and the push side does none of it. A directory deleted after it was pushed must never reach the picker, and the push has no way to know that happened. Filtering here costs one `path exists` per entry over a list capped at 100; filtering on write would leave stale entries behind forever whenever the deletion came after the last push.

This is a read: the file is not rewritten or compacted.

## `recents.nu`

```
const RECENTS_CAP = 200
```

recents.nu — the cross-channel recency LOG (04-shell/07-quicklist R1/R2). One nuon file under XDG state, five defs that read and write it, and nothing else: no picker, no keybinding, no hook, no `$env.config` write. The picker half lives in quicklist.nu, sourced below finder.nu.

WHY THIS NODE SHIPS TWO MODULES AND NOT ONE. Nushell binds a def body's
command calls at PARSE time, and this node has a genuine cycle:
  * zoxide.nu (MODULES, above finder.nu) and finder.nu BOTH call
    `_recents_add`, so the log must parse BEFORE both;
  * quicklist.nu's runner calls `_finder_decode`, `_finder_open`,
    `_finder_parse` and `finder`, so it must parse AFTER finder.nu.
One file cannot sit on both sides of finder.nu, so the log is its own
module and is sourced between claude.nu and zoxide.nu. An unresolved
`_recents_add` would bind as an EXTERNAL and fail at runtime on every
jump, which is what the deleted no-op shim in zoxide.nu was standing in
for.

FOUR LOAD-BEARING DECISIONS, each with its reason:

(1) THE STATE DIRECTORY IS dirstack.nu's `_state_dir`, NOT A SECOND COMPUTATION. dirstack.nu is sourced at config.nu's FUNNEL anchor, well above MODULES, and it exports `_state_dir` precisely so there is exactly one definition of the directory — so the log is `<XDG_STATE_HOME|~/.local/state>/nushell/recents.nuon`. This deliberately DIFFERS from the live config, which computed its own `$env.HOME`-rooted `.../state/finder/` path: on this host `$nu.home-dir` and `$env.HOME` differ under a symlinked TMPDIR (dirstack.nu's own header records it), and a second path computation is exactly the divergence env.nu already has to be kept in step by hand. The COST is that this file does not run standalone under `nu -n` on its own — so quicklist.toml's source command sources dirstack.nu first, exactly as recent-dirs.toml already does for `_dirstack_list`.

(2) THE ROW HAS FOUR FIELDS, NOT FIVE. The live log carried a `query` column that was written `""` at every call site and read by nothing. R1 names kind, value, channel, cwd and a timestamp and does not name a query, so the field is dropped. The cable's display template indexes (0 kind, 1 value, 2 cwd, 3 channel) are unchanged by the drop.

(3) `ts` IS STORED AND NOT READ. R1 requires it; ordering is POSITIONAL — newest-first on write — so nothing sorts by it. Said out loud so the next reader does not add a `sort-by ts`, which the 200-entry cap makes wrong: the cap has already dropped the tail the sort would need.

(4) NO `--env` ON ANY DEF HERE, and it is dirstack.nu's reason: these helpers only write a file. The `cd` (or the editor spawn, or the tv pick) that prompted the write has already happened in the caller. The cap, named rather than buried as a literal inside `first`.

```
export def _recents_file [] {
```

_recents_file: the log. Derived from dirstack.nu's `_state_dir`, so there is exactly one definition of the directory (decision 1).

```
export def _recents_key [e] {
```

_recents_key: the dedup identity of an entry — channel + value, with an ASCII unit separator between them so a channel name ending in the value's first characters cannot collide with a shorter pair. ONE definition, used by the add path and by nothing else, so "dedup by channel+value" has a single spelling.

```
export def _recents_load [] {
```

_recents_load: the parsed log, newest first, or [] for a missing, empty or corrupt file. Two guards, not one, and both are measured on the pinned 0.114.1: `"" | from nuon` returns NULL rather than raising, so an empty file needs the shape check and not just the `catch`; and a list of records describes as `table<...>`, not `list<...>`, so a prefix test for `list` alone rejects every log this file ever writes.

```
export def _recents_add [kind: string, value: string, channel: string] {
```

_recents_add: prepend one entry, drop any earlier entry with the same channel+value, cap the list, persist as nuon. Newest first, positionally (decision 3). No --env (decision 4).

```
export def _recents_lines [] {
```

_recents_lines: the quicklist cable's source rows — one TAB-joined `kind<TAB>value<TAB>cwd<TAB>channel` line per entry, newest first, joined with newlines because television reads the source command's STDOUT. The field order is the cable's template contract: 0 kind, 1 value, 2 cwd, 3 channel (decision 2).

## `zoxide.nu`

```
def _z_no_zoxide [] {
```

zoxide.nu — zoxide navigation (04-shell/03): the z/zi wrappers, the composed verbs zz/zl/zc, and the bare-word fallback. Sourced by config.nu at the MODULES anchor.

PARSE ORDER IS LOAD-BEARING, TWICE OVER. Nushell binds a def body's command calls at parse time, so this file must be parsed AFTER the generated zoxide init at the GENERATED anchor (`__zoxide_z` in the def bodies below) and AFTER claude.nu at MODULES (`cc` in `zc`'s body). An unresolved `cc` silently binds to /usr/bin/cc, the C compiler: a reversed MODULES order produces no error at parse and a compiler invocation at runtime. Reverse the two anchors and type `zc` if you want to watch it happen.

THE RECENTS SEAM, NOW CLOSED (04-shell/07-quicklist): the real logger lives in recents.nu, sourced above this file at MODULES, and the four `_recents_add` call sites below re-bind to it at parse. The no-op shim this file used to carry is GONE — it existed only because an unresolved name binds as an EXTERNAL and would fail at runtime on every jump, which is a hazard only while the logger does not exist. Sourcing recents.nu above this file is the same mechanism the live config used (finder.nu sourced before the wrappers); recents.nu is its own module, and not quicklist.nu, because quicklist.nu's runner calls into finder.nu and so must be sourced BELOW it, on the other side of this file.

THE M-8 HAZARD, CORRECTLY ATTRIBUTED: a no-match `zoxide query` returns the EMPTY string, `__zoxide_z` hands that to the `cd` alias, and `mkcd` reads an empty argument as "no argument" and targets $env.HOME. The hazard is mkcd's empty-argument reading, not `__zoxide_z` itself. Every non-literal jump below is pre-flighted through `complete` and validated as an existing dir BEFORE anything reaches `cd`, so a miss never moves PWD — and a cancelled `zi`, whose empty selection walks the same road, is guarded the same way. _z_no_zoxide — the one message the USER-INVOKED entry points share (R3). Defined ABOVE its call sites, and that is load-bearing for the same reason the header gives for `cc` and `__zoxide_z`: nushell binds a def body's calls at PARSE time, so a helper defined below them would bind as an EXTERNAL and fail at runtime on the one path that is supposed to be the clean answer.

```
def --env _z_jump [rest: list<string>] {
```

_z_jump — the guarded jump. Returns true when the jump ran, false on a miss — and on a miss PWD is untouched (R6, M-8). The three literal arms of the generated `__zoxide_z` ([], ['-'], a single arg expanding to an existing dir) delegate directly; everything else is pre-flighted as a query so the empty no-match result never reaches `cd` → mkcd. On a genuine match the jump is still DELEGATED to `__zoxide_z` — R1's "wraps `__zoxide_z`" and R4's funnel (the `cd` inside it is the alias → mkcd) stay literally true — so the matched query runs twice: milliseconds, paid only on success.

```
if (which zoxide | is-empty) { _z_no_zoxide; return false }
```

ABOVE THE LITERAL ARMS, not at the query below: an ABSENT zoxide means an EMPTY generated init (the generator truncates on a missing tool), so `__zoxide_z` is not defined either and binds as an EXTERNAL — measured 2026-08-23, `z <existing dir>` answered `Command __zoxide_z not found`.

```
print -e ($q.stderr | str trim)
```

zoxide's own "no match found" surfaces; PWD stays put.

```
def --env --wrapped _z_nav [...rest: string] {
```

z (R1): a single arg that resolves to an existing FILE opens in $EDITOR instead of jumping, and file opens always log; otherwise it is a dir query, and the jump logs to the quicklist recents only when PWD actually moved — a failed `z` leaves no trace.

```
def --env --wrapped _zi_nav [...rest: string] {
```

zi (R2): the interactive picker. It shells out to `zoxide query --interactive`, which spawns fzf — the one accepted exception to epic I3's "tv owns every picker screen" (decided 2026-08-21, user; see 00-delivery/decisions/fzf). Queried DIRECTLY rather than via `__zoxide_zi`: R2 names the command, `__zoxide_zi` adds nothing but the unguarded `cd` — the zi-shaped M-8 hole: live, a cancelled picker hands "" to `cd` → mkcd → HOME. No --exclude is added: the live `__zoxide_zi` carries none (measured; recorded in decisions/fzf's closing note).

```
alias cdi = zi
```

cdi — the same picker under the name muscle memory reaches for. 04-shell/02's spec explicitly left this alias to this node.

```
alias zz = cd -
```

zz — step back to the previous directory (R3). Pairs with the bare-word fallback below: a bare unknown token jumps forward, `zz` steps back. `cd` is the funnel alias, so `-` reaches mkcd like any move.

```
def --env --wrapped zl [...rest: string] {
```

zl (R3): jump, then `la`. Dirs only — no file-opening branch, unlike `z`. On success the terminal shows the listing TWICE — zl's own plus the PWD hook's auto-list — which is exactly what the shipped manual entry says. No listing on a failed jump.

```
def --env --wrapped zc [...rest: string] {
```

zc (R3): jump, then Claude (`cc`). No launch on a failed jump — launching Claude in the un-jumped-to dir is the M-8 failure wearing a different hat.

```
def --env _z_fallback [] {
```

z as the default verb (R5–R7). A bare line whose first word is NOT a known command, path, or nu expression is treated as a zoxide navigation query — `proj` ⏎ jumps just like `z proj`, no prefix typed.

Nushell gives no clean hook for this: `command_not_found` can't cd (its env changes are discarded) and the unknown command always errors. So we jump from `pre_execution`, where a cd DOES persist, then bury the doomed command's "not found" by CLEARING the screen in `pre_prompt` (after the error has printed) and letting the next prompt redraw fresh in the jumped-to dir. A clear is the only scroll-safe wipe — the prompt usually sits at the bottom of the screen, so the error scrolls the view and any cursor-restore trick misses it; and reedline repaints over anything pre_prompt prints, so a post-clear `la` can't survive (the new-dir prompt is the jump's confirmation instead).

We jump ONLY on a genuine zoxide dir match, querying directly — never via `__zoxide_z`, whose empty no-match hand-off is the M-8 route to HOME. A no-match line falls straight through to the normal "command not found", and the screen is left untouched.

THE GUARD IS $nu.is-interactive, NOT THE ONE THE LIVE CONFIG USES: the live spelling, as a parenthesised `if` condition, captures stdout and is false unconditionally (the measurement at config.nu's PALETTE anchor), so the live fallback's guard never drew the line it meant to. $nu.is-interactive is the guard every shipped guard in this tree uses: fallback live in the REPL, inert under `nu -c`. The banned spelling is kept out of this file entirely, so a grep hit is proof of a regression.

```
let meta = ['|' '>' '<' ';' '&' '(' ')' '{' '}' '[' ']' '$' '`' '"' "'" '#' '^' '=' '!']
```

any shell/nu metacharacter means it is an expression or a real invocation — leave it.

```
if (which $first | is-not-empty) { return }
```

a resolvable name (builtin/alias/def/external) or a path-ish token is a real command.

```
if ($first | str starts-with '-') or ($first | str starts-with '/') or ($first | str starts-with '~') or ($first | str contains '/') or ($first in ['.' '..']) { return }
```

bail only on real path operators — a leading '/' or '~', any embedded '/' (so `./x`, `../x`, `~/x`, `a/b` are paths), a flag, or bare `.`/`..`. A dotdir NAME like `.files` is NOT a path operator, so it stays a valid zoxide nav target.

```
if (which zoxide | is-empty) { return }
```

candidate navigation: ask zoxide directly, jump only on a genuine dir match. SILENTLY, unlike the three user-invoked sites above (R2): nothing asked for zoxide here — this closure fires on EVERY unresolvable bare word — so a missing binary must leave the shell's OWN unknown-command error as the only thing printed. Measured 2026-08-23 with zoxide absent: two typos in one session produced FOUR error boxes unguarded, the first of each pair quoting this file and even offering the generated init's jump function as a did-you-mean, and the string `zoxide` appeared 8 times in the transcript; with the guard it is two boxes, both the shell's own, and the string `zoxide` appears NOT ONCE. (The name of the generated init's jump function is kept out of this body on purpose — its empty no-match hand-off is the M-8 route to HOME — so a grep of the source finds it only if that route has been reopened.)

```
_dirstack_push $env.PWD
```

cd in pre_execution may not trip the env_change PWD hook, so log the dirstack and the recents entry HERE, at jump time (mirrors the `z` wrappers); _dirstack_push dedups if the hook also fired. (`cd` → mkcd already recorded the new-shell start dir.)

```
$env.config.hooks.pre_execution = (
```

The jump reacts in pre_execution — a cd persists there, where `command_not_found` discards env changes.

```
$env.config.hooks.pre_prompt = (
```

…and the clear lands in pre_prompt, after the doomed error has printed. NO PWD APPEND BELONGS TO THIS NODE: the PWD hook may not fire for a cd made in pre_execution (R7), so this module's reaction points are pre_execution and pre_prompt, and config.nu keeps exactly two PWD append blocks (S.1's dirstack push, 04-shell/06's auto-list).

## `history.nu`

```
def _hist_cwd [] {
```

history.nu — directory-scoped history: the shared cwd query, the local Ctrl-R picker and the inline Up/Down cycle. Covers 04-shell/05-history R1–R3. DEFS ONLY: the six keybinding records live at config.nu's KEYBINDINGS anchor — that anchor's last-entry-wins promise is this node's R5 — no hook is appended and the config record is never written here, so the file parses standalone under `nu -n`. The name of the config record is kept out of this comment entirely, so a grep of the source finds a config write here only if one has been added.

THE DB PATH IS `$nu.history-path`, NEVER A LITERAL. Measured 2026-08-22 on the pinned 0.114.1: the constant honours XDG_CONFIG_HOME from the LAUNCH environment (env.nu's own assignment runs too late to move it) and follows the loaded config's history.file_format; under `env -i` with no XDG set it is ~/Library/Application Support/nushell/history.sqlite3. The live config's hardcoded path worked only because the LIVE wezterm.lua exports XDG_CONFIG_HOME — a line the repo's wezterm.lua deliberately omits — so a literal here would silently query a db no keystroke ever updates. The constant is the file reedline actually reads and writes, wherever the terminal's env puts it. The live literal spelling is kept out of this comment entirely, so a grep of the source finds it only if a literal has come back.

ALT-R'S TARGET IS NOT DEFINED HERE. `tv_shell_history` comes from the generated television init (`tv init nu`, written at apply time by home/run_after_generate-shell-init.sh, whose comment names this node). The `nu-history` cable channel behind it — the sqlite-aware override — belongs to 04-shell/04-television, which depends on this node and owns that file. Until it lands, Alt-R runs tv's builtin nu-history channel: degraded content, correct wiring. The cwd query, shared by the picker and the inline cycle (R1): this directory's distinct commands, newest use first, capped at 5000.

THE `\\:` IN `text.toml` IS TWO ESCAPES, NOT ONE. `home/dot_config/television/cable/text.toml`'s templates (`output`, `preview.command`, `preview.offset`, `ui.preview_panel.header`, `actions.edit.command`) all split on `\\:` in the TOML source. TOML's own escaping turns that into the single-backslash `\:` tv actually receives, which is the escaped-colon delimiter its template engine splits on — a bare `:` would also split on every colon inside the matched line, not just the field boundary, and a single un-escaped `\:` is invalid TOML. Anyone rewriting a `split:` template here needs both backslashes or the channel silently mis-splits.

The missing-db guard returns [] and precedes the open (D3): reedline creates the sqlite on the first interactive Enter, so a fresh machine (and any --no-history run) has none — unguarded, `open` throws, and every Up press and Ctrl-R becomes a red error at the prompt.

```
def tv_history_local [] {
```

Ctrl-R: television history picker, candidates pre-filtered to this directory and piped in on stdin — plain stdin mode, no channel argument, because the candidates ARE the cwd filter. Alt-R is the global route: tv's own tv_shell_history, from the generated init (see the header).

```
let cur = (commandline | str substring 0..(commandline get-cursor))
```

`0..cursor` is INCLUSIVE — exact at end-of-line, the position the picker is invoked from. Live quirk, carried verbatim (D5): a fix is a correction filed upward, not an edit here.

```
def --env _hist_local [--down] {
```

Up/Down: inline cwd-scoped history cycle. reedline's native traversal is global-only (no cwd filter), so this re-implements the cycle over just this directory's commands, newest-first, tracking position in $env across keypresses. Typing anything (buffer no longer matches what we last injected) resets to the newest entry. Shift+Up/Down keep reedline's native global traversal.

```
let np = ([([($pos + $dir) 0] | math max) ($n - 1)] | math min)
```

The clamp floors at 0 and ceils at n−1, so Down before any Up injects the NEWEST entry. Live quirk, carried verbatim (D5).

## `finder.nu`

```
export def --env finder [
```

finder.nu — the typed channel runner over `tv` (television): `finder`, the channel picker, the typed decoder, the open-by-type dispatcher, the --expect parser, the shell quoter and the cht → cht-query pipe. DEFS ONLY, and since 2026-09-01 that is all: the entry points `tv_finder` and `tv_remote` lived in config.nu rather than here, because they had to parse-bind `theme` (defined at the THEME anchor, after MODULES) and later `quicklist`, which a def in this earlier-sourced file could not. Both are gone with the three keybinding records that called them, and the ordering constraint they forced went with them — `finder` itself binds nothing defined below this file. The finder key is now `F3`, handled outside nushell entirely by `~/.local/bin/tv-go find`. The file parses standalone under `nu -n`.

tv LIMITATIONS (04-shell/04-television R7), each one measured: (a) tv REQUIRES a TTY. It panics ("Failed to create TUI instance") when run without a terminal, so every entry point is interactive-only. The guard is `$nu.is-interactive`, NOT `is-terminal --stdout`: measured on the pinned 0.114.1 (see config.nu's PALETTE anchor), a parenthesised `is-terminal --stdout` as an `if` condition captures stdout and is false unconditionally — on a terminal or off one. (b) The CLI `--keybindings` grammar is `key="action"` (e.g. enter="confirm_selection"), the INVERSE of the config-file `action = "key"` form. Verified: the config-file form is rejected by the CLI flag. (c) With `--expect`, stdout line 1 is the pressed key; a plain enter emits an empty first line.

THE UN-HIJACK RIDES EVERY INVOCATION. FOUR channels bind enter to an action instead of confirming (backlog M-9 counts three — `git-branch` is a fourth it undercounted, reported for the backlog): `text` and `recent-files` bind `actions:edit`, `zoxide` binds `actions:cd` (a nested `$SHELL` in the picked directory instead of moving the caller's shell), and `git-branch` binds `actions:checkout`. Passing `enter="confirm_selection"` unconditionally covers all four and whatever a new cable file does; tab multi-selects. Note `text` is our own local override, not the stock channel — it carries a local `output` template and a two-entry source list, so a reader sent upstream for it finds nothing. ── public entrypoint ──────────────────────────────────────────────────────── finder: run a tv channel and return the selection as structured nu data. --start : skip the channels picker and run this channel directly (e.g. `finder --start recent-dirs` drops straight into the recent-dirs channel).

```
error make { msg: "finder: interactive-only — tv requires a TTY" }
```

tv would panic without a TTY (limitation (a)); fail first, cleanly.

```
let unhijack = 'enter="confirm_selection";tab="toggle_selection"'
```

The un-hijack (R1) — on EVERY invocation, see the header.

```
if $channel == "cht" {
```

The cht → cht-query pipe (R5): ctrl-p carries the picked language into the query channel, whose source becomes that language's live topic list, each topic prefixed `<lang>/` so the confirmed line is a complete sheet id (`python/lambda`). A BUILD, not a port: the deployed finder.nu never implemented it. Plain enter on `cht` falls through as a raw pick.

```
for line in $entries { _recents_add "Any" $line "cht" }
```

04-shell/07 R2: a raw `cht` pick is a finder pick, so it logs too — below this branch's own emptiness guard, for the same reason the main branch logs below its decode check. `cht` is an untyped channel, so the kind is `Any` and quicklist's Any arm decides what `enter` may do with it.

```
if ($decoded | is-empty) {
```

An empty decode over a non-empty selection is an ERROR, not [] (R2b). Returning [] quietly is exactly what hid the dead Commits decode for the life of the live config. The check lives HERE, not in _finder_decode: 04-shell/07 reuses the decoder on single stored values, where a dead path is that entry's problem, not a failure.

```
for line in $entries { _recents_add (_finder_type $channel) $line $channel }
```

04-shell/07 R2 logs the pick HERE — the L-4 fix. Two things about this
line are load-bearing:
  * it is BELOW the empty-decode check, not above it. A pick whose
    channel and decoder disagree must never enter a log whose whole
    purpose is to be REPLAYED; the earlier comment sat above the
    decode and would have logged exactly those rows.
  * it stores the RAW pick line plus the channel's `produces` name, so
    `_recents_open` can re-decode the stored pair with the same
    `produces` and reproduce what `finder` returned here. One entry per
    selected row, because tab multi-selects.

```
def _finder_cht_query [lang: string, unhijack: string] {
```

── the cht-query step ────────────────────────────────────────────────────── _finder_cht_query: run the cht-query channel with its source overridden to the picked language's live topic list. nu has no `||`, so the fetch is a bash one-liner; sed prefixes every topic with `<lang>/`.

```
for line in $entries { _recents_add "ChtSheet" $line "cht-query" }
```

04-shell/07 R2, below this branch's empty-decode check for the same reason: a sheet pick is a finder pick.

```
def _finder_type [channel: string] {
```

── type lookup ───────────────────────────────────────────────────────────── _finder_type: the typed value a channel produces (R2). Known channels return typed values _finder_decode can parse into structured data; anything unknown passes raw strings. `recent-dirs` and `recent-files` are typed by the names their cable files actually carry (the L-3 fix: the live decoder typed a name no cable file has ever had, so recent-dir picks fell through to Any and came back as raw, unexpanded strings).

```
def _finder_pick_channel [] {
```

── channel picker ────────────────────────────────────────────────────────── _finder_pick_channel: choose a channel by fuzzy-searching tv's channel list. The candidate list is computed here and handed to the `channels` channel via --source-command (R5: the remote's own channel, overridden per call). esc → "" (the caller reads that as abort). NO non-tty fallback to "first channel" — the live one has that and it is wrong; callers guard on `$nu.is-interactive` before calling.

```
def _finder_shquote [p: string] {
```

── shell quoting ─────────────────────────────────────────────────────────── _finder_shquote: POSIX single-quote one path (everything inside '' is literal). NOTE: this is POSIX-shell quoting (sh/bash/zsh).

```
def _finder_shquote_list [ps: list] {
```

_finder_shquote_list: quote+join a list of paths for safe splicing.

```
def _finder_parse [raw: string] {
```

── tv --expect output decoder ────────────────────────────────────────────── _finder_parse: decode tv's `--expect` stdout into { key, entries }. Contract (limitation (c)): with --expect, line 1 is the pressed key; a plain enter emits an empty first line. Kept from live verbatim — 04-shell/07's quicklist runner reuses it.

```
let known = ["ctrl-p" "ctrl-b" "ctrl-n" "ctrl-r" "ctrl-o" "enter" "esc"]
```

`ctrl-o` was 06-help/03-browser's key — the `manual` channel's "open the entry's PRD". **That channel was deleted on 2026-09-02 and nothing binds `ctrl-o` any more**, so this list entry is dead: no runner passes `--expect ctrl-o`, and a key nobody expects is never the head of a row block. It is left in `known` rather than removed because the reason it had to be here is the live constraint and outlives the key — with an unknown head, the else-branch below returns the pressed key AS THE FIRST ENTRY, so any `--expect`ed key missing from this list silently yields a detail render for a nonexistent entry instead of opening anything. Add a key here in the same change that binds it.

```
def _finder_decode [stage] {
```

── typed decoder ─────────────────────────────────────────────────────────── _finder_decode: map a channel's raw tv output into real nu values keyed by `produces`. FileList → expanded, existing paths; GrepList → {file, line, text}; Commits → {hash}; ChtSheet → {sheet}; anything else passes raw strings.

```
$results | each { |line| { hash: ($line | str trim) } }
```

The L-2 fix: consume the emitted value WHOLE. git-log.toml's `output = "{strip_ansi|regex_extract:[0-9a-f]{7,}}"` has already reduced the entry to a bare hash — the extraction belongs to the CHANNEL, which uses that same template for its preview and its three actions; a second extraction here is the duplication that rotted (the live decoder split the bare hash again, read index 1 — empty — and the guard ate every row, so commit → git show never ran). The channel selects the hash BY PATTERN because it runs `git log --graph`: positional field 1 is `*` on a `| * <hash>` row and `|` on a `* | <hash>` row, and the channel now also drops the connector rows that carry no hash at all, so nothing reaches this decoder without one. The `^[0-9a-f]{7,}$` guard is KEPT, as a validity filter that now passes. Shape is {hash}: `subject` is dropped — a bare hash cannot fill it and nothing consumes it; a label would come from the channel's display template, never reconstructed here.

```
def --env _finder_open [sel: list] {
```

── open a selection by type ──────────────────────────────────────────────── _finder_open: act on a decoded selection by its produced shape (R3) — {file, line} (grep hit) → editor at line, {hash} (commit) → git show, {sheet} (cht.sh) → pager, else a path → cd if a dir, edit if a file. --env so a `cd` here reaches the shell.

── the 04-shell/07 seam, as built ────────────────────────────────────────── No _recents_* DEFS here: they live in recents.nu, sourced at MODULES ABOVE zoxide.nu and therefore above this file, so the three `_recents_add` CALLS above bind at parse. That direction is forced — nushell binds a def body's calls at parse time, so a later-sourced module could not have injected them, which is why the log is its own module rather than part of quicklist.nu (which must be sourced BELOW this file to reach `_finder_decode`, `_finder_open`, `_finder_parse` and `finder`). 04-shell/07 still owns the quicklist cable and its runner; the quicklist dispatch arm it had in config.nu's `tv_remote` went with that def on 2026-09-01, and Ctrl-Q is now the only way in.

## `quicklist.nu`

```
def _recents_entry [line: string] {
```

quicklist.nu — the quicklist RUNNER (04-shell/07-quicklist R3/R4): the `quicklist` command behind Ctrl-Q, plus the two dispatch helpers it uses. The log itself lives in recents.nu.

SOURCED AFTER finder.nu AT MODULES, and that is forced rather than tidy: nushell binds a def body's calls at PARSE time, and the bodies below call `_finder_decode`, `_finder_open`, `_finder_parse` and `finder`. recents.nu is on the OTHER side of finder.nu for the mirror-image reason — zoxide.nu and finder.nu both call `_recents_add` — which is why this node ships two modules and not one. config.nu's MODULES paragraph carries the same note.

THE GUARD IS `$nu.is-interactive`, NOT THE ONE THE LIVE CONFIG USES, and the live spelling is kept OUT OF THIS FILE ENTIRELY — including out of this comment — so that a grep hit is proof of a regression and never of a sentence explaining one. That is zoxide.nu's convention, for the same reason. Measured on the pinned 0.114.1 (config.nu's PALETTE anchor carries the measurement): the live spelling, used as a parenthesised `if` condition, captures stdout and is false unconditionally — on a terminal or off one — so it never drew the line it meant to.

`ctrl-r` HERE MEANS REPLAY AND COLLIDES WITH NOTHING. This is its own `tv` invocation, and the reedline Ctrl-R history binding is a different surface: reedline is not reading the keyboard while tv owns the terminal.

WHAT THE `Any` ARM IS FOR, since R3 leaves it undefined. The untyped channels — zoxide, git-branch, alias, env, nu-history, cht — log kind `Any`, which `_finder_decode` passes through as a bare string and `_finder_open`'s else-branch would `cd` if it were a directory and open in $EDITOR otherwise. For a branch name or an env var that means the editor on a file that does not exist. So an `Any` entry opens only when its value resolves to an existing path, and otherwise prints one line naming ctrl-r as the way to act on it. The alternative — not logging the untyped channels at all — was declined: it would empty "cross-channel recents" of most of its channels. _recents_entry: one TAB row from the cable's `output = "{}"` back into the record the dispatch helpers read. Every field is defaulted, `--empty` included, because a truncated row must degrade rather than raise: an unknown kind is `Any` (the least-privileged arm above) and an unknown cwd is the current directory (replay in place beats replay nowhere).

```
def --env _recents_open [entry] {
```

_recents_open (R3, `enter`): OPEN BY TYPE, reusing finder's decoder and its opener on a SINGLE stored value. That reuse is what finder.nu's own comment reserves — the empty-decode check lives in `finder` and not in `_finder_decode` precisely so "04-shell/07 reuses the decoder on single stored values", where a dead path is that one entry's problem and not a failure. The stored pair is the RAW pick line plus the channel's `produces` name, so this re-decode reproduces exactly what `finder` returned when the pick was made. --env so a `cd` from a directory entry reaches the shell.

```
def --env _recents_replay [entry] {
```

_recents_replay (R3, `ctrl-r`): cd to the directory the pick was made in, then re-run its originating channel THERE. NEW BEHAVIOUR, not a port: live, `finder` never logged (bug L-4), so every live entry carries channel `zoxide` and this path has never run for any other channel. A recorded cwd that no longer exists is skipped rather than raised on — the channel still opens, in the current directory. --env so both the `cd` and any `cd` the pick causes reach the shell.

```
export def --env quicklist [] {
```

quicklist (R3, R4): the runner. Guard, empty-state, ONE tv call, dispatch.

The un-hijack rides this invocation like every other (finder.nu's header): our own cable file binds no `enter`, but the flag costs nothing and survives someone adding one.

R4's empty state is a PRINT AND RETURN, never an empty picker — the shipped manual entry (help/shell.nuon, Ctrl-Q) already promises "an empty log prints a hint rather than an empty picker", and this is what makes that entry true. tv is not spawned at all on that path.

```
let parsed = (_finder_parse $raw)
```

_finder_parse, reused verbatim — which is what finder.nu's comment at that def reserves it for. With --expect, stdout line 1 is the pressed key and a plain enter emits an EMPTY first line.

## `copymode.nu`

```
def copymode [] {
```

copymode.nu — enter copy mode from the shell. Sourced by config.nu at the MODULES anchor.

REWRITTEN 2026-08-30 (07-multiplexer/09-manual-entries). It used to print an OSC 1337 SetUserVar that wezterm.lua's `user-var-changed` handler parsed off the pty — "the only route from a shell command into a GUI-only mode", which was true of WezTerm and is the kind of sentence that stops being true when the mode moves. Copy mode is tmux's now, and tmux's CLI *does* have an action for it, so the whole escape-sequence trick is gone: one command, addressed at the pane it was typed in.

`$env.TMUX` is the guard, not `which tmux`: what matters is whether THIS shell is inside a session, not whether the binary exists. Outside one there is no pane to freeze and nothing sensible to do but say so.

## `theme` (config.nu) and `theme.sh`

```
def --wrapped theme [...rest] {
```

theme: three lines over `~/.config/tinted-theming/tinty/theme.sh`, which is the whole theme system. `theme` runs `tv theme`; Enter prints the id and the shell hands it to `theme.sh --apply`, Esc prints nothing and plain `theme.sh` repaints the current scheme over whatever the preview left. `theme toggle` is `theme.sh --toggle`, the same action as F6.

theme.sh modes: plain (paint the current scheme — tinty's hook, tmux's client-session-changed hook, Esc), `--apply ID` (paint, record the pick as its variant's slot in `$XDG_STATE_HOME/tinted-theming/{dark,light}.txt`, then let `tinty apply` record it as current), `--toggle` (`--apply` the other variant's slot, gruvbox dark/light hard when empty), `--preview ID` (paint into a scratch conf, record nothing, print the swatch — the tv preview, so moving the cursor retints the whole terminal), `--list` (current, then every scheme of the same variant, one `rg` over the catalog — the tv source).

Why one bash script: every exec costs ~80 ms on this host (measured 2026-09-23). The old split — a nu module, a nu-sourcing tv source, a grep|sed preview script and a grep|sed hook — parsed the palette three times and made an apply take five seconds and F6 two. theme.sh parses the yaml with bash builtins and calls tmux once (`source-file` and `list-clients` in one command), so a paint is ~0.1 s; F6 paints before tinty records, so the colour changes first.

## `claude.nu`

```
def _claude_share [root: path, name: string] {
```

claude.nu — the Claude Code launchers `cc` and `cr` (04-shell/08). Sourced by config.nu at the MODULES anchor.

THE PROFILE MODEL, AND WHY THE MACHINERY BELOW IS DORMANT (R3). A login profile is a subdir of ~/.claude carrying its own settings.json. With no such subdir, `cc` launches Claude directly and touches nothing — no picker, no CLAUDE_CONFIG_DIR, no read or write of .last-login — so the single-login case pays nothing for the machinery. Creating a second login is OUT-OF-BAND, not an in-picker entry: `mkdir ~/.claude/<name>` and copy ~/.claude/settings.json into it — the copy is what makes detection see it. From then on `cc` offers the picker (last-used first, bare Enter relaunches it) and the first pick of the new name completes the seeding via _claude_share. _claude_share — an account profile isolates only credentials + settings; the heavy, meant-to-be-shared state (plugins, project/session history, caches…) is symlinked back to the top-level ~/.claude so it stays reachable from every login. .claude.json / settings are seeded once from the default so a new account starts configured (enabled plugins, MCP servers, project trust) but then diverges. The credentials file is never copied — that is what makes a new profile log in fresh. Links and copies that already exist are skipped, so this is idempotent and runs on every non-default pick.

```
def _claude_profiles [] {
```

_claude_profiles — the subdir profile names: [] when ~/.claude does not exist, else the basenames of subdirs carrying a settings.json, sorted, `default` filtered out (the top-level ~/.claude is always offered as "default" by the picker). Claude's own internal dirs (projects, sessions, cache…) never carry a settings.json, so they self-filter.

Detection is by settings.json, NOT the credentials file: on macOS Claude keeps credentials in the login Keychain (service "Claude Code-credentials" plus a per-CLAUDE_CONFIG_DIR hashed entry), so no per-profile credentials file is ever written — the old check found nothing and the picker came up empty on Mac. settings.json is seeded by _claude_share for every profile and works on both Linux (file creds) and macOS (Keychain).

```
def _claude_login [profiles: list<string>] {
```

_claude_login — multi-profile only: pick a login and return its CLAUDE_CONFIG_DIR (~/.claude for "default"). The last-used name (recorded in ~/.claude/.last-login) is listed first, so a bare Enter relaunches it. Returns null on cancel (Esc / empty selection).

The picker is tv (epic invariant I3: tv owns every picker screen), as an AD-HOC channel: --source-command emits the ordered names, --no-sort keeps that order (last-used stays first), --input-header labels it, --inline keeps it at the prompt line. No cable file and no read of the television config — those belong to 04-television.

```
def _claude_run [args: list<string>] {
```

_claude_run — the R3 fork: with zero subdir profiles launch directly and touch nothing; otherwise pick a login and scope Claude to it.

```
def --wrapped cc [...args: string] { _claude_run $args }
```

`--wrapped`, and the live plain `def` is a defect not to copy: measured on the pinned nu 0.114.1, `def f [...args: string]` rejects `f --foo bar` with nu::parser::unknown_flag, so the live `cc` could not pass any flag-shaped argument at all. --wrapped delivers them intact — `cc --model opus`, `cc -p …`, `cc --resume` all reach claude — which is what makes the manual's "Arguments pass straight through" true.

```
def --wrapped cr [...args: string] { _claude_run (["--resume"] ++ $args) }
```

cr — like cc, but resume a session within the chosen profile.

## `pass.nu`

```
def "nu-complete pass" [] {
```

pass.nu — Nushell completion for `pass` (the unix password manager). Sourced by config.nu at the MODULES anchor. `pass` ships bash/zsh/fish completions but none for Nushell, so this declares a known-external signature whose rest-arg completer offers both the subcommands and the live entry names from the store. Declaring `extern` only adds completion; undeclared flags (e.g. `pass generate -n -c`) still pass straight through to the real binary. Entry names = every *.gpg under the store, with the store prefix and the .gpg suffix stripped (so `email/personal.gpg` completes as `email/personal`). The subcommands let `pass <tab>` also surface the verbs. The store is $env.PASSWORD_STORE_DIR when the environment provides one, else the documented default ~/.password-store. A store that does not exist completes the verbs alone.
