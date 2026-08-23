# spec01 — managed-config: strip burrito, and record L-12 as it actually is

Discharges W0.4f **R1** and **R4**.
Est: **0.5h**

## Files touched
- `.mi/prds/05-platform/01-deploy-mechanism/managed-config/prd.md` (only)

## Goal

Two edits to one file.

**1. Strip burrito from the managed surface (R1).** R2's list currently reads
`nushell, nvim, wezterm, television, burrito, starship.toml, bat, gh,
lazygit, tinted-theming`. Remove `burrito`. This is settled: `DO NOT PORT —
burrito`, decided 2026-08-20, recorded in
[`.mi/prds/README.md`](../../../../../README.md) under the exclusion list,
which also names "burrito from the managed-config surface" as one of the four
things that come out with it.

Live-config evidence that the decision holds, so the implementer does not
re-litigate it: `~/.cargo/bin/burrito` exists but `brr` — the binary the
`bb`/`ba` aliases actually invoke — does **not**, so those aliases are dead,
not merely misnamed (M-7 understated this). No shell-start launch of burrito
exists in `~/.config/nushell/config.nu`; the only live references are three
comments, the two dead aliases, and the `burrito-sessions` tv channel that
`w0-4-s2-corrections/shell` R5 removes.

**2. Record L-12 correctly (R4).** The backlog says six dead files are "still
shipped in the chezmoi source". Measured today against the live source
(`chezmoi source-path` → `/Users/feb/dev/.files/home`):

| file | live source `/Users/feb/dev/.files` | stale clone `~/.local/share/chezmoi` |
|---|---|---|
| `solo-window.{applescript,sh,ps1,vbs}` | absent | present (4 files) |
| `wsl-clip-prime.sh` | absent | absent |
| `background.png` | **present** at `home/dot_config/wezterm/background.png` | absent |
| `wezterm.lua` `solo_window()` refs | 0 | 3 |

So five of the six are an artefact of reading the stale clone, and one is
real. Add a `## Notes` entry recording that, and note that `background.png`
is not carried into the rebuild **by cross-link, not by a new verdict** —
decision 5(a) already drops it with the `Ctrl+Shift+B` wallpaper pipeline.

The two-trees nuance W0.4f R4 was told to preserve describes the *stale clone*
versus deployed, not the live source versus deployed, and must be written that
way. Per Q1, no document may cite `~/.local/share/chezmoi` as "the chezmoi
source" — naming it here as the stale clone that produced a wrong finding is
the one permitted use, and it must be labelled as such.

## Acceptance
- [x] R2's managed-surface list names neither `burrito` nor `brr`.
- [x] The file records which of L-12's six files is actually in the live
      source (`background.png`) and which are not, citing L-12 by id.
- [x] Both trees are named and distinguished: `/Users/feb/dev/.files` as the
      live source, `~/.local/share/chezmoi` explicitly as the stale clone the
      finding came from.
- [x] `background.png`'s exclusion cross-links `decisions/wallpaper-opacity`; it does not restate the verdict.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check01.sh`
      exits 0.

**Proven RED 2026-08-21** against the current tree: check01 exits 1 with 8
failures (burrito present; `background.png`, `solo-window`, `wsl-clip-prime`,
both tree paths, the `wallpaper-opacity` link and the `L-12` id all absent).

## Do not
- Touch `tinted-theming` in R2's list. It is absent from the live source
  (`diff -rq` shows it deployed-only, unmanaged), but the tinty decision keeps
  tinty as palette owner, so listing it is a deliberate forward-looking
  choice, not an error. Flagged in the analyst report; not this spec's call.
- Touch the epic, the sibling, or the backlog.

verify: ""

## Spent proof

`burrito` reappears in
`prds/05-platform/01-deploy-mechanism/managed-config/prd.md:128` only inside
the `## Closing note` added on the node's close, recording that the surface
census went "red six for six against planted `burrito/`" — a counterfactual
proof the whole-file substring sweep cannot distinguish from a surviving
managed-surface entry.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check01.sh`
```
