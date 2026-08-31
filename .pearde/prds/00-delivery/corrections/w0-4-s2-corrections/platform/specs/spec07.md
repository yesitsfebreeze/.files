# spec07 — homebrew-bootstrap: the capability survives, the stage does not

Folded into W0.4f rather than routed out: it is the same one-line mechanism
swap as spec03/spec06, in the third child of the same epic, and the file is in
nobody else's footprint. Leaving it would make P.3 contradict its own parent
after spec03 lands. Est: **0.3h**

## Files touched
- `.mi/prds/05-platform/02-package-provisioning/homebrew-bootstrap/prd.md`
  (only)

## Goal

R3 reads: "**Homebrew first.** `run_once_before` installs Homebrew on a fresh
macOS machine; later stages must re-`eval "$(brew shellenv)"` because the new
brew is not yet on PATH in the same apply."

The **capability is intact** — `install.sh` §1 installs Homebrew when `brew`
is missing and immediately re-evaluates `brew shellenv` — so R3 is kept, not
withdrawn. Only its mechanism moved: `run_once_before_install-homebrew.sh.tmpl`
was deleted by commit `8fe3a71` (2026-08-19). Restate R3 against `install.sh`,
keeping the PATH reason verbatim in substance; it is the same constraint
`01-deploy-mechanism` R6 carries after spec02, and the two must agree.

Also retitle the node heading, "run_once homebrew bootstrap", which names a
chezmoi stage that no longer exists. **Do not rename the directory** — the
path is the node id, and `02-package-provisioning`'s allocation list and
`plan.json`'s P.3 both cite it.

## Acceptance
- [x] R3 still exists as a numbered box — the capability is kept.
- [x] The file names neither `run_once` nor `run_once_before`.
- [x] It names `install.sh` and cites `8fe3a71`.
- [x] The `brew shellenv` PATH re-resolve reason survives, and does not
      contradict `01-deploy-mechanism` R6 after spec02.
- [x] The `#` heading no longer names a chezmoi stage; the directory name is
      unchanged.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check07.sh`
      exits 0.

**Proven RED 2026-08-21**: check07 exits 1 with 4 failures — `run_once`
present in both R3 and the heading; `install.sh` and `8fe3a71` absent.

## Ordering
After spec02, so R6 and R3 are written against the same wording of the same
constraint.

verify: ""

## Spent proof

`run_once_before` reappears in
`prds/05-platform/02-package-provisioning/homebrew-bootstrap/prd.md:52`,
inside the `## Absorbed by P.2 — 2026-08-21` section the orchestrator added
after this node closed to record that the stage was deleted by `8fe3a71`.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check07.sh`
```
