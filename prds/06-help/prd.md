---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
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

**I1** — **One content source, many renderers.** Human tables, fuzzy
browser, JSON, and markdown all read the same data. A binding is
described exactly once.

**I2** — **Delegate, never shadow.** Anything that isn't ours goes to
the tool that owns it — builtin `help` for nu commands, `:help` for
Neovim.

**I3** — **Checkable or absent.** Every documented binding must be
verifiable against live introspection, or explicitly marked prose-only.

**I4** — **Non-TTY output is plain.** No pager, no colors, no TUI when
stdout isn't a terminal — agents capture stdout, and [tv needs a
TTY](../04-shell/04-television/prd.md).

**I5** — **A `desc` exemption is declared, never inferred.** Neovim
introspection is uneven (finding 2), so the drift check must be told
which missing descriptions are intentional rather than inferring it. It
is told per verify target, by a three-state `desc` field on `nvim-map`
targets — enforced in `tests/help-content-model.nu`, whose
`VERIFY_KINDS` entry reads `nvim-map: {req: ["mode" "lhs"], opt:
["desc" "scope"], nullable: ["desc"]}`, and met by a writer in
`home/dot_config/nushell/help/README.md`:

  | state | meaning to the drift check |
  |---|---|
  | field absent | compare the live `desc` against this entry's `title` |
  | `desc: null` | the live map carries **no** description on purpose — assert existence only, never a mismatch (**7** targets do this, measured 2026-08-29; this cell read 14 until then) |
  | `desc: "text"` | the live map's description must equal that string |

  Two rules follow, and the second is the one that keeps the first honest:

  - A map that deliberately carries no description is written `desc: null`,
    so the check asserts existence and never reports a mismatch. The four
    centred-jump maps and the two visual-indent maps are this class, and
    `~/.config/nvim/lua/config/keymaps.lua:28` says so in the config itself.
  - An **omitted** `desc` means "compare against `title`", so omitting one
    for a map that *does* carry a description live is a defect, not an
    exemption. This clause is what stops I5 being read as a licence to skip
    the field. **The four failures this bullet promised do not exist.**
    Corrected 2026-08-29: it named four `nvim-map` targets from
    `use-review.nuon`'s header (`gd and gI`, `<leader>rn and <leader>ca`)
    that omit `desc` where the live maps set `LSP: …` strings, and called
    them "four drift-check false failures waiting". The `04-drift-check`
    analyst built the check and measured the live corpus: `desc` **absent 0**,
    **null 7**, **explicit 59**, and **zero** desc mismatches. The record does
    not say whether the corpus was fixed after this was written or the count
    was never right. The clause above still binds — an omitted `desc` on a map
    that carries one live is still a defect — but no child inherits an
    exception for four targets that are not there. See
    [`an-invariant-naming-a-defect-must-be-re-measured`](../memos/an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it.md).

  Maps that are not ours at all — Neovim's bundled matchit plugin, eight of
  the twelve — are not an exemption but out of scope, covered by
  [04-drift-check](04-drift-check/prd.md) R6's plugin/core allowlist.

  Why the three states survive the file at all: nushell's `open` on a
  heterogeneous `.nuon` list keeps records heterogeneous rather than
  null-filling them, so *absent* and *null* stay distinguishable across the
  round trip. Lose that and the rule collapses to two states.

  [04-drift-check](04-drift-check/prd.md) R2 ("Our maps carry `desc`, so the
  check can compare descriptions as well as existence") and its R4
  *Mismatched* class are written against the claim this invariant retires and
  need reconciling by that node's owner. Filed on the corrections backlog
  rather than edited here — another ticket owns that file.

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
   - Neovim: `nvim_get_keymap` per mode — 87 normal-mode maps, rich enough
     to check against, but not uniformly: measured 2026-08-21, **12 of those
     87 carry none**. Four are ours without a `desc` by design (the centred-
     jump maps) and eight belong to Neovim's bundled matchit plugin. Which
     absences are intentional is declared, not guessed — see **I5**.
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
