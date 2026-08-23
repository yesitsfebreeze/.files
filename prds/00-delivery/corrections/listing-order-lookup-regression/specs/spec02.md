---
est: 1.25h
footprint:
---

# spec02 — census every gate for a substring positional lookup

R5, and the durable half of this node. Two gates have been bitten by the same
shape in one session — `tests/nushell-core.sh`'s CP.9 counterfactual (caught
before shipping) and `tests/shell-listing.sh`'s T1 (caught after) — so the
question is no longer "is this one fixed" but "how many more are waiting".
Sweep `tests/` and `gates/` for first-match greps whose result is used as a
**position**, and record a verdict per site.

**This spec writes no files.** `footprint: []` is deliberate: the census is a
read-only measurement and its record is the implementer's report, which is
what the orchestrator carries onto the node's transition. Do not add a
`census.md` under `prds/` — that tree holds PRDs and nothing else — and
do not create sibling correction folders; name the follow-ups and let the
orchestrator file them.

## The verdict rules, which are the board's

From [the corrections backlog](../../prd.md), "How a census records a
verdict": the verdict is one of **`reproduced` / `refuted` / `unmeasured`**,
never `exact` and never `the last carrier`; the fixture or search predicate
goes beside it in one parenthesis; and a cheap claim is run **twice with a
different input**.

Two claims per site, so each gets its own word:

- **A — "this site is defused today."** Predicate: run the site's own lookup
  and a line-start-anchored lookup against the real file it reads, and compare.
  `reproduced` when they disagree and the substring one lands on a comment.
- **B — "a comment quoting the target would defuse this site silently."**
  Fixture: the file with a `#`/`--` line quoting the target inserted above the
  declaration, plus the answer to *is there a count assertion beside the
  lookup*. A `-cF … -eq 1` guard next to a positional lookup turns a duplicate
  into a **red**, so B is `refuted` there even though the lookup is a
  substring — the defusal is loud, not silent. That distinction is the census's
  most useful column and it is the one a grep alone cannot produce.

## Enumeration, not sampling

Enumerate with a predicate the report quotes, so the next analyst can re-run
it rather than trust it. The two shapes that produce a position:

```sh
# a line number out of a search
/usr/bin/grep -rnE 'grep -n|print NR|index\(\$0' tests gates \
  | /usr/bin/grep -E 'head -1|head -n1|tail -1|sed -n .[0-9]p|print NR'
# …used as a position: compared with another line number, or bounding a range
/usr/bin/grep -rnE '\-lt |\-gt |\-le |\-ge |sed -n "\$\{' tests gates
```

Classify each site on four axes, then give both verdicts:

1. **lookup form** — substring (`grep -F`, plain `grep`), line-anchored regex
   (`^…`), whole-line (`grep -x`), start-of-string (`index($0,s)==1`), or a
   **comment-stripped input** (`nocomm`, `grep -v '^[[:space:]]*#'`).
2. **input class** — prose-bearing (a managed config, a `.lua`, a board
   `prd.md`) or machine output (`invocations.log`, a rendered `$env.PATH`, a
   flattened Dockerfile).
3. **count guard beside it** — yes / no.
4. **`head -1` or `tail -1`** — a leading quote defuses `head -1`; a trailing
   one defuses `tail -1`.

## The seed the analyst measured — verify it, do not trust it

Re-run each row's predicate; a row that does not reproduce is a finding in
itself. Line numbers are as of 2026-08-23.

| site | reads | form / guard | verdict A | verdict B |
|---|---|---|---|---|
| `tests/shell-listing.sh:108` `order_ok` core | `config.nu` | substring, no guard, `head -1` | **`reproduced`** (161 comment vs 202 decl) | `reproduced` — spec01's subject |
| `tests/shell-listing.sh:109-110` `def ls [` / `def la [` | `config.nu` | substring, no guard | `refuted` (278/302 both ways, 1 hit each) | `reproduced` (injected quote answers at line 1) |
| `tests/shell-listing.sh:141-142` in-block `^stty sane` / ` la ` | the append block | substring, indented targets | `refuted` (block 490-500 holds no comment) | `reproduced` — `config.nu:400` already quotes ``try { la \| print }``, 90 lines above the block |
| `tests/nushell-core.sh:380-382` `funnel_binds` | `config.nu` | substring, no guard | `refuted` (365 / 534 both ways) | `reproduced` — the file anchored `textual_order_ok` and left this one |
| `tests/nushell-core.sh:566-568` S3.9, `:594-596` S4.13 | `config.nu` | substring, no guard | `refuted` (309/333/378, 533/534/535) | `reproduced` |
| `tests/capsule-lifecycle.sh:93-101` ten-def roster | `capsule.nu` | substring **with `-cF … -eq 1`** | `refuted` | **`refuted`** — the count guard makes a quote go red |
| `tests/capsule-lifecycle.sh:667` s13 control | mutated `capsule.nu` | substring, no guard | `refuted` (455 / 378) | `reproduced` |
| `tests/capsule-credentials.sh:143-144` `git_fill_ok` | `capsule.nu` | substring, indented | `refuted` — `:208` says `GIT_TERMINAL_PROMPT=0`, the lookup wants `: "0"` | `reproduced`; the file's own comment on the next line already states the lesson for the *presence* check only |
| `tests/wezterm-copy-mode.sh:76-77`, `:141-143` | `wezterm.lua` | substring, no guard, mixed `head`/`tail` | `refuted` (602/603, 1201/602) | `reproduced` — highest-exposure input on the board, 595 of 1237 lines are comments |
| `tests/wezterm-startup-layout.sh:104-105` R14 | `wezterm.lua` | substring, no guard | `refuted` (1141 / 1144) | `reproduced` |
| `tests/wezterm-tab-content-state.sh:192-193`, `:270-271` | a `wezterm.lua` block | substring on `return true` / `return false` / `get_foreground_process_name` | `refuted` | `reproduced` — the loosest targets in the sweep |
| `tests/shell-television.sh:199-206`, `:214-221` | `config.nu` | substring for the anchors and source lines, `-cxF` guard on one of them only | `refuted` | `reproduced` for the unguarded positions |
| `tests/shell-help.sh:159-165` `capture_ok` | `config.nu` | `-nxF` **whole-line** for the three ordered lines, `line_of` for the two anchors | `refuted` — and note `config.nu:555` *does* quote `use std/help`, which the whole-line match correctly ignores | `refuted` for the `-nxF` three, `reproduced` for the two anchors |
| `tests/shell-history.sh:185-190`, `:226-228`, `:271-272` | `config.nu`, `history.nu` | substring, indented targets at `path_ok` | `refuted` | `reproduced` |
| `tests/shell-claude.sh:103-108`, `tests/shell-zoxide.sh:136-140`, `:452`, `tests/nushell-aliases.sh:197-201` | `config.nu`, `zoxide.nu`, `pass.nu` | substring; `nushell-aliases` uses `-nxF` for the source line | `refuted` | `reproduced` for the substring rows |
| `tests/theme-switcher.sh:267-270` | `config.nu` | `^# ── X ──$` anchored + `-nxF` | `refuted` | **`refuted`** — anchored |
| `tests/nvim-statusline.sh:213-214`, `tests/nvim-colorscheme.sh:160-161` | `.lua`, through `nocomm` | comment-stripped input | `refuted` | **`refuted`** — comments removed before the search |
| `tests/nvim-autocmds.sh:450-451` | a derived require list, `grep -nx` | whole-line on derived text | `refuted` | **`refuted`** |
| `tests/dev-image.sh:145-150`, `tests/provisioning.sh:251-252`, `:377`, `tests/shell-init.sh:461-463` | flattened Dockerfile, `install.sh`, run log | `^RUN`/`^export PATH=`/`^# --- 1\.` anchored, or machine output | `refuted` | **`refuted`** |
| `tests/capsule-credentials.sh:652`, `tests/capsule-lifecycle.sh:397` `log_ln` | `invocations.log` | `^exec`/`^build` anchored, machine output | `refuted` | **`refuted`** |
| `tests/wezterm-launchd-path.sh:212`, `:872` | `wezterm.lua`, a rendered PATH | substring on a `-- ──` banner (1 hit); `-nxF` on PATH entries | `refuted` | `reproduced` for the banner, `refuted` for the PATH |
| `tests/live-bugs.sh:174` | the **live** `~/.config/nvim/**` | substring, bounds a `sed -n` range read | `refuted` | `reproduced` — a comment shifts the 7-line window, which changes what L-8 concludes |
| `gates/wave-status.sh:337` | `prds/06-help/prd.md` | `\[tv needs a$` end-anchored, bounds a 2-line read | `refuted` (1 hit) | `reproduced` — the only prose *document* read positionally |
| `gates/tree-links.sh:89` | a `prds/README.md` fixture copy | substring `outside the fence` | `refuted` (0 hits in the real README) | `reproduced` |
| `gates/nushell-module-staging.sh:88` | `config.nu` | `^source ~/…$` anchored | `refuted` | **`refuted`** |

## The detector, run twice with a different input

The cheap claim here is "no other site is defused today". Run this over two
**disjoint** input sets and quote both:

```sh
det() {
  awk -v F="$1" '
    /^[[:space:]]*(#|--)/ { cmt[NR]=$0; next }
    { l=$0; gsub(/^[[:space:]]+/,"",l); if (length(l)<8) next
      for (n in cmt) if (n<NR && index(cmt[n],l)) {
        printf "%s: code %d [%s] quoted at comment %d\n", F, NR, l, n; break } }' "$1"
}
```

Set 1, the managed tree (`home/**` `.nu` `.lua` `.sh` `.toml`), measured 14
hits — of which `config.nu:202 [alias core-ls = ls]` quoted at 161 is the one
a gate reads positionally, and `config.nu:496 [try { la | print }]` quoted at
400 is the one spec01's comment-stripping fix pre-empts. Set 2, the gate
fixtures (`gates/fixtures/**`), measured **zero** hits. Report both, and treat
a *new* hit as a finding.

## Acceptance

- [ ] Every positional lookup in `tests/` and `gates/` enumerated with
      `file:line`, the enumeration predicate quoted so it can be re-run, and
      the count of sites stated. No sampling.
- [ ] Each site carries the four classification axes and **both** verdicts,
      each verdict one of `reproduced` / `refuted` / `unmeasured` with its
      predicate or fixture in one parenthesis. No `exact`, no "the last
      carrier", no verdict without a run behind it.
- [ ] Every row of the seed table above re-measured, and any row that does not
      reproduce reported as a finding against this spec.
- [ ] The detector run over the two disjoint input sets, both outputs
      quoted — the twice-with-a-different-input rule, satisfied by a run
      and not by a sentence.
- [ ] The count-guard column is populated, and the census states plainly how
      many substring positional sites on prose-bearing input have **no** count
      guard beside them — that number is the size of the remaining exposure.
- [ ] Every verdict-A `reproduced` row (a check defused *today*) named with the
      node that owns its file, as a recommended follow-up for the orchestrator
      to file. No sibling PRD folder created, no other node's file touched.
- [ ] The report names the three mitigation shapes already present on the
      board — line-start anchoring (`tests/nushell-core.sh:401-410`),
      comment-stripped input (`nocomm`, `tests/nvim-statusline.sh:152`), and a
      count assertion beside the lookup (`tests/capsule-lifecycle.sh:98`) —
      and says which one fits each remaining site. A census that recommends
      one hammer for four shapes is not measured.
- [ ] No file under `tests/`, `gates/`, `home/`, or `prds/` other than this
      node's `specs/` is modified: `git status --porcelain` quoted.

## Verify and Proof

```sh
# 1 — enumeration
/usr/bin/grep -rnE 'grep -n|print NR|index\(\$0' tests gates \
  | /usr/bin/grep -E 'head -1|head -n1|tail -1|sed -n .[0-9]p|print NR' | wc -l
/usr/bin/grep -rnE '\-lt |\-gt |\-le |\-ge ' tests gates | wc -l

# 2 — per-site verdict A: the site's lookup versus a line-start anchor
sub()  { /usr/bin/grep -nF -- "$2" "$1" | head -1 | cut -d: -f1; }
anch() { awk -v s="$2" 'index($0,s)==1{print NR;exit}' "$1"; }
# …run for every substring site's real target file, and quote both numbers

# 3 — verdict B: does a quoting comment capture the lookup?
#     copy the file, insert `#   * \`<target>\` …` above the declaration,
#     re-run the site's own lookup, and check for a count guard beside it

# 4 — the detector, both input sets
for f in $(find home -type f \( -name '*.nu' -o -name '*.lua' \
           -o -name '*.sh' -o -name '*.toml' \) | sort); do det "$f"; done
for f in gates/fixtures/nu/*.nu gates/fixtures/nvim/*.lua \
         gates/fixtures/wezterm/*.lua; do det "$f"; done

# 5 — nothing was written
git status --porcelain
```
