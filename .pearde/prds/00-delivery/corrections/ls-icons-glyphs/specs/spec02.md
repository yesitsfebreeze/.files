---
spec: 02
node: 00-delivery/corrections/ls-icons-glyphs
covers: R2
complexity: 15
footprint:
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec02 — correct the `ls` manual entry and re-digest both its reviews

Delivers R2. Depends on spec01 landing first (or at least its decision being
settled — the wording below does not depend on spec01's exact glyph bytes,
only on the shape of the outcome: files get icons, directories don't).

## The wrong claim, precisely

`home/dot_config/nushell/help/shell.nuon`'s `cmd: "ls"` entry's `use` field
reads (line 114): "…and each row carries an icon." That was true of the
*intent* but false of the *shipped* behavior before spec01 (every glyph was
empty), and stays imprecise after spec01 lands: directories still carry no
icon by design (spec01's finding — no vendored source for a folder glyph
exists anywhere in this repo's dependency tree). "Each row" overclaims
either way.

## The edit

In `home/dot_config/nushell/help/shell.nuon`, the `cmd: "ls"` record's `use`
field only — nothing else in the record changes:

```
-        use: "Plain `ls`. Rows are sorted by type then modified time, so directories group together and the freshest thing sits nearest the prompt, and each row carries an icon. It is still a nushell table: `ls | where size > 1mb | sort-by modified` works."
+        use: "Plain `ls`. Rows are sorted by type then modified time, so directories group together and the freshest thing sits nearest the prompt, and each file row carries a Nerd Font icon for its extension; directories show no icon. It is still a nushell table: `ls | where size > 1mb | sort-by modified` works."
```

`title`, `topic`, `mode`, `also`, `why`, `verify`, `source` all stay
byte-identical. No other entry in the file changes.

## Both review files need re-digesting, not one

`tests/help-content-model.nu` computes two independent digests over this
entry, and **both key on `use`**:

```nu
def use-digest [use: string, source: string] {
    $"($use)\n--\n($source)" | hash sha256 | str substring 0..15
}
def why-digest [use: string, why: string] {
    $"($use)\n--\n($why)" | hash sha256 | str substring 0..15
}
```

`use-review.nuon`'s `ls` row is keyed on `(use, source)`; `why-review.nuon`'s
`ls` row is keyed on `(use, why)`. Editing `use` invalidates **both** rows
even though neither `source` nor `why` changes — this is easy to miss
because the PRD's own R1 text only names "review row" in the singular. Do
not stop at one file.

Reproduced against both rows' **recorded** digests before touching
anything, so the recipe is known-good rather than assumed (analyst,
2026-08-25, against the `use` text as it stands today):

```
recorded use-review.nuon:130 (ls)   2029fcc64e9cebf7
recorded why-review.nuon:87  (ls)   0f7b212163f82343
```

Both matched a from-scratch SHA-256 replica of the two functions above run
against today's `use` (`shell.nuon:114`), `source`
(`"prds/04-shell/06-listing/prd.md"`), and `why` ("The builtin is captured
as `core-ls` before being shadowed, because an alias target binds at parse
time — without the capture the wrapper would call itself.") — so the digest
recipe is confirmed correct on this file before either edit lands.

With the new `use` text above (and `source`/`why` unchanged), the same
replica computed:

```
new use-digest   da50263294cce00a
new why-digest   0dff5fa49207b027
```

Do not take these on trust either — `nu tests/help-content-model.nu` prints
the digest it wants the moment the `use` edit lands and nothing else has
changed yet; confirm it prints exactly these two values (one per file, in
whichever order the gate visits them) before writing either row.

## Who may be the reviewer

Per `use-review.nuon`'s own ritual (see the `cdi` precedent,
`prds/00-delivery/corrections/cdi-manual-source/specs/spec01.md`, for the
full argument): the session making the `use` edit is the row's `author`; a
*different* session — dispatched specifically to read the new `use` against
the shipped route and the spec, not to bless it — is the `reviewer`. Both
rows (`use-review.nuon` and `why-review.nuon`) need this pair; they may
share the same author/reviewer session ids.

What the reviewer reads:
- the new `use` text above against spec01's landed `config.nu` (does a
  mixed-content `ls` actually show a per-extension icon on files and none
  on dirs — spot check against the fixture, or spec01's own acceptance
  evidence);
- the `why` field, unchanged, still accurately describing the `core-ls`
  capture (it does — nothing in this PRD touches that mechanism).

## Shared files — re-verify before editing

`help/shell.nuon`, `use-review.nuon` and `why-review.nuon` carry rows for
every manual entry, not just `ls`, and other lanes touch them independently
(precedent: `cdi-manual-source/specs/spec01.md` shared `shell.nuon` with
`06-help/02` and waited rather than raced). Re-run the two `grep`s below
immediately before editing to confirm the `ls` rows still read exactly as
quoted above — they did as of 2026-08-25, 21:33 (`use-review.nuon:130`
digest `2029fcc64e9cebf7`, `why-review.nuon:87` digest `0f7b212163f82343`,
both unchanged from this spec's writing) — and if they don't, recompute the
new digests against whatever `source`/`why` text is current rather than the
values printed here.

```sh
grep -n '"ls"' home/dot_config/nushell/help/use-review.nuon home/dot_config/nushell/help/why-review.nuon
```

## Acceptance

- [ ] `open home/dot_config/nushell/help/shell.nuon | where cmd == "ls" |
      get use.0` matches the new text above exactly.
- [ ] `git diff -U0 home/dot_config/nushell/help/shell.nuon` shows exactly
      one `-`/`+` pair, the `use` line.
- [ ] `use-review.nuon`'s `ls` row carries `digest: "da50263294cce00a"`,
      `author` and `reviewer` present and different, and a `note` giving the
      actual reading (not asserting one happened).
- [ ] `why-review.nuon`'s `ls` row carries `digest: "0dff5fa49207b027"`,
      `author` and `reviewer` present and different.
- [ ] `nu tests/help-content-model.nu` prints `ok` and exits 0, reporting
      the same entry count as before this change (measure and quote both
      counts in the report — do not assume the count from an older spec is
      still current).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu | tail -1        # baseline: expect ok

# after the shell.nuon edit only
nu tests/help-content-model.nu 2>&1 | grep -i ' ls'
# expect it to name both digests to set: da50263294cce00a and 0dff5fa49207b027

# after both review rows are updated
nu tests/help-content-model.nu                  # expect ok, exit 0
open home/dot_config/nushell/help/shell.nuon | where cmd == "ls" | get use.0
git diff -U0 home/dot_config/nushell/help/shell.nuon
```
