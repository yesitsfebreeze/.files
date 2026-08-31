---
est: 0.5h
footprint:
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/use-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec01 — repoint `cdi` at 03-zoxide and re-digest its reading

Two edits, one change: the `cmd: "cdi"` entry's `source` field moves from
`prds/04-shell/02-aliases-utilities/prd.md` to
`prds/04-shell/03-zoxide/prd.md`, and the matching `use-review.nuon` row is
re-digested by a reader who did not make the edit. They must land together —
`tests/help-content-model.nu` keys the review digest on `use` **and**
`source`, so repointing the entry alone turns the gate red, and it is
supposed to.

The attribution is wrong today, not arguably wrong.
[`04-shell/03-zoxide`](../../../../04-shell/03-zoxide/prd.md) R2 names the
capability "**`zi`** (and the `cdi` alias)"; `04-shell/02`'s own
[spec01](../../../../04-shell/02-aliases-utilities/specs/spec01-config-aliases.md)
(line 63) says "`cdi` belongs to `03-zoxide` R2" and its
[spec03](../../../../04-shell/02-aliases-utilities/specs/spec03-gate.md)
turns that into an absence assertion that `tests/nushell-aliases.sh:188`
enforces — `cdi` must not appear in config.nu's ALIASES anchor. The shipped
alias lives where 03 put it, `home/dot_config/nushell/zoxide.nu:101`.

## The two edits

1. **`home/dot_config/nushell/help/shell.nuon`**, line 46 — inside the
   `cmd: "cdi"` record (lines 38–47), the `source` field **only**:

   ```
   -        source: "prds/04-shell/02-aliases-utilities/prd.md"
   +        source: "prds/04-shell/03-zoxide/prd.md"
   ```

   Nothing else in that record changes — not `title`, not `use`, not
   `topic`, `mode`, `also` or `verify`. No other entry in the file changes.
   PRD R1 is exactly this line.

2. **`home/dot_config/nushell/help/use-review.nuon`**, line 123 — the one
   `{id: "cdi", file: "shell.nuon", …}` row. Set `digest` to the value
   below, set `reviewer` to the reader's session id, add `author` naming the
   session that made edit 1, set `date`, and rewrite `note` to carry the
   reading. Keep `id` and `file` as they are.

## The digest, reproduced

`tests/help-content-model.nu:414` is the whole recipe:

```nu
def use-digest [use: string, source: string] {
    $"($use)\n--\n($source)" | hash sha256 | str substring 0..15
}
```

That is: the `use` string, a literal newline, `--`, a literal newline, the
`source` string; SHA-256 of the result; the first 16 hex characters. No
trimming, no normalisation, no `id` and no `file`.

Reproduced against this row's **recorded** digest before touching anything,
so the recipe is known-good rather than inferred:

```
recorded in use-review.nuon:123   99ddb8576c553ed6
use-digest <cdi.use> "prds/04-shell/02-aliases-utilities/prd.md"
                                  99ddb8576c553ed6   ← matches
use-digest <cdi.use> "prds/04-shell/03-zoxide/prd.md"
                                  3a8f2a6e5bdbbb23   ← the new value
```

So **`digest: "3a8f2a6e5bdbbb23"`**. Do not take that on trust either: edit
1 alone makes the gate print it, verbatim, which is step 2 of the ritual in
`use-review.nuon`'s header ("run `nu tests/help-content-model.nu`. It prints
the digest to set"). Confirmed on a full-tree copy, 2026-08-23:

```
shell.nuon [cdi]: `use`/`source` changed since the recorded reading —
re-read the gesture against the spec, then set digest to 3a8f2a6e5bdbbb23
```

The same copy with edit 2 applied printed `ok`. If the implementer's run
prints a *different* digest, the `use` has been touched — revert that, this
spec changes one field.

## Who may be the reviewer

The gate (`tests/help-content-model.nu:858`) fails any row whose `author`
equals its `reviewer`, and `author` is optional — so honesty about
authorship is what makes the check bite. Concretely, for this change:

- **The session that performs edit 1 is the row's `author`.** The digest
  keys on the pair, and this change revises half of the pair. "I only moved
  `source`, I did not write the `use`" does not exempt anyone: the two
  standing precedents for exactly this move are `use-review.nuon:198`
  (`Ctrl+V`) and `:199` (`Ctrl+C`), whose notes open "the `use` is
  byte-identical to the reviewed text; only `source` moved" — and both still
  record `author: implementer-copy-mode` with `reviewer:
  implementer-copy-mode-r1`.
- **The `reviewer` is a different session that did not make the edit** and
  is dispatched to *refute* the entry, not to bless it. The established way
  to get one, and the one available to an afk implementer, is a subagent:
  the implementer spawns a reader, hands it the new text and the routes
  below, and records what it returns. House id convention, from the rows
  already in the file: `<implementer-id>-r1` (`implementer-copy-mode` →
  `implementer-copy-mode-r1`, `impl-H-1` → `impl-H-1-r5`) or
  `reader-<lane>` (`impl-S-9` → `reader-S-9`). Any two distinct strings
  satisfy the gate; a subagent that actually read is what satisfies the
  record.
- **What the reader is asked to read**, so the `note` is a reading and not a
  restatement:
  - the `use` — "Alias for `zi` — the same picker under the name muscle
    memory reaches for." — against **03-zoxide R2**
    (`prds/04-shell/03-zoxide/prd.md:31-40`), which names `cdi` as `zi`'s
    alias with the same recents logging and the fzf exception;
  - the shipped route in this repo's tree, which is where the alias now
    lives: `home/dot_config/nushell/zoxide.nu:101` `alias cdi = zi` →
    `alias zi = _zi_nav` (:98) → `_zi_nav` (:87-95) → `^zoxide query
    --interactive`;
  - the standing reading it replaces, `use-review.nuon:123` by
    `impl-H-1-r1`: "defers wholesale to `zi` … It inherits whatever `zi`
    says, so it stands once `zi` names fzf." That reading was taken against
    the *live* config (`~/.config/nushell/config.nu:150`); carrying it
    forward means re-checking it against the tree route above, the way the
    `idioms` row (`:156`) was carried forward and re-verified.
  - whether the entry's `also: ["zi"]` and `zi`'s own row still agree — the
    `idioms` row leaves a standing nit that the board names the exception as
    `zi`/`cdi` while the prose names only `zi`. Record it if it is still
    open; do not fix it here.

  If the reader refutes the entry rather than vouching for it, that is a
  finding, not a blocker: the `use` text is out of this PRD's scope ("only
  the attribution and its review row"), so the note records the objection
  and it goes to the corrections backlog.

## Out of limits

`tests/help-content-model.nu` is **run, never edited** — no constant here is
transcribed from `cdi`. `why-review.nuon` carries no `cdi` row (the entry has
no `why`) and must gain none. `prds/04-shell/02-aliases-utilities/` and
`prds/04-shell/03-zoxide/` are other nodes' folders and both are already
correct — the manual was the only wrong record. `tests/nushell-aliases.sh`
already asserts the absence this change agrees with; leave it alone.

`home/dot_config/nushell/help/shell.nuon` is also in
[`06-help/02-help-command`](../../../../06-help/02-help-command/prd.md)
spec02's footprint (the `cmd: "help"` entry's `why` field) and that node is
claimed. The fields are disjoint — entry `cdi` field `source`, versus entry
`help` field `why` — but the file is shared, so this spec waits for that
lane rather than racing it.

## Acceptance

- [x] `open home/dot_config/nushell/help/shell.nuon | where cmd == "cdi" |
      get source.0` prints `prds/04-shell/03-zoxide/prd.md`.
- [x] Every other field of the entry is byte-identical. Checked as a
      fingerprint, because the file is shared with another lane and a whole-
      file diff is not a clean signal:
      `open … | where cmd == "cdi" | first | reject source | to nuon |
      hash sha256 | str substring 0..15` prints `77b658ee1a919c20`, the
      value it prints today (measured 2026-08-23). The new pair digest
      `3a8f2a6e5bdbbb23` pins `use` a second time — change one character of
      it and the gate asks for a different digest.
- [x] `git diff -U0 home/dot_config/nushell/help/shell.nuon` shows exactly
      one `-`/`+` pair inside the `cmd: "cdi"` record, and it is the
      `source` line. Other hunks elsewhere in the file may belong to the
      `06-help/02` lane; this box is about the `cdi` record. One pair, and
      it is the `source` line. Its `-` side reads
      `.mi/prd/04-shell/02-aliases-utilities/prd.md` rather than the
      `prds/` form, because an uncommitted tree-wide `.mi/prd/` -> `prds/`
      rename sits under this edit.
- [x] `use-review.nuon`'s `cdi` row carries `digest: "3a8f2a6e5bdbbb23"`,
      and that value is the one the gate printed on the intermediate run
      (quote the gate line in the report).
- [x] That row's `reviewer` and `author` are both present and different, the
      `author` naming the session that made edit 1 and the `reviewer` naming
      the session that read the entry.
- [x] That row's `note` gives the reading — the `use` against 03-zoxide R2
      with its line numbers, and the `zoxide.nu` route — rather than
      asserting that a reading happened.
- [x] `nu tests/help-content-model.nu` prints `ok` and exits 0, reporting
      the same entry count as before the change. The count is 92, not the
      91 this box was written against: `04-shell/09-theme-switcher` landed
      three `theme` entries and `bb / ba` was removed in the same tree.
      Unchanged by this edit, which replaces one field value.
- [x] `rg -n '04-shell/02-aliases-utilities' home/dot_config/nushell/help/`
      finds no `cdi` hit. The review `note` names the origin as
      `04-shell/02` for this reason, and because `language.md` bars
      migration notes.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# baseline, before either edit
nu tests/help-content-model.nu | tail -1        # expect: ok

# after edit 1 only — the gate names the digest to set
nu tests/help-content-model.nu 2>&1 | grep 'cdi'
# expect: shell.nuon [cdi]: `use`/`source` changed since the recorded
#         reading — ... set digest to 3a8f2a6e5bdbbb23

# after edit 2
nu tests/help-content-model.nu                  # expect: ok, exit 0
open home/dot_config/nushell/help/shell.nuon |
  where cmd == "cdi" | get source.0
open home/dot_config/nushell/help/shell.nuon |
  where cmd == "cdi" | first | reject source | to nuon |
  hash sha256 | str substring 0..15        # expect: 77b658ee1a919c20
git diff -U0 home/dot_config/nushell/help/shell.nuon
rg -n '04-shell/02-aliases-utilities' home/dot_config/nushell/help/
```
