---
atomic: check-what-apply-left-behind
subject: "`chezmoi apply` left all four deleted files deployed, so the deletion was true of the repo and false of the machine, and one of them kept a picker channel pointing at a function that was gone"
date: 2026-09-02
updated: 2026-09-02
runs: 3
---

## Do

1. After deploying, test for each file the change deleted at its DEPLOYED
   path, not its source path.
2. For anything still present, find what would still read it — a picker
   channel, a `source` line, a lane in a launcher.
3. Give the retirement a mechanism the repo carries. For chezmoi that is
   `.chezmoiremove` in the source root — one target path per line,
   relative to `$HOME`, no leading `./`. A hand `rm` fixes the machine in
   front of you and no other. A **scoped** apply does process it; it is
   not skipped just because the apply names paths.
4. Prove the mechanism fires rather than asserting it: plant the deleted
   file's original bytes back at its deployed path
   (`git show HEAD:<source path> > <deployed path>`), re-apply scoped,
   and confirm it is gone.

## Done when

- Every deleted source file is absent from the deploy target.
- The retirement survives a second deploy from a clean checkout.

## Fails when

- The retired target no longer matches what the deploy tool last wrote —
  locally edited, or re-created after a successful removal, which makes
  the tool forget the entry. chezmoi then **prompts**
  (`… has changed since chezmoi last wrote it?`) and headless that is not
  a skip: `could not open a new TTY: open /dev/tty: device not
  configured`, exit 1 for the whole apply. A green CI apply can go red on
  one user's machine for a file being deleted. Answer it with `--force`
  where the retirement is intended, and assert each target's absence
  afterwards rather than trusting the apply's exit code. Measured
  2026-09-02 on chezmoi in this repo.
