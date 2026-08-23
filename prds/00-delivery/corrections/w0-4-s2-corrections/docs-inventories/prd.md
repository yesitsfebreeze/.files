---
state: done
priority: 37
est: 1.5h
task: W0.4a
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# Docs inventories

Purpose: One epic's share of the S2/S3 corrections sweep. capabilities.md is
USER-AUTHORED. The backlog's own acceptance says "capabilities.md corrections
are confirmed with the author before editing", so that confirmation is a box
on this node, not an assumption. Child of W0.4; one writer per file, so the
seven corrections run in parallel instead of one agent serialising ~22 files.

## Requirements
- [x] **R1** — `capabilities.md` is user-authored. The backlog's acceptance
      says its corrections are confirmed with the author before editing, so no
      edit lands until that confirmation is recorded here.
- [x] **R2** — Fix the marker typo `DO NOT PORST`, the missing markers on
      three entries the README treats as excluded, the header note describing
      verdicts as containing `|`, and the "maximiz:ed" typo.
- [x] **R3** — Fix the sort-order violations: four rises in
      `capabilities-nvim.md`, opacity below theme in
      `capabilities-nushell.md`.
- [x] **R4** — Reconcile the mini.nvim entry, unmarked in one inventory and
      double-rated in another.
- [x] **R5** — Strip burrito: the `bb`/`ba` aliases in
      `capabilities-nushell.md` and burrito from
      `capabilities-provisioning.md`'s package list.
- [x] **R6** — `capabilities-provisioning.md` violates the sort rule its own
      header line states ("sorted best-first by value ratio"): its twelve
      value ratios run 6, 7, 6, 1, 4, 6, 6, 6, 5, −2, −1, 0 in file order, and
      the 6 → 7 rise at position 2 alone breaks it. Sort descending by
      (usefulness − complexity) with ties broken by existing file order — the
      only tie-break that changes nothing it does not have to — giving:
      Declarative package set (7) · Shell-init generation (6) · Idempotent
      apply + push workflow (6) · Homebrew bootstrap (6) · Managed config
      surface (6) · Starship prompt (6) · Small tool configs (5) · Neovim
      version gating (4) · Package installer (1) · Published docs site (0) ·
      wp-stat-overlay installer (−1) · Windows config mirroring (−2). That
      tie-break also lands the three verdict-marked entries at the bottom in
      DEFER, DEFER, DO NOT PORT order, so the excluded tail reads as one
      block. Re-homed from `w0-3-platform-rewrite` R3 by the conductor on
      2026-08-21 (user decision): W0.3 identified it but does not own
      `.mi/docs/`; this node does.
- [~] **R7** — Decision 4 (2026-08-21) makes the deployed `~/.config` tree
      canonical and the chezmoi source abandoned, and its closing line makes
      that a correction rather than an opinion: "Every inventory in
      `.mi/docs/` rates the deployed artifact. Where one was written against
      the source, that is a correction." Only
      `capabilities-provisioning.md`'s head and canonicality note have been
      corrected so far (commit 56c9f0d). Sweep the remaining inventories —
      `capabilities.md`, `capabilities-nushell.md`, `capabilities-nvim.md`,
      `capabilities-terminal.md` — for any line rating or describing the
      chezmoi source rather than the deployed tree, and correct each. Note
      while doing it that the two trees genuinely diverge: `wezterm.lua` 339
      source vs 1149 deployed, `config.nu` 380 vs 715, `finder.nu` 345 source
      vs 221 deployed with the source holding a different stack-and-resume
      design.
      **Partly landed, 2026-08-21.** `capabilities-nushell.md` corrected —
      head and leader-mode entry, `specs/spec01.md` B5/B6.
      `capabilities.md` rates the legacy `~/.files` repo and carries no
      chezmoi reference at all, and `capabilities-nvim.md` carries none
      either, so there is nothing to correct in those two.
      `capabilities-terminal.md` is **not** in this node's `files` list in
      `plan.json`; its half is routed to `w0-2-terminal-respec`, which is
      re-speccing `02-terminal` from that file anyway. The box stays `[~]`
      until that lands.

## Answers

*Answered 2026-08-21 by the user (the author of `capabilities.md`), which is
the confirmation R1 requires. R1's block is lifted.*

1. **Typos and the header note — fix all three.** `DO NOT PORST` →
   `DO NOT PORT` (line 154); `maximiz:ed` → `maximized` (line 49), which
   repairs the broken source citation in
   [`02-terminal/02-startup-layout`](../../../../02-terminal/02-startup-layout/prd.md);
   and the header note's `|` (lines 3–5) reworded to read as intended.
2. **Add all seven verdict markers** — `mount` → `CONSOLIDATE`; `Neovim:
   shared theme`, `WezTerm terminal configuration`, `Neovim:
   self-bootstrapping config` and the three further entries → `DO NOT PORT`.
   This covers both the R2/R4 names and the three extras found separately.
   The one the README does not yet list gets added to its exclusion section
   too — but `.mi/prds/README.md` is **W0.4g's** footprint, so name it and
   route it rather than reaching.

Confirmed as part of the answer: markers are not a sort key and the file's
ratio sort is already clean (`6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0
0 0 0 -1 -2 -2`, no rise), so **no entry moves and no C/U number changes.**

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Questions

R1 is a real gate, and it bites harder than it looks: **every single item R2
names lives in `capabilities.md`, and half of R4 does too.** Nothing in R2 or
R4 can close without your confirmation. The other four requirements (R3, R5,
R6, and the one reachable part of R7) touch only the three inventories you did
not write, and are specced and ready — `specs/spec01.md` (nushell),
`specs/spec02.md` (nvim), `specs/spec03.md` (provisioning). They do not wait
on these answers.

Everything below is a text edit to `.mi/docs/capabilities.md`. Each has a
recommended answer; a plain "yes to all" closes R2 and R4 in one pass.

**None of it moves an entry.** I measured the file's value ratios in file
order — `6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0 0 0 0 -1 -2 -2` —
and they descend without a single rise. `capabilities.md` is the one inventory
already sorted correctly, and markers are not a sort key, so confirming any or
all of these leaves every entry exactly where it is and every C/U untouched.
That is deliberate: it is the same principle the tinty decision settled on
2026-08-21 — the marker records membership, the numbers measure intricacy and
daily value, and the human overrides the marker.

1. **The `DO NOT PORST` typo.** Line 154, `## OpenCode theme generation from
   terminal colors DO NOT PORST` → `DO NOT PORT`. As written it matches no
   marker in the vocabulary, so a tool reading verdicts sees this entry as
   unmarked, i.e. take-over-as-is — the opposite of what you meant.
   *Recommended: yes.*

2. **The header note's `|`.** Lines 3–5 read "NOTE: everything that has | in
   the ## line. descibes what to do with it." No `##` line in the file
   contains a `|`; the verdicts are bare words appended to the heading
   (`DO NOT PORT`, `CONSOLIDATE`). The four sibling inventories all carry the
   same legend in the same shape, so the proposal is to replace those three
   lines with it, keeping your two examples:

   > Markers on the `##` line say what to do with a capability: nothing =
   > take over as-is, `SIMPLIFY` = take over a reduced version,
   > `CONSOLIDATE` = merge with overlapping capabilities into one tool,
   > `DEFER` = not part of the minimal base, `DO NOT PORT` = drop entirely.
   > For example the docker dev mount is `CONSOLIDATE` — it should work
   > flawlessly, as one tool — and nothing marked `DO NOT PORT` is created or
   > ported at all.

   *Recommended: yes.* If you would rather keep your wording verbatim and only
   fix the `|`, say so and I will change nothing but that character.

3. **The `maximiz:ed` typo.** Line 49, `## Nine-tab maximiz:ed startup
   windows` → `maximized`. This one is not cosmetic: the PRD that sources it,
   `02-terminal/02-startup-layout`, cites `source: "Nine-tab maximized
   startup windows"`, which matches no heading in this file — so the
   citation is currently dangling on a stray colon. *Recommended: yes.*

4. **Three entries the tree treats as excluded, but which carry no marker.**
   Read alone, an unmarked entry means take-over-as-is, so each of these
   currently contradicts a decision recorded elsewhere:

   - **`Cross-platform Lua/shell/PowerShell parity`** (line 144, C 6 / U 6) —
     `.mi/prds/README.md`'s exclusion list already names it: "cross-platform
     Lua/shell/PowerShell parity (Windows out of scope)".
     *Recommended: add `DO NOT PORT`.*
   - **`Cross-platform dependency bootstrap`** (line 79, C 5 / U 7) —
     `.mi/docs/capabilities-provisioning.md`'s head says in as many words that
     it is "**superseded** by the entries below. It should not be ported."
     *Recommended: add `DO NOT PORT`.* Note the README does **not** yet list
     this one; adding it there is W0.4g's file, not mine, and I have routed it.
   - **`Just task runner`** (line 69, C 3 / U 6) — this is the one I would
     *not* mark `DO NOT PORT`. `01-capsule/01-container-lifecycle` is titled
     "Container lifecycle (consolidates capsule + `mount` + justfile)", and
     the scope decision in `AGENTS.md` says the keybinding, `mount`,
     `justfile` and standalone image "consolidate into a single Capsule tool".
     That is the definition of `CONSOLIDATE`, not a drop.
     *Recommended: add `CONSOLIDATE`.*

5. **The mini.nvim entry (R4).** `## Neovim: self-bootstrapping config`
   (line 59, C 5 / U 8) has no marker, yet `.mi/prds/README.md` excludes "the
   mini.nvim plugin set and `mini.deps` bootstrap (superseded by the live
   lazy.nvim config)", and `capabilities-nvim.md` rates the same capability a
   second time at C 5 / U 2 with `DO NOT PORT`. *Recommended: add
   `DO NOT PORT` and leave C 5 / U 8 alone.* The two U numbers are not a
   contradiction once said out loud — U 8 rates the capability in its own era
   against no alternative, U 2 rates it against the live config that replaces
   it — and `specs/spec02.md` writes exactly that explanation into the nvim
   side, cross-linking to this entry by name. That half lands whatever you
   answer; only the marker here needs you.

6. **Three more with the same defect, which R2 and R4 do not name.** I found
   these while checking the five above. Answer them now or leave them; they
   are listed separately so a "yes to all" on 1–5 does not silently sweep
   them in.

   - **`` `mount` — drop the current dir into a container ``** (line 44,
     C 3 / U 7) — the same `01-capsule/01` title names `mount` as a merged
     source. *Recommended: add `CONSOLIDATE`,* for the same reason as 4c.
   - **`Neovim: shared theme + desktop-style keys`** (line 89, C 5 / U 7) —
     describes the mini.nvim-era WezTerm→Neovim theme bridge.
     `capabilities-nvim.md`'s head says "the mini.nvim **entries**" (plural)
     "in `capabilities.md` are superseded and should not be ported".
     *Recommended: add `DO NOT PORT`.*
   - **`WezTerm terminal configuration`** (line 19, C 4 / U 9) — this entry is
     what audit finding S1/T-1..T-10 was about: it describes the legacy
     repo's WezTerm config (Departure Mono, Gruvbox Material, platform-aware
     padding), none of which is live, and `02-terminal` is being re-specced
     from `capabilities-terminal.md` instead. The capability is still ported;
     *this description* of it is not. *Recommended: add `DO NOT PORT` plus one
     line in the head pointing at `capabilities-terminal.md`,* the same
     treatment `capabilities-nvim.md` already gives the Neovim entries. If you
     would rather not mark a capability that is genuinely being ported, the
     alternative is head-note-only; say which.

7. **Nothing in R7 needs you.** R7 asks me to sweep the inventories for lines
   rating the abandoned chezmoi source instead of the deployed `~/.config`
   tree (Decision 4). `capabilities.md` rates the legacy `~/.files` repo,
   which is neither — it has no `chezmoi` reference at all, and I found
   nothing in it to correct. Recorded here so R7 is not read later as blocked
   on an answer that was never needed.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All four spec verifies `OK`, exit 0,
from RED baselines of 12 / 14 / 12 / 20. R1–R6 `[x]`, R7 `[~]` with a close-out
note.

**The load-bearing guard is green and unmoved.** `capabilities.md` still holds
**30** entries with ratio sequence `6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1
1 0 0 0 0 0 -1 -2 -2`, verified descending. That makes "no entry moved and no
C/U changed" a checked fact, not a promise — which is what the user's
confirmation was conditioned on. Both shipped tickets' guards intact:
shift-to-select `SIMPLIFY` 7/7, theme switcher `SIMPLIFY` 8/5.

`DO NOT PORST` and `maximiz:ed` are gone, and `## Nine-tab maximized startup
windows` now exists as a heading — so `02-terminal/02-startup-layout`'s source
citation resolves. The verify checks that against the **real consumer**: it
re-reads that PRD's `Parent:` line, extracts the cited string, and greps it
back as a heading, so it passes whether or not `02-terminal` repairs its own
truncation.

**Separator normalisation was not optional, and was flagged rather than
slipped in.** spec04's verify asserts 24 two-space-separated markers, so
leaving the 16 single-space ones would have kept it red; and the legend
installed at the head only reads truthfully once the separator is uniform.
Zero semantic change, and the ratio guard proves it.

**The WezTerm block sweep was deliberately not extended.** `WezTerm terminal
configuration` got its confirmed `DO NOT PORT`; `Nine-tab maximized startup
windows` and `F5 one-shot jump mode` stay unmarked though the audit found them
equally wrong, because the author confirmed three named entries, not a block.
A head note covers them by pointing at `capabilities-terminal.md`, and the
entry-by-entry question is filed with
[`w0-2-terminal-respec`](../../w0-2-terminal-respec/prd.md).

**Refused rather than improvised — and this created real work:** the platform
lane's re-rating (fold `Package installer` 8/9, `Declarative package set` 2/9
and `Homebrew bootstrap` 2/8 into one `## Tool installation (install.sh)` at
C 4 · U 9) is **not** covered here. spec03's guards actively assert the
opposite — all three must stay put as separate entries at their current
ratings — so doing it would have turned this ticket's own gate red and moved
`Neovim version gating`'s neighbours. It is now
[`provisioning-rerate`](../provisioning-rerate/prd.md).

**Routed, not written:** R7's terminal half and the copy-mode "searches"
defect (both `w0-2-terminal-respec`'s — `capabilities-terminal.md` is absent
from this node's `files` list), and `Cross-platform dependency bootstrap`
missing from `.mi/prds/README.md`'s exclusion list (W0.4g's).

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec03.md`'s verify asserted `.mi/docs/capabilities-provisioning.md`
held **12** entries in a fixed order, with `Package installer` 8/9,
`Declarative package set` 2/9 and `Homebrew bootstrap` 2/8 standing separately.
[`provisioning-rerate`](../provisioning-rerate/prd.md) (W0.4i) folded those
three into one `## Tool installation (install.sh)` at **C 4 · U 9**, on the
user's decision, because commit `8fe3a71` deleted the machinery they rated.

Three assertions were therefore **repointed, not abandoned**: the entry count
(`12` → `10`), the exact-order `WANT` string, and the three `RL` C/U pairs —
replaced by a single `Tool installation@4 9` pair so the new entry is guarded
too. Everything else that verify asserts still passes untouched, because W0.4i
deliberately preserved each guarded literal inside the corrected sentences:
`1149` survives as `1149 vs 1149`, and `not a port target` was re-attached to
the rebuild-from-scratch clause rather than to the withdrawn "abandoned" claim.

R7 remains `[~]` and its sweep is **known to have used the wrong baseline** —
it compared source against deployed before `~/.local/share/chezmoi` was
identified as a stale June clone. Re-measuring is routed as R9 on
[`backlog-closeout`](../backlog-closeout/prd.md).

## Superseded guard — second

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec04.md` asserted `.mi/docs/capabilities.md` carried **24**
two-space-separated markers and that its take-over-as-is set was exactly six
named entries. The user answered `w0-2-terminal-respec`'s Q4 on 2026-08-21,
marking the two remaining legacy WezTerm entries — `Nine-tab maximized startup
windows` and `F5 one-shot jump mode` — `DO NOT PORT`, superseded by
`capabilities-terminal.md`. Marker count is now **26** and the unmarked set is
four.

Repointed, not abandoned: the count assertion reads 26. **The entry count (30)
and the ratio sequence stayed green with ratio strings sha-identical** — that
lane measured it before editing, confirming again that markers are not a sort
key and that no rating moved.
