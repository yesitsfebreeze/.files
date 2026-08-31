---
est: 0.75h
footprint:
  - tests/help-browser.sh
---

# spec02 — `tests/help-browser.sh`: the standing gate

The node's own gate, in the house shape: `--tree` proves the managed files as
text with a counterfactual behind every ordering or absence claim, `--hermetic`
proves behaviour in a real nushell under a scratch HOME with a recording `tv`
stub, and no argument runs both. `tests/shell-quicklist.sh` is the model to
copy — same subject (a cable file plus a runner), written this session, and its
harness already does every hard part.

Registered `external` in the wave registry, like its siblings, so
`gates/selftest.sh` reports it as unverified-by-contract instead of demanding a
`--selftest` case; carry the inline counterfactuals instead. **Do not edit
`gates/selftest.sh`** — another lane holds it. The registry line itself is
owed to the orchestrator (see the report), not written here.

## Non-negotiable harness facts

- `. "$REPO/gates/lib.sh"`; `/usr/bin/grep` always, because plain `grep`
  resolves to ugrep on this machine; `SCRATCH="$(gates_tmpdir)"` re-resolved
  with `cd … && pwd -P`, because `$nu.home-dir` resolves symlinks and every
  path assertion compares against a nu-reported path.
- Every nu run under `/usr/bin/env -i` with `HOME` in the scratch tree,
  `XDG_CONFIG_HOME` pinned, `PATH="$M/bin:/usr/bin:/bin"`, and
  `--config`/`--env-config` pointed at the managed files. The live tree is
  never written and `~/.cache/nushell` must not exist when the gate finishes.
- `nu -i -c` sets `$nu.is-interactive` **true without a pty** (measured on the
  pinned 0.114.1; `tests/shell-television.sh`'s header carries it). So every
  check here runs as a plain captured command — **no pty runner is needed at
  all**, because this node adds no keybinding.
- **`mk_machine` must stage every module `config.nu` sources**, via the
  list-driven idiom (`for m in dirstack pass theme claude recents zoxide
  history capsule finder quicklist copymode help; do … "$M/home/.config/nushell/$m.nu"`).
  This is not tidiness: `gates/nushell-module-staging.sh` derives its gate list
  by grepping for scripts that stage into a scratch `.config/nushell/`, so this
  new file joins that grid the moment it exists, and Part C fails the whole
  wave-0 gate for any module it does not stage. It also stages the television
  cable dir, since the source and preview commands read the corpus, not the
  cable — but `tv list-channels` needs the cable dir to see `manual`.
- The `tv` stub is `tests/shell-quicklist.sh`'s recording stub verbatim:
  `printf '%s\n'` and never `echo` (macOS `/bin/sh` is bash in POSIX mode with
  xpg_echo on, so `echo` expands a literal `\n` inside an argv and puts every
  `sed -n Np` off by one from that invocation on), an invocation counter in its
  own file rather than `wc -l` of the argv log, numbered replies
  (`tv-reply.$n`), and an argv log. A recording `nvim` stub under the name
  `env.nu` pins for `EDITOR`, a controllable `chezmoi` stub whose stdout the
  check sets, and poison stubs for everything else.

## Counterfactual rule

Every mutated-copy counterfactual follows
[`a-counterfactual-proves-its-own-mutation`(../../../../../prds/memos/a-counterfactual-proves-its-own-mutation.md):
the copy's sha before and after the mutation **on one line**, a `chk_fail`
naming this gate and its subject, then the repair with the sha coming back.
An end-state `grep -qF` for what the mutation was supposed to produce is not
proof — it passes identically when the `sed` matched nothing, which is the
only interesting failure. Reuse `shell-quicklist.sh`'s `cf_begin` / `cf_end`
pair.

At minimum these counterfactuals, each pointed at a claim that would otherwise
be a comment:

1. **a real tab in the cable's `display`** → the template stops splitting.
2. **`output` narrowed from `{}` to one field** → the runner cannot recover
   the id.
3. **the index column dropped from `_help_rows`** → the preview command's
   `{split:\t:3}` has nothing to address.
4. **the index counted after the `--mode` filter** (`enumerate` moved below
   `_help_by_mode`) → `_help_preview` names a different entry than the row
   being previewed. This is the invariant most likely to be "simplified" away.
5. **`"ctrl-o"` removed from `finder.nu`'s `_finder_parse` known list** → the
   ctrl-o path degrades to `enter` and the pressed key arrives as a row.
6. **the `manual` arm deleted from `tv_remote`** → the remote's generic chain
   hands a TAB row to `_finder_open`.
7. **`_help_preview` rewritten to call `_help_entry_detail`** → the
   `core-help`-under-`nu -n` death inside the preview pane.
8. **`manual` removed from `shell.nuon`'s `tv channel` `why`** → the curated
   list is false again, the exact defect that row was re-recorded for.

## Timing: record it, assert nothing

The source and preview commands measure **20 ms each, three runs, at 15-minute
load 6.36** on 2026-08-24. Print the wall time with the load average beside it
and assert **no** budget:
[`a-headless-gate-red-may-be-load-not-code`(../../../../../prds/memos/a-headless-gate-red-may-be-load-not-code.md)
— this machine ran one hermetic stage at 8s, 100s, 194s and 273s tonight at
~1% CPU, and a budget that survives that has stopped asserting anything. What
the gate asserts instead is *structural*, and it is what the budget was a proxy
for: the cable's source and preview commands both carry `nu -n`, so neither
cold-starts a full nushell config per keypress. No retry is specified anywhere
in this gate, because nothing in it is timed.

## Stages

`--tree` — the cable file's keys (a `cable_ok`-style predicate, one function so
the counterfactuals can call it), the `\\t`/no-real-tab rule, the absent
`[keybindings]`/`[actions.`/hex colour, `nu -n` in both commands; `help.nu`'s
three new defs and the `--fuzzy` clause order; the `enumerate`-before-filter
ordering; `finder.nu`'s known list; `config.nu`'s third arm and the absence of
a stale "TWO channels" claim in its comment; `shell.nuon`'s `tv channel` `why`
naming `manual`; the `help --fuzzy` entry unchanged.

`--hermetic` — a real nushell in a scratch HOME: the source rows' shape and
count, the index↔preview correspondence, the `--mode` subset with unfiltered
indices, `_help_preview`'s fields and its out-of-range line, `help.nu` parsing
under a bare `nu -n`, `tv list-channels` seeing `manual` and not `help`, then
the runner's argv for the three interactive invocations, the `enter` and
`ctrl-o` dispatches, the unresolved-repo message, the non-interactive degrade
against a poison tv, and the missing-tv error.

## Acceptance

- [x] `bash tests/help-browser.sh` runs both stages and exits 0, with every
      acceptance box of `spec01-manual-channel.md` covered by at least one
      named check.
- [x] `bash tests/help-browser.sh --tree` and `--hermetic` each run alone and
      exit 0.
- [x] Every counterfactual above prints its before/after sha **on one line**
      and a `chk_fail` naming this gate and its subject, and each repair
      brings the sha back.
- [x] A deliberately no-op'd mutation (point the `sed` at text that is not
      there) shows an **equal** sha pair on that one line and fails — run it
      once, by hand, to prove the shape discriminates, and quote both lines in
      the report.
- [x] The gate prints the source-command and preview-command wall times with
      the load average beside them, and asserts no timing budget anywhere.
- [x] `bash gates/nushell-module-staging.sh` passes with this new file in its
      derived grid: the row for `tests/help-browser.sh` is all `.` — no `X`.
- [x] The live tree is byte-identical after the run and `~/.cache/nushell`
      does not exist when it finishes.
- [x] `gates/selftest.sh` is not edited by this spec.

## Verify and Proof

```sh
bash tests/help-browser.sh
bash tests/help-browser.sh --tree
bash tests/help-browser.sh --hermetic
bash gates/nushell-module-staging.sh
```

## Proof (implementer, 2026-08-24)

`bash tests/help-browser.sh` — **96 PASS / 0 FAIL, rc 0**.
`bash tests/help-browser.sh --tree` — 44 PASS / 0 FAIL, rc 0.
`bash tests/help-browser.sh --hermetic` — 54 PASS / 0 FAIL, rc 0.
`bash gates/nushell-module-staging.sh` — 44 PASS / 0 FAIL, rc 0, and the
derived grid's new row is `help-browser.sh` with a `.` in all twelve module
columns.

**No pty runner exists in this gate at all**, as specified: this node adds no
keybinding, and `nu -i -c` sets `$nu.is-interactive` true without a pty, so
every check is a plain captured command.

**Eight counterfactuals, each in the memo's shape** — sha before and after on
ONE line, a `chk_fail` naming this gate and its subject, then the repair with
the sha coming back:

| counterfactual | sha pair, as printed |
|---|---|
| cable-display-uses-a-real-tab | `3cd4793bde52 -> 05b07c0c7cb0` |
| cable-output-narrowed-to-one-field | `3cd4793bde52 -> e6e2f151cd57` |
| index-column-dropped-from-`_help_rows` | `ef97cba4edc0 -> 549ae8688ef5` |
| index-counted-AFTER-the-mode-filter | `ef97cba4edc0 -> 9f0af5d5dd16` |
| preview-reuses-`_help_entry_detail` | `ef97cba4edc0 -> 2af0a8833cec` |
| ctrl-o-removed-from-the-known-list | `a3bb9d541111 -> 539eedf83dc4` |
| manual-arm-deleted-from-tv_remote | `4d65bb6931a1 -> e9a852ab232d` |
| manual-removed-from-the-curated-list | `232d0c978a65 -> e4b6c33d2113` |

Read the left column of the pairs, not just the right: the two `3cd4793bde52`
rows are two mutations of the same cable file and the three `ef97cba4edc0`
rows are three mutations of the same `help.nu`, each hashed before its own
`sed`, and each landed on a DIFFERENT right-hand value — so none of the five
no-opped. **These are the values on the run recorded here and they will move
whenever their subject file does**; the gate re-prints the pairs on every run,
which is why the table is a transcript rather than an assertion.

**The no-op'd-mutation rehearsal, run once by hand** (outside the repo, with
the gate's own `cf_begin`/`cf_end` and `cable_ok`, and the `sed` aimed at
`outputxx` — a key that is not in the file). Both lines, quoted:

```
      CF NOOP-cable-output-narrowed (deliberately aimed at text that is not there): sha 3cd4793bde52 -> 3cd4793bde52
FAIL  cf: NOOP-cable-output-narrowed (deliberately aimed at text that is not there) really changed the copy — a claimed mutation is not a made one
```

The equal sha prefix on one line is the mechanism, and the FAIL beside it is
the discrimination. A second FAIL followed from `chk_fail`, because the
unmutated copy passes `cable_ok`, which is the only interesting failure the
memo names.

**Timing printed, nothing asserted.** The run prints

```
      timing: the cable source command took 37 ms   (load avg 3.78 3.18 3.70)
      timing: the cable preview command took 33 ms   (load avg 3.78 3.18 3.70)
```

and the structural claim the budget was a proxy for is asserted in `--tree`
by `nu_n_both_ok`: exactly two `^command = ` lines in the cable file, both
carrying `nu -n`. There is no retry anywhere in this gate, because nothing in
it is timed.

**`gates/selftest.sh` was not opened.** `gates/waves.tsv` and
`gates/manual/wave5.md` were not touched either — both are the
orchestrator's, per the brief.

Two things the writing of this gate turned up, both fixed in the subject
rather than worked around in the gate:

* `cable_ok` asserts `[keybindings]` and `[actions.` as ABSENCES, so the cable
  file's own comment explaining that it binds no keys was a hit for its own
  grep. The comment now says it in words. This is the history.nu discipline
  applied to a TOML file, and the same class as `recents_purity_ok`.
* `tests/shell-help.sh`'s `corpus_path_ok` greps `help.nu` for `/Users/`, and
  the first draft of the ctrl-o comment quoted the measured legacy
  `source-path` verbatim. The measurement is kept, the literal is not.

**Corpus counts are measured, never pinned.** The gate reads 92 rows and
asserts `> 0` plus shape; `92` appears only as `CORPUS_ON_2026_08_24`, in a
comment saying it is a reading of that day. Four counts on this board went
stale in prose the same week, which is the argument.
