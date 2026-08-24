# spec02 — Restore the truncated source attributions on the three children

est: 0.5h

## Goal

All three `05-platform` children carry a `Parent:` header line that is cut off
mid-quote. Measured:

```
01-deploy-mechanism/prd.md:13   … · sources: "Idempotent
02-package-provisioning/prd.md:13 … · sources: "Package
03-shell-init-generation/prd.md:13 … · source: "Shell-init
```

The line ends there. The opening quote is never closed, the inventory entries
are never named, and — for the two `sources:` cases — the per-entry C/U
numbers are gone. That breaks a rule `SYSTEM.md` states explicitly: "A PRD
that merges several entries carries the dominant entry's rating and **lists
every source with its own numbers**."

This is a **conversion loss with a recoverable original**, not an authoring
gap. Commit `8ecbbe4` ("board: land the flat-prose -> node conversion")
inserted the frontmatter and rewrote the parent link, and truncated the
`Parent:` paragraph at its first newline. The pre-conversion text is intact in
git and is the text to restore, re-pointed at node paths:

```
$ git show 8ecbbe4^:.mi/prd/05-platform/01-deploy-mechanism.md   | sed -n 3,5p
Parent: [Provisioning epic](00-epic.md) · C 3 · U 9 · sources: "Idempotent
apply + push workflow" (C3 U9 — dominant), "Managed config surface" (C3 U9) in
capabilities-provisioning.md

$ git show 8ecbbe4^:.mi/prd/05-platform/02-package-provisioning.md | sed -n 3,6p
Parent: [Provisioning epic](00-epic.md) · C 8 · U 9 · sources: "Package
installer" (C8 U9 — dominant), "Declarative package set" (C2 U9), "Homebrew
bootstrap" (C2 U8), "Neovim version gating" (C4 U8) in
capabilities-provisioning.md

$ git show 8ecbbe4^:.mi/prd/05-platform/03-shell-init-generation.md | sed -n 3,4p
Parent: [Provisioning epic](00-epic.md) · C 3 · U 9 · source: "Shell-init
generation" in capabilities-provisioning.md
```

Every rating above was re-checked against `.mi/docs/capabilities-provisioning.md`
as it stands today and all eight numbers still match the inventory entries
(Idempotent apply + push 3/9 · Managed config surface 3/9 · Package installer
8/9 · Declarative package set 2/9 · Homebrew bootstrap 2/8 · Neovim version
gating 4/8 · Shell-init generation 3/9). Restore, do not re-derive.

Verified before speccing: the truncation is a **tree-wide class** hitting 19
nodes across five epics. Only these three are in W0.3's footprint. Do **not**
fix the other sixteen here — they belong to `02-terminal`, `03-editor`,
`04-shell` and `01-capsule` tasks, and a cross-epic sweep would break
one-writer-per-file.

## Second defect, same files: a dangling cross-reference

`01-deploy-mechanism/prd.md:32` reads:

```
- moved out of this epic — R4; see the Notes below
```

There is no `## Notes` section in that file — the line after `## Requirements`
is `## Acceptance`. The pointer resolves to nothing. R4 did move and its
destination is known: `.mi/prds/04-shell/02-aliases-utilities/prd.md:31` reads
`**R4 (from 05-platform/01 req 4)** — rr = chezmoi update --force`. Replace
the dangling pointer with the real one rather than adding a `## Notes` section
to hold a one-line fact.

## Files touched

- `.mi/prds/05-platform/01-deploy-mechanism/prd.md` — the `Parent:` paragraph
  and the R4 allocation bullet. Body only.
- `.mi/prds/05-platform/02-package-provisioning/prd.md` — the `Parent:`
  paragraph. Body only.
- `.mi/prds/05-platform/03-shell-init-generation/prd.md` — the `Parent:`
  paragraph. Body only.

Do not edit frontmatter in any of the three.

## What to write

Keep the existing node-form parent link `[Provisioning epic](../prd.md)` and
the existing `C n · U n` — only the truncated tail is restored. Wrap the
continuation at ~78 columns, as the originals did. Link the inventory rather
than naming it bare, matching how the epic does it:
`[capabilities-provisioning.md](../../../../../docs/capabilities-provisioning.md)`.

For the R4 bullet, write something that names the destination, e.g.:

```
- moved out of this epic — R4 (`rr` = `chezmoi update --force`), now
  [`04-shell/02`](../../04-shell/02-aliases-utilities/prd.md) R4
```

## Acceptance

- [x] Each of the three `Parent:` paragraphs has a balanced number of `"`
      characters — no unterminated quote.
- [x] Each of the three names `capabilities-provisioning.md`, and the link
      resolves to an existing file from that node's directory.
- [x] `01`'s and `02`'s paragraphs list **every** merged source entry with its
      own `Cn Un`, and mark exactly one as `dominant`: `01` names 2 entries,
      `02` names 4. `03` uses singular `source:` and names 1.
- [x] The dominant entry's rating equals the header's `C n · U n` in all three
      files (3/9, 8/9, 3/9 respectively).
- [x] `grep -rn 'see the Notes below' .mi/prds/05-platform` returns nothing,
      and `01`'s R4 bullet links to `04-shell/02-aliases-utilities/prd.md`.
- [x] Every relative link in the three files still resolves (none was broken
      by the rewrap).
- [ ] The sixteen out-of-footprint truncations are untouched:
      `git status --porcelain .mi/prds/01-capsule .mi/prds/02-terminal
      .mi/prds/03-editor .mi/prds/04-shell` is empty.
      - NOT TICKED, same pre-existing dirt as spec01's equivalent box: the
        tree-wide frontmatter normalisation and one stray body line in
        `02-terminal/04-copy-mode/prd.md` make the literal command
        non-empty. No `Parent:` line outside this node's three files was
        edited — the non-frontmatter diff over those four epics is that one
        stray line and nothing else.
- [x] Each file's frontmatter block is byte-identical to before the edit.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; for f in prds/05-platform/01-deploy-mechanism/prd.md prds/05-platform/02-package-provisioning/prd.md prds/05-platform/03-shell-init-generation/prd.md; do p=$(awk "/^Parent:/{g=1} g&&NF{print} g&&!NF{exit}" "$f"); q=$(printf "%s" "$p" | tr -cd "\"" | wc -c); [ $((q % 2)) -eq 0 ] || { echo "FAIL unbalanced quote: $f"; rc=1; }; printf "%s" "$p" | grep -q "capabilities-provisioning.md" || { echo "FAIL no inventory named: $f"; rc=1; }; printf "%s" "$p" | grep -q "dominant\|source:" || { echo "FAIL no attribution: $f"; rc=1; }; d=$(dirname "$f"); tr "\n" " " < "$f" | grep -oE "\]\([^)#][^)]*\)" | sed "s/^](//;s/)$//" | while read -r l; do [ -e "$d/${l%%#*}" ] || echo "BROKEN $f -> $l"; done | grep . && rc=1; done; grep -rn "see the Notes below" prds/05-platform && { echo "FAIL dangling Notes ref"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
