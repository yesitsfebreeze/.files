# spec02 — C-3: the legacy `mount` is an input, not the specification

est: 0.4h

## Goal

This ticket's **R1**. Audit finding C-3, in full:

> **Legacy `mount` never worked.** It `cd`s to a non-existent `~/docker`,
> calls `just run "$PWD"` where the recipe takes zero parameters, and that
> recipe mounts `./workspace` rather than the current directory. Do not
> preserve its semantics — design them.

Read the two capability entries this node merges and the danger is plain.
`.mi/docs/capabilities.md` describes `mount` as a "shell function that runs
`just run "$PWD"` from `~/docker`, building the dev image and dropping into
it with the workspace mounted", and "Just task runner" as a `run` recipe that
"creates `workspace/`, builds `devzsh`, and starts an interactive zsh
container". Both read as descriptions of working software. Neither ran. An
implementer who takes them as the behavioural contract reproduces three
defects — a hard-coded `~/docker` cwd, an argument that is silently dropped,
and a mount of `./workspace` instead of the directory the user asked for.

The third one is the dangerous one, because it is *invisible*: a capsule that
mounts the wrong directory still starts, still gives you a zsh prompt, and
still looks correct until you notice your files are not there.

R5 today says "The target directory is mounted at `/workspace`". That is
right, and it is right by luck — nothing in the file records that it is the
correction of a specific failure, so nothing stops the next editor from
"restoring" the legacy behaviour on the strength of the inventory entry. This
spec turns a lucky sentence into a constraint with its reason attached, which
is what `AGENTS.md` asks of every hard-won why in this tree.

**Scope boundary against W0.5.** `w0-5-capsule-rebase` owns finding **C-2**
— the epic's "consolidate what exists" framing, across four capsule files.
This spec touches C-3 only, and only in this node's own file. In particular
it does **not** retitle the node (the H1 still reads "consolidates capsule +
`mount` + justfile"): that heading is C-2's, it spans a file W0.5 also
rewrites, and two tickets editing the same line is exactly what the one
writer per file rule exists to prevent. The spec leaves a cross-link instead.

## Files touched

- `.mi/prds/01-capsule/01-container-lifecycle/prd.md` — the R5 bullet, the
  `## Acceptance` list, and the `## Out of scope` list. **Do not edit the
  frontmatter block.**
- `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/capsule/prd.md` —
  close the R1 box (body only, **not** the frontmatter).

Nothing else. Do not touch `.mi/prds/01-capsule/prd.md` (already carries its
own "inputs to the design, not the design" bullet, and is W0.5's file),
`02-dev-image`, `04-recent-workspaces`, `.mi/docs/capabilities.md` (owned by
`w0-4-s2-corrections/docs-inventories`, blocked on author confirmation), or
`.mi/prds/00-delivery/corrections/prd.md` (see this ticket's report — no
W0.4 child owns it).

## What to write

### 1. Rewrite R5, keeping the number

Wrap at ~78 columns; keep the box open.

> - [ ] **R5** — **Mounting.** The target directory *itself* is mounted at
>       `/workspace` and is the shell's initial cwd — never a `workspace/`
>       subdirectory of it, and never a path derived from where the tool
>       happened to be started: `capsule /some/path` behaves identically from
>       any directory, and the tool has no working directory of its own. Both
>       clauses are constraints rather than detail, because the legacy
>       attempt failed on exactly them (finding **C-3**: `mount` `cd`s to a
>       non-existent `~/docker`, then calls `just run "$PWD"` on a recipe
>       that takes zero parameters and mounts `./workspace`). Credential
>       mounts per
>       [03-credential-propagation](../../../../../01-capsule/03-credential-propagation/prd.md).

The C-3 citation is not decoration. It is what tells a reader who finds the
inventory entry describing `mount` as working software that the disagreement
was already adjudicated, and which way.

### 2. Add one acceptance box

The existing four boxes never check *which* directory got mounted — the
first one says "with the directory contents visible", which a `./workspace`
mount of a directory that happens to contain a `workspace/` would also
satisfy in the failure case that matters least. Add, at the end of
`## Acceptance`:

> - [ ] `capsule /some/path` run from an unrelated cwd produces a container
>       whose `docker inspect --format '{{json .Mounts}}'` shows the
>       workspace bind with `Source` exactly `/some/path` — not the cwd, and
>       not `/some/path/workspace/`.

### 3. Add one `## Out of scope` bullet

Keep the existing bullet, append:

> - Preserving the semantics of the legacy `mount` function or the `just
>   run` recipe. They never worked (finding **C-3**), so there is no
>   behaviour to stay compatible with; they are inputs to the design, not
>   the specification. The related framing question — that this node's title
>   says "consolidates" of pieces that never ran (C-2) — belongs to
>   [`w0-5-capsule-rebase`](../../../w0-5-capsule-rebase/prd.md),
>   which rebases the epic on "build once".

Do not mark any box in the PRD `[x]` or `[~]`. Nothing here is implemented.

## Acceptance

- [ ] R5 rules out a `workspace/` subdirectory mount, in R5's own text.
- [ ] R5 states the tool behaves identically from any invoking directory.
- [ ] The file names finding `C-3` by id, and all three of its concrete
      defects: `~/docker`, `just run`, `./workspace`.
- [ ] The file says somewhere that the legacy attempt never worked / is not
      the specification / is an input to the design.
- [ ] `## Acceptance` gained a box that checks the mount **source** and names
      `workspace/` as the thing it must not be.
- [ ] R1–R7 all still exist, still numbered as before, still seven of them.
      Other documents cite these by number.
- [ ] Every box in `01-container-lifecycle/prd.md` is still open — no `[x]`,
      no `[~]`.
- [ ] No line inside the leading `---` fence changed. Reviewer check, not in
      the verify: the file carries uncommitted orchestrator frontmatter edits
      already, so a `git diff` clause would false-fail on someone else's
      change.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above: it reports all nine of the C-3 clauses — the
four missing names, the missing "never worked" statement, both R5 clauses,
and both acceptance clauses — and exits 1. The R1–R7 and box-state clauses
pass today and are regression guards.

Two mechanical notes, both learned the hard way this session:

- Every assertion reads whitespace-normalised text (`tr "\n" " " | tr -s
  " "`), never lines. Prose here wraps at 78 columns, so a phrase worth
  asserting straddles a break; a line-wise grep produced a false negative
  earlier today.
- The acceptance mount check greps for `\.Source|Mounts|single bind`, not for
  `bind`. `bind` alone **false-passes** on the existing box's phrase "The
  WezTerm binding and the CLI…" — the same false-pass shape H.1 found in
  `terminal.nuon [Ctrl+Shift+B]`, where a verify target matched a live
  wallpaper prompt.
- `grep -E "R1.{0,4000}R7"` is not portable — BSD grep rejects the
  repetition count. Hence the loop.

## Spent proof

`prds/01-capsule/01-container-lifecycle/prd.md` now carries eight
requirements — an `R8` for the WezTerm bindings — and twelve closed boxes,
both added by the capsule lanes after this node closed.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/01-capsule/01-container-lifecycle/prd.md; rc=0; N=$(tr "\n" " " < "$f" | tr -s " "); R5=$(awk "/\*\*R5\*\*/{r=1} r&&/^- \[.\] \*\*R[0-9]/&&!/R5/{r=0} r&&/^## /{r=0} r" "$f" | tr "\n" " " | tr -s " "); A=$(awk "/^## Acceptance/{a=1;next} /^## /{a=0} a" "$f" | tr "\n" " " | tr -s " "); for s in "C-3" "~/docker" "just run" "./workspace"; do printf "%s" "$N" | grep -qF -- "$s" || { echo "FAIL: the file never names: $s"; rc=1; }; done; printf "%s" "$N" | grep -qE "never worked|not the specification|input to the design" || { echo "FAIL: the legacy attempt is not recorded as an input rather than a spec"; rc=1; }; printf "%s" "$R5" | grep -qE "subdirectory|sub-directory" || { echo "FAIL: R5 does not rule out mounting a workspace/ subdirectory"; rc=1; }; printf "%s" "$R5" | grep -qE "any directory|any working directory|cwd-independent|whatever directory|regardless of" || { echo "FAIL: R5 does not state the tool is cwd-independent"; rc=1; }; printf "%s" "$A" | grep -qE "\.Source|Mounts|single bind" || { echo "FAIL: acceptance has no mount-source check"; rc=1; }; printf "%s" "$A" | grep -qF "workspace/" || { echo "FAIL: acceptance does not rule out the workspace/ subdirectory"; rc=1; }; for n in 1 2 3 4 5 6 7; do grep -q "\*\*R$n\*\*" "$f" || { echo "FAIL: requirement R$n vanished"; rc=1; }; done; [ "$(grep -c "^- \[.\] \*\*R" "$f")" = "7" ] || { echo "FAIL: requirement count is not 7"; rc=1; }; grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box in the PRD was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
