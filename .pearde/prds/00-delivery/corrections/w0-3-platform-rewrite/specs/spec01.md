# spec01 — Give the 05-platform epic a real `## Acceptance`

est: 0.5h

## Goal

`.mi/prds/05-platform/prd.md` carries an `## Acceptance` heading with **zero
boxes** under it — the heading is followed immediately by `## Out of scope`.
Per `worker.md` §1 a node owes `unchecked + stubbed`, so an epic with an empty
Acceptance owes nothing from it and closes vacuously on its children alone.
`SYSTEM.md`'s own rule is that prose acceptance "is invisible to the scheduler
and closes unmet"; an empty Acceptance is the limiting case.

This is not an authoring oversight, it is a **conversion loss**, and the lost
text is recoverable rather than inventable. The pre-conversion flat file
`git show 8ecbbe4^:.mi/prd/05-platform/00-epic.md` ends with:

```
## Success criteria

A fresh macOS machine: clone the repo, `chezmoi apply`, and every tool the
other five epics assume is present. A second apply changes nothing.
```

The node conversion (commit `8ecbbe4`) mapped `## Non-goals` → `## Out of
scope` and `## Architecture invariants` → the `I1`–`I4` boxes, but dropped
`## Success criteria` on the floor. Restore it as boxes.

Verified before speccing: this is a **tree-wide class**, and four epics share
it — `02-terminal`, `03-editor`, `04-shell`, `05-platform`. Only
`05-platform/prd.md` is in W0.3's footprint; the other three belong to their
own tasks and **must not be touched here**.

## Files touched

- `.mi/prds/05-platform/prd.md` — body only, under `## Acceptance`. Do not
  edit its frontmatter.

## What to write

Four boxes. They must be **cross-child, end-to-end claims** — the things no
single child can prove on its own — because `SYSTEM.md` requires
"cross-link, don't duplicate" and the children already own the per-leg checks.
Specifically, do **not** restate these, which are already boxes elsewhere:

| already owned by | box |
|---|---|
| `02-package-provisioning` | "Fresh macOS machine: one apply installs every tool in the required set" |
| `02-package-provisioning` | "Simulating one failed package still completes the apply, with a warning" |
| `01-deploy-mechanism` | "Fresh clone + `chezmoi apply` … a second apply reports no changes" (scoped to the `~/.config` tree) |
| `03-shell-init-generation` | "Launching a shell runs no generator" (scoped to the three init files) |

The four to add, each tied to the invariant it proves:

- [ ] End to end on a scratch target: clone → `chezmoi apply` → a machine on
      which every tool the other five epics assume resolves on `PATH`, with no
      manual step between the clone and the working shell. (I1–I4 together;
      each child proves its own leg, this box proves they compose.)
- [ ] A second `chezmoi apply` run immediately after the first reports zero
      changes across **every** stage — `run_once_before` skipped by its stamp,
      the `run_onchange` installer skipped because the `packages.yaml` sha256
      is unchanged, `run_after` re-running to byte-identical output. (I2)
- [ ] Adding one tool to the base is a single edit to
      `.chezmoidata/packages.yaml`, and the next apply installs it. Checked by
      carrier: after adding the tool, `grep -rl <tool>` names only that data
      file, and no file under the script directory names it. `git diff` cannot
      answer this twice over — `.chezmoidata/packages.yaml` does not exist yet,
      and nothing in this repo's `home/` tree is tracked
      (`git ls-files --error-unmatch`, 2026-08-23; 18 of 60), so the diff is
      silent over both the file and the scripts it is compared against. A
      forward-looking invariant, not a post-edit check. (I3)
- [ ] Apply survives a hostile machine: with one package made unresolvable,
      the apply still exits 0 and the remaining tools are installed. (I4)

Write them as `- [ ]`. **Do not mark any of them `[x]` or `[~]`** — nothing in
this repo is implemented yet (`SYSTEM.md`: "planning only, on a board"), so a
checked box here would be a false record. The boxes describe the intended end
state and are closed by Wave 1, not by this task.

## Acceptance

- [x] `.mi/prds/05-platform/prd.md` has at least four `- [ ]` boxes under
      `## Acceptance`, and none of them is the first line after the heading
      being another `## ` heading.
- [x] Every box under `## Acceptance` is open (`- [ ]`) — no `[x]`, no `[~]`.
- [x] Each of I1, I2, I3 and I4 is referenced by at least one acceptance box,
      so no invariant is left unproven by the epic's own acceptance.
- [x] No box duplicates a child's acceptance verbatim: the strings "one apply
      installs every tool in the required set", "still completes the apply,
      with a warning" and "Launching a shell runs no generator" do not appear
      in the epic file.
- [ ] The three other empty-Acceptance epics are untouched:
      `git status --porcelain .mi/prds/02-terminal .mi/prds/03-editor
      .mi/prds/04-shell` is empty.
      - NOT TICKED: the command is non-empty, but for reasons that predate
        this task. The whole `.mi/prds` tree is staged-added with an
        unstaged frontmatter normalisation applied to all 78 nodes, and
        `02-terminal/04-copy-mode/prd.md` carries one stray pre-existing
        body line. Filtering the diff to non-frontmatter lines over those
        three epics returns only that one stray line, so nothing here
        touched them; the literal check cannot go green until the tree is
        clean, so the box stays open rather than being ticked falsely.
- [x] The file's frontmatter block is byte-identical to before the edit.

verify: `bash -c 'f=prds/05-platform/prd.md; n=$(awk "/^## Acceptance/{a=1;next} /^## /{a=0} a&&/^- \[ \]/{c++} END{print c+0}" $f); [ "$n" -ge 4 ] || { echo "FAIL: $n open acceptance boxes, want >=4"; exit 1; }; awk "/^## Acceptance/{a=1;next} /^## /{a=0} a&&/^- \[[x~]\]/{print \"FAIL: closed box in epic acceptance: \" \$0; exit 1}" $f || exit 1; for i in I1 I2 I3 I4; do awk -v I=$i "/^## Acceptance/{a=1;next} /^## /{a=0} a&&\$0 ~ I{f=1} END{exit !f}" $f || { echo "FAIL: $i unreferenced in acceptance"; exit 1; }; done; grep -q "one apply installs every tool in the required set" $f && { echo "FAIL: duplicates 02 acceptance"; exit 1; }; echo OK'`
