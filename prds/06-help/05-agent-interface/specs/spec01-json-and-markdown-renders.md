---
est: 1.25h
footprint:
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/why-review.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - tests/help-agent.sh
  - tests/shell-help.sh
---

# spec01 — `help --json`, `help --md`, and the gate that pins the fields

Two renderers over the corpus reader that
[`02`](../../02-help-command/prd.md) already built, one validation block, one
`also` link, and one standing gate. No new module, no new file under
`home/`: `help.nu` already holds `_help_corpus`, `_help_topics` and
`_help_by_mode`, and this node adds nothing to the data — R1's "one content
source, many renderers" means these two renders are *shape only*, exactly as
the file's own LAYOUT ONLY, NEVER CONTENT header says.

**`est` calibration.** [`03-browser`](../../03-browser/prd.md) is the nearest
node of the same kind: specced at 1.75h across two spec files, implemented in
roughly 24 minutes. This node is strictly smaller than that one — no cable
file, no `tv`/`chezmoi`/`nvim` stubs, no `config.nu` or `finder.nu` wiring, no
process spawned at all — but its gate needs a real nushell and four
counterfactuals. 1.25h, in one spec file because splitting a job this size
across two makes the implementer read two files for one file's worth of work.

## Measured, 2026-08-24, on this machine (nushell 0.114.1)

**The baseline is a live falsehood, and it is this node's whole point.**
With the repo's `help.nu` and corpus staged in a scratch `HOME`:

```
$ HOME=$S nu -n -c 'source ~/.config/nushell/help.nu; help --json'
Error: nu::parser::unknown_flag
  x The `help` command doesn't have flag `json`.
```

`--md` fails identically. Meanwhile the *shipped* corpus already documents
both: `home/dot_config/nushell/help/shell.nuon` carries `cmd: "help --json"`
and `cmd: "help --md"` in the `agents` topic, each with
`verify: [{kind: "command", name: "help"}]` and
`source: "prds/06-help/05-agent-interface/prd.md"`, and the `config`-topic
`help` entry's `also` names `help --json`. So the manual currently promises
two flags the command rejects at parse. That is the red this node turns
green, and no other requirement on the board is closing it.

Measured with the same staging, all **computed, never frozen** — four
documents on this board had a stale count corrected on 2026-08-23, and this
gate asserts shape and internal agreement rather than totals:

| quantity | today |
|---|---|
| entries across the four surface files | 92 |
| topics in `topics.nuon` | 9 |
| entries carrying a `why` | 59 |
| `verify: prose` entries | 13 |
| entries with `mode: "terminal"` (the host-only set) | 16 |

Five more facts that shape the code below.

1. **`core-help` is not reachable from a render that must run without
   config.** `core-help` is an *alias* defined in `config.nu`; under `nu -n`
   the name binds as an external at parse time and dies at runtime. This is
   the same measurement `_help_preview`'s header records, and it applies here
   for a second reason: `--md` over 28 `command`-kind entries would shell out
   to `std/help` 28 times. **Neither new render may name `core-help`**, and
   the gate asserts it two ways.
2. **One live entry id is shell-hostile.** `Neovim's own LSP keys` — the
   apostrophe that forced [`03`](../../03-browser/prd.md)'s preview to
   address a row index. The answer *here* is not a second handle: it is that
   the JSON is complete, so an agent never has to pass an id back through a
   shell to learn anything. A corpus row index is deliberately **not**
   published — an index shifts whenever an entry is added, and an unstable
   handle inside a stable interface is worse than no handle.
3. **`tests/shell-help.sh:539` asserts the overview's Go-deeper line by
   substring** (`$GREP -oF 'help <topic> · help <query> · help <entry> ·
   help --all · help --fuzzy'`). Appending to the **end** of that line keeps
   it green; inserting anything *inside* it turns 02's gate red. Append only.
4. **`tests/shell-help.sh:208-213` carries a count that this node makes
   stale**: "the only trailing-`#` lines in the file are the **seven** flag
   comments in that signature". Two more flags land here, so the number goes
   to nine. Drop the number rather than bump it — a mechanism survives being
   re-measured, a number does not — and leave the claim (`the only
   trailing-#` lines are the flag comments in that signature) intact, because
   `strip_comments` depends on it.
5. **An `also` edit triggers no re-review.** `tests/help-content-model.nu`'s
   `why-digest` keys on the `(use, why)` pair and `use-digest` on the
   `(use, source)` pair — verified in that file's own selftest controls. This
   spec writes **no** `use`, `why` or `title` prose, so no digest changes and
   nothing in `why-review.nuon` or `use-review.nuon` needs a new reading.
   The two review files are in the footprint so the orchestrator serialises
   this node against anything that *does* rewrite corpus prose. If the
   implementer finds a digest moving, that is a surprise: **stop and report
   it — do not record a review of your own writing.**

`help --check` is **not** in this node. It does not exist today
(`06-help/04-drift-check` is `open` behind 14 deps) even though `AGENTS.md`
cites it as a working gate; see the report's findings.

## 1 — `home/dot_config/nushell/help.nu`: one normaliser, two renders

Add three defs in the `── the renders ──` section, below
`_help_all_table` and above `_help_entry_detail`. The section's existing
header comment already says what governs them — "Column names are an
interface (06-help/05-agent-interface R1). Renaming one is a breaking change,
not a tidy-up" — so extend that comment to say the same of the JSON keys and
point at this spec.

**`_help_norm`** — the shared row shape, and the canonical field list. Takes
a corpus list from the pipeline, returns one record per entry with **exactly
these eleven keys, in this order**:

| key | value |
|---|---|
| `id` | `key` if non-empty, else `cmd` — the same derivation `_help_corpus` already does, and the field an agent should address entries by |
| `key` | the corpus `key`, or `""` — non-empty means this entry is a keystroke |
| `cmd` | the corpus `cmd`, or `""` — non-empty means this entry is an invocation |
| `title` | verbatim |
| `use` | verbatim |
| `topic` | verbatim |
| `mode` | verbatim (`shell`, `nvim:normal`, `nvim:visual`, `nvim:insert`, `terminal`, `container`) |
| `also` | the corpus `also`, or `[]` |
| `why` | the corpus `why`, or `""` |
| `verify` | verbatim — the list of `{kind, name?}` records |
| `source` | verbatim, repo-root relative |

Optional corpus fields are **materialised with an empty default, never
omitted**: `jq '.entries[].why'` must never hit a missing key, which is the
difference between an interface and a dump. `key` and `cmd` are both emitted
for the same reason, and because which one an entry carries is itself
information.

**`_help_json [m: string]`** — returns the JSON **text** (via `to json`, so a
caller gets one document whether it pipes to `jq` or to `from json`), shaped

```
{topics: <topics.nuon verbatim: id, title, summary>, entries: [<_help_norm rows>]}
```

No per-topic entry count and no `version` key: both are derivable from
`entries`, and a stored count is exactly the stale-number shape this board
keeps correcting. Entry order is built the way `_help_all_table` builds it —
iterate `_help_topics | get id`, filter the corpus, `flatten` — so
`--json`, `--md` and `--all` agree **by construction** rather than by a sort
happening to be stable. Honour `--mode` through `_help_by_mode`, like every
other render.

**`_help_md [m: string]`** — returns one plain markdown string:

- an `# ` H1, then one line saying the document is generated by `help --md`
  and that `help --json` is the same content as one JSON document. No count
  in that line.
- per topic, in spine order and skipped entirely when the `--mode` filter
  empties it: `## <id> — <title>`, blank line, the topic `summary`.
- per entry: `### <id>`, blank, `title`, blank, `use`, then `why: …` and
  `also: a, b` only when non-empty, then `mode: …` and `source: …`.
- a `mode: "terminal"` entry's mode line carries the **same host-only
  marker** `_help_entry_detail` already appends —
  `" (host-only — the terminal is outside a capsule)"` — which is R6 in this
  render. Use one shared literal, do not retype it.
- the entry id goes in the H3 **unquoted and unbackticked**: one live id
  contains an apostrophe, and no id needs fencing to survive markdown.
- no `std/help` tail, ever (see measured fact 1).

Measured on a prototype of exactly this shape: 1137 lines, 9 `## `, 92
`### `, 16 host-only markers, and the JSON id sequence equal to
`help --all | get key`.

## 2 — the flag plumbing, and the clause numbering that must not move

`def help`'s signature gains two flags with the house trailing comments:

```
    --json                 # the whole manual as one JSON document
    --md                   # the whole manual as markdown
```

Validation, beside the existing `--mode` check at the top of the body:
`--json` and `--md` are **mutually exclusive**, and each accepts `--mode` and
nothing else — a query or any other flag alongside them is an `error make`
naming the flag. An interface that silently drops an argument is how an agent
comes to trust a wrong answer, and there is nothing to filter *to*: R1's
subject is the whole manual.

Render clauses go **immediately after clause 1** (`--delegate`), which stays
first because it is the corpus-free escape hatch and must keep working when
the corpus is gone. **Do not renumber the existing clause comments.**
`help.nu`'s own header cites "Clause 8" by number, and so does
`tests/shell-help.sh`; label the two new ones `1a`/`1b` or as unnumbered
blocks, the way the `--fuzzy` branch was inserted.

## 3 — the overview: both flags, and the block that earns this node

**This section, not the renderers, is what makes the node work.** Measured
tonight against the shipped `help`: bare `help` prints the nine topics with
counts, four first keys, and the go-deeper line. It does **not** name the
`idioms` entry, and `idioms` is where the corpus says "search with `rg` and
find with `fd`, never `grep`/`find`" and "pick with television (`tv`)". So an
agent that runs `help` once — which is what `AGENTS.md` asks it to do —
reads a table of contents and still has to guess. That is the standard
failure mode surviving the manual, and it is one render away from being
fixed.

Two edits, both in `_help_overview`, both layout only:

1. the Go-deeper line gains ` · help --json · help --md` at the **end**
   (measured fact 3 — append, never insert). The reverse rule from the
   browser still binds: an overview naming a flag the command rejects is a
   false line, and it is now satisfied in both directions.
2. a new block below it, built by the **same mechanism** the existing "First
   keys:" block uses — a curated list of ids rendered as `id — <corpus
   title>`, so **no sentence is written here**:

   ```
   For agents:
     help --json — Read this manual as structured data
     help --md — Write this manual out as markdown
     idioms — Search with rg, find with fd, pick with tv
   ```

   Extract the existing curated-id render out of the `first` block into one
   helper both blocks call, so the two cannot diverge. Leave the `First keys:`
   block's four ids and its label exactly as they are: 02's R1 names those
   four keys and its gate greps for them.

The curated render **silently drops** an id that is not in the corpus
(`where {|l| $l | is-not-empty}`), so renaming `idioms` would shrink this
block without a word of complaint. Do not change that behaviour — it is 02's
— but pin it from the gate: assert bare `help` names all three agent ids and
all four first keys with their corpus titles, with a counterfactual that
renames `idioms` in the scratch **corpus** and proves the check goes red.

## 4 — the `agents` topic reaches the credentials entry

`topics.nuon`'s `agents` summary promises "the launchers, what a capsule
hands an agent, and this manual as data", but the `agents` topic's five
entries are `cc`, `cr`, `help --json`, `help --md` and `idioms` — the
credentials entry (`credentials in a capsule`) lives in `containers`, where
it belongs by reader task, and nothing in `agents` points at it. R4's third
bullet is unmet in the letter for that reason only.

Fix it with **one value**: add `"credentials in a capsule"` to the `cc
[...args]` entry's `also` in `home/dot_config/nushell/help/shell.nuon`. The
target already exists, so `tests/help-content-model.nu`'s also-resolution
check stays green, and no prose moves (measured fact 5). Do not move the
entry between topics and do not rewrite the summary — both are
`01-content-model`'s call, not this node's.

## 5 — `tests/help-agent.sh` (new)

Two stages, `--tree` and `--hermetic`, both by default; no `--selftest`,
because the wave registry takes it `external` like every sibling under
`tests/`. Copy the harness from `tests/help-browser.sh`:
`. "$REPO/gates/lib.sh"`, `GREP=/usr/bin/grep` (plain `grep` is ugrep
here), `SCRATCH="$(gates_tmpdir)"`
re-resolved with `cd … && pwd -P`, `PY="$(command -v python3)"`, and an
epilogue asserting the managed files and the live `~/.config` are untouched.

The hermetic stage is cheaper than the browser's: **no `config.nu`**. Stage
`help.nu` plus the `help/` corpus into a scratch `HOME` and run
`env -i HOME=$M PATH=… nu -n -c 'source ~/.config/nushell/help.nu; …'`. That
is not a shortcut — it is the assertion, because a render that needs
`config.nu` is a render that names `core-help`.

`--tree` (help.nu and shell.nuon as text):

- the eleven-key list appears in `_help_norm` in the documented order;
- neither `_help_json`, `_help_md` nor `_help_norm` names `core-help`;
- the two flags are in the signature with trailing `#` comments, and no
  string in the file carries a `#` (02's `strip_comments` depends on it);
- the Go-deeper line names `help --json` and `help --md` **after**
  `help --fuzzy`, and 02's exact substring is still present intact;
- the `cc [...args]` entry's `also` names `credentials in a capsule`;
- the `For agents:` block's three curated ids appear in `_help_overview`, and
  the curated-id render exists once, not twice.

`--hermetic` (a real nushell, every number computed from the staged corpus):

- `help --json | from json` round-trips, and `$PY -c json.load` parses it;
- `.topics | length` equals the staged `topics.nuon` length, and every
  entry's `topic` is one of those ids;
- `.entries | length` equals the staged corpus count, and equals
  `help --all | length`;
- the entry key set is **exact** — the eleven keys, no more and no fewer, on
  **every** entry, so an added field is as red as a renamed one. This is
  what "renaming a JSON field requires updating this PRD's field list" means
  mechanically;
- `[.entries[].id]` equals `help --all | get key`, in order;
- every entry has `why` and `also` present, of the right type, on entries
  that carry neither in the corpus;
- the entry whose id contains an apostrophe is present with non-empty
  `use`, `why` and `source` — an agent reading the JSON never needs to send
  that id back through a shell;
- `help --json --mode nvim` and `help --md --mode nvim` both narrow to the
  nvim subset, and `--mode tmux` exits non-zero on both;
- `help --md` has one `## ` per non-empty topic, one `### ` per entry, and a
  host-only marker on exactly the `mode: "terminal"` entries;
- `help --json ctrl-r`, `help --md ctrl-r` and `help --json --md` each exit
  non-zero and name the flag;
- bare `help` names `help --json`, `help --md` and `idioms`, each followed by
  that entry's corpus `title`, and still names the four first keys and the
  nine topics — this is the discovery check, and it is the one a reader
  should look at first;
- neither output contains an ESC byte (`0x1b`), and neither does bare `help`
  under capture — R3, verified rather than assumed;
- with the corpus directory renamed away, `help --json` and `help --md`
  raise with a message naming `chezmoi apply`, while `help --delegate ls`
  still exits 0.

Four counterfactuals, each in the memo's shape — print `sha <12> -> <12>` on
**one line** so an equal pair is visible instead of inferred, assert the pair
differs, assert the copy is **red before repair** with the FAIL naming the
gate and the subject, then repair and hash again:

1. rename `use` to `usage` in `_help_norm` on a scratch copy → the exact-key
   check FAILS;
2. make `_help_md` call `core-help` on a scratch copy → the no-`core-help`
   text check FAILS **and** running the mutated copy under `nu -n` exits
   non-zero (the text check alone is an end-state guard; the run is its
   companion);
3. delete `help --json` from the Go-deeper line on a scratch copy → the
   discovery check FAILS;
4. delete `credentials in a capsule` from the scratch `shell.nuon`'s `cc`
   entry → the reachability check FAILS;
5. rename the `idioms` entry's `cmd` in the scratch **corpus** → the
   `For agents:` block loses that line silently, and the discovery check
   FAILS naming `idioms`. This is the one counterfactual that mutates the
   corpus rather than the code, and it is the one that proves the block is
   read from data.

## Acceptance

- [x] `help --json` emits one document that `from json` and `python3
      -c 'json.load(...)'` both parse, with `topics` and `entries` at the top
      level.

      Checked 2026-08-28 in a scratch `HOME` (`help.nu` + the `help/` corpus,
      **no** `config.nu`), `nu -n`: `help --json | from json | columns` →
      `topics` / `entries`, rc 0, and `python3 -c json.load` →
      `py ok, top keys: ['entries', 'topics'] topics 9 entries 96`.
- [x] Every entry in `help --json` carries **exactly** the eleven keys
      `id key cmd title use topic mode also why verify source` — no entry has
      a twelfth and none is missing one.

      Checked: over the 96 entries there is exactly **one** distinct key
      tuple — `distinct key tuples: 1`, `96 entries -> ['id', 'key', 'cmd',
      'title', 'use', 'topic', 'mode', 'also', 'why', 'verify', 'source']` —
      and `order matches documented list: True`. No twelfth key on any entry,
      none missing.
- [x] `[.entries[].id]` from `help --json` equals `help --all | get key`
      element for element, and `.entries | length` equals
      `help --all | length`.

      Checked: `help --all length: 96 json entries: 96` and
      `element-for-element equal: True`.
- [x] `.topics | length` equals the staged `topics.nuon` row count, computed
      in the same run — no number frozen in the test.

      Checked, computed in the same run rather than frozen:
      `topics.nuon rows: 9`, ids `['navigate', 'find', 'history', 'edit',
      'git', 'containers', 'terminal', 'agents', 'config']`, and
      `every entry.topic in topics: True`. (`tests/help-agent.sh` asserts the
      same equality against the corpus it stages, so the 9 is never a
      literal.)
- [x] The entry whose id contains an apostrophe appears in `help --json`
      with non-empty `use`, `why` and `source`.

      Checked: `apostrophe id: "Neovim's own LSP keys"` with non-empty
      `use` and `why` and `source prds/03-editor/09-lsp/prd.md`. An agent
      reading the JSON never sends that id back through a shell.
- [x] `help --md` renders one `## ` heading per non-empty topic in spine
      order, one `### <id>` per entry, and the host-only marker on exactly
      the `mode: "terminal"` entries.

      Checked on the staged corpus: 1183 lines, `## ` → **9** in
      `topics.nuon` spine order (navigate, find, history, edit, git,
      containers, terminal, agents, config), `### ` → **96** = the entry
      count, and the host-only marker `host-only — the terminal is outside a
      capsule` on **16** lines against **16** `mode == "terminal"` entries in
      the same run. The two `std/help` hits in the document are the `help`
      entry's own corpus `use`/`why` prose, not a render tail — the render
      shells out nowhere.
- [x] `help --json --mode nvim` and `help --md --mode nvim` return only
      `nvim*` entries; `--mode tmux` exits non-zero on both.

      Checked: `--json --mode nvim` → 29 entries, modes
      `['nvim:insert', 'nvim:normal', 'nvim:visual']`, `all nvim*: True`;
      `--md --mode nvim` → 29 `### ` under **2** `## ` (find, edit) — the
      seven topics the filter empties are skipped whole rather than left as
      bare headings. `--mode tmux` on both → rc 1,
      `help: --mode takes shell, nvim, terminal or container, not tmux`.
- [x] `help --json ctrl-r`, `help --md ctrl-r` and `help --json --md` each
      exit non-zero with a message naming the offending flag.

      Checked, each rc 1 and each naming the flag: `help: --json renders the
      whole manual and takes no query — got 'ctrl-r'`; the same sentence
      with `--md`; and `help: --json and --md are exclusive — each renders the
      whole manual, so there is nothing to combine; run them separately`.
- [x] `help --json`, `help --md` and bare `help` contain no `0x1b` byte
      under capture.

      Checked by byte, not by eye — first `0x1b` index over the captured
      bytes: `out.json -1` (94518 bytes), `manual.md -1` (56965 bytes),
      `bare.txt -1` (1462 bytes). R3 verified rather than assumed.
- [x] Both renders run under `nu -n` with only `help.nu` sourced — no
      `config.nu`, no `core-help` named anywhere in `_help_norm`,
      `_help_json` or `_help_md`.

      Checked: every run above is `env -i HOME=$S … nu -n -c 'source
      ~/.config/nushell/help.nu; …'` with **no `config.nu` in the scratch
      tree** — that absence is the assertion, because a render needing
      `config.nu` is a render naming the alias only `config.nu` binds. And by
      line: `core-help` occurs in `help.nu` at 24, 27, 38, 484, 534, 645, 657,
      708, 773, 782, while `_help_norm` is 359-375, `_help_json` 388-390 and
      `_help_md` 421-456 — no occurrence falls inside any of the three.
- [x] With the corpus renamed away, `help --json` and `help --md` raise a
      message naming `chezmoi apply` while `help --delegate ls` exits 0.

      Checked with `help/` renamed to `help-gone/`: both rc 1 with
      `help: the manual's corpus directory <path> is missing — run `chezmoi
      apply`…`. The `--delegate` half needs `core-help` **bound**, which is
      the accepted deviation 1 in the PRD: under bare `nu -n` (no `config.nu`)
      `help --delegate ls` dies at `Command `core-help` not found` naming no
      corpus path — the escape hatch is corpus-free — and with the alias
      bound the way `config.nu` binds it, the same command with the corpus
      still gone exits **rc 0** and prints nushell's own `ls` help ("List
      the filenames, sizes, and modification times of items in a
      directory.").
- [x] `_help_overview`'s Go-deeper line names `help --json` and `help --md`,
      and `tests/shell-help.sh:539`'s exact substring is still present.

      Checked both ways. `help.nu:278` is `"Go deeper: help <topic> ·
      help <query> · help <entry> · help --all · help --fuzzy · help --json
      · help --md"` — the two flags **appended**, nothing inserted; and
      `grep -oF 'help <topic> · help <query> · help <entry> · help --all ·
      help --fuzzy'` over the rendered bare `help` still returns that exact
      substring intact, which is what `tests/shell-help.sh:539` asserts.
- [x] Bare `help` — no flag, no argument — names `help --json`, `help --md`
      and `idioms`, each with that entry's corpus `title`, alongside the four
      first keys and the nine topics.

      Checked on the rendered output: the `For agents:` block reads

          For agents:
            help --json — Read this manual as structured data
            help --md — Write this manual out as markdown
            idioms — Search with rg, find with fd, pick with tv

      each line `id — <corpus title>` with no prose of the render's own, and
      the same output still carries the nine topic lines with their counts and
      the four `First keys:` ids (`Ctrl-Space / F1`, `F5 <digit>`, `Ctrl-R`,
      `<leader>ff and <leader><space>`).
- [x] `home/dot_config/nushell/help/shell.nuon`'s `cc [...args]` entry lists
      `credentials in a capsule` in `also`, and `nu
      tests/help-content-model.nu` exits 0 (baseline today: `ok`, 92 entries
      / 9 topics).

      Checked: `shell.nuon:356` — `also: ["cr [...args]", "zc <query>",
      "credentials in a capsule"]` on the `cmd: "cc [...args]"` entry at
      :351, and the rendered JSON agrees
      (`cc [...args] | topic agents | also ['cr [...args]', 'zc <query>',
      'credentials in a capsule']`). `nu tests/help-content-model.nu` →
      `ok`, `96 entries across 4 files, 9 topics, 16 prose-only` — the
      also-target
      resolves and no digest moved, so no review was rewritten. (The 92 in
      this spec's baseline table is the 2026-08-24 reading; the corpus has
      since grown to 96 and every check above is computed, not frozen.)
- [x] `bash tests/shell-help.sh` exits 0 with no fewer checks than its
      baseline of 93 (`CHECKS: 93 run, 93 passed, 0 failed`, measured
      2026-08-24 before this node), and its stale "seven flag comments"
      count is gone rather than bumped.

      Checked: `CHECKS: 93 run, 93 passed, 0 failed`, `EXIT=0`. And the
      stale count is **gone rather than bumped** —
      `tests/shell-help.sh:207-223` now reads "the only trailing-`#` lines in
      the file are the flag comments in that signature" with a paragraph
      headed `THE NUMBER IS GONE ON PURPOSE, not bumped`; `grep -n seven`
      finds it only inside that explanation, never in the claim
      `strip_comments` rests on.
- [x] All five counterfactuals in `tests/help-agent.sh` print a **differing**
      `sha … -> …` pair on one line and FAIL the named check before repair.

      Checked in `bash tests/help-agent.sh --hermetic`, each pair on one
      line and each pair differing:

          CF use-renamed-to-usage        sha db54c04f19cd -> cf0ea4ca2e3f
          CF md-calls-core-help          sha db54c04f19cd -> b43bae555bb8
          CF go-deeper-drops-help--json  sha db54c04f19cd -> 295521200761
          CF cc-also-drops-credentials   sha 39d95caa5b31 -> 2f20251483f3
          CF corpus-renames-idioms       sha 39d95caa5b31 -> 68e0652cd04b

      each followed by the named check going red before repair
      (`norm_keys_ok`, `no_core_help_ok`, `go_deeper_ok`, `cc_also_ok`, and
      the discovery check naming `idioms`), two of them with the mutated copy
      also *run* rather than only grepped, and each repair restoring the
      original sha (`repaired: sha db54c04f19cd (want db54c04f19cd)` /
      `39d95caa5b31`). CF5 mutates the **corpus**, and its own line records
      the silence it proves: `the For agents: block silently lost a line — 2
      remain under it (was 3)`.

      One wording slip in this spec, not in the code: section 5's prose says
      "Four counterfactuals" and then lists five. Five is what is specified
      and five is what the gate runs.

## Verify and Proof

```sh
bash tests/help-agent.sh
nu tests/help-content-model.nu
bash tests/shell-help.sh
```

Scoped to this spec's footprint: the first is this node's gate, the second is
the corpus gate for the one `.nuon` value edited, the third is the gate on
`help.nu` — the file this node mutates and another node owns. No
whole-workspace command.

## Owed to the orchestrator (not written here)

- `gates/waves.tsv`, wave 6, whose gates cell is empty today: append
  `external bash tests/help-agent.sh`. Wave 6 is `H.4 H.5 H.1c`, so the cell
  goes red the moment all three are `done` with nothing in it.
- `gates/manual/wave6.md`, one H.5 box — the PRD's second acceptance
  criterion is a reading, not a command, and cannot be faked green:

  > - [ ] **H.5** — give a fresh agent session **only** the output of `help`
  >   (no repo access, no this file) and ask it to jump to a directory, find
  >   a file, and start a capsule.
  >   PASS: it uses the bare-word jump or `z`, `Ctrl-Space`/`Ctrl-T` or
  >   telescope, and `capsule` — and names no tool this environment does not
  >   install, `fzf` outside `zi` included.
  >   FAIL: any invented tool, or any step it could not derive from the
  >   overview alone. Record what it reached for; that is the only
  >   measurement of whether the overview is discoverable.

## Out of scope

- `help --check` — `06-help/04-drift-check`'s, and it does not exist yet.
- Any new corpus **prose**. The `agents` topic's five entries are written and
  reviewed; this node adds one `also` value and no sentence — the
  `For agents:` block renders corpus titles rather than writing its own.
- Changing the `First keys:` block's four ids or its label (02's R1), and
  making the curated-id render loud on a missing id (02's, and a real
  weakness — see the report).
- Filtering `--json`/`--md` by query, a `version` key, per-topic counts, and
  publishing a corpus row index — each rejected above, with the reason.
- Moving the credentials entry between topics, or rewriting the `agents`
  topic summary in `topics.nuon` (`01-content-model`'s file).
- `gates/waves.tsv`, `gates/manual/wave6.md`, `tests/nvim-keymaps.sh`, and
  `home/dot_config/nushell/help/README.md` — owned elsewhere.
