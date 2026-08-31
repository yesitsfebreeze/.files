# spec02 — hold `use` to the real gesture with a recorded review, the way `why` is already held

verify: `nu tests/help-content-model.nu`

## Goal

Close the node's last substantive stub — R2's `use` sub-box and R5's stub 2,
which are the same clause counted twice: "`use` describes the real gesture,
including what to press next and what comes back."

Three sessions have left it open on one argument, quoted from the box:

> Whether a `use` describes the gesture the configuration actually performs is
> truth against a live surface; 80 of 84 entries have no deployed surface to be
> checked against.

**That premise is wrong, and checking it is what this spec turns on.** Measured
on 2026-08-21 against the live corpus:

- Every one of the **84** entries carries a `source:` naming a PRD, and **all
  84 resolve** — 29 distinct files, `path exists` true for every one. The gate
  already enforces that resolution at `tests/help-content-model.nu:608-631`.
  The `source` PRD is the specification the `use` is supposed to describe, and
  it exists today for every entry.
- `~/.config/nushell`, `~/.config/nvim` and `~/.config/wezterm` all exist, so
  **79 of 84** entries (shell 41, nvim 27, terminal 11) additionally have a
  live route to read. Only `capsule.nuon`'s 5 entries have no surface at all —
  and `capsule` is the one file whose header already says the CLI is unbuilt.
- The precedent is this node's own. The `Ctrl-T` defect that the box cites as
  proof the clause is ungated was found *by exactly this method* — read off
  `config.nu:635` → `config.nu:686` → `finder.nu:33`. The method works; what
  was missing was the obligation to run it.

And the boundary is settled by the ticket's own wording, so this is not
poaching: R2 "carves the resolution half out of the `verify` sub-box only, and
[`coverage`](../coverage/prd.md) R5 is about verify targets resolving, not
about `use` prose." `use` prose is this node's, unexempted.

So build for `use` what `why-review.nuon` already is for `why`: a digest-keyed
record that makes the *obligation* mechanical while the reading stays human.
Both failed lexical proxies are recorded in `README.md` and in the gate's
comments — **do not build a third**; that is the trap this corpus has fallen
into twice.

## Files

- `home/dot_config/nushell/help/use-review.nuon` — **new**; one row per entry
- `tests/help-content-model.nu` — a `use-digest`, a `use-review` gate block
  mirroring the `why-review` block at ~line 655-720, and `selftest` controls
- `home/dot_config/nushell/help/README.md` — the ritual, under `## Writing an
  entry` beside the `why` clause it parallels
- `home/dot_config/nushell/help/{shell,nvim,terminal,capsule}.nuon` — **only**
  where the review finds a `use` that misdescribes its source; every edit is a
  finding, never a sweep

Lane edge, restated because prior sessions flagged it: `tests/` is outside the
`home/dot_config/nushell/help/` directory this node's lane owns, but it holds
this node's own `verify:` and every prior session on this node edited it.

## What to build

**1 — the record.** `use-review.nuon`, rows shaped exactly like
`why-review.nuon`'s: `{id, file, digest, reviewer, date}` required, `author`
and `note` optional. Header carries the ritual and the reason, the way
`why-review.nuon`'s does.

**2 — the digest.** `use-digest` over the `use` **and** the `source` together —
`$"($use)\n--\n($source)"`, hashed and truncated the way `why-digest` is at
`tests/help-content-model.nu:354`. Keying on both is the point: a review says
"this prose matches that spec", so editing *either* side must invalidate it.
`why-digest` keys on one pair; this keys on the other.

**3 — the gate.** Mirror the `why-review` block, with the four failure modes it
already has, plus the coverage difference: `why` is optional so only
`why`-carrying entries need rows, while **`use` is required, so all 84 entries
need a current row** and an entry with none is a violation. Reuse
`bad-string`/`bad-field` rather than re-spelling the shape checks — the comment
at line 88-92 asks for exactly that. Keep the `author == reviewer` refusal and
the empty-record abort.

**4 — the review.** Read all 84 `use` fields against their `source` PRD, and
for the 79 with a live surface against the live route as well. Fix what is
wrong. Where a `use` and its source PRD genuinely disagree about the gesture,
**the PRD wins and the `use` changes** — a `use` may not be "fixed" by editing
another node's PRD (law 2); if the PRD looks wrong, that is a
[`corrections`](../../../00-delivery/corrections/prd.md) filing, and the entry
gets a `note` on its row saying so.

**5 — the independence rule, which constrains the order of work.** The gate
refuses `author == reviewer`. Any entry whose `use` this session rewrites gets
`author: <this session>` on its row and **cannot be reviewed by this session** —
it needs the refuting reader of worker.md §5, exactly as the four self-vouched
`why` rows were handled across `cc-1787301962` → `cc-1787432671`. Plan for
that: review first, rewrite second, and hand the rewritten rows on.

## Acceptance

- [x] `use-review.nuon` exists, is version-controlled (`git ls-files` lists
      it), and holds **84** rows — one per entry across the four surface files.
      `git ls-files home/dot_config/nushell/help/` lists it alongside the four
      surface files, `topics.nuon`, `why-review.nuon` and `README.md`;
      `open use-review.nuon | length` → `84`, and the gate's own per-entry pass
      is what proves the one-per-entry mapping rather than the count alone.
- [x] Deleting one row exits 1, naming the entry and the digest to set.
      Deleted `shell.nuon|Ctrl-R` from a scratch copy: exit 1,
      ``shell.nuon [Ctrl-R]: has no row in use-review.nuon — read the `use`
      against .mi/prds/04-shell/05-history/prd.md and the live route, then
      record the reading with digest eef0af4b64a4fd38``.
- [x] Editing one entry's `use` by a single word exits 1 with a
      digest-drift message naming that entry — run it, quote it.
      Prefixed `shell.nuon [grep]`'s `use` with one word: exit 1,
      ``shell.nuon [grep]: `use`/`source` changed since the recorded reading —
      re-read the gesture against the spec, then set digest to
      67674882ef66ff31`` (and, separately, the `why-review` drift message,
      because that record keys on the `use` too).
- [x] Editing one entry's **`source`** and nothing else also exits 1. This is
      the clause that separates this record from `why-review.nuon`; if it
      exits 0, the digest is keyed wrong.
      Re-pointed `shell.nuon [grep]` from `04-shell/02-aliases-utilities` to
      `04-shell/01-core-config`, touching nothing else: exit 1,
      ``shell.nuon [grep]: `use`/`source` changed since the recorded reading …
      set digest to 687ee72bc5657421``. **And exactly one new violation** — the
      `why-review.nuon` row did not fire, which is the proof that the two
      records key on different pairs rather than duplicating each other.
- [x] Renaming an entry's `key`/`cmd` exits 1 **twice** — once for the entry
      with no row, once for the row reviewing an entry that no longer exists —
      so the record cannot drift in either direction.
      `cmd: "grep"` → `"grepp"`: exit 1, and both halves appear —
      ``shell.nuon [grepp]: has no row in use-review.nuon …`` and
      ``use-review.nuon: row `shell.nuon|grep` reviews a `use` that no entry
      carries any more — delete it, or the record starts vouching for text that
      is gone``. (The same rename also fires the two `why-review` halves, the
      dangling `also` and the coverage miss, which is the predicted cascade.)
- [x] Deleting `use-review.nuon` exits 1; an empty record aborts with the
      "refusing to pass a check with nothing to check" message rather than
      passing vacuously.
      Deleted: exit 1, ``use-review.nuon: missing — every `use` is held by a
      recorded reading against its `source` PRD …``. Replaced with `[]`: exit 1,
      `use-review.nuon records no reviews — refusing to pass a check with
      nothing to check`, printed as an abort rather than counted as a
      violation.
- [x] Adding `author: <X>` to a row whose `reviewer` is `<X>` exits 1 with the
      self-vouching message.
      Added `author: "impl-H-1-r1"` to the `shell.nuon|zz` row, whose reviewer
      is that reader: exit 1, ``use-review.nuon [zz]: reviewer and author are
      both impl-H-1-r1 — a `use` reviewed by the session that wrote it is the
      record vouching for itself; it needs a reader who did not write it``.
      An empty `reviewer` is refused by the same shape pass that `why-review`
      uses (`bad-string`).
- [x] A `selftest` control asserts `use-digest` is stable for one pair and
      that it *changes* when the `source` half changes — making the digest
      blind to `source` trips it.
      Three controls: stability, `use`-sensitivity, `source`-sensitivity.
      Rewriting `use-digest` to hash the `use` alone on a copy of the gate:
      exit 1, ``selftest: use-digest ignores a changed `source` — an entry
      could be re-pointed at a different PRD and keep a review that read it
      against the old one`` (plus the 93 rows whose digests then no longer
      match, which is the same fact from the other side).
- [x] `grep -c` for any row where reviewer equals author returns 0, and every
      entry whose `use` this session rewrote carries an `author` and a
      `reviewer` that differ.
      `open use-review.nuon | where {|x| ($x.author? | default "") == $x.reviewer} | length` → `0`.
      14 rows carry `author: "impl-H-1"` — the 14 entries rewritten this
      session — and all 14 carry `reviewer: "impl-H-1-r5"`, a reader that wrote
      none of them. The other 70 rows carry no `author`, because their text
      predates this session and inventing one would be the false record
      pointing the other way.
- [x] Each `use` that was **changed** is listed in the evidence with the live
      route or PRD line that was read (`file:line`), the way the `Ctrl-T` fix
      was — a finding a later reader can re-check, not a claim to trust.
      All 14 are recorded, each with the route or PRD line, but **in the `note`
      field of their own `use-review.nuon` row rather than in this prd.md's
      `## Evidence`** — this worker's footprint does not include prd.md, and
      the landing session owns that block. The rows are the more durable
      place anyway: the gate refuses to let one drift away from the text it
      describes. Sample, so the shape is visible without opening the file —
      telescope: ``sorting_strategy unset, so descending applies
      (telescope.nvim/lua/telescope/config.lua:144-145); Picker:get_row =
      max_results - index (pickers.lua:376-382) puts the BEST match on the
      BOTTOM row … so <Tab> (worse) moves UP the screen``. LSP keys:
      ``]d/[d are vim.diagnostic.jump({count=...}) with no float
      (runtime/lua/vim/_core/defaults.lua:263-269) … the key that opens the
      bordered float is <C-W>d (:280-282)``.
- [x] Each `use` that was read and **left standing** but is borderline carries
      a `note` on its row giving the reading, matching how the four borderline
      `why` pairs were handled.
      56 of the 84 rows carry a `note` — the 14 findings plus 42 readings that
      qualify an entry left standing. They are not decoration: several are
      defects this node cannot fix, recorded where they will be found rather
      than dropped. `ls -D` is spec-correct but dead live (`^du -sb` at
      `config.nu:93`, live bug L-1); `cc [...args]`/`cr [...args]` always show
      a login picker (`config.nu:213,231-239`) although `04-shell/08` R3 says a
      single profile launches directly, and that divergence is on **no**
      declared list; `terminal.nuon [Ctrl+V]` and `[Ctrl+C]` cite an epic that
      contains no requirement for them; `capsule list`'s subcommand name is the
      manual's invention, because R6 names none.
- [x] The 5 `capsule.nuon` entries are reviewed against
      [`01-capsule`](../../../01-capsule/prd.md) alone, and their rows say so —
      no capsule row may claim a live reading, because `capsule` is absent from
      `PATH`.
      `which capsule` finds nothing and `git ls-files` holds no Dockerfile or
      CLI, both checked by the reader before it read anything. All five rows
      open with `PRD-only, no live reading`, and every `file:line` they cite is
      under `.mi/prds/01-capsule/`.
- [x] `nu tests/help-content-model.nu` exits 0 on the finished tree with the
      entry/topic summary intact.
      `help content model: 84 entries across 4 files, 9 topics, 10 prose-only`
      … `ok`, exit 0, with the nine-topic table unchanged.
- [x] `bash tests/live-bugs.sh` still exits 0.
      Exit 0 — `OK — every live-bug record still matches the config it
      describes, and every row is owned`. Re-run after the last edit.

## Out of scope

- **A third lexical proxy for anything.** Whole-text containment (mean 0.11)
  and best-sentence containment (mean 0.157) were both measured and both put
  the known defects at or below the corpus mean. `README.md` and the gate
  comments record this so it is not rebuilt.
- A `title` word floor. `## Findings` records that omission as a deliberate
  decision pending measurement against the 84 live titles, and no requirement
  names it.
- Whether a `verify` target resolves ([`coverage`](../coverage/prd.md) R5), and
  any live-introspection resolver ([`04-drift-check`](../../04-drift-check/prd.md)).
- Editing the epic's invariants to state the sibling obligation. `## Findings`
  flags it as the epic's amendment to make; law 2 forbids making it here.
- Backfilling `author` onto `why-review.nuon`'s 47 pre-field rows. Inventing
  one is the same false record pointing the other way, as that file's header
  already says.
