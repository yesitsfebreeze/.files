---
state: done
claim: 
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Terminal (WezTerm)

Purpose: WezTerm is the daily driver, and its look, startup shape and
navigation speed set the tone for everything else. Every requirement in this
epic is specced from
[`capabilities-terminal.md`](../../docs/capabilities-terminal.md), which was
read live off the deployed config on 2026-08-20 after an audit found the
earlier terminal PRDs had been written from the legacy inventory and were
wrong on font, palette, keys and model. Only the rated keepers are taken over.

Goal: a WezTerm config that comes up fullscreen with nine addressable tabs,
inherits its palette from tinty without hardcoding a colour anywhere, and puts
tab addressing, copy mode and paste one keystroke away.

## Requirements

**Architecture invariants**

These are what make the pieces compose. Every child leans on them by
reference; none of them restates one.

**I1** — **REVERSED 2026-08-30. tmux owns tabs and panes; WezTerm owns
neither.** The original text made the self-healing nine-tab floor the
owner, with `TAB_COUNT = 9` a floor and a digit a stable address. That
was right about the hazard — two live key schemes is exactly what it
existed to prevent — and wrong about which program should be the one.
[`07-multiplexer`](../07-multiplexer/prd.md) is the reversal, carried by
[the memo](../memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md);
do not re-take that decision here. What binds now: WezTerm binds nothing
that addresses a tab or a pane, `enable_tab_bar = false`, and
`disable_default_key_bindings = true` — because WezTerm's own shipped
defaults bind ActivateTab and SplitVertical, so the invariant is false
out of the box without that line. The 2026-08-20 deletion of the
shell-side multiplexer still stands and is still `DO NOT PORT` in
[`README.md`](../README.md)'s exclusion list — what was deleted then was
a *second* multiplexer under a WezTerm that already was one, and that
reason survives the reversal intact. `tests/wezterm-appearance.sh`
--probe reads the loaded key table and asserts the absence.

**I2** — **tinty owns the palette. AMENDED 2026-08-30: WezTerm is no
longer its reader.** The first clause stands and is the important half:
`tinty apply` is the single funnel, nothing below the terminal hardcodes
a hex value, and no PRD in this epic names a scheme — the scheme is user
state that tinty rewrites. The second clause is gone. `tinty` no longer
writes `~/.config/wezterm/colors.lua`, WezTerm no longer `dofile`s it,
and the reload watch is deleted:
[`07-multiplexer/04-palette-delivery`](../07-multiplexer/04-palette-delivery/prd.md)
replaced that path with OSC 4/10/11/12 written straight to every attached
client's tty plus `~/.config/tmux/colors.conf` for tmux's own surfaces
(base02, the active window label's background, has no ANSI slot, which is
why a file is still needed at all). The reason the old clause gave was
sound and machine-specific: `config.colors` is WezTerm-wide, so one write
retints everything — on that emulator, on that desk. The new path retints
a terminal reached over ssh, which the old one never could. **The
`dofile`-never-`require` trap is not deleted knowledge** — `require`
caches by module name and would hand back the *first* palette on a second
apply — it is recorded in the memo as history, because no file in this
tree reads a lua palette any more. Finding T-3 and open decision 2
([`decisions/tinty`](../00-delivery/decisions/tinty/prd.md)) are
unaffected: they corrected who OWNS the palette, and tinty still does.

**I3** — **`PaneSelect` is forbidden, and the reason is the
requirement.** A key bound in `config.keys` or in a key table is
consumed in the raw-key pass before the modal ever sees it, while an
unbound key reaches the modal, which answers only to a complete label,
`Escape` and `ctrl+g` and silently eats everything else. Nothing in Lua
closes it: `cancel_modal` is reachable from no `KeyAssignment`, and
`PaneSelector::perform_assignment` returns false unconditionally
(checked in this build's source and in main). This invariant outlives
the pane-letter overlay that discovered it — it is what stops a later
lane "simplifying" one-key navigation back onto the modal.

**I4** — **The deployed `~/.config/wezterm/` is the artifact every
child is written against.** Decided 2026-08-21, open decision 4:
`chezmoi source-path` prints `/Users/feb/dev/.files/home`, and
`~/.local/share/chezmoi` is a stale June clone whose HEAD is a git
*ancestor* of that source. No terminal PRD may cite the stale clone as
the chezmoi source; the only permitted mention of it is as the clone
that produced wrong findings, labelled as such. Reading a clone instead
of the live tree is the failure class that invalidated this epic the
first time.

**I5** — **A WezTerm config check goes through `config_builder()` and reads
stderr; the exit code is not a predicate.** `wezterm.config_builder()`
installs a validating `__newindex` metamethod that refuses an unknown field
as it is assigned; a plain `return { ... }` table installs none and drops
unknown keys silently. The probe's **construction**, not the build, is what
decides whether a check can fail — and a probe that does not use
`config_builder()` is not testing what ships
(`home/dot_config/wezterm/wezterm.lua:12`). Measured 2026-08-28 on
`20240203-110809-5046fc22` at `ls-fonts --list-system`: a clean
`config_builder()` probe gives 791 stdout lines and 0 stderr bytes; the same
probe plus one bogus key gives 0 stdout lines and 350 stderr bytes carrying
`` `no_such_wezterm_field` is not a valid Config field ``. **Both exit 0** —
as do a wrong value type, a `--config-file` that does not exist, and the
whole set again with `config:set_strict_mode(true)`. Two constraints come
with it. `show-keys` is not an error channel at all: on a config that
`ls-fonts` rejects with 5 stderr lines, `show-keys --lua` exits 0 with 230
stdout lines and **zero** on stderr, so it serves only as a read-back
control. And the `__newindex` error is a Lua error that aborts the chunk, so
a probe carrying several bad fields reports only the **first** — one field
per probe. One consequence for anyone documenting a WezTerm check: the
`named` harvest reads `config.<field>` out of this epic's prose, so a document
quoting an invalid field name as an example is read as a claim — it turned the
gate red against the very paragraph describing its own red on 2026-08-28. A
line carrying the literal `NOT-A-FIELD` is exempt, per line and never per
file, and the gate's mutations deliberately do not carry it so its own red
still bites. This invariant was bought by a measurement that was filed wrong
and refuted the same day; the record is in
[`wezterm-probe-cannot-fail`](../00-delivery/corrections/wezterm-probe-cannot-fail/prd.md).

## Acceptance

All four run 2026-08-28 by the orchestrator, under
[`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
R4, which requires an epic's own acceptance to be verified before it
transitions. Two pass outright. The second was under-specified — it named a
command and no predicate — and now closes on a gate proven by its own red.
The first is the one still open, on a contract gap put to the user.

- [x] Every child's header cites an entry of
      [`capabilities-terminal.md`](../../docs/capabilities-terminal.md) by
      name, or `net-new`, with `C`/`U` numbers matching that entry.

      Seven children checked against the inventory's own trailing `- C` / `- U`
      pair. Six match exactly: `01-appearance` C5 U9, `02-startup-layout`
      C10 U7, `04-copy-mode` C4 U9, `06-launchd-path` C2 U10,
      `07-grid-centering` C8 U6, and `05-tab-content-state` is `net-new` and
      rated in its own header (C4 U7), which the rating rules permit.
      `03-f5-jump-mode` reads **C 6** against
      `docs/capabilities-terminal.md:475` reading **C 9**.

      **Ticked, unticked, and ticked again on 2026-08-28 — the third time on
      a rule rather than on an argument.** `03-f5-jump-mode` reads **C 6**
      against `docs/capabilities-terminal.md` reading **C 9**, because the
      2026-08-21 answer (digits only; the self-painted pane-letter overlay
      dropped) removed half of what that entry rated.

      The first tick rested on the divergence being well explained in the
      node. A skeptic rejected that: the line's predicate is "numbers matching
      that entry", they do not match, and a well-argued violation is still a
      violation — the same move this epic had correctly refused one box below.
      So it was unticked, and the gap put to the user, because the gap was in
      the contract: `AGENTS.md` had a rule for a PRD that *merges* several
      inventory entries and none for one that *splits* one.

      The user added the split-entry rule on 2026-08-28. It permits diverging
      numbers on three conditions — a rating note naming the decision, a
      statement of which number moved and which did not, and **the inventory
      entry updated to point at the split**. All three now hold: the node's
      `**Rating note.**` carries the first two, and the entry carries a
      `**Split by decision, 2026-08-21 (user).**` paragraph naming the node,
      the withdrawn `SIMPLIFY` marker and why its own numbers stay put. The
      box ticks on the rule being satisfied, not on the reasoning being good.

      That third condition also closed a real drift found in the same pass:
      the rating note claimed the `SIMPLIFY` marker was "withdrawn" and
      nothing in the inventory recorded it, so a reader arriving from the
      inventory saw `SIMPLIFY` and `C 9` with only the node knowing otherwise.
      It is recorded there now.

- [x] No child names, and the shipped `wezterm.lua` does not set, a WezTerm
      config field the installed build rejects at config-load time. The
      check is `bash gates/wezterm-config-fields.sh`: probes built with
      `wezterm.config_builder()` — because that is what ships — driven
      through `wezterm --config-file <probe> ls-fonts --list-system`, with
      the verdict read off **empty stderr and non-empty stdout**. The exit
      code is not a predicate and the gate never reads it; see **I5**.

      Run 2026-08-28 on `wezterm 20240203-110809-5046fc22`: rc 0, 7 PASS /
      0 FAIL. Sixteen `config.<field>` names harvested from the children,
      none rejected; the shipped `wezterm.lua` loads with 0 stderr bytes,
      which validates all 31 of its own `config.<field>` assignments in that
      one load because it uses `config_builder()` at line 12. The two sets
      union to 30 distinct fields and nothing in either is rejected.

      Proven by its own red, per `G.1`.
      `bash gates/wezterm-config-fields.sh --selftest` appends
      `config.no_such_wezterm_field = true` to a `scratch_tree` copy of  NOT-A-FIELD
      `wezterm.lua`, and writes `config.not_a_real_wezterm_field` into a  NOT-A-FIELD
      copied child. Each turns the gate rc 1, naming the field, with
      ``ERROR … `is not a valid Config field` `` on stderr; removing the one
      line restores rc 0. The same run shows the superseded plain-table
      probe **green** on the identical violation, so the difference between
      the two probe constructions stays on the record instead of in a
      memory.

      The line this replaces named the command without a predicate, and the
      obvious predicate — the exit status — discriminates nothing. Filed and
      corrected as
      [`wezterm-probe-cannot-fail`](../00-delivery/corrections/wezterm-probe-cannot-fail/prd.md),
      whose own first filing was wrong and is kept there as the record.

- [x] The child count agrees in three places: the directories under this
      epic, the tree in [`README.md`](../README.md), and README's build
      order.

      Seven in all three: seven directories `01-`–`07-`; seven rows under
      `02-terminal/` in the README tree; and seven `T.` ids in README's build
      order — T.1, T.2, T.3, T.4, T.6, T.7, T.8, matching the children's
      `task:` fields exactly (there is no T.5).

- [x] No file under this epic hardcodes a palette hex or names a colour
      scheme, the single exception being the no-theme-picked fallback
      recorded in [`01-appearance`](01-appearance/prd.md).

      One hex under the epic — `"#1d2021"` in
      `01-appearance/specs/spec01-wezterm-lua.md:81` — and it appears as
      **"Do not port that hex"**, a negative reference, not a hardcode. The
      only named scheme is `Gruvbox dark, hard (base16)`, which is the
      no-theme-picked fallback this line names as its exception, recorded in
      `01-appearance` R3.

## Out of scope

Non-goals, each with the reason it is refused and the rating it was refused
at. The canonical list is [`README.md`](../README.md)'s exclusion section;
this is the terminal-local view of it.

- **The `Ctrl+Shift+B` wallpaper pipeline** (`DO NOT PORT`, C 8 / U 3) — a
  terminal keybinding that reaches out and rewrites the OS desktop wallpaper
  *and* a chezmoi source tree, depends on ImageMagick, and is cosmetic. The
  key itself is freed and goes to `capsule --rebuild`.
- **`background.png`** (C 2 / U 0) — a 2.8 MB output artifact sitting in a
  config directory that nothing in `wezterm.lua` reads. Drops out with the
  pipeline above.
- **The OSC-1337 background-transparency user-var** — the live rebuild of the
  legacy opacity toggle. Both are refused by
  [`decisions/wallpaper-opacity`](../00-delivery/decisions/wallpaper-opacity/prd.md)
  (2026-08-21).
- **The dead `config.lua`** (`DO NOT PORT`, C 1 / U 1) — 23 lines next to
  `wezterm.lua`, never loaded, not valid Lua, and unmanaged by chezmoi. Its
  whole danger is as a decoy: it asserts a font and a colorscheme a reader
  would plausibly believe. Delete rather than port.
- **`wsl-clip-prime.sh`** (`DO NOT PORT`, C 4 / U 0) — orphaned binding,
  WSL-only, against a macOS-host-only scope decision.
- **The four `solo-window.*` scripts** (`DO NOT PORT`, C 5 / U 0) — deployed
  dead code; the `ctrl+shift+m` binding each of them names does not exist.
- Legacy surfaces already refused before this re-spec: the three-pane split
  layout, the quake-style dropdown pane, the container-aware status bar, and
  **background image cycling** with its opacity toggle. Finding **T-11** is
  why the last of those is spelled out here: this line once refused only the
  *legacy* implementations while the live config had rebuilt both ideas in new
  form, and an unrefused rebuild is how an excluded capability walks back in.

The carve-out that keeps being mistaken for one of the above: **none of this
touches the static `window_background_opacity`, its base00 tint, or
`macos_window_background_blur`.** Those are the *Appearance baseline* entry
(C 2 / U 7, take over as-is) and belong to
[`01-appearance`](01-appearance/prd.md). The wallpaper decision covers the
pipeline and the user-var toggle only, and owes this epic no further answer.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.

## Closed 2026-08-28 — all four acceptance boxes run, two of them twice

Transitioned by the orchestrator under
[`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
R4, which requires an epic's own acceptance to be verified before it
transitions. All seven children were already `done`; what held this epic was
its own four boxes, and this is the round that ran them.

Two closed on the first reading — the three-place child count, and the
no-hardcoded-palette rule. The other two each closed on a second pass after
the first was wrong, and both failures are worth keeping:

- **The config-field probe** was reported as a check that *could not fail*.
  That was a false measurement, made with a bare `return { ... }` probe table
  and refuted the same day: `wezterm.config_builder()` — which is what ships —
  does reject an unknown field. The box now closes on
  `gates/wezterm-config-fields.sh`, a gate proven by its own red, and **I5**
  records the constraint so nobody re-derives it. See
  [`wezterm-probe-cannot-fail`](../00-delivery/corrections/wezterm-probe-cannot-fail/prd.md).
- **The child-rating box** was ticked on a well-argued divergence, then
  unticked, because a well-argued violation is still a violation. The gap was
  in the contract rather than in the node, and the user closed it with the
  split-entry rating rule on 2026-08-28. It ticks on that rule now.

`verify:` runs the epic's own claim — every child `done` — and then the gate
that closes its second box. Both were run at transition.
