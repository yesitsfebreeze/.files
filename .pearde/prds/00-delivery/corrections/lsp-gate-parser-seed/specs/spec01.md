---
est: 0.5h
footprint:
  - tests/nvim-lsp.sh
---

# spec01 — port `seed_parsers` into `tests/nvim-lsp.sh`

`tests/nvim-lsp.sh` seeds every `lazy-lock.json` key and then opens
`work/a.lua`. Since `nvim-treesitter` entered the lockfile, that `:edit`
loads the plugin, whose `config` calls `install()` for sixteen languages on
every launch. Port the `seed_parsers` helper from `tests/nvim-options.sh`
and call it from `seed_lazy`. Twenty-six inserted lines, no deletion, no
assertion touched.

## Measured, 2026-08-23, by the analyst

A frozen copy of `gates tests home prds docs AGENTS.md` outside the repo,
lockfile md5 `245b535bae0e89c9261276c8df1b2dc1` before and after both runs.
Both runs serial, nothing else running.

| state | tally | exit | `got: TIMEOUT` | `tree-sitter-` URLs | wall clock |
|---|---|---|---|---|---|
| unmodified | PASS=60 FAIL=65 | 1 | 4 | 15 | 16m 12s |
| with this port | **PASS=125 FAIL=0** | **0** | **0** | **0** | 2m 32s |

125 is the pre-landing count, so the repair restores the gate exactly. All
nine `hermeticity:` checks go green, including `the shim log holds no
package-download URL` — the tarball URLs match its `\.tar\.gz` pattern, so
that box is a second, independent witness that no parser download was
attempted.

**The failure is a hard abort, not a slow run.** Measured in an isolated
staged root: with no parser store the leftover master-era
`nvim-treesitter/parser/lua.so` resolves for `lua`, and
`queries/lua/highlights.scm` — identical at line 74 in `$VIMRUNTIME` and in
the clone — fails to compile against it: `Query error at 74:3. Invalid field
name "operator"`. The error propagates out of the `FileType` autocmd,
through `nvim_exec2`, out of `vim.cmd("edit …")`, and kills the probe chunk
at line 4. `vim.cmd("qa!")` never runs, so nvim idles until the 60 s
watchdog. That is why the tally is deterministic and why it cannot be a
flake: four probes, four aborts, ten counterfactual re-runs of the same two
scripts.

**This is why the two repaired siblings failed differently.**
`tests/nvim-options.sh` and `tests/nvim-telescope.sh` open only `.txt`
files, so they lost time to the downloads but never hit a query. This gate
opens `.lua`.

## The edit

The helper is byte-identical in `tests/nvim-options.sh` (lines 98-113) and
`tests/nvim-telescope.sh` (lines 127-142). md5
`a3d324ba9459a09682c9f40a4dde0d3e` over those sixteen lines. **Copy from
`tests/nvim-options.sh`. Do not retype it.**

Insert the helper between `need_seed_source`'s closing `}` and
`seed_lazy() {`, with a comment naming the source. Then add the gated call
inside `seed_lazy`, after the `done <<< "$LOCK_KEYS"` line and before the
closing `}`:

```sh
  # After the clone loop, so the queries symlinks resolve inside the seeded
  # clone; every caller of seed_lazy is covered.
  if printf '%s\n' "$LOCK_KEYS" | /usr/bin/grep -qx 'nvim-treesitter'; then
    seed_parsers "$1"
  fi
```

The guard reads `LOCK_KEYS`, so the seed arms and disarms with the lockfile
and no future plugin node has to edit this gate.

## Do NOT strip the leftovers, and do NOT add an assertion

PRD R3 asks for a strip and for the gate to assert the pair. Both are
wrong here, measured:

- **The ported helper does not strip anything.** It writes
  `site/parser/<l>.so` and `site/queries/<l>`. Only
  `tests/nvim-treesitter.sh`'s `seed_clone` strips `parser/` and
  `parser-info/`, and that is a different function in a different file.
- **The strip is not needed.** Three isolated staged roots, same config,
  same shims: leftovers kept and no parser store → `edit` throws,
  `parser_lua` resolves to
  `data/nvim/lazy/nvim-treesitter/parser/lua.so`, `installed_n=0`, 16 curl
  attempts. Leftovers **kept** and the store seeded → `edit` succeeds,
  `parser_lua` resolves to `data/nvim/site/parser/lua.so`,
  `hl_lua=true`, `installed_n=16`, 0 curl attempts. Leftovers stripped and
  seeded → byte-for-byte the same result. `lazy.nvim`'s `add_to_rtp` inserts
  plugin directories *after* `$XDG_DATA_HOME/nvim/site`, so the seeded store
  wins and there is no false pass to inherit.
- **The pair is already asserted by its owner.**
  `tests/nvim-treesitter.sh` proves it twice — `prov_ok` after every
  stripped stage, and the provenance counterfactual that shows `hl=true`
  with `installed=` empty. Restating it here would give one fact two owners.

PRD R2 governs: no assertion in this file changes. The diff is insertions
only.

## R4 — the census

Only eight gates launch Neovim; `grep -c 'NVIM_BIN\|nvim --headless'` over
the other twenty-four returns 0, so they are out of the exposure class by
construction. `gates/probes.sh`'s `nvim_probe` runs `-u <fixture init>`
with no lazy and no lockfile, so it is out too.

| gate | seeds every lockfile key | opens a file | verdict |
|---|---|---|---|
| `tests/nvim-options.sh` | yes | yes — `work/long.txt`, `work/undo.txt` | REPAIRED, `seed_parsers` present |
| `tests/nvim-telescope.sh` | yes | yes — `edit aaa.txt`, `edit bbb.txt` | REPAIRED, `seed_parsers` present |
| `tests/nvim-treesitter.sh` | yes, via `seed_clone` | yes — `x.nu`, `z.lua`, `x.go` | IMMUNE by design: it owns the seed, strips the leftovers, and its cold and provenance stages download on purpose behind their own curl log |
| `tests/nvim-lsp.sh` | yes | yes — `edit $PROBE_FILE` (`work/a.lua`) in all four probe scripts | **EXPOSED — this node** |
| `tests/nvim-completion.sh` | yes | **no** — `doautocmd InsertEnter` and `setfiletype lua` only; neither fires `BufReadPost` or `BufNewFile` | unexposed, verified |
| `tests/nvim-colorscheme.sh` | yes | **no** — `+luafile readback.lua` / `rederive.lua`; neither script touches a buffer | unexposed, verified by reading both heredocs, not by trusting the claim at line 62 |
| `tests/nvim-plugin-manager.sh` | yes, in the hermetic stages | **no** — `+qa`, `+luafile optprobe.lua`, `+luafile demoprobe.lua` | unexposed, verified. Its `--network` stage is deliberately online with a 180 s budget; `Lazy! sync` runs `build = ":TSUpdate"`, a measured no-op on an empty store |
| `tests/nvim-statusline.sh` | yes | **no** — every probe uses `noautocmd edit sub/note.txt`, so only `BufEnter` fires | unexposed, and it is the only gate that *proves* it: `render: nvim-treesitter never loaded` asserts `ts_loaded=false`, and the seed block carries the reason plus "if a future probe here ever uses a plain `:edit`, add the seed back" |

`event = { "BufReadPost", "BufNewFile" }` in
`home/dot_config/nvim/lua/plugins/treesitter.lua` is what makes "opens a
file" the discriminator. `setfiletype` and `doautocmd InsertEnter` do not
reach it.

**A second widening landed during this analysis, and the class held.**
`statusline.lua` plus a two-key `lazy-lock.json` growth (`lualine.nvim`,
`nvim-web-devicons`) were written at 16:20 and 16:21, and
`tests/nvim-statusline.sh` at 16:37. Neither new plugin fetches at load
time, so the class does not fire, and the new gate declares its immunity.

The widening did invalidate one measurement: `LOCK_KEYS` is computed once at
gate start, so a run already in flight staged a config asking for thirteen
plugins while eleven were seeded, and lazy `git clone`d the missing two for
real — two `.git` URLs in the shim log and two extra hermeticity reds.
Re-run a gate whose staged tree moved underneath it.

## R5 — no shared helper

The `sibling-gates-copymode-staging` R2 argument transfers in full, and one
more reason applies here.

- A helper only constrains the gates that call it. The next gate that
  hand-rolls its own staging escapes it, exactly as `shell-television`
  escaped `shell-help.sh`'s maintained `SIBLINGS` list.
- The helper's body is not stable. It hardcodes sixteen language names that
  already exist twice — `install()`'s list in `treesitter.lua` and
  `$WANT_LANGS` in `tests/nvim-treesitter.sh`. A shared copy would be a
  third.
- Its only home is `gates/lib.sh`, which every gate sources. That is the
  maximum blast radius across files owned by other nodes.

**The exposure is not derivable from `LOCK_KEYS` either.** It has three
conditions and only the first derives cleanly: the gate seeds every
lockfile key (greppable); the gate opens a file (semantic — `setfiletype`
and `doautocmd` look identical to a grep); some lockfile plugin fetches at
**load** time (not derivable from the lockfile at all — `nvim-treesitter`
qualifies because its `config` calls `install()`, while
`telescope-fzf-native`'s `build = "make"` does not).

So the generalisation is not a helper and not a full drift gate. It is a
cheap derived registry check: every gate that seeds every lockfile key and
launches a staged Neovim must either call `seed_parsers` or carry one
greppable claim of immunity. Both sides derive from the gate text, and the
burden of the claim sits on the gate rather than on a central list. It would
have caught this node.

The pattern is already in the tree, unprompted and in two strengths:
`tests/nvim-colorscheme.sh` line 62 states it in a comment, and
`tests/nvim-statusline.sh` states it in a comment **and asserts it** —
`ts_loaded=false`. Standardise on the statusline form. File it as its own
node; it is out of scope here.

## Run the gate ALONE

Two implementers are working the board, and one of them wrote into
`home/dot_config/nvim/` during this analysis. Before running, `md5 -q
home/dot_config/nvim/lazy-lock.json`; after, check it again. A run whose
lockfile moved is void — re-run it.

`git diff` cannot prove this change: `tests/nvim-lsp.sh` is untracked, so a
diff over it is empty by construction. Copy the file aside first and diff
against that copy.

## Acceptance

- [x] `grep -c seed_parsers tests/nvim-lsp.sh` is **2**, and the sixteen
      helper lines are byte-identical to `tests/nvim-options.sh` lines
      98-113 — md5 `a3d324ba9459a09682c9f40a4dde0d3e`. Quote both. The
      comment above the helper names `tests/nvim-options.sh` as the source.
- [x] The reconstructed diff against a `cp`-aside baseline is **26
      insertions, 0 deletions**, and
      `grep '^>' | grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!='`
      over it is **0**. Quote all three numbers.
- [x] `bash tests/nvim-lsp.sh`, run alone, reaches **PASS=125 FAIL=0,
      EXIT=0**. Quote the tally and the exit code. A lower PASS total is not
      a pass: it means a check disappeared.
- [x] `grep -c 'got: TIMEOUT'` over that run's output is **0**, and all four
      probe lines read `(got: 0)`. Quote the four lines.
- [x] `grep -c 'tree-sitter-'` over that run's output is **0**, and the
      `hermeticity: the shim log holds no package-download URL` box is PASS.
      This is the anti-luck check: it fails on a run that merely got faster.
- [x] The run is reproduced a **second** time with the identical tally, and
      `md5 -q home/dot_config/nvim/lazy-lock.json` is the same before the
      first run and after the second. Quote the md5 and both tallies.
- [x] The R4 census table above is in the report with a verdict per gate,
      re-confirmed by the two greps in step 6 of Verify: eight gates launch
      nvim, and `seed_parsers` count per gate. The board is moving — report
      any gate that appeared, or whose verdict moved, since 2026-08-23 16:40.
- [x] The R5 recommendation is in the report as **no shared helper**, with
      the three-condition argument for why `LOCK_KEYS` does not make this
      case different.
- [x] `gates/waves.tsv` is byte-identical across the whole run — same md5
      before and after. `tests/nvim-lsp.sh --tree` and `--headless` are
      already registered in wave 4 (confirmed 2026-08-23), so nothing is
      appended. The orchestrator owns that file and
      `gates/manual/wave*.md`.

## Verify and Proof

```sh
# 0 — baselines: the file aside, the two md5s that must not move
T="$(mktemp -d)"
cp tests/nvim-lsp.sh "$T/baseline.sh"
md5 -q home/dot_config/nvim/lazy-lock.json | tee "$T/lock.before"
md5 -q gates/waves.tsv | tee "$T/waves.before"

# 1 — the helper is byte-identical in both repaired siblings
sed -n '98,113p'  tests/nvim-options.sh   | md5 -q
sed -n '127,142p' tests/nvim-telescope.sh | md5 -q

# 2 — the edit: copy the helper in, then add the gated call. Two insertions,
#     nothing deleted, no assertion. Make it, then prove it.
grep -c seed_parsers tests/nvim-lsp.sh

# 3 — the reconstructed diff: insertions only, no assertion token
diff "$T/baseline.sh" tests/nvim-lsp.sh > "$T/port.diff"
printf 'insertions=%s deletions=%s assertions=%s\n' \
  "$(grep -c '^>' "$T/port.diff")" "$(grep -c '^<' "$T/port.diff")" \
  "$(grep '^>' "$T/port.diff" | grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!=')"

# 4 — the gate, ALONE, twice
for run in 1 2; do
  bash tests/nvim-lsp.sh > "$T/run$run.log" 2>&1
  printf 'run%s EXIT=%s PASS=%s FAIL=%s TIMEOUT=%s TS=%s\n' "$run" "$?" \
    "$(grep -c '^PASS' "$T/run$run.log")" \
    "$(grep -c '^FAIL' "$T/run$run.log")" \
    "$(grep -c 'got: TIMEOUT' "$T/run$run.log")" \
    "$(grep -c 'tree-sitter-' "$T/run$run.log")"
done
grep -E 'headless: .* no TIMEOUT' "$T/run1.log"
grep 'no package-download URL' "$T/run1.log"
grep '^FAIL' "$T/run1.log"

# 5 — nothing moved underneath the run
md5 -q home/dot_config/nvim/lazy-lock.json; cat "$T/lock.before"
md5 -q gates/waves.tsv; cat "$T/waves.before"

# 6 — the R4 census, re-derived
for f in tests/*.sh; do
  n=$(grep -c 'NVIM_BIN\|nvim --headless' "$f")
  [ "$n" -gt 0 ] && printf '%s nvim=%s seed_parsers=%s\n' \
    "$f" "$n" "$(grep -c seed_parsers "$f")"
done
grep -n 'vim.cmd("edit\|setfiletype\|doautocmd' \
  tests/nvim-completion.sh tests/nvim-colorscheme.sh \
  tests/nvim-plugin-manager.sh tests/nvim-lsp.sh
```
