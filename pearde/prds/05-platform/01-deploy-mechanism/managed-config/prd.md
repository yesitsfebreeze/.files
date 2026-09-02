---
state: done
priority: 21
est: 2h
task: P.5
mode: afk
needs:
  - 05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# Managed config surface + dot_gitconfig.tmpl

Parent: [`01-deploy-mechanism`](../prd.md) · source:
[`01-deploy-mechanism`](../prd.md) requirements R2

## Requirements
- [x] **R2** — **Managed config surface.** One source of truth per tool under
      `home/dot_config/`: nushell, nvim, wezterm, television,
      `starship.toml`, bat, gh, lazygit, tinted-theming. Templated only where
      it must differ per machine (`dot_gitconfig.tmpl`).

## Acceptance
- [x] Every requirement box above is `[x]` against the real thing.

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Notes

 Footprint narrowed from home/dot_config/ to the file it actually owns
      (05-platform/01 req 1 puts dot_gitconfig.tmpl at the home/ root). The
      managed-surface declaration lists directories owned by other tracks; it
      does not write them.

**Managed surface trimmed, 2026-08-21.** The terminal multiplexer that used
to sit between `television` and `starship.toml` is out of the list above:
`DO NOT PORT`, decided 2026-08-20 and recorded in the exclusion list of
[`prds/README.md`](../../../README.md), which names the managed-config
surface as one of the four places it comes out of. Live-config evidence, so
this is not re-litigated: the crate binary is installed, but the executable
the `bb`/`ba` aliases actually invoke is not present on the machine at all,
so those aliases are dead rather than merely misnamed (M-7 understated this);
nothing in `~/.config/nushell/config.nu` launches it at shell start.

**L-12, corrected against the live source (2026-08-21).** Backlog item
[L-12](../../../00-delivery/corrections/prd.md) records six dead files "still
shipped in the chezmoi source" — `solo-window.{applescript,sh,ps1,vbs}`,
`wsl-clip-prime.sh` and `background.png`. Five of the six are an artefact of
measuring the wrong tree.

There are two trees and they are two months apart:

- `/Users/feb/dev/.files` is the **live chezmoi source** — `chezmoi
  source-path` prints `/Users/feb/dev/.files/home`, and
  `~/.config/chezmoi/chezmoi.toml` sets `sourceDir` to it.
- `~/.local/share/chezmoi` is a **stale clone** of the same GitHub repo, last
  commit 2026-06-20 and a git ancestor of the live HEAD. L-12 was measured
  here. It is named in this note only as the tree that produced the wrong
  finding; no document may cite it as "the chezmoi source".

Measured file by file on 2026-08-21:

| file | live source `/Users/feb/dev/.files` | stale clone `~/.local/share/chezmoi` |
|---|---|---|
| `solo-window.{applescript,sh,ps1,vbs}` | absent | present (4 files) |
| `wsl-clip-prime.sh` | absent | absent |
| `background.png` | **present** at `home/dot_config/wezterm/background.png` | absent |
| `solo_window()` references in `wezterm.lua` | 0 | 3 |

So the solo-window half of L-12 is **struck, not restated**: the deployed
`~/.config/wezterm` has zero references to `solo_window()` and so does the
live source — only the stale clone defines and calls it, which is why the two
trees looked like different programs. That nuance describes the stale clone
versus the deployed config, not the live source versus the deployed config.
`wsl-clip-prime.sh` is in neither tree.

One file is real. `background.png` is in the live source and is **not carried
into the rebuild** — a cross-link, not a new verdict here: decision 5(a)
already drops the `Ctrl+Shift+B` wallpaper pipeline and takes the image with
it. See
[`decisions/wallpaper-opacity`](../../../00-delivery/decisions/wallpaper-opacity/prd.md).
Under Decision 4 the rebuild does not delete files from the live source, so
this is recorded as "not carried across", never as a deletion to perform.

**Two content decisions, made 2026-08-21 while speccing (see
[`specs/spec01.md`](specs/spec01.md) for the evidence).**

1. **The `[includeIf "gitdir:~/dev/_pi_extensions/"]` block is not carried
   across**, and neither is the `~/.config/git/pi-extensions.gitconfig` it
   points at. Measured: `~/dev/_pi_extensions` does not exist on this machine;
   the installer that created it (`run_onchange_after_install-pi.sh`) is not in
   the live source any more, removed by commit `8fe3a71` (2026-08-19); and its
   `path` targets a `git` directory that is not one of R2's nine managed names.
   The pi surface is already `DO NOT PORT` twice in
   [the board README](../../../README.md). Under Decision 4 nothing is deleted
   from the live source and nothing is removed from this machine — the file is
   unmanaged, chezmoi never removes unmanaged files, and it simply stops being
   included. Restoring it, if the workspace returns, is the two-line block plus
   a declared tenth surface name. **This exclusion still needs a line in the
   README exclusion list and in the epic's Non-goals**; both are outside this
   node's write scope.
2. **The gh credential-helper comment is retargeted, the mechanism is
   untouched.** The live comment blames Git Credential Manager's `manager`
   helper and names Azure DevOps; on this host `git config --system
   credential.helper` is `osxkeychain` and `git-credential-manager` is not
   installed. GCM was the Windows half of a `DO NOT PORT` dual-platform setup.
   The empty `helper =` reset stays exactly as-is — it is why gh's *active*
   account wins over a cached keychain token for github.com only.

**One thing this node allows but does not endorse.** `plan.json` schedules
C.4 to write `home/dot_config/capsule/recents.nuon` — a tenth directory under
a surface R2 declares as nine, holding recents *state* rather than tool
config. The census in [`specs/spec02.md`](specs/spec02.md) lists it as
declared-pending so C.4 is not blocked by this gate. Whether it belongs in the
managed config surface at all is for the epic to settle.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `bash tests/managed-config.sh` →
**63 PASS / 0 FAIL**, exit 0, re-run independently (64 PASS lines counted
including the summary). `home/dot_gitconfig.tmpl` and `tests/managed-config.sh`
both landed; the live chezmoi config is unchanged
(`02d5d4ee…c850a1`, `source-path /Users/feb/dev/.files/home`) and nothing was
ever deployed to the real `$HOME`.

**Every check was proven to fire, in scratch copies.** The surface census went
red six for six against planted `burrito/`, `wezterm/background.png`,
`nushell/config.nu.tmpl`, `dot_bash_profile`, a second `starship.toml` and a
second `nvim/`. Planting the user's real address turned three gitconfig checks
red at once; deleting the two `helper =` lines turned both credential checks
red; `syntax-theme = gruvbox-dark` turned the palette check red.

The implementer **corrected the spec's own arithmetic** rather than matching
it: the key table asserts 35 parsed keys, not the 33 specced, covering all 36
non-identity keys in the live file. The box is met as a superset and the
correction is recorded in the spec.

Kept verbatim on purpose: **both empty `helper =` resets** — asserted to read
back as `["", "!gh auth git-credential"]`. That empty reset is load-bearing and
is exactly the line a tidying pass deletes as noise. `delta.syntax-theme = ansi`
is asserted as the palette-inheritance rule in one line.

One portability constraint worth keeping: the census could not use a `case`
inside `$(…)` — macOS's system bash 3.2 mis-parses it and silently swallows the
rest of the block. Rewritten as a `while read` loop, with the reason in a
comment.

**Three items reported, not fixed:** the pi `includeIf` exclusion is not yet
recorded in `.mi/prds/README.md`'s exclusion list or the epic's Non-goals, which
the contract requires; `capsule` would be a tenth entry in a surface R2 declares
as nine (`plan.json` schedules C.4 to write `home/dot_config/capsule/recents.nuon`
— recents *state*, not tool config); and `delta` and `gh` are hard runtime
dependencies of this file, so a P.2 that drops either breaks this node while
this gate still passes, because it asserts the config, not the binaries.
