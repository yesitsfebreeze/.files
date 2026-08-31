---
est: 2h
footprint:
  - tests/nvim-treesitter.sh
---
<!-- gates/waves.tsv and gates/manual/wave3.md are NOT in the footprint:
     they belong to the orchestrator. The exact segment and rows to append
     are at the bottom of this file. -->

# spec02 — the standing gate `tests/nvim-treesitter.sh`

Write `tests/nvim-treesitter.sh` proving R1–R4 and all three PRD acceptance
boxes against a staged, seeded, offline Neovim, plus a cold stage that
establishes what a fresh machine actually does. Every value below was
measured 2026-08-23 on nvim 0.12.4 with `nvim-treesitter` `main` at
`c9f9ed6c` — nothing is hoped.

Stages: `--tree`, `--headless`, `--cold`; no arg runs all three.

No `--network` stage. Restore-reproducibility for the new lockfile row is
already owned by `tests/nvim-plugin-manager.sh --network`'s lockfile-key
loop, and a real parser install is minutes of downloading and compiling —
that is a manual row, not a gate.

## Runner

The `tests/nvim-completion.sh` shape, and reuse its decisions rather than
re-deriving them: source `gates/lib.sh`; `chk`/`chk_ok`/`chk_fail`,
`gates_tmpdir`; `snapshot_paths` over `~/.config/nvim`,
`~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` +
`assert_unchanged` at exit; `/usr/bin/grep` always; a missing `nvim`,
`python3` or `git` is exit 127, never an empty pass. `nvim` by absolute path
so a PATH shim cannot hide it. No `timeout` on this machine: background each
run, poll `kill -0` for 20 s, `kill -9` on overrun, record TIMEOUT. A warm
launch is **75 ms** measured, so probe runs are cheap — spend them.

Two traps carried from E.6, both still true here: a probe doing deferred
work must self-quit with `qa!` and the runner must never append `-c qa`; and
`nvim_get_autocmds({ group = ... })` **throws** when the group does not
exist, so every group readback goes through `pcall` (that is also the
discriminator in the I7 counterfactual).

### Two PATH shims, both mandatory

- **logging `git`** — append `"$*"` to `git-calls.log`, exec the real git.
  Hermeticity is "no `clone|fetch|ls-remote`", not "no git": blink's
  load-time version check runs local `rev-parse`/`describe`.
- **refusing `curl`** — append `"$*"` to `curl-calls.log`, print to stderr,
  `exit 6`. Two reasons it must refuse rather than log-and-pass. First,
  `install()` downloads a tarball per language and a passing shim would give
  the gate a 16-download network dependency. Second, `mason.nvim` — E.9's
  `lsp.lua`, already in the tree — calls `api.mason-registry.dev` and
  `api.github.com` on **every launch that loads it** (measured 2026-08-23,
  two calls per run). So the hermeticity assertion is *"the log holds no
  `tree-sitter` URL"*, never *"the log is empty"*; two mason lines are
  expected and are not this node's business.

### Staging and seeding

`cmp_stage <root>`: copy `home/dot_config/nvim` to `<root>/config/nvim`,
then

1. **`seed_lazy`** — the lockfile-driven helper (read every
   `lazy-lock.json` key, `cp -R "$HOME/.local/share/nvim/lazy/<name>"` to a
   **nonexistent** destination; `cp -R` into an existing directory nests the
   source inside it). An absent live clone is
   `PROBE-ERROR: … ASSUMPTION MISSING`, exit 127.
2. **Strip the leftovers, and this is the load-bearing one.** The live
   `nvim-treesitter` clone carries **untracked `parser/` and `parser-info/`
   directories** — master-era leftovers, 24 MB, `git status` says `??`. The
   plugin root is on the runtimepath, so those `.so` files satisfy
   `vim.treesitter.language.add` all by themselves: measured 2026-08-23, a
   root seeded with the plain `cp -R` and **no** parser store at all
   highlighted `x.nu` while `get_installed()` was empty and sixteen
   downloads were in flight. A gate seeded that way passes for a reason
   that does not exist on a fresh machine. So `rm -rf` both directories from
   the seeded copy, and assert they are gone.
3. **`seed_parsers`** — `cp` each of the sixteen `.so` from
   `$HOME/.local/share/nvim/site/parser/` into
   `<root>/data/nvim/site/parser/`, and create
   `<root>/data/nvim/site/queries/<lang>` as a symlink into the **seeded**
   clone's `runtime/queries/<lang>`. Do not copy the live `site/queries`
   entries: they are absolute symlinks into the live clone and copying them
   points the scratch root outside itself. Any missing source `.so` is
   `ASSUMPTION MISSING`, exit 127.

`cf_stage <root> <sedx>` = `cmp_stage` + one `sed -i ''` on
`lua/plugins/treesitter.lua`, asserting the copy differs.

`cold_stage <root>` = step 1 + step 2 only — no parser store. That is the
fresh machine.

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/treesitter.lua`, each a **function over a
path** so the selftests can run the same check against a mutated copy.

- `"nvim-treesitter/nvim-treesitter"`; `branch = "main"`;
  `build = ":TSUpdate"`; `event = { "BufReadPost", "BufNewFile" }`.
- `require("nvim-treesitter").setup({})` and
  `require("nvim-treesitter").install({`.
- **The parser list, as set equality.** Extract the lines between
  `install({` and the closing `})`, strip quotes and commas, `LC_ALL=C
  sort`, and compare to the exact sixteen: `bash c json lua luadoc markdown
  markdown_inline nu odin python query rust toml vim vimdoc yaml`. Equality,
  not membership — a dropped `nu` or `odin` is the failure R2 exists to
  prevent, and both are the non-obvious ones (the shell config and the Odin
  work). **Substring caution:** `markdown` is a prefix of
  `markdown_inline`, so match whole extracted tokens, never `grep markdown`.
- `pcall(vim.treesitter.start, buf)` present, and the exact indentexpr
  string `"v:lua.require'nvim-treesitter'.indentexpr()"` present.
- R4's loop: `nvim_list_bufs` and `nvim_buf_is_loaded` both present.
- I7, per call site: exactly **one** `nvim_create_autocmd` and exactly
  **one** `nvim_create_augroup(... { clear = true })` in the file, and the
  augroup call on the `group =` line of that autocmd. The epic warns that a
  file-level `augroup` grep passes falsely; here the paired counts *are* the
  per-site check, because the file registers exactly one autocmd — write
  that reason as a comment or the next maintainer will relax it to a
  presence grep.
- Scope: no `vim.keymap.set` (I5); exactly one `"owner/repo"` string (I8).
- **Ban `ensure_installed`** — the `main`-vs-`master` API discriminator; the
  old module config is what a copy-paste from an outdated README brings in.
  **Strip comment lines first** (`/usr/bin/grep -v '^[[:space:]]*--'`, the
  `nvim-completion.sh` `ban_ok` idiom — prose is not a plugin spec). Checked
  2026-08-23 against spec01's exact file text: `ensure_installed` has **1
  hit with comments and 0 with them stripped**, because the header comment
  names the API it is not using. A naive ban would be red on the correct
  file. The planted-mutation selftest proves the stripped check still
  fires.
- **The cold-install contract is documented.** Assert `curl` and the phrase
  `COLD-INSTALL CONTRACT`, and pick those two on purpose. Measured
  2026-08-23 against spec01's exact file text: `curl` has **1 hit, and 0
  once comment lines are stripped**, so it is a real assertion about the
  comment rather than a word the code carries anyway. Do **not** gate on
  `treesitter` — unhyphenated, it is a substring of the repo string
  `nvim-treesitter/nvim-treesitter` and of the augroup name, so it hits in
  every possible version of this file and proves nothing. (The hyphenated
  `tree-sitter` happens to be comment-only too — 0 stripped hits — but the
  one-character difference between a real check and a vacuous one is exactly
  the kind of thing that gets "simplified" later, so use `curl`.)
- `lazy-lock.json`: parses (python3), holds `nvim-treesitter` with
  `branch == "main"` and a 40-hex `commit`. Membership, not exact key
  equality — later plugin nodes must not have to edit this gate.

**Selftests, every invocation** (a check that cannot fail proves nothing):
a copy with `"nu",` deleted goes red on the set equality; a copy with the
`group = …augroup…` line deleted goes red on the I7 pairing; a copy with
`if pcall(vim.treesitter.start, buf) then` rewritten to
`do vim.treesitter.start(buf)` goes red on the pcall check; a copy with
`ensure_installed = { "lua" },` planted **as code** goes red on the ban,
while a copy whose header comment alone mentions `ensure_installed` stays
green (that pair is what proves the comment strip); a copy with every
comment line stripped goes red on the `curl` check.

## `--headless` (warm, seeded, offline, both shims)

Seven probes, `chk` per line. All expected values measured.

**P1 — deferral, the plugin's own knobs, and install idempotence.** No file
opened; `-c` chain; self-quits.

- `lazy.core.config.plugins["nvim-treesitter"]._.loaded` falsy at startup,
  truthy after `doautocmd BufReadPost` (R1's lazy event, observed).
- readback: `branch == "main"`, `build == ":TSUpdate"`, `event` exactly
  `{ "BufReadPost", "BufNewFile" }`.
- `vim.fn.exists(":TSUpdate")` is `0` before the load and `2` after — the
  `build` string names a command the plugin really creates, so it is not an
  inert code path.
- `require("nvim-treesitter").get_installed()` sorted equals the sixteen.
- `curl-calls.log` holds no `tree-sitter` URL: warm, `install()`
  short-circuits and makes zero network calls. (Two mason lines are
  expected. See the shim note.)

**P2 — PRD acceptance 1, `nvim x.nu` from the command line.** Stage a
scratch `x.nu`; open it as an argument, not with `:edit`.

- `filetype == "nu"` (core detects it — nvim 0.12 ships `ftplugin/nu.vim`);
  `require("vim.treesitter.highlighter").active[buf] ~= nil`;
  `vim.treesitter.get_parser(buf):lang() == "nu"`; `&indentexpr` is exactly
  `v:lua.require'nvim-treesitter'.indentexpr()`.
- `vim.treesitter.query.get("nu", "highlights") ~= nil` — highlights really
  resolve, with the in-probe negative control
  `vim.treesitter.query.get("go", "highlights") == nil` (measured
  `q_nu=true`, `q_go=false`).
- a `pcall` of `nvim_get_autocmds` for event `FileType` and group
  `treesitter_attach` succeeds and returns exactly one autocmd.

Choose `nu` and not `lua` on purpose, and comment it: Neovim 0.12's own
`ftplugin/lua.lua`, `markdown.lua`, `help.lua` and `query.lua` already call
`vim.treesitter.start()`, so for those four filetypes highlighting proves
nothing about this config. `nu` is one of the nine languages that only exist
because of R2.

**P3 — PRD acceptance 2, a filetype with no installed parser.** Open a
scratch `x.go` (`go` is deliberately not in R2's sixteen and not one of the
seven built-ins).

- exit 0; `vim.v.errmsg` empty; `nvim_exec2("messages")` output empty;
  `highlighter.active[buf]` nil; `&indentexpr == "GoIndent(v:lnum)"` — vim's
  own, i.e. the attach declined rather than half-applied.

**P4 — PRD acceptance 3, the indent path.** Open a scratch `z.lua` holding a
block flattened to column 0.

- `&indentexpr` is ours.
- `require("nvim-treesitter.indent").get_indent(3)` returns `2` here and
  `-1` on the `.go` buffer of P3 — the indent module resolves a parser plus
  `indents.scm`, or it does not.
- `setlocal nosmartindent`, then `normal! gg=G`: line 4 is `    return {`
  and line 8 is `  end`. With `indentexpr` cleared the same run gives
  `  return {` and `end`.
  **Why `nosmartindent`, and this must be a comment in the gate:**
  [`01-options`](../../01-options/prd.md) sets `smartindent = true`, and with
  it on `=` produces **byte-identical** output with the indentexpr cleared
  (measured on this exact snippet). The option masks the discriminator, so
  the probe turns it off to isolate the indentexpr; the interactive,
  smartindent-on case is a manual row rather than a box that cannot fail.

**P5 — R4's real subject.** `-c 'setfiletype lua' -c 'new x.nu'`, so a
buffer that was filetyped *before* the plugin loaded survives.

- buffer 1 (`ft=lua`) has `&indentexpr` = ours; buffer 2 (`ft=nu`) too.
- **Comment the measurement, because the PRD's stated reason is wrong.** On
  `nvim x.nu` the FileType autocmd has **not** already fired: the
  triggering buffer's filetype is still empty when `config()` runs (measured
  `loop:1:ft=` then `au:1:ft=nu`), so the loop does nothing for it and
  deleting the loop leaves `nvim x.nu` fully highlighted. The loop's real
  subject is the pre-typed sibling above, whose only symptom is losing the
  indentexpr to `GetLuaIndent()`. Do not gate R4 on acceptance 1; it cannot
  fail there.

**P6 — I7, double registration.** `loadfile(stdpath("config") ..
"/lua/plugins/treesitter.lua")()` and call its `config()` a second time.

- total `FileType` autocmd count unchanged (`4` → `4`); the group holds
  exactly one.

**P7 — the half-installed wedge.** A root seeded with the queries symlinks
but with `site/parser/*.so` deleted.

- `get_installed()` reports **all sixteen**; `curl-calls.log` holds no
  `tree-sitter` URL; `x.nu` has no highlighter. `get_installed()` unions the
  queries directory with the parser directory, so a half-installed language
  is indistinguishable from an installed one and `install()` never retries
  it — no relaunch heals it.
- This is not trivia: spec01's `seed_parsers` in `tests/nvim-options.sh`
  relies on exactly this short-circuit to keep E.1 offline. Asserting it
  here means an upstream semantics change turns **this** box red instead of
  silently re-arming sixteen downloads inside E.1.

**Counterfactuals**, each a `cf_stage` copy, each naming the check it turns
red:

- the `group = …augroup…` line deleted → P6's total grows `4` → `5`
  and the group `pcall` returns false.
- the pcall rewritten to a bare `vim.treesitter.start(buf)` → P3 prints
  `Parser could not be created for buffer 1 and language "go"` with a Lua
  traceback (measured verbatim), so P3's empty-`messages` check goes red.
- the `for _, buf in ipairs(vim.api.nvim_list_bufs())` loop deleted → P5's
  buffer-1 indentexpr becomes `GetLuaIndent()`. **Also assert the
  non-effect:** P2 stays green on the same copy. That asymmetry is the
  measurement, and writing it down is what stops someone "fixing" P2.
- `"nu",` deleted from the install list, staged against a root whose
  `site/parser/nu.so` and `site/queries/nu` are also removed → P2's
  highlighter check goes red and no download is attempted.
- **the provenance counterfactual:** a root staged with the plain `cp -R`
  (leftover `parser/` kept) and **no** parser store → `x.nu` highlights
  while `get_installed()` is empty. Assert that pair explicitly and label it
  THE FALSE PASS. It is the whole reason step 2 of the seed exists.

**Provenance guard, once per stage:** the seeded clone has no `parser/` and
no `parser-info/` directory.

**Hermeticity, last checks:** `git-calls.log` free of
`clone|fetch|ls-remote`; `curl-calls.log` free of `tree-sitter`.

## `--cold` (hermetic, offline, the fresh machine)

`cold_stage`: seeded clone with the leftovers stripped, **no** parser store,
refusing `curl`. One run, `nvim x.nu` with a scratch `y.lua` beside it.

- exit `0`. The fresh-machine launch does not fail — that is the finding,
  and the gate's job is to pin it rather than to be surprised by it later.
- `get_installed()` is empty.
- `x.nu`: no highlighter, `&indentexpr == "GetNuIndent(v:lnum)"` (vim's).
- `:new y.lua`: highlighter **active** and `&indentexpr` = ours. The seven
  parsers Neovim 0.12 compiles into the binary (`c lua markdown
  markdown_inline query vim vimdoc`) still work, so the degradation is
  partial. This is the positive control: without it, "nothing highlighted"
  could just as well be a broken config.
- **Name the network dependency deterministically.** Do not count the
  background downloads — they race the quit (the same root logged 0 curl
  calls on one run and 16 on another, measured). Instead await one:
  `require("nvim-treesitter.install").install({ "json" }):wait(60000)`, then
  assert `site/parser/json.so` is absent and `curl-calls.log` holds a URL
  matching `tree-sitter-json/archive/`.

Not automated here, and say so in the header: with a **real** `curl` and
`tree-sitter` off PATH, the same install fails at
`Error during "tree-sitter build": ENOENT … 'tree-sitter'`, per language,
still exit 0, parser store still empty (measured 2026-08-23). It needs the
network, so it is the manual row below.

## Acceptance

- [x] `bash tests/nvim-treesitter.sh --tree` exits 0; all selftest
      mutations red-then-caught.
      `exit=0`. The seven selftest lines:
      `PASS  selftest: a copy with "nu", deleted goes red on the
      parser-list set equality` ·
      `PASS  selftest: a copy with the group = augroup line deleted goes
      red on the I7 pairing` ·
      `PASS  selftest: a copy with the pcall rewritten to a bare start()
      goes red on the pcall check` ·
      `PASS  selftest: a copy with ensure_installed planted AS CODE goes
      red on the ban` ·
      `PASS  selftest: a copy whose COMMENT alone names ensure_installed
      stays green (the strip works)` ·
      `PASS  selftest: a copy with every comment line stripped goes red on
      the curl / cold-install-contract check` ·
      `PASS  selftest: a lockfile copy with a truncated nvim-treesitter
      commit goes red`.
      The stage's own readback prints
      `parser list = bash c json lua luadoc markdown markdown_inline nu
      odin python query rust toml vim vimdoc yaml`.
- [x] `bash tests/nvim-treesitter.sh --headless` exits 0; every
      counterfactual named its red check; no TIMEOUT.
      `exit=0`. P1 `pre_loaded=false` -> `post_loaded=true`,
      `pre_tsupdate=0` -> `post_tsupdate=2`, `installed=` the sixteen.
      P2 `ft=nu` `hl=true` `lang=nu` `q_nu=true` `q_go=false` `au_n=1`.
      P3 exit 0, `errmsg=<empty>`, `messages=<empty>`, `hl=false`,
      `indentexpr=GoIndent(v:lnum)`. P4 `get_indent3=2`, `go_indent3=-1`,
      `line11=  :rep(3)`. P5 `buf1_ft=lua` with our indentexpr.
      P6 `count_before=4` `count_after=4` `group_n=1`.
      P7 `installed=` the sixteen with `hl=false`.
      Counterfactuals: ungrouped `4 -> 5` and `group_ok=false`; no pcall
      prints `Parser could not be created for buffer 1 and language "go"`
      with a traceback; no loop gives `buf1_indentexpr=GetLuaIndent()`;
      indentexpr assignment deleted gives `line11=:rep(3)`; `nu` dropped
      gives `hl=false`.
      **The false-pass pair**: `hl=true` with `installed=` empty on a plain
      `cp -R` root.
      **The R4 asymmetry**: the same loop-deleted copy reads `hl=true` on
      `nvim x.nu` — `PASS  counterfactual: the SAME copy still highlights
      nvim x.nu — P2 stays GREEN, so it cannot prove R4`.
- [x] `bash tests/nvim-treesitter.sh --cold` exits 0 and quotes the fresh
      machine. `exit=0`, staged run exit 0, `installed=[]`,
      `nu_hl=false` with `nu_indentexpr=GetNuIndent(v:lnum)`,
      `lua_hl=true` with
      `lua_indentexpr=v:lua.require'nvim-treesitter'.indentexpr()`,
      `await_ok=true`, `json_so=0`, and the awaited attempt
      `github.com/tree-sitter/tree-sitter-json/archive/001c28d7...gz`.
- [x] Provenance guard green in every stage: no `parser/` or
      `parser-info/` in any seeded clone. Three lines, one per stage, plus
      the inverse assertion on the false-pass root
      (`PASS  counterfactual staging: the plain cp -R copy KEEPS parser/
      and parser-info/`).
- [x] `git-calls.log` free of `clone|fetch|ls-remote` and the warm curl log
      free of `tree-sitter`, in `--headless`. The warm log holds 18 lines,
      all `api.mason-registry.dev` / `api.github.com` — E.9's mason, named
      in the shim comment.
- [x] `assert_unchanged` green in all three stages — no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`.
- [x] `gates/waves.tsv` wave-3 row carries all three stages.
      **Closed by the orchestrator on the transition.**
      **Orchestrator carve-out.** Confirmed by read 2026-08-23: wave 3's
      gates cell ends at `external bash tests/nvim-telescope.sh
      --headless` and names no `nvim-treesitter.sh` stage. The segment to
      append is below, verbatim.
      **It is load-bearing, not cosmetic.** `gates/wave-status.sh
      --validate` asserts that every script under `tests/` is named by a
      wave row, so while this box is open it reads
      `FAIL  registry: every script under tests/ is named by a row
      (unreferenced: nvim-treesitter.sh)` and `gates/selftest.sh` goes red
      through `wave-status.sh --selftest` (29 PASS / 1 FAIL). Applying the
      segment below to a scratch copy of the registry turns `--validate`
      green on all seven checks — measured 2026-08-23, so the segment is
      correct and sufficient.
- [x] `gates/manual/wave3.md` carries the four E.8 rows.
      **Closed by the orchestrator on the transition.**
      **Orchestrator carve-out.** Confirmed by read 2026-08-23:
      `/usr/bin/grep -c 'E\.8' gates/manual/wave3.md` returns 0.

## Verify

```sh
bash tests/nvim-treesitter.sh                  # all three stages
bash tests/nvim-options.sh                     # neighbour, census + seed
bash tests/nvim-completion.sh
bash tests/nvim-plugin-manager.sh --tree
bash tests/nvim-plugin-manager.sh --headless
```

## Orchestrator carve-outs

### `gates/waves.tsv` — wave **3**, gates cell

Append, verbatim:

```
 | external bash tests/nvim-treesitter.sh --tree | external bash tests/nvim-treesitter.sh --headless | external bash tests/nvim-treesitter.sh --cold
```

E.8 is already in wave 3's task list; only the gates cell changes.

### `gates/manual/wave3.md` — four rows

```markdown
- [ ] **E.8** — a cold machine really installs the parsers. In a scratch XDG
      root with no parser store, on a network, with `tree-sitter` on PATH,
      open a `.nu` file and wait for the install to finish; quit and reopen
      it.
      PASS: sixteen `.so` files in `<root>/.local/share/nvim/site/parser`,
      and the reopened file is coloured.
      FAIL: an empty parser store, or `:messages` carrying `Error during
      "tree-sitter build"` — the toolchain, not the config.
      (Automated only offline: `tests/nvim-treesitter.sh --cold` pins the
      no-network shape. This row is the only place the real install is
      exercised, because it needs the network and minutes of compiling.)
- [ ] **E.8** — the toolchain is actually installed. Run `command -v
      tree-sitter` and `command -v curl` on a machine provisioned only by
      `install.sh`.
      PASS: both resolve.
      FAIL: `tree-sitter` missing — then R2 installs nothing on a fresh
      machine and every failure is one `:messages` line while Neovim still
      exits 0. It is NOT in the required package set
      (`05-platform/02-package-provisioning/packages-installer` R7), so this
      is expected to fail until that correction lands. Not gated: a gate
      asserting it would be red on a correctly provisioned machine.
- [ ] **E.8** — the colours actually paint. Open a `.nu` and a `.rs` file in
      the GUI and switch scheme with `tinty apply`.
      PASS: multi-coloured syntax in both, and it re-tints with the scheme.
      FAIL: one flat colour — the highlighter is attached (the gate proves
      that) but nothing is painting, or the palette is not reaching it.
- [ ] **E.8** — `=` re-indents in a real session. With the config's own
      `smartindent` on, flatten a Lua block and a TOML array to column 0 and
      press `=` over each.
      PASS: both re-indent correctly.
      FAIL: either left flat, or indented to the wrong depth.
      (Headless, `smartindent = true` produces byte-identical output with
      the treesitter indentexpr cleared, so the gate's probe turns
      smartindent off to isolate the indentexpr. This row is the on-config
      half.)
```
