---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/04-shell/04-television
  - .mi/prd/04-shell/07-quicklist
  - .mi/prd/05-platform/01-deploy-mechanism/managed-config
  - .mi/prd/06-help/02-help-command
verify: ""
---

# Fuzzy browser

Parent: [Help epic](../prd.md) · C 3 · U 7 · net-new

Purpose: "I know it exists, I forget the key" — a fuzzy search over every
manual entry, as a television channel. Consistent with the shell epic's
invariant that tv owns every picker screen, so this is a cable file plus a
small runner, not a new UI.

## Requirements
- [ ] **R1** — **Channel.** A `help` cable channel whose source emits one row
      per entry from [01-content-model](../01-content-model/prd.md): topic, key/cmd,
      title — TAB-delimited, mirroring how the quicklist channel is built
      ([04-shell/07](../../04-shell/07-quicklist/prd.md)).
- [ ] **R2** — **Preview.** The focused row previews its full entry: title,
      use, why, related. This is where `why` earns its place — the constraint
      is visible at the moment you're looking the key up.
- [ ] **R3** — **Entry points.** `help --fuzzy`, and the `help` channel
      appearing in the `Ctrl-Space` channels remote like any other channel. No
      new global keybinding is required; add one only if it proves needed in
      daily use.
- [ ] **R4** — **Actions.** `enter` prints that entry's detail into the
      scrollback (the default — you looked it up to read it). `ctrl-o` opens
      the entry's source PRD in `$EDITOR`, for when the answer is "why is it
      like this".
- [ ] **R5** — **Interactive-only.** tv requires a TTY; guard and degrade to
      `help <query>` when there isn't one.

## Acceptance
- [ ] `help --fuzzy`, type "select": the shift-select entries appear, and the
      preview explains the collapse-on-motion behavior.
- [ ] `enter` leaves the detail in the scrollback after tv exits.
- [ ] Piping the command in a non-interactive context falls back to plain
      search output instead of panicking.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
