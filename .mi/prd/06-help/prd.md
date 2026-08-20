---
state: open
mode: afk
deps: []
verify: ""
---

# Epic: `help` — the environment manual

Purpose: The configuration is dense and largely invisible. Nothing tells you
(or an agent) that `F5 3` jumps to tab 3, that a bare word jumps via zoxide,
that `Ctrl-R` is directory-scoped while `Alt-R` is global, or that
`Shift+arrows` select and a plain motion then collapses the selection. The
knowledge lives in comments across ~2600 lines of nushell, Lua, and TOML — and
in whoever wrote it. Two distinct readers need it: - **You**, wanting a cheat
sheet: what exists, what it does, how to use it. - **Agents**, needing to
operate this environment correctly. An agent that can run one command and
learn the real keybindings, commands, and idioms stops guessing and stops
suggesting `fzf` when `tv` is what's installed.

Goal: One command — `help` — that renders the complete manual for this
configuration: every custom keybinding, command, alias, and workflow, with
what it does and how to use it. Human-readable by default, machine-readable on
request, and verifiable against the live config so it cannot silently rot.

## Requirements

**Architecture invariants**

- [ ] **I1** — **One content source, many renderers.** Human tables, fuzzy
      browser, JSON, and markdown all read the same data. A binding is
      described exactly once.
- [ ] **I2** — **Delegate, never shadow.** Anything that isn't ours goes to
      the tool that owns it — builtin `help` for nu commands, `:help` for
      Neovim.
- [ ] **I3** — **Checkable or absent.** Every documented binding must be
      verifiable against live introspection, or explicitly marked prose-only.
- [ ] **I4** — **Non-TTY output is plain.** No pager, no colors, no TUI when
      stdout isn't a terminal — agents capture stdout, and [tv needs a
      TTY](../04-shell/04-television/prd.md).

## Acceptance
- [ ] A newcomer runs `help` and can use this environment: navigate, find,
      edit, containerize.
- [ ] An agent runs one command and gets the same knowledge as structured
      data.
- [ ] Adding a keybinding without documenting it fails the drift check.

## Out of scope
- Replacing nushell's builtin `help` for nu commands, or `:help` in Neovim,
  or which-key's in-editor discovery. This documents *our* configuration and
  delegates everything else.
- A hand-written document nobody updates. If it can't be checked, it isn't
  in scope.
- A web page or GUI. Terminal-first, since that's where the work happens.

## Two findings that shape the design

1. **Nushell sanctions overriding `help`.** Its builtin help says verbatim:
   *"If you want your own help implementation, create a custom command named
   `help` and it will also be used for `--help` invocations."* So typing
   `help` is the supported design — but our command inherits a real duty:
   it intercepts `<anything> --help` too, and must delegate those to the
   builtin. Getting this wrong breaks `--help` everywhere. See
   [02-help-command](02-help-command/prd.md).
2. **Most of the content is introspectable**, so the manual can be checked
   against reality rather than hand-maintained on trust:
   - nushell: `$env.config.keybindings` (each entry has a `name`),
     `scope aliases`, `scope commands` (name, category, description)
   - Neovim: `nvim_get_keymap` per mode — and our maps already carry `desc`
     (87 normal-mode maps, descriptions present)
   - WezTerm: `wezterm show-keys --lua`, including `--key-table` for the F5
     jump table
   What is *not* derivable is the teaching part: grouping, prose, "how to
   use it", and why. Hence a curated content model plus a drift check, not
   pure generation. See [01-content-model](01-content-model/prd.md) and
   [04-drift-check](04-drift-check/prd.md).


## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
