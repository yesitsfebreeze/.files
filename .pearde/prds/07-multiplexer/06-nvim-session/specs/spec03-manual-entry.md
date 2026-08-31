---
complexity: 6
footprint:
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
---

# spec03 — the manual entry, and the two readings it cannot close without

Three new keybindings mean a manual entry in the same change, per the repo
contract. `home/dot_config/nushell/help/nvim.nuon` gains one entry keyed
`<leader>ss <leader>sl <leader>sd` on the existing `edit` topic, with three
`kind: "nvim-map"` verify targets.

**This already stands and the content-model gate is green** (97 entries, 0
violations). What is left is to keep it that way: the gate enforces four
things that are easy to get wrong, and one of them cannot be satisfied by the
session that writes the entry.

- **The title must be imperative.** Watch the check's shape: it is a suffix
  test, so a title opening "Bring back the buffers ..." is rejected as
  "opens with the gerund `bring`". That is a false positive in the gate and
  it is filed as a finding, not fixed from here — the entry simply opens
  "Restore".
- **Every `why` needs a row in `why-review.nuon`**, keyed by a digest of the
  exact `(use, why)` pair: `a3d233b599fb26ea` for this entry's text. Edit
  either field and the digest stops matching.
- **Every entry needs a row in `use-review.nuon`**, keyed by a digest of
  `(use, source)`: `b3919ace8b0a107e`.
- **The reviewer may not be the author.** The gate rejects a row where
  `reviewer` equals `author` — "a record vouching for itself". A separate
  session read the pair against persistence.nvim's source, `keymaps.lua` and
  tmux-resurrect, and its reading is recorded verbatim under
  `reviewer: "reader-07-06-nvim-session"`. If the `use` or the `why` is ever
  reworded, a **new** independent reading is required; recomputing the digest
  alone is the failure this record exists to prevent.

One thing the entry says and does not tick: the three `nvim-map` verify
targets **cannot be resolved today**. The reader that would resolve them
lives in `06-help/04-drift-check`, which is `open` and parse-erroring. The
entry is documented and machine-unverified until that lands, and both review
rows say so in their own words rather than implying coverage that does not
exist.

## Acceptance

- [x] `nvim.nuon` carries one entry keyed
      `<leader>ss <leader>sl <leader>sd`, topic `edit`, mode `nvim:normal`,
      `source:` this PRD, with three `kind: "nvim-map"` verify targets whose
      `desc` values equal the `desc` strings in `lua/plugins/session.lua`
- [x] its `use` describes the gesture only — when a session is written, what
      each of the three keys does, and that nothing restores unless asked
- [x] its `why` carries the two things the `use` cannot: that tmux-resurrect
      is the consumer, and why the keys are on `<leader>s` rather than
      persistence.nvim's documented `<leader>q`
- [x] `use-review.nuon` and `why-review.nuon` each carry a row for the entry
      with the matching digest, and with `reviewer` different from `author`
- [x] `nu tests/help-content-model.nu` prints `ok` and exits 0
- [x] no box anywhere claims the `nvim-map` targets are verified while
      `06-help/04-drift-check` is unbuilt

## Verify and Proof

Scoped to this node's three footprint files and its one entry — a bare
`nu tests/help-content-model.nu` measures 97 entries across every surface and
would report the tree's worst neighbour rather than this node's work. The
whole-file gate is still run, second, because acceptance names it; `set -e`
so the scoped failure cannot be masked by the gate that follows it.

```sh
cd /Users/feb/dev/dotfiles
set -e
nu -c '
  let K = "<leader>ss <leader>sl <leader>sd"
  let e = (open home/dot_config/nushell/help/nvim.nuon | where key == $K | first)
  let ud = ($"($e.use)\n--\n($e.source)" | hash sha256 | str substring 0..15)
  let wd = ($"($e.use)\n--\n($e.why)" | hash sha256 | str substring 0..15)
  let u = (open home/dot_config/nushell/help/use-review.nuon | where id == $K and file == "nvim.nuon" | first)
  let w = (open home/dot_config/nushell/help/why-review.nuon | where id == $K and file == "nvim.nuon" | first)
  let src = (open --raw home/dot_config/nvim/lua/plugins/session.lua)
  let d = ($e.verify | get desc)
  let joined = ($d | str join " / ")
  mut bad = []
  if $e.topic != "edit" { $bad = ($bad | append "topic") }
  if $e.mode != "nvim:normal" { $bad = ($bad | append "mode") }
  if $e.source != "prds/07-multiplexer/06-nvim-session/prd.md" { $bad = ($bad | append "source") }
  if ($e.verify | get kind) != ["nvim-map" "nvim-map" "nvim-map"] { $bad = ($bad | append "verify-kinds") }
  if ($d | length) != 3 { $bad = ($bad | append "verify-count") }
  if not ($d | all {|x| $src | str contains $x }) { $bad = ($bad | append "desc-ne-session.lua") }
  if $ud != $u.digest { $bad = ($bad | append "use-digest") }
  if $wd != $w.digest { $bad = ($bad | append "why-digest") }
  if $u.reviewer == $u.author { $bad = ($bad | append "use-row-vouches-for-itself") }
  if $w.reviewer == $w.author { $bad = ($bad | append "why-row-vouches-for-itself") }
  print $"entry ($K) topic=($e.topic) mode=($e.mode)"
  print $"descs ($joined)"
  print $"use-digest entry=($ud) row=($u.digest) | why-digest entry=($wd) row=($w.digest)"
  print $"reviewer=($u.reviewer) author=($u.author)"
  let msg = ($bad | str join ", ")
  if ($bad | is-empty) { print "ok - scoped" } else { print -e $"FAIL ($msg)"; exit 1 }
'
nu tests/help-content-model.nu
```
