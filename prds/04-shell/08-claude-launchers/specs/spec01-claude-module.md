# spec01 — `claude.nu`: `cc`/`cr`, with the profile machinery dormant

Delivers R1–R3 as a new module, `home/dot_config/nushell/claude.nu`, sourced
at config.nu's MODULES anchor. The live implementation at
`~/.config/nushell/config.nu:155-243` is the model; what does NOT survive the
port: the always-on picker (R3 inverts it), the in-picker "＋ new login"
entry (D5), `input list` as the picker surface (D4), and the plain `def`
that cannot pass flags through (D2). `cl`, `jj` and `cl.py` are out of scope
by the PRD and never enter this tree.

**Est:** 1.5h

**Footprint:** `home/dot_config/nushell/claude.nu` (create),
`home/dot_config/nushell/config.nu` (MODULES anchor: one `source` line),
`tests/nushell-core.sh` (one `cp` line in `mk_machine`),
`tests/nushell-aliases.sh` (one `cp` line in staging),
`tests/shell-listing.sh` (one `cp` line in staging)

## Exact files touched

- **create** `home/dot_config/nushell/claude.nu` → deploys to
  `~/.config/nushell/claude.nu`. Contents in parse order:
  1. A header comment carrying the profile model: a profile is a subdir of
     `~/.claude` holding its own `settings.json`; with no such subdir `cc`
     launches directly and touches nothing; creating a second login is
     out-of-band — `mkdir ~/.claude/<name>` and copy `~/.claude/settings.json`
     into it — after which the picker appears and first pick completes the
     seeding (D5).
  2. `_claude_share [root: path, name: string]` — ported from live `:161-183`
     unchanged in behavior: symlink the heavy shared items (the live list,
     verbatim: `plugins projects sessions session-env history.jsonl cache
     file-history shell-snapshots agent-memory hooks hub jobs plans backups
     paste-cache context-mode debug tasks teams telemetry`) from `$root` into
     the profile, skipping links that exist; copy `.claude.json`,
     `settings.json`, `settings.local.json` once, skipping files that exist.
     Idempotent, so it runs on every non-default pick. The credentials file
     is never copied — that is what makes a new profile log in fresh.
  3. `_claude_profiles []` — return the subdir profile names: `[]` when
     `~/.claude` does not exist; else the basenames of subdirs carrying a
     `settings.json`, sorted, `default` filtered out. Detection is by
     `settings.json`, NOT `.credentials.json`, and the live comment's reason
     is carried: on macOS Claude keeps credentials in the login Keychain
     (service `Claude Code-credentials` plus a per-CLAUDE_CONFIG_DIR hashed
     entry), so no per-profile credentials file is ever written and the old
     check found nothing.
  4. `_claude_login [profiles: list<string>]` — multi-profile only. Build
     `ordered`: `["default"] ++ $profiles`, then move the `.last-login` name
     (from `~/.claude/.last-login`, if present) to the front. Run the tv
     picker (D4); empty selection → return null. A non-default pick:
     `mkdir` the profile dir, run `_claude_share`. Save the picked name to
     `.last-login`. Return the profile's dir (`~/.claude` for `default`).
  5. `_claude_run [args: list<string>]` — the R3 fork:
     - `_claude_profiles` empty → `^claude --dangerously-skip-permissions
       ...$args` directly. No picker, no `CLAUDE_CONFIG_DIR`, no read or
       write of `.last-login` — the single-login case pays nothing.
     - otherwise → `_claude_login`; null → return without launching; else
       `with-env { CLAUDE_CONFIG_DIR: $dir } { ^claude
       --dangerously-skip-permissions ...$args }`.
  6. `def --wrapped cc [...args: string] { _claude_run $args }` (R1) and
     `def --wrapped cr [...args: string] { _claude_run (["--resume"] ++
     $args) }` (R2).
- **edit** `config.nu`: `source ~/.config/nushell/claude.nu` under
  `# ── MODULES ──`, after the `pass.nu` line. A `source` of a missing file
  is a parse error that discards the whole of `config.nu` — the definitions
  above the failing line as well as those below. Interactively the shell
  still reaches a prompt, so the result is a working but naked REPL; `nu -c`
  prints the error, never runs the command, and exits 1. The GENERATED
  anchor in `config.nu` carries the measurement. The module and the line
  therefore land in one change; chezmoi deploys both in the same apply.
- **edit** the three gates that stage config.nu's sourced modules — the
  moment config.nu sources `claude.nu`, every hermetic check in them dies
  with `nu::parser::sourced_file_not_found` (the spec02-pass-completion D1
  precedent, third repetition): one `cp` of the repo's `claude.nu` beside
  `pass.nu` in `tests/nushell-core.sh` `mk_machine`, in
  `tests/nushell-aliases.sh`'s staging, and in `tests/shell-listing.sh`'s
  staging. Each line carries a comment naming this node; nothing else in
  those files is touched.

## Decisions

**D1 — a module at MODULES, not a block in config.nu.** S3.14's anchor map
assigns every config.nu anchor to another node (ALIASES is S.2's, LISTING
S.3's, THEME S.9's) and names MODULES as "where later nodes source their own
new files". `pass.nu` is the precedent, including the staging edits it
forced. This also keeps the config.nu churn to one line on a file the
06-listing lane holds right now.

**D2 — `def --wrapped`, and the live plain `def` is a defect not to copy.**
Measured on this machine's nushell: `def f [...args: string]` rejects
`f --foo bar` with `nu::parser::unknown_flag`; `def --wrapped` delivers
`--foo bar` intact. The shipped manual entry for `cc` says "Arguments pass
straight through", and the live `def cc [...args]` cannot pass any
flag-shaped argument at all. `--wrapped` is what makes the manual's sentence
true; `cc --resume`, `cc --model …`, `cc -p …` all reach claude.

**D3 — "single profile" means zero subdir profiles.** `~/.claude` absent, or
present with no `<name>/settings.json` subdir, is the single-login case: the
top-level `~/.claude` is the only login and claude finds it on its own, so
`CLAUDE_CONFIG_DIR` stays unset. The machinery R3 names activates on the
first real subdir profile.

**D4 — the picker is tv, as an ad-hoc channel; `input list` does not
survive the port.** Epic invariant I3: tv owns every picker screen, fzf is
the one recorded exception, and "a second picker outside tv is a new
decision, not an appeal" — so the live `input list --fuzzy` picker would be
exactly the second exception this node has no authority to mint. Measured on
the installed television 0.15.9: with no channel argument,
`--source-command` creates an ad-hoc channel; `--no-sort` preserves source
order; `--input-header` labels it; `--inline` (or `--height`) keeps it at
the prompt line instead of a full screen. So the picker is one `^tv` spawn —
source emits `ordered` one name per line, `--no-sort` so last-used stays
first and bare Enter relaunches it, header `claude login`, selection read
from stdout, empty stdout (Esc) → cancel. No cable file and no read of the
television config: those belong to [`04-television`](../../04-television/prd.md)
(S.5), which is not one of this node's deps. The `tv` binary itself comes
from the required package set
([P.2](../../../05-platform/02-package-provisioning/packages-installer/prd.md)),
and the picker path is unreachable until a second profile exists, so the
fresh-machine acceptance never touches it.

**D5 — no "＋ new login" entry; creating a profile is out-of-band.** R3
lists what activates once a second profile exists — `_claude_share` seeding,
keychain-aware detection, `.last-login` ordering — and an in-picker creation
flow is not on the list; the PRD's own acceptance says "after creating a
second profile", not "after picking new login". Under R3 the entry would
also be unreachable for profile #2 (the picker only shows once two exist).
Creation is `mkdir ~/.claude/<name>` plus copying `~/.claude/settings.json`
into it — the copy is what makes detection see it — and first pick completes
the seeding. Documented in the module header, where the gesture will be
looked for.

## Hands off the manual

`home/dot_config/nushell/help/shell.nuon` already carries the `cc [...args]`
and `cr [...args]` entries, sourced to this PRD, describing exactly this
behavior — direct launch with one login, pass-through args, the machinery
waking only on a second profile. Do not edit them: a `use` edit invalidates
its review digest in `use-review.nuon`. If the implementation is forced to
diverge, file a correction instead.

## Hand-off — 03-zoxide's `zc` and the C compiler

[`03-zoxide`](../../03-zoxide/prd.md) depends on this node and its `zc`
names `cc` inside a def body. Nushell binds a def body's command calls at
parse time, and an unresolved `cc` binds to the **external** `cc` —
`/usr/bin/cc`, the C compiler — with no error and no warning. `zc`'s def
must therefore be parsed after config.nu's
`source ~/.config/nushell/claude.nu` line. Recorded here for 03's analyst;
nothing in this spec depends on it.

## Acceptance

Hermetic = scratch HOME via `env -i`, generated-init stubs, the repo's
managed nushell files copied in, a recording `claude` stub and a poison `tv`
stub first on PATH. spec02's gate holds every box; the inline runs below are
the smoke check.

- [x] Hermetic, no `~/.claude` in the scratch HOME: `cc foo` reaches the
      claude stub as `--dangerously-skip-permissions foo`, with
      `CLAUDE_CONFIG_DIR` unset in the stub's environment; the poison `tv`
      was never invoked; `.last-login` was not created.
- [x] Hermetic: `cr x` reaches the stub as
      `--dangerously-skip-permissions --resume x`.
- [x] Hermetic: `cc --model opus` reaches the stub with both tokens intact —
      the D2 check, which the live `def` fails.
- [x] Hermetic, `~/.claude/work/settings.json` present and a `tv` stub
      printing `work`: `tv` runs exactly once; the stub claude runs with
      `CLAUDE_CONFIG_DIR` ending in `.claude/work`; `work/plugins` is a
      symlink to the root `plugins`; `work/.claude.json` is a regular-file
      copy; the pre-existing `work/settings.json` is byte-unchanged;
      `.last-login` reads `work`.
- [x] Hermetic, same layout, `tv` stub printing nothing: the claude stub is
      never invoked and `cc` returns cleanly.
- [x] `/usr/bin/grep -c 'input list' home/dot_config/nushell/claude.nu` is 0,
      and `cl.py`, `def cl`, `def jj` appear nowhere in the managed nushell
      tree.
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh` and
      `bash tests/shell-listing.sh` stay green after the staging edits —
      `EXIT=0`, `CHECKS: 39 run, 39 passed, 0 failed` / `EXIT=0`, and
      `EXIT=0`.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-claude.sh          # spec02's gate; covers every box above
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
/usr/bin/grep -n 'claude.nu' home/dot_config/nushell/config.nu   # one source line, MODULES anchor
```
