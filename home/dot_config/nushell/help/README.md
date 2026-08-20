# `help` content model

The manual's single data source. Every renderer — `help` itself, the tv
browser, `help --json`, `help --md` — reads these files and holds layout only.
No description text for this environment lives anywhere else.

Spec: `.mi/prd/06-help/01-content-model/prd.md`. Read that before editing the
schema; read this before editing an entry.

## Files

| File | Surface |
|---|---|
| `topics.nuon` | the spine: the nine topics in reading order, with summaries |
| `shell.nuon` | nushell — keybindings, aliases, custom commands, idioms |
| `nvim.nuon` | Neovim — keymaps, plugin keys, and the core keys we keep |
| `terminal.nuon` | WezTerm — jump mode, window/tab keys, copy mode, clipboard, capsule bindings |
| `capsule.nuon` | the capsule CLI and what a container gets from the host |

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

One more measured detail: `K` is **not** a global map. Neovim attaches hover
per buffer on `LspAttach`, while `grn`, `gra`, `grr`, `gri` and `gO` are
global. So `K` carries `scope: "buffer"` and the others do not.

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
  map, so it must match the `desc` in the config. All three clauses are gated:
  "imperative" is decided from the first word, which is where its three failure
  modes show — a gerund ("Jumping to a tab"), a third-person verb ("Jumps to a
  tab") or a noun phrase ("The fastest way to a tab"). Verbs that genuinely end
  in `s` (`Press`, `Pass`, `Focus`) are allowlisted, and the allowlist is
  itself a `selftest` control, because a rule that rejects `Press` in a manual
  about keys would be turned off within the week.
- `use` is the gesture, not the key again: "press `F5`, then a digit 1–9",
  never "presses F5 to jump". Naming the key mid-sentence is fine — R5's own
  example does it. What is not fine is *opening* with it, which is the title
  written twice: "`<leader>fg` searches file contents" says nothing about the
  gesture, while "press `<leader>fg`, then type" does. **Backticks do not
  exempt you**, and this is not a hypothetical: the check compared the bare id
  only, every id in this corpus is written in backticks, and so it fired on
  none of the 84 entries while 24 of them opened with their own id. Nine were
  real violations.
- `why` only where the reason is non-obvious, and never restating what `use`
  already said — if `use` explains a mechanism, the mechanism belongs here and
  the gesture stays there. Measured on 2026-08-20: 51 of 84 entries carry a
  `why`, which is more than the spec's R5 predicts ("most entries won't have
  one"). Each one reviewed carries a real constraint, so the entries are not
  the thing to change; the wording of R5 is an open question against this
  corpus, not a licence to add whys.

  **This one clause is held by review, not by the gate, and that is a measured
  decision rather than an omission.** The obvious mechanical proxy is word
  overlap between `use` and `why`, and it was computed over all 51 pairs
  (content words, stopped and deduplicated, containment of `why` in `use`).
  It does not separate the defects from the good entries: the corpus mean is
  0.11, and the one entry known to state the same fact twice — `Ctrl+V`, whose
  `why` said the paste "works inside a running program and not only at a
  prompt" while its `use` already said "in any pane — a shell prompt, nvim, a
  running agent alike" — scores **0.097, ranking 28th of 51, below the mean**.
  A threshold that caught it would fire on more than half the manual. The
  restatement is semantic, in different words, so it takes a reader. Both
  defects the 2026-08-20 review found (`Ctrl+V` and `Ctrl-T`) were rewritten
  in that pass; re-run the review when entries are added rather than trusting
  the gate to notice.
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

Strict schema, topics, the writing rules, `also` resolution and the coverage
the PRD's `coverage/` child names, R1–R4. It exits non-zero on any violation,
and it fails rather than passes when it finds nothing to check.

Requirement numbers moved when the node split on 2026-08-20: the four coverage
requirements became the child's R1–R4, the old R8 (concepts) is now R4 and the
old R9 (writing rules) is now R5. The gate's comments and messages cite the
current numbers.

Two of its constants are transcribed from the spec rather than read out of the
data, and that is deliberate — a check fed by the thing it is checking can only
assert that the data agrees with itself:

- `COVERAGE` — the surfaces the `coverage/` child's R1–R4 name. If a
  requirement names a key and no entry documents it, this is what notices.
- `TOPICS` — R3's nine ids **in R3's order**. Before it existed the topic list
  was read out of `topics.nuon`, so renaming `git` to `vcs` or deleting
  `history` both exited 0.

`selftest` runs both prose predicates against known-bad and known-good strings
on every run, so a repeat of the backtick miss above fails here instead of
passing quietly for a cycle. The imperative check finds no violation in the
current 84 entries, which is why its controls matter more than its output: a
check with subjects and no violations and a check that cannot fire read
identically from the outside.

What it cannot do is confirm a `verify` target resolves against a live shell,
editor or terminal: that is `help --check`
(`.mi/prd/06-help/04-drift-check`), and it needs a deployed configuration —
which does not exist yet. Until then the target names are the contract the
shell, editor and terminal work must meet, and the shell ones were read off
the live nushell config (`hist_picker_local`, `hist_picker_global`,
`hist_up_local`, `hist_down_local`, `hist_up_global`, `hist_down_global`,
`tv_remote`, `tv_remote_f1`, `finder_pick`, `quicklist`, `esc_clear`) rather
than invented here.
