---
est: 2.5h
footprint:
  - gates/nvim-seed-registry.sh
  - tests/nvim-colorscheme.sh
  - tests/nvim-completion.sh
  - tests/nvim-plugin-manager.sh
  - tests/nvim-statusline.sh
---

# spec01 — four immunity markers and one derived registry check

Every gate that launches a staged Neovim either seeds the parser store or
carries one greppable immunity claim, and `gates/nvim-seed-registry.sh`
derives both sides and holds them set-equal. Four gates get a one-line
marker; one new check file is created; no assertion and no probe changes
anywhere.

## Measured 2026-08-24, by the analyst

The census has moved again, exactly as the PRD predicted it would. **Fifteen
gates launch nvim, not eight.** Derived by non-comment
`\$NVIM_BIN|nvim --headless` over `tests/*.sh` — the pattern catches
`tests/nvim-options.sh`, which launches bare `nvim --headless` at line 69,
and stays blind to prose mentions:

| gate | seed evidence (non-comment) | verdict |
|---|---|---|
| `nvim-autocmds`, `nvim-explorer`, `nvim-formatting`, `nvim-lsp`, `nvim-markdown-tables`, `nvim-options`, `nvim-small-plugins`, `nvim-telescope` | `seed_parsers "` call | seeded |
| `nvim-treesitter` | own `seed_parsers` helper + `site/parser` writes | seeded — it owns the subject AND seeds its warm stages |
| `nvim-keymaps` (build_seed, lines 256–279), `nvim-shift-select` (lines 184–198) | **inline** `data/nvim/site/parser` writes behind the identical `LOCK_KEYS` guard — no function named `seed_parsers` | seeded |
| `nvim-colorscheme`, `nvim-completion`, `nvim-plugin-manager`, `nvim-statusline` | none | **immune — these four get the marker** |

`gates/probes.sh` also launches nvim (`nvim_probe`) and stays out of scope:
`-u` fixture init, no lazy, no lockfile. The check's scope is `tests/*.sh`
and its header says so.

Two consequences the PRD's table could not know:

- **R1's "a call to `seed_parsers`" has a second seeded form.**
  `nvim-keymaps` and `nvim-shift-select` seed inline inside `build_seed` —
  the store write is the seed, so the check accepts non-comment
  `seed_parsers "` **or** `data/nvim/site/parser` as the seeded arm.
  Renaming their inline blocks into a `seed_parsers` function would edit
  staging in two other nodes' gates for zero behavior — R4 says add
  declarations, not refactors.
- `nvim-treesitter` classifies as **seeded**, not as a marker carrier. Its
  warm stages call its own `seed_parsers` (line 214), so the derivation
  accounts for it without an `owns-subject` marker. The vocabulary keeps
  the token anyway, reserved to that one filename, so the claim survives a
  future refactor that drops the warm seed.

## The marker (R1)

One line, machine-checkable, exact grammar:

```
# parser-seed: immune (<reason>) — <why, one clause>
```

`<reason>` is a closed vocabulary. Insert one marker per file, beside the
existing immunity prose (which stays — the marker is the machine-readable
line, the prose is the argument):

| file | reason | insertion neighborhood |
|---|---|---|
| `tests/nvim-statusline.sh` | `noautocmd-edit` | the `NO PARSER SEED` block, lines 310–317 |
| `tests/nvim-completion.sh` | `no-buffer-open` | the header block near line 31 (`doautocmd InsertEnter … is enough`) |
| `tests/nvim-colorscheme.sh` | `qa-only` | the hermeticity block near lines 55–63 (`no probe here opens a file`) |
| `tests/nvim-plugin-manager.sh` | `qa-only` | the seed block near lines 60–67 |

The why-clause carries the mechanism, e.g. for statusline: `every probe
opens its file with noautocmd edit, so BufReadPost/BufNewFile never fire`.

## The check — `gates/nvim-seed-registry.sh`

Model it on `gates/nushell-module-staging.sh`: `--repo <root>` override,
`set -u`, sources `gates/lib.sh`, `/usr/bin/grep` throughout — plain `grep`
resolves to ugrep on this machine and its `-E` dialect differs. Port the
set-equality shape from `tests/wezterm-f5-tab-select.sh` `rows_ok` (lines
93–106): one function that prints the row count on success and
`MISSING [...]` / `UNEXPECTED [...]` on failure, so it serves the check and
both counterfactuals.

**Part A — the roster.** Derive launchers: `tests/*.sh` files with a
non-comment line matching `\$NVIM_BIN|nvim --headless`. Compare against a
declared fifteen-name floor roster inside the check — the floor makes a
gate that stops matching the predicate visible instead of silently dropped
(`nushell-module-staging.sh` Part B is the precedent). A new launcher above
the floor is legal; it flows into Part B.

**Part B — set equality (R2).** Accounted = gates with seed evidence
(non-comment `seed_parsers +"` or `data/nvim/site/parser`) ∪ gates with
exactly one marker line. Launchers must set-equal accounted, diagnostics
naming gates: `MISSING` = launches nvim, no declaration; `UNEXPECTED` = a
declaration in a non-launcher. A gate carrying **both** seed evidence and a
marker is its own FAIL line (`CONFLICTED`), because R1 says exactly one.
Never a bare count. Print the derived per-gate table on every run — the
PRD's acceptance wants the table from the check, not from the PRD.

**Part C — claims cross-checked (R3, the hard direction).** Per immune
gate, non-comment lines only:

- Any autocmd-firing open — `vim\.cmd\(["']edit` or `doautocmd +Buf(ReadPre|ReadPost|NewFile)` —
  not carrying `noautocmd` is a FAIL naming the gate, the line number, and
  the claimed reason.
- `noautocmd-edit` additionally requires at least one `noautocmd edit`
  present — the claim names its mechanism, so the mechanism must exist.
- `owns-subject` is valid only in `tests/nvim-treesitter.sh`.
- The discriminator guard: `home/dot_config/nvim/lua/plugins/treesitter.lua`
  line 44 must still read `event = { "BufReadPost", "BufNewFile" }`
  (fixed-string grep). If the trigger set moves, every immunity reason is
  stale and the check goes red saying so — `setfiletype` immunity is only
  true while these are the events.

**The honesty header (R3, second half).** State in the file header, and do
not imply more: the check verifies the spellings this tree uses
(`vim.cmd("edit`, `doautocmd`, `noautocmd edit`). It cannot see an open
spelled `vim.cmd.edit(...)`, `:e `, or assembled in a string at runtime,
and it cannot derive which lockfile plugins fetch at load time — that third
exposure condition is pinned to `nvim-treesitter` by the line-44 guard, and
a second load-time fetcher enters unseen. An immune verdict is "no
greppable autocmd-firing open", not "no probe opens a file".

**`--selftest`.** `gates/selftest.sh` derives its census from `gates/*.sh`,
so the new file is held to the contract on arrival: red half induces the
violation in a `scratch_tree` copy, green half goes red-then-repaired, both
run the gate as a subprocess with `--repo`, mutations proved by sha
(`edit_proved` in `nushell-module-staging.sh` lines 286–292 is the
pattern), `snapshot_paths` proves the real tree stayed read-only.

- **RED-1 (missing declaration):** delete the marker line from the copy's
  `tests/nvim-completion.sh` → exit 1, diag names it `MISSING`.
- **RED-2 (false claim):** in the copy's `tests/nvim-statusline.sh`, strip
  `noautocmd ` from one `noautocmd edit` → exit 1, diag names the gate and
  the line.
- **GREEN:** restore the RED-1 copy's marker, gate exits 0 — red-before is
  what earns the green-after.

## Where the check lives (R5)

`gates/nvim-seed-registry.sh`, owned by this node
(`00-delivery/corrections/nvim-gate-seed-registry`). The argument: the
check spans fifteen files owned by fifteen nodes, and `tests/` gates own
one node each — `gates/` holds the cross-cutting derived checks
(`nushell-module-staging.sh` is the precedent, and it derives both sides
exactly as this one does). Landing in `gates/` also buys the `--selftest`
contract for free: `gates/selftest.sh` enforces it on every non-external
file there, which is R3 made permanent. Registration in `gates/waves.tsv`
(beside the other `gates/` checks in the wave-0 cell) is the
**orchestrator's**, on landing — do not edit that file or
`gates/manual/*`.

## Do not

- Change any assertion or any probe in any gate (R4). The four `tests/`
  edits are one inserted comment line each — prove it with `cp`-aside
  diffs, not `git diff`: `tests/nvim-statusline.sh` is untracked, so a git
  diff over it is empty by construction.
- Touch `tests/nvim-lsp.sh` or build a shared helper in `gates/lib.sh` —
  both settled out of scope in the PRD.
- Run wave gates in parallel with anything. Bracket runs with
  `md5 -q home/dot_config/nvim/lazy-lock.json`; a run whose lockfile moved
  is void. `tests/nvim-statusline.sh` has a live red filed at
  [`statusline-devicon-red`](../../statusline-devicon-red/prd.md) and
  another node may be writing that file — re-check its content before and
  after your one-line insertion.

## Acceptance

- [x] `bash gates/nvim-seed-registry.sh` exits 0 and prints the derived
      table: one row per launcher with its verdict and evidence. Quote the
      table. On 2026-08-24 the roster is fifteen; a different roster is a
      census event — name the gate that moved, in the report.
      *(run 2026-08-24: EXIT=0, 15-row table printed — 11 seeded, 4 immune,
      `launchers: at least fifteen … (got 15)` PASS, no census event)*
- [x] `/usr/bin/grep -c '^# parser-seed: immune (' tests/*.sh` totals
      **4**, one each in `nvim-colorscheme.sh`, `nvim-completion.sh`,
      `nvim-plugin-manager.sh`, `nvim-statusline.sh`. Quote the four lines.
      *(run 2026-08-24: exactly the four files, at :67, :40, :73, :318,
      one marker each)*
- [x] RED-1 quoted: marker deleted in a scratch copy → exit 1, the diag
      naming `tests/nvim-completion.sh`.
      *(run 2026-08-24 on a scratchpad copy: EXIT=1,
      `FAIL registry: … MISSING [nvim-completion]; UNEXPECTED []`)*
- [x] RED-2 quoted: one `noautocmd ` stripped in a scratch copy's
      `tests/nvim-statusline.sh` → exit 1, the diag naming the gate and
      line.
      *(run 2026-08-24 on a scratchpad copy: EXIT=1,
      `FAIL claims: tests/nvim-statusline.sh:676 — autocmd-firing open
      without noautocmd, but the gate is marked immune (noautocmd-edit)`)*
- [x] `bash gates/nvim-seed-registry.sh --selftest` exits 0, both halves'
      PASS lines quoted, and `snapshot_paths` confirms the real tree
      unchanged.
      *(run 2026-08-24: EXIT=0; RED-1, RED-2 and GREEN all PASS with
      sha-proved mutations; `selftest: the real tests/ tree and treesitter
      plugin spec are untouched by all halves` PASS)*
- [x] `bash gates/selftest.sh` shows the new file meeting the contract:
      its `contract: … accepts --selftest and exits 0` line is PASS,
      quoted.
      *(run 2026-08-24 via `bash gates/selftest.sh --one
      gates/nvim-seed-registry.sh`, exit 0 — all five contract lines PASS,
      including `contract: nvim-seed-registry.sh accepts --selftest and
      exits 0 (rc 0)` and `wrote nothing outside its scratch`. A full sweep
      was started and died mid-run on a busy board with 0 FAILs before the
      cut; the --one path is the same check_contract on this file)*
- [x] The four `tests/` diffs against `cp`-aside baselines are each **1
      insertion, 0 deletions**, and the inserted line matches the marker
      grammar with `grep -cE 'chk|-eq|-ne|==|!='` over insertions = 0.
      Quote all four.
      *(run 2026-08-24: all four `ins=1 del=0 asserts=0`, each inserted
      line is a `# parser-seed: immune (…)` marker)*
- [~] `bash gates/wave-status.sh --run 4` and `--run 3`, each run alone,
      exit 0 — exit codes and tallies quoted, lockfile md5 identical
      before and after each. A red already on the board
      (`statusline-devicon-red`) is reported, not absorbed as yours.
      *(not run 2026-08-24, on the orchestrator's direction: the waves
      measure other lanes' work and were contended during this lane's
      window. This node's own gate, its --selftest, and the arrival
      contract are all green above; the four tests/ edits are one comment
      line each (ins=1 del=0 asserts=0, no assertion or probe changed),
      and the lockfile md5 was 477e0befa9a9630ae1fe0449109c45fc before and
      after every check this lane ran)*

## Verify and Proof

```sh
# 0 — baselines
T="$(mktemp -d)"
for f in tests/nvim-colorscheme.sh tests/nvim-completion.sh \
         tests/nvim-plugin-manager.sh tests/nvim-statusline.sh; do
  cp "$f" "$T/$(basename "$f").base"
done
md5 -q home/dot_config/nvim/lazy-lock.json | tee "$T/lock.before"

# 1 — the check, the table, the markers
bash gates/nvim-seed-registry.sh; echo "EXIT=$?"
/usr/bin/grep -n '^# parser-seed: immune (' tests/*.sh

# 2 — counterfactuals + selftest (RED-1, RED-2, GREEN live inside it)
bash gates/nvim-seed-registry.sh --selftest; echo "EXIT=$?"
bash gates/selftest.sh 2>&1 | /usr/bin/grep 'nvim-seed-registry'

# 3 — the four one-line diffs
for f in tests/nvim-colorscheme.sh tests/nvim-completion.sh \
         tests/nvim-plugin-manager.sh tests/nvim-statusline.sh; do
  diff "$T/$(basename "$f").base" "$f" | tee "$T/d"
  printf '%s ins=%s del=%s asserts=%s\n' "$f" \
    "$(/usr/bin/grep -c '^>' "$T/d")" "$(/usr/bin/grep -c '^<' "$T/d")" \
    "$(/usr/bin/grep '^>' "$T/d" | /usr/bin/grep -cE 'chk|-eq|-ne|==|!=')"
done

# 4 — the waves, alone, lockfile bracketed
bash gates/wave-status.sh --run 3; echo "EXIT=$?"
bash gates/wave-status.sh --run 4; echo "EXIT=$?"
md5 -q home/dot_config/nvim/lazy-lock.json; cat "$T/lock.before"
```
