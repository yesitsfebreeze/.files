---
kind: routine
name: stage-the-extraction-in-a-throwaway-project
description: "the five scripts read as one bash set and two of them are python3; staging them from `git show` in a temp directory turned a relocatable set into a measured one, and surfaced the call back into the shell config they were leaving"
read_when: "executing stage-the-extraction-in-a-throwaway-project"
---

# stage-the-extraction-in-a-throwaway-project

_Origin: `pearde/workflows/stage-the-extraction-in-a-throwaway-project.md` (workflow subject: ""the five scripts read as one bash set and two of them are python3; staging them from `git show` in a temp directory turned a relocatable set into a measured one, and surfaced the call back into the shell config they were leaving"")_


## Do

1. Only when the cut is really a move — something leaves for a new home
   rather than ceasing to exist. Build the destination before the deletion
   is real: `mktemp -d`, then write each file out at its deployed mode.
   Take it from the **working tree**, not from the commit, unless you have
   just proved they are the same: `git show HEAD:<p> | wc -c` against `wc -c
   <p>` against `wc -c <deployed path>`, for every file. A file whose
   worktree and deployed bytes agree with each other but not with `HEAD` is
   carrying uncommitted work that only the machine holds, and the deletion
   this move is part of is what destroys it. Measured 2026-09-02 by
   09-simplify/08-litellm-out: `cll` was 12005 at `HEAD` and 12952 in both
   the worktree and the deploy — 947 bytes of proxy auto-start that `git
   show HEAD:` would have silently dropped on the floor.
2. Parse each staged file under its OWN interpreter, read off its shebang —
   never under the one the directory suggests.
3. Put the staged directory on PATH and run the entry point the way a person
   runs it. Watch how the pieces find each other: through PATH, or through a
   directory that is about to stop existing.
4. Grep the staged copy for every path and command that reaches back into
   the repo it is leaving. Those are the couplings the move does not fix,
   and they belong written down in the new project, not left silent.

## Done when

- Every staged file parses under its own interpreter.
- The entry point runs from the staged directory and exits 0.
- Every reach-back into the repo being left is named.

## Fails when

- A directory-wide `bash -n` over `bin/*`. Two of the five files carried
  python3 shebangs (`litellm-gen-config`, `llm-quota`) and reported syntax
  errors that were not there — `HOME = os.path.expanduser("~")` read as
  `syntax error near unexpected token '('`. Branch on the shebang:
  `python3 -m py_compile` for those, `bash -n` for the rest.
- A guard written `timeout 20 <cmd>`. macOS ships no `timeout(1)`, so the
  probe exits 127 and the run reads as the command failing when it never
  ran. Let the tool's own fast-fail be the guard.
- Trusting a paper reading of self-containment. `cll` resolves its sibling
  through PATH (`. "$(dirname "$(command -v litellm-env)")/litellm-env"`),
  which does survive the move — but 180 lines further down it execs
  `nu -c 'source ~/.config/nushell/config.nu; cc …'`, a call straight back
  into the repo it was leaving. Only running it from the staged directory
  and grepping the staged bytes found the second one. Measured 2026-09-02
  by 09-simplify/08-litellm-out.
- The staging probe reads `HEAD` and the spec repeats it, so both agree and
  both are wrong. Two sources agreeing is not a measurement when they share an
  assumption. Compare against the deployed bytes, which is the third,
  independent witness.
