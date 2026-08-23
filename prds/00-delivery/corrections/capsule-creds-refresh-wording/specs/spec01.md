---
est: 0.5h
footprint:
  - home/dot_config/nushell/help/capsule.nuon
  - home/dot_config/nushell/help/why-review.nuon
verify: "nu tests/help-content-model.nu"
---

# spec01 — rewrite the credentials `why` to the shipped refresh

Two edits, one change: the `cmd: "credentials in a capsule"` entry's final
`why` sentence is replaced by the refresh C.3 actually shipped, and the
matching `why-review.nuon` row is re-digested by a reader who did not make the
edit. They land together — `tests/help-content-model.nu` keys the review
digest on `use` **and** `why`, so rewriting the field alone turns the gate red,
and it is supposed to.

## The PRD names the wrong review file, and the gate decides

PRD R3 says the edit invalidates the `use-review.nuon` row. It does not.
`use-review.nuon` keys on `use` + `source` (`tests/help-content-model.nu:414`)
and this change touches neither, so that row stays byte-identical. The file
that goes stale is `why-review.nuon`, which keys on `use` + `why`
(`tests/help-content-model.nu:382`). Measured, not reasoned: with only edit 1
applied, the gate printed one violation and it named `why-review.nuon`'s
digest, while `use-digest` still returned the recorded `d922b7e911810476`.
Read R3 as "the matching review row", and the row is the `why` one.

## What `capsule.nu` actually does

Read out of the shipped `home/dot_config/nushell/capsule.nu`, not out of the
PRD. All three of the PRD's claims hold, and two of them are wider than
the PRD says.

| PRD says | The code does | Route |
|---|---|---|
| synchronous refresh on create | synchronous when `--rebuild` **or** the container does not exist | `capsule.nu:388-389` |
| backgrounded on warm attach | backgrounded on **any** attach to an existing container — running *and* stopped | `capsule.nu:390-392` |
| 60 s staleness short-circuit | the same window guards **both** paths, because the check is the first line of the refresh itself | `capsule.nu:305`, `_capsule_creds_fresh` at `:181-188` |

So the trigger set is: `--rebuild` or a container that does not exist take the
synchronous path; everything else takes `job spawn`. The window is 60 s and it
requires the creds directory to exist, to be non-empty, and **every** file in
it to be younger than `(date now) - 60sec`. One file older than the window
and the whole export runs.

Two facts C.3 measured, both already carried in the code, and neither needs
re-deriving:

- `job spawn` does not survive `nu` exiting. It is safe here because the parent
  blocks in `docker exec -it` for the whole session (`capsule.nu:380-387`,
  `:440`), so the job finishes long before anything inside reads a credential.
- the latency behind the design: `git credential fill` through the `!gh auth
  git-credential` helper 0.75–1.16 s, the keychain read 0.34–0.50 s
  (`capsule.nu:176-180`) — ~1.5 s, against C.2 R2's warm reconnect of "well
  under a second".

One more correction the same sentence carries. The old text said a rotated
token heals "by reconnecting instead of by rebuilding". It heals a capsule that
is **already running**: the creds path is bound as a directory precisely
because the refresh publishes by rename (`_capsule_creds_write`,
`capsule.nu:158-165`) and a file bind would pin the old inode
(`capsule.nu:38-43`); the container reads the store straight off the read-only
mount (`setup-credentials.sh:165-186`, `helper = store
--file=/opt/capsule/creds/git-credentials`). "A cache file the container uses
as its credential store" is right about the file and wrong about the bind, so
the replacement says both.

## Edit 1 — `home/dot_config/nushell/help/capsule.nuon`, line 57

Inside the `cmd: "credentials in a capsule"` record (lines 50–60), the `why`
field **only**. The first three sentences are byte-identical and correct
against the code; the fourth sentence is replaced by three. Do not reflow the
line — NUON strings here are single-line by design.

Replace this sentence:

```
HTTPS credentials are refreshed out of the host keychain on every mount into a cache file the container uses as its credential store, which is what makes a rotated token heal by reconnecting instead of by rebuilding.
```

with this text:

```
The HTTPS credential is exported from the host's credential helper into a cache directory the container reads as its git credential store — synchronously on create and on `--rebuild`, in a background job on any attach to an existing capsule, and on either path skipped while every exported file is under 60 seconds old, because the export costs ~1.5s (`gh` 0.75–1.16s plus a 0.34–0.50s keychain read) — a whole warm reconnect. The directory is bound, never the files: the refresh renames each file into place, so a rotated token reaches even a capsule that is already running.
```

The whole line then reads:

```
        why: "Everything arrives by mount, never in an image layer — `docker history` shows no credential material. `~/.ssh` is mounted read-only and the keys are copied to a container-local directory with 600/700 permissions on first run, with GitHub's host keys pre-added so nothing asks you to trust them. `.gitconfig` is mounted read-only so authorship matches the host. The HTTPS credential is exported from the host's credential helper into a cache directory the container reads as its git credential store — synchronously on create and on `--rebuild`, in a background job on any attach to an existing capsule, and on either path skipped while every exported file is under 60 seconds old, because the export costs ~1.5s (`gh` 0.75–1.16s plus a 0.34–0.50s keychain read) — a whole warm reconnect. The directory is bound, never the files: the refresh renames each file into place, so a rotated token reaches even a capsule that is already running."
```

Three characters are non-ASCII and load-bearing for the digest: the three em
dashes `—` (U+2014) and the two en dashes in `0.75–1.16s` and `0.34–0.50s`
(U+2013). Typing a hyphen instead makes the gate ask for a different digest,
which is the check that the text landed byte-exact.

Nothing else in that record changes — not `cmd`, `title`, `use`, `topic`,
`mode`, `also`, `verify` or `source`. No other entry in the file changes.
The replacement is three sentences and no more. The new `why` is 153 words,
against a corpus maximum of 156 (`terminal.nuon [lit and dim tabs]`) and this
entry's own 93, so a fourth sentence would make it the longest `why` in the
manual.

## Edit 2 — `home/dot_config/nushell/help/why-review.nuon`, line 146

The one `{id: "credentials in a capsule", file: "capsule.nuon", …}` row. Set
`digest` to the value below, set `reviewer` to the reader's session id, add
`author` naming the session that made edit 1, set `date`, and add a `note`
carrying the reading. Keep `id` and `file` as they are. The row carries no
`author` and no `note` today; both are added.

### The digest, reproduced

`tests/help-content-model.nu:382` is the whole recipe:

```nu
def why-digest [use: string, why: string] {
    $"($use)\n--\n($why)" | hash sha256 | str substring 0..15
}
```

The `use` string, a literal newline, `--`, a literal newline, the `why`
string; SHA-256; the first 16 hex characters. No trimming, no normalisation,
no `id` and no `file`.

Reproduced against this row's **recorded** digest before touching anything, so
the recipe is known-good rather than inferred:

```
recorded in why-review.nuon:146    8b2e7d51f3dbda84
why-digest <use> <old why>         8b2e7d51f3dbda84   ← matches
why-digest <use> <new why>         311c76d74a9286d2   ← the new value
```

So **`digest: "311c76d74a9286d2"`**. Do not take that on trust either: edit 1
alone makes the gate print it, verbatim, which is step 2 of the ritual in
`why-review.nuon`'s header. Confirmed on a copy of the help directory,
2026-08-23, with `nu tests/help-content-model.nu <copy>`:

```
1 violation(s):
  capsule.nuon [credentials in a capsule]: `use`/`why` changed since the
  recorded review — re-read the pair for restatement, then set digest to
  311c76d74a9286d2
```

The same copy with edit 2 applied printed `ok`. A *different* digest means the
text is not byte-identical to the block above. Fix the text; do not record
the digest the gate offers.

## Who may be the reviewer

The gate (`tests/help-content-model.nu:795`) fails any row whose `author`
equals its `reviewer`, and `author` is optional — so honesty about authorship
is what makes the check bite. The convention is
[`cdi-manual-source` spec01](../../cdi-manual-source/specs/spec01.md)'s,
followed rather than reinvented:

- **The session that performs edit 1 is the row's `author`.** It rewrote half
  the digested pair. "I only replaced one sentence" does not exempt anyone.
- **The `reviewer` is a different session that did not make the edit**, and it
  is dispatched to *refute* the pair, not to bless it. The way available to an
  afk implementer is a subagent: spawn a reader, hand it the new text and the
  routes below, record what it returns. House id convention from the rows
  already in the file: `<implementer-id>-r1`, or `reader-<lane>`. Any two
  distinct strings satisfy the gate; a subagent that actually read is what
  satisfies the record.
- **What the reader is asked to read**, so the `note` is a reading and not a
  restatement:
  - the `why` against the entry's `use` for restatement, which is the clause
    this file exists to hold. The `use` names no mechanism at all ("Nothing to
    run: … all just work"), so the whole `why` is new information — say so
    against the text, not from this line.
  - the refresh claims against the shipped code: `capsule.nu:388-392` for the
    trigger set, `:304-313` and `:181-188` for the window and its reason,
    `:154-165` and `:333-352` for the rename-plus-directory-bind, and
    `home/dot_config/capsule/executable_setup-credentials.sh:165-186` for the
    container reading the store off the read-only mount.
  - the three preserved sentences, which are carried forward unedited and
    therefore inherit no review of their own: no-COPY/no-ADD
    (`capsule.nu:28-31`, and C.1's Dockerfile gate), the SSH copy with 600/700
    and pre-added host keys (`setup-credentials.sh:51-80`), and `.gitconfig`
    mounted `:ro` (`capsule.nu:339-342`).
  - the standing reading it replaces, `why-review.nuon:146` by
    `cc-1787301962`, which carries no note. There is nothing to carry forward,
    so the new note is the first reading of record for this entry.

If the reader refutes the new text rather than vouching for it, that is a
finding and the text changes before the row is written. The digest follows
the text, never the reverse.

## Out of limits

`tests/help-content-model.nu` is **run, never edited**; no constant in it is
transcribed from this entry. `use-review.nuon` is **not touched** — its
`use`/`source` digest for this entry is `d922b7e911810476` before and after,
and editing that row would be recording a reading nobody did. `capsule.nu`,
`setup-credentials.sh` and the `01-capsule/03-credential-propagation` folder
are read only: PRD "Out of scope" puts the design beyond this node, and the
manual is the side that was wrong. No other loose `why` in the corpus is
swept. `gates/waves.tsv` and `gates/manual/wave*.md` need no segment.

## Acceptance

- [x] `nu tests/help-content-model.nu` prints `ok` and exits 0, reporting 92
      entries across 4 files, the count it reports today — unchanged by an
      edit that replaces one field value.
- [x] With edit 1 applied and edit 2 not, the gate prints exactly one
      violation, and it is `capsule.nuon [credentials in a capsule]: … set
      digest to 311c76d74a9286d2`. Quote that line in the report.
- [x] `open home/dot_config/nushell/help/capsule.nuon | where cmd ==
      "credentials in a capsule" | get why.0` contains the backgrounded-attach
      clause and no longer contains `on every mount`. **Amended at
      implementation:** the reviewer's refutation (below) rewrote the clause to
      `backgrounded on any attach to an existing capsule`, so the string
      checked is that one. Measured: contains it `true`, contains `on every
      mount` `false`.
- [x] Every other field of the entry is byte-identical, checked as a
      fingerprint: `open … | where cmd == "credentials in a capsule" | first |
      reject why | to nuon | hash sha256 | str substring 0..15` prints
      `81987b546a4910ab`, the value it prints today (measured 2026-08-23).
- [x] `git diff -U0 home/dot_config/nushell/help/capsule.nuon` shows exactly
      one new `-`/`+` pair inside the `cmd: "credentials in a capsule"`
      record, and it is the `why` line. The file has other uncommitted hunks
      under this edit — a tree-wide `.mi/prd/` -> `prds/` rename touches every
      `source` field, including this record's, and other landed work rewrote
      neighbouring `use` fields — so the box is about this record's `why`, not
      about a clean whole-file diff. The fingerprint box above is the stronger
      signal.
- [x] `why-review.nuon`'s row for this entry carries the digest the gate
      printed for the text that actually landed. **Not `311c76d74a9286d2`.**
      That value was correct for this spec's draft wording and was reproduced
      twice (independently, and from the gate) — but the reviewer refuted two
      of the draft's claims, the wording changed, and the digest followed the
      text as this spec requires. The landed value is
      `digest: "df68bce54ec761bf"`, printed verbatim by the gate before it was
      recorded.
- [x] That row's `reviewer` and `author` are both present and different, the
      `author` naming the session that made edit 1 and the `reviewer` naming
      the session that read the pair.
- [x] That row's `note` gives the reading — the `why` against the `use` for
      restatement, and the refresh claims against `capsule.nu` with line
      numbers — rather than asserting that a reading happened.
- [x] `use-review.nuon`'s row for this entry is untouched: `open
      home/dot_config/nushell/help/use-review.nuon | where id == "credentials
      in a capsule" | get digest.0` still prints `d922b7e911810476`, and
      `git diff -U0` on that file shows no hunk at that row. The file carries
      other uncommitted hunks from other lanes; this box is about the one row.
- [x] The report quotes the entry's new `why` and `capsule.nu:388-392` plus
      `:304-313` side by side, so the match is on the record rather than
      asserted (PRD Acceptance box 2).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# baseline, before either edit
nu tests/help-content-model.nu | tail -1          # expect: ok

# after edit 1 only — the gate names the digest to set
nu tests/help-content-model.nu 2>&1 | grep 'credentials in a capsule'
# expect: … re-read the pair for restatement, then set digest to
#         311c76d74a9286d2

# after edit 2
nu tests/help-content-model.nu                    # expect: ok, exit 0
nu -n -c 'open home/dot_config/nushell/help/capsule.nuon |
  where cmd == "credentials in a capsule" | first | reject why | to nuon |
  hash sha256 | str substring 0..15'               # expect: 81987b546a4910ab
git diff -U0 home/dot_config/nushell/help/capsule.nuon
nu -n -c 'open home/dot_config/nushell/help/use-review.nuon |
  where id == "credentials in a capsule" | get digest.0'
sed -n '388,392p;304,313p' home/dot_config/nushell/capsule.nu
```

## What the review changed, recorded at implementation

The ritual fired. `implementer-creds-wording-r1` returned **REFUTE** on the
draft wording of the final sentence-group, and a second, independently
dispatched reader reached the same central finding, so it is treated as
settled rather than as one reader's opinion. Three fixes, all forced:

- **The latency was mis-billed.** The draft made `The HTTPS credential` the
  subject and then charged it `~1.5s (`gh` 0.75–1.16s plus a 0.34–0.50s
  keychain read)`. `_capsule_refresh_git` (`capsule.nu:201-222`) is only the
  `git credential fill`; the 0.34–0.50s keychain read is
  `_capsule_refresh_claude_credentials` (`:236-238`), a different file. The
  `~1.5s` is the four-call refresh that `_capsule_creds_fresh` guards
  (`:304-313`), which is also the code's own figure at `:382`. Now
  `the four-file export costs ~1.5s (git's helper 0.75–1.16s, an agent
  keychain read 0.34–0.50s)`.
- **`a whole warm reconnect` understated the reason.** `:380-383` says that
  cost *would break* C.2 R2's sub-second warm attach, so the export is over
  the budget, not equal to it. Now `over the whole warm-attach budget`.
- **`The directory is bound, never the files` contradicted this same `why`.**
  `.gitconfig` and the setup script are file binds (`:339-342`, `:347-350`),
  and the sentence three before it says `.gitconfig` is mounted. Scoped to the
  creds path: `That path is bound as a directory, never file by file`.

The corrected `why` is **153 words** — the same as the draft, so the corpus
maximum of 156 is still not approached.

Two further imprecisions live in the three *preserved* sentences, which this
node's one-sentence scope does not reach. They are recorded in the review row
and want their own correction: `*.pub` is installed at 644
(`setup-credentials.sh:67`) so `600/700` does not describe every copied key,
and the no-prompt guarantee rests on `StrictHostKeyChecking accept-new`
(`:115`) rather than on the best-effort `ssh-keyscan -T 5` pre-add
(`:121-130`).
