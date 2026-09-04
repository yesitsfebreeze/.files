# the pearde guard hook is wired into the harness — implementer report

Verdict: BLOCKED

spec01 closed and committed (3/3). spec02's code is done and verified, but
its last box — committing the two files — is refused by the repo's own gate,
and overriding that gate is the board's call, not mine.

## What is done

**spec01 — 3/3, all ticked, all run.**

`.claude/settings.json` committed on `lane/the-pearde-guard-hook-is-wired-into-the-harness`
as `836a925 the guard hook is wired into this repo's settings`.

```
$ pearde guard "$(pwd)"
  guard  ok  wired in .../.lanes/.../.claude/settings.json · MAX_THINKING_TOKENS=8000 · skill tree guarded
$ git status --short .claude/settings.json
(empty)
$ just board-guard the-pearde-guard-hook-is-wired-into-the-harness ".claude/settings.json"
rc=0
```

**spec02 — 2/3.** The two ticked boxes hold; the third does not:

```
$ grep -c "guard hook is wired" home/dot_config/nushell/help/shell.nuon             -> 1
$ grep -c "guard hook is wired" .../manual/guide/agents.md                          -> 1
$ just manual   -> guide: 14 pages / agents 20 blocks (21 entries); reference: 9 pages, 107 entries
                   no diff beyond the two files already changed
```

Both files sit uncommitted in the lane, content final.

## The wall

`just board-guard` refuses staging spec02's two paths:

```
$ just board-guard the-pearde-guard-hook-is-wired-into-the-harness \
    ".claude/settings.json home/dot_config/nushell/help/shell.nuon \
     home/dot_config/nushell/help/manual/guide/agents.md"
2 path(s) held by a live claim — none staged:
  home/dot_config/nushell/help/manual/guide/agents.md
      held by 09-simplify/08-litellm-out (failed)
  home/dot_config/nushell/help/shell.nuon
      held by 09-simplify/08-litellm-out (failed)
error: recipe `board-guard` failed on line 39 with exit code 1
```

`failed` is in `board-guard.py`'s `CONTENDING` set, so a failed node keeps
holding every path its `prd.md` and specs declare. `09-simplify/08-litellm-out`
declares `home/dot_config/nushell/help/shell.nuon` in `specs/spec01.md`, and its
own `## Failure` says: *"Superseded, not undone. … Not to be retried: the lane
`lane/09-simplify-08-litellm-out` must not merge."* Nothing will ever release
that hold on its own, and its paths are the two most-shared files on the board.

Precedent, not permission: `b560631` (2026-09-04 02:25) committed `shell.nuon`
and names 08-litellm-out's failure in its own message — the same crossing, made
without the gate being consulted.

**The question, for the orchestrator:** commit spec02's two files past the hold,
or first release it on the board — retire `09-simplify/08-litellm-out` out of
`CONTENDING`, or drop the two shared paths from its footprint? I did not touch
another PRD and did not override the gate.

## Defect outside scope — the PRD's second acceptance box is not satisfiable

> `- [ ]` Staging a path held by a `claimed` node in a fresh session is refused
> by the hook, not only by `just board-guard`.

The probe's own fixture says otherwise. Run as written:

```
$ bash prds/.../probe/claim-staging-fixture.sh
RESULT: not refused — guard.py pre allowed staging a path a live claim holds
```

This is by design, not a bug in the wiring. `@references/parts/guard.md`'s Bash
row covers `git reset --hard`, `checkout --`, `clean` and a real `stash` against
a tree the session does not own — it never reads a `git add`, and it reads the
*shape of the command*, not the board's claims over the paths in it. Refusing a
held path is `just board-guard`'s job and stays so. The box asks the hook for a
capability the hook does not have; it needs rewording (or a new PRD extending
`guard.py`), and neither is mine to do.

`specs/spec01.md` also misdescribes this fixture — it says it "shows the hook
itself refuses a hand-walked board read", which is not what the script tests.

## `pearde doctor` — still `off`, as spec01 predicted

```
$ pearde doctor /Users/feb/dev/dotfiles | grep guard
  guard  off  not wired in /Users/feb/dev/dotfiles/.claude/settings.json
```

Expected: the settings file exists only on the lane branch. This flips to `ok`
on merge, and PRD acceptance box 1 should be checked then, not now.

## Notes

- `.claude/settings.json` names the skill by two different absolute paths for
  the same file: `/Users/feb/dev/infra/pearde/resources/guard.py` for the three
  guard entries, `/Users/feb/dev/dotfiles/.claude/skills/pearde/resources/board/serve.py`
  for `SessionStart`. Both resolve through the install symlink to one file, and
  both were written by `pearde guard on`. Left as the tool wrote it.
- Health floor: no file in the footprint was under it; nothing moved.
- No grammar term was missing. No outside research was needed, so no
  `knowledge.py` entry was owed.
