# spec04 — packages-installer: strip burrito, re-spec the requirements it keeps

Discharges W0.4f **R2**, and carries spec03's allocation decision into the
node that owns the requirements. Est: **0.8h**

## Files touched
- `.mi/prds/05-platform/02-package-provisioning/packages-installer/prd.md`
  (only)

## Goal

**1. Strip `burrito/brr` from R7's required set (W0.4f R2).** R7 currently
lists `... chezmoi, tinty, docker, burrito/brr, gh`. Remove `burrito/brr`.
Settled by the `DO NOT PORT — burrito` decision of 2026-08-20, which names
"`burrito/brr` from the required package set" explicitly. Note for the
implementer: `install.sh` §3 still builds burrito from its own justfile — the
live script is not the spec, and this requirement describes the rebuild's
required set, so the strip is correct and does not need reconciling against
`install.sh`.

**2. Withdraw R1 and R2.** R1 ("Tools as data" — `.chezmoidata/packages.yaml`
holds the package set) and R2 (the `run_onchange` sha256 re-run gate) specify
files commit `8fe3a71` deleted on 2026-08-19. Per Q2 they are withdrawn.
Record them as withdrawn, in place, with the commit and date — do not delete
the lines and renumber. Replace what they provided with the one property that
actually replaces them: `install.sh` is safely re-runnable because every step
is `command -v`-guarded, so a second run on a provisioned machine is a no-op.

**3. Reword R4.** "macOS path is the supported one. brew for everything
available there. The Linux ladder (distro package → prebuilt GitHub release
tarball → cargo) exists for capsule containers" — the *substance* is exactly
right and matches `install.sh` (§1 brew/apt/pacman/dnf, §2
`latest_tag`/`fetch_release` release tarballs, §3 cargo). Only the implied
location changes: the ladder is in `install.sh`, not a chezmoi template.

**4. R5, R6, R7 survive.** R5 (never abort) is what `install.sh` already does:
`set -uo pipefail` with no `-e`, and every failure path calls `warn` and
continues. R6 (Neovim ≥ 0.11 floor) is live in `install.sh` — it parses
`nvim --version`, and when the minor is `< 11` it installs the official
release tarball. Both should now cite `install.sh` as the thing that proves
them.

**5. Retitle the node's heading** from "packages.yaml + run_onchange
installer" to what it now is. **Do not rename the directory** — the path is
the node id and its `deps` are cited by other nodes.

**6. Keep R7's fzf paragraph exactly as it stands.** It is the discharged W0.4f
R3 (see spec05). Do not touch it beyond removing `burrito/brr` from the list
above it.

## Acceptance
- [x] R7's required set names neither `burrito` nor `brr`.
- [x] R7 still names `fzf` and still links `decisions/fzf` — the fzf exception
      is not collateral damage of the burrito strip.
- [x] R1 and R2 are marked withdrawn with their numbers intact; the file names
      neither `packages.yaml` nor `sha256`.
- [x] The file names `install.sh` as the installer being specified.
- [x] R5 and R6 still exist as numbered boxes, and the Neovim floor is still
      stated as 0.11.
- [x] The directory name is unchanged.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check04.sh`
      exits 0.

**Proven RED 2026-08-21**: check04 exits 1 with 6 failures (`burrito` and
`brr` present; `install.sh` and any "withdraw" record absent;
`packages.yaml` and `sha256` still present).

## Ordering
Run after spec03 — spec03 decides the allocation, this carries it into the
requirements. Both files are inside this ticket, so there is no cross-ticket
write conflict.

verify: ""

## Spent proof

`burrito`, `brr` and `sha256` reappear in
`prds/05-platform/02-package-provisioning/packages-installer/prd.md` only
where the file records them as gone: lines 42 and 149 name burrito as a `DO
NOT PORT` consumer of the removed cargo rung, line 200 lists it among "eight
do-not-reintroduce items verified absent", and line 197's `sha256` is
`chezmoi.toml`'s digest rather than the deleted `run_onchange` gate.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check04.sh`
```
