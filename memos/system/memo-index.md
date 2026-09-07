---
kind: documentation
description: Read the generated memo index progressively from the kind overview to a leaf entry and its source file.
read_when: finding a memo without loading the whole record
---

# memo-index

Read `memos/index.json` first. Its `kinds` object is keyed by declared kind;
each value contains `description`, `read_when`, `memo_count`, `declaration`,
and `index`. `memo_count` at the root counts the memos included in the index.

```sh
jq '.kinds.decision' memos/index.json
jq '.memos["tmux-owns-multiplexing"] memos/decision/index.json'
```

Open the chosen kind's `index` path relative to `memos/`. The kind file has
`kind`, `memo_count`, and `memos`, an object keyed by leaf name. Each memo
has `path`, `description`, `read_when`, and `links`. Open `path` for its
body. Every path, including a link destination, is relative to `memos/`.
Link values are paths or `null` when a leaf has no indexed destination.

Other system memos are indexed under their semantic kind with a `system/`
source path. `system/_index_.md` lists every base-system memo together.

`just memos-check` regenerates all levels. No index is authored by hand.
[[the-index-is-derived]] is the rule, [[SYSTEM]] the protocol.