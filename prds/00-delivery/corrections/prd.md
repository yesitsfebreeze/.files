---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
origin: derived
---

# Corrections backlog

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Findings from the four-agent audit of 2026-08-20, which checked every
PRD and inventory against the live configs. These are Wave 0: they change what
later tasks build, so they land before implementation starts. Severity: **S1**
invalidates a PRD or a scope decision · **S2** a factual error to correct ·
**S3** cosmetic. `[x]` = already fixed in this pass.

## Acceptance
- [x] Every S1 item is either fixed or converted into a task in
      [`01-work-breakdown`](../work-breakdown/prd.md) before Wave 1 starts.
- [ ] The three open decisions have a recorded answer, in this file, with a
      date.
- [ ] No S2 "live bug" is reproduced in the rebuild; each is either fixed or
      documented as accepted-with-reason.
- [ ] `capabilities.md` corrections are confirmed with the author before
      editing.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## How a census records a verdict

A census audits recorded reasons. Its own verdicts follow three rules.

**One of three words.** `reproduced`, `refuted`, `unmeasured`. Never
`exact`, and never `the last carrier`. "Exact" is a claim about a mechanism
and one run cannot support it. "The last carrier" is a claim about a whole
tree and one grep cannot support it.

**The fixture goes beside the verdict.** For a mechanism claim, the inputs
the run used — `reproduced (2 empty dirs, guard off, try off, no winsize)`.
For a coverage claim, the search predicate — `refuted (one-dimension grep
over every board prd.md)`. One parenthesis, and it is what makes two
verdicts on one claim comparable.

**A cheap claim is run twice, with a different input.** Under a minute per
run means two runs. A claim that survives the first and dies on the second
was never a finding.

Four steps, which are the reason these rules exist.
`home/dot_config/nushell/config.nu:381-385` says `la | print` HANGS at 0
columns. [`pwd-closure-blast-radius`](pwd-closure-blast-radius/prd.md) ran it
in empty scratch directories, saw a hang, and wrote "That bullet is exact. Do
not touch it."
[`stale-pwd-latch-carriers`](stale-pwd-latch-carriers/prd.md) ran it in a
one-entry and a 200-entry directory, saw one message per fire, and refuted
it. [`autolist-width-guard-reason`](autolist-width-guard-reason/prd.md) varied
the directory and found both right about their own fixture: a non-empty
directory prints a message, an empty one spins the shell at 100% CPU. The
discriminator cost two `touch`es. Nobody was careless — both measured
honestly, recorded a conclusion, and omitted the fixture.

**These rules catch nothing on their own.** Eight wrong reasons have been
found on this board, and every one was found by someone running the claim or
by someone widening a grep, never by a word. "Trust the gate over the
comment" is not the lesson either: `tests/shell-listing.sh:158-166` described
the non-empty case and never reached the empty one. What the first two rules
buy is legibility one analyst earlier — with the fixture in the record, the
next verdict's different fixture contradicts it in writing. Only the third
rule catches anything, and it catches because it is a run.

Three verdicts already written, re-expressed:

| as written | under these rules |
|---|---|
| `pwd-closure-blast-radius` spec01, M7 — "That bullet is exact. Do not touch it." | `reproduced (2 empty scratch dirs, width guard off, try off, no winsize)`. The next node's `refuted (1-entry and 200-entry dirs)` then disagrees with it on the fixture, in the record, and no third run is needed |
| `stale-pwd-latch-carriers` R2, item 2 — "DOES NOT REPRODUCE" | `refuted (1-entry and 200-entry dirs, 0 columns, try on and off)`. Rule three forces a second input, the empty directory is that input, and the verdict lands as `reproduced (empty) · refuted (non-empty)` inside one node |
| `terminal-inventory-path-claim` R4 — "this inventory is the last carrier" | `refuted (single-dimension grep, prds and docs)`. [`gui-dies-claim-carriers`](gui-dies-claim-carriers/prd.md) found five more carriers with a three-dimensional grep, and [`truncated-source-attributions`](truncated-source-attributions/prd.md) turned seven into nine the same way |

Gating this vocabulary belongs to
[`retired-phrase-sweep`](retired-phrase-sweep/prd.md), and the paragraph above
applies to it: a phrase gate over this section must allow the wordings quoted
here in order to retire them.

## S1 — the terminal epic is specced from the wrong config

`02-terminal/*` was written from `capabilities.md` and never checked against
the live `~/.config/wezterm/`. Nearly every requirement is wrong, and the live
config is a substantially more sophisticated thing. **Treat all of
`02-terminal` as invalid until re-specced (task W0.2).**

| # | Owner — who carries it | Finding |
|---|---|---|
| T-1 | `w0-2-terminal-respec` R3 — **open** | Font is **CaskaydiaCove Nerd Font** (installed, with `font_dirs` → `~/Library/Fonts`), not in-repo Departure Mono — that is legacy-only. |
| T-2 | `w0-2-terminal-respec` R1 — **open**. Palette *ownership* is settled by decision 2; the font/palette re-spec is not. | Palette is **not** Gruvbox Material. `wezterm.lua` `dofile`s a tinty-generated `colors.lua` (currently `base16-everforest-dark-hard`); the base16 gruvbox scheme is only a fallback. No green cursor override; style is `BlinkingBlock`. |
| T-3 | `00-delivery/decisions/tinty` — resolved; see the Finding cell | **Palette ownership is inverted.** WezTerm *reads* what `tinty apply` writes, and F6 delegates the switch to nushell's `theme.nu`. Tinty is the source of truth — yet the theme switcher is `DEFER`red, so the palette source is currently out of the minimal base. **Resolved 2026-08-21 (D.1b): tinty stays and owns the palette — see open decision 2.** |
| T-4 | `w0-2-terminal-respec` R5 — **open** | Padding is zeroed and recomputed every tick by `center_grid` to center the cell grid. There is no platform-aware padding. |
| T-5 | `w0-2-terminal-respec` R3 — **open** | `gui-attached` does not exist; startup calls `toggle_fullscreen()`, not `maximize()`. |
| T-6 | `w0-2-terminal-respec` R5 — **open** | Quit passes `confirm = false` explicitly, and must `mark_closing()` first to defeat the tab-refill floor. |
| T-7 | `w0-2-terminal-respec` R3 — **open** | **No `Cmd+N` binding exists.** New windows get nine tabs from a reconciler on `window-config-reloaded`. |
| T-8 | `w0-2-terminal-respec` R3 — **open** | F5 pane letters are `asdfghjkl` indexing `tab:panes()` in **split-creation order, not geometry**. `b` is bound but maps to nothing and rings the bell. Both the letter set and the ordering in the PRD are wrong. |
| T-9 | `w0-2-terminal-respec` R5 — **open** | The "JUMP" status hint was **deliberately removed** as noise; discoverability is a reverse-video letter painted into each pane. Right status is clock-only. |
| T-10 | `w0-2-terminal-respec` R5 — **open** | Uncovered live features, ~230 lines of the most intricate code in the config: the **self-healing nine-tab floor** (per-window slot maps, `MoveTab` re-positioning, re-entrancy guard, 5 s heal tick), **dynamic grid centering**, **copy mode** (`Ctrl+Shift+X` + single-key toggle + OSC user-var), `Ctrl+V` bracketed paste / `Ctrl+C` copy-or-SIGINT, mouse bindings (`StartWindowDrag` is the only window handle under `RESIZE`), and the launchd-PATH seeding without which a GUI launch never reaches nushell — measured, the pane is created and **kept**, holding `No viable candidates found in PATH` and then `didn't exit cleanly`, because neither config sets `exit_behavior` and the default `CloseOnCleanExit` retains an uncleanly-exited pane; the window does not die, and `02-terminal/06-launchd-path` R3 holds the measurement. |
| T-11 | `00-delivery/decisions/wallpaper-opacity` — closed; see the Finding cell | The epic's Non-goals list "background image cycling" and "opacity toggle" as never-port, but both exist live in new form (`Ctrl+Shift+B` sets a blurred desktop wallpaper; opacity via OSC-1337 user var over `window_background_opacity = 0.95`). **Closed 2026-08-21 — converted to a decision and answered: both features are dropped on the record.** See open decision 5 below and [`decisions/wallpaper-opacity`](../decisions/wallpaper-opacity/prd.md). |


## S1 — capsule collides with live bindings and rests on broken code

| # | Owner — who carries it | Finding |
|---|---|---|
| C-1 | `w0-5-capsule-rebase` R2 — landed. The `Ctrl+Shift+B` half was dissolved by decision 5(c); the `Ctrl+Shift+T` half by rekey. | **`Ctrl+Shift+B` is already the wallpaper prompt** and `Ctrl+Shift+T` is WezTerm's default SpawnTab (which the tab reconciler treats as the manual new-tab path). The capsule PRDs claim both. Pick new bindings. **Fixed 2026-08-22** — `w0-5-capsule-rebase` R2. `SpawnTab` keeps `Ctrl+Shift+T` and the recents new-tab variant is `Ctrl+Shift+O` (`01-capsule/04` R2; decision recorded there). |
| C-2 | `w0-5-capsule-rebase` R1 — landed | **No live capsule implementation exists** — no `~/docker`, no Dockerfile or capsule script in `~/.config`. The five "existing pieces" the epic consolidates live only in the undeployed legacy repo. The epic's framing ("consolidate what exists") should become "build once, informed by the legacy attempt". **Fixed 2026-08-22** — `w0-5-capsule-rebase` R1; the epic purpose now reads build-once, informed by the legacy attempt, and `01-capsule/01` is retitled off "consolidates". |
| C-3 | `w0-4-s2-corrections/capsule` R1 (landed); the epic-level rebase is `w0-5-capsule-rebase` R3 | **Legacy `mount` never worked.** It `cd`s to a non-existent `~/docker`, calls `just run "$PWD"` where the recipe takes zero parameters, and that recipe mounts `./workspace` rather than the current directory. Do not preserve its semantics — design them. **Fixed 2026-08-21** — `w0-4-s2-corrections/capsule` R1 re-specced `01-capsule/01-container-lifecycle` to design the semantics rather than preserve them. Residue, named rather than assumed away: the epic's "consolidate what exists" framing is `w0-5-capsule-rebase` R3. **Residue landed 2026-08-22** — the epic is re-based (`w0-5-capsule-rebase` R1/R3). |
| C-4 | `w0-5-capsule-rebase` R4 — landed | **`devzsh` has no zsh** (image installs none; `CMD ["bash"]`), so zsh/oh-my-zsh comes only from the capsule image. `01-capsule/02` mis-attributes it. Claude Code is likewise only in the capsule image, not the standalone one. **Fixed 2026-08-22** — `w0-5-capsule-rebase` R4; `01-capsule/02` attributes zsh, oh-my-zsh and Claude Code to the capsule image and its `Parent:` source list is restored. |
| C-5 | `01-capsule/04-recent-workspaces` via `w0-5-capsule-rebase` — landed | The "Recent:" status indicator required by `01-capsule/04` has no host: the live status bar is clock-only and `set_left_status` is never called. **Fixed 2026-08-22** — `w0-5-capsule-rebase` via `01-capsule/04` R3: the picker surface announces the mode; the status bar stays clock-only. |


## S1 — open decisions for the human

These are scope forks an agent must not resolve alone:

1. **burrito vs the nine-tab floor.** The live WezTerm config states "burrito
   owns multiplexing, so there's a single tab", yet also implements a
   self-healing nine-tab floor. These are two competing models of the same
   surface, and the terminal epic is built on the tab one. burrito
   (`~/.cargo/bin/burrito`, config at `~/.config/burrito/`) appears in the PRD
   tree only as the `bb`/`ba` aliases.
   **Answered 2026-08-21: WezTerm owns tabs and panes.** Not a fresh call and
   not this node's — it was settled on 2026-08-20, when burrito took
   `DO NOT PORT` in [`README.md`](../../README.md)'s exclusion list. This
   entry records the answer where the question was asked, which is the only
   thing that was missing.

   What the answer settles:
   - (a) **The self-healing nine-tab floor is the model.** With burrito
     excluded there is no second multiplexer, so the two competing models
     collapse to one.
     [`w0-2-terminal-respec`](w0-2-terminal-respec/prd.md) R2 already carries
     the consequence — "burrito is deleted … remove every burrito reference
     from the epic" — and T-6, T-7 and T-10 are specced against the floor,
     not against a single-tab surface.
   - (b) **The `bb`/`ba` aliases go with it**, and they never called burrito
     anyway: they invoke `brr` (M-7). `w0-4-s2-corrections/shell` R4 and
     `w0-4-s2-corrections/platform` R1/R2 stripped burrito from the shell and
     platform epics on 2026-08-21.
   - (c) **Nothing downstream is reopened.** How much of the ~230 uncovered
     lines the floor keeps is `w0-2-terminal-respec` R5's question, not this
     item's.
2. **Does tinty stay?**
   **Decided 2026-08-21 (user): tinty stays as palette owner, and the
   `DEFER` "cosmetic" verdict on it is withdrawn.** It is
   infrastructure, not decoration. Recorded from
   [`00-delivery/decisions/tinty`](../decisions/tinty/prd.md), where the fork
   was put to the human.

   What the decision settles:
   - (a) **The chain, top to bottom.** `tinty apply` writes both
     `~/.config/wezterm/colors.lua` and its cached tinted-shell artifact.
     WezTerm `dofile`s the former (never `require`, which caches by module
     name and would return the *first* palette on a second apply) and
     re-tints every window, tab and pane, because `config.colors` is
     WezTerm-wide. `config.nu` sources the latter so a new shell re-asserts
     the active scheme's OSC escapes. F6 delegates the switch to nushell's
     `theme.nu` (`_theme_toggle`), bound in WezTerm rather than the shell so
     it works under a full-screen TUI. Neovim (base16 + transparent) and
     television (`default` ANSI theme) inherit downstream.
     Nothing below WezTerm hardcodes hex values.
   - (b) **This resolves T-3 in T-3's favour.** Palette ownership is not
     WezTerm's: WezTerm *reads* what tinty writes. Where a document says
     "the terminal owns the palette", that wording is now a defect to
     correct, not an invariant to preserve.
   - (c) **Nodes reconciled against this answer:**
     `04-shell/01-core-config` (S.1) — the tinty palette re-assert in
     `config.nu` is **kept**, not orphaned, and becomes a requirement;
     `03-editor/11-colorscheme` (E.5) and `03-editor/13-statusline` (E.13) —
     the palette they derive from is tinty's, and E.5 records how far the
     inheritance actually reaches; `02-terminal/01-appearance` (T.1) — see
     (e).
   - (d) **The inventory verdicts move off `DEFER`:** the theme switcher in
     `capabilities-nushell.md` (to `SIMPLIFY` — the palette-owning core is
     minimal base, the background-override ladder/tuner is not), and the F6
     theme toggle and per-pane OSC retint in `capabilities-terminal.md` (to
     no marker). No `C`/`U` number changes: the ratings measure intricacy
     and daily value, the marker records membership, and it is the marker
     the human overrode.
   - (e) **What this opens.** The switcher now needs a home. `theme.nu` (the
     A/B slots, `_theme_toggle`, the tv scheme picker) has no node in
     `04-shell`, and the F6 binding has no node in `02-terminal`; the latter
     is inside `w0-2-terminal-respec` R5's remit ("give the ~230 uncovered
     lines a home"); the former now has a node, `04-shell/09-theme-switcher`
     (S.9), created by the orchestrator on 2026-08-21 once this answer
     landed. Neither is specced here — this node records a decision, it does
     not implement one — but they are missing work now, not deferred work.
     `06-help` will owe the resulting command and keybinding a manual entry.
3. **fzf.** `zi`/`cdi` shell out to `zoxide query --interactive`, which spawns
   **fzf**, against the shell epic's invariant that "tv owns every picker
   screen".
   **Decided 2026-08-21 (user): fzf is an accepted, documented exception.**
   `zi`/`cdi` keep shelling out to `zoxide query --interactive`; `zi` is
   **not** rewritten against a tv-backed picker.

   What the decision settles:
   - (a) `05-platform/02-package-provisioning/packages-installer` (P.2)
     req 7 stands: **fzf stays in the required package set**, and the
     parenthetical that called it "required whether or not it is wanted"
     becomes a statement of this decision rather than a shrug.
   - (b) [`04-shell/03-zoxide`](../../04-shell/03-zoxide/prd.md) (S.4) req 2
     keeps the interactive path unchanged.
   - (c) The exception is **written down, not merely tolerated**, in two
     places: the shell epic's invariant I3 in
     [`04-shell/prd.md`](../../04-shell/prd.md) names fzf as the one exception
     *and why*, and `help` carries an entry saying so. Without the second the
     manual teaches a rule the environment breaks, which is the failure mode
     [`06-help`](../../06-help/prd.md) exists to prevent.
   - (d) It is an exception, not a precedent. Nothing else may add a picker
     outside tv; a second one is a new decision, not an appeal to this one.

4. **Deployed or source — which artifact do the inventories rate?**
   **Decided 2026-08-21 (user): the deployed `~/.config` tree is canonical.**
   Raised by `w0-6-live-bugs`: checking L-12 surfaced what looked like two
   different programs. It was a reading error. The tree measured on
   2026-08-20, `~/.local/share/chezmoi`, is **not the chezmoi source** —
   `chezmoi source-path` prints `/Users/feb/dev/.files/home`, and
   `~/.config/chezmoi/chezmoi.toml` sets
   `sourceDir = "/Users/feb/dev/.files"`.
   `~/.local/share/chezmoi` is a stale checkout of the same GitHub repo
   (`yesitsfebreeze/.files`), last commit 2026-06-20, whose HEAD `a2544e4` is
   a git **ancestor** of the live source's `8e99f58` — two months behind, not
   divergent. Measured against the live source, the divergence is zero:
   `wezterm/wezterm.lua`, `nushell/config.nu`, `nushell/finder.nu` and
   `nushell/theme.nu` are byte-identical to their deployed `~/.config`
   counterparts. CLAUDE.md's "verify against the live config, always" still
   failed, but one directory further out than the audit thought — "the live
   config" resolved to whichever *clone* the reading agent opened, which is
   the same failure class that invalidated `02-terminal`.

   What the decision settles:
   - (a) The deployed tree is canonical — and, source and deployed being the
     same content, that costs nothing. The live chezmoi source at
     `/Users/feb/dev/.files` is **not** abandoned: it is where the deployed
     config comes from, last committed 2026-08-19. No document may cite
     `~/.local/share/chezmoi` as the chezmoi source again; the only permitted
     mention is as the stale clone that produced wrong findings, labelled as
     such. (Supersedes the previous (a), which was written about the wrong
     tree.)
   - (b) There is no 345-line source `finder.nu`. The live source's
     `finder.nu` is 221 lines and byte-identical to the deployed file, so
     `04-shell/04` is correctly specced and there is nothing to choose
     between. The 345-line stack-and-resume design exists only in the stale
     clone. L-5 still stands on its own evidence: `leadermode.nu` is dead
     code calling `finder --resume`/`--fresh`, flags the deployed finder
     never had. (Supersedes the previous (b).)
   - (c) `w0-2-terminal-respec` takes the **deployed** 1149-line
     `wezterm.lua` as its input. The ~810-line delta is not pushed back.
   - (d) **Commit `8fe3a71` (2026-08-19) deleted the machinery three PRDs and
     three inventory entries were written from** —
     `home/.chezmoidata/packages.yaml` (214 lines),
     `home/run_onchange_install-packages.sh.tmpl` (486 lines),
     `home/run_once_before_install-homebrew.sh.tmpl` and
     `home/.chezmoiignore`, replaced by a flat 233-line `install.sh` at the
     repo root; 2490 deletions in all. Inside `05-platform` this is
     discharged by `w0-4-s2-corrections/platform` and
     [`provisioning-rerate`](w0-4-s2-corrections/provisioning-rerate/prd.md).
     It is recorded here so nothing else is specced against a deleted
     capability.
   - L-12 is **corrected, not confirmed**. Of its six files, five are
     artefacts of reading the stale clone: the four `solo-window.*` files are
     absent from the live source (which has zero `solo_window()` references,
     as does the deployed config — the 3 references exist only in the clone),
     and `wsl-clip-prime.sh` is in neither tree. One is real:
     `home/dot_config/wezterm/background.png` is in the live source, and is
     dropped by decision 5(a) along with the wallpaper pipeline. Recorded in
     `05-platform/01-deploy-mechanism/managed-config`.

   Every inventory in `docs/` rates the deployed artifact. Where one was
   written against the source, that is a correction, not a difference of
   opinion.

5. **Wallpaper cycling and the opacity toggle: ported or dropped, and who
   gets `Ctrl+Shift+B`?**
   **Decided 2026-08-21 (user): both are dropped, on the record, and
   `Ctrl+Shift+B` goes to capsule.**
   Raised by T-11, which found the terminal epic refusing the two *legacy*
   features (`Ctrl+Shift+P` cycling, `Ctrl+Shift+O` toggle) while the live
   config had rebuilt both in new form. Refusing an old implementation is not
   a decision about its replacement, so C-1's "give `Ctrl+Shift+B` to
   capsule" would have deleted a live feature as a side effect of a
   keybinding change. Dropping it deliberately and dropping it by accident
   leave the same config and a very different record.

   What the decision settles:
   - (a) The `Ctrl+Shift+B` **wallpaper pipeline is not ported**, confirming
     the `DO NOT PORT` (C 8 / U 3) verdict in
     [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md).
     The engineering is careful, but the capability is a GUI keypress that
     rewrites the OS desktop *and* another tool's source tree, depends on
     ImageMagick, and is the largest block in the file after the tab floor.
     If desktop wallpaper matters later it is a shell command, not a
     terminal binding. `background.png` (`DO NOT PORT`, C 2 / U 0) drops out
     with it.
   - (b) The **opacity toggle is not in the minimal base**: neither the
     OSC-1337 `opacity` user-var nor the `opacity` tv picker. The picker
     keeps its existing `DEFER` (C 3 / U 3) — deferred is not refused, and
     it may come back with the theme switcher it shares a surface with.
   - (c) **`Ctrl+Shift+B` goes to capsule** — `capsule --rebuild`,
     [`01-capsule/01`](../../01-capsule/01-container-lifecycle/prd.md) R4.
     C-1's collision is **dissolved, not resolved**: with the incumbent
     dropped the key is free, so no rekey is needed and none should be
     invented. `Ctrl+Shift+T` is a separate collision and is untouched by
     this.
   - (d) **Not settled here, because it is not a fork.** The *static*
     `window_background_opacity = 0.95`, its base00 translucent tint and
     `macos_window_background_blur = 30` belong to the **Appearance
     baseline** entry (C 2 / U 7, take-over-as-is) — a different capability
     from either feature dropped above, and one the inventory already rates.
     [`02-terminal/01-appearance`](../../02-terminal/01-appearance/prd.md)'s
     escalation names this node as their decider; it is mistaken.
     [`w0-2-terminal-respec`](w0-2-terminal-respec/prd.md) specs them from
     the inventory like every other appearance field, and must not wait on an
     answer that is not coming.

   T-11 is thereby closed as *converted to a decision and answered* — gantt
   task D.1d, board node
   [`decisions/wallpaper-opacity`](../decisions/wallpaper-opacity/prd.md).

*A note on the gate that reads this list, recorded 2026-08-21 by W0.4h.*
`decisions/fzf`'s landed `specs/spec01.md` asserts that item 1 contains no
"Decided" — a scope guard meaning "the fzf lane did not answer item 1", true
when it was written and now superseded by this node answering it. Item 1
therefore records its answer as **Answered**, which is also the accurate verb;
the guard's letter still holds, while its message no longer describes the
file. Measured 2026-08-21 *before* this sweep, that same verify already exits
1 on its sibling assertion — "decision 2 was answered by this spec" — because
`decisions/tinty` answered item 2; that red predates this node and is the
identical superseded-guard class. Repointing both belongs to whoever owns that
closed ticket. The same applies to this node's acceptance box "The three open
decisions have a recorded answer": it is five decisions now, all answered, and
two landed verifies pin the box's text including its empty checkbox, so it is
left exactly as it is.


## S2 — bugs in the live config (do not reproduce these)

The PRDs documented these as working behavior. They are not. The **Owner**
column names the node whose PRD must not reproduce the bug; `none` means the
capability is not being ported and the reason is recorded in the inventory
the cell names.

| # | Owner — must not reproduce it | Finding |
|---|---|---|
| L-1 | `04-shell/06-listing` — carried by `w0-4-s2-corrections/shell` R3 | **`ls -D` cannot work on macOS.** It runs `du -sb`; macOS `du` has no `-b`, stderr is discarded, so dir sizes silently stay inode sizes. Fix in the rebuild (`-sk`, or `gdu`). **Fixed 2026-08-21** — `w0-4-s2-corrections/shell` R3; `04-shell/06-listing` R3 now specifies `du -sk`. |
| L-2 | `04-shell/04-television`, `04-shell/01-core-config` — carried by `w0-4-s2-corrections/shell` R7 | **`git-log` → commit decode is dead.** The channel emits a bare hash, the decoder reads field index 1, so the result is always empty and `git show` never runs. **Fixed 2026-08-21** — `w0-4-s2-corrections/shell` R7. The channel already extracts the hash (`{strip_ansi\|split: :1}`), so the decoder's second extraction was the duplication that rotted; `subject` is dropped and a silent empty decode is now forbidden. |
| L-3 | `04-shell/04-television`, `04-shell/01-core-config` — carried by `w0-4-s2-corrections/shell` R1 | **`rcwd` is not a channel** — the real name is `recent-dirs`, and the decoder only types `rcwd`, so recent-dir picks are never decoded as paths. Named wrongly in three PRDs and the inventory. **Fixed 2026-08-21** — `w0-4-s2-corrections/shell` R1; the channel is named `recent-dirs` everywhere and the decoder types that name. |
| L-4 | `04-shell/07-quicklist` — carried by `w0-4-s2-corrections/shell` R2 | **Finder picks are never logged to the quicklist** — only zoxide jumps and the bare-word fallback log. `04-shell/07`'s premise and acceptance criterion are wrong. **Fixed 2026-08-21** — `w0-4-s2-corrections/shell` R2; `04-shell/07`'s premise and acceptance criterion are re-specced against what actually logs. |
| L-5 | none — `DO NOT PORT`; accepted-with-reason in `docs/capabilities-nushell.md` | **`leadermode.nu` is dead code** (never sourced) and calls `finder --resume` / `--fresh`, flags that do not exist. Its `DO NOT PORT` verdict stands; the inventory should say "dead code", not describe it as live. **Accepted 2026-08-21** — accepted-with-reason, per `w0-6-live-bugs` R2; the inventory now reads "Dead code, not live behaviour (L-5)", which `tests/live-bugs.sh` greps. Decision 4(b) as rewritten keeps L-5 standing on its own evidence. |
| L-6 | `03-editor/01-options`, `03-editor/02-keymaps` — carried by `w0-4-s2-corrections/editor` R3 | Neovim `<Esc>` → `nohlsearch` is **inert** because `hlsearch=false`. **Decided 2026-08-21 (afk):** keep `opt.hlsearch = false` and drop the inert map. Rejected: the LazyVim pairing (turn `hlsearch` on, keep the map) — it changes the feel of every search to give one dead line a job, and `06-help`'s drift check would then have to document a binding that never fires. Reasoning in `docs/capabilities-nvim.md`. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R3 carries the decision into `03-editor/01-options` and `03-editor/02-keymaps`. |
| L-7 | `03-editor/06-explorer` — carried by `w0-4-s2-corrections/editor` R6 | **oil does not replace netrw for `:e some/dir`.** It is lazy on `keys`, so its `default_file_explorer` hijack isn't installed until `<leader>e` is pressed; with netrw disabled, `:e dir` opens neither. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R6. |
| L-8 | `03-editor/03-autocmds`, `03-editor/10-treesitter`, `03-editor/14-shift-select` — carried by `w0-4-s2-corrections/editor` R1 | treesitter's `FileType` autocmd (and shift-select's `ModeChanged`) are **ungrouped**, so a reload stacks duplicates — violating `03-editor/03`'s own invariant. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R1, whose independent sweep measured ten autocmds at eight sites, seven of them grouped, and found **three** ungrouped rather than two: `plugins/treesitter.lua:31`, `config/keymaps.lua:58` and `plugins/editor.lua:80`. The count is the point: a file-level `augroup` grep passes falsely on the seven grouped hits, which is why the epic gave it invariant I7. |
| L-9 | `03-editor/02-keymaps`, `03-editor/14-shift-select` — carried by `w0-4-s2-corrections/editor` R7 | Visual-mode `<C-v>` shadows blockwise-visual mode. **Decided 2026-08-21 (afk): intentional — port as-is and leave `<C-q>` unbound.** It is half of the `<C-c>`/`<C-v>` pair that is the point of shift-select; the map is `v`-mode only, so normal-mode `<C-v>` still enters blockwise, `virtualedit=block` still applies, and the built-in `<C-q>` still covers promoting an existing selection. Rejected: moving paste to another key, which breaks the pair for a mode that keeps a working alternative. Reasoning in `docs/capabilities-nvim.md`. **Half open.** `03-editor/02-keymaps` carries the decision (`w0-4-s2-corrections/editor` R7), but that lane's own closing note records R7's `03-editor/14-shift-select` half as **undischarged**, so this row is not marked fixed. |
| L-10 | `03-editor/12-small-plugins` — carried by `w0-4-s2-corrections/editor` R2 | gitsigns delete/topdelete glyphs are **empty strings** — a nerd-font character was lost. Both docs describe them as glyphs. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R2; the replacement glyph is prescribed by codepoint (U+F0DA), because L-10 is a codepoint lost to copy-paste and a spec that pasted it would lose it again. |
| L-11 | `02-terminal/03-f5-jump-mode` — to be carried by `w0-2-terminal-respec`, which lists this node in its `deps` | The F5 miss path rings BEL, but `audible_bell = "Disabled"` and no visual bell is set: a mistyped jump letter gives **no feedback at all**. |
| L-12 | `05-platform/01-deploy-mechanism/managed-config` — carried by `w0-4-s2-corrections/platform` R4 | Dead files still shipped in the chezmoi source: `solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh`, `background.png` — zero references in the live config. **Fixed 2026-08-21** — `w0-4-s2-corrections/platform` R4 — and **corrected**: five of the six files were phantoms of the stale June clone the audit read; only `background.png` is in the live source, and decision 5(a) drops it with the wallpaper pipeline. Recorded in `capabilities-provisioning.md`. |


## S2 — my factual errors

| # | Owner — who carries it | Finding |
|---|---|---|
| M-1 | `w0-4-s2-corrections/editor` R4 | `scrolloff=999` does **not** center the cursor "at all times" — the first and last half-screen are uncentered (measured). Three statements overclaim this. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R4, in `03-editor/01-options`. **Residue:** the third overclaiming statement lives at `docs/capabilities-nvim.md:17` ("cursor line permanently centered") and is unowned. |
| M-2 | `03-editor/14-shift-select` — **fixed 2026-08-24** | Shift-select acceptance criteria are off by one twice: one `<S-Right>` already selects two characters (`v<Right>`), and `<S-Left>` from insert selects two (`yz`), not one. **Fixed 2026-08-24** — and M-2's third reading was the correct one: the *acceptance criteria* were off by one, not the mappings. Measured on Neovim 0.12.4 through the real input path (`--listen` + `--remote-send`), fixture `ijklmnop`, cursor on `k`: `<S-Right>` → `kl`, `<S-Right><S-Right>` → `klm`, insert-then-`<S-Left>` → `jx`. The one-character variants (`v` bare, `<Esc>v`, `<Esc>lv`) were measured too and also work, so this was a fork between two working mapping sets rather than a defect. The user kept the live behaviour: the shipped manual entry already documents two characters *with its reason*, and editor-exactness would have falsified a reviewed entry while fixing only the horizontal half. The node's acceptance boxes now read two, and the four RPC-input mechanics that would otherwise falsify the gate are recorded in its body. |
| M-3 | `w0-4-s2-corrections/editor` R4 | Baseline is stated as "native 0.11" but the live binary is **0.12.4**, where `vim.highlight.on_yank` is deprecated in favor of `vim.hl`. `03-editor/03` prescribes the deprecated API. **Fixed 2026-08-21** — `w0-4-s2-corrections/editor` R4; `03-editor/03` now prescribes `vim.hl` against the live 0.12.4 baseline. |
| M-4 | `03-editor/05-completion` — **open** | blink.cmp is specced as lazy on `InsertEnter`, but it is a dependency of nvim-lspconfig (`BufReadPre`), so it loads at first buffer read. **Open.** Measured 2026-08-21: `03-editor/05-completion` R1 still says "lazy on `InsertEnter`"; only `plan.json`'s task note carries the correction. |
| M-5 | `04-shell/03-zoxide` | `04-shell/03-zoxide.md` header says C 5; sources are C 4 (suite, dominant) and C 7 (fallback). No entry yields 5. **Fixed 2026-08-21** — `04-shell/03-zoxide`'s header now reads C 4 and lists both sources with their own numbers. |
| M-6 | `04-shell/01-core-config` | `04-shell/01` folded the separate "Dirstack" entry (C 3 / U 7) in without listing it as a source or giving it a table row. **Fixed 2026-08-21** — `04-shell/01-core-config` lists the Dirstack entry as a source. The "no table row" half is moot: the epic's `## Children` table was deliberately deleted. |
| M-7 | `w0-4-s2-corrections/shell` R4 | `bb`/`ba` invoke **`brr`**, not `burrito`. Both binaries exist, so the name matters. **Fixed 2026-08-21** — `w0-4-s2-corrections/shell` R4. |
| M-8 | `04-shell/03-zoxide` | The no-match HOME hazard comes from **`mkcd`** treating `""` as "no argument", not from `__zoxide_z`. **Fixed 2026-08-21** — `04-shell/03-zoxide` R6 attributes the hazard to `mkcd`. |
| M-9 | `04-shell/04-television` | Three enter-hijacking channels exist (`text`, `zoxide` → `actions:cd` spawning a nested shell, `recent-files` → `actions:edit`), not just `text`; and `text.toml` is a local override, not stock. **Fixed 2026-08-21** — `04-shell/04-television` records all three enter-hijacking channels and the local `text.toml` override. *Addendum 2026-08-22 (S.6 analyst): `git-branch.toml` is a fourth (`enter = "actions:checkout"`); functionally covered — the un-hijack flag rides every `finder` invocation — and recorded in `04-television` spec01.* |
| M-10 | `w0-4-s2-corrections/capsule` R2 | `01-capsule/01` header carries `U 8–9` — a range, which the contract forbids. **Fixed 2026-08-21** — `w0-4-s2-corrections/capsule` R2; the range is gone and that lane's spec03 restored the truncated per-source numbers. |
| M-11 | `00-delivery/work-breakdown` | Critical path in `01-work-breakdown` used a non-existent edge (`S.7 → H.2`); H.2 depends on H.1 only. **Fixed 2026-08-21** — `00-delivery/work-breakdown` records the non-existent edge and its recomputed critical path no longer uses it. The bare backticked `[x] fixed` this row carried is not a marker any gate recognises. Recorded here because it is where the next reader looks, 2026-08-21: `M-11` is also the hardcoded probe of `gates/audit-findings.sh --selftest`, whose neutraliser re-inserts the marker it means to strip — `(was &)` keeps the match — so an inline marker on this row makes that selftest's three route counterfactuals unprovable and turns `--selftest` red. The wave-0 gate itself, `bash gates/audit-findings.sh` with no flag, is unaffected and stays green. Emitting the capture instead of the whole match fixes it; that file belongs to `00-delivery/verification-gates`, not to this node. |
| M-12 | `03-editor/11-colorscheme` | `11-colorscheme` acceptance says "all five highlights"; the requirement defines six. **Fixed 2026-08-21** — `03-editor/11-colorscheme`'s acceptance now reads "all six highlights"; discharged and verified. |
| M-13 | `w0-4-s2-corrections/help` R1 | `06-help/02` acceptance ("`help ls` reaches the builtin") contradicts its own resolution order plus `06-help/01`, which documents `ls` variants as entries. **Resolved toward "ours wins"** — the outlier acceptance box was the defect, not the resolution order. `06-help/02` now records the measured collision classes (`find`/`history`/`config` are nu builtins and do route; externals such as `git` never route here at all), keeps the flags reachable by ending a `command`-kind detail view with that command's `std/help` output, and adds R10's `--entry`/`--topic`/`--delegate`. The acceptance line naming a `listing` topic is gone — no such topic or entry exists. **Fixed 2026-08-21** — `w0-4-s2-corrections/help` R1. |
| M-14 | `w0-4-s2-corrections/help` R4 | `06-help/02` and `03` both render an entry's "source PRD", a field the content model's schema does not define. **Half-expired by the time it was worked:** `source` was already required, shape-checked and resolved against the repo by H.1 — it is the *written* R2 schema that had not caught up, and that is what was corrected. `06-help/01` R2 now carries a `source` sub-box; the field itself was not added, and neither the data nor the gate changed. **Fixed 2026-08-21** — `w0-4-s2-corrections/help` R4. |
| M-15 | `w0-4-s2-corrections/help` R3 | `06-help/00` claims all maps carry `desc`, but `03-editor/02` says the centered-jump maps carry none (and the visual-indent maps don't either) — so the drift check's "mismatched" class needs an exemption. **Fixed as epic invariant I5.** Measured: 12 of 87 normal-mode maps carry no `desc` — 4 ours by design plus 8 from Neovim's bundled matchit, which is an allowlist matter, not an exemption. The mechanism already existed from H.1 (`nullable: ["desc"]`); only its documentation was missing. The declared exemption is `desc: null`, and an *omitted* `desc` remains a defect rather than an exemption. `04-drift-check`'s own R2/R4 still need reconciling — see M-20. **Fixed 2026-08-21** — `w0-4-s2-corrections/help` R3. |
| M-16 | `w0-4-s2-corrections/help` R2 | `06-help/03` claims TAB-delimited rows "mirroring" `04-shell/07`, which specifies nuon and says nothing about channel row format. **The format was right and the citation was wrong.** R1 now derives TAB from tv's display template (`{split:\t:N}`), cites `~/.config/television/cable/quicklist.toml` as the live exemplar including the `"\\t"`-in-TOML escaping trap, and states that `04-shell/07`'s nuon is the quicklist's storage format and not a row format, so the two never conflicted. **Fixed 2026-08-21** — `w0-4-s2-corrections/help` R2. |
| M-17 | `03-editor/prd.md` — needs no fix | Editor epic says "13 files"; there are 14. **Needs no fix.** Measured 2026-08-21: `03-editor/prd.md` already says 14 files, and `find ~/.config/nvim -name '*.lua'` counts 14. Recorded rather than marked fixed — nothing was changed. |
| M-18 | `w0-4-s2-corrections/delivery` R2 | Work breakdown targets a `conf/` directory for T.2/T.3/C.4 — legacy-only layout. **Fixed 2026-08-21** — `w0-4-s2-corrections/delivery` R2; `conf/` appears nowhere in the work breakdown. |
| M-19 | `00-delivery/work-breakdown` | Work breakdown claimed "every feature PRD appears exactly once"; `05-platform`'s children and `00-delivery`'s own PRDs were absent. **Fixed 2026-08-21** — `00-delivery/work-breakdown` narrows the claim to "every feature PRD **outside `00-delivery`**", and Track P carries `05-platform`'s children. |
| M-20 | `06-help/04-drift-check` — **open** | `06-help/04-drift-check` R2 ("Our maps carry `desc`, so the check can compare descriptions as well as existence") and the *Mismatched* class in its R4 are written against the claim M-15 retired, so as specced the check false-positives on every deliberately desc-less map. Reconcile that node against the epic's I5 three-state rule (`absent` / `desc: null` / `desc: "text"`). Filed rather than fixed: `w0-4-s2-corrections/help` does not own that file, and one writer per file. **Open.** No lane has touched `06-help/04-drift-check`; it still needs reconciling against the epic's I5 three-state rule. |
| M-21 | unowned — needs a node; the `capabilities-terminal.md` third is inside [`w0-2-terminal-respec`](w0-2-terminal-respec/prd.md)'s remit | **The source-vs-deployed sweep used the wrong baseline and must be re-measured.** `w0-4-s2-corrections/docs-inventories` R7 swept `capabilities-nushell.md`, `capabilities-nvim.md` and `capabilities-terminal.md` for source-vs-deployed wording on 2026-08-21, before `~/.local/share/chezmoi` was identified as a two-months-stale June clone whose HEAD is a git ancestor of the live source. That node is `done` with R7 at `[~]`. Re-measure against `/Users/feb/dev/.files` — what `chezmoi source-path` reports — and **never** against `~/.local/share/chezmoi`. Same failure class as the seven assertions in `tests/live-bugs.sh` that were green while asserting the opposite of the record, until `gate-reconciliation` repointed them on 2026-08-21. |


## S2 — coverage gaps found

Live behavior no PRD and no inventory covers:

- **Shell:** `ollama-host` probe on every interactive start; `starship` (in no
  inventory entry at all); the tinty palette re-assert in `config.nu` (kept —
  open decision 2; specified as `04-shell/01-core-config` R10);
  `$env.ENV_CONVERSIONS`; the `esc_clear` binding;
  `cursor_shape` / `table` / `sync_on_enter` / `completions.external` config
  blocks.
  Absorbed 2026-08-21 by `w0-4-s2-corrections/shell` R6. `[x] fixed`
- **Television:** the `nu-history` channel — **`Alt-R` depends on it** — plus
  `alias`, `cht`/`cht-query` naming, `recent-files`, `channels`; the
  in-tv shortcut keys (with `cht.sh=f5` colliding with `burrito-sessions=f5`);
  and the non-cable assets (`bg-preview.sh`, `theme-preview.sh`).
  Absorbed 2026-08-21 by `w0-4-s2-corrections/shell` R6; the same lane's R5
  removed the burrito-sessions channel that owned half the f5 collision.
  `[x] fixed`
- **Neovim:** `cmdheight`; and the fact that `plugins/editor.lua` actually
  holds five specs (gitsigns, which-key, autopairs, **conform**,
  **vim-table-mode**) — the filename appears nowhere in the tree, though three
  PRDs write it.
  Absorbed 2026-08-21 by `w0-4-s2-corrections/editor` R5. `[x] fixed`
- **Provisioning:** covered now by
  [`capabilities-provisioning.md`](../../../docs/capabilities-provisioning.md) and
  [`05-platform`](../../05-platform/prd.md). `[x] fixed`


## S3 — hygiene

- Inventory sort order violated in `capabilities-nvim.md` (four rises) and
  `capabilities-nushell.md` (opacity below theme).
  Fixed 2026-08-21 by `w0-4-s2-corrections/docs-inventories` R3. `[x] fixed`
- `capabilities.md` (user-authored — **confirm before editing**): marker typo
  `DO NOT PORST`; missing markers on "Cross-platform Lua/shell/PowerShell
  parity", "Cross-platform dependency bootstrap", and "Just task runner",
  all of which the README treats as excluded or superseded; the header note
  describes verdicts as containing `|`, which none do; "maximiz:ed" typo;
  mini.nvim entry unmarked yet double-rated in `capabilities-nvim.md`.
  Fixed 2026-08-21 by `w0-4-s2-corrections/docs-inventories` — R1 (the
  author's confirmation, which the backlog's own acceptance box demands),
  R2 (the typo and the missing markers) and R4 (the mini.nvim double rating).
  `[x] fixed`
- Opacity is `DO NOT PORT` in one inventory and `DEFER` in another, and
  `04-shell/04` both specs its channel and defers it.
  Closed 2026-08-21 by decision 5(a)/(b), not by a lane: the two markers rate
  two different capabilities — the wallpaper pipeline is `DO NOT PORT`, the
  opacity picker keeps its `DEFER` — so there was no contradiction left to
  resolve. `[x] fixed`
- Duplicated facts the tree's own rule forbids: `cdi` in two PRDs; the
  kitty-protocol reason in three places; "the terminal owns the palette" in
  five, none of them the terminal epic (which has no invariants section).
  Closed 2026-08-21 by `w0-4-s2-corrections/delivery` R5, re-measured rather
  than assumed: the surviving `cdi` mentions are three distinct roles, the
  palette clause survives only as a historical note in `SYSTEM.md`, and the
  one kitty residue is the schema `why`-field example at
  `06-help/01-content-model/prd.md:85`. That lane recorded the residual risk
  rather than fixing it — if the quoted entry changes, the example goes
  stale and nothing checks it. `[x] fixed`
- README stated exclusions twice; build order still listed the bootstrap third
  though `04-shell/01` depends on it.
  Closed 2026-08-21 by `w0-4-s2-corrections/delivery` R4 — exactly one line
  outside `## Excluded` mentions exclusion at all — and R7, which gave the
  list the provisioning entries it was missing. `[x] fixed`
- `00-delivery` PRDs carry no C/U ratings, and the "plans live in `docs/`"
  argument used to exile the Gantt would also exile them. Resolve by
  exempting meta-epics explicitly in `AGENTS.md`.
  Fixed 2026-08-21: the exemption is written into `AGENTS.md`'s rating
  section ("Meta-epics are exempt"), which is the file `AGENTS.md` resolves
  to. `[x] fixed`
- Wrap limit exceeded in several files; tables should be exempted from the
  rule rather than the rule quietly broken.
  Fixed 2026-08-21 by `w0-4-s2-corrections/delivery` R6: the table exemption
  is in `SYSTEM.md`'s `## Conventions`, and the two non-table overruns that
  lane owned are rewrapped under 80 columns. `[x] fixed`
