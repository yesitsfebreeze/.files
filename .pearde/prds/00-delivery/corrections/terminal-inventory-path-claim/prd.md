---
state: done
claim: 
priority: 14
est: 0.5h
actual: 15m
mode: afk
needs:
verify: ""
origin: derived
---

# The terminal inventory says `nu` does not resolve in the F6 subshell

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `docs/capabilities-terminal.md` (around line 125) explains the
inline PATH prefix in the F6 binding as covering a subshell "where neither
`nu` nor `tinty` resolves". T.7's analyst measured that half of it is false:
`sh -lc` is a **login** shell, so `/etc/profile` runs `path_helper`, which
reads `/etc/paths.d/homebrew` and puts `/opt/homebrew/bin` on PATH by itself.

```
$ env -i HOME=$HOME sh -lc 'command -v nu; command -v tinty'
/opt/homebrew/bin/nu
tinty: NOT FOUND
```

So the prefix earns `~/.local/bin` (where `tinty` lives), `~/.cargo/bin` and
`/opt/homebrew/sbin`. `nu` would have resolved without it.

Why an inventory line is worth a node: [`AGENTS.md`(../../../../../AGENTS.md)
makes the rated inventories the thing PRDs are specced *from*, and this repo
has already paid for that once — the whole `02-terminal` re-spec exists
because an epic was written from an inventory that was wrong. A stated reason
that is half false is how the next reader deletes the half that matters. It
also travels: the same wrong claim reached
[`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md)
R4, where it has now been corrected against the measurement.

The live `~/.config/wezterm/wezterm.lua:1029` comment carries the same claim.
That file is a read-only reference under this repo's rules, so it is recorded
here rather than fixed — and it is one more reason the corrected reason must
land in the rebuild's own comment, which T.7's spec01 does.

## Requirements

**Three wrong claims, not one — the node is larger than its author assumed.**
R3's census turned up two more, both in the same entry, and both reported
rather than folded in silently. Recorded here because "one prose line" was my
framing and it was wrong.

Every probe below ran under a **scratch `HOME`**: `~/.profile` on this
machine is `. "$HOME/.cargo/env"`, so with the real `HOME` the measurement
passes for the wrong reason — and this repo deploys no `dot_profile`.

- [x] **R1** — **Defect 1, the node's own.** The entry states what the prefix
      actually earns — `~/.local/bin` (where `tinty` lives), `~/.cargo/bin`,
      `/opt/homebrew/sbin` — and why `nu` resolves without it: `sh -lc` is a
      *login* shell, so `/etc/profile` runs `path_helper`, which reads
      `/etc/paths.d/homebrew`. The negative control isolates the cause to the
      login shell rather than to `env -i`: under `sh -c`, `nu: NOT FOUND`.
- [x] **R2** — The entry's complexity and usefulness numbers are re-read and
      left alone unless the correction genuinely changes them. **Settled:
      `C 2 · U 10` stays.** Complexity 2 — the implementation is a fixed
      four-entry string behind an `is_mac` guard and not one line changes.
      Usefulness 10 — defect 2 makes the symptom less dramatic, not less
      fatal (`nu` never starts, so no `04-shell` and no `help`), and defect 1
      moves *which* binary the F6 half is load-bearing for, not whether it
      is. The consistency rule also binds it:
      [`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md)
      carries `C 2 · U 10` sourced from this entry.
- [x] **R3** — **Census the neighbouring PATH claims, by running them.**
      Done by the analyst; the results are the requirements below and the
      list of claims deliberately left alone. Every claim in the file about
      what resolves in a given launch shape was probed: lines 120-123,
      125-127 and 136 are **true** and untouched, and the only other
      `resolves` uses (145, 509) are about font families and
      `wezterm show-keys`.
- [x] **R4** — **Defect 2: "the window dies immediately" is false.**
      Line 124. Re-measured independently with `wezterm-mux-server` under
      `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`: `cli list` shows PANEID 0
      **alive**, carrying `Unable to spawn nu because: / No viable candidates
      found in PATH`, then `didn't exit cleanly`, then `This message is shown
      because exit_behavior="CloseOnCleanExit"`. Already corrected in
      `06-launchd-path` R3; **this inventory is the last carrier.** It sits in
      the same sentence as defect 1, so leaving it would be absurd — but it
      gets its own box rather than riding along unnamed.
- [x] **R5** — **Defect 3: "the same seeding … for the identical reason" is
      false twice.** The two seedings are not the same — F6
      (`wezterm.lua:1038`) seeds four directories, the wallpaper (`:757`)
      seeds two. And the wallpaper's own stated reason is false as well: its
      comment claims `sh -lc` "won't find brew's magick/curl", yet under that
      same login shell `magick`/`convert` resolve to `/opt/homebrew/bin/`,
      `curl` to `/usr/bin/curl`, and `chezmoi` to `/opt/homebrew/bin/chezmoi`.
      That seeding is redundant outright. The fact lands in **this** entry,
      not the wallpaper entry: wallpaper is `DO NOT PORT`, so it changes no
      port decision, and the wallpaper entry's line 532 describes its code
      accurately while stating no reason — leave it alone.

**The correct mechanism was already written down one file away.** The analyst
found `~/.config/nushell/env.nu:15-19` recording `path_helper`, `/etc/paths`,
`/etc/paths.d/*`, and that it runs only from `/etc/zprofile` and
`/etc/profile` — then prepending exactly `~/.local/bin` and `~/.cargo/bin`,
the two directories `path_helper` never adds. So the inventory contradicted a
live comment in the same config tree. That is the cheapest possible check and
nobody ran it, which is the real lesson of this node.

## Acceptance
- [x] The corrected entry is quoted beside the `env -i … sh -lc` output that
      justifies it.
- [x] The R3 census is in the report: every PATH-resolution claim in the
      file, with the command run and its result.
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken **and its link
      count is unchanged at 691** — the replacement block adds no markdown
      link, so a moved count means something else was edited. Baseline
      measured at spec time: exit 0, `checked 691 links in 110 files, 0
      broken`. **Measured at implement time: exit 0, `checked 704 links in
      111 files, 0 broken`.** The 0 broken holds. The count moved because
      other lanes wrote the tree between spec and implement: Tier A read
      `700 links in 111 files` immediately *before* this edit and `704`
      after, and the four new links are not this entry's. This node's own
      delta is zero, measured by counting markdown links in
      `docs/capabilities-terminal.md` with the block in place and with the
      replaced 12 lines back: 7 either way.
- [x] Defects 2 and 3 are each quoted before and after, with the command
      that measured them — `cli list` for the surviving pane, and the
      `command -v` sweep for the wallpaper seeding's redundancy.

## Out of scope
- Editing `~/.config/wezterm/wezterm.lua`. The live config is read-only
  reference in this repo.
- The rebuild's own comment, which
  [`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md)
  spec01 owns and already carries the corrected reason.

## Orchestrator note on the link-count baseline, 2026-08-23

The acceptance box named an absolute Tier A count of 691, and by the time the
implementer ran, the tree read 700 before its edit and 704 after. I re-ran it
on the transition and got **713 links in 112 files, 0 broken, exit 0** —
higher again, minutes later.

That is three different "baselines" for one node, and none of them is wrong:
five lanes were writing the tree, and one of them also edited this same
inventory file. The implementer handled it correctly — it proved its **own**
delta is zero two ways (its 39-line block contains no markdown link, the 12
lines it replaced contained none, and counting links in
`capabilities-terminal.md` with and without the block gives 7 either way) and
recorded both readings rather than passing one off as 691.

**The lesson for the board, not just this node:** an absolute count measured
at spec time is stale before the implementer reads it. This is the second
node where that bit — `truncated-source-attributions`' box was rewritten from
an absolute 621→630 to a delta for the same reason. Acceptance boxes over
counts in a concurrently-written tree must assert a **delta**, measured as a
before/after pair in one session.
