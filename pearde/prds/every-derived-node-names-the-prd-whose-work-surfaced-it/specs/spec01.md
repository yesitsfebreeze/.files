---
complexity: 3
footprint:
  - pearde/prds/09-simplify/retire-the-unmanaged-television-channels/prd.md
  - pearde/prds/09-simplify/propagate-a-tinty-apply-into-a-running-nvim/prd.md
  - pearde/prds/09-simplify/silence-the-chezmoi-config-template-drift-warning/prd.md
  - pearde/prds/09-simplify/retire-the-two-unmanaged-television-preview-scripts/prd.md
---

# spec01 — name the four derived nodes' provenance

Adds `from: <prd>` to the four `origin: derived` PRDs the doctor's origin
check flagged as untraceable. Each value is the PRD named in the node's own
"Established … by … on `<prd>`" sentence — never guessed — and each named
PRD directory is confirmed to exist. Already done during the build pass:

- `retire-the-unmanaged-television-channels` and
  `propagate-a-tinty-apply-into-a-running-nvim` both read "Established
  2026-09-02 by the skeptic called on `09-simplify/06-neovim-television`" →
  `from: 09-simplify/06-neovim-television`.
- `silence-the-chezmoi-config-template-drift-warning` and
  `retire-the-two-unmanaged-television-preview-scripts` both read
  "Established 2026-09-02 by `analyst-tv` while speccing
  `09-simplify/retire-the-unmanaged-television-channels`" →
  `from: 09-simplify/retire-the-unmanaged-television-channels`.

## Acceptance

- [x] Each of the four `prd.md` files carries a `from:` line in its
      frontmatter, directly below `origin: derived`, naming a PRD directory
      that exists on disk.
- [x] `pearde doctor`'s no-from: count over the canonical `pearde/prds/`
      tree is 0 (was 4).

## Verify and Proof

```sh
for f in pearde/prds/09-simplify/retire-the-unmanaged-television-channels/prd.md \
         pearde/prds/09-simplify/propagate-a-tinty-apply-into-a-running-nvim/prd.md \
         pearde/prds/09-simplify/silence-the-chezmoi-config-template-drift-warning/prd.md \
         pearde/prds/09-simplify/retire-the-two-unmanaged-television-preview-scripts/prd.md; do
  grep -A1 '^origin: derived' "$f" | grep '^from: ' || echo "MISSING: $f"
done
# each grep line prints "from: <prd>"; confirm the target exists:
test -d pearde/prds/09-simplify/06-neovim-television
test -d pearde/prds/09-simplify/retire-the-unmanaged-television-channels
```

**Residual, outside this footprint.** `pearde doctor` (whole board) still
reads `origin broken` after this spec, at `2 with no from:` — both are
duplicate copies of two of these same four nodes, stranded under
`.lanes/09-simplify-retire-the-unmanaged-television-channels/.pearde/prds/`,
a worktree for an already-`done` PRD that was never removed and still
carries a pre-rename `.pearde/prds` tree. `find "$BOARD" -type f -name
prd.md` recurses into `.lanes/*` and counts them. See the report's
`## Findings`.
