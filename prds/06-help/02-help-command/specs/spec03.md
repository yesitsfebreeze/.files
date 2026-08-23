# spec03 — `tests/shell-help.sh`: the gate, and its wave registration

Delivers the standing check for spec01 and registers it in the wave
registry. House shape: `--tree` proves the managed files as text with a
counterfactual per ordering/absence claim, `--hermetic` proves behavior in
a real nushell under a scratch HOME; no arg runs both. Uses `gates/lib.sh`
the way the sibling shell gates do; `/usr/bin/grep` always (plain `grep`
resolves to ugrep here); every nu run under `env -i HOME=<scratch>` with
`XDG_CONFIG_HOME` pinned; live tree untouched, `~/.cache/nushell` absent
when the gate finishes.

**Est:** 2h

**Footprint:** `tests/shell-help.sh` (create), `gates/waves.tsv` (wave-5
gates cell — **shared registration cell**, one appended `|` segment)

## Stages

**`--tree`** — text over `home/dot_config/nushell/{config.nu,help.nu}` and
the sibling gates. Each check is a function so its counterfactual (a broken
scratch copy) runs the SAME check and must FAIL:

1. config.nu order under MODULES: `source …history.nu` < `use std/help` <
   `alias core-help = help` < `source …help.nu` < `# ── PALETTE ──`, each
   present exactly once. Counterfactual: a copy with the `use` moved below
   the help.nu source line fails (that ordering is D1/D2 — the capture must
   parse before the shadow).
2. help.nu purity (the history.nu precedent): `def help [` present once;
   zero hits for `upsert keybindings` and `$env.config`.
   Counterfactual: appending an `$env.config` write to a copy fails.
3. R8 no-spawn: `\^(nvim|wezterm|git|tv)` has zero hits in help.nu.
   Counterfactual: a copy with `^git log` inserted fails.
4. Corpus path: help.nu reads `$nu.default-config-dir`; zero hits for
   `dot_config` or `/Users/` (no repo path hardcoded into a deployed file).
5. Staging: each of the six sibling gates (`nushell-core`,
   `nushell-aliases`, `shell-listing`, `shell-zoxide`, `shell-history`,
   `shell-claude`) carries exactly one `help.nu` cp line.

**`--hermetic`** — scratch HOME: cp `config.nu`, `env.nu`, `dirstack.nu`,
`pass.nu`, `theme.nu`, `claude.nu`, `zoxide.nu`, `history.nu`, `help.nu`
and the `help/` dir (all seven data files — the gate is the one consumer
that needs the corpus staged) into `$M/home/.config/nushell/`; one-line
generated-init stubs at `~/.cache/nushell/init/`; a `fakecmd` external stub
and a poison `tv` stub first on PATH. Probes, each `chk_ok`:

1. `help`: all nine topic ids, per-topic counts summing to the corpus
   entry count (computed from the staged `.nuon` files, never hardcoded —
   the corpus grows), the four first keys, the delegation sentence.
2. `nu -c 'help' | complete`: zero `\x1b` bytes (R7).
3. `help navigate`: contains `ls`, `ls -D`, `l / ll / la`, and the zoxide
   suite including the bare-word fallback row.
4. `help find | to json`: parses (python `json.loads`), and the `key`
   column exists (`help find | where key =~ 'ctrl'` runs clean).
5. `help select`: the shift-select entries return, with `topic` column.
6. `help ls`: tail contains `Usage:` and `> ls`; `help --entry ls` output
   byte-equal to `ls --help` output (R10 — the two are indistinguishable
   at the call site, so the gate holds them identical).
7. `help ctrl-r`: mentions the directory scope and `Alt-R`.
8. `help find` / `help history` / `help config`: our topic tables (assert a
   corpus-only string, e.g. a known entry id), and `help --delegate find`
   is std's (assert its `Usage:` block).
9. `help commands | length` > 400 (D3: std subcommands survive the shadow).
10. `fakecmd --help`: the stub's own output verbatim — externals never
    route here.
11. `help --all --mode nvim`: every `mode` value starts `nvim`; `--mode
    tmux` exits non-zero.
12. `help "F5 <digit>"`: detail carries the host-only mark (R9).
13. `timeit { help } < 100ms` evaluates true inside the configured shell
    (R8; corpus load measured ~3 ms, so this is headroom, not a race).
14. `help qqqxyzzy` exits 0 — the `core-help --find` fallthrough.
15. The poison `tv` was never invoked (plain `help` spawns nothing).

**Registration** — append `| external bash tests/shell-help.sh` to the
wave-5 `gates` cell of `gates/waves.tsv` (H.2's wave per the registry;
the row currently holds only `external bash tests/shell-claude.sh`). That
cell is shared with the other wave-5 tasks — one appended segment, nothing
else in the file touched.

## Acceptance

- [x] `bash tests/shell-help.sh --tree` exits 0 on the tree, and each
      counterfactual copy fails its own check (printed as the sibling gates
      print theirs). Ran it: `tree rc=0`. Five counterfactuals, all PASS:
      use-std-help-below-the-shadow, config-record-write-appended,
      git-spawn-inserted, hardcoded-repo-path, staging-line-dropped.
- [x] `bash tests/shell-help.sh --hermetic` exits 0, all probes above run
      (count printed). Ran it: `hermetic rc=0`.
- [x] `bash tests/shell-help.sh` (both stages) exits 0; `~/.cache/nushell`
      does not exist afterwards; the live `~/.config/nushell` is untouched.
      Ran it: `CHECKS: 60 run, 60 passed, 0 failed` / `EXIT=0`, with
      `~/.cache/nushell does not exist`, `config.nu, env.nu, help.nu and
      shell.nuon are byte-identical` and `the whole corpus directory is
      byte-identical, file by file`.
- [x] `gates/waves.tsv` wave-5 row carries the new gate as an appended
      segment, and every other row is byte-unchanged. The row now reads
      `external bash tests/shell-claude.sh | external bash
      tests/shell-history.sh | external bash tests/shell-help.sh`: S.7
      registered `shell-history.sh` in that cell after this spec was written,
      so the segment was appended after it rather than after `shell-claude.sh`
      — append-only, as the shared-cell rule requires. `bash
      gates/selftest.sh` reads the new row and reports `external, not held to
      the contract (owned by another node): bash tests/shell-help.sh`.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-help.sh
/usr/bin/grep -n 'shell-help' gates/waves.tsv
git diff --stat gates/waves.tsv
```
