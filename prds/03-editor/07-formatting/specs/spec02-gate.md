---
est: 1.25h
footprint:
  - tests/nvim-formatting.sh
---

# spec02 — the standing gate

Write `tests/nvim-formatting.sh`, the node's `verify:`. Three stages:
`--tree` (hermetic text checks), `--headless` (a staged, seeded, offline
Neovim driven by fake formatter binaries) and `--formatters` (the real
`stylua` and `prettier`, which is where PRD acceptance 1 and 2 actually
close). Bare invocation runs all three, as every sibling gate does.

`est: 1.25h`, on the **corrected scale** — this board's 37 clean
`est`/`actual` pairs run **4.0x high** (62.75h estimated against 15.58h
measured), so the number that would traditionally read 5h is written as
1.25h.

**`gates/waves.tsv` and `gates/manual/wave4.md` are NOT in this footprint.**
Both are contended by other workers. The wave-4 gates cell already lists
E.11 among its tasks and carries no formatting command; adding
`external bash tests/nvim-formatting.sh` is the orchestrator's edit, not
this spec's. Do not touch either file.

Every value quoted below was measured 2026-08-23 on nvim 0.12.4 against
conform.nvim `016802de402556da54c36bd7359b441266b01cdd`, in a scratch root
with `HOME` and all four XDG dirs pinned, the plugin clones copied from the
live tree, and fake formatter binaries. Re-measure anything you change.

## What the shims buy, and why they are not a weaker proof

Every conform formatter is an external process fed on stdin. A fake binary
that logs its argv and pipes stdin through `sed` proves the whole contract
this node owns — that the right binary is invoked, with the right argv, for
the right filetype, and that its stdout reaches the buffer and the file —
without needing four formulas installed. The real binaries prove one thing
the shims cannot: that the formatting a human sees is the formatting the
PRD promises. That is `--formatters`, and it is a separate stage so a
machine mid-provisioning fails one stage loudly instead of all of them.

## Runner

Source `gates/lib.sh`: `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim`, and `assert_unchanged` at exit.
`/usr/bin/grep` always — bare `grep` is ugrep here.

Take the staging shape from `tests/nvim-treesitter.sh`: `seed_clone`
(lockfile-driven, with the untracked `parser/` and `parser-info/` leftovers
stripped), `seed_parsers` (the warm parser store, so `treesitter.lua`'s
`install()` short-circuits instead of firing sixteen downloads), the
refusing `curl` shim, the logging `git` shim, and `nv_watch`. `cp -R` must
copy to a **nonexistent** destination — into an existing directory it nests
the source inside it.

### Seed mason's registries, or every probe is a coin flip

**This is the one thing this gate needs that no sibling nvim gate needed,
and it is not tidying.** `lsp.lua` loads mason on `BufReadPre`, and
`mason-lspconfig.setup()` refreshes its registry over the network on every
launch. Under the refusing `curl` shim that promise **rejects**, and the
rejection surfaces inside whatever blocking call is pumping the event loop
at that moment. Every probe in this gate makes one: conform's
`format_on_save` path is `format_lines_sync` → `vim.wait`.

Measured on a cold root, saving a lua file with a working fake `stylua`:

```
E5113: Lua chunk: … BufWritePre Autocommands for "*": Vim(append):Lua callback:
ENOTCONN
  .../mason.nvim/lua/mason-core/async/init.lua:121: in function 'callback'
  …/conform.nvim/lua/conform/runner.lua:709: in function 'format_lines_sync'
```

The formatter had already run — the shim log holds its argv — and the write
was **aborted anyway**: the file on disk was byte-identical to before.
The same rejection hit a different blocking call on another probe
(`table-mode.lua:39`'s `nvim_exec2` while opening a markdown file), so it is
not conform-specific and a per-filetype warm-up does not fix it.

The fix, measured: copy the live `~/.local/share/nvim/mason/registries`
(536 KB) into `<root>/data/nvim/mason/registries` in the staging helper, as
`tests/nvim-lsp.sh`'s `seed_mason` does. With it, the same cold root ran the
same probe clean — `RES disk={ "-- S local  x=1", "-- S return x" }`,
exit 0, no `ENOTCONN`. Precondition it like any other seed source: absent
`registries` is `PROBE-ERROR … ASSUMPTION MISSING`, exit 127, never a skip.

### Preconditions, each a loud `exit 127`

1. `nvim`, `python3`, `git` on PATH.
2. Every `lazy-lock.json` key present under `~/.local/share/nvim/lazy/` —
   this node's key is `conform.nvim`, and it needs no build artifact.
3. `~/.local/share/nvim/site/parser/<lang>.so` for the sibling's
   `WANT_LANGS`.
4. `~/.local/share/nvim/mason/registries` present.
5. `--formatters` only: `stylua`, `prettier`, `black`, `rustfmt` all
   resolve with `command -v`. Absent is `PROBE-ERROR … ASSUMPTION MISSING`,
   exit 127 — this node's whole point is that `install.sh` provisions them,
   so "not installed" is a failure, never a skip.

### Two probe-output rules, both measured, both must be comments

- **conform's notifications are deferred.** `conform/init.lua:17` wraps
  `notify` in `vim.schedule_wrap`. Measured: a probe that reads its
  captured notifications right after `:write` sees `{}` — the same probe
  reading them from a `vim.defer_fn(…, 300)` sees
  `{ "3:Formatter 'stylua' timeout" }`. A probe that asserts on a
  notification **must** defer first, or it asserts on emptiness and passes
  for the wrong reason.
- Capture notifications by replacing **both** `vim.notify` and
  `vim.notify_once` at probe start, recording `level .. ":" .. msg`.
  `vim.log.levels.WARN` is `3` and `ERROR` is `4`; assert the level, not
  only the text.
- A probe that does deferred work self-quits with `qa!` and the runner
  appends no `-c qa` — a trailing `-c qa` fires at startup, before any
  `defer_fn`. A 60 s watchdog per probe is ample; measured probes finish in
  a few seconds.

### The fake binaries

Four bin dirs, each prepended to the probe's PATH:

| dir | contents | behaviour |
|---|---|---|
| `fmtbin` | `stylua`, `prettier`, `rustfmt`, `black` | log `ARGV:$*` and `CWD:$PWD` to `$FMT_LOG`, then `sed 's/^/-- S /'` (or `P `, `# F `) over stdin |
| `slowbin` | `stylua` | logs, `sleep 2`, then transforms — the timeout probe |
| `failbin` | `stylua` | drains stdin, writes `boom` to stderr, `exit 1` |
| `emptybin` | *(empty)* | the absent-formatter probes |

The transform must be a **prefix**, not a no-op: a formatter whose output
equals its input cannot tell "conform applied the output" from "conform did
nothing".

### Work files, created outside the XDG root

`x.lua` (`local  x=1` / `return x`), `t.md` (a ragged three-line table),
`t.jd` (the same bytes), `x.rs`, `x.py`, `x.txt`. Recreate them before every
probe — the probes write them.

Use `text`, never `json` or `lua`, for the "no configured formatter" probe.
The sibling gate measured nvim's bundled `ftplugin/lua.lua` throwing
`Query error at 74:3. Invalid field name "operator"` in a seeded root, which
would redden a clean-messages assertion for a reason this node did not
cause; `x.txt` produced no such error here.

## `--tree` (hermetic, no nvim run)

Each check is a function over a path, so the selftests can run the same
check against a mutated copy. `-qF` on substrings, never anchored full
lines — spec01 reindents from 4 spaces to 2.

Over `home/dot_config/nvim/lua/plugins/conform.lua`:

- R1: `"stevearc/conform.nvim"`; `event = "BufWritePre"`;
  `cmd = "ConformInfo"`.
- R2: `lua = { "stylua" }`, `rust = { "rustfmt" }`, `python = { "black" }`,
  `markdown = { "prettier" }` — all four.
- R2: **no `markdown.mdx`**, comment lines stripped. The literal must not
  appear as a key anywhere in the file.
- R4: `format_on_save`; `timeout_ms = 500`; `lsp_format = "fallback"`.
  Assert `500` inside the `format_on_save` table, not merely somewhere in
  the file.
- R5: the `<leader>cf` key entry, `desc = "Format buffer"`,
  `async = true`, and its own `lsp_format = "fallback"`.
- I5: **no `vim.keymap.set`** — the map is declared through lazy's `keys`.
- I8: the sorted set of repo strings in the file is exactly
  `"stevearc/conform.nvim"`. Use `tests/nvim-completion.sh`'s `f_repos`
  idiom.
- The four comments spec01 mandates, matched over the file's **comment
  lines only**: one names `proseWrap`, one names `.jd`, one says the
  fallback also fires for a formatter whose binary is missing, one says the
  write always succeeds.
- `home/dot_config/nvim/lua/plugins/editor.lua` does **not** exist (epic
  I8's catch-all, and the file this node was carved out of).

Over `home/dot_config/nvim/lazy-lock.json`: parses (python3), holds
`conform.nvim` with `"branch": "master"` and a 40-hex commit, one row per
line. Membership, not exact equality.

Over `install.sh`, as a function of a path so a mutated copy can go red:
`stylua=stylua`, `prettier=prettier`, `black=black` and `rust=rustfmt` all
appear **inside the `PKGS=( … )` array** — slice the file between `PKGS=(`
and the closing `)` before matching, so a pair added to `CASKS` or written
in a comment cannot pass. Assert nothing else about `install.sh`: it is
another node's file and this node holds a carve-out, not ownership.

Over `tests/nvim-options.sh`: `./lua/plugins/conform.lua` appears in E.1's
census string. Read-only membership — E.1 owns the exact-equality check;
this one only catches the entry being dropped.

**Negative controls, measured before this node lands**, over
`home/dot_config/nvim/` (raw / comment-stripped): `conform` 0/0,
`stylua` 0/0, `black` 0/0, `rustfmt` 0/0, `format_on_save` 0/0,
`<leader>cf` 0/0, `prettier` **1/0**, `markdown.mdx` **1/0**. The last two
live in `table-mode.lua`'s comments, which is why every assertion here is
scoped to one file and why the `markdown.mdx` check strips comment lines.
Re-run these greps before writing the assertions; if a count moved, find
out why.

**Selftests, every invocation** — each a mutated copy that must go red:
`format_on_save` deleted; `timeout_ms = 500` changed to `5000`;
`lsp_format = "fallback"` deleted from `format_on_save`; the `markdown` key
deleted; an `["markdown.mdx"] = { "prettier" }` key planted; a
`vim.keymap.set` planted; a second repo string planted; a lockfile copy with
a truncated `conform.nvim` commit; an `install.sh` copy with
`prettier=prettier` deleted; an `install.sh` copy with the four pairs moved
out of `PKGS` into a comment.

## `--headless` (hermetic, seeded, fake binaries)

One `chk` per line. Every value below is a real reading from a real run.

**Probe A — pre-load shape (R1, R5).** Open `x.lua`, `-c` chain, no
deferral. Measured:
`require("lazy.core.config").plugins["conform.nvim"]._.loaded`
is **false**; `vim.fn.exists(":ConformInfo")` is **2** — the command exists
before the plugin loads, which is what `cmd =` buys;
`vim.fn.maparg(" cf", "n")` is lazy's
`lazy/core/handler/keys.lua:121` stub. `vim.g.mapleader` is `" "`, so the
probe lhs is a literal space.

**Probe B — a lua save formats through the real argv (R1, R2).** `fmtbin`,
`x.lua`, `:silent write`. Measured:

- shim log line 1: `ARGV:--search-parent-directories --respect-ignores
  --stdin-filepath <abs path to x.lua> -`
- shim log line 2: `CWD:` the directory the gate was invoked from — conform
  falls back to `vim.fn.getcwd()` because `stylua`'s `cwd` is
  `util.root_file({ ".stylua.toml", "stylua.toml" })` and neither file
  exists in this repo.
- buffer **and** disk both `{ "-- S local  x=1", "-- S return x" }`
- `_.loaded` now true.

Assert the argv **exactly**. It is the difference between "conform ran
something" and "conform ran stylua the way the formatter definition says".

**Probe C — the 500 ms timeout (R4).** `slowbin`. Measured: `:write`
returned after **570 ms** wall for a 2 s formatter; `vim.bo.modified` is
`false`; disk is `{ "local  x=1", "return x" }` — the **unformatted** write
went through; after a 300 ms defer the captured notification is
`3:Formatter 'stylua' timeout`. Assert the elapsed window (≥ 500 ms,
< 1500 ms), not a point value.

**Probe D — a failing formatter (R4).** `failbin`. Measured: disk unchanged,
process exit 0, deferred notification
`4:Formatter failed. See :ConformInfo for details` — level **4**, ERROR.

**Probe E — absent formatter, no LSP, and the dedup (R4).** `emptybin`.
Measured: `:write` returned in 4 ms, disk unchanged, deferred notification
`3:Formatters unavailable for lua file`. Then save a **second** lua buffer
in the same session and assert **no second notification**:
`conform/init.lua:543` keys `has_notified_ft_no_formatters` by filetype for
the life of the session. Assert the silence — it is the reason the user
chose to provision the binaries rather than ship them missing.

**Probe F — the silent LSP substitution, and it is R4's discriminator.**
`emptybin` plus an in-process fake language server: `vim.lsp.start` with a
`cmd` **function** returning a table whose `request` answers `initialize`
with `capabilities = { documentFormattingProvider = true }` and
`textDocument/formatting` with one `newText` edit. No mason binary, no
network. Measured: one client attached, buffer and disk both
`{ "-- LSP FORMATTED", "local  x=1", "return x" }`, and the captured
notification list is **empty** — nothing at all says `stylua` never ran.
Assert both the edit **and** the empty notification list.

**Probe G — a present formatter beats the LSP.** Same fake server, but
`fmtbin` on PATH. Measured: disk is `{ "-- S local  x=1", "-- S return x" }`
— the stylua shim's output, not the server's — and the shim log holds the
argv. This is the control that keeps probe F honest.

**Probe H — markdown, and the manual key (R2, R5).** `fmtbin`, `t.md`.
Measured: `vim.bo.filetype` is `markdown`; on save the shim log holds
`ARGV:--stdin-filepath <abs path to t.md>` — prettier takes **no**
`--parser` argument, because the config's `ft_parsers` table is all
commented out upstream. Then, in a fresh probe,
`vim.api.nvim_feedkeys(" cf", "x", false)` and a 800 ms defer: the buffer
reads `{ "P | a | bbbb |", "P |---|---|", "P | c | d |" }`,
`vim.bo.modified` is **true** — `<leader>cf` formats the buffer and does
**not** write it — and `maparg(" cf", "n", false, true).desc` is
`Format buffer`.

**Probe I — `.jd` is a markdown buffer (R2, and the accepted
consequence).** `fmtbin`, `t.jd`. Measured: saving invokes
`prettier --stdin-filepath <abs path to t.jd>`. `init.lua`'s
`extension = { jd = "markdown" }` is what routes it, so this probe is also
the standing proof that the consequence the user accepted is still the
behaviour.

**Probe J — the other two argv shapes (R2).** `fmtbin`, `x.rs` then `x.py`.
Measured: `ARGV:--emit=stdout --edition=2021` for rustfmt — the edition is
`util.parse_rust_edition`'s fallback, because the scratch tree has no
`Cargo.toml` — and `ARGV:--stdin-filename <abs path to x.py> --quiet -` for
black.

**Probe K — no configured formatter, no LSP, silence (R4).** `emptybin`,
`x.txt`, filetype `text`. Measured: disk unchanged, exit 0, captured
notifications `{}`. This is the fourth failure mode and the only silent one
that is correct.

**Hermeticity, asserted at the end of the stage:** the `curl` log holds no
GitHub or tree-sitter URL (mason's `api.mason-registry.dev` lines are E.9's
and are expected), the `git` log holds no `clone|fetch|ls-remote`, and no
probe output carries `Downloading tree-sitter`.

## `--formatters` (the real binaries — PRD acceptance 1 and 2)

The stage that needs `install.sh`'s new formulas. Same staged root, **no**
formatter shims on PATH — the real `stylua` and `prettier` resolve from
`/opt/homebrew/bin`. The `curl` and `git` shims stay.

- **PRD acceptance 1.** Save `x.lua` holding `local  x=1`. Assert the buffer
  and the file come back as stylua's output, that it changed, and that it
  arrived **within the 500 ms budget** — i.e. the save produced formatted
  bytes rather than a `Formatter 'stylua' timeout` notification.
- **PRD acceptance 2.** Save a markdown fixture the gate writes itself: a
  ragged three-column table, a `*` list, and one hand-wrapped prose
  paragraph of three short lines. Assert (a) the table's pipes align — every
  row's pipe columns identical; (b) the paragraph's three lines come back as
  **three lines with identical text**, which is `proseWrap: preserve` and the
  whole of R3; (c) prettier ran within the budget.
- **The accepted consequences, recorded not asserted.** Print, with a
  `MEASURED` prefix: prettier's diff stat against a copy of a real
  `prds/**/prd.md`, and stylua's diff stat against a copy of
  `home/dot_config/nvim/lua/plugins/conform.lua`. Assert only that both
  binaries exit 0. **Do not assert the diff is empty**: this repo carries no
  `.prettierrc` and no `.stylua.toml` (measured), so both tools run on their
  own defaults, and pinning an assertion to a board file another lane edits
  would go red for a reason this node did not cause. The numbers are for the
  human; spec01's report is where they get classified.

**Measure prettier's cold start before anything else in this stage.**
prettier is a node program and `format_on_save` gives it 500 ms. It is
unmeasured here, because prettier is not installed yet. If it does not fit,
the correct move is a **correction filed against R4's timeout**, not a
quietly widened `timeout_ms` — R4 names 500 ms and this node does not get to
re-take it.

**Note for whoever reads the argv here:** `prettier`'s `command` is
`util.from_node_modules("prettier")`, which walks parent directories for
`node_modules/.bin/prettier` and only then falls back to PATH. The scratch
root has no `node_modules`, so the PATH binary is what runs; in a JS project
the project's own prettier — and its `.prettierrc` — wins. That is a
feature, and it is why the repo-level defaults measured here are not what
every buffer sees.

## Acceptance

- [x] `bash tests/nvim-formatting.sh --tree` exits 0, and every selftest
      mutation above is reported red by the same check that passes on the
      real file.
- [x] `bash tests/nvim-formatting.sh --headless` exits 0 with probes A–K
      all PASS, and the run touches no real Neovim state
      (`assert_unchanged`). 107 PASS / 0 FAIL. There is a **probe L** as well,
      which spec02 did not ask for: probes F and G cover the fallback's
      *second* case (a listed formatter whose binary is missing), and the
      PRD's third acceptance box names the *first* one — a filetype with no
      configured formatter at all. `x.txt` plus the same in-process fake
      server closes it literally rather than by analogy.
- [x] Probe F passes with an **empty** notification list — the silent LSP
      substitution is proven, not assumed.
- [x] Probe E's second lua save in the same session emits no second
      notification.
- [x] `bash tests/nvim-formatting.sh --formatters` exits 0 with the real
      `stylua` and `prettier`, closing PRD acceptance 1 and 2, and prints
      both `MEASURED` diff stats.
- [x] With any of the four binaries removed from PATH, `--formatters` exits
      **127** with a `PROBE-ERROR … ASSUMPTION MISSING` line — not a skip,
      not a pass.
- [x] `bash tests/nvim-formatting.sh` (no argument) runs all three stages
      and exits 0.
- [x] **Amended 2026-08-23 by the orchestrator, and closed against the
      amendment.** The box asked that a staged root without `mason/registries`
      reproduce the `ENOTCONN` abort **and that the seeded one not** — quoting
      both runs. The first half holds. The second is false, so the box as
      written could not be closed by any correct implementation, and leaving
      it open would have recorded a working gate as unfinished.

      What closes it instead, all three landed and quoted below: the abort is
      reproduced; the seeding fix and the drain fix are each measured
      **failing**, with counts; and the probes are isolated from the race so
      they measure conform rather than a coin flip, with a three-arm control
      proving the isolation rather than asserting it.

      The bug itself now has a home — `00-delivery/corrections/offline-launch-eats-first-save`,
      whose R3 was corrected on this measurement. The evidence:
      Seeding the registries does NOT stop the abort. Measured on a root with
      the live `mason/registries` copied in, 5 of 5 identical probe-B runs
      still aborted with `E5113 … ENOTCONN` and left the file byte-identical
      with the shim log holding the formatter's argv. A second fix was tried
      and also failed: draining the loop under `pcall` before the write, first
      to a flat 1500 ms (1 of 6 still aborted) and then to five quiet 100 ms
      windows (3 of 6). It is a race on which blocking call is pumping when
      mason's refused promise rejects, and no amount of seeding or pumping
      wins it reliably.

      What the gate does instead, and it is stronger than the box asked for:
      the probe root is staged **without `lua/plugins/lsp.lua`**, the only
      file that loads mason — so probes A–L measure conform and never a coin
      flip — and a three-arm `race` control at the end of `--headless` runs
      the identical probe on the FULL config, with and without the drain, and
      prints all three abort counts. Only the isolated arm is asserted; the
      other two are the bug's own timing and must not redden this node. A
      representative run:

      ```
      MEASURED ENOTCONN aborts in 5 identical probe-B runs:
      MEASURED   full config, undrained : 2/5   <- the bug a user meets on an offline launch
      MEASURED   full config, drained   : 2/5   <- draining the loop first does NOT fix it
      MEASURED   isolated (no lsp.lua)  : 0/5   <- what every probe above ran on
      ```

      The registries seed is kept — it is a real seed source, it is cheap, and
      it is preconditioned like any other — but it is not the fix, and the
      gate's comments say so where someone would look. This belongs on
      [`offline-launch-eats-first-save`](../../../00-delivery/corrections/offline-launch-eats-first-save/prd.md),
      whose own reason line should stop saying the seed fixes it.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/nvim-formatting.sh --tree
bash tests/nvim-formatting.sh --headless
bash tests/nvim-formatting.sh --formatters
bash tests/nvim-formatting.sh          # all three, the node's verify

# the precondition is loud, not silent
env PATH=/usr/bin:/bin bash tests/nvim-formatting.sh --formatters; echo "rc=$?"

# the gate left the real config alone (it says so itself, on the last line)
bash tests/nvim-formatting.sh 2>&1 | tail -3
```
