# probe notes — 07-multiplexer/06-nvim-session

Running log. Appended after each step so a dropped connection costs one step.

## Step 1 — context read (done)

Read:
- `prds/07-multiplexer/06-nvim-session/prd.md` — no `## Answers` on the child;
  the answers live on the epic.
- `prds/07-multiplexer/prd.md` — Q12/Q13 answers:
  - Q12: layout, cwds and nvim sessions come back; cost inside `done` 03-editor
    was named and accepted.
  - Q13: **a session plugin** owns save/restore, resurrect just re-launches
    nvim. Which of persistence.nvim vs auto-session is *the analyst's call to
    recommend*, explicitly delegated — so it is NOT a QUESTION verdict.
- `prds/memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md` — binding,
  uncommitted; does not constrain this node beyond resurrect being the caller.

Key constraint from the epic child table: footprint is `03-editor`'s files, so
this node takes the single-writer rule and amends `03-editor` where the plugin
list is stated.

Scope boundary: `07-persistence` owns resurrect/continuum. This node owns only
what makes nvim write and restore a session.

## Next

Step 2 — find the chezmoi source, read the live nvim plugin layout.

## Step 2 — live nvim config located

`chezmoi source-path` -> `/Users/feb/dev/.files/home` (pre-cutover, not this
repo). The rebuild's shipped nvim config is in this repo at
`home/dot_config/nvim/`:
- `init.lua` (options -> keymaps -> shift-select -> autocmds -> lazy)
- `lua/config/{options,keymaps,autocmds,shift-select,lazy}.lua`
- `lua/plugins/*.lua` — one file per plugin node, imported by
  `{ import = "plugins" }`; `plugins/init.lua` is a permanent empty anchor.
- `lazy-lock.json` committed beside init.lua; policy in `config/lazy.lua`:
  each plugin node commits its lockfile delta with its spec.

So the natural shape here is one new `lua/plugins/session.lua` + a lockfile
entry + a test + a help entry. That matches how every other 03-editor plugin
node landed.

## Step 3 — harness constraints found

- `gates/lib.sh` gives `chk`, `scratch_tree`, `snapshot_*`, `guard_*`.
- `gates/nvim-seed-registry.sh` is a derived set-equality gate: **every new
  `tests/*.sh` that launches nvim must carry either a `seed_parsers "` call
  or one immunity marker `# parser-seed: immune (<reason>) — <why>`** with
  reason from {noautocmd-edit, no-buffer-open, qa-only, owns-subject}.
  A new launcher is legal but must declare. This is a hard footprint item.
- Test runner rules (from tests/nvim-explorer.sh header, measured): results to
  stderr, XDG into scratch, `/usr/bin/grep` (bare grep is ugrep here), **no
  `timeout` binary on this machine**, never append `-c qa`.

## The real mechanism question (found by reading, to be measured next)

tmux-resurrect's `@resurrect-strategy-nvim 'session'` restores with
`nvim -S Session.vim` **only when `Session.vim` sits in the pane's cwd**.
Neither persistence.nvim nor auto-session writes `Session.vim` into cwd —
both write into a state dir keyed by cwd. So picking "a session plugin"
(Q13 answer 2) does not by itself satisfy the strategy that Q13's preamble
describes. The node has to bridge that, and how it bridges is the plugin
choice. Measuring next.

## Step 4 — measured: the resurrect interface

Read `tmux-resurrect/strategies/nvim_session.sh` (cloned to scratch, HEAD
2026-08-29):

    nvim_session_file_exists() { [ -e "${DIRECTORY}/Session.vim" ]; }
    main() { if nvim_session_file_exists; then echo "nvim -S"; ... }

So `@resurrect-strategy-nvim 'session'` restores **only** when a literal
`Session.vim` sits in the pane's cwd. Confirmed: neither candidate plugin
writes that file — persistence.nvim writes
`stdpath("state")/sessions/<cwd-with-separators-escaped>[%%branch].vim`,
auto-session writes into its own `root_dir`.

**But resurrect has a second, better hook**, read in
`scripts/process_restore_helpers.sh:108-170`: an *inline strategy* in
`@resurrect-processes`, `"~nvim->nvim <custom restore command>"`, splits on
the `->` token and uses the right-hand side as the restore command verbatim.
That means the restore can be `nvim -c 'lua require("persistence").load()'`
and no `Session.vim` is ever written into a working tree.

That is the interface this node publishes and `07-persistence` consumes.

## Step 5 — plugin comparison, measured not assumed

| | persistence.nvim | auto-session |
|---|---|---|
| lua LOC | 180 (2 files) | 4213 |
| branch-aware | **yes**, `branch = true` by default | yes |
| picker | **yes**, `M.select()` over `vim.ui.select` | yes, session-lens |
| augroup | `augroup("persistence", {clear=true})` — I7-clean | (larger surface) |
| restore | explicit only | automatic on bare `nvim` |

**The PRD's framing is wrong on both distinguishing points**: it says
persistence.nvim is the small lazy one and auto-session is "branch-aware and
brings a picker" — persistence.nvim is branch-aware by default and ships a
`select()` picker. The honest difference is size (180 vs 4213 lines) and
*when it restores*: persistence restores only when asked, auto-session
restores on every bare `nvim` in a known cwd.

Recommendation forming: **persistence.nvim**.

## Step 6 — spec file written

`home/dot_config/nvim/lua/plugins/session.lua` created (persistence.nvim,
`lazy = false`, `opts = {}` so `need = 1` stays, three `keys` under
`<leader>q`). Rationale carried in the file's header per the repo's
"preserve the hard-won why" rule. Next: lockfile row, then measure.

## Step 7 — probe one GREEN (9/9), minimal init

`prds/07-multiplexer/06-nvim-session/probe/session-roundtrip.sh`, run
2026-08-29 against nvim 0.12.4 and persistence.nvim @ b20b2a7:

    PASS Q1 exit with 2 files writes exactly one session file
         -> state/nvim/sessions/%private%var%...%work.vim
    PASS Q1 session names alpha.txt / beta.txt
    PASS Q1 session lives under XDG_STATE_HOME, not the work tree
    PASS Q1 no Session.vim written into the work tree
    PASS Q2 restore reopens alpha.txt / beta.txt
    PASS Q2b bare nvim restores nothing (restore is explicit)
    PASS Q3 exiting an empty nvim leaves the session untouched
    nvim stderr empty

So the mechanism holds, including the `need = 1` guard: a bare nvim opened
and closed in a directory does NOT overwrite that directory's session.

Also landed:
- `home/dot_config/nvim/lazy-lock.json` — one row added, in lazy's own
  one-line-per-plugin format (a `json.dumps(indent=2)` rewrite reformats
  all 19 other rows; reverted and inserted by hand).
- Live seed source `$HOME/.local/share/nvim/lazy/` has **no**
  persistence.nvim — every sibling nvim gate seeds from that directory and
  PROBE-ERRORs when a lockfile key is missing there. So the gate needs a
  `lazy sync` on the deployed config once, exactly the obligation every
  other plugin node carried. Writing to that directory is outside this
  node's footprint, so the gate takes a pinned-clone fallback.

Next: the staged run through the real config (lazy, all 20 rows).

## Step 8 — tree stage of `tests/nvim-session.sh` GREEN (17/17 + 3 selftests)

Gate written following the tests/nvim-explorer.sh idiom (nocode/comments
split so a comment cannot satisfy a code assertion; three counterfactual
selftests proving each check by its own red). Headless stage next.

## Step 9 — headless stage GREEN (12/12)

`bash tests/nvim-session.sh` is green end to end: 17 tree + 3 selftests +
12 headless. Measured facts, all through the real config under lazy:
- `plugins["persistence.nvim"].lazy = false`, loaded at startup,
  `#persistence#VimLeavePre` exists = 1, session dir created by setup().
- exit with two files -> exactly one session file, no `Session.vim` in cwd.
- `nvim -c "lua require('persistence').load()"` reopens both buffers.
- a bare `nvim` restores nothing.
- exiting an empty nvim does not touch the session (need = 1 holds).
- a non-default git branch gets its own `%%feature%x` session file.

One trap measured on the way: seeding a TRIMMED parser list (nine of the
sixteen) sends nvim-treesitter to the network at BufReadPost — seven
"Downloading tree-sitter-*" lines on stderr and a false red. The seed list
must be the full live set with PROBE-ERROR on absence, as its siblings do.

## Step 10 — a real collision found and fixed: `<leader>q`

persistence.nvim's documented prefix is `<leader>q`. This config already
binds `<leader>q` as a **leaf** map (`Quit`, lua/config/keymaps.lua, and
help entry `<leader>w and <leader>q`), so `<leader>qs` would turn every
quit into an ambiguous prefix that waits `timeoutlen` for a second key.
Swept the whole config for bound leader keys:

    - | b bd c ca cf e f fb ff fg fh p q r rn t tt w

`s` is free. Keys moved to `<leader>ss` / `<leader>sl` / `<leader>sd`, and
which-key needs a `session` group beside find/buffer/code/rename-refactor/
table. That group lives in `lua/plugins/which-key.lua`, whose R2 says group
names must stay in sync with the keys under them — checking that gate next.

## Step 11 — the lockfile row breaks fifteen sibling gates until the plugin
## exists live. This is the biggest consequence of the node and it is DEFINED.

`tests/nvim-small-plugins.sh` (and fourteen other nvim gates) seed their
scratch root from `$HOME/.local/share/nvim/lazy/<key>` for **every**
lazy-lock.json key, and treat an absent clone as `PROBE-ERROR ... exit 127`
— by design, so a lockfile row nobody installed cannot read as a skip.
Measured after adding the row:

    tests/nvim-small-plugins.sh --tree      52 PASS, 0 FAIL
    tests/nvim-small-plugins.sh (headless)  PROBE-ERROR: .../persistence.nvim
                                            is absent

Fifteen gates seed this way (grep `LOCK_KEYS\|seed_lazy` over tests/nvim-*):
autocmds, colorscheme, completion, explorer, formatting, keymaps, lsp,
markdown-tables, options, plugin-manager, shift-select, small-plugins,
statusline, telescope, treesitter.

This is precisely the defect `gates/nvim-seed-registry.sh`'s header records
("nvim-treesitter entering lazy-lock.json broke three gates at once"), now
reproduced by a second row. The remedy is one act, and it is the same one
every earlier plugin node needed: the plugin has to exist in the live clone
directory. `install.sh` has no `Lazy` step — plugins arrive when nvim first
runs the deployed config — and `just cutover` has not run, so nothing will
place it there on its own.

    git clone https://github.com/folke/persistence.nvim \
      "$HOME/.local/share/nvim/lazy/persistence.nvim"
    git -C "$HOME/.local/share/nvim/lazy/persistence.nvim" \
      checkout b20b2a7887bd39c1a356980b45e03250f3dce49c

Writing the developer's live Neovim state is outside an analyst's footprint
(the gates only ever READ it), so this is an implementer step with the
command written down, not something this pass performed. `tests/nvim-session.sh`
carries a documented pinned-clone fallback so THIS node's gate is provable
before that step happens; the siblings have no such fallback and must not
grow one from here (that is fifteen files and another node's contract).

## Step 12 — the manual entry, and what the content model gate enforces

Added one entry to `home/dot_config/nushell/help/nvim.nuon`, key
`<leader>ss <leader>sl <leader>sd`, topic `edit`, three `kind: "nvim-map"`
verify targets, `source:` this PRD. `nu tests/help-content-model.nu` is the
gate, and it caught three real things in one run:

1. **title must be imperative** — my first title opened "Bring back the
   buffers ..." and the gate reported "opens with the gerund `bring`". It is
   a suffix test and `bring` ends in `ing`; a false positive, filed as a
   finding, not fixed from here. Retitled "Restore the buffers you had open
   here", which is the better title anyway.
2. **every `why` needs a row in `why-review.nuon`** keyed by a digest of the
   exact (use, why) pair — `a3d233b599fb26ea` here.
3. **every entry needs a row in `use-review.nuon`** keyed by a digest of
   (use, source) — `b3919ace8b0a107e` here.

Both rows written. The gate then caught a fourth, which is the interesting
one:

    reviewer and author are both analyst-07-06-nvim-session — a record
    vouching for itself; it needs a reader who did not write it

So the manual entry is not closable by the session that writes it. An
independent reader is dispatched; its notes go into the two rows with its
own id. Until then this gate is RED, deliberately and visibly.

## Step 13 — the second census: tests/nvim-options.sh

`tests/nvim-options.sh` holds a literal, exhaustive file census of
`home/dot_config/nvim/`, so a new plugin file goes red there too. Updated
(one path plus a re-worded label naming this node). Verified green by
running every affected gate under a FAKE HOME whose
`.local/share/nvim/lazy/` is a directory of symlinks to the real clones plus
one to the scratch persistence.nvim checkout — the gates only ever read the
seed source, so a symlink farm is a faithful stand-in and proves the edits
without touching the developer's live Neovim state.

    HOME=<fake> bash tests/nvim-options.sh --tree   -> census PASS

## Step 14 — control run: the census edit is sound

Under the fake HOME, `tests/nvim-options.sh` also reports
`FAIL R1: mapleader = " "`. Controlled for: with session.lua moved aside and
the lockfile, which-key and census edits stashed, the SAME failure appears
under the same fake HOME. It is an artefact of the symlink-farm HOME (nvim
resolves state through it), not of this node's changes. The census check
itself passes with the new file listed.

Also observed while checking `git status`: `home/dot_config/nushell/config.nu`,
`help.nu` and `prds/00-delivery/corrections/g1-verify-still-red-on-just-gates/`
are dirty from the concurrent `06-help/04-drift-check` lane. Untouched here;
the stash used above was path-scoped for exactly that reason.

## Step 15 — independent reader recorded; help gate GREEN

A separate session read the pair against the plugin source, keymaps.lua and
tmux-resurrect, and its reading is recorded verbatim in both rows with
`reviewer: "reader-07-06-nvim-session"` distinct from
`author: "analyst-07-06-nvim-session"`. It found no overclaim in the `use`
and no restatement in the `why`, and recorded one precision on the `why`:
`nvim_session.sh` IS the Session.vim strategy, while this config uses the
inline custom-command strategy — the sentence stays true of the strategy
family, and the row says so rather than smoothing it over.

    nu tests/help-content-model.nu   -> ok   (97 entries, 0 violations)
    bash tests/nvim-session.sh       -> rc=0 (32 checks)

## Step 16 — what is left, and it is all defined

1. `git clone` persistence.nvim into `$HOME/.local/share/nvim/lazy/` at the
   pinned commit, so the fifteen sibling nvim gates seed again. Outside an
   analyst's footprint (they only read that directory), one command.
2. Nothing else. The build went through.

## Step 17 — specs written, verdict SPECCED

specs/spec01-persistence-plugin.md (9), spec02-gate.md (8),
spec03-manual-entry.md (6), spec04-live-clone.md (4). Sum 27, count 4.

## Step 18 — implementer pass: spec04 live clone DONE

    git clone https://github.com/folke/persistence.nvim \
      "$HOME/.local/share/nvim/lazy/persistence.nvim"
    git -C ... checkout b20b2a7887bd39c1a356980b45e03250f3dce49c
    rev-parse HEAD -> b20b2a7887bd39c1a356980b45e03250f3dce49c

Before the clone, `tests/nvim-options.sh --tree` PROBE-ERRORed at the seed
step ("/Users/feb/.local/share/nvim/lazy/persistence.nvim is absent"), so
even the tree stage was unrunnable. Re-running the gates next.

## Step 19 — spec02 GREEN, all boxes ticked

    bash tests/nvim-session.sh            rc=0   31 PASS, 0 FAIL
    bash tests/nvim-session.sh --tree     rc=0
    bash tests/nvim-session.sh --headless rc=0
    grep NOTE <output>                    no match — the pinned-clone
                                          fallback no longer fires
    bash gates/nvim-seed-registry.sh      rc=0, row: nvim-session  seeded
                                          "seed_parsers call + site/parser
                                           store write"

Comment-stripping confirmed in code, not just by selftest:
`nocode()`/`comments()` at tests/nvim-session.sh:61-62, and every tree
assertion routes through one of them.

## Step 20 — a REAL breakage the analyst pass could not see

With the live clone in place, `tests/nvim-small-plugins.sh` runs headless for
the first time and goes RED — 146 PASS, **5 FAIL**:

    FAIL  C/R2: five leader groups declared
    FAIL  C/R2: in R2's order, with their names
    FAIL  cf6: the ordered five-group readback goes red
    FAIL  cf7: four declared groups, not five
    FAIL — a check above is red
    (probe output: wk_decl_n=6, wk_decl=... | <leader>s=session)

Cause: this node's which-key `session` group makes it **six**, and that gate's
HEADLESS stage hardcodes the count and the ordered list at five. Its TREE
stage passes (`tree/R2: all five leader groups` — a set/order check that
tolerates the sixth), which is the only stage the analyst could run: the
headless stage PROBE-ERRORed on the absent clone and masked this.

This is the exact analogue of the `tests/nvim-options.sh` census update the
analyst DID make and DID put in spec01's footprint. `tests/nvim-small-plugins.sh`
is in no spec's footprint, so it is not mine to write. Reported, not fixed.

## Step 21 — spec03 verify block narrowed, and PROVEN falsifiable

The gate warning was right twice over. The old block was one line,
`nu tests/help-content-model.nu` — whole-workspace (97 entries across four
files), naming no footprint path. Replaced with a scoped `nu -c` block that
names all three footprint files plus `session.lua`, and asserts only this
node's entry: topic, mode, source, the three `nvim-map` kinds, each `desc`
present verbatim in `session.lua`, both digests recomputed from the entry and
compared to their review rows, and `reviewer != author` on both rows. The
whole-file gate is kept as the second command because acceptance names it.

**Two bugs found in my own first draft, both fixed:**

1. `str join \", \"` inside a `$"..."` interpolation is a nu parse error
   (`unexpected_eof`). The join is now a `let` before the `if`.
2. **The second command masked the first.** With the scoped block parse-erroring,
   the whole block still exited 0, because `nu tests/help-content-model.nu`
   ran after it and succeeded. Same class as the `chk "$(cmd)" $?` false-PASS
   `01-session-and-windows` found. Fixed with `set -e`.

Green:

    entry <leader>ss <leader>sl <leader>sd topic=edit mode=nvim:normal
    descs Restore session for this directory / Restore last session /
          Stop session save on exit
    use-digest entry=b3919ace8b0a107e row=b3919ace8b0a107e
    why-digest entry=a3d233b599fb26ea row=a3d233b599fb26ea
    reviewer=reader-07-06-nvim-session author=analyst-07-06-nvim-session
    ok - scoped
    help content model: 97 entries across 4 files, 9 topics, 16 prose-only
    ok                                                              rc=0

Three counterfactuals, each run against a temporarily-broken copy and then
restored (all three files verified byte-identical afterwards):

    CF1  why digest a3d233b599fb26ea -> ...eb   rc=1  FAIL why-digest
    CF2  reviewer := author                     rc=1  FAIL use-row-vouches-for-itself
    CF3  session.lua desc reworded              rc=1  FAIL desc-ne-session.lua

In none of the three did `help content model` print — so `set -e` demonstrably
stops the second command from masking the first. The fix is proven by its own
red, not by being green.

## Step 22 — a second masked breakage, this one INSIDE the footprint and fixed

`tests/nvim-shift-select.sh` also went red once the clone let it run headless:

    FAIL  tree: the census label names the generation this node created (post-E.14)

`tests/nvim-shift-select.sh:450` guards the census label by a literal token:

    c_label() { /usr/bin/grep -qF 'post-E.14 census' "$1"; }

The analyst's re-worded label read "holds exactly the census — the post-E.14
**set** plus lua/plugins/session.lua", which names the node but no longer
contains `post-E.14 census`. `tests/nvim-options.sh` IS in spec01's footprint,
so this one is mine. Re-worded to keep both the guarded token and the naming:

    tree: home/dot_config/nvim/ holds exactly the post-E.14 census plus
    lua/plugins/session.lua, added by 07-multiplexer/06-nvim-session

    bash tests/nvim-shift-select.sh   rc=0  157 PASS, 0 FAIL
    bash tests/nvim-options.sh        rc=0   74 PASS, 0 FAIL

Note the shape of the lesson, twice now: the absent live clone PROBE-ERRORed
the headless stage of fifteen gates, which hid BOTH consequences of this
node's edits. spec04 is not a tidy-up at the end — it is what makes the rest
of the node's gates able to fail.

## Step 23 — the exact repair small-plugins needs (NOT performed — out of footprint)

`tests/nvim-small-plugins.sh` is in no spec's footprint, so the five literal
five-group expectations below are reported, not edited. They are mechanical:

    1031  ok "C/R2: five leader groups declared"      'wk_decl_n=5'   -> 6
    1032  'wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code
           | <leader>r=rename/refactor | <leader>t=table'
                                             -> append ' | <leader>s=session'
    1134  cf6 expected line                  -> same append
    1137  the chk_fail grep -qxF control line -> same append
    1144  ok "cf7: four declared groups"     'wk_decl_n=4'   -> 5
    plus the probe's own `all_five_after_seeding` (built near :827) and the
    labels that say "five"/"ALL FIVE".

Whoever takes it should also decide whether the count stays a literal at all —
a sixth group broke it, a seventh will too.

## Step 24 — spec01 GREEN, all 8 boxes ticked

    bash tests/nvim-session.sh --tree        rc=0
    bash tests/nvim-small-plugins.sh --tree  rc=0  54 PASS, 0 FAIL
      PASS tree/R2: all five leader groups, each on its own line with its name
      PASS tree/R2: and in R2's declared order f < b < c < r < t
    bash tests/nvim-options.sh --tree        rc=0

which-key.lua group order confirmed by reading, not inferred: f 47, b 48,
c 49, r 50, t 51, **s 57** — the session group is last, after `table`, which
is what keeps the ascending-line-number order check green.

## Step 25 — full sixteen-gate sweep, post-clone

    autocmds        rc=0  114 PASS  0 FAIL  0 PROBE-ERROR
    colorscheme     rc=0  121       0       0
    completion      rc=0   74       0       0
    explorer        rc=0  107       0       0
    formatting      rc=0  137       0       0
    keymaps         rc=0  112       0       0
    lsp             rc=0  140       0       0
    markdown-tables rc=0  120       0       0
    options         rc=0   74       0       0
    plugin-manager  rc=0   65       0       0
    shift-select    rc=1  155       2       0   -> FIXED in step 22, now rc=0/157
    small-plugins   rc=1  146       5       0   -> out of footprint, step 23
    statusline      rc=0  193       0       0
    telescope       rc=0  136       0       0
    treesitter      rc=1  105       3       0   -> NOT this node, see step 26
    session         rc=0   31       0       0

**Zero PROBE-ERRORs anywhere** — spec04's clone did its job for all fifteen.

## Step 26 — treesitter's 3 FAILs are NOT this node's

    FAIL  counterfactual staging: the plain cp -R copy KEEPS parser/ and parser-info/
    FAIL  THE FALSE PASS: x.nu is highlighted from the clone's untracked leftovers

Both are the provenance counterfactual at tests/nvim-treesitter.sh:809-825.
It stages a root with a plain `cp -R` and requires the copy to KEEP untracked
`parser/` + `parser-info/` leftovers, so it can demonstrate the false pass that
`seed_clone` exists to strip. Measured:

    ls -d ~/.local/share/nvim/lazy/nvim-treesitter/parser
      -> No such file or directory
    ls -d ~/.local/share/nvim/lazy/nvim-treesitter/parser-info
      -> No such file or directory

The demonstration cannot stage because the leftovers it demonstrates against
are gone from the developer's live clone. It reads only nvim-treesitter's
directory, which this node never writes — the lockfile row, which-key group,
census label and help entry cannot reach it. Pre-existing machine state, out
of footprint, reported not fixed.

## Step 27 — spec04: four of five boxes ticked; the fifth is honestly open

    lockfile b20b2a7887bd39c1a356980b45e03250f3dce49c
    HEAD     b20b2a7887bd39c1a356980b45e03250f3dce49c   MATCH
    bash tests/nvim-session.sh   rc=0, zero NOTE lines — the pinned-clone
                                 fallback no longer fires
    sixteen-gate sweep           zero PROBE-ERRORs

Box 4 ("nvim-options.sh, nvim-small-plugins.sh and nvim-explorer.sh green end
to end") stays `[ ]`. options 74/0 and explorer 107/0 are green; small-plugins
is 146/5 for the six-groups reason in step 20, and its file is out of
footprint. Ticking it would be a false record, so it is left open with the
reason written into the spec above the box.

## Step 28 — the repo meta-gate, with a control

    bash gates/selftest.sh            rc=1  43 PASS  5 FAIL

Controlled against a clean worktree at HEAD (`git worktree add --detach`):

    CLEAN HEAD gates/selftest.sh      rc=1  45 PASS  3 FAIL
      FAIL  tree-links.sh accepts --selftest and exits 0 (rc 1)
      FAIL  manual-coverage.sh accepts --selftest and exits 0 (rc 1)
      FAIL  wave-status.sh accepts --selftest and exits 0 (rc 1)

So three of the five are **pre-existing at HEAD** and touch none of this
node's files. The remaining two are both `gates/retired-phrases.sh`, whose
own `CF13` reports `changed: /Users/feb/dev/dotfiles/prds`. Measured that
prds/ is NOT moving under it — `find prds -type f -exec shasum` taken either
side of a full selftest run diffed empty — so the carrier is something in the
dirty working tree, not a concurrent write. `gates/lib.sh:274-279` records
this exact hazard in its own words ("prds/ is the live board and every analyst
and the orchestrator write into it while a gate runs"), and three lanes hold
this tree right now. `tests/nvim-session.sh` is not in the meta-gate's scope
at all (it covers `gates/*.sh`; `bash tests/nvim-session.sh --selftest` exits
2, not a contract it is held to). Isolation run under way; result below.

## Step 29 — final state: 27 of 28 boxes, one open and named

    spec01-persistence-plugin   8/8   [x]
    spec02-gate                 9/9   [x]
    spec03-manual-entry         6/6   [x]
    spec04-live-clone           4/5   — box 4 open

The open box is spec04's fourth: "`tests/nvim-options.sh`,
`tests/nvim-small-plugins.sh` and `tests/nvim-explorer.sh` are green end to
end". Two of the three are (74/0 and 107/0). `tests/nvim-small-plugins.sh` is
146/5 because its headless `C/R2` checks hardcode **five** which-key leader
groups and this node's `session` group makes it six. That file is in no
spec's footprint; the exact five-line repair is in step 23. Nothing else on
the node waits on anything.

The `gates/retired-phrases.sh` CF13 isolation run is a diagnostic on a
meta-gate failure that is out of footprint either way — three of the five
`gates/selftest.sh` failures already reproduce on a clean worktree at HEAD,
and the meta-gate does not cover `tests/*.sh` at all. It gates no box and the
node is not held for it.

## Verdict: DONE, with one box open on another node's file.
