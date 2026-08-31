# spec02 — 01-deploy-mechanism R6: keep the reason, drop the dead framing

Est: **0.4h**

## Files touched
- `.mi/prds/05-platform/01-deploy-mechanism/prd.md` (only)

## Goal

R6 currently reads:

> **Script ordering contract.** chezmoi runs `run_once_before` → package
> installer (`run_onchange`) → `run_after`. Anything depending on an installed
> tool must live in a later stage than the install, and stages must re-resolve
> PATH because a tool installed this run isn't on it yet.

Two of those three stages do not exist. Commit `8fe3a71` (2026-08-19,
*"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal chezmoi, one
plain install.sh"*, an ancestor of the live HEAD) deleted
`home/run_once_before_install-homebrew.sh.tmpl` and
`home/run_onchange_install-packages.sh.tmpl`. The live source's `home/` holds
exactly one script: `run_after_generate-shell-init.sh`.

Rewrite R6 so the **constraint** survives and the **framing** goes. The
constraint is the expensive knowledge (AGENTS.md: "carry those into
requirements as constraints *with their reason*"); the three-stage pipeline was
only the shape it happened to take.

New R6, in substance:

> **R6 — Install before use, and re-resolve PATH.** Anything that depends on
> an installed tool must run after the install, and must re-resolve PATH
> before using it: a tool installed during this run is not on the PATH the
> run inherited. Homebrew is the canonical case — its own installer puts
> `brew` somewhere the current shell has never looked, so `brew shellenv`
> must be re-evaluated in the same run before anything brew-installed is
> called.
>
> The live shape satisfies this by construction: `install.sh` installs
> everything (§1–§4) and calls `chezmoi apply` **last** (§7), so
> `run_after_generate-shell-init.sh` — the only script left in `home/` — runs
> with every tool already on PATH. R6 previously specified a
> `run_once_before` → `run_onchange` → `run_after` chezmoi pipeline; commit
> `8fe3a71` (2026-08-19) deleted the first two stages, and the ordering
> contract narrows to the reason it existed for.

Then update the **Allocation** list: R6's line still reads "a contract
spanning every child", which stays true. No other requirement in this file
changes.

## Acceptance
- [x] R6 still exists as a numbered box — it is narrowed, not deleted, because
      other documents cite requirements by number.
- [x] The file names neither `run_once_before` nor `run_onchange` anywhere.
- [x] The PATH re-resolve reason survives, with `brew shellenv` kept as its
      concrete case.
- [x] The file names `install.sh` as where installation moved to, and
      `run_after_generate-shell-init.sh` as the one script left in `home/`.
- [x] Commit `8fe3a71` is cited, so the narrowing is auditable rather than
      looking like drift.
- [x] `bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check02.sh`
      exits 0.

**Proven RED 2026-08-21**: check02 exits 1 with 6 failures (`run_onchange` and
`run_once_before` both present; `run_after_generate-shell-init.sh`, `8fe3a71`,
`install.sh` and `shellenv` all absent).

## Do not
- Touch the acceptance box about `just push` / `just cutover` — amended today
  by the conductor and correct as it stands.
- Touch `05-platform/prd.md`. Invariant I3 needs to come down with this, but
  the epic file is not in this ticket's footprint (see the analyst report).

verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/check02.sh`
