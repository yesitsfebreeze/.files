# spec02 — the zoxide gate: tests/shell-zoxide.sh, registered

Delivers this node's standing proof: a gate script holding spec01's
acceptance to executable checks, plus its registration in the wave
registry. New file — the three gates spec01 adds staging lines to belong
to other nodes; their harness patterns are followed, not forked.

**Est:** 2.5h

**Footprint:** `tests/shell-zoxide.sh` (create), `gates/waves.tsv`

## Shape

`bash tests/shell-zoxide.sh [--tree|--hermetic]`, no argument runs both.
Source `gates/lib.sh`. Follow `tests/nushell-core.sh`'s safety rules —
measured failures, not style: `/usr/bin/grep` always (bare `grep` is
ugrep here); every nu run under `env -i HOME="$S"` with a scratch HOME;
never snapshot `~/.config/nushell` wholesale; `~/.cache/nushell` must not
exist when the gate finishes; nothing installed, live tree untouched.
Copy the pty runner from `tests/shell-listing.sh` (the winsize-setting
variant — the fallback and `zl` checks assert listings and screen
clears, and a 0-column pty fails them for the wrong reason).

No `--apply` stage, and say so in the header: S.1's gate already proves
the managed tree deploys byte-identical, and `zoxide.nu` rides the same
path as `pass.nu` and `claude.nu`.

**The fixture init.** The scratch machines stage, at
`~/.cache/nushell/init/zoxide.nu`, not the poison one-liner but a
heredoc fixture carrying the generated init's two defs verbatim
(`__zoxide_z` with its three match arms and query, `__zoxide_zi`, the
`z`/`zi` aliases; header comment naming `zoxide init nushell` 0.10.0 as
the source) — spec01's module names `__zoxide_z` in def bodies, and with
the poison stub those names would bind as externals at parse. The
`zoxide` BINARY is a per-check stub: it appends its argv to a log and
prints/exits whatever the check sets, so "queried once", "never
queried" and the no-match branch are all countable and controllable.
Also on PATH: a recording `nvim` (the `$env.EDITOR` target), a recording
`claude`, which also records its `pwd`, and a poison `cc` for the
ordering counterfactual. Also staged: `pass.nu`, `claude.nu`,
`theme.nu`, `dirstack.nu`, `zoxide.nu` at the literal paths config.nu
sources.

## --tree: the managed files as text

Each ordering or absence claim carries a counterfactual — a deliberately
broken copy in scratch that must FAIL the same check.

- `source ~/.config/nushell/zoxide.nu` sits under `# ── MODULES ──`,
  AFTER the `claude.nu` line and before `# ── PALETTE ──`; the ten S.1
  anchors are present once each, in order (own grep — never call into
  another gate). Counterfactual: a copy with the two MODULES lines
  swapped fails the ordering check (and the hermetic stage executes why).
- `zoxide.nu` defines, in this parse order: `_recents_add` (the D2
  shim), `_z_jump`, `_z_nav`, `_zi_nav`, the aliases `z`, `zi`, `cdi`,
  `zz`, then `zl`, `zc`, `_z_fallback`, one `pre_execution` append, one
  `pre_prompt` append. Counterfactual: a copy with `alias zi` moved
  above `def --env --wrapped _zi_nav` fails.
- The guard is `$nu.is-interactive`; `is-terminal` appears nowhere in
  `zoxide.nu` (D3, the PALETTE-anchor measurement). Counterfactual: a
  copy with the live guard spelling fails.
- Both non-interactive query spawns carry `--exclude $env.PWD` and pipe
  through `complete`; `_zi_nav`'s spawn carries `--interactive` and no
  `--exclude` (decisions/fzf closing note: the live `__zoxide_zi` has
  none). `^fzf` is spawned nowhere in the managed nushell tree — fzf is
  reached only inside the zoxide binary (epic I3's named exception).
- Absences (D4): `$env.config.hooks.env_change.PWD` has 0 hits in
  `zoxide.nu`, and config.nu holds exactly two PWD append blocks — the
  dispatch anticipated a third; R7 (the PWD hook may not fire from
  pre_execution) is why there is none, and this check is where that
  reason is enforced. `__zoxide_z` appears in `_z_fallback` 0 times (R6:
  the fallback queries directly).
- Exactly four `_recents_add ` call sites besides the shim's own `def`
  line — `_z_nav`'s file branch (`"FileList"`), `_z_nav`'s moved-only
  dir branch, `_zi_nav`'s moved-only branch, `_z_fallback`'s jump — each
  with channel `"zoxide"`. The shim's header names 04-shell/07 and the
  delete-and-source-above hand-off. Counterfactual: a copy with the
  fallback's call site dropped fails the count.
- The six `shell.nuon` entries this node must keep true (`z <query>`,
  `zi`, `zz`, `zl <query>`, `zc <query>`, `<word>`) are read, not
  rewritten: assert each `source:` names this PRD and that the gate's
  own sha over `shell.nuon` is unchanged at exit.

## --hermetic: a real nushell in a scratch HOME

- `z proj`, stub returning `$S/home/proj`: PWD is that dir;
  `startdir.txt` holds it (the funnel ran — R4); the zoxide stub's log
  shows `query --exclude <old PWD> -- proj`.
- `z nomatch`, stub exits 1 with `zoxide: no match found` on stderr:
  PWD unchanged, **not** HOME (M-8), `startdir.txt` unchanged, the
  message surfaced on stderr, `nvim`/`claude` logs empty.
- `z <file>` where the file exists: `nvim` log holds the expanded path;
  PWD unchanged; the zoxide stub never invoked.
- `zz` after two moves toggles back (PWD comparison across `cd a; cd b;
  zz`).
- `zi` with the stub printing a dir on `--interactive`: PWD moves there
  through the funnel (`startdir.txt`); `cdi` runs the same route.
  Cancel (stub prints nothing, exits 130): PWD unchanged, exit clean,
  nothing on stderr but the stub's own silence.
- pty `zl proj`: the canary filename in the fixture dir appears exactly
  twice — `zl`'s own `la` plus the PWD hook's (the manual's double
  listing, proven). `zl nomatch`: canary appears zero times, PWD
  unchanged.
- `zc proj`: `claude` log holds `--dangerously-skip-permissions` and a
  recorded `pwd` of the fixture dir. `zc nomatch`: claude log unchanged.
- **Ordering counterfactual, executed:** against a scratch copy of
  config.nu with the two MODULES source lines swapped (zoxide.nu before
  claude.nu), `zc proj` trips the poison `cc` (`REAL-INVOCATION cc` on
  stderr) and the real `claude` log stays empty — nushell bound the def
  body's `cc` to the external. The correct config run above never trips
  it. This is the 08-claude-launchers spec01 hand-off as a check that
  can fail.
- pty fallback, happy path: type a bare unknown word (stub returns the
  fixture dir) → PWD is the dir, `dirs.txt` holds it (R7's jump-time
  push), the recents shim is a no-op so nothing else is asserted there,
  and exactly one `[2J` appears in the captured buffer; a second
  typed `cd` produces no further clear (`_NAV` was reset).
- pty fallback, negative triggers: `ls | nope-xyz` (metacharacter),
  `./x` (path-shaped), `-foo` (flag) — the zoxide stub's log gains no
  `query` entry, PWD unchanged, the ordinary error surfaces. A dot-NAME
  (`.files`, stub returning a dir) does jump.
- pty fallback, no match: unknown word, stub exits 1 → no `[2J`, PWD
  unchanged, `command not found` visible in the buffer, `dirs.txt`
  unchanged.
- `nu -c 'print HOOKS-OK'` with the module staged: exit 0, stderr
  empty; `$env.config.hooks.pre_execution | length` and
  `... pre_prompt | length` each report exactly one appended entry from
  this module (counted relative to a machine staged without it — a
  scratch config copy with the zoxide source line removed).

## Registration

Append ` | external bash tests/shell-zoxide.sh` to wave 4's `gates` cell
in `gates/waves.tsv` — S.4 is a wave 4 task and the cell already carries
that wave's other gates. `external` because the script lives in
`tests/`; `gates/selftest.sh` reports it unverified-by-contract, and the
counterfactuals above are this script's own falsification.

## Acceptance

- [x] `bash tests/shell-zoxide.sh` exits 0 on the finished spec01 work,
      printing one `chk` line per check above.
- [x] Every counterfactual copy fails its check — shown in the gate's
      own output, not asserted in prose.
- [x] `gates/waves.tsv` wave 4 names the gate; `bash gates/selftest.sh`
      still exits 0.
- [x] `~/.cache/nushell` does not exist after a full run, and the shas
      of the managed nushell files and `shell.nuon` are unchanged by
      running the gate.
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh`,
      `bash tests/shell-listing.sh` and `nu tests/help-content-model.nu`
      still exit 0.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-zoxide.sh
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
nu tests/help-content-model.nu
bash gates/selftest.sh
/usr/bin/grep -n 'shell-zoxide' gates/waves.tsv   # wave 4 row
```
