---
state: done
commit: 51396f0
claim:
priority: 10
est: 1.75h
task: H.3
mode: afk
needs:
  - 06-help/02-help-command
  - 05-platform/01-deploy-mechanism/managed-config
  - 04-shell/04-television
  - 04-shell/07-quicklist
  - 00-delivery/corrections/w0-4-s2-corrections
footprint:
  - home/dot_config/television/cable/manual.toml
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/why-review.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - tests/shell-television.sh
  - tests/shell-help.sh
  - tests/help-browser.sh
verify: "bash tests/help-browser.sh"
---

# Fuzzy browser

Parent: [Help epic](../prd.md) · C 3 · U 7 · net-new

Purpose: "I know it exists, I forget the key" — a fuzzy search over every
manual entry, as a television channel. Consistent with the shell epic's
invariant that tv owns every picker screen, so this is a cable file plus a
small runner, not a new UI.

## Requirements
- [x] **R1** — **Channel, named `manual`.** **Corrected 2026-08-24 by the
      orchestrator: the name `help` is unimplementable, and this requirement's
      letter could not have been satisfied.** Measured on tv 0.15.9 with a
      scratch `XDG_CONFIG_HOME`: `help` is a clap **subcommand** of `tv`, so
      `tv help` prints tv's own usage at rc 0 and never opens the channel —
      even though `tv list-channels` lists it. `tv -- help` does reach it, but
      that only fixes our own runner: `finder --start help` and `Ctrl-T` both
      run `tv <channel>` *with* flags, so a channel called `help` would hand
      tv's usage text to `_finder_decode` as rows and then to `_finder_open`
      as a path. `manual` is free — neither a subcommand nor a builtin
      channel — and costs exactly one thing, recorded so nobody treats it as
      a defect: typing "help" in the `Ctrl-Space` remote will not match it,
      because `_finder_pick_channel` matches channel names only.

      A `manual` cable channel whose source emits one row
      per entry from [01-content-model](../01-content-model/prd.md): topic,
      key/cmd, title — TAB-delimited, because that is what tv's display
      template requires. A template addresses fields as `{split:\t:N}`, so a
      cable's source must emit TAB-separated columns for tv to slice them; the
      live exemplar is `~/.config/television/cable/quicklist.toml`. Set
      `output = "{}"` so the whole row is emitted and the runner can recover
      the fields `display` does not show. Carry the escaping trap with its
      reason: `"\\t"` in the TOML reaches tv as `\t`, which is the delimiter
      the template engine splits on — writing a real tab, or a single
      backslash, breaks the split.
      [`04-shell/07`](../../04-shell/07-quicklist/prd.md)'s nuon is the
      quicklist's *storage* format and is not a row format, so the two are not
      in conflict: nuon is how that list is persisted, TAB is how every tv
      cable hands rows to the picker. That node stays the exemplar for "a
      cable file plus a small runner", which is the shape this node copies.
- [x] **R2** — **Preview.** The focused row previews its full entry: title,
      use, why, related. This is where `why` earns its place — the constraint
      is visible at the moment you're looking the key up.
- [x] **R3** — **Entry points.** `help --fuzzy`, and the `help` channel
      appearing in the `Ctrl-Space` channels remote like any other channel. No
      new global keybinding is required; add one only if it proves needed in
      daily use.
- [x] **R4** — **Actions.** `enter` prints that entry's detail into the
      scrollback (the default — you looked it up to read it). `ctrl-o` opens
      the PRD named by the entry's `source` field in `$EDITOR`, for when the
      answer is "why is it like this". That field is defined by
      [`01-content-model`](../01-content-model/prd.md) R2 — required, shape-
      checked and resolved against the repo — and its path is repo-root
      relative. Every live entry resolves in node form (`<node>/prd.md`), and
      none is still on the pre-board flat form.

      **The count in this requirement was stale and is corrected: the corpus
      is 92 entries, not 84.** Re-measured 2026-08-24 — 92 entries, all ids
      unique, no tab or newline in any `id`/`title`/`topic`, no missing
      `topic` or `source`, 59 carrying a `why`. The 84 came from a
      2026-08-21 reading. `home/dot_config/nushell/help/README.md:320` still
      says "all 84 carry a `source:`" and is **not** in this node's
      footprint — a finding for the help lane, not an edit for this one. A
      count is a reading of the day it was taken; this is the fourth stale
      one the board has corrected today, which is the argument for asserting
      shapes and counting live rather than freezing numbers in prose.
- [x] **R5** — **Interactive-only.** tv requires a TTY; guard and degrade to
      `help <query>` when there isn't one.

## Acceptance
- [x] `help --fuzzy`, type "select": the shift-select entries appear, and the
      preview explains the collapse-on-motion behavior.
- [x] `enter` leaves the detail in the scrollback after tv exits.
- [x] Piping the command in a non-interactive context falls back to plain
      search output instead of panicking.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Proof (implementer, 2026-08-24)

Gate: `bash tests/help-browser.sh` — **96 PASS / 0 FAIL, rc 0**
(`--tree` 44, `--hermetic` 54, each green alone). Beside it:
`tests/shell-television.sh` 61/0, `tests/shell-help.sh` 93/0,
`gates/nushell-module-staging.sh` 44/0, all rc 0. Per-box detail and every
counterfactual sha pair are in
[`specs/spec01`](specs/spec01-manual-channel.md#proof-implementer-2026-08-24)
and [`specs/spec02`](specs/spec02-gate.md#proof-implementer-2026-08-24).

**The channel is `manual`.** Re-measured here on tv 0.15.9: with this cable
dir as `XDG_CONFIG_HOME`, `tv list-channels` lists `manual` and no `help`,
`tv manual …` reaches the channel (crashing on the absent TTY, like
`tv files`), and `tv help` prints tv's own usage at rc 0. All four runner
flags — `--input-header`, `--keybindings`, `--expect`, plus `--input` and
`--source-command` — parse together in one argv; a bogus flag gives a clap
error instead, so the parse is real.

**The invariant the specs said a reader would get wrong is asserted twice.**
`_help_rows` enumerates BEFORE `_help_by_mode`, so `--mode nvim` returns 27
of 92 rows carrying indices 43, 44, 45 … — not `0..27` — and
`_help_preview 43` still names `<leader>`, the first filtered row. The
counterfactual that moves `enumerate` below the filter is red before its
repair with its sha pair on one line.

**One correction to spec01, measured.** spec01 §5 specifies the `tv_remote`
arm as `{ _help_browse "" ""; return }`, which **swallows the return value**:
`enter` through Ctrl-Space then printed nothing. The arm ships as
`{ return (_help_browse "" "") }` — one token different, and the only form
that makes R4's "enter prints that entry's detail into the scrollback" true on
the remote path as well as on `help --fuzzy`. The theme and quicklist arms are
correctly value-less: they act rather than render.

**One deviation from spec01 §2, in the other direction.** ctrl-o's repo
resolution is INSIDE `_help_browse` rather than in a fourth def, which is what
§2's "three `def`s" asks for and what makes the re-scoped R8 check strong:
`tests/shell-help.sh` now asserts that help.nu **with `_help_browse`'s body
excised** names no spawn in either spelling, and that `_help_browse` is the
only def naming `tv`, `chezmoi` or `$env.EDITOR`. Both go red on a mutated
copy that puts a `tv` call inside a render def.

**What is on tv's side of the seam, stated rather than blurred.** The first
acceptance box types "select" into the picker; tv's fuzzy matcher is tv's, and
a recording stub cannot exercise it. What is proven is everything on our side:
the rows handed to tv contain both shift-select entries and "select" matches
them as a substring, `--input select` is what tv receives, and the preview of
`h j k l (visual)` names collapse-on-motion. The same seam is where
04-shell/07 closed its own `enter`/`ctrl-r` boxes.

**One box left open, and it is the review ritual, not the code.** Adding
`manual` to `shell.nuon`'s `tv channel` `why` staled that entry's
`why-review` digest. `nu tests/help-content-model.nu` reports exactly one
violation and names the digest to set: **`edf405bf05241f37`**. This session
wrote that revision, so it may not also vouch for it — the gate refuses a row
whose `reviewer` equals its `author`, and a self-vouched row is what sent
another node to `blocked`. The row is owed to a reader who did not write the
text; see the report.

**Three findings, reported not fixed.** (1) `chezmoi source-path` still
reports the legacy source repo on this machine, so ctrl-o's resolution is
correct-by-construction only post-`just cutover`; the pre-cutover path is
proven through a `chezmoi` stub and prints the resolved path and
`just cutover`. (2) `home/dot_config/nushell/help/README.md:320` still says
"all 84 carry a `source:`" and is not in this node's footprint. (3) env.nu's
PATH repair APPENDS `/opt/homebrew/bin` unconditionally, so a scratch machine
cannot hide a real binary from the configured shell by its launch PATH alone —
the missing-`tv` guard is observable only by setting `$env.PATH` inside the
shell, and every gate that "removes a tool from PATH" should know it.

## Closed 2026-08-24 by the orchestrator

`done`. `bash tests/help-browser.sh` → **96 PASS / 0 FAIL, rc 0** (`--tree`
44, `--hermetic` 54), with `shell-television.sh` 61/0, `shell-help.sh` 93/0 and
`nushell-module-staging.sh` 44/0 beside it. `nu
tests/help-content-model.nu` now exits **0** — `92 entries across 4 files, 9
topics, 13 prose-only`, `ok` — after an independent reader recorded the
`tv channel` row. R1–R5 and all three acceptance boxes `[x]`; spec02 8/8,
spec01 20/20.

**`actual:` is left empty, and the reason is structural rather than a
one-off.** Any node that edits a manual entry needs **two** dispatches — the
implementer, then a reader who did not write the text — so elapsed from the
`claim:` measures the reader alone and elapsed from the first claim measures the
gap between them. Neither is the cost of the work. Every future `help`-touching
node has the same shape, so this is worth knowing before someone reads a
suspiciously small `actual` on one of them.

**Four spec corrections, all measured:**

1. **spec01 §5's `tv_remote` arm swallowed the return value.**
   `{ _help_browse "" ""; return }` discards the detail string, so `enter`
   through `Ctrl-Space` printed nothing. Shipped as
   `{ return (_help_browse "" "") }` — the only form that makes R4 true on the
   remote path. The theme and quicklist arms are correctly value-less: they
   *act* rather than render, which is why the defect did not generalise.
2. **`ctrl-o`'s resolution lives inside `_help_browse`**, not a fourth def —
   which is what "three defs" asked for and what lets `shell-help.sh` assert
   the re-scoped R8 claim as *help.nu with `_help_browse`'s body excised* plus
   *`_help_browse` is the only def naming `tv`/`chezmoi`/`$env.EDITOR`*.
3. **"no `tv` on PATH" is unreachable through the launch environment.**
   `env.nu`'s PATH repair appends `/opt/homebrew/bin` unconditionally, so with
   only the stub removed `help --fuzzy` reached the **real** tv and crashed on
   the absent TTY. The check sets `$env.PATH` inside the shell instead. Any
   future gate that "removes a tool from PATH" needs this.
4. **The non-interactive degrade is proven against the recording stub, not a
   poison one** — "never invoked" read off an empty argv log is stronger than a
   poison binary's non-zero exit.

**The no-op rehearsal was run by hand, outside the repo**, and it printed the
equal pair the rule asks for: `sha 3cd4793bde52 -> 3cd4793bde52` with
`a claimed mutation is not a made one`. The eight in-gate counterfactuals each
moved their pair, and the five sharing a left-hand sha landed on five different
right-hand values, so none no-opped.

**Two subject files had to move so an absence check could mean something:**
`cable/manual.toml`'s comment says "binds no keys" in words, because the TOML
spellings `[keybindings]` / `[actions.` are the absences `cable_ok` greps for;
and `help.nu`'s `ctrl-o` comment records the legacy-path measurement without
the literal, because `corpus_path_ok` greps that file for `/Users/`. A check
that greps for a string constrains the prose around it — worth knowing before
writing the next one.

**Readings of the day, asserted as shape and not as numbers:** 92 corpus
entries; `--mode nvim` → 27 rows carrying indices **43, 44, 45 …** rather than
`0..27`, which is why the preview addresses a position in the *unfiltered*
corpus; cable source 37 ms and preview 33 ms at load ~3.5, printed with **no
budget asserted anywhere**.

**The reader's finding, routed rather than absorbed:** the forced channel name
and its accepted cost — `help` is a clap subcommand of `tv`, so typing "help"
in the `Ctrl-Space` remote will never match this channel — **appears nowhere in
the manual**, because `shell.nuon`'s `help --fuzzy` entry carries no `why` at
all. That is the most non-obvious thing a reader of the manual would want about
the browser and cannot get. It belongs to
[`06-help/01-content-model/coverage`](../01-content-model/coverage/prd.md) and
has been written there.
