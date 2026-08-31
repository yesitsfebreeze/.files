# spec03 — listing, aliases, and the epic

Ticket: W0.4b (`00-delivery/corrections/w0-4-s2-corrections/shell`)
Covers ticket requirements **R3** (L-1, the `du -sb` bug) and **R4** (M-7, the
`bb`/`ba` removal), plus the two S3 hygiene items that land in these files —
the duplicated `cdi` statement and the stale "still-open" reference to a
decision answered today.

Est: **0.4h**

## Files touched (no other spec in this ticket writes them)

- `.mi/prds/04-shell/06-listing/prd.md`
- `.mi/prds/04-shell/02-aliases-utilities/prd.md`
- `.mi/prds/04-shell/prd.md` (the epic)

## Do not disturb (landed 2026-08-21, earlier today)

Epic invariant **I3** (fzf, from `decisions/fzf`) and invariant **I5** plus
the Goal and Out-of-scope rewrite (from `decisions/tinty`). The only epic edit
in this spec is item 7 below — one clause inside `## Out of scope`. Guards
**EP-2** and **EP-3** fail if I3 or I5 is damaged.

## The live facts, measured 2026-08-21

| What | Evidence |
|---|---|
| `ls -D` cannot work here | `config.nu:93` `^du -sb ...$dirs e> /dev/null`; `/usr/bin/du -sb <path>` on this host prints `du: invalid option -- b` and the usage banner |
| and it fails silently | `e> /dev/null` swallows that banner, `parse -r` finds no rows, `dir_sizes` is `{}`, and `get --optional … \| default $row.size` falls back to the inode size — so `ls -D` looks like it worked and shows the flat ~4 KB it was written to replace |
| the replacement | `/usr/bin/du -sk` works: `du -sk .mi` → `1324` (KiB). `gdu` is **not installed** and is not in `05-platform/02` R7's required set, so choosing it would mean adding coreutils to the required set for one flag — in another lane's file, for a flag `-sk` already covers |
| `-sk` is also the *right* number | `-sb` is apparent size; `-sk` is allocated blocks. R3 asks for "recursive on-disk size", which is what `-sk` measures |
| `bb`/`ba` call `brr` | `config.nu:244-245` — `alias bb = brr`, `alias ba = brr --attach`. Both binaries exist, so the name is load-bearing |
| burrito is settled | `.mi/prds/README.md` — `DO NOT PORT — burrito`, decided 2026-08-20, listing the `bb`/`ba` aliases as part of what comes out |
| the duplicate requirement number | `02-aliases-utilities` carries `**R4** — Sessions` *and* `**R4** (from 05-platform/01 req 4)` — and the second is a verbatim restatement of its own **R3** (`rr` = `chezmoi update --force`) |
| the wallpaper/opacity decision is answered | `decisions/wallpaper-opacity`, 2026-08-21: both features dropped, `Ctrl+Shift+B` to capsule. The epic still calls it "the still-open `wallpaper-opacity` decision" |

## What to write

### `06-listing/prd.md`

1. **R3 — L-1, with the fix and the reason for the fix.** State that the live
   implementation runs `du -sb`, that macOS `du` has no `-b`, and that the
   rebuild uses **`du -sk`** and multiplies by **1024** to reach bytes. Give
   the reason `gdu` was not chosen: it would add coreutils to
   `05-platform/02` R7's required set — another node's file — to buy a flag
   `-sk` already provides. Note that `-sk` measures allocated blocks rather
   than apparent size, which is what R3's own wording ("on-disk size") asks
   for, so this is a correction in both directions.
2. **R3 — the constraint that matters more than the flag.** `e> /dev/null`
   is why this survived: the error was discarded, the parse found nothing,
   and the code fell back to the inode size, so the feature *looked* like it
   worked. The rebuild must not discard `du`'s stderr without also detecting
   the failure — a `du` that errors has to surface once, not degrade
   silently into the very sizes the flag exists to replace. Carry the reason,
   not just the rule.
3. **Header.** Close `source: "Decorated ls +` → `"Decorated ls + auto-list on
   cd"` (C 5 / U 8) and link `capabilities-nushell.md`.

### `02-aliases-utilities/prd.md`

4. **R4 — M-7, and then the whole requirement goes.** Record in `## Out of
   scope` that the sessions aliases are `DO NOT PORT`: they invoked **`brr`**,
   not `burrito` (M-7 — both binaries exist, so the name matters), and
   burrito itself was dropped on 2026-08-20 (link the README's `DO NOT PORT —
   burrito` entry). Delete the requirement box. **Do not renumber the
   surviving requirements** — the tree cites requirements by number; a gap at
   R4 is correct and a renumbered R5 is a broken citation.
5. **The duplicate R4.** The stray `**R4** (from 05-platform/01 req 4)` line
   says exactly what **R3** says. Fold its cross-reference note into R3 and
   delete the line: one fact, one place. After this, no requirement number
   appears twice.
6. **R1 — the duplicated `cdi` (S3).** `cdi` is stated here *and* in
   `03-zoxide` R2, which owns it (and which `decisions/fzf` rewrote today —
   it is not to be edited by this ticket). Drop `cdi`→`zi` from the alias
   list and cross-link `03-zoxide` R2 instead. Also close the truncated
   header: `"Aliases and small utilities"` (C 2 / U 8), with the inventory
   link.

### `prd.md` (the epic) — one clause only

7. **`## Out of scope`** calls the opacity picker's fate "the still-open
   `wallpaper-opacity` decision". It was **answered 2026-08-21**: both the
   wallpaper pipeline and the opacity toggle are dropped, the picker keeps
   its `DEFER` (deferred is not refused), and `Ctrl+Shift+B` went to capsule.
   Replace "still-open" with the answer and its date, and keep the link.
   Touch nothing else in this file — I3 and I5 are other lanes' work and the
   guards check them.

## Acceptance

- [ ] **AL-1** `burrito` appears in `02-aliases-utilities/prd.md` only under
      its `DO NOT PORT` record.
- [ ] **AL-2** the real binary name `brr` is on the record.
- [ ] **AL-3** **M-7** is cited.
- [ ] **AL-4** `cdi` is stated at most once here and the file cross-links
      `03-zoxide`.
- [ ] **AL-5** no requirement number appears twice.
- [ ] **AL-6** the header is a closed quotation naming the inventory.
- [ ] **LS-1** *(guard, green now — must stay green)* `-sb` never appears in
      `06-listing/prd.md` except beside **L-1**.
- [ ] **LS-2** the replacement flag `-sk` is specified.
- [ ] **LS-3** the KiB→bytes multiplier `1024` is specified.
- [ ] **LS-4** the discarded-stderr mechanism is named next to **L-1** and
      constrained.
- [ ] **LS-5** the header is a closed quotation naming the inventory.
- [ ] **EP-1** the epic no longer describes the wallpaper/opacity decision as
      open.
- [ ] **EP-1b** the disposition carries its decision date.
- [ ] **EP-2** *(guard, green now — must stay green)* invariant I3's fzf text
      is untouched.
- [ ] **EP-3** *(guard, green now — must stay green)* invariant I5's tinty
      text is untouched.

## verify

```
bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec03
```

**Proved RED on 2026-08-21** against the current tree: `4/15 passed (11
FAILED)`. The four passes are LS-1, EP-1b, EP-2 and EP-3 — regression guards
that are green by design; a FAIL there means the implementer damaged work that
landed today or reintroduced `du -sb` unlabelled.
