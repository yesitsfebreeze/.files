# retire the unmanaged television channels — implementer

Verdict: DONE

Q1's answer landed. Nine `git-*` channels are adopted into
`home/dot_config/television/cable`, four are tombstoned in
`home/.chezmoiremove` and gone from the machine, and the two sides list the
same nineteen names. The transferred acceptance box is resettled from "at
most 15" to exactly 19 with `10 + 9 = 19` written next to it. Every spec box
is ticked against output quoted below; nothing is staged and nothing is
committed — the footprint is left dirty for `collect`, which is where this
board's commits are made.

**One red that is not this node's to fix, and `collect` must see it first.**
`just board-guard` refuses `home/.chezmoiremove`: it is held by a live claim
on `09-simplify/08-litellm-out` (`analyzing`, `claim analyst-router
2026-09-02 16:24`). That path is in this PRD's frontmatter footprint *and* in
08's `specs/spec01.md` footprint, so two concurrently-claimed nodes own one
file. See `## The board-guard collision` for the isolation and why the
guard's own advice does not apply. `just board-guard-blocks` exits 0.

| spec | boxes | verify |
|---|---|---|
| `spec01-reconcile-the-cable-directory.md` | 7/7 `[x]` | `probe/verify.sh` rc=0 twice, nothing staged, listings identical |
| `spec02-resettle-the-transferred-count.md` | 5/5 `[x]` | verify block prints `ok` |
| PRD `## Acceptance` | 1/1 `[x]` | machine 19, source 19 |

## spec01 — the cable directory reconciles

The build was standing uncommitted in the checkout from the analyst pass; this
pass verified it rather than rebuilt it, which is what `land-an-answered-fork`
step 1 asks for.

`chezmoi diff ~/.config/television/cable` prints nothing — the directory is
fully applied. The rest of the tree is still pending and untouched: six
unrelated modified files plus `generate-shell-init.sh`, `register-mcp.sh` and
`seed-mason-registry.sh` rendering as new files at `$HOME` root. Those three
are `run_after_*` scripts chezmoi executes, exactly the alarm the step 2
atomic tells you not to scope around.

`probe/verify.sh`, run 1 — 31 `ok`, no `FAIL`:

```
ok   bg.toml gone
ok   burrito-sessions.toml gone
ok   opacity.toml gone
ok   opencode-sessions.toml gone
ok   bg.toml tombstoned
...
ok   git-worktrees.toml adopted and deployed
ok   machine and source list the same files
ok   machine count is 19
ok   source count is 19
ok   06's theme.toml intact
ok   earlier retirements still retired

verify rc=0
```

Run 2 `rc=0`. `git diff --cached --name-only` is empty. The two listings:

```
$ diff <(ls ~/.config/television/cable | sort) <(ls home/dot_config/television/cable | sort)
identical (19 names)
```

The four tombstones appear once each, at lines 14–17 of
`home/.chezmoiremove`, and the diff of that file is exactly four appended
lines and nothing else:

```
+.config/television/cable/bg.toml
+.config/television/cable/burrito-sessions.toml
+.config/television/cable/opacity.toml
+.config/television/cable/opencode-sessions.toml
```

## The count the tool reports, and the count you own

Step 3 read the merged state out of the live program rather than the source.
`tv --version` is `television 0.15.9`.

```
machine dir count:      19
source dir count:       19
tv list-channels count: 23
```

All four Q1 drops are gone from `tv`'s own list; all nine adopted channels are
in it. The four-name gap is not drift, and it is not the built-in count either
— it is the built-ins the cable directory does not shadow:

```
$ diff <(tv list-channels|sort) <(ls ~/.config/television/cable|sed 's/\.toml$//'|sort) | grep '^<'
< bash-history
< docker-images
< env
< git-branch
```

Those four are what is left over, not the whole set. Measured against a fixture
holding an empty `television/cable` and nothing else, `tv` 0.15.9 compiles in
**ten** channel names — `bash-history dirs docker-images env files git-branch
git-diff git-log git-repos text`. A cable file whose name is one of the ten
shadows the built-in rather than adding a row, so

    len(tv list-channels) = 10 + files - shared

and the gap is `10 - shared`, which moves whenever an adopted or retired name
collides with a built-in. The formula reproduces both readings on record:

    23 files, shared 6 (dirs files git-diff git-log git-repos text) -> 27  ✓ the PRD's transfer measurement
    19 files, shared 6 (the same six)                               -> 23  ✓ measured above

The record on this board named two built-ins where there are ten and read the
gap as a constant; both under-count. Written back as `[[260902-f13a]]`, which
this pass then corrected after `ac8b3051118453706` refused the first version —
its empty-fixture measurement was right and mine was an artefact of reading the
gap on one directory only.

## spec02 — the transferred box

The box now asserts the machine count is exactly 19 and the source count is
the same 19, carries `10 + 9 = 19`, and says Q1's answer is what set it — not
a tuned threshold. It is exact rather than a ceiling, so 18 fails it as
readily as 20; the contract asks that the two sides agree, not that either
stay small.

```
$ machine count 19 ok
$ ok
```

`## Questions` and `## Answers` are untouched and the frontmatter is
untouched: `git diff -U0` on `prd.md` shows my edit as one hunk,
`@@ -79,7 +112,27 @@`, entirely inside `## Acceptance`. Every other hunk is
the orchestrator's Q1 write. The other modified PRD nodes in
`git status` — `05-terminal`, `08-litellm-out` and two new ones — are
concurrent siblings' work; this pass wrote to no file outside its own node
directory and its footprint.

Both this node's number and 06's two green clauses now read against a
directory of nineteen. 06's second clause,
`ls home/dot_config/television/cable | wc -l` at most 15, is therefore red as
of this landing. It belongs to 06 and was not touched — a finding for its
owner, restated here because this node is what moved the number under it.

## The board-guard collision

```
$ just board-guard 09-simplify/retire-the-unmanaged-television-channels "home/dot_config/television/cable home/.chezmoiremove"
1 path(s) held by a live claim — none staged:
  home/.chezmoiremove
      held by 09-simplify/08-litellm-out (analyzing, claim analyst-router 2026-09-02 16:24)
```

Isolated: the same guard over `home/dot_config/television/cable` alone exits 0
with no output, so `home/.chezmoiremove` is the sole cause.

The guard's advice — *"Name the paths instead of the tree, or pass the
exclusion set this prints"* — is written for a caller who named a directory
containing a held path. This caller named the exact file, and there is no
narrower name for it. The guard is red because two live claims genuinely own
one file, which is a dispatch decision, not something a worker inside either
node can resolve.

It is safe in content: this node appends four `television/cable` lines and 08
wants one `nushell/litellm.nu` line and asserts no `.local/bin/` path — the
two edits are disjoint appends to different regions of the same file and do
not conflict. What the orchestrator has to choose is whether `collect` stages
`home/.chezmoiremove` now or waits for 08's claim to clear. Not guessed here.

`just board-guard-blocks` exits 0.

## Manual drift

No `.nuon` was edited, so no generated page should move, and none did.

```
before: dc165e5a9664c0770d27bc0687a78d9ba7b3a111
after:  dc165e5a9664c0770d27bc0687a78d9ba7b3a111
IDENTICAL — no manual drift
```

`just manual` printed `reference: 9 pages, 106 entries` on that run, which it
prints whether or not anything changed; the shasum pair is what says nothing
drifted. The manual pages that *are* modified in `git status` were already so
before this pass — the identical shasums prove this pass moved none of them —
and belong to `05-terminal`.

## Health floor

The brief named no file under the floor, and none is. The nine adopted
channel files were carried in as they stand: none holds an absolute
`/Users/feb/...` path, and their declared `requirements` are only `git`,
`fd`, `rg` and `bat`, all already in the Brewfile.

## Grammar

Two words this node could not do without, and `grammar.py show` defines
neither on this board. Not invented here — reported so the word is coined
once rather than four ways:

- **tombstone** — a line in `home/.chezmoiremove` naming a target path, which
  makes a deployed file leave the machine on the next scoped apply. It is
  `probe/verify.sh`'s own word and the only short name for the thing.
- **adopt** — to move a file that exists only on the machine into
  `home/`, so chezmoi owns it and a fresh machine gets it. The PRD, both
  specs and Q1's options all lean on it.

## Workflow land-an-answered-fork

| # | step | outcome |
|---|---|---|
| 1 | `take-the-answers-not-the-stale-report` | pass, after a trap the atomic does not list — see edits |
| 2 | `apply-scoped-not-bare` | pass; `chezmoi diff` scoped clean, the rest of the tree still pending; the `run_after_*` alarm appeared as predicted |
| 3 | `read-the-merged-config-not-the-source` | pass; `tv list-channels` read from the live binary. First reading of the mechanism was wrong — corrected against an empty fixture, `10 + 19 - 6 = 23` |
| 4 | `rerun-the-drift-check` | `just manual` shasums identical, `board-guard-blocks` 0, `board-guard` **red** on a held path |
| — | back-edge 4 → 3 | taken once. Step 3 re-measured identical; the guard is red for a reason step 3 cannot reach, so it was not taken twice. Stopped and reported at step 4, per the brief. |

### Edits

**1 — `take-the-answers-not-the-stale-report`, `## Fails when` (currently
empty). Add:**

> - The brief names a lane worktree as the repo, and the lane holds its own
>   copy of `prd.md` cut before the fork was answered — `## Answers` empty,
>   `## Questions` absent, and no `specs/` at all. It reads as a node that
>   was never answered, which is the same failure as the stale `Verdict:`
>   line wearing different clothes. Measured 2026-09-02: the lane for
>   `09-simplify/retire-the-unmanaged-television-channels` was cut at the
>   orchestrator's HEAD and carried a `prd.md` two writes behind, while the
>   answer, the specs, the probe and the standing uncommitted build were all
>   in the orchestrator's checkout. Read `## Answers` from the board the
>   `pearde brief` command was run against, not from the lane; and when
>   every spec's `## Verify and Proof` block opens with a `cd` to a path
>   that is not the lane, that `cd` is the atomic's answer to which tree the
>   work is in.

**2 — `apply-scoped-not-bare`, `## Fails when`, the second bullet. The first
version of this edit was refused by `ac8b3051118453706` and withdrawn: it said
`tv` has four built-ins and the gap is a constant 4, which is an artefact of
measuring the gap on one directory. Re-measured against an empty fixture.
Replace the bullet with:**

> - A retirement applies correctly and the tool's own count does not move,
>   which reads as "the apply did nothing". Some names are compiled into the
>   binary rather than read from a file, and a file whose name matches one of
>   them *shadows* it rather than adding a row. Measured 2026-09-02 against a
>   fixture holding an empty `television/cable` and nothing else, `tv` 0.15.9
>   compiles in **ten**: `bash-history`, `dirs`, `docker-images`, `env`,
>   `files`, `git-branch`, `git-diff`, `git-log`, `git-repos`, `text`. So
>   `len(tv list-channels) = 10 + files - shared`, where `shared` is how many
>   of the ten the cable directory also supplies, and the gap between the list
>   and the directory is `10 - shared` — **not a constant**. It moves the
>   moment an adopted or retired name collides with a built-in, which is
>   exactly the situation this atomic is warning about. Today's arithmetic:
>   19 files sharing six names (`dirs`, `files`, `git-diff`, `git-log`,
>   `git-repos`, `text`) gives `10 + 19 - 6 = 23`, and the same formula
>   reproduces the 27 measured at 23 files. Count the directory, which you
>   own, before you read the tool's list, which you do not. (An earlier
>   measurement in this atomic named `env` and `git-branch` alone — two where
>   there are ten — and a later one named four, the four that 19-file
>   directory happened not to shadow. Both read a shadowing effect as a fixed
>   offset and turn a correct apply into an apparent failure.)

**4 — `rerun-the-drift-check`, `## Fails when`. Add:**

> - `just board-guard` refuses a path that is genuinely yours because a
>   *sibling* PRD in a contending state also names it — most often through a
>   spec's frontmatter footprint rather than the PRD's own, so it is not
>   visible in the sibling's `prd.md`. The guard prints *"Name the paths
>   instead of the tree, or pass the exclusion set this prints"*, which is
>   advice for a caller who named a directory; a caller who named the exact
>   file has no narrower name to give and cannot make it green. Do not drop
>   the path from the list to get a zero — that hides the collision from
>   `collect`. Isolate it (run the guard over each footprint path alone),
>   name the holder and its claim in the report, and say whether the two
>   edits actually conflict. Resolving it is a dispatch decision, not a
>   worker's.
