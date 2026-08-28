---
complexity: 70
footprint:
  - gates/wezterm-config-fields.sh
  - gates/waves.tsv
---

# spec01 — `gates/wezterm-config-fields.sh`, the predicate the acceptance line was missing

The check itself: a gate that builds its probe with `wezterm.config_builder()`,
runs it through the command already on record
(`wezterm --config-file <probe> ls-fonts --list-system`), and reads the
verdict off **stderr and stdout, never `$?`**. It covers both halves of R1 and
R4 — the fields the epic's children *name*, and the fields the shipped
artifact *sets* — and its `--selftest` is R2: it induces its own violation
against a `scratch_tree` copy and asserts the red.

**This spec is already built and green in the working tree, uncommitted.** It
is written down so the next worker continues it rather than rebuilding it, and
so the boxes below carry the run that closed them.

## What already stands

`gates/wezterm-config-fields.sh` exists and is registered in `gates/waves.tsv`
as the 24th gate of wave 4 (the wave holding the last terminal tasks — T.4,
T.6, T.7). It holds seven assertions in three groups:

- **instrument** (3) — run on every invocation, before any verdict is taken.
  A clean `config_builder` probe loads with empty stderr; an unknown field is
  rejected; the probe file is genuinely read (its `F20` binding comes back out
  of `show-keys --lua`). If the build's behaviour ever moves, these go red
  first and nothing below them is trusted.
- **witness** (1) — the same unknown key in a *plain* `return { ... }` table is
  swallowed. This asserts the **probe's construction**, not the build: it is
  the machine-checked form of "use `config_builder()` or you are validating
  nothing", and it is deliberately not phrased as a claim about what WezTerm
  can detect. Getting that distinction backwards is the error this node
  corrects.
- **artifact + named** (2) — `home/dot_config/wezterm/wezterm.lua` loads with
  empty stderr (it already uses `config_builder()` at line 12, so one load
  validates all 31 of its `config.<field>` assignments), and every
  `config.<field>` token harvested from `prds/02-terminal/*/` is a valid field,
  probed **one field per probe**.

Four traps are recorded in the file's header, each measured on
`wezterm 20240203-110809-5046fc22`, and each is the reason a line of the gate
is shaped the way it is:

| trap | measured | consequence for the gate |
|---|---|---|
| the probe's *construction* decides whether it can fail | plain table + bad key: `EXIT=0`, 0 stderr bytes. `config_builder` + same key: `EXIT=0`, **0 stdout lines, 350 stderr bytes** | every probe goes through `config_builder()` |
| the exit code never moves | unknown field, wrong type, and a `--config-file` that does not exist all exit 0 — including with `config:set_strict_mode(true)` | verdict is stderr-empty **and** stdout-non-empty; `$?` is never read |
| `show-keys` is not an error channel | with a rejected field: `show-keys --lua` = exit 0, 230 stdout lines, **0 stderr lines**; `ls-fonts --list-system` on the same config = 5 stderr lines carrying the ERROR | `ls-fonts --list-system` is the probe command; `show-keys` is only the read-back control |
| one field per probe | `config_builder`'s error is raised in `__newindex` and aborts the chunk, so a probe assigning four bad fields reports only the **first** | the `named` loop writes one probe per field |

`gates/probes.sh`'s existing `wezterm_probe` is **not** the basis of this
check and must not become it: it runs `show-keys --lua` with `2>/dev/null`, so
it discards the only channel a config error travels on. That is recorded in
the header rather than fixed here — `probes.sh` belongs to another node.

## What is left

Nothing in the script. Landing it (the orchestrator commits on the
transition), and spec02's epic edit, which names this gate.

One judgement call is recorded rather than hidden, and a later worker may
revisit it: `named` harvests only tokens written `config.<field>`. Field names
that appear as bare backticked identifiers are not harvested, because a
bare-identifier harvest of the same tree returns 88 tokens of which most are
Lua API calls, gate helpers and local variables (`action_callback`, `chk_ok`,
`avail_w`). Measured: this costs nothing today — all 16 harvested names are
also set in the artifact, and the 14 fields named only as bare identifiers
(`macos_window_background_blur`, `use_fancy_tab_bar`, `front_end`, …) are all
set in the artifact too, so the union of 30 distinct fields is fully covered
by the two checks together.

## Acceptance

- [x] `bash gates/wezterm-config-fields.sh` exits 0 on the live tree, with the
      instrument controls passing before any verdict.

      `rc=0`, 7 PASS / 0 FAIL:
      `instrument: a config_builder probe of only valid fields loads with an empty stderr`,
      `instrument: config_builder REJECTS an unknown field — the check can go red`,
      `instrument: the probe file is actually READ — its F20 binding comes back out of show-keys --lua`,
      `witness: …`, `artifact: wezterm.lua loads under this build with an empty stderr`,
      `named: every config.<field> the children name is a valid Config field (16 probed, 0 rejected)`.

- [x] The gate goes RED on an unknown field introduced into the **artifact**,
      and green again when that one line is removed.

      `--selftest`, against a `scratch_tree` copy:
      `MUTATION: appended \`config.no_such_wezterm_field = true\` to …/scratch/home/dot_config/wezterm/wezterm.lua`
      → `FAIL  artifact: wezterm.lua loads under this build with an empty stderr`, rc 1,
      stderr carrying ``ERROR  wezterm_gui > error converting Lua table to Config (Config::from_dynamic: `no_such_wezterm_field` is not a valid Config field…)``;
      then `PASS  selftest GREEN again: removing that one line restores the pass (rc 0)`.

- [x] The gate goes RED when a **child** names a field this build rejects —
      the acceptance line's own subject.

      `MUTATION: wrote \`config.not_a_real_wezterm_field\` into …/scratch/prds/02-terminal/01-appearance/prd.md`
      → `REJECTED by this build: config.not_a_real_wezterm_field` and
      `FAIL  named: every config.<field> the children name is a valid Config field (17 probed, 1 rejected)`, rc 1.

- [x] The superseded probe is shown green on the same violation, so the
      difference is on the record and not in a memory.

      `superseded probe: EXIT=0, stderr=[<empty>]` →
      `PASS  superseded: a PLAIN-TABLE probe is GREEN on the same violation — the construction, not the build, was the defect`.

- [x] The gate satisfies the `gates/selftest.sh` contract — `--selftest`
      exits 0, prints `MUTATION` lines and a `MUTATION HOST`, really changes
      its scratch tree, and writes nothing outside it.

      `bash gates/selftest.sh --one gates/wezterm-config-fields.sh` → rc 0,
      5 PASS / 0 FAIL, `3 mutation line(s)`.

- [x] It is registered, and the registry still resolves.

      `gates/waves.tsv` wave 4 gains `| bash gates/wezterm-config-fields.sh`;
      `bash gates/wave-status.sh --matrix` → `4  PENDING  17/18  24 registered`.

## Verify and Proof

```sh
bash gates/wezterm-config-fields.sh
bash gates/wezterm-config-fields.sh --selftest
bash gates/selftest.sh --one gates/wezterm-config-fields.sh
bash gates/wave-status.sh --matrix
```

## Amendment 2026-08-28 — the counterexample marker, added at the orchestrator's edit

Applying spec02's wording to `prds/02-terminal/prd.md` turned this gate **red**,
and the red was a false positive: the `named` harvest reads `config.<field>`
out of the epic's prose, and spec02's box quotes the two deliberately invalid
field names the `--selftest` mutations use. The gate went red against the very
paragraph describing its own red.

The analyst could not have seen this — the wording was never applied while the
gate was being built, because an epic's body is the orchestrator's edit.

Fixed in `harvest_fields`: a line carrying the literal `NOT-A-FIELD` is
dropped before the match. **Per line, never per file** — exempting a document
would blind the check to a real `config.<field>` written further down it. The
`--selftest` mutations deliberately do not carry the marker, which is what
keeps the gate's own red biting.

Proven, all three legs:

- `bash gates/wezterm-config-fields.sh` → rc 0, 16 fields harvested, 0
  rejected. The two counterexamples no longer reach the probe.
- `bash gates/wezterm-config-fields.sh --selftest` → rc 0, with **RED 1 and
  RED 2 both still biting** and each naming its field.
- The marker cannot over-reach: a marked line followed by
  `config.definitely_bogus_field_zz` on the next line still goes red — `17
  probed, 1 rejected`.

