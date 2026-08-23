---
state: done
claim:
priority: 28
est: 5h
task: S.4
mode: afk
needs:
  - 04-shell/08-claude-launchers
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/decisions/fzf
  - 06-help/01-content-model
verify: "bash tests/shell-zoxide.sh"
---

# Zoxide navigation

Parent: [Nushell epic](../prd.md) · C 4 · U 9 · sources: "Zoxide navigation
suite" (C 4 / U 9, dominant — R1–R4) + "Bare-word zoxide fallback"
(C 7 / U 8 — R5–R7), both in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

*Source list corrected 2026-08-21 from backlog row **M-5**: the header rated
this node C 5, a number neither entry carries. A merged PRD takes the dominant
entry's rating and lists every source with its own numbers.*

Purpose: Zoxide is the primary way to move: explicit jumps (`z`/`zi` and
friends) and the signature implicit form — typing a bare directory name jumps
to it.

## Requirements

### Wrappers

- [~] **R1** — **`z`** wraps `__zoxide_z`: a single arg that resolves to an
      existing *file* opens in `$EDITOR` instead of jumping; otherwise it's a
      dir query. Dir jumps log to quicklist recents only when PWD actually
      moved; file opens always log.
- [~] **R2** — **`zi`** (and the `cdi` alias) — interactive picker, same
      recents logging as R1. It shells out to `zoxide query --interactive`,
      which spawns **fzf**; it is *not* rewritten against a tv-backed
      picker. This is the one accepted exception to the epic's
      [I3](../prd.md) "tv owns every picker screen", decided 2026-08-21
      (user) — reimplementing zoxide's frecency ranking behind a cable file
      buys one consistent screen at the cost of owning the ranking, and the
      exception is documented in `help` rather than left as a surprise.
- [x] **R3** — **Composed verbs.** `zz` = `cd -` (back-toggle, pairs with the
      fallback), `zl` = jump then `la`, `zc` = jump then Claude (`cc`).
- [x] **R4** — **Funnel compliance.** All jumps go through the `cd` alias →
      `mkcd` inside `__zoxide_z`, so start dir + dirstack update like any
      move.

### Bare-word fallback

- [x] **R5** — **Trigger.** A line whose first token is not a known command,
      contains no shell/nu metacharacters, and is not path-shaped (`-`/`/`/`~`
      prefix, embedded `/`, bare `.`/`..`) is treated as a zoxide query. A
      dot-NAME like `.files` stays a valid target.
- [x] **R6** — **Jump only on a genuine match.** Query `zoxide query --exclude
      $PWD` directly rather than calling `__zoxide_z`; no match → the normal
      "command not found", untouched. The requirement is right, but the
      reason recorded for it was not (backlog **M-8**): the hazard is
      **`mkcd`**, not `__zoxide_z`. A no-match `zoxide query` returns the
      empty string, `__zoxide_z` hands that to the `cd` alias, and `mkcd`
      reads an empty argument as "no argument" and targets `$env.HOME`.
      Attributing it to `__zoxide_z` sends the fix to the wrong file.
- [~] **R7** — **Mechanics.** Jump from `pre_execution` (cd persists there),
      mark `$env._NAV`, and clear the screen in `pre_prompt` to bury the
      doomed error — the fresh prompt in the new dir is the confirmation. Log
      dirstack + recents at jump time (the PWD hook may not fire from
      pre_execution).

## Acceptance
- [~] `z somefile.txt` opens the editor; `z proj` jumps; failed `z nomatch`
      leaves PWD alone and logs nothing. **This is work to prove, not
      behaviour to preserve:** live, the `mkcd` mechanism of R6 (**M-8**)
      moves PWD to `$env.HOME`, and because PWD did move, that HOME is then
      logged to the quicklist recents as well. It is the first finding in the
      header of `home/dot_config/nushell/help/use-review.nuon`, filed against
      this node, and it is on no live-bug list.
- [x] `proj` ⏎ (bare) lands in the project dir with a clean screen; `zz`
      returns.
- [x] `ls | something-unknown` and `./x` never trigger the fallback.

*Checked 2026-08-22 by `bash tests/shell-zoxide.sh` (72 PASS, EXIT=0): the
M-8 boxes hold — a failed `z`, a cancelled `zi` and a no-match bare word
all leave PWD, startdir.txt and dirs.txt untouched. The `[~]` boxes are the
recents-logging clauses of R1/R2/R7 and the first acceptance line: their
four `_recents_add` call sites are real and placed, but the logger is the
D2 no-op shim until [`07-quicklist`](../07-quicklist/prd.md) sources the
real one above zoxide.nu and deletes the shim (the hand-off is written in
`home/dot_config/nushell/zoxide.nu`'s header). They close `[x]` there, not
here.*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
