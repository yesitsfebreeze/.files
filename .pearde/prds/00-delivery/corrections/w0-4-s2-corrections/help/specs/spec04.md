# spec04 — M-15: the `desc` exemption class, recorded where the check reads it

est: 0.5h

## Goal

The epic claims "our maps already carry `desc` (87 normal-mode maps,
descriptions present)". The map count is right and the claim after it is
false, and every downstream design rests on the claim rather than the count.
Correct it, and record the desc-exemption class as an epic invariant so
`04-drift-check` — which is **not** in this ticket's footprint — inherits it
instead of re-deriving it.

## Files touched

- `.mi/prds/06-help/prd.md` (only this file)

Explicitly **not** `.mi/prds/06-help/04-drift-check/prd.md`. Its R2 carries the
same false sentence ("Our maps carry `desc`, so the check can compare
descriptions as well as existence") and its R4 defines the *Mismatched* class
that would false-positive. Another ticket owns that file, and
`decisions/fzf` landed in it today. Recording the class in the epic is what
AGENTS.md's "epics own the invariants" prescribes; leave a note for the
drift-check node's owner rather than an edit (see step 4).

## What was measured (2026-08-21, `nvim --headless` + `nvim_get_keymap`)

| mode | maps | without `desc` |
|---|---|---|
| n | 87 | 12 |
| v | 45 | 12 |
| x | 42 | 12 |
| i | 9 | 0 |
| o | 11 | 8 |
| s | 21 | 2 |

The 87 matches the epic exactly. The 12 do not split evenly, and the split is
the whole finding:

- **Ours, deliberately without `desc` — 4 normal, 2 visual.** `n`, `N`,
  `<C-D>`, `<C-U>` (the centred-jump maps) and `<`, `>` (visual indent).
  `~/.config/nvim/lua/config/keymaps.lua:28` says so in the config itself:
  `-- Keep cursor centered on jumps / search (these maps carry no desc).`
  M-15 named the centred-jump maps and guessed the visual-indent ones; both
  are confirmed at `keymaps.lua:29-32` and `:34-35`.
- **Not ours at all — the remaining 8 normal / 10 visual.** Neovim's bundled
  matchit plugin: `%`, `[%`, `]%`, `g%`, `a%` and the five `<Plug>(Matchit…)`
  mappings they expand to. These are already covered by `04-drift-check` R6's
  plugin/core allowlist and are not an exemption at all — they are out of
  scope.

**The mechanism already exists in what H.1 landed**, so this is a documentation
gap and not new work. `tests/help-content-model.nu:41-60` records a
three-state rule for an `nvim-map` verify target's `desc`, and
`VERIFY_KINDS`'s `nvim-map: {req: ["mode" "lhs"], opt: ["desc" "scope"],
nullable: ["desc"]}` enforces the distinction:

| state | meaning to the drift check |
|---|---|
| field absent | compare the live `desc` against this entry's `title` |
| `desc: null` | the live map carries **no** description on purpose — assert existence only, never a mismatch (14 targets do this today) |
| `desc: "text"` | the live map's description must equal that string |

The comment there also records the measurement that makes it work: nushell's
`open` on a heterogeneous `.nuon` list keeps records heterogeneous rather than
null-filling them, so *absent* and *null* survive the round trip and stay
distinguishable. That is the expensive part of the knowledge — carry it.

## Edits

1. **Finding 2 in "Two findings that shape the design".** Replace "and our
   maps already carry `desc` (87 normal-mode maps, descriptions present)" with
   the measured statement: 87 normal-mode maps, **12 of those 87 carry none** —
   four of ours by design and eight belonging to Neovim's bundled matchit.
   Keep the sentence's original job (introspection is rich enough to check
   against) but stop it overclaiming.
2. **New architecture invariant I5 — a `desc` exemption is declared, never
   inferred.** Give the three-state table above, cite
   `tests/help-content-model.nu` as where it is enforced and
   `home/dot_config/nushell/help/README.md` as where a writer meets it, and
   state the two rules it buys:
   - a map that deliberately carries no `desc` is written `desc: null`, so the
     drift check asserts existence and never a mismatch;
   - an **omitted** `desc` means "compare against `title`", so omitting one for
     a map that *does* carry a description live is a defect, not an exemption.
     This clause is what stops I5 being read as a licence to skip the field.
   Add the not-ours class as a one-line pointer to `04-drift-check` R6 rather
   than restating its allowlist (cross-link, don't duplicate).
3. **Record the live example that proves rule two bites**, from
   `use-review.nuon`'s header: four `nvim-map` targets (`gd and gI`,
   `<leader>rn and <leader>ca`) omit `desc` where the live maps set `LSP: …`
   strings — four drift-check false failures waiting. Name it as belonging to
   the content files and `04-drift-check`, not to this epic.
4. **Leave the drift-check node a pointer, not an edit.** In I5, note that
   `04-drift-check` R2 and R4 are written against the retired claim and need
   reconciling by that node's owner. If the corrections backlog is the right
   home for that, file it there as part of spec05's pass — do not edit
   `04-drift-check/prd.md`.

## Acceptance

- [ ] The overclaim is gone: the epic no longer contains "our maps already
      carry `desc` (87 normal-mode maps, descriptions present)".
- [ ] The measured split is stated: the file contains "12 of those 87 carry
      none".
- [ ] The epic carries an invariant numbered **I5**.
- [ ] I5 gives `desc: null` as the declared exemption, in those characters, so
      an implementer can write it without opening the test file.
- [ ] The not-ours class is named — the file mentions `matchit` — so the two
      classes cannot be conflated.
- [ ] `.mi/prds/06-help/04-drift-check/prd.md` is unmodified.
- [ ] No frontmatter field is changed.

## verify

Proved RED against the current tree before being written here (exit 1, all
five clauses failing — the forbidden phrase is found only after whitespace
normalisation, since in the file it wraps after "carry `desc`").

```
nu -n -c 'let t = (open --raw prds/06-help/prd.md | str replace -ar "\\s+" " "); let checks = [[want, phrase]; [false, "our maps already carry `desc` (87 normal-mode maps, descriptions present)"], [true, "12 of those 87 carry none"], [true, "desc: null"], [true, "matchit"], [true, "**I5**"]]; let bad = ($checks | where {|r| ($t | str contains $r.phrase) != $r.want}); if ($bad | is-empty) { print "ok" } else { print ($bad | to text); exit 1 }'
```

Guard that the neighbouring node stays untouched. A `git diff --name-only`
guard is **not** usable here — the working tree already carries unrelated
modifications, including `decisions/fzf`'s note landed into that very file
today, so it fires red before this ticket starts. Pin the content instead:

```
shasum -a 256 prds/06-help/04-drift-check/prd.md | grep -q '^3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd '
```

That digest was taken at analysis time, 2026-08-21, with the `fzf` note
already in place. If the file legitimately changes under another ticket while
this one is in flight, re-take the digest rather than deleting the guard.
