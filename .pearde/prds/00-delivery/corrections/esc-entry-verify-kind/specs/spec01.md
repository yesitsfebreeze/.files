---
complexity: 4
footprint:
  - home/dot_config/nushell/help/nvim.nuon
---

# spec01 — `<Esc>`'s verify target becomes `prose`

`home/dot_config/nushell/help/nvim.nuon`'s `<Esc>` entry documents the L-6
non-ported binding but still carries
`verify: [{kind: "nvim-map", mode: "n", lhs: "<Esc>"}]`. Confirmed against
`home/dot_config/nvim/lua/config/keymaps.lua`: no `<Esc>` map exists in any
mode (the only other `<Esc>` in the nvim lua tree is
`plugins/completion.lua:16`, the completion-menu cancel, a different key
already covered by its own "Drive the completion menu" entry). The L-6
decision holds against the live keymaps file, so the entry is
documented-but-not-carried and belongs on `prose`, matching the sibling
`<leader>` entry two rows above it which already uses this kind.

## R1 — the edit

```
verify: [{kind: "nvim-map", mode: "n", lhs: "<Esc>"}]
```
becomes
```
verify: [{kind: "prose"}]
```

`key`, `title`, `use`, `topic`, `mode`, `why`, `source` all stay
byte-identical.

## R2 — the digest, and why nothing is owed

`tests/help-content-model.nu:414`'s `use-digest` hashes `use` + `source`
only — `verify` is not an input, confirmed by the gate's own self-tests.
This edit touches only `verify`, so the existing `use-review.nuon:166` row
(digest `a88215afd64071cf`) stays valid unchanged. No re-digest is owed.

## Acceptance

- [x] `nu tests/help-content-model.nu` prints `ok`, exit 0 (94 entries
      across 4 files, 9 topics).
- [x] No remaining `nvim-map` verify target in `nvim.nuon` names `<Esc>` —
      `grep -n '"lhs": "<Esc>"\|lhs: "<Esc>"'` returns nothing, exit 1.
- [x] `git diff -U0 home/dot_config/nushell/help/nvim.nuon` shows exactly
      one line changed:
      ```
      @@ -27 +27 @@
      -        verify: [{kind: "nvim-map", mode: "n", lhs: "<Esc>"}]
      +        verify: [{kind: "prose"}]
      ```

## Verify and Proof

```sh
nu tests/help-content-model.nu
grep -n '"lhs": "<Esc>"\|lhs: "<Esc>"' home/dot_config/nushell/help/nvim.nuon
git diff -U0 home/dot_config/nushell/help/nvim.nuon
```
