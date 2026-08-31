# spec04 — tests/shell-television.sh: the gate

Write the node's gate in the house shape (hermetic scratch HOMEs, the pty
runner, a recording `tv` stub, counterfactuals for every ordering/absence
claim). It proves spec01's surface, spec02's decoder and spec03's wiring —
including the two acceptance boxes that have never passed against the live
config (L-2's `git show`, the empty-decode error).

**Est:** 2.5h

**Footprint:** `tests/shell-television.sh`

## Shape

`bash tests/shell-television.sh [--tree|--hermetic]`, both by default.
Follow `tests/shell-history.sh`'s conventions: `gates/lib.sh`,
`/usr/bin/grep` always (plain `grep` resolves to ugrep here), every nu run
under `env -i HOME=<scratch>` with `XDG_CONFIG_HOME` pinned, never read or
sha the live history db, `~/.cache/nushell` absent when the gate finishes,
live tree untouched. No `--apply` stage: S.1's gate already proves the
managed tree deploys byte-identical.

The `tv` stub records argv to one log and stdin per invocation, and replies
from a per-check reply file — the sibling gates' pattern. An `EDITOR` stub
records its argv the same way. Banned literal spellings the gate greps for
are assembled from fragments so the gate's own text is never a hit.

## --tree (text checks, each absence/ordering claim with a counterfactual)

- Cable census: the 15 spec01 files plus `theme.toml.tmpl` present under
  `home/dot_config/television/cable/`; every drop-set name absent
  (sessions pair, the nine git-tail files, `bg.toml`, `opacity.toml`);
  `bg-preview.sh` and `theme-preview-sample.ts` absent from the television
  dir; `quicklist.toml` absent (it is 04-shell/07's, with its logger).
- `config.toml`: `theme = "default"`; no `#RRGGBB` hex value anywhere in
  the managed television tree.
- `git-log.toml`: the `{strip_ansi|split: :1}` template appears in
  `output`, `preview` and all three actions. Counterfactual: a copy whose
  decoder-side duplication is reintroduced must fail the paired finder
  check below.
- finder.nu: parses under `nu -n`; contains no `$env.config` write; `rcwd`
  absent (counterfactual: a copy with an `"rcwd"` match arm FAILS);
  `_finder_type` maps `recent-dirs` and `recent-files` to FileList; the
  Commits arm contains no second `split row` (counterfactual: the live
  decoder's split-index-1 arm planted in a copy FAILS).
- `nu-history.toml`: the literal `.config/nushell/history.sqlite3` spelling
  absent (assembled fragments).
- config.nu: finder.nu sourced at MODULES; `tv_finder`/`tv_remote` defined
  after the theme.nu source line and before the KEYBINDINGS anchor
  (counterfactual: a copy with `tv_remote` moved above the theme source
  must fail — the `theme` call cannot parse-bind); the three records
  present with their `executehostcommand` cmds; the ten anchors in order;
  S.6's six records still after `esc_clear`.

## --hermetic (a real nushell, scratch HOME, stubs)

- `finder --start files` with a reply of one existing + one nonexistent
  path returns only the existing path, expanded; argv log carries
  `enter="confirm_selection";tab="toggle_selection"` (R1).
- `finder --start git-log` with bare-hash replies decodes to `{hash}` rows
  (no `subject` column), and `_finder_open` runs `git show` against a
  scratch git repo with one real commit — observed via `git show`'s output,
  not asserted (L-2: never passed before this gate).
- All-invalid FileList reply → a named error naming the channel, exit
  non-zero, not `[]` (R2b). Counterfactual: a finder.nu copy with the check
  removed returns `[]` silently and FAILS the gate.
- `finder --start recent-dirs` returns expanded existing paths (L-3).
- GrepList: a `file:12:text` reply opens the EDITOR stub with `+12 file`.
- Non-tty: `nu -c '…; finder'` without a pty exits non-zero with the
  interactive-only message; no panic string in stderr.
- Ctrl-T (pty): reply `a path/with spaces` → commandline gains
  `'a path/with spaces'` at the cursor; empty reply → commandline
  byte-identical. Counterfactual: deleting the three spec03 records hands
  Ctrl-T back to the generated init's `tv_smart_autocomplete` (its argv
  signature appears in the stub log instead).
- `tv_remote` (pty): channel reply `dirs`, pick reply a scratch dir → PWD
  moves there and the auto-list fires.
- cht pipe: first stub invocation replies `ctrl-p` + `python`; the second
  invocation's argv carries `cht-query` and a `--source-command` containing
  `cht.sh/python/:list` (no network — argv only).
- nu-history channel source: run the cable's source command against a
  scratch db seeded at the `$nu.history-path`-derived location; rows come
  back newest-first, deduped; a missing db yields empty output, not an
  error.

## Acceptance

- [x] `bash tests/shell-television.sh` exits 0 with a PASS/FAIL summary;
      every counterfactual above is executed and shown to fail its check.
      Run 2026-08-23 from the repo root: **61 PASS, 0 FAIL, `EXIT=0`.**
      All seven counterfactuals executed and green: live-literal-db-path,
      rcwd-match-arm, reintroduced decoder-side split, source-line-above-
      MODULES, tv_remote-above-theme-source, records-deleted (both the tree
      form and the pty form), and check-removed-finder
      (`rc=0, out=[]` — the silent `[]` the gate exists to forbid).
- [x] `bash tests/shell-television.sh --tree` and `--hermetic` each run
      standalone. `--tree`: `EXIT=0 PASS=28 FAIL=0`.
      `--hermetic`: `EXIT=0 PASS=34 FAIL=0`. (28 + 34 = 62 against the
      combined run's 61 because the epilogue's two checks run once per
      invocation and the combined run shares one guard pair.)
- [x] The gate leaves no trace: live `~/.config` and `~/.cache/nushell`
      untouched (per-file shas, the house proof).
      `PASS  the managed nushell and television files are byte-identical`,
      `PASS  ~/.cache/nushell does not exist (a real one appearing means an
      isolation leak)`, plus the chezmoi guard pair
      `PASS  hermetic: LIVE chezmoi.toml unchanged (02d5d4ee…)` and
      `PASS  hermetic: LIVE chezmoi source-path unchanged
      (/Users/feb/dev/.files/home)`.
- [x] The six sibling gates still pass in the same run.
      `nushell-core: EXIT=0 PASS=212 FAIL=0`,
      `nushell-aliases: EXIT=0 PASS=39 FAIL=0`,
      `shell-listing: EXIT=0 PASS=36 FAIL=0`,
      `shell-claude: EXIT=0 PASS=51 FAIL=0`,
      `shell-zoxide: EXIT=0 PASS=106 FAIL=0`,
      `shell-history: EXIT=0 PASS=68 FAIL=0`.

## Verify

```sh
bash tests/shell-television.sh
bash tests/shell-television.sh --tree
bash tests/shell-television.sh --hermetic
```
