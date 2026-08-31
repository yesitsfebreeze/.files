---
state: done
priority: 37
est: 3.7h
task: W0.4f
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# 05-platform corrections + burrito strip

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — Remove burrito from `01-deploy-mechanism` requirement 2's
      managed-surface list.
- [x] **R2** — Remove `burrito/brr` from `02-package-provisioning` requirement
      7's required set.
- [x] **R3** — Requirement 7 also notes `fzf` is required whether or not it is
      wanted. Reconcile it with whatever the fzf decision returns rather than
      leaving both statements standing.
- [x] **R4** — L-12: dead files still shipped in the chezmoi source
      (`solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh`,
      `background.png`). Under Decision 4 the source is abandoned, so this is
      recorded as "not carried into the rebuild" rather than as a deletion to
      perform. Note when recording it: the deployed `~/.config/wezterm` has
      zero references to `solo-window.*`, but the chezmoi source's own
      `wezterm.lua` defines `solo_window()` and calls it twice — the two trees
      are different programs, which is what raised Decision 4. Placed here by
      the conductor on 2026-08-21 per `w0-6-live-bugs`' escalation.

## Questions

Raised by the analyst on 2026-08-21. Answering these is a precondition for
R4, and for whether R1/R2 are worth doing to documents that survive.

**The finding underneath all four.** `chezmoi source-path` prints
`/Users/feb/dev/.files/home`, and `~/.config/chezmoi/chezmoi.toml` sets
`sourceDir = "/Users/feb/dev/.files"`. The audit of 2026-08-20 measured
`~/.local/share/chezmoi` instead. That directory is a **stale checkout of the
same GitHub repo** (`yesitsfebreeze/.files`), last commit 2026-06-20; its HEAD
`a2544e4` is a git ancestor of the live source's HEAD `8e99f58` (verified:
`git merge-base` returns the stale HEAD). So it is not a divergent tree — it
is the same repo, two months behind.

Measured against the **live** source, every divergence L-13 reports is gone:
`wezterm/wezterm.lua`, `nushell/config.nu`, `nushell/finder.nu` and
`nushell/theme.nu` are byte-identical to their deployed `~/.config`
counterparts (`diff -q`, all four SAME). This is the failure class that
invalidated `02-terminal`, one directory further out.

1. **Which tree is "the chezmoi source", and does Decision 4 survive its
   basis being wrong?**

   Decision 4 concluded "the deployed tree is canonical" from measurements
   (339 vs 1149 `wezterm.lua`, 380 vs 715 `config.nu`, 345 vs 221
   `finder.nu`) that are all readings of the stale June clone. Against the
   live source those numbers are 1149/1149, 715/715, 221/221.

   *Recommended answer:* the live chezmoi source is `/Users/feb/dev/.files`;
   `~/.local/share/chezmoi` is a stale clone and no document may cite it.
   Decision 4's **conclusion** stands and becomes trivially true — source and
   deployed are the same content, so "rate the deployed artifact" costs
   nothing. Its **reasoning** does not: 4(a) "the chezmoi source is
   abandoned, not a port target" is false of the live source, and 4(b) "the
   345-line source `finder.nu` is not ported" describes a file that exists
   only in the stale clone. Both sub-clauses need rewriting in
   [`corrections`](../../prd.md) — a file this node does not own, so it is
   the conductor's to route (W0.6 owns that file).

2. **Does `02-package-provisioning` survive commit `8fe3a71`?**

   On **2026-08-19**, the day before the audit, the user committed
   *"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal chezmoi,
   one plain install.sh"* — 2490 deletions. It removed
   `home/.chezmoidata/packages.yaml` (214 lines),
   `home/run_onchange_install-packages.sh.tmpl` (486 lines),
   `home/run_once_before_install-homebrew.sh.tmpl`, and
   `home/.chezmoiignore`, replacing them with a flat 233-line `install.sh`
   (a plain `brew install` list plus release/cargo/npm fallbacks). It is an
   ancestor of the live HEAD; none of it has come back.

   That is the entire subject of this epic. `02-package-provisioning`'s
   Purpose, its C 8 / U 9 rating, all four of its inventory sources
   ("Package installer", "Declarative package set", "Homebrew bootstrap",
   "Neovim version gating"), and the parent epic's invariant **I3 "Tools are
   data"** describe machinery the user deliberately deleted two days ago.
   `.mi/docs/capabilities-provisioning.md` rates it as live.

   *Recommended answer:* re-spec the epic against `install.sh`, and re-rate.
   The rebuild's whole premise is "minimal", and the user has just made this
   exact simplification by hand on the real repo; rebuilding the 559-line
   renderer would be porting a capability its owner removed. Keep the two
   properties that earn their place regardless — never abort on a failed
   package (`install.sh` already does this), and the Neovim ≥ 0.11 floor —
   and drop `packages.yaml` + the `run_onchange` sha256 re-run gate with it.
   If instead the data-driven installer is wanted back, that is a deliberate
   **re-addition**, not a port, and should say so in the PRD.

3. **`01-deploy-mechanism` R6 — a three-stage ordering contract with one
   stage left.** R6 specifies `run_once_before` → package installer
   (`run_onchange`) → `run_after`. In the live source `home/` holds exactly
   one script, `run_after_generate-shell-init.sh`; the other two stages went
   out with `8fe3a71`.

   *Recommended answer:* contingent on Q2. If Q2 goes to `install.sh`, R6
   stops being a chezmoi script-ordering contract and becomes the narrower
   real constraint it was protecting — **anything depending on an installed
   tool must run after the install and must re-resolve PATH, because a tool
   installed this run is not on PATH yet**. That reason is the expensive part
   and must survive whichever shape wins. If Q2 keeps the three stages, R6
   stands unchanged.

4. **R4 / L-12 — what is actually there.** L-12 lists
   `solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh` and
   `background.png` as dead files "still shipped in the chezmoi source".
   Measured today against the live source: the four `solo-window.*` files are
   **not there** (they exist only in the stale June clone, which is also the
   only tree whose `wezterm.lua` defines `solo_window()` — 3 references there,
   0 in both the live source and the deployed config). `wsl-clip-prime.sh` is
   in neither tree. `background.png` **is** in the live source at
   `home/dot_config/wezterm/background.png`.

   *Recommended answer:* record one file, not six. `background.png` is not
   carried into the rebuild — already settled by decision 5(a), which drops
   the `Ctrl+Shift+B` wallpaper pipeline and `background.png` with it, so
   this is a cross-link and not a new verdict. The solo-window half of L-12
   is an artefact of reading the stale clone and should be struck rather than
   restated; the two-trees nuance this node's R4 was told to preserve
   describes the stale clone versus deployed, not the live source versus
   deployed.

## Acceptance
- [x] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
      *(a) — L-12 is marked fixed in the backlog: "**Fixed 2026-08-21** —
      `w0-4-s2-corrections/platform` R4 — and **corrected**: five of the six
      files were phantoms of the stale June clone".*

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Notes

**R1 / R2 — the burrito strip landed in two files, 2026-08-21.** R1 removed
it from the managed-surface list in
[`05-platform/01-deploy-mechanism/managed-config`](../../../../05-platform/01-deploy-mechanism/managed-config/prd.md)
R2; R2 removed `burrito/brr` from the required package set in
[`packages-installer`](../../../../05-platform/02-package-provisioning/packages-installer/prd.md)
R7 — the grandchild that took R7 in the split, not either of the two files
W0.4f originally declared. Proven by `specs/check01.sh` and
`specs/check04.sh`, both exit 0.

**R3 was already discharged before this ticket was analysed.** Recorded here
rather than ticked as if this ticket did the work, because a `[x]` without
its proof is a false record that outlives its author.

- The phrase R3 asks about — that `fzf` is required "whether or not it is
  wanted" — existed in exactly one file in the tree,
  [`packages-installer/prd.md`](../../../../05-platform/02-package-provisioning/packages-installer/prd.md),
  in R7. Neither of W0.4f's two declared footprint files contains the string
  `fzf` at all, so there was never anything for this ticket to reconcile in
  them.
- [`decisions/fzf`](../../../decisions/fzf/prd.md) landed 2026-08-21 and its
  implementer **replaced** that parenthetical in place. The old wording is
  gone. R7 now reads that `fzf` is in the set as `zi`'s dependency — `zoxide
  query --interactive` spawns it — and is "an accepted, documented exception
  to `04-shell`'s 'tv owns every picker screen'", linking
  [`decisions/fzf`](../../../decisions/fzf/prd.md) and decision 3 of the
  corrections backlog.
- So there is one statement standing, not two. R3 is discharged; this ticket
  verified it rather than re-doing it (`specs/check04.sh` asserts both that
  `fzf` survives the burrito strip and that its link to `decisions/fzf`
  survives with it).

**R4 — L-12 recorded, five of its six files struck.** Written into
[`managed-config`](../../../../05-platform/01-deploy-mechanism/managed-config/prd.md)'s
Notes. L-12 was measured against `~/.local/share/chezmoi`, a stale June clone
of the same repo; the live source is `/Users/feb/dev/.files`. Against the
live source the four `solo-window.*` files and `wsl-clip-prime.sh` are absent
and `wezterm.lua` has zero `solo_window()` references, so the two-trees
nuance describes the stale clone versus the deployed config, not the live
source versus the deployed config. One file is real — `background.png` — and
it is recorded as not carried into the rebuild by cross-link to decision
5(a)'s wallpaper-opacity node, not as a new verdict and not as a deletion to
perform.

**Q2 answered by the user, 2026-08-21: re-spec against `install.sh` and
re-rate.** `02-package-provisioning` goes C 8 → C 4 (U stays 9); invariant I3
"Tools are data" is withdrawn in place at the epic; requirements R1 and R2 of
`packages-installer` are withdrawn with their numbers intact; `01-deploy-
mechanism` R6 narrows from a three-stage chezmoi contract to the constraint
it was protecting; and `homebrew-bootstrap` R3 is **kept** — the capability
survives in `install.sh` §1, only its mechanism moved. Commit `8fe3a71`
(2026-08-19) is cited in every file changed.

**Left for other owners.** `.mi/docs/capabilities-provisioning.md` needs the
matching fold-in (three entries → one `Tool installation (install.sh)` at C 4
· U 9, with "Neovim version gating" kept separate) — it is
`docs-inventories`' footprint. The corrections backlog's Decision 4 rewrite is
`backlog-closeout`'s (W0.4h); the replacement text is persisted beside this
node as `decision4-replacement.md`. Both are why the Acceptance box below
stays open.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All seven checks exit 0, re-run
independently, from RED baselines of 8/6/7/6/4/11/4 that reproduced exactly.
`chezmoi source-path` still `/Users/feb/dev/.files/home` — only read-only
invocations were made.

Re-checked: `02-package-provisioning` reads **C 4 · U 9**; the epic holds
**exactly four** acceptance boxes with I1–I4 all present and **I3 withdrawn in
place** rather than deleted (I1–I4 are cited by number, including by the epic's
own boxes); and neither `homebrew-bootstrap` nor `packages-installer` was
renamed — the path is the node id and `plan.json` P.3/P.2 cite it.

**This ticket acted on the session's most consequential finding.** The audit of
2026-08-20 measured `~/.local/share/chezmoi`, a stale June clone whose HEAD is a
git *ancestor* of the live source at `/Users/feb/dev/.files`. Commit `8fe3a71`
had already deleted `.chezmoidata/packages.yaml`, the 486-line `run_onchange`
installer and the Homebrew `run_once_before` template — so this epic, rated
C 8 / U 9, described machinery that no longer existed. The user chose to
re-spec against `install.sh` and re-rate. U stays 9 because every epic still
depends on its tools existing; C falls to 4 because what is rated now is a
guarded shell script, not a 559-line template rendering a YAML model behind a
sha256 gate.

**Two approved deviations, both better than the instruction they replaced:**
epic acceptance box 2 was *narrowed in place* rather than replaced — it was
still closable, but enumerated three mechanisms of which only `run_after`
re-running to byte-identical output survives — and a new **R8** was added to
`packages-installer` to carry the re-runnability property that withdrawing
R1/R2 would otherwise have silently dropped. R1/R2 are marked withdrawn with
their numbers intact, not deleted.

**The Homebrew capability survives; only its mechanism moved.** `install.sh` §1
installs brew when missing and re-evaluates `brew shellenv`, so P.3's R3 is
kept and restated rather than withdrawn.

**One transient inconsistency, deliberately sequenced:** this PRD's header now
cites `"Tool installation (install.sh)" (C4 U9)`, an inventory entry that does
not exist yet. The contract's C/U-must-match rule closes the moment
[`provisioning-rerate`](../provisioning-rerate/prd.md) (W0.4i) folds the three
stale entries into it. The PRD leads and the inventory follows, inside the same
sweep — rather than the inventory being edited by a lane whose own gate forbids
it.

Decision 4's replacement text is persisted at
[`decision4-replacement.md`](decision4-replacement.md) for
[`backlog-closeout`](../backlog-closeout/prd.md) (W0.4h) to write. Committer
date `8fe3a71` = 2026-08-19 (author date 2026-08-18); the specs use the
committer date consistently.
