---
state: done
commit: 53c2c26
claim:
priority: 20
est: 8.5h
task: S.5
mode: afk
needs:
  - 04-shell/05-history
  - 05-platform/01-deploy-mechanism/managed-config
  - 06-help/01-content-model
footprint:
  - home/dot_config/television/config.toml
  - home/dot_config/television/cable/
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
  - tests/nushell-aliases.sh
  - tests/shell-listing.sh
  - tests/shell-claude.sh
  - tests/shell-zoxide.sh
  - tests/shell-history.sh
  - tests/shell-television.sh
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "bash tests/shell-television.sh"
---

# Television finder

Parent: [Nushell epic](../prd.md) · C 8 · U 9 · source: "Television finder
stack" in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: television (`tv`) owns every picker screen — no hand-coded TUIs.
`finder` runs a channel and returns **typed nushell data**; channel selection
is itself a fuzzy channel; selections open by type.

## Requirements
- [x] **R1** — **`finder [--start <channel>]`.** Runs a tv channel (or the
      channels remote first), un-hijacks enter (`--keybindings
      'enter="confirm_selection"'`), tab = multi-select, returns structured
      data. **Four channels hijack enter, not one** (backlog **M-9**, and
      its 2026-08-22 addendum): `text` and `recent-files` bind
      `actions:edit`, `zoxide` binds `actions:cd`, which spawns a nested
      `$SHELL` in the picked directory instead of moving the caller's shell,
      and `git-branch` binds `actions:checkout`. The un-hijack has to cover
      all four — it does, because the flag rides every `finder` invocation
      rather than being listed per channel, which is why the miscount was
      harmless. **The count was corrected 2026-08-23 by the orchestrator on
      the implementer's finding**: the body still said "three" while M-9's
      own addendum had said four since 2026-08-22, and a count that
      disagrees with its own source is how a later reader re-derives the
      wrong invariant. `text` is also **our own local override**, not the stock
      channel — it carries a local `output` template and a two-entry source
      list — so a reader sent upstream for it finds nothing.
- [x] **R2** — **Typed decode.** Channel → produced type → decoder:
      `files`/`dirs`/`recent-dirs`/`recent-files` → FileList (expanded,
      existing paths); `text` → GrepList `{file, line, text}`; `git-log` →
      Commits `{hash}`; `cht-query` → ChtSheet; unknown channels pass raw
      strings.
  - [x] **(a) Live bug L-3 — type the channel that exists.** The live
        decoder types `rcwd`, a name no cable file has ever carried (the
        channel is `recent-dirs`), so recent-dir picks missed the FileList
        arm, fell through to `Any`, and came back as raw strings instead of
        expanded, existence-checked paths; `recent-files` is untyped for the
        same reason. `rcwd` is the id of bug **L-3** made into a word, not a
        channel name, and must never again be written as one.
  - [x] **(b) Live bug L-2 — read the field the channel actually emits.**
        The `Commits` decode consumes the emitted value **whole**:
        `git-log.toml`'s `output = "{strip_ansi|split: :1}"` has already
        reduced the entry to a bare hash, and the live decoder splits that
        hash a second time and reads index 1, which is empty — so the
        `^[0-9a-f]{7,}$` guard dropped every row and commit → `git show` has
        never run. Four parts of the why, each load-bearing:
    - [x] the extraction belongs to the **channel**, which already uses that
          same `strip_ansi` template for its preview and for its three
          actions (cherry-pick, revert, checkout) — a second extraction in
          the decoder is the duplication that rotted;
    - [x] the `^[0-9a-f]{7,}$` guard is **kept**, but as a validity filter
          that now passes rather than one that eats every row;
    - [x] the produced shape is `{hash}` — `subject` is **dropped**, because
          a bare hash cannot fill it and nothing consumes it (R3 opens a
          commit with `git show $hash`, and
          [`07-quicklist`](../07-quicklist/prd.md) R3 reuses that opener).
          If a subject label is ever wanted it comes from the channel's own
          display template; the decoder never reconstructs it;
    - [x] **a decode that yields an empty list where the picker showed rows
          is a failure, not a no-op.** That is what hid this for the life of
          the config: `finder` returns `[]` and `_finder_open` returns on an
          empty selection, so nothing ever complained. The rebuild surfaces
          an empty decode over a non-empty selection as an error instead of
          returning quietly.
- [x] **R3** — **Open-by-type.** GrepList → `$EDITOR +line file`; Commits →
      `git show`; ChtSheet → cht.sh via pager; path → cd if dir, edit if file.
      `--env` so a cd reaches the shell.
- [x] **R4** — **Keybindings.**
  - [x] `Ctrl+Space` / `F1` → `tv_remote`: pick a channel, run it, ACT on the
        result (the quicklist channel dispatches to its own runner). The
        opacity picker is not among them — the
        [`wallpaper-opacity`](../../00-delivery/decisions/wallpaper-opacity/prd.md)
        decision of 2026-08-21 put it out of the minimal base, so this node
        neither specs its channel nor dispatches to it.
  - [x] `Ctrl+T` → `tv_finder`: same picker but INSERT the selection at the
        cursor, shell-quoted (fzf-style).
- [x] **R5** — **Cable channels.** Curate the channel set for the minimal
      base. **Keep:** `files`, `dirs`, `text` (grep), `zoxide`, `env`,
      `quicklist`, `git-log`/`git-files`/`git-branch`, `recent-dirs` (fed by
      the dirstack of [`01-core-config`](../01-core-config/prd.md) R8 and
      decoded as a FileList per R2), `recent-files` (FileList too), `alias`
      (nu aliases, listed through `scope aliases`), the `cht` → `cht-query`
      pair, `channels`, and `nu-history`.
  - [x] **`nu-history` — `Alt-R` depends on it.**
        [`05-history`](../05-history/prd.md) R2 binds the key; this epic owns
        the channel. Ours is a deliberate local override of tv's builtin, for
        two reasons worth keeping: the builtin cold-starts a full nushell per
        keypress (re-sourcing starship, zoxide and the tv init), and it
        assumes the plaintext history format while ours is
        `file_format: sqlite`, which it read as text and mangled. The
        override runs `nu -n` (no config load) and queries the sqlite history
        directly.
  - [x] **`cht` → `cht-query` is a two-step pipe.** `ctrl-p` carries the
        picked language from `cht` into the query channel, which is why R2
        types `cht-query` and not `cht`.
  - [x] **`channels` is the remote's own channel**, overridden per call with
        `--source-command` (the carry-aware candidate list) — it is what
        makes the set browsable at all, so it is kept rather than curated
        away.
  - [x] **The `theme` channel is not on any "migrate on demand" list.** It
        backs [`09-theme-switcher`](../09-theme-switcher/prd.md) R3's
        tv-backed scheme picker, which points back here for the picker
        contract: that node owns the scheme scope, this one owns the channel
        plumbing.
  - [x] **Drop:** the sessions channels (`DO NOT PORT`, decided 2026-08-20 —
        see the [README exclusion list](../../README.md)), and the long tail
        of `git-*` channels (`git-diff`, `git-stash`, `git-reflog`,
        `git-worktrees`, …) plus `bg`, which migrate only on demand.
        Dropping the sessions channel also dissolves the in-tv
        `shortcut = "f5"` collision it had with `cht`, so no rekey is needed.
  - [x] **Non-cable assets:** `bg-preview.sh` is **not ported** — it belongs
        to the wallpaper pipeline the
        [`wallpaper-opacity`](../../00-delivery/decisions/wallpaper-opacity/prd.md)
        decision dropped. `theme-preview.sh` belongs to
        [`09-theme-switcher`](../09-theme-switcher/prd.md); it is referenced
        here, not owned here.
- [x] **R6** — **Theming.** tv uses the `default` ANSI theme so it inherits
      the terminal's palette rather than baking hex values.
- [x] **R7** — **Known tv limitations (encode as guards/tests).** tv panics
      without a TTY → all entry points are interactive-only; the CLI
      `--keybindings` grammar is `key="action"` (inverse of the config-file
      form); with `--expect`, stdout line 1 is the pressed key (empty = plain
      enter).

## Acceptance

Every box below was executed by `bash tests/shell-television.sh` on
2026-08-23 — **61 PASS, 0 FAIL, `EXIT=0`** — quoted per box.

- [x] `Ctrl+Space`, type `fil`, enter, pick a file → it opens in nvim; pick a
      dir via `dirs` → shell cds (and auto-lists).
      Dir half, in a pty against a scratch HOME:
      `PASS  hermetic: an F1 dirs pick moved PWD to the picked directory
      (print $env.PWD line present)` and
      `PASS  hermetic: …and the PWD hook auto-listed it (REMOTE-CANARY row
      painted: 1)`. File half:
      `PASS  hermetic: _finder_open on a plain FILE path runs $EDITOR on it,
      no +line (got: nvim …/m-tv/home/gf.txt)` — a check this retry added,
      because the grep arm the gate already had goes through `{file, line}`,
      a different branch of `_finder_open`.
- [x] `Ctrl+T` on a path with spaces inserts it quoted; esc leaves the line
      untouched.
      `PASS  hermetic: Ctrl-T inserts the pick at the cursor, single-quoted —
      the double space survives execution only if quoted` and
      `PASS  hermetic: an aborted pick leaves the line untouched — the
      pre-typed command still runs bare`, with the executed counterfactual
      `PASS  hermetic: with the records deleted, Ctrl-T reaches tv's OWN
      binding — argv shows --autocomplete-prompt, not list-channels`.
- [x] A grep pick from `text` opens the editor at the matching line.
      `PASS  hermetic: a text pick decodes {file, line, text} with the file
      expanded and the text keeping its colons` and
      `PASS  hermetic: _finder_open on the grep pick runs $EDITOR +12 <file>
      (got: nvim +12 …/m-tv/home/gf.txt)`.
- [x] `finder` in a non-tty context returns/errors cleanly, no panic.
      `PASS  hermetic: finder under nu -c (no pty, no -i) exits non-zero with
      the interactive-only message (rc=1)` and
      `PASS  hermetic: …and no tv panic string in stderr (tv was never
      reached: argv log has 0 lines)`.
- [x] A `git-log` pick opens `git show` for that commit — the check L-2 never
      passed — and a decode that drops every row of a non-empty selection
      raises instead of returning `[]`.
      **L-2 passes for the first time.**
      `PASS  hermetic: finder --start git-log decodes bare hashes to {hash}
      rows (got [{"hash":"01729f5"}])`,
      `PASS  hermetic: …with no subject column`, and
      `PASS  hermetic: _finder_open on the decode runs git show — the scratch
      commit's message is in the output (L-2: never passed against the live
      config)` — observed through `git show`'s own output against a scratch
      repo, not asserted. The raise:
      `PASS  hermetic: all-invalid FileList reply exits non-zero and never
      prints [] (rc=1, out=)`,
      `PASS  hermetic: …and the error names the channel and the row count
      (… finder: the files decode dropped all 2 selected rows —)`, and the
      executed counterfactual
      `PASS  hermetic: counterfactual check-removed finder returns []
      silently, rc 0 (rc=0, out=[]) — what the gate would then FAIL`.
      See the finding below: the `{hash}` promise holds for first-lane
      `git log --graph` rows only.
- [x] A pick from `recent-dirs` decodes as a FileList and cds to an expanded,
      existing path rather than returning a raw string.
      `PASS  hermetic: finder --start recent-dirs decodes as FileList —
      expanded, existing (got ["…/m-tv/home/rd-target"]; L-3)`, with the
      executed counterfactual
      `PASS  tree: counterfactual rcwd-match-arm FAILS the type check`, and
      `PASS  tree: the L-3 bug id appears nowhere under the managed
      television tree`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Failure — history, retried 2026-08-23

Retried 2026-08-23T20:52Z by the user's answer in the round. Set `specced`, not
`open`: all four specs are on disk and the history below is what the retry
needs — uncommitted partial code of unknown correctness, three measured live
FAILs this node now owns, and the one-word `help.nu` staging gap. The retry
audits the disk against the specs; it does not assume the code is right and it
does not start over blind.

Swept by the orchestrator on 2026-08-22 22:05: the PRD was left `claimed` by
`implementer-television`, whose session died. No live worker held the claim
(claim written 16:02, ~6h earlier).

**Partial work exists in the working tree and must be reviewed before a retry**
— all of it uncommitted:

- `home/dot_config/nushell/finder.nu` (16:11)
- `home/dot_config/television/config.toml` (16:08) and `cable/` channel files
- `tests/shell-television.sh` (16:24), the spec04 gate

None of the four specs has a single ticked acceptance box and no verify output
was ever reported, so the state of that code against R1–R7 is unknown — in
particular the three live-bug requirements (L-2 `git-log` decode, L-3 the
`rcwd` name, and the empty-decode-must-raise rule). A retry audits what is on
disk against the specs rather than assuming it is correct or starting over
blind.

### Added 2026-08-23 by the orchestrator — three real FAILs measured

Not part of the sweep above, and useful to whoever retries this node.
`sibling-gates-copymode-staging`'s analyst staged the modules
`tests/shell-television.sh` was missing and ran it. It goes from 19 FAILs to
**3**, and those three are a television-lane defect rather than a staging
artefact:

- the **Ctrl-T cursor insert** check
- both **F1 dirs-pick** checks

Stable across three runs, and reproduced with an *empty* `help.nu`, so they
are caused by neither the missing staging nor any `help.nu` content. They were
invisible until now because this gate had been red on the staging defect
since T.7 landed — the exact harm a silent gate outage does.

A retry of this node owns them. Note also that `tests/shell-television.sh` is
missing `help.nu` staging (`config.nu:450`), deliberately left out of the
copymode correction's scope and recorded in its Out of scope; that fix is one
word in the list loop at line 471 and is a prerequisite for registering the
new module-staging drift gate in wave 0.

### Added 2026-08-23 by the orchestrator — a vacuous assertion in this gate

`television-help-staging`'s analyst found that `tests/shell-television.sh`'s
check `hermetic: …and the error names the channel and the row count` greps the
captured stderr for the bare literals `files` and `2`. **A scratch path
containing a digit satisfies the `2` half by accident**, so the check passes
from `/private/tmp/claude-501/…` and fails from `/Users/feb/dev/dotfiles` — on
identical code. That is why the parse-dead FAIL count of this gate is
path-dependent: 20 measured in-tree, 18 in a frozen copy, for the same outage.

A retry of this node owns tightening that assertion to something a path cannot
satisfy. It is the same defect class as the `T.4` `opacity` box and R10's
`get_current_working_directory` — an assertion whose subject is wider than what
it means to check — and it is the fifth instance on this board.

Also recorded for a retry: this gate's `the managed nushell and television
files are byte-identical` check snapshots the managed tree, so **any**
concurrent write under `home/dot_config/nushell/` convicts it. That is correct
behaviour for an isolation guard, but it means the gate must be run while no
other lane is writing.

### Resolved 2026-08-23 by `implementer-television` — the retry's audit

**The disk was right; the gate was wrong.** The audit found the dead session's
`finder.nu`, the fifteen cable files, `config.toml` and the `config.nu` wiring
all correct against R1–R7 — nothing was rewritten. All three recorded FAILs had
a single cause in `tests/shell-television.sh`'s own `tv` stub, and it is the
kind of bug that only a measurement finds:

- The stub numbered invocations with `wc -l` of its argv log, and logged argv
  with `echo`. macOS `/bin/sh` is bash in POSIX mode with `xpg_echo` on, so its
  `echo` **expands backslash escapes** — measured:
  `/bin/sh -c 'echo "a\nb"'` emits two lines.
- `_finder_pick_channel` passes `--source-command "printf '%s\n' 'a' 'b'"`
  with a LITERAL two-character `\n` — measured:
  `nu -n -c '$"printf %s\\n x" | to nuon'` prints `"printf %s\\n x"`.
- So the second invocation wrote a two-line entry, the counter jumped, and the
  **third** invocation read `tv-reply.4`, a file no check writes. It fell back
  to the empty `tv-reply`, `finder` saw an empty selection and returned `[]`,
  and nothing was inserted or cd'd to. Exactly the three checks that need a
  third invocation failed — Ctrl-T and both F1 dirs-pick checks — while every
  one-and-two-invocation check passed. Both halves are now fixed (a dedicated
  counter file, `printf '%s\n'` in both stubs) with the measurement in the
  comment.

The other two items the history handed the retry:

- **The `help.nu` staging gap was already closed** when the retry audited the
  file: the list loop already reads `… capsule finder copymode help`. The
  history's `config.nu:450` is stale — `config.nu` sources `help.nu` at **line
  565**. `bash gates/nushell-module-staging.sh`, the drift gate that gap was
  blocking, is green: `EXIT=0 PASS=40 FAIL=0`.
- **The vacuous assertion is tightened.** The empty-decode check greps the
  whole rendered sentence `the files decode dropped all 2 selected rows`
  through `norm`, instead of the bare literals `files` and `2` that a scratch
  path with a digit in it satisfied by accident.
- **`gates/waves.tsv` needs nothing.** The wave-4 gates cell already carries
  `external bash tests/shell-television.sh` (line 25). Not touched.

### Finding, reported not fixed — `git-log --graph` and split index 1

Outside what any spec authorises this node to change, so it is reported rather
than filed or fixed. `cable/git-log.toml` is carried verbatim from live per
spec01, and it runs `git log --graph` while `output = "{strip_ansi|split: :1}"`
takes field 1. On a graph row field 1 is not the hash. Measured on this repo's
own history, **6 of the first 20 rows**: four connector rows (drawn with pipes
and slashes) split to empty, and two `| * <hash>` rows split to `*` — and those
two are *real commits* whose hash sits at field 2.

So a pick of a merge-lane commit yields a value the `^[0-9a-f]{7,}$` guard
rejects; a single-row pick of one now hits R2(b)'s raise instead of opening
`git show`. The same template feeds the channel's preview and its cherry-pick /
revert / checkout actions, so all four get `*` for those rows. R2(b)'s "a
validity filter that now passes rather than one that eats every row" is true of
first-lane rows and not of merge-lane ones. This would get R2(b) and spec01's
`git-log.toml` row wrong. The reading is recorded in
`home/dot_config/nushell/help/use-review.nuon`'s `finder` row.

Also reported, from the same reader: `_finder_pick_channel` lists
`tv list-channels`, which includes tv's own builtins — so `git-diff`, a channel
R5's Drop clause names, is browsable in the remote anyway. R5 curates the
*cable set*, not what the remote shows.

## Closed 2026-08-23 by the orchestrator

`done`. The node's own gate is `bash tests/shell-television.sh` → **EXIT=0,
61 PASS, 0 FAIL**, all seven counterfactuals executed, and six sibling shell
gates plus `managed-config.sh`, `nushell-module-staging.sh`,
`retired-phrases.sh` and `tree-links.sh` are green beside it. **L-2 passes for
the first time on this board** — `_finder_open` on a `git-log` decode runs
`git show` against a scratch repo, observed through its output — with L-3 and
the empty-decode raise green and counterfactualled.

**`actual:` is deliberately left empty.** The run was not clean by the
calibration rule: this node carries a `## Failure` history and this was a
retry, so the elapsed time measures the audit of a dead session's leftovers
rather than the cost of the work. A wrong number is worse than none.

**The one `[~]`, and why it is not this node's:** `nu
tests/help-content-model.nu` exits 1 in-tree on `nvim.nuon [<leader>t]` — a
file another lane modified and left uncommitted, red before this worker's
first command. Proved foreign by construction: with that single digest stamped
in a scratch copy of the help dir and nothing else changed, the gate prints
`ok` and exits 0. It clears when
[`15-markdown-tables`](../../03-editor/15-markdown-tables/prd.md)'s owed
review row lands.

**The three FAILs this retry inherited had one cause, and it was in the gate,
not the config.** The dead session's `finder.nu`, the fifteen cable files,
`config.toml` and the `config.nu` wiring were all correct against R1–R7, and
nothing was rewritten. `tests/shell-television.sh`'s own `tv` stub logged argv
with `echo` and numbered invocations by `wc -l` of that log; macOS `/bin/sh`
is bash in POSIX mode with `xpg_echo` on, so `echo` expands backslash escapes
(`/bin/sh -c 'echo "a\nb"'` emits two lines). `_finder_pick_channel` passes
`--source-command "printf '%s\n' …"` with a **literal** two-character `\n`,
so invocation 2 wrote a two-line entry, the counter jumped, and invocation 3
read a reply file that was never written. Exactly the three checks needing a
third invocation failed — Ctrl-T and both F1 dirs-picks — while every check
needing one or two passed. Fixed with a dedicated counter file and
`printf '%s\n'` in both stubs, measurement in the comment.

That is worth carrying: **a gate that fails only its highest-numbered
invocations is a counting bug in the harness, not a defect in the subject.**

**Two board facts corrected by the audit:** the `help.nu` staging gap was
already closed (the loop reads `… capsule finder copymode help`), and
`config.nu` sources `help.nu` at **line 565** — the history's `:450` was
stale. `gates/waves.tsv` needed nothing; its wave-4 cell already carries
`external bash tests/shell-television.sh` at line 25.

**R5's scope, corrected on the record:** R5 curates the **cable set**, not
what the remote lists. `_finder_pick_channel` lists `tv list-channels`, which
includes tv's builtins, so `git-diff` — named in R5's Drop clause — remains
browsable. The Drop clause is true of what this repo ships, not of what the
picker can reach.

## Report

**DONE** — retried after a dead session, and the audit reversed the diagnosis.

`bash tests/shell-television.sh` → **EXIT=0, 61 PASS, 0 FAIL**, all seven counterfactuals executed. Six sibling shell gates green (core 212, aliases 39, listing 36, claude 51, zoxide 106, history 68), plus `managed-config.sh` 65, `nushell-module-staging.sh` 40, `retired-phrases.sh` and `tree-links.sh`. **L-2 passes for the first time on this board**: `_finder_open` on a `git-log` decode runs `git show` against a scratch repo, observed through its output. L-3 and the empty-decode raise green with counterfactuals.

**The disk was right; the gate was wrong.** The dead session's `finder.nu`, the fifteen cable files, `config.toml` and the `config.nu` wiring were all correct against R1-R7 and nothing was rewritten. The three recorded FAILs had one cause in the gate's own `tv` stub: it logged argv with `echo` and counted invocations by `wc -l`, and macOS `/bin/sh` is bash in POSIX mode with `xpg_echo` on, so `echo` expanded the literal `\n` in `--source-command "printf '%s\n' ..."` into a second line. The counter jumped, invocation 3 read a reply file that was never written. Exactly the three checks needing a third invocation failed. Fixed with a dedicated counter file and `printf '%s\n'`.

`actual:` left empty on purpose — a retry over a dead session's leftovers measures the audit, not the work.

Board corrections made on this transition: R1's enter-hijack count went three to four (`git-branch` binds `actions:checkout`; M-9's own addendum had said so since 2026-08-22), and R5's scope is recorded as curating the cable set rather than what `tv list-channels` shows.

One finding filed as a derived PRD, `git-log-graph-field-one`: the channel runs `git log --graph` and takes field 1 as the hash, but 6 of the first 20 rows of this repo's history split wrong, two of them real commits whose hash is at field 2. A merge-lane pick raises instead of showing.
