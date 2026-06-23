# finder — concept & design

`finder` is a composable, **typed** fuzzy finder for Nushell built on top of
`tv` (television). It lives in `home/dot_config/nushell/finder.nu` and is sourced
by `config.nu`. This document explains the model; the code comments cover the
line-level mechanics, and `tests/nushell/finder-test.nu` pins the behaviour.

## The one idea

**Don't hand-code pickers. Treat `tv`'s channels as data, and let Nushell
orchestrate them into a typed pipeline.**

`tv` already ships dozens of channels (`files`, `text`, `git-log`, …), each a TOML
prototype describing a source command. Rather than reimplement a fuzzy UI per
search, finder:

1. lets you pick a channel by typing its unique prefix (autofires),
2. runs that channel through `tv` to get a selection,
3. **decodes the selection into real Nushell values** typed by the channel, and
4. lets you **pipe** one channel's selection into the next, scoped automatically.

The payoff over raw `tv` is the last two: structured output you can pipe in nu,
and typed chaining that only ever offers sensible next steps.

## Vocabulary

| Term | Meaning |
|------|---------|
| **channel** | A `tv` source (`files`, `text`, `git-log`, …). The unit you pick. |
| **stage** | One committed step: `{ channel, results, produces }`. |
| **carry** | The stage flowing *into* the current pick — the upstream selection. |
| **chain** | The list of committed stages, newest last. Rendered as a breadcrumb. |
| **produces / accepts** | The type a channel emits, and the upstream types it can scope on. |

## The type graph

Only channels with a declared type can chain. The table (`_finder_type`):

| channel | produces | accepts (can scope on) |
|---------|----------|------------------------|
| `files` | `FileList` | `DirList` |
| `dirs` | `DirList` | `DirList` |
| `text` | `GrepList` | `FileList`, `DirList` |
| `git-log` | `Commits` | `FileList` |

Anything else is `Any` with no accepts → it runs fresh and is a chain dead-end.

A directed **scope edge** exists from carry → channel when the carry's `produces`
is in the channel's `accepts`. `_finder_scope` turns an edge into a concrete,
path-scoped source command (e.g. `files → text` becomes `rg … -- '<paths>'`).
`_finder_compatible` derives the chainable channels *from the edges themselves*,
so the picker list and the scoping can never drift apart.

## The flow

```
            ┌──────────────────────────────────────────────┐
   pick ───▶│ _finder_pick_channel   (nu, prefix-autofire)  │
            └───────────────┬──────────────────────────────┘
                            ▼
            ┌──────────────────────────────────────────────┐
   run  ───▶│ _finder_run_channel    (tv, scoped by carry)  │
            └───────────────┬──────────────────────────────┘
                            ▼ confirm key + entries
            ┌──────────────────────────────────────────────┐
 branch ───▶│ enter → commit & finish                       │
            │ ctrl-p → pipe: commit, re-pick (scoped)       │
            │ ctrl-b → back: pop, re-run upstream           │
            │ ctrl-n → fwd: redo the stage back left behind │
            │ ctrl-r → reset: tear the pipe down, re-pick   │
            └───────────────┬──────────────────────────────┘
                            ▼
            ┌──────────────────────────────────────────────┐
 decode ───▶│ _finder_decode   (typed nu values out)        │
            └──────────────────────────────────────────────┘
```

### Pick — prefix-autofire

The channel is chosen by **typing its name's unique prefix**, not a fuzzy
multiselect. The instant exactly one channel still matches, it fires (`f` →
`files`). A keystroke that would match nothing is rejected, so the buffer always
resolves to ≥1 channel. On the first pick the candidates are *all* tv channels;
on a chain pick they are only the channels the carry can flow into.

### Pipe — chaining with `ctrl-p`

Inside the result list, `ctrl-p` **commits the current selection as a stage and
re-opens the picker** (a fresh tv remote), now filtered to channels that accept
this stage's type and scoped to its paths. So `files` → `ctrl-p` → `text` greps
*only the files you selected*. `ctrl-b` steps back one stage; `ctrl-n` walks
forward again, re-entering the stage a `ctrl-b` left behind (browser back/forward).
`ctrl-r` resets — tears the whole pipe down to a fresh channels pick. `enter` ends
the chain. The whole input chain is shown as a breadcrumb (`files[3] > text[1] >`)
in every header, above the input.

### Decode — the payoff

`_finder_decode` maps the final stage's raw lines into real values keyed by what
the channel `produces`:

| produces | decoded value |
|----------|---------------|
| `FileList` / `DirList` | `list<string>` of expanded, existing paths |
| `GrepList` | `list<{ file, line, text }>` (split on the first two colons; text keeps the rest) |
| `Commits` | `list<{ hash, subject }>` (graph-art rows dropped) |
| anything else | the raw lines |

This is what makes finder *composable in nu*: `finder | each { … }` gets typed
records, not strings to re-parse.

## Persistence & resume

A committed chain is saved as versioned NUON under `$XDG_STATE_HOME/finder/`, each
stage carrying its `channel`, `results`, `produces`, and the typed `query`.
`finder --resume` re-enters the saved chain — it re-runs the last channel scoped by
the stage below it **and prefills the prompt with that stage's saved query**, so you
drop back *into* the search ready to adjust it rather than just reprinting its
result. The same prefill happens on `ctrl-b` back-nav.

tv has no `--print-query`, so the query is recovered *after the fact* from tv's own
channel-scoped history (`$XDG_DATA_HOME/television/history.json`) via
`_finder_history_query`. The prefill lands with the cursor at the end and **no
selection** (tv's prompt has no text selection), so resume is for adjusting or
extending; `--fresh` (leader `F`) skips the prefill for a clean slate.

## Hard constraints (tv 0.15.8)

- Capture tv's stdout **directly**, never `| complete` — `complete` also grabs
  stderr, detaching tv's controlling terminal (it then panics, os error 6).
- `--keybindings` uses `key="action"`; `--expect` takes a **semicolon**-separated
  key list. The chain keys are `ctrl-p` (pipe) / `ctrl-b` (back) / `ctrl-n`
  (forward) / `ctrl-r` (reset).
- Scoped paths are **POSIX single-quoted** before splicing into a source command
  (tv runs it through a POSIX shell on Linux/WSL2/macOS).
- finder is **interactive-only** — it drives a TUI and must not be called
  non-interactively.

## Extending

- **Add a typed, chainable channel:** add a row to `_finder_type` (its `produces`
  + `accepts`) and a scope arm to `_finder_scope`. `_finder_compatible` and the
  picker pick it up automatically.
- **Add a decode shape:** add a `produces` arm to `_finder_decode`.

## Testing

Pure functions (`_finder_decode`, `_finder_scope`, `_finder_type`,
`_finder_compatible`, `_finder_shquote*`, `_finder_breadcrumb`, `_finder_mk_stage`)
are covered headless in `tests/nushell/finder-test.nu` — run `just test`. The
interactive layer (tv, `input listen`, the prefix overlay render) needs a tty and
is verified by hand.
