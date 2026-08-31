# spec03 — 02-package-provisioning: re-purpose and re-rate against install.sh

Implements the user's answer to Q2. Est: **0.8h**

## Files touched
- `.mi/prds/05-platform/02-package-provisioning/prd.md` (only)

## Goal

This node's Purpose, its C 8 / U 9 rating and all four of its inventory
sources describe machinery the user deleted on 2026-08-19 in commit `8fe3a71`
(2490 deletions): `home/.chezmoidata/packages.yaml` (214 lines),
`home/run_onchange_install-packages.sh.tmpl` (486 lines),
`home/run_once_before_install-homebrew.sh.tmpl`, `home/.chezmoiignore`. What
replaced all of it is one flat `install.sh` (233 lines) at the repo root.

**User decision (2026-08-21, Q2):** re-spec against `install.sh` and re-rate.
Keep only the never-abort property and the Neovim ≥ 0.11 floor.

### Header

Current: `· C 8 · U 9 · sources: "Package installer" (C8 U9 — dominant),
"Declarative package set" (C2 U9), "Homebrew bootstrap" (C2 U8), "Neovim
version gating" (C4 U8)`.

New: **C 4 · U 9**. Justification the implementer should keep in the file so
the number is defensible rather than asserted — what is being rated now is a
guarded shell script with three mechanisms (a package-manager batch install, a
`latest_tag`/`fetch_release` GitHub-release ladder for tools distros do not
carry, and a handful of cargo/git/npm builds), not a 559-line template
rendering a YAML model with a sha256 re-run gate. Usefulness is unchanged at
9: every other epic still depends on its tools existing.

Sources must be restated against the re-rated inventory. Per the C/U rule a
header's numbers must match its inventory entry, and
`.mi/docs/capabilities-provisioning.md` is **`w0-4-s2-corrections/docs-inventories`'
footprint, not this ticket's**. What this spec needs from that file is named in
the analyst report; the implementer of this spec writes the PRD header to
match and does **not** edit the inventory. If the inventory has not landed
yet, cite the entry by the name the report specifies and leave the PRD's own
numbers as the single source until it does.

### Purpose

Currently "installed from a declarative list, exactly once, without ever
aborting the apply". The declarative list is gone and "exactly once" was the
`run_onchange` sha256 gate, also gone. Rewrite to what `install.sh` is: one
idempotent script that installs every tool the other epics assume, re-runnable
safely because each step is `command -v`-guarded, and non-fatal throughout.

### Allocation

`packages-installer` currently owns R1, R2, R4, R5, R6, R7. **R1** (tools as
data) and **R2** (sha256 re-run gate) are withdrawn — the mechanisms they
specify no longer exist. Say *withdrawn*, with the commit, rather than
deleting the lines: other documents cite these requirements by number, and a
silently vanished R2 reads as a renumbering error. R4, R5, R6, R7 survive.
`homebrew-bootstrap` keeps R3 — Homebrew bootstrap survives as a capability
(`install.sh` §1 installs brew when missing and re-evaluates `brew shellenv`),
only its mechanism moved out of `run_once_before`.

### Acceptance boxes

Current box 2, "Editing `packages.yaml` triggers exactly one installer re-run;
touching anything else triggers none", must go with the mechanism. The other
three survive and box 1 should name `install.sh` as what is run. Add one for
re-runnability, which is what replaces the sha256 gate: a second `install.sh`
on an already-provisioned machine installs nothing and exits 0.

## Acceptance
- [x] Header carries single-number C and U, with C below 8.
- [x] The file names `install.sh` and does not name `packages.yaml`,
      `run_onchange`, `sha256`, or describe the set as `declarative`.
- [x] Commit `8fe3a71` is cited as what deleted the machinery this node used
      to spec.
- [x] Both kept properties survive as checkable boxes: never-abort (the apply
      exits 0 with a warning when one package fails) and the Neovim ≥ 0.11
      floor.
- [x] R1 and R2 are recorded as withdrawn with their numbers intact, not
      deleted.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check03.sh`
      exits 0.

**Proven RED 2026-08-21**: check03 exits 1 with 7 failures (C is 8;
`install.sh`, `8fe3a71`, `0.11` and any never-abort phrasing absent;
`packages.yaml` and `declarative` still present).

## Do not
- Edit `.mi/docs/capabilities-provisioning.md` — another ticket's file.
- Edit `.mi/prds/05-platform/prd.md` to bring invariant I3 down. It needs to
  come down, and it is outside this footprint; the analyst report names it.

verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check03.sh`
