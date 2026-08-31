# spec01 — re-base the capsule epic on build-once and give every binding an owner

Rewrites the epic's framing from "consolidate five existing pieces" to
"build once, informed by the legacy attempt" (C-2, C-3 residue), retitles
`01-container-lifecycle`, adds the terminal-binding ownership the epic
promised but no task carried (W0.5 R5), and records the `Ctrl+Shift+T`
resolution where `01-container-lifecycle`'s `## Decisions` currently says it
is unsettled. Covers W0.5 R1, R3 (epic half), R5.

**Est:** 0.75h

**Footprint:** `prds/01-capsule/prd.md`,
`prds/01-capsule/01-container-lifecycle/prd.md`, `prds/README.md`

Never edit the frontmatter (`---` block) of any file.

## Edits

### `prds/01-capsule/prd.md`

1. Replace the Purpose paragraph with:

   > Purpose: The legacy repo reached "drop this directory into a
   > container" through five loosely coupled pieces: a WezTerm capsule
   > keybinding, the `mount` shell function, a `justfile`, a standalone
   > Dockerfile, and a credential-mounting script. None of them is
   > deployed, and the entry path never ran (findings C-2, C-3) — there is
   > no live implementation to consolidate from. This epic builds the tool
   > once, informed by that attempt: the pieces are evidence for the
   > design, not parts of it. `capabilities.md` asks for the capability to
   > work **flawlessly and consolidated as one tool**; "consolidated"
   > names the outcome — one name, one image definition, one code path —
   > not a porting job.

   Keep the Goal paragraph unchanged.

2. Insert a `## Bindings` section between Goal and `## Acceptance`:

   > ## Bindings
   >
   > The tool's terminal surface is four keys, each owned by the child
   > that implements its wrapper:
   >
   > | Key | Runs | Owner |
   > |---|---|---|
   > | `Ctrl+Shift+D` | `capsule` on the pane's directory | [`01-container-lifecycle`](../../../../01-capsule/01-container-lifecycle/prd.md) R8 |
   > | `Ctrl+Shift+B` | `capsule --rebuild` | [`01-container-lifecycle`](../../../../01-capsule/01-container-lifecycle/prd.md) R4, R8 |
   > | `Ctrl+Shift+S` | recents picker, current pane | [`04-recent-workspaces`](../../../../01-capsule/04-recent-workspaces/prd.md) R2 |
   > | `Ctrl+Shift+O` | recents picker, new tab | [`04-recent-workspaces`](../../../../01-capsule/04-recent-workspaces/prd.md) R2 |
   >
   > All four are unbound in the deployed `wezterm.lua` and in WezTerm's
   > defaults (`wezterm -n show-keys`, checked 2026-08-22);
   > `Ctrl+Shift+B` is free because the wallpaper pipeline is dropped
   > ([decision 5(c)](../../prd.md)). `Ctrl+Shift+T`
   > is not capsule's: it stays WezTerm's `SpawnTab`, the tab
   > reconciler's manual new-tab path. The rekey record is in
   > [`04-recent-workspaces`](../../../../01-capsule/04-recent-workspaces/prd.md)
   > `## Decisions`.

3. Replace the first Acceptance box ("One command (and one terminal
   keybinding that calls it) covers everything the old `mount`,
   `Ctrl+Shift+D`, `Ctrl+Shift+B`, and `just run` did.") with:

   > - [ ] One command, `capsule`, is the only entry path: every binding
   >       in `## Bindings` is a thin wrapper that invokes it, and nothing
   >       else builds, mounts, or attaches.

### `prds/01-capsule/01-container-lifecycle/prd.md`

4. Retitle the H1 to `# Container lifecycle`. The merged sources stay on
   the `Parent:` line; the title stops claiming a consolidation of pieces
   that never ran (C-2).

5. In the Purpose, change `One CLI entry point, e.g. \`capsule [dir]\`` to
   `One CLI entry point, \`capsule [dir]\`` — the name is settled; the
   manual (`capsule.nuon`) already documents it.

6. Append requirement R8:

   > - [ ] **R8** — **Terminal bindings.** This node delivers the WezTerm
   >       bindings that wrap the CLI: `Ctrl+Shift+D` runs `capsule` on
   >       the active pane's directory; `Ctrl+Shift+B` runs
   >       `capsule --rebuild` (R4). Thin wrappers only — binding and CLI
   >       take the one code path, which is what the `docker inspect`
   >       diff in Acceptance checks.

7. In `## Decisions`, replace the final paragraph ("`Ctrl+Shift+T` is
   **not** settled by this. …") with:

   > `Ctrl+Shift+T` was the separate collision: WezTerm's default
   > `SpawnTab`, the tab reconciler's manual new-tab path.
   > Resolved 2026-08-22 by
   > [`w0-5-capsule-rebase`](../prd.md)
   > R2: `SpawnTab` keeps the key, and the recents picker's new-tab
   > variant moves to `Ctrl+Shift+O` — record in
   > [`04-recent-workspaces`](../../../../01-capsule/04-recent-workspaces/prd.md)
   > `## Decisions`.

### `prds/README.md`

8. In the tree diagram, the `01-container-lifecycle/` line ends
   `Container lifecycle…`. Drop the ellipsis: the retitled node is
   `Container lifecycle`, nothing is elided.

## Acceptance

- [x] Epic purpose states build-once and cites C-2; the "covers everything
      the old `mount` … did" acceptance box is gone. Verify 2026-08-22:
      `PASS epic: build-once purpose`, `PASS epic: cites C-2`,
      `PASS epic: old acceptance box gone`.
- [x] Epic `## Bindings` table lists exactly D, B, S, O with owner links,
      and names `Ctrl+Shift+T` as `SpawnTab`, not capsule's. Verify
      2026-08-22: `PASS epic: Bindings section`, `PASS epic: claims
      Ctrl+Shift+O`, `PASS epic: T stays SpawnTab`;
      `grep '^| \`Ctrl' prds/01-capsule/prd.md` returns exactly the
      D/B/S/O rows, each with its owner link.
- [x] `01-container-lifecycle` H1 is `# Container lifecycle`; R8 exists;
      `## Decisions` records the `Ctrl+Shift+T` resolution and no longer
      says it is unsettled. Verify 2026-08-22: `PASS 01: retitled`,
      `PASS 01: R8 terminal bindings`, `PASS 01: T resolution recorded`,
      `PASS 01: unsettled wording gone`.
- [x] README tree line for `01-container-lifecycle` reads
      `Container lifecycle` with no ellipsis. Verify 2026-08-22:
      `PASS README: ellipsis dropped`.
- [x] No frontmatter block changed in any of the three files. `git diff`
      is empty by construction (`git ls-files prds/` is empty — untracked
      tree); checked 2026-08-22 by printing each file's `---` block: all
      three are well-formed with their scheduled fields intact.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
e=prds/01-capsule/prd.md
g=prds/01-capsule/01-container-lifecycle/prd.md
r=prds/README.md
fail=0; chk(){ if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }
chk "epic: build-once purpose"            "grep -qF 'builds the tool once' $e"
chk "epic: cites C-2"                     "grep -q 'C-2' $e"
chk "epic: old acceptance box gone"       "! grep -qF 'everything the old' $e"
chk "epic: Bindings section"              "grep -qF '## Bindings' $e"
chk "epic: claims Ctrl+Shift+O"           "grep -qF 'Ctrl+Shift+O' $e"
chk "epic: T stays SpawnTab"              "grep -qF 'SpawnTab' $e"
chk "epic: one-entry-path box"            "grep -qF 'the only entry path' $e"
chk "01: retitled"                        "grep -qx '# Container lifecycle' $g"
chk "01: consolidates-title gone"         "! grep -qF 'consolidates capsule' $g"
chk "01: R8 terminal bindings"            "grep -qF '**R8** — **Terminal bindings.**' $g"
chk "01: T resolution recorded"           "grep -qE 'Resolved 2026-08-[0-9]{2}' $g"
chk "01: unsettled wording gone"          "! grep -qF 'is **not** settled by this' $g"
chk "README: ellipsis dropped"            "grep -qF 'C9 U9 V0 · Container lifecycle' $r && ! grep -qF 'Container lifecycle…' $r"
exit $fail
```
