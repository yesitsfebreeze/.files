---
est: 0.5h
footprint:
  - home/dot_config/nvim/lua/plugins/conform.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
  - install.sh
---

# spec01 — `conform.lua`, one lockfile row, the census, four formulas

Write `lua/plugins/conform.lua`, grow `lazy-lock.json` by one row, insert the
new file into E.1's exact-equality census, and add the four formatter
formulas to `install.sh`'s `PKGS`. Covers PRD R1–R6. The standing gate is
[spec02](spec02-gate.md)'s work; write no `tests/` file here beyond the one
census edit.

Every value below was measured 2026-08-23 on nvim 0.12.4 against
conform.nvim `016802de402556da54c36bd7359b441266b01cdd`, in a scratch root
with `HOME` and all four XDG dirs pinned, the plugin clones copied from the
live tree, a refusing `curl` shim, and fake `stylua` / `prettier` /
`rustfmt` / `black` binaries that log their argv and pipe stdin through
`sed`. Nothing here was read off the live config and assumed.

## The estimate

`est: 0.5h`, on the **corrected scale**: this board's 37 clean `est`/`actual`
pairs run **4.0x high** (62.75h estimated against 15.58h measured), so the
number that would traditionally read 2h is written as 0.5h. Same for
[spec02](spec02-gate.md).

## The file name

`lua/plugins/conform.lua`, settled by PRD R6. The three-way collision on the
live `lua/plugins/editor.lua` is already resolved across the siblings: E.11
takes `conform.lua`, E.12 takes three files, E.15 takes `table-mode.lua`.
Do not create `lua/plugins/editor.lua` — epic [I8](../../prd.md) forbids the
catch-all, and `lua/plugins/init.lua` is the import anchor, not a spec file.

## The file

Port the live spec (`~/.config/nvim/lua/plugins/editor.lua:38–62`) into the
repo's **2-space** indent — live is 4-space, so this is a reindent, not a
copy. One plugin per file, one repo string in the file.

What it must contain:

| element | value | requirement |
|---|---|---|
| repo | `"stevearc/conform.nvim"` | R1 |
| lazy trigger | `event = "BufWritePre"` | R1 |
| lazy trigger | `cmd = "ConformInfo"` | R1 |
| key | `keys` entry `<leader>cf`, `desc = "Format buffer"`, calling `require("conform").format({ async = true, lsp_format = "fallback" })` | R5 |
| formatters | `lua = { "stylua" }`, `rust = { "rustfmt" }`, `python = { "black" }`, `markdown = { "prettier" }` | R2 |
| on save | `format_on_save = { timeout_ms = 500, lsp_format = "fallback" }` | R4 |

**No `["markdown.mdx"]` key.** Dropped by the user's answer to Q2 — no
buffer in this config can hold that filetype. Nothing registers the
extension, so the key would be dead configuration.

**The key is declared through lazy's `keys`, never `vim.keymap.set`.**
Measured: at startup in a lua buffer, `maparg(" cf", "n")` is already
lazy's `keys.lua:121` stub and `plugins["conform.nvim"]._.loaded` is
`false`, so the map exists before the plugin does. `vim.g.mapleader` is
`" "` from `config.options`, which is why the probe lhs is `" cf"`.

### The comments the file must carry

Each one is a measured fact whose rediscovery costs a debugging round. Write
them; spec02 gates their presence, because no behaviour can defend a comment.

1. **R3, prettier's job and its limit.** prettier is chosen to align table
   pipes and normalise lists; prose must stay as wrapped, because these PRD
   files are hand-wrapped at ~78 columns and reflowing them churns every
   diff. `proseWrap` defaults to `preserve`, which is what makes that safe —
   and the repo carries **no** `.prettierrc` (measured: no `.prettierrc`,
   `.prettierrc.json`, `prettier.config.js` or `package.json` at the root),
   so prettier's defaults are what run here.
2. **`.jd` is a markdown buffer, so prettier owns it.** `init.lua` registers
   `extension = { jd = "markdown" }`. Measured with a fake prettier: opening
   `t.jd` gives `filetype=markdown` and saving invokes
   `prettier --stdin-filepath <abs path to t.jd>`. This user has 27 `.jd`
   files under `~/dev` alone, so this is not a corner case.
3. **`lsp_format = "fallback"` covers two cases, and the second is silent.**
   Measured with an in-process fake LSP (`vim.lsp.start` with a `cmd`
   function advertising `documentFormattingProvider`) and an empty PATH bin:
   with `stylua` absent, the language server formatted the buffer, the write
   succeeded, and **`vim.notify` was never called** — nothing indicates
   `stylua` did not run. With `stylua` present the shim wins and the LSP is
   not consulted. So the fallback is not only "a filetype with no listed
   formatter": it is also "a listed formatter whose binary is missing",
   which is why R2's four formulas are provisioned below rather than
   assumed.
4. **The write always succeeds.** Every failure mode was measured to exit 0
   with the file written: timeout (570 ms wall for a 2 s formatter, WARN
   `Formatter 'stylua' timeout`, unformatted write), formatter failing
   (ERROR `Formatter failed. See :ConformInfo for details`, unformatted
   write), formatter absent with no LSP (WARN `Formatters unavailable for
   lua file`), and no configured formatter with no LSP (silent). Formatting
   never blocks a save.

## `install.sh` — the carve-out, and its limits

The four formatter binaries join `PKGS`. This edit is
[`packages-installer`](../../../05-platform/02-package-provisioning/packages-installer/prd.md)'s
file, **authorised for this node only** by the user's answer to Q1 and
recorded in this node's `footprint:`. Touch nothing else in that file.

Add them as one commented group inside `PKGS`, in the same
`formula=binary` shape the file already uses:

```
  # 03-editor/07-formatting's four formatters (E.11 R2). conform.nvim names
  # them by binary; a configured-but-absent formatter is SILENT when a
  # language server is attached (lsp_format = "fallback" substitutes it),
  # so absence is not a state to ship.
  stylua=stylua prettier=prettier black=black
  rust=rustfmt     # rustfmt is no formula of its own; it ships with rust
```

Four measured facts about that block:

- **`rustfmt` is not a Homebrew formula**, which is why the pair is
  `rust=rustfmt`. The file already carries pairs whose halves differ
  (`gnupg=gpg`, `git-delta=delta`) and says why a guard keyed on the
  package name would be wrong.
- **On this machine `rustfmt` already resolves** — the rustup shim at
  `~/.cargo/bin/rustfmt`, `rustfmt 1.8.0-stable`, five toolchains
  installed. `install.sh` exports
  `PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"` before anything
  installs, so the shim keeps winning after `rust` is installed, and the
  have-guarded straggler loop skips the entry. The
  unconditional batch still names it; that is the file's existing shape for
  every package, not something this edit introduces.
- **`stylua`, `prettier` and `black` are absent from PATH** (measured with
  `command -v`), and none of the four is in `PKGS` today.
- **`tests/provisioning.sh` stays green without an edit**, and this was
  checked rather than hoped: `R7_BATCH` is asserted as a **subset** of the
  batch line ("superset of R7's required set"), and the retry check derives
  `entries` from the batch line itself, so four new pairs move both sides
  together. Its `PROV_BINS` literal — the poison list for the
  already-provisioned machine — does **not** grow here; it is that node's
  file and this carve-out does not extend to it. Report it; do not edit it.

The Linux subsets (`APT_PKGS`, `PACMAN_PKGS`, `DNF_PKGS`) are **not**
touched: the host is macOS only, and Linux matters only inside capsule
containers.

## `lazy-lock.json` — one row

Append `conform.nvim` from the live lockfile's own pin, which is the clone
this repo's gates seed from:

```
  "conform.nvim": { "branch": "master", "commit": "016802de402556da54c36bd7359b441266b01cdd" },
```

`master`, read out of `~/.config/nvim/lazy-lock.json` rather than from the
clone — the live clone is in detached HEAD, so `git rev-parse
--abbrev-ref HEAD` there answers `HEAD` and proves nothing. The key sorts
**second**, between `blink.cmp` and `friendly-snippets`: a comma appended to
the `blink.cmp` row and one new row after it. No existing commit value
moves.

**Keep lazy's one-line-per-plugin shape.** A `json.dump(indent=2)` rewrite
splits every row and silently defuses `tests/nvim-completion.sh`'s
line-scoped truncated-commit selftest.

Reproducibility for the new row needs no new stage:
`tests/nvim-plugin-manager.sh --network` loops over every lockfile key and
asserts the restored HEAD equals the repo commit, so it widens by itself.

## `tests/nvim-options.sh` — the census

Line 231 holds E.1's exact-equality file census as one hardcoded string.
**Read it from disk; do not transcribe it from here** — it grows on every
plugin node and another may land while this one is in flight. Insert
`./lua/plugins/conform.lua` in `LC_ALL=C sort` position, which is between
`./lua/plugins/completion.lua` and `./lua/plugins/explorer.lua` (verified
with `LC_ALL=C sort`). One string edit, nothing else in that file.

## The two accepted consequences — measure them, do not tune them

The user accepted both when answering Q1 and asked for them measured once
prettier exists, and to be told rather than quietly re-tuned. Neither is a
licence to add a `.prettierrc`, a `.stylua.toml` or any other formatter
config file to this repo: that would be a new file outside this footprint,
and a widening this node did not get. **Measure, quote, report.**

1. **prettier against a hand-wrapped PRD.** Copy a real
   `prds/**/prd.md` to a scratch path, run
   `prettier --stdin-filepath <copy> < <copy>`, and diff. Classify every
   hunk. The line that must hold is R3's: paragraph line breaks unchanged
   (`proseWrap` defaults to `preserve`). List and table normalisation is
   expected and is **not** opt-in — record exactly what it does.
2. **stylua against the repo's own lua.** Run
   `stylua --search-parent-directories --respect-ignores --stdin-filepath
   home/dot_config/nvim/lua/plugins/conform.lua -` and diff against the
   file. There is no `.stylua.toml` or `stylua.toml` in this repo
   (measured), so StyLua's own defaults apply, and this repo writes its
   Neovim lua at 2-space indent. If the diff reindents, say so in the
   report with the byte-level shape of the change — a `.stylua.toml` is a
   correction someone else files, not a file this node adds.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/conform.lua` exists, holds exactly
      one repo string (`"stevearc/conform.nvim"`), and contains no
      `vim.keymap.set` and no `["markdown.mdx"]` key.
- [x] `home/dot_config/nvim/lua/plugins/editor.lua` does **not** exist in
      the repo tree (epic I8's catch-all).
- [x] `lazy-lock.json` parses, holds `conform.nvim` with
      `"branch": "master"` and a 40-hex commit, and every other row's commit
      value is byte-identical to before the edit.
- [ ] `bash tests/nvim-options.sh` exits 0 with `./lua/plugins/conform.lua`
      in the census string. **Half met, and the open half is not this node's.**
      `./lua/plugins/conform.lua` IS in the census string, in `LC_ALL=C sort`
      position between `completion.lua` and `explorer.lua`, and the gate's own
      check confirms it. The gate still exits 1, on one line: the live tree
      also carries an untracked `./lua/config/keymaps.lua` from the in-flight
      `02-keymaps` lane, which the census has not yet been told about — their
      edit, not this node's. Proved by construction rather than asserted: a
      copy of `home/dot_config/nvim/` with `keymaps.lua` removed produces a
      `find | sort` string BYTE-IDENTICAL to line 231's, conform.lua included.
      Re-run once that lane lands.
- [x] `install.sh` carries `stylua=stylua`, `prettier=prettier`,
      `black=black` and `rust=rustfmt` in `PKGS`, and
      `INSTALL_DRY_RUN=1 ./install.sh` prints all four names on the single
      `DRY brew install …` batch line.
- [x] `bash tests/provisioning.sh` exits 0 after the `PKGS` edit — the
      carve-out did not redden another node's gate. **Met, but only after a
      second edit, because spec01's "stays green without an edit" did not
      reproduce.** The two checks the analyst named are indeed subset-shaped
      and did move together — `packages/retry` widened by itself, and now
      reads `one single-package brew install per PKGS entry (24 of 24)`. A
      third check was missed: `shape/prov: NO per-package brew install line`
      counts the R8 straggler loop's output on an already-provisioned machine,
      and the loop is `have "${p##*=}" && continue` — guarded on the BINARY,
      not the package — so four pairs whose binaries were absent from that
      gate's `PROV_BINS` poison list produced four lines. It read
      `FAIL shape/prov: NO per-package brew install line (got 4)`.

      Isolated before it was fixed: a COPY of the gate whose `PROV_BINS` named
      `stylua prettier black rustfmt` exited 0 with no FAIL line, which is
      what identified the one line to change. The fix was then landed in
      `tests/provisioning.sh` itself — **authorised by the orchestrator as the
      other half of the same Q1 carve-out**, on the grounds that this node
      caused the red, `packages-installer` is `done`, and nobody holds that
      file. `PROV_BINS` gains the four binary names (`rustfmt`, not `rust` —
      the pair is `rust=rustfmt`) plus a comment saying the list is keyed on
      the binary and why that makes it grow whenever `PKGS` does. **This file
      is not in the node's `footprint:`; recording it there is the
      orchestrator's edit.** After it:

      ```
      PASS  shape/prov: NO per-package brew install line (got 0)
      PASS  packages/fresh: batch set is a superset of R7's required set (R7)
      PASS  packages/retry: one single-package brew install per PKGS entry (24 of 24)
      PASS  the gate wrote nothing outside its scratch (sha256 over prds, docs, gates, tests, home, install.sh)
      ```

      115 PASS / 0 FAIL, exit 0. Two of three runs in the same minute *also*
      reported `changed: /Users/feb/dev/dotfiles/prds` on the untouched-tree
      guard; that is neither this node's nor the gate's write. Attributed by
      hashing `prds/` either side of a run: the only file that moved is
      `prds/.plane-pull.json`, the board machinery's own state, rewritten by
      the orchestrator inside the guard's window. `plane-pull` appears nowhere
      in `tests/provisioning.sh`, `install.sh` or `gates/lib.sh`, and the
      third run — in a quiet window — was clean.

      One further collision, and this one WAS this node's to avoid: the
      mandated comment block in `install.sh` names the task as `E.11`, and
      `tests/provisioning.sh` asserts that the string `11` appears in
      `install.sh` **only** as `NVIM_MIN_MINOR=11`. The comment therefore says
      `03-editor/07-formatting's four formatters (its R2)` — same reference,
      no literal `11` — and the `PROV_BINS` comment carries none either
      (measured: the added block's `11` count is 0, and the file's total is
      unchanged at 7). The bare-substring `grep -n '11'` over the whole of
      `install.sh` is recorded as a finding, not fixed here.
- [x] `stylua`, `prettier`, `black` and `rustfmt` all resolve with
      `command -v` after provisioning, and each answers `--version`.
- [x] Measured and quoted in the report: prettier's diff against a copy of
      a real `prds/**/prd.md`, with paragraph line breaks **unchanged** and
      every other hunk classified.
- [x] Measured and quoted in the report: stylua's diff against
      `lua/plugins/conform.lua`, including whether it reindents the repo's
      2-space style.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# the file, the lockfile, the census
test -f home/dot_config/nvim/lua/plugins/conform.lua
! test -e home/dot_config/nvim/lua/plugins/editor.lua
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(d["conform.nvim"])'
bash tests/nvim-options.sh

# the carve-out
/usr/bin/grep -nE 'stylua=stylua|prettier=prettier|black=black|rust=rustfmt' install.sh
INSTALL_DRY_RUN=1 ./install.sh 2>&1 | /usr/bin/grep -E '^DRY brew install ' | head -1
bash tests/provisioning.sh

# the binaries
for b in stylua prettier black rustfmt; do command -v "$b" && "$b" --version; done

# the two accepted consequences, measured
f=prds/03-editor/07-formatting/prd.md
prettier --stdin-filepath "$f" < "$f" > /tmp/e11-prd.md; diff -u "$f" /tmp/e11-prd.md
g=home/dot_config/nvim/lua/plugins/conform.lua
stylua --search-parent-directories --respect-ignores --stdin-filepath "$g" - \
  < "$g" > /tmp/e11-conform.lua; diff -u "$g" /tmp/e11-conform.lua
```

`diff` exiting 1 on either of the last two commands is a **measurement**,
not a failure: quote it and classify it. The failure is an unclassified
diff, or a paragraph whose line breaks moved.
