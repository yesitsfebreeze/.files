# Feature: Zoxide navigation

Parent: [Nushell epic](00-epic.md) · C 4 · U 9 · sources: "Zoxide navigation suite"
(C4 U9 — dominant) + "Bare-word zoxide fallback" (C7 U8) in
capabilities-nushell.md

## Summary

Zoxide is the primary way to move: explicit jumps (`z`/`zi` and friends) and
the signature implicit form — typing a bare directory name jumps to it.

## Requirements

### Wrappers

1. **`z`** wraps `__zoxide_z`: a single arg that resolves to an existing
   *file* opens in `$EDITOR` instead of jumping; otherwise it's a dir query.
   Dir jumps log to quicklist recents only when PWD actually moved; file
   opens always log.
2. **`zi`** (and the `cdi` alias) — interactive picker, same recents logging.
3. **Composed verbs.** `zz` = `cd -` (back-toggle, pairs with the fallback),
   `zl` = jump then `la`, `zc` = jump then Claude (`cc`).
4. **Funnel compliance.** All jumps go through the `cd` alias → `mkcd`
   inside `__zoxide_z`, so start dir + dirstack update like any move.

### Bare-word fallback

5. **Trigger.** A line whose first token is not a known command, contains no
   shell/nu metacharacters, and is not path-shaped (`-`/`/`/`~` prefix,
   embedded `/`, bare `.`/`..`) is treated as a zoxide query. A dot-NAME like
   `.files` stays a valid target.
6. **Jump only on a genuine match.** Query `zoxide query --exclude $PWD`
   directly (never `__zoxide_z`, whose no-match would cd HOME); no match →
   the normal "command not found" untouched.
7. **Mechanics.** Jump from `pre_execution` (cd persists there), mark
   `$env._NAV`, and clear the screen in `pre_prompt` to bury the doomed
   error — the fresh prompt in the new dir is the confirmation. Log dirstack
   + recents at jump time (the PWD hook may not fire from pre_execution).

## Acceptance criteria

- `z somefile.txt` opens the editor; `z proj` jumps; failed `z nomatch`
  leaves PWD alone and logs nothing.
- `proj` ⏎ (bare) lands in the project dir with a clean screen; `zz` returns.
- `ls | something-unknown` and `./x` never trigger the fallback.
