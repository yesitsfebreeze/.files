---
complexity: 8
footprint:
  - home/dot_config/television/cable/git-deletions.toml
  - home/dot_config/television/cable/git-diff.toml
  - home/dot_config/television/cable/git-reflog.toml
  - home/dot_config/television/cable/git-remotes.toml
  - home/dot_config/television/cable/git-repos.toml
  - home/dot_config/television/cable/git-stash.toml
  - home/dot_config/television/cable/git-submodules.toml
  - home/dot_config/television/cable/git-tags.toml
  - home/dot_config/television/cable/git-worktrees.toml
  - home/.chezmoiremove
---

# spec01 — the live cable directory and the chezmoi source list the same files

Q1 is answered: keep the git ones, drop the rest. Nine `git-*` channels are
adopted into `home/dot_config/television/cable` so this repo owns them and a
fresh machine gets them; four — `bg`, `burrito-sessions`, `opacity`,
`opencode-sessions` — are retired from the machine through
`home/.chezmoiremove` plus a scoped `chezmoi apply` naming each target path.
Both sides end at nineteen files with the same names.

**This is already built and standing in the working tree, uncommitted.** The
nine files are copied into the source, four lines are appended to
`.chezmoiremove`, the applies have run, and
`probe/verify.sh` passes twice at `rc=0`. What is left is to commit. The nine
adopted files were checked for portability before adoption: none contains an
absolute `/Users/feb/...` path, and their declared `requirements` are only
`git`, `fd`, `rg` and `bat`, all of which the Brewfile already carries — so
they travel to a fresh machine as they stand and need no rewrite.

**Nine, not seven.** The answer's prose says "the seven git searches"; there
are nine `git-*` files among the thirteen. The PRD's own anchor comment
already records the miscount and names all nine — `git-deletions` and
`git-submodules` were the two omitted. Adopt nine.

**The removal mechanism, as measured rather than as assumed.** The PRD's
premise paragraph says chezmoi has forgotten the entries for these thirteen
and that an apply would therefore prompt and fail at exit 1 without `--force`.
That is false here and was measured: `chezmoi state dump` holds an
`entryState` for every one of the thirteen with a `contentsSHA256` matching
the live file byte for byte, so each removal is the quiet case — silent, exit
0, no prompt, no controlling terminal needed, no `--force`. `--force` is
harmless and may stay for safety, but nothing depends on it. A canary planted
at a path with no state entry at all (`probe/canary.sh`) was also removed
silently at exit 0, so neither shape produces the loud failure the premise
predicted.

**Scoped, never bare.** The working tree holds around twenty unrelated
modified files. Name each target path to `chezmoi apply`, one per invocation;
never run it bare, and never apply `.chezmoiremove` itself or the directory
above the targets.

**What must not change.** The ten channels the repo owned after `9b80a71`
(`dirs`, `docs`, `files`, `git-log`, `nu-history`, `quicklist`, `recent-dirs`,
`recent-files`, `text`, `theme`), and 06's five retirements plus 04's four.
`probe/verify.sh` checks both.

## Acceptance

- [x] `bg.toml`, `burrito-sessions.toml`, `opacity.toml` and
      `opencode-sessions.toml` are absent from `~/.config/television/cable`,
      asserted by testing each path, not by reading an apply's exit code.
- [x] Each of those four paths appears once in `home/.chezmoiremove` as
      `.config/television/cable/<name>.toml`.
- [x] All nine `git-*` channels named in this spec's footprint exist in
      `home/dot_config/television/cable` and are byte-identical to the
      deployed copy under `~/.config/television/cable`.
- [x] No adopted file is also listed in `home/.chezmoiremove`.
- [x] `ls ~/.config/television/cable | sort` and
      `ls home/dot_config/television/cable | sort` print the same nineteen
      names.
- [x] The ten channels the repo owned after `9b80a71` are still present on
      both sides, and none of 06's or 04's earlier retirements has returned.
- [x] `probe/verify.sh` exits 0 on two consecutive runs and stages nothing.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash .pearde/prds/09-simplify/retire-the-unmanaged-television-channels/probe/verify.sh
bash .pearde/prds/09-simplify/retire-the-unmanaged-television-channels/probe/verify.sh
test -z "$(git diff --cached --name-only)"
diff <(ls ~/.config/television/cable | sort) <(ls home/dot_config/television/cable | sort)
```
