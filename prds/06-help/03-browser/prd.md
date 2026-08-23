---
state: open
priority: 10
est: 1h
task: H.3
mode: afk
needs:
  - 06-help/02-help-command
  - 05-platform/01-deploy-mechanism/managed-config
  - 04-shell/04-television
  - 04-shell/07-quicklist
  - 00-delivery/corrections/w0-4-s2-corrections
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
- [ ] **R2** — **Preview.** The focused row previews its full entry: title,
      use, why, related. This is where `why` earns its place — the constraint
      is visible at the moment you're looking the key up.
- [ ] **R3** — **Entry points.** `help --fuzzy`, and the `help` channel
      appearing in the `Ctrl-Space` channels remote like any other channel. No
      new global keybinding is required; add one only if it proves needed in
      daily use.
- [ ] **R4** — **Actions.** `enter` prints that entry's detail into the
      scrollback (the default — you looked it up to read it). `ctrl-o` opens
      the PRD named by the entry's `source` field in `$EDITOR`, for when the
      answer is "why is it like this". That field is defined by
      [`01-content-model`](../01-content-model/prd.md) R2 — required, shape-
      checked and resolved against the repo — and its path is repo-root
      relative. All 84 live entries resolve in node form (`<node>/prd.md`),
      measured 2026-08-21 by `nu tests/help-content-model.nu`, which reports
      none still on the pre-board flat form.
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
