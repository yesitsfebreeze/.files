# `help` content model

The manual's single data source. Every renderer — `help` itself, the tv
browser, `help --json`, `help --md` — reads these files and holds layout only.
No description text for this environment lives anywhere else.

Spec: `prds/06-help/01-content-model/prd.md`. Read that before editing the
schema; read this before editing an entry.

## Files

| File | Surface |
|---|---|
| `topics.nuon` | the spine: the nine topics in reading order, with summaries |
| `shell.nuon` | nushell — keybindings, aliases, custom commands, idioms |
| `nvim.nuon` | Neovim — keymaps, plugin keys, and the core keys we keep |
| `terminal.nuon` | WezTerm — jump mode, window/tab keys, copy mode, clipboard, capsule bindings |
| `capsule.nuon` | the capsule CLI and what a container gets from the host |
| `why-review.nuon` | not content: the record of who read each `why` against its `use`, and of the exact text they read |
| `use-review.nuon` | not content: the record of who read each `use` against its `source` PRD and its live route, and of the exact pair they read |

NUON, not YAML: `open shell.nuon` in nushell returns a table with no parser and
no dependency. Comments are legal and used for section headers.

## Entry schema

Every entry is a record. Field order below is the order entries are written in,
so a diff reads top to bottom.

| Field | Required | Meaning |
|---|---|---|
| `key` *or* `cmd` | one of the two | the binding (`Ctrl-R`, `F5 <digit>`) or the invocation (`z <query>`) |
| `title` | yes | one line, imperative, no trailing period |
| `use` | yes | the real gesture in order: what to press next, and what comes back. A `key` entry never *opens* by restating its key, backticks included |
| `topic` | yes | one of the nine in `topics.nuon` |
| `mode` | yes | `shell` · `nvim:normal` · `nvim:visual` · `nvim:insert` · `terminal` · `container` |
| `also` | optional | related entries, by `key`/`cmd` |
| `why` | optional | the non-obvious reason it works this way — a constraint that cost somebody a day, and nothing the `use` already said |
| `verify` | yes | how the drift check confirms it exists — a list, see below |
| `source` | yes | the PRD this entry was written from, so `help <entry>` and the browser's `ctrl-o` can open it |

**Present is not enough — every value has a shape.** A field that is spelled
correctly and holds nothing is the failure this schema shipped with for three
cycles: `verify: [{kind: "command", name: ""}]`, `key: ""` and `source: ""` all
passed the gate, and an entry with an empty `key` then had no id, so every
message about it read `shell.nuon []`. Since 2026-08-21 `key`, `cmd`, `title`,
`use`, `topic`, `mode`, `why` and `source` must each be a string that is
non-empty after trimming; `also` must be a non-empty list of such strings;
`verify` must be a non-empty list of records, and every field of every target
must be a non-empty string — the one exception being a `nullable` target field
written as an explicit `null`, which today is `nvim-map`'s `desc` and nothing
else. The same rule covers `topics.nuon`'s rows and `why-review.nuon`'s.

**`use` has a word floor, and it is not the gesture rule.** Five words, which
`tests/help-content-model.nu` checks. It exists because replacing an entry's
whole `use` with the single character `x` used to exit 0, and one word is not
an under-described gesture but an absent one. It is set from the corpus, not
from taste: measured over all 84 entries the shortest real `use` is 8 words and
the mean is 34, so the floor has three words of headroom and cannot fire on
anything anyone has written. Whether a `use` describes the *real* gesture is a
different question, decided by a reader against the entry's `source` PRD and
its live route, and recorded in `use-review.nuon` — see "Writing an entry"
below.

### `verify` — a list of typed targets

One entry can document a pair (`Up`/`Down`), a group (`<C-h/j/k/l>`), or a
command that also has an alias, so `verify` is always a **list** of records,
each with a `kind`:

| kind | fields | checked against |
|---|---|---|
| `keybinding` | `name` | `$env.config.keybindings`, matched by `name` |
| `alias` | `name` | `scope aliases` |
| `command` | `name` | `scope commands` (defs and externs) |
| `nvim-map` | `mode`, `lhs`, optional `desc`, optional `scope` | `nvim_get_keymap` |
| `wezterm-key` | `key`, `mods`, optional `table` | `wezterm show-keys --lua` |
| `tmux-key` | `key`, `mods`, optional `table` (default `root`) | `tmux -L <label> list-keys -T <table>` |
| `prose` | — | nothing; existence-exempt and counted separately |

Two nuances the drift check depends on:

- **`desc`** on an `nvim-map` target is the string the live map's `desc` must
  equal. Absent means "compare against this entry's `title`". Explicit `null`
  means the live map carries no `desc` on purpose (the centered-jump maps, the
  visual-indent maps, Neovim's own LSP keys) — existence only, never a
  mismatch. Without this the mismatch class would fire on every descless map.
- **`scope: "buffer"`** marks a buffer-local map (the LSP aliases attach on
  `LspAttach`), so introspection needs a buffer with a server attached. A
  global-map lookup would report it stale.

**Every element of the list must be a record, and that is now said with a
message rather than a stack trace.** A `verify` holding a non-record — `verify:
["foo"]`, `[5]`, `[null]` — used to die inside the gate with an uncaught
`nu::shell::only_supports_this_input_type`: still exit 1, so nothing unsafe
passed, but the run stopped at the first bad entry and reported nothing about
the rest of the corpus. Since 2026-08-21 it reports
``verify target is a string, not a record`` against the file and entry id and
carries on, so an unrelated defect elsewhere in the manual shows up in the same
run.

`prose` covers both an entry with no live counterpart (a concept) and one with
no introspectable handle — the bare-word fallback is a `pre_execution` hook and
telescope's marking keys are picker-internal; both are real, neither is
addressable by name.

### `lhs` is written as you press it, and normalized before comparing

Measured against a live Neovim (0.12.4), `nvim_get_keymap` does not return the
`lhs` you wrote in the config. It returns a normalized form:

| written | returned |
|---|---|
| `<leader>ff` | `" ff"` — leader expanded to the actual key |
| `<space>` | `" "` — and so `<leader><space>` returns two spaces |
| `<C-h>` | `<C-H>` — the letter is upper-cased |
| `<A-j>` | `<M-j>` — alt is reported as meta |
| `<S-h>` | `H` — shift on a letter folds into the letter |
| `<S-Right>` | `<S-Right>` — shift on a *named* key does not fold |
| `<C-Up>` | `<C-Up>` — a named key keeps its case |
| `<` | `<lt>` |

These files hold the written form, because the manual has to show what you
press. The drift check must therefore normalize before matching, or every
control-letter map in the config reads as stale. That failure is silent and
looks exactly like a real regression.

How much of the resolution these rules carry, measured 2026-08-29 against 61
global `nvim-map` targets and 217 live maps: raw `lhs` comparison resolves
**30**, these rules resolve **61**. The `<space>` row was the last one found —
by `<leader><space>`, which was the single unresolved global target after the
other six — and it is in the table because a rule that is only in the code is
a rule the next reader re-discovers by watching a real map read as stale.

One more measured detail: `K` is **not** a global map. Neovim attaches hover
per buffer on `LspAttach`, while `grn`, `gra`, `grr`, `gri` and `gO` are
global. So `K` carries `scope: "buffer"` and the others do not.

### `tmux-key` puts the modifiers in the key, `wezterm-key` does not

The two kinds share a shape and differ in exactly one habit, which is the
thing that trips a writer moving between them.

A **tmux** binding spells its modifiers inside the key — `C-S-x`, `M-x` — so a
`tmux-key` target carries the whole chord in `key` and `mods: "NONE"`. Written
as `{key: "x", mods: "CTRL|SHIFT"}` it matches nothing, because
`list-keys` never prints that form.

A **wezterm** target keeps them apart, and carries its own trap, below.

### `wezterm-key` is spelled the way `show-keys` prints it

`mods` is `NONE` for an unmodified key. For anything modified, `show-keys`
prints WezTerm's own spelling, not the one written in the Lua config, and the
two differ in two independent ways:

| written in `wezterm.lua` | printed by `show-keys --lua` |
|---|---|
| `key = "q", mods = "CTRL\|SHIFT"` | `key = 'Q', mods = 'CTRL'` |
| `key = "x", mods = "CTRL\|SHIFT"` | `key = 'X', mods = 'CTRL'` |
| `key = "v", mods = "CTRL"` | `key = 'v', mods = 'CTRL'` |
| `key = "Tab", mods = "CTRL\|SHIFT"` | `key = 'Tab', mods = 'SHIFT\|CTRL'` |

1. **Ordering.** Where both survive, it is `SHIFT|CTRL` — in that order. A
   documented `CTRL|SHIFT` matches nothing while looking perfectly reasonable.
2. **Shift folds into a letter.** Control+shift on a *letter* is reported as
   the **uppercase letter with `mods = 'CTRL'`** and no `SHIFT` at all — the
   same fold `nvim_get_keymap` does to `<S-h>`. `SHIFT|CTRL` survives only
   where shift cannot fold: `Tab`, digits, symbols, named keys.

Measured against a live WezTerm on 2026-08-20, not assumed. This is not a
cosmetic detail: `{key: "q", mods: "SHIFT|CTRL"}` was written for
`Ctrl+Shift+Q` and resolves to nothing, and a `SHIFT|CTRL` letter row does
exist in the output for many keys — WezTerm's *defaults* carry both spellings —
so the wrong form fails silently on our bindings while looking correct next to
the defaults.

One consequence the drift check inherits: a documented key that WezTerm also
binds by default (`T`, `N`, `W`, `Z`, …) resolves off the default alone. Such
an entry can pass while the binding it documents was never written. Where that
matters the entry says so in its `why`.

`table` is the key table's real name: the F5 jump table is `jump_mode`, and the
other two a live config reports are `copy_mode` and `search_mode`. A `table`
that does not exist must be an error rather than an empty match, or a renamed
table silently documents nothing.

## Writing an entry

- `title` is one line, imperative, no trailing period. For an `nvim-map` target
  with no explicit `desc`, the title *is* the string compared against the live
  map, so it must match the `desc` in the config. All three clauses are gated,
  and "imperative" **fails closed**: the first word must be a base-form verb on
  the gate's `IMPERATIVE_VERBS` list, and anything else is a violation. Write a
  title whose verb is not on the list yet and the gate tells you so; add the
  verb in the same change, having read the title. That one-line edit is the
  review.

  It used to be a blocklist — a gerund, a third-person verb, or one of 33
  determiners, all decided from the first word — and it let through everything
  it had not thought of. Three confirmed escapes, all exit 0: `Tab jumping by
  number` (the gerund is not the first word), `Fast tab access by number`
  (adjective-led noun phrase), `Jumped to a tab by its number` (past tense).
  All three are now `selftest` controls. The set of noun phrases is unbounded;
  the set of verbs this manual opens a title with is 51 long.
- `use` is the gesture, not the key again: "press `F5`, then a digit 1–9",
  never "presses F5 to jump". Naming the key mid-sentence is fine — R5's own
  example does it. What is not fine is *opening* with it, which is the title
  written twice: "`<leader>fg` searches file contents" says nothing about the
  gesture, while "press `<leader>fg`, then type" does. **Backticks do not
  exempt you**, and this is not a hypothetical: the check compared the bare id
  only, every id in this corpus is written in backticks, and so it fired on
  none of the 84 entries while 24 of them opened with their own id. Nine were
  real violations.

  That rule is scoped to `key` entries, deliberately. A `cmd` entry has no key
  to restate: for `g` or `capsule list` the invocation *is* the gesture,
  because typing it is what you do.

  **And the gesture itself is held by a reader, the way `why` is — see
  `use-review.nuon`.** Presence, a five-word floor and the opener rule are all
  floors under vacuity; whether the `use` describes the gesture the spec and
  the configuration actually perform is a reading, and every entry needs a row
  in `use-review.nuon` recording that someone did it. The digest there keys on
  the `use` **and** the `source` together, because a review says "this prose
  matches that spec" — so re-pointing an entry at a different PRD invalidates
  it just as rewriting the prose does. The file carries the ritual.

  The premise that kept this ungated for three cycles was that "80 of 84
  entries have no deployed surface to be checked against". It was wrong on its
  own terms: every entry carries a `source:` naming the PRD that specifies the
  capability, all 84 of those resolve, and a spec is exactly what a `use` is
  supposed to describe. 79 of the 84 have a live route to read as well. The
  `Ctrl-T` defect cited as proof the clause was uncheckable had itself been
  found by reading `config.nu:635` → `config.nu:686` → `finder.nu:33`. The
  method worked; what was missing was the obligation to run it.
- `why` only where the reason is non-obvious, and never restating what `use`
  already said — if `use` explains a mechanism, the mechanism belongs here and
  the gesture stays there. Measured on 2026-08-20: 51 of 84 entries carry a
  `why`, which is more than the spec's R5 predicts ("most entries won't have
  one"). Each one reviewed carries a real constraint, so the entries are not
  the thing to change; the wording of R5 is an open question against this
  corpus, not a licence to add whys.

  **This one clause is held by a reader, not by a text check, and the gate
  holds the reader to it.** Two mechanical proxies were built and measured, and
  both are recorded here so a third is not attempted:

  | proxy | corpus mean | where the known defects landed |
  |---|---|---|
  | containment of `why`'s content words in `use` | 0.11 | `Ctrl+V` 0.097 — rank 28 of 51, *below* the mean |
  | best single sentence of `why`, same containment (2026-08-21) | 0.157 | `Ctrl+C` 0.167 — rank 23; `Ctrl+Shift+B` 0.143 — rank 27 |

  Neither separates anything: a threshold that catches those entries fires on
  half the manual. The reason is that the restatement is semantic — `Ctrl+C`'s
  `why` opened "One key for both because the terminal can tell them apart",
  which is exactly what its `use` says in completely different words.

  So the clause is held by a person, and `why-review.nuon` is what stops that
  being a wish. Every `why`-carrying entry needs a row there whose `digest`
  matches its current `use`/`why` pair; add a `why` or edit either field and
  the gate fails until someone reads the new pair and records it. The file
  itself carries the three-step ritual.

  Reviewing your own writing used to be "the part no gate can enforce", stated
  in a prose note the gate ignored — and four rows duly said in plain words
  that they vouched for their own writing while passing. A row now carries an
  optional `author` field naming the session that wrote or last revised the
  pair, and the gate **fails** any row where `author` equals `reviewer`. On
  2026-08-21 those four were re-read by a session that had written none of
  them; all four stand, and each note now gives the reading rather than the
  fact of it. What is still unenforceable is omission: leaving `author` out is
  invisible in the data, so this hardens an honest record rather than
  defeating a careless one.
- Add the entry in the **same change** as the binding. `help --check` exits
  non-zero on an undocumented one, which is the only reason this file stays true.

- `also` names other entries by their exact `key`/`cmd` — `"cc [...args]"`,
  not `"cc"`. A pointer to nothing is worse than no pointer, so the check
  resolves every one of them.

Strings are single-line by design, even long ones: it keeps `grep` and
`| where use =~ …` useful, and renderers reflow.

## Checking it

```
nu tests/help-content-model.nu
```

Strict schema, topics, the writing rules, `also` resolution, the currency of
`why-review.nuon` and of `use-review.nuon`, and the coverage the PRD's
`coverage/` child names, R1–R4.
It exits non-zero on any violation, and it fails rather than passes when it
finds nothing to check.

Requirement numbers moved when the node split on 2026-08-20: the four coverage
requirements became the child's R1–R4, the old R8 (concepts) is now R4 and the
old R9 (writing rules) is now R5. The gate's comments and messages cite the
current numbers.

Three of its constants are transcribed from the spec rather than read out of
the data, and that is deliberate — a check fed by the thing it is checking can
only assert that the data agrees with itself:

- `COVERAGE` — the surfaces the `coverage/` child's R1–R4 name. If a
  requirement names a key and no entry documents it, this is what notices.
- `TOPICS` — R3's nine ids **in R3's order**. Before it existed the topic list
  was read out of `topics.nuon`, so renaming `git` to `vcs` or deleting
  `history` both exited 0.
- `VERIFY_KINDS`'s `nullable` — the "Entry schema" section's three-state `desc`
  rule above, transcribed. Take `desc` out of it and the 14 live targets that
  write `desc: null` all fail, which is how you know the exception is carrying
  weight rather than decorating the record.

`selftest` runs every predicate — `restates-key`, `non-imperative`,
`why-digest`, `use-digest`, `bad-string`, `bad-string-list`, `bad-record`,
`bad-field` and `too-thin` —
against known-bad and known-good inputs on every run, so a repeat of the
backtick miss above fails here instead of passing quietly for a cycle. The
imperative check and the shape checks find no violation in the current 84
entries, which is why their controls matter more than their output: a check
with subjects and no violations and a check that cannot fire read identically
from the outside.

**What it cannot do by itself**: confirm that a `use` describes the gesture the
configuration actually performs. The gate holds `use` to presence, a non-empty
string, a five-word floor and the no-restating-the-key opener — every one of
those is a floor under vacuity, not the clause. The gap was not theoretical:
`shell.nuon [Ctrl-T]`'s `use` skipped a whole step of the live route, sat
marked as met for a cycle, and was found by a person reading `config.nu`, not
by this file.

What changed on 2026-08-21 is that the reading is now *obligatory* rather than
occasional. `use-review.nuon` holds one row per entry, keyed on a digest of the
`use` and the `source` together, and the gate fails on a missing row, a stale
row, a row reviewing an entry that is gone, or a row whose `reviewer` is its
`author`. The gate still does not decide the clause — a person does — but it
decides whether a person has, and against exactly which text. The old claim
that "80 of the 84 entries describe a surface that is not deployed, so there is
nothing to be checked against" was wrong twice over: all 84 carry a `source:`
PRD that resolves, and 79 have a live route as well. Only `capsule.nuon`'s five
have neither, and their rows say so.

The rest of that sentence: it cannot confirm a `verify` target resolves against
a live shell, editor or terminal either — that is `help --check`
(`prds/06-help/04-drift-check`), and it needs a deployed configuration —
which does not exist yet. Until then the target names are the contract the
shell, editor and terminal work must meet, and the shell ones were read off
the live nushell config (`hist_picker_local`, `hist_picker_global`,
`hist_up_local`, `hist_down_local`, `hist_up_global`, `hist_down_global`,
`tv_remote`, `tv_remote_f1`, `finder_pick`, `quicklist`, `esc_clear`) rather
than invented here.
