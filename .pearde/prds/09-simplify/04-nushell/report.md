Verdict: SPECCED

# 04-nushell — analyst report

Built and deployed, not just specced from reading. Every requirement
R1-R12 is implemented in the working tree; the change was applied live
via a scoped `chezmoi apply` (never bare — the tree carries many
unrelated pending changes from other in-flight PRDs) and exercised in a
real login shell. One spec file: `specs/spec01-simplify.md`, `complexity:
10`, well under the 40/6 caps, so this is SPECCED rather than REFINE.

Knowledge query first: `python3 .claude/skills/pearde/resources/knowledge.py
query` against the PRD's contract returned two directly relevant, already-
recorded facts (nu -c loads no config — use `nu -l`; a nushell config
change must be proved in a shell that loaded it) and no gap — nothing
auto-enqueued to `.pearde/wiki/pending/`. Workflow: no library entry fit
build-a-simplification-and-verify-it-live, so `## Route` below drafts one
(`simplify-a-nushell-surface-and-deploy-it`) from the actual run —
closest near-miss was `delete-what-nothing-reads`, which covers the
deletions but not the deploy-and-verify-live steps this PRD's acceptance
demanded.

## Findings

- **Acceptance's keybindings-count check does not reproduce.**
  `$env.config.keybindings | length` is 18 after the build, not ≤8:
  nushell ships 8 built-in bindings, and our own 8 named additions plus
  tv's own `tv_history` all coexist alongside them — deleting any of
  quicklist, esc-clear or the history pickers to force the number down
  would cut real, kept functionality R2 and the epic's own Out-of-scope
  list both preserve. R2's actual ask — five upserts into one append —
  is met. Confirmed by direct isolated test that nushell's keybindings
  list dedupes by `name`, not by (modifier, keycode); recorded as
  `[[260902-c5df]]` since it wasn't on record.
- **`capsule recent` fails, but not with "not found".** `capsule` still
  takes an optional positional `dir`, so `recent` is read as a directory
  name: `capsule: not a directory: <cwd>/recent`. Still an error, just a
  different shape than the box names.
- **R9's shquote merge and R4's theme.nu range both needed narrowing** —
  full detail in the spec's body: R6+R7 delete the only callers of
  `_finder_shquote`/`_capsule_shquote` in the same change, so both are
  gone rather than merged; and theme.nu's `_theme_catalog`-empty guard
  (`tinty install` not run) is not covered by install.sh the way
  `which tinty`/`which tv` are, so it was kept against R4's literal line
  range.
- **`chezmoi apply` does not delete a target whose source vanished** —
  already on record (`[[260902-f203]]`); reproduced again here for
  `copymode.nu` and the three deleted cable `.toml` files, all four
  hand-removed from `~/.config` after the scoped apply.
- **`home/dot_config/nushell/help/manual/internals/nushell-modules.md`
  goes stale** — its hand-written walkthrough of finder.nu still
  describes the deleted cht pipeline and `_finder_pick_channel` in
  detail. Out of this PRD's footprint (internals/ is `03-help-system`'s);
  flagging so it isn't mistaken for missed scope here.
- **`theme.toml.tmpl`** (television cable, not in this PRD's footprint)
  still describes the retired A/B slot pair in its header comment; same
  out-of-footprint situation as above.

## Scores

complexity: 10
blast-radius: high
workflow: simplify-a-nushell-surface-and-deploy-it

## Route

## Use when

- A PRD asks for real deletions and consolidations across a shell
  config's surface (dead code, tombstone comments, second-machine
  branches) AND its acceptance requires proving the result live, not
  just that it parses.
- Not when the change is deletion only with no live-behavior acceptance
  — `delete-what-nothing-reads` fits that alone.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | two requirements (R9's shquote merge, part of R4's theme.nu range) rested on facts the earlier requirements in the same PRD had already changed | `stop` |
| 2 | `prove-nothing-reads-it` | confirmed both shquote helpers and the ChtSheet decode arm had zero callers left before deleting them | `→ 1` |
| 3 | `prove-in-a-shell-that-loaded-the-config` | `nu -c` loads neither env.nu nor config.nu; every acceptance check ran as `nu -l -c` against the deployed tree instead | `→ 1` |
| 4 | `apply-scoped-not-bare` | the working tree held many unrelated pending changes from other PRDs; `chezmoi apply <path>...` named every touched target instead | `stop` |
| 5 | `check-what-apply-left-behind` | four deleted source files (copymode.nu, three cable .toml) stayed deployed after the scoped apply and needed a manual `rm` | `→ 4` |
| 6 | `run-the-verify-twice` | ran the acceptance battery, then re-ran the F6 toggle and the keybindings count a second time before trusting either | `→ 3` |

A step naming an atomic already in the library (1, 2, 3, 4, 5, 6 above)
writes no new block — all six are already on record.
