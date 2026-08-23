---
state: done
claim: 
priority: 19
est: 0.5h
actual: 15m
mode: afk
needs:
verify: "bash gates/tree-links.sh"
origin: derived
---

# "The GUI launch dies" survives in five more places

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: a GUI-launched WezTerm with no PATH seeding does **not** die — it
creates the pane and keeps it, showing the spawn error, `didn't exit cleanly`,
and `exit_behavior="CloseOnCleanExit"`. Measured three times now by three
different agents.

[`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md) R4
asserted the inventory was "the last carrier". It was not — the census found **five**
more, and one of them is the row a future analyst would spec from.

**Amended 2026-08-23 by the orchestrator: four became five.** This node was
filed off a single-dimension grep. Its analyst ran a three-dimensional one and
found a fifth carrier **in a file already on the list**:
`prds/02-terminal/06-launchd-path/prd.md:121`, an acceptance box promising
Finder "opens a working shell rather than dying" — one file, two carriers, six
lines apart from the R3 that corrects them. Same shape as
[`truncated-source-attributions`](../truncated-source-attributions/prd.md),
where seven became nine for the same reason.

| carrier | note |
|---|---|
| `prds/02-terminal/06-launchd-path/prd.md:30` | contradicted by its own R3 at `:55-62`, which carries the correction |
| `prds/00-delivery/corrections/prd.md:52` | row T-10, **state open** — the one that propagates |
| `prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md:32` | `done` |
| `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md:82` | `done` |

Worth a node rather than four drive-bys because the T-10 row is *live*: a
correction backlog entry is read as a specification, so a wrong symptom there
becomes a wrong requirement.

## Requirements
- [x] **R1** — All **five** carriers state the measured symptom: the pane
      survives, carrying the spawn error and the `exit_behavior` note. The
      symptom is *harder* to diagnose than a vanished window, which is why
      the correction matters rather than being pedantry.
- [x] **R2** — `06-launchd-path/prd.md:30` is reconciled with its own R3
      instead of being edited in isolation. A file contradicting itself is
      worse than a file wrong in one place, and R3 is the verified half.
- [x] **R3** — Re-run the census afterwards and report zero carriers. The
      previous attempt claimed the last one while four survived, so the
      closing evidence is a grep, not an assertion.
- [x] **R4** — No requirement, acceptance box or rating changes **in
      substance**. Prose only.

      *Read on the record, because read literally R4 forbids this node's own
      work.* **Three of the five carriers sit inside a box**: `w0-1:32` is
      `- [x] **R2**`, `spec06:82` is `- [x] **B8**`, and
      `06-launchd-path:121` is `- [~]`. R1 demands all five state the measured
      symptom, so R1 and R4 cannot both be read literally.

      R4 governs the **contract**: no marker changes, no box changes what
      would falsify it, no `C`/`U` moves — only the sentence naming the
      failure mode. Carrier 5 is the clean illustration: its check ("opens a
      working shell, and resolves `nu`, `nvim`, `tv`, `zoxide`") is untouched
      and only the false counterfactual goes.

## Acceptance
- [x] All five corrected passages quoted, plus the `cli list` output showing
      the surviving pane. **Executed by the orchestrator, 2026-08-23** — all
      five edits applied from the spec's pre-resolved text. Fourth
      independent measurement, `wezterm-mux-server` under
      `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`:

      ```
      WINID TABID PANEID WORKSPACE SIZE  TITLE   CWD
          0     0      0 default   80x24 wezterm
      ```

      with `Unable to spawn nu because: / No viable candidates found in
      PATH … / didn't exit cleanly / … exit_behavior="CloseOnCleanExit"`.
      The pane exists.
- [x] The closing census quoted, showing zero remaining carriers.
      `grep -rn 'GUI launch dies' prds/` returns **5 hits, all of them the
      phrase quoted *as retired* inside correction bodies** — two in
      `pwd-closure-blast-radius/specs/spec02.md`, one in this PRD, two in this
      node's own spec. Zero carriers. That is precisely the allow-list case
      [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md) R2 has to
      handle, and it is why a naive tree-wide grep would go red on its own
      correction.
- [x] `bash gates/tree-links.sh` Tier A at 0 broken, asserted as a delta.
      **Measured before and after in one session: Tier A `783 links, 0
      broken` both times; Tier B `114 broken` both times; exit 0 both
      times.** Zero link delta, exactly as the spec designed — no edit adds a
      markdown link, and Edit 5 deliberately adds none because spec06's two
      existing links are already part of Tier B's standing 114.

## Out of scope
- `docs/capabilities-terminal.md`, already corrected by
  [`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md).
- `~/.config/wezterm/wezterm.lua:1029-1030`, which is read-only reference.
