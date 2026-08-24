# spec06 — 05-platform epic: bring I3 down, re-word Purpose, make box 3 closable

Implements the user's answer to Q2 at the epic level. Est: **0.7h**

## Files touched
- `.mi/prds/05-platform/prd.md` (only)

## Goal

spec03 re-rates `02-package-provisioning` against `install.sh`. The epic above
it still asserts the deleted model, and leaving it makes the tree
self-contradictory: the invariant would stand while the data model it names is
gone, and one acceptance box would be permanently unclosable.

### 1. Purpose paragraph

It currently reads, in part: "a 559-line `run_onchange` installer renders a
declarative `packages.yaml` (re-running only when its sha256 changes, with a
documented fallback ladder on Linux), and a `run_after` script generates the
starship/zoxide/television init files". Two of those three no longer exist.

Rewrite so the paragraph describes the live source at `/Users/feb/dev/.files`:
`install.sh` (233 lines) installs the tool set — a package-manager batch, a
GitHub-release ladder for tools distros do not carry, a few cargo/git/npm
builds — and calls `chezmoi apply` last, which runs
`run_after_generate-shell-init.sh`, the only script left in `home/`. Cite
commit `8fe3a71` (2026-08-19) as what removed the rest.

**Keep two things verbatim in substance.** The paragraph's opening — that this
epic used to be specced from `capabilities.md`'s WezTerm-Lua bootstrap and
that winget is out of scope — is still correct and still explains why the epic
exists. And the closing sentence, that the shell-init generation is
load-bearing for [`04-shell/01`](../../../../../04-shell/01-core-config/prd.md) which
requires shell launch to do zero setup work, is the most valuable line in the
file: `run_after_generate-shell-init.sh` survives `8fe3a71` intact, so the
dependency is unchanged and must not be lost in the rewrite.

### 2. Invariants

- **I1** (apply-time, not launch-time) — unchanged.
- **I2** (idempotent by construction) — narrow, do not remove. Its guard list
  reads "(`command -v`, `run_once`, `run_onchange` hashes)"; only the first
  survives. `install.sh` is re-runnable because every step is
  `command -v`-guarded, which is exactly what I2 asserts.
- **I3** (Tools are data — "the package set lives in
  `.chezmoidata/packages.yaml`; the installer is a renderer over it") —
  **withdrawn**, per the user's answer to Q2. Mark it withdrawn **in place**,
  with the commit and date and a one-line reason. Do not delete the line and
  renumber: I1–I4 are cited by number, including by the epic's own acceptance
  boxes, and a silently vanished I3 reads as a numbering error.
- **I4** (never fail the whole apply) — unchanged, and now the property the
  epic most depends on, since it is one of the two Q2 kept.

### 3. Acceptance — four boxes in, four boxes out

W0.3 restored these four from the pre-conversion text hours ago. **Do not
delete any box.** Two need work, two do not:

- **Box 1** (end to end: clone → apply → every tool on PATH) — keep. Re-point
  it at the real entry point: the fresh-machine path is `install.sh`, which
  ends by calling `chezmoi apply`.
- **Box 2** (a second apply reports zero changes) — the box is still closable;
  its clause list is not. It enumerates "`run_once_before` skipped by its
  stamp, the `run_onchange` installer skipped because the `packages.yaml`
  sha256 is unchanged, `run_after` re-running to byte-identical output". Only
  the third clause survives. Narrow the list to what exists — a second
  `install.sh` on a provisioned machine installs nothing, and
  `run_after_generate-shell-init.sh` re-runs to byte-identical output. This is
  a repair of the box, not a replacement of it; it still proves I2.
- **Box 3** (adding one tool is a single edit to `.chezmoidata/packages.yaml`)
  — **unclosable; replace it.** It was I3's proof and I3 is withdrawn. The
  satisfiable form of the same intent: adding one tool to the base is a single
  edit to `install.sh`'s package list — `git diff` after the change touches no
  other file, and the next run installs it. Note in the box that it now proves
  I2 rather than I3, or the box cites a withdrawn invariant.
- **Box 4** (apply survives a hostile machine, exits 0 with one package made
  unresolvable) — keep unchanged. It proves I4, which Q2 explicitly kept, and
  `install.sh` already satisfies it (`set -uo pipefail` with no `-e`; every
  failure path calls `warn` and continues).

### 4. Out of scope section

Unchanged. All four exclusions still hold.

## Acceptance
- [x] The file names none of `.chezmoidata`, `packages.yaml`, `run_onchange`,
      `run_once`, `sha256`.
- [x] It names `install.sh`, cites `8fe3a71`, and names
      `run_after_generate-shell-init.sh`.
- [x] The link to `04-shell/01` survives.
- [x] I1, I2, I3 and I4 all still exist as numbered boxes, and I3 is marked
      withdrawn in place with its reason.
- [x] The Acceptance section still holds exactly four boxes.
- [x] No acceptance box turns on `packages.yaml`; the "adding one tool" box
      turns on `install.sh`; the hostile-machine box survives.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check06.sh`
      exits 0.

**Proven RED 2026-08-21**: check06 exits 1 with 11 failures — all five dead
identifiers present; `install.sh`, `8fe3a71`,
`run_after_generate-shell-init.sh` and any I3 withdrawal absent; the acceptance
section still turning on `packages.yaml`. The 4-box count, the `04-shell/01`
link and the I1/I2/I4 boxes already pass, so those assertions are regression
guards for exactly what W0.3 restored.

verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check06.sh`
