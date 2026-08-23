# spec02 — M-16: the browser's row format, cited to the thing that sets it

est: 0.4h

## Goal

`03-browser` R1 requires TAB-delimited channel rows "mirroring how the
quicklist channel is built ([04-shell/07](...))". The row format is right; the
citation is wrong, and the wrong citation is the whole defect — `04-shell/07`
specifies a **nuon storage file** and says nothing about channel row format,
so a reader who follows the link to learn the format learns nothing and a
reader who trusts it will reach for nuon.

## Files touched

- `.mi/prds/06-help/03-browser/prd.md` (only this file)

## What was measured

- `.mi/prds/04-shell/07-quicklist/prd.md` R1: "stored as nuon in XDG state".
  R3 says the quicklist opens as a tv channel with two `--expect` keys. There
  is no row-format requirement anywhere in that node. Confirmed by reading the
  whole file.
- `~/.config/television/cable/quicklist.toml` is where the TAB format actually
  comes from, and it is TAB **because tv's display template says so**:

  ```
  command = "nu -n -c 'source ~/.config/nushell/finder.nu; _recents_lines'"
  display = "{split:\\t:1}    ({split:\\t:3})  {split:\\t:2}"
  output  = "{}"
  ```

  Its own comment records the escaping trap: `\\t` in TOML reaches tv as the
  literal escape `\t`, which tv's template engine treats as the delimiter that
  splits each source row. `output = "{}"` emits the whole row so the runner
  can recover the fields the display hid.
- So the honest chain is: **nuon is the quicklist's storage format; TAB is
  every tv cable's row format, set by `{split:\t:N}`.** Two different layers,
  and `04-shell/07` owns only the first.

## Edits

1. **R1.** Keep TAB-delimited. Replace "mirroring how the quicklist channel is
   built ([04-shell/07](...))" with the real reason and the real exemplar:
   tv's display template addresses fields as `{split:\t:N}`, so a cable's
   source emits TAB-separated columns; `~/.config/television/cable/quicklist.toml`
   is the live exemplar. Name the columns the source emits and state that
   `output = "{}"` emits the whole row so the runner can recover fields the
   `display` string does not show. Carry the escaping constraint with its
   reason: `"\\t"` in the TOML reaches tv as `\t`, and writing a real tab or a
   single backslash breaks the split.
2. **R1, second sentence.** State explicitly that `04-shell/07`'s nuon is the
   quicklist's *storage* format and is not a row format, so the two are not in
   conflict — this is the sentence that stops M-16 being re-filed.
3. **R4.** `ctrl-o` opens "the entry's source PRD". Name the field: it is the
   entry's `source` field, defined by
   [`01-content-model`](../../../../../06-help/01-content-model/prd.md) R2
   (see spec03 — land that first or in the same change). State that the path
   is repo-root-relative and that all 84 live entries resolve in node form
   (`<node>/prd.md`), measured 2026-08-21 by
   `nu tests/help-content-model.nu`, which reports zero entries still on the
   pre-board flat form.
4. Leave `deps` and every other frontmatter field alone. `04-shell/07` stays
   in `deps` — it is still the exemplar for "a cable file plus a small
   runner", which is the part R1's prose keeps.

## Acceptance

- [ ] The false citation is gone: the file no longer contains "TAB-delimited,
      mirroring how the quicklist channel is built".
- [ ] The file names `quicklist.toml` as the exemplar.
- [ ] The file carries tv's field syntax `{split:` so the format is derivable
      from the PRD rather than from a link.
- [ ] The file names the entry's `source` field for R4 rather than the
      undefined phrase "source PRD" alone.
- [ ] The file says, in some form, that `04-shell/07`'s nuon is storage and
      not a row format.
- [ ] No frontmatter field is changed.

## verify

Proved RED against the current tree before being written here (exit 1, all
four clauses failing — including the forbidden phrase, which is found only
because whitespace is normalised first: in the file it straddles a line break
after "topic, key/cmd,").

```
nu -n -c 'let t = (open --raw prds/06-help/03-browser/prd.md | str replace -ar "\\s+" " "); let checks = [[want, phrase]; [false, "TAB-delimited, mirroring how the quicklist channel is built"], [true, "quicklist.toml"], [true, "{split:"], [true, "`source` field"]]; let bad = ($checks | where {|r| ($t | str contains $r.phrase) != $r.want}); if ($bad | is-empty) { print "ok" } else { print ($bad | to text); exit 1 }'
```
