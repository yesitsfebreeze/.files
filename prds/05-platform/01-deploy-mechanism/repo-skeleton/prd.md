---
state: done
priority: 47
est: 3h
task: P.1
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: "bash tests/deploy-skeleton.sh"
---

# Repo skeleton: chezmoi source layout, home/, justfile

Parent: [`01-deploy-mechanism`](../prd.md) · source:
[`01-deploy-mechanism`](../prd.md) requirements R1, R3, R5
**Scheduled first (priority 100, set 2026-08-21).** Not for its own sake: it
is what `00-delivery/verification-gates` waits on, and until that node closes
this repository has no gate runner at all — no `justfile`, no `Makefile`, no
`package.json`, and a `tests/` holding two single-purpose scripts. Every
acceptance box in the tree phrased "the wave gate passes" is therefore
uncloseable by construction, and nothing on the board can be closed with
proof. This node and the gates node are the two that end that, so they sort
ahead of the work that will need them.


## Requirements
- [x] **R1** — **Source layout.** `home/` holds the managed tree
      (`dot_config/`, `dot_gitconfig.tmpl`, `run_*` scripts, `.chezmoidata/`),
      with the repo root carrying the `justfile` and docs.
      *Met 2026-08-21.* `.chezmoiroot` = `home`, so the source dir is
      `home/` and every root entry stops being a target by construction:
      `--apply` asserts none of `AGENTS.md`, `CLAUDE.md`, `.mi`, `tests`,
      `vicky`, `justfile`, `.chezmoiroot`, `home` reaches the target
      (`leaked:<none>`) while `home/dot_config/**` does, and the `justfile`
      is at the root. The per-file contents (`run_*`, `.chezmoidata/`,
      `dot_gitconfig.tmpl`) are P.2–P.5's; this node makes the root.
- [x] **R3** — **Apply.** `chezmoi apply` is the single deploy step and must
      be idempotent — a second apply changes nothing.
      *Met 2026-08-21.* `chezmoi apply --force --verbose` immediately after
      the first prints nothing, and `chezmoi status` prints nothing.
      *Amended 2026-08-21: both are now run with `--exclude=always`.*
      [`03-shell-init-generation`](../../03-shell-init-generation/prd.md)
      added `home/run_after_generate-shell-init.sh`, and chezmoi reports an
      always-run script on every apply **by design** — so the unfiltered
      command stopped reproducing this evidence the moment that landed.
      `--exclude=always`, not `--exclude=scripts`: the wider flag also hides
      an *unrun* `run_once_`/`run_onchange_` script, and one of those
      reappearing is a real defect. The requirement is unchanged; only the
      recorded command is.
- [x] **R5** — **Push recipe, and a separate cutover.** `just push` is
      **git only**: stage, commit, push. It must not deploy, init, or repoint
      anything.
      *Amended 2026-08-21 (user).* R5 previously read "One `just push`: init
      from this source, apply, commit, push, then update", mirroring the live
      workflow. That shape makes the recipe typed daily for its git half also
      perform the **cutover** — silently repointing this machine's chezmoi
      source from `~/dev/.files` to this repo. Nothing is destroyed (chezmoi
      never removes unmanaged files) but ownership persists, and through all of
      Wave 1 the managed tree is a handful of files. The cutover therefore
      moves to its own named recipe, `just cutover`, carrying the hazard in its
      doc comment. An interactive confirm was rejected: it would make the
      recipe ungateable.
      *Met 2026-08-21.* `push message="dotfiles: update"` is add / guarded
      commit / push and nothing else; `cutover` is its own recipe with the
      hazard in its doc comment; no confirm. Two independent proofs that
      `push` never deploys: the recipe-body lint, and a poison `chezmoi`
      shim (exit 97, logs on call) that never fired across two runs.
- [x] **R7** — **Gates never touch the live chezmoi config.** Every `chezmoi`
      invocation in a gate passes `--config`, `--config-path` (init only),
      `--destination`, `--persistent-state` and `--cache` explicitly.
      **`HOME` does not isolate chezmoi** — this was found the expensive way:
      a scratch-`HOME` `chezmoi init --force` rewrote the real
      `~/.config/chezmoi/chezmoi.toml` and repointed the live machine at a
      throwaway repo. The gate must assert the live config's hash and
      `chezmoi source-path` are unchanged on exit, so dropping a flag turns it
      red on the damage itself rather than on a lint.
      *Met 2026-08-21.* One `cz()` helper carries all five flags; the
      cutover shim adds `--config-path` for `init` only; a structural lint
      rejects a bare `chezmoi` in command position; and the guard runs in
      all three stages. Both counterfactuals were **run**, not asserted:
      armed at a copy of the config with the copy mutated mid-run, the stage
      prints `FAIL: … LIVE chezmoi.toml unchanged` and exits 1; a bare
      `chezmoi` appended to the script turns the lint red and exits 1.

## Acceptance
- [x] chezmoi apply on a scratch target is idempotent (second apply is a
      no-op) — `bash tests/deploy-skeleton.sh --apply`, exit 0; both the
      second `apply --verbose` and `status` printed nothing
- [x] `just push` round-trips a local edit to the remote and back out of a
      fresh clone, without the live machine ever being cut over — nonce in
      `remote.git main:home/dot_config/dot_p1-roundtrip`, in the reclone, and
      deployed from the reclone to `<dest>/.config/.p1-roundtrip`; live
      `source-path` still `/Users/feb/dev/.files/home` on exit
- [x] `just push` performs no deploy: proved with a poison `chezmoi` on `PATH`
      that fails loudly if the recipe calls it — the shim never fired, over
      two runs (one with a change, one with nothing to commit)
- [x] `just cutover` exists as its own recipe and is the only path that
      repoints the source — `just --list` inside the repo names it, and it
      is the only recipe body containing `chezmoi`; renaming it turns
      `--cutover` red (`FAIL: cutover: a 'cutover' recipe exists`, exit 1)
- [x] After every gate stage, `~/.config/chezmoi/chezmoi.toml` is byte-identical
      and `chezmoi source-path` is unchanged — sha256
      `02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1` in
      and out of all three stages; `source-path` = `/Users/feb/dev/.files/home`

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Notes

 Footprint narrowed: P.1 creates the skeleton and the chezmoi root, not the
      managed files inside it. Each per-app config dir is owned by its own
      track (nushell/ by S.x, nvim/ by E.x, wezterm/ by T.x, help/ by H.x) — a
      wholesale home/ claim made every nested write invisible to the
      string-equality collision check.

## Closing note

*Closed 2026-08-21 by the orchestrator.* **The first real implementation on the
board.** `bash tests/deploy-skeleton.sh` → **53 PASS, 0 FAIL**, exit 0, re-run
independently. Five files created: `.chezmoiroot`, `home/.chezmoiignore`,
`home/.chezmoi.toml.tmpl`, `justfile`, `tests/deploy-skeleton.sh`.

**Every guard was observed failing, not assumed.** `.chezmoiroot` moved aside →
`leaked: AGENTS.md CLAUDE.md tests vicky justfile home`; `push`→`pushx` and
`cutover`→`cutoverx` each caught; a bare `chezmoi` appended to a copy of the
script caught by the lint with its line number; and the live-config guard armed
against a *copy* and mutated mid-run went red on the hash. Two real bugs in the
gate were found **by** those counterfactuals rather than by inspection: a
command substitution clobbering `$?` so the lint printed PASS while failing,
and `grep -q '^ *push'` being satisfied by `pushx`.

**The live chezmoi config was never touched**, verified before, during and
after every stage and again by the orchestrator: `~/.config/chezmoi/chezmoi.toml`
sha256 `02d5d4ee…c850a1` unchanged, `chezmoi source-path` still
`/Users/feb/dev/.files/home`. R7 exists because the opposite happened during
analysis — `HOME` does not isolate chezmoi.

The user's cutover decision is enforced by mechanism, not comment: `just push`
is git-only, checked by a body lint **and** by running it with a poison
`chezmoi` on `PATH` that exits 97 if called.

**Orchestrator follow-up applied after closing:** `just` renders only the last
line of a multi-line doc comment, so `cutover` listed as
`# almost none of it. Type this on purpose.` and `push` as an orphaned clause —
the hazard was invisible in `just --list`, which undercuts the very
deliberateness the decision was made for. `[doc('…')]` attributes were added to
both recipes; `just --list` now shows `DANGER: hands this machine over to this
repo. One-time, deliberate.` and `Git only — does NOT deploy or change
ownership.` The gate was re-run after the edit: still 53 PASS, 0 FAIL.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`tests/deploy-skeleton.sh:212` asserted that `gates/justfile` is **absent**, as
its way of proving the root justfile's `import? 'gates/justfile'` is genuinely
optional — a fresh clone without `gates/` must still work.
[`verification-gates`](../../../00-delivery/verification-gates/prd.md) (G.1)
then created that file, correctly, and the assertion began failing on another
node's success.

It is **superseded, not violated.** The property still holds and is now checked
properly, by [`gate-reconciliation`](../../../00-delivery/corrections/gate-reconciliation/prd.md)
(W0.8): a scratch copy of the **real** root justfile with `gates/` removed must
still `just --list` at exit 0, a non-optional `import` in the same position must
go **red**, and restoring `gates/justfile` must make the imported recipe appear.
That is strictly stronger than the original, which only ever asserted a file was
missing and became unrunnable the moment the file legitimately existed. The
stage went from 1 assertion to 4.

**Do not delete `gates/justfile` to make the old form pass.**
