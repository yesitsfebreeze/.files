---
spec: 02
node: 00-delivery/corrections/gate-home-isolation
task: W0.9
covers: R3, R4
verify: "F=$(mktemp -d); mkdir -p \"$F/.config/chezmoi\"; cp ~/.config/chezmoi/chezmoi.toml \"$F/.config/chezmoi/\"; /usr/bin/env HOME=\"$F\" GATES_GUARD_CFG=\"$F/.config/chezmoi/chezmoi.toml\" bash tests/managed-config.sh && [ ! -e \"$F/.cache/nushell\" ]"
---

# spec02 — the second offender, and the rule where the next author will meet it

Goal: close the audit (R3) and record the two-part isolation rule in the one
file every gate sources (R4).

**Files this spec may edit:**

- `tests/managed-config.sh`
- `gates/lib.sh`
- this ticket's own directory

`tests/deploy-skeleton.sh` is spec01's. Do not touch it here.

## The audit (R3) — every named gate, by name, measured not assumed

Each gate was run from a clean state (`~/.cache/nushell` removed first), then
the real user paths were re-hashed against a snapshot taken before any gate
ran. "clean" means: exit 0, and **not one** of `~/.cache/{nushell,starship,
television}`, `~/.zoxide.nu`, `~/.config/{nushell,television,chezmoi}`,
`~/.gitconfig`, `~/.local/share/chezmoi`, `~/.config/{wezterm,nvim}` moved a
byte.

| gate | verdict | evidence |
|---|---|---|
| `tests/deploy-skeleton.sh` | **DEFECTIVE** | exit 0, 60 PASS / 0 FAIL, and creates `~/.cache/nushell/init/{starship,zoxide,television}.nu` at 2280 / 1966 / 1809 bytes. **Two** unpinned sites, not one — see spec01. Fixed there. |
| `tests/managed-config.sh` | **DEFECTIVE** | exit 0, 64 PASS / 0 FAIL, and creates the same three files. Its `cz()` is the same shape as `deploy-skeleton`'s: five flags, no `HOME`. **Not previously reported.** Fixed here. |
| `tests/shell-init.sh` | clean — **verified, not inherited** | exit 0, 95 PASS / 0 FAIL, no real path moved. Its `cz()` wraps every call in `/usr/bin/env -i HOME="$S/home" PATH=… SHELL_INIT_BREW_PREFIXES=` and passes `--destination "$S/home"` — `HOME` and `--destination` are the same directory. It is the correct precedent and the model for both fixes. |
| `tests/provisioning.sh` | clean | exit 0, 115 PASS / 0 FAIL. Runs **no real chezmoi at all** — every `chezmoi apply` in its output is a `DRY` line from `install.sh` under poison stubs, and `install.sh` itself runs under `/usr/bin/env -i HOME="$HOME_SCRATCH" PATH=… HOMEBREW_PREFIX=…`. Re-checked 30s after exit for a late write: still clean, no stray process. |
| `tests/live-bugs.sh` | clean | exit 0, 159 PASS / 0 FAIL. Read-only by construction. Its only chezmoi call is `chezmoi source-path`, which its header already justifies; no init, no apply, no update. |
| `gates/tree-links.sh` | clean | exit 0, no real path moved. No chezmoi. (Reports 96 broken links in `.mi/prds` advisorily — **pre-existing, unrelated, routed below**.) |
| `gates/audit-findings.sh` | clean | exit 0, 101 PASS / 0 FAIL, no chezmoi. |
| `gates/manual-coverage.sh` | clean | exit 0, 19 PASS / 0 FAIL, no chezmoi. |
| `gates/probes.sh` | clean | scratches `NVIM_APPNAME` + all four `XDG_*` into a temp dir. It never runs chezmoi, and nothing it drives reads `$HOME` for a write path. |
| `gates/selftest.sh` | clean **for HOME**, defective for attribution | 25 PASS / 0 FAIL quiet, no real path moved. Its separate defect is R6 / spec03. |
| `gates/wave-status.sh` | clean **in itself** | `--matrix`, `--validate`, `--selftest` write nothing. But `--sweep` (= `just gates`) *invokes* `tests/deploy-skeleton.sh` and `tests/managed-config.sh`, so **`just gates` writes the user's home today**. That is inherited, not its own defect, and spec01 + S2.1 remove it. |
| `gates/lib.sh` | library, not a gate | no invocation of its own. Carries the rule — R4. |

**Two pre-existing findings to route elsewhere, not fixed here** (neither is a
`HOME` defect and both are outside this node's footprint):

1. `gates/tree-links.sh` reports **96 broken links across 90 files** in
   `.mi/prds`, concentrated in `00-delivery/decisions/wallpaper-opacity/specs/`
   — relative links written as if from the node directory rather than from
   `specs/`, so they resolve to paths like
   `.mi/prds/00-delivery/decisions/wallpaper-opacity/specs/00-delivery/…`.
   The gate exits 0 on them, so nothing is enforcing it.
2. `tests/shell-init.sh` watches `$HOME/.config/nushell` **as a whole** in its
   real-path snapshot. That directory holds the live `history.sqlite3-wal`,
   which the developer's own interactive Nushell rewrites at any moment —
   observed changing mid-session with no gate running. It passed every time it
   was run here, but it is a latent flake, and it will read as "the gate
   touched a real user path" when it did nothing. Narrowing it to
   `$HOME/.config/nushell/help` fixes it. **P.4's file, not this node's.**

## Boxes

- [x] **S2.1** — `cz()` in `tests/managed-config.sh` sets `HOME` to the same
      directory it passes as `--destination`, i.e. `$root/dest`:

      ```bash
      cz() {
        local root="$1"; shift
        HOME="$root/dest" \
        "$CHEZMOI" \
          --source            "$root/src" \
          --destination       "$root/dest" \
          ...
      }
      ```

      Rehearsed by the analyst in a scratch clone: **64 PASS / 0 FAIL**, no
      existing assertion disturbed, `~/.cache/nushell` absent afterwards.
      Unlike `deploy-skeleton` this file has **one** invocation site — it
      writes no PATH shim — so `cz()` alone is the whole fix here. Verified
      by running the fixed gate from clean.

      CONFIRMED: `grep -c` for a second chezmoi invocation site in this file
      finds none — no `bin/chezmoi` heredoc, no PATH shim — and the fixed gate
      run from clean leaves `~/.cache/nushell` absent.

- [x] **S2.2** — `tests/managed-config.sh` asserts it touched no real user
      path, before and after in the same run. This file **already sources
      `gates/lib.sh`** (line 45), so use the library rather than hand-rolling:
      `snapshot_paths` on entry, `assert_unchanged` on exit, exactly as
      `tests/provisioning.sh` and `tests/shell-init.sh` do.

      Watch the same list spec01's S1.4 names, and **not**
      `$HOME/.config/nushell` as a whole — see routed finding 2 above for why
      that is a flake, not a guard.

      DONE with `snapshot_paths` right after the preconditions and
      `assert_unchanged` immediately before the verdict line, so it brackets
      both stages in the same run. It reads:
      `PASS  the gate touched no REAL user path
      (~/.cache/{nushell,starship,television}, ~/.zoxide.nu,
      ~/.config/{nushell/help,television}, ~/.gitconfig)`.

- [x] **S2.3** — `gates/lib.sh`'s **guard section** (the `── the
      live-chezmoi-config guard ──` block, currently opening at the
      `GATES_REAL_CFG=` line) states the rule in **both halves**. Today the
      file states half 1 twice — in the header bullet at the top and in the
      section — and half 2 nowhere, which is why two gates shipped with it.
      The text must say, in the file's own voice:

      * flags bound where chezmoi **writes** — `--config`, `--config-path`
        (init only), `--destination`, `--persistent-state`, `--cache`;
      * `HOME` bounds what a script chezmoi **runs** inherits;
      * neither is sufficient alone, and a gate must do both;
      * the concrete evidence, so it is not read as caution:
        `home/run_after_generate-shell-init.sh` writes to a literal
        `$HOME/.cache/nushell/init`, and on 2026-08-21 a `--destination`-only
        gate put 2280 / 1966 / 1809-byte files into the developer's real home.

      Name `tests/shell-init.sh`'s `cz()` as the worked example.

- [x] **S2.4** — The `lib.sh` header inventory (the six-item list at the top,
      whose `guard_begin/guard_end` entry currently shouts "HOME DOES NOT
      ISOLATE CHEZMOI") gains the second half in the same breath. A reader who
      only ever reads the header must come away knowing there are two rules.
      Do not delete the existing sentence — it is half the rule and it is
      correct.

- [x] **S2.5** — The R3 audit table above is reproduced in the node's
      completion record so every gate named in R3 is reported on by name, and
      the two routed findings reach the corrections backlog. **Do not edit
      `.mi/prds/00-delivery/corrections/prd.md` yourself** — another lane
      holds it. Hand the two items to the orchestrator in the return message.

- [x] **S2.6** — R5 for this file: `/usr/bin/grep -c '^PASS'` on
      `bash tests/managed-config.sh` is **≥ 64** with **0** FAIL. Record the
      actual numbers. S2.2 adds `chk` lines, so the count should rise.

      MEASURED 2026-08-21, `bash tests/managed-config.sh` against the real
      `$HOME`: rc 0, `^PASS` = **65**, `^FAIL` = **0**. Up from 64 by exactly
      the one `chk` line S2.2 adds. `~/.cache/nushell` absent before and
      after.

- [x] **S2.7** — `just gates` leaves `~/.cache/nushell` absent, and its PASS
      count does not fall. Check `~/.cache/nushell` immediately before and
      after the sweep. **This is the box that proves the node**: the sweep is
      the thing that was damaging the machine, because it runs both defective
      gates. Note when recording the number that the orchestrator measured
      `667 PASS / 5 FAIL` on a sweep run concurrently with their own ticket
      edits, and that all five were R6's false positive — compare against a
      **quiet** sweep, or the number means nothing.

      MEASURED 2026-08-21, `just gates` with the real user paths hashed
      immediately before and immediately after the sweep in the same wrapper:

      | sweep | result |
      |---|---|
      | quiet board, all fixes in | rc 0, **677 PASS / 0 FAIL**, `~/.cache/nushell` **absent** before and after, and not one of the nine watched real paths moved a byte |
      | ~5 min later, same code | rc 1, **674 PASS / 3 FAIL** — see below, and no real path moved then either |

      677 against the orchestrator's 667: up ten (three from S1.3, one from
      S2.2, six from S3.4/S3.5), and the five false FAILs gone. Six
      `INDETERMINATE:` lines appeared in the quiet run, naming
      `.mi/prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec01.md`
      — a real concurrent lane writing a spec while `manual-coverage.sh` was
      under test. **Before this node that was a FAIL convicting
      `manual-coverage.sh`.** It is now a named, non-failing report, which is
      R6 working on live traffic rather than in a rehearsal.

      The second sweep's 3 FAILs are **not this node's** and not a
      regression. At 19:48 the orchestrator added task **T.8**
      (`02-terminal/07-grid-centering`) to `.mi/gantt/plan.json`, and
      `gates/waves.tsv` — which is not this node's file — has no row for it.
      One root cause, two cascades:
      `registry: every plan.json task appears in a wave row (missing: T.8)`
      turns `wave-status.sh --selftest` red, which turns its contract check
      red, which turns `preflight: gates/selftest.sh` red. 674 + 3 = 677:
      three PASSes became FAILs, none of them from a line this node wrote.
      Proved rather than argued — see the completion record in the node's
      `prd.md`. **Routed to the orchestrator: T.8 needs a `gates/waves.tsv`
      row.**

## Verify

The frontmatter `verify:` runs `tests/managed-config.sh` under a fake `HOME`
so the counterfactual never dirties the real one, and asserts the fake home
stayed clean. `GATES_GUARD_CFG` is `lib.sh`'s existing test-only hook, needed
because the live-config guard must have a config to watch.

Proved by the analyst before any edit: **pristine repo → rc 1** (64 PASS / 0
FAIL, `$F/.cache/nushell/init/` created); **rehearsed fix → rc 0** (64 PASS /
0 FAIL, absent). Real `~/.cache/nushell` absent throughout.

No `.gitconfig` needs seeding here — unlike `deploy-skeleton`, this gate makes
no git commit.

## Out of scope

- `tests/shell-init.sh` — verified clean; its `~/.config/nushell` flake is
  P.4's file and is routed, not fixed.
- `gates/tree-links.sh`'s 96 broken links — pre-existing, unrelated, routed.
- `gates/selftest.sh`'s attribution defect — R6, spec03.
- Any structural lint for the `HOME` pin; spec01 records why the behavioural
  guard is the enforcement instead.
