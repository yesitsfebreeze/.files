# spec02 — the launcher gate: tests/shell-claude.sh, registered

Delivers this node's standing proof: a gate script holding spec01's
acceptance to executable checks, plus its registration in the wave registry.
New file — `tests/nushell-core.sh`, `tests/nushell-aliases.sh` and
`tests/shell-listing.sh` belong to other nodes (spec01 adds one staging line
to each and nothing more); their harness patterns are followed, not forked.

**Est:** 1.5h

**Footprint:** `tests/shell-claude.sh` (create), `gates/waves.tsv`

## Shape

`bash tests/shell-claude.sh [--tree|--hermetic]`, no argument runs both.
Source `gates/lib.sh`. Follow `tests/nushell-core.sh`'s safety rules — they
are measured failures, not style: `/usr/bin/grep` always (bare `grep` is
ugrep here); every nu run under `env -i HOME="$S"` with a scratch HOME;
never snapshot `~/.config/nushell` wholesale; `~/.cache/nushell` must not
exist when the gate finishes; nothing installed, live tree untouched. No pty
runner is needed: every launcher path ends in an external spawn, so
recording stubs on PATH observe everything a pty could.

No `--apply` stage, and say so in the header: S.1's gate already proves the
managed nushell tree deploys byte-identical through a real `chezmoi apply`,
and `claude.nu` rides the same deploy path as `pass.nu`.

## --tree: the managed files as text

Each ordering or absence claim carries a counterfactual — a deliberately
broken copy in scratch that must FAIL the same check.

- `source ~/.config/nushell/claude.nu` sits under `# ── MODULES ──`, after
  the `pass.nu` line and before `# ── PALETTE ──`; the ten S.1 anchors are
  present once each, in order (own grep — do not call into another gate).
- `claude.nu` defines, in this parse order: `_claude_share`,
  `_claude_profiles`, `_claude_login`, `_claude_run`, `def --wrapped cc`,
  `def --wrapped cr`. Counterfactual: a copy with `--wrapped` stripped from
  `cc` fails the check.
- `--dangerously-skip-permissions` appears in `_claude_run`'s spawn, and
  `cr`'s body carries `--resume`.
- The tv spawn carries `--no-sort` (last-used stays first — bare Enter
  relaunches it) and the detection predicate is `settings.json`, not
  `.credentials.json`. Counterfactual: a copy detecting by
  `.credentials.json` fails.
- Absences, each 0 hits in the managed nushell tree: `input list` in
  `claude.nu` (epic I3 — the picker is tv); `cl.py`; `def cl`; `def jj`
  (the PRD's out-of-scope list).
- The two `shell.nuon` entries this node must keep true (`cc [...args]`,
  `cr [...args]`) are read, not rewritten: assert their `source:` names this
  PRD and that the gate's own sha over `shell.nuon` is unchanged at exit.

## --hermetic: a real nushell in a scratch HOME

Staging mirrors `mk_machine`: generated-init stubs, the repo's `config.nu`,
`env.nu`, `dirstack.nu`, `pass.nu`, `claude.nu` at the literal paths
config.nu sources. A stubs dir first on PATH holds a recording `claude`
(appends its argv and `$CLAUDE_CONFIG_DIR` to a log, exits 0) and a `tv`
whose behavior each check sets; both record every invocation so "exactly
once" and "never" are countable.

- No `~/.claude`: `cc foo` → claude log holds exactly
  `--dangerously-skip-permissions foo`, `CLAUDE_CONFIG_DIR` unset; tv log
  empty; `~/.claude/.last-login` does not exist.
- `~/.claude` with a top-level `settings.json` only (still a single login):
  same behavior — no picker, no `CLAUDE_CONFIG_DIR`.
- `cr x` → `--dangerously-skip-permissions --resume x`.
- `cc --model opus` → both tokens reach the stub intact (the `--wrapped`
  check; the live plain `def` fails it with `unknown_flag`).
- Multi-profile fixture — `~/.claude/work/settings.json`, root `plugins/`
  dir, root `.claude.json`, tv stub printing `work`: tv invoked exactly
  once; claude ran with `CLAUDE_CONFIG_DIR` ending in `.claude/work`;
  `work/plugins` is a symlink to the root `plugins`; `work/.claude.json` is
  a regular file; the fixture's `work/settings.json` byte-unchanged (`cmp`);
  `.last-login` reads `work`.
- Ordering: write `.last-login` = `work`, add a second profile `play`; the
  tv stub records its argv; the recorded `--source-command` emits `work`
  before `default` and `play`.
- Cancel: tv stub printing nothing → claude log unchanged, `cc` exits 0.
- Seeding is idempotent: run `cc` twice against the same fixture — second
  run adds no new symlinks, rewrites nothing, and still launches.

## Registration

Fill wave 5's empty `gates` cell in `gates/waves.tsv` with
`external bash tests/shell-claude.sh` — S.8 is a wave 5 task and the cell is
legally empty only while the wave is pending. `external` because the script
lives in `tests/`; `gates/selftest.sh` reports it unverified-by-contract
rather than failing, and the counterfactuals above are this script's own
falsification.

## Acceptance

- [x] `bash tests/shell-claude.sh` exits 0 on the finished spec01 work,
      printing one `chk` line per check above (49 run, 49 passed).
- [x] Every counterfactual copy fails its check — shown in the gate's own
      output, not asserted in prose.
- [x] `gates/waves.tsv` wave 5 names the gate (registered through the lane
      holding that file); `bash gates/selftest.sh` still exits 0.
- [x] `~/.cache/nushell` does not exist after a full run, and the shas of
      the managed nushell files and `shell.nuon` are unchanged by running
      the gate.
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh`,
      `bash tests/shell-listing.sh` and `nu tests/help-content-model.nu`
      still exit 0 — `EXIT=0`, `CHECKS: 39 run, 39 passed, 0 failed` /
      `EXIT=0`, `EXIT=0`, and `ok`.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-claude.sh
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
nu tests/help-content-model.nu
bash gates/selftest.sh
/usr/bin/grep -n 'shell-claude' gates/waves.tsv   # wave 5 row
```
