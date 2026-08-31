---
state: done
commit: b77134d
claim:
priority: 34
est: 0.75h
actual: 10m
mode: afk
footprint:
  - AGENTS.md
verify: ""
origin: derived
---

# `AGENTS.md` sends every specifying agent to a two-month-stale chezmoi clone

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `AGENTS.md:55-58` — "Live sources to read when specifying (never edit
them as part of PRD work)" — ends its list with `~/.local/share/chezmoi`.
Finding **M-21** in this same backlog establishes that path is a **June clone,
two months stale**, and that measurement must go through
`chezmoi source-path` instead.

**This is the worst possible carrier for that error.** `AGENTS.md` is the file
every agent reads before touching anything, and this is the sentence that
tells them where the ground truth lives. An analyst following it specs against
a two-month-old snapshot — which is precisely the failure mode the whole
`02-terminal` re-spec exists to atone for, and which `AGENTS.md` itself warns
about four lines earlier ("Verify against the live config, always").

M-21 is recorded in the backlog as **unowned**. Found again by
`census-verdict-discipline`'s analyst while auditing the same file, which is
how an unowned finding usually surfaces: someone trips over it twice.

## Requirements
- [x] **R1** — **Re-measure first.** Establish what `chezmoi source-path`
      returns now and whether `~/.local/share/chezmoi` is still stale, or
      still exists. M-21 was recorded some time ago and this node must not
      inherit its measurement — the board has been bitten twice this session
      by exactly that, and its own new rule says a cheap claim gets run.
      *Re-measured 2026-08-24 at implement time, two probes per claim; the
      table is below and every claim reproduced.*
- [x] **R2** — The line names the way to find the source, not a literal path
      that can drift: `chezmoi source-path`, with the reason. If a literal
      path is worth keeping as an example, it is labelled as one.
      *`AGENTS.md:72-89`; quoted below. The literal stays as a stamped
      2026-08-24 reading that `just cutover` will move.*
- [x] **R3** — **Census the other carriers.** M-21 is unowned and this is one
      more carrier; there are likely others. Sweep `prds/`, `docs/` and
      `AGENTS.md` for `~/.local/share/chezmoi` and for any other place a
      chezmoi source is named literally. Report each with its owner.
      *Census table below: 35 files, 2 unowned Tier A carriers remain.*
- [x] **R4** — M-21's backlog row gets its disposition updated to name this
      node, so the finding stops being unowned. That row is the orchestrator's
      edit — report the wording. *Already written by the orchestrator before
      this node implemented; quoted below, not touched by this lane.*
- [x] **R5** — The `## Conventions` and `## Where things live` sections are
      checked for the same claim, since both describe where things are read
      from. Report, do not widen. *Checked; one imprecision reported, nothing
      widened.*

## Acceptance
- [x] R1's measurement quoted — `chezmoi source-path` output, and the state
      of `~/.local/share/chezmoi`. — the table under **Measured** below.
- [x] The corrected line quoted, with its reason. — under **The corrected
      wording** below.
- [x] The R3 census in the report, one row per carrier with its owner. —
      under **R3 census** below.
- [x] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count — the tree is written by several
      lanes and an absolute is stale before it is read. — `TIER A (gating) /
      checked 1034 links in 154 files, 0 broken` after the edit; and box6 of
      this node's own check re-asserts it by matching `, 0 broken`, never a
      link count.
- [x] `checks/agents-chezmoi-source.sh` passes against the real tree: 6 boxes,
      6 PASS, rc=0.
- [x] `checks/agents-chezmoi-source.sh --selftest` is red before repair and
      green after, with a one-line `sha before -> after` pair on **both** the
      mutation and the repair: `sha 473040dfaee8 -> a93764a5f03b` for the
      mutation, `sha a93764a5f03b -> 473040dfaee8` for the repair, 9 PASS,
      rc=0. The mutated sha is the pre-edit `AGENTS.md` byte-for-byte, which
      is what makes the substitution the *literal historical sentence* rather
      than a lookalike.
- [x] The real `AGENTS.md` is byte-identical across the selftest —
      `473040dfaee8` printed before and after, and the scratch host is a
      `mktemp -d` outside the repo, removed in a `finally`. The root census
      (`bash gates/selftest.sh --root`) reports `0 undeclared` after the run.

## Out of scope
- Editing anything under `~/.local/share/chezmoi` or the live chezmoi source.
  They are read-only reference.
- Any other M-* finding.
- `gates/retired-phrases.sh`, the tree-wide home for this rule. Its
  exemption table is asserted as **set equality**, so arming a phrase for
  `~/.local/share/chezmoi` also means adding a labelled-retirement-quote
  exemption for all twelve legitimate citations across nine files — and the
  file sits in 20+ other nodes' footprints. Separate node. The gate was run
  unchanged after the edit and is green (`allow-list: exactly the 29 declared
  pairs`, `isolation: prds/, docs/ and AGENTS.md are byte-identical`).

## Report

### Measured 2026-08-24 at implement time, two probes per claim

| claim | probe 1 | probe 2 |
|---|---|---|
| the live chezmoi source | `chezmoi source-path` → `/Users/feb/dev/.files/home` | `chezmoi data` → `sourceDir: /Users/feb/dev/.files/home`; `~/.config/chezmoi/chezmoi.toml` sets `sourceDir = "/Users/feb/dev/.files"` (the `/home` suffix comes from `.chezmoiroot`) |
| `~/.local/share/chezmoi` still exists and is still stale | HEAD `a2544e4`, `2026-06-20 22:07:14 +0200` — two months four days behind | `git -C /Users/feb/dev/.files merge-base --is-ancestor a2544e4 8e99f58` → ancestor; live HEAD `8e99f58`, `2026-08-19 21:13:25 +0200` |
| `~/.files` is a plain directory, not a git repo | `git -C ~/.files remote -v` → `fatal: not a git repository` | `git -C ~/.files rev-parse --git-dir` → same fatal; `ls -d ~/.files/.git` → no such file |
| the two `.files` trees are distinct | `~/.files` holds `user/`, `index`, `deleted`, `deploy.disabled`, `vicky`, `CLAUDE.md` — and no `install.sh` | `/Users/feb/dev/.files` holds `.chezmoiroot`, `.git`, `home/`, `install.sh`, `justfile`, `tests/` |

**The finding is bigger than the node was opened for: there are two trees
called `.files`.** An agent told "legacy lives in `~/.files`" that runs
`chezmoi source-path` and reads `/Users/feb/dev/.files/home` has every reason
to believe it found the legacy tree. That is the trap the load-bearing
sentence closes, and it is why the literal path is kept — labelled — rather
than deleted: an agent needs to recognise the answer when it sees it, and
needs to be warned off `~/.files` when it does.

### The corrected wording (`AGENTS.md:72-89`)

Was:

> Live sources to read when specifying (never edit them as part of PRD work):
> `~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
> `~/.config/wezterm/`, `~/.files/`, and the chezmoi source at
> `~/.local/share/chezmoi`.

Is:

> Live sources to read when specifying (never edit them as part of PRD work):
> `~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
> `~/.config/wezterm/`, and the legacy tree at `~/.files/` — a plain
> directory, not a git repo (measured 2026-08-24), holding the zsh-era
> material `docs/capabilities.md` rates.
>
> **Find the chezmoi source by running `chezmoi source-path`. Never by
> literal path.** It printed `/Users/feb/dev/.files/home` on 2026-08-24 — a
> reading of that day, not a constant, because `just cutover` rewrites
> `sourceDir` and the answer moves. Two traps live in that answer.
> `~/dev/.files` is **not** `~/.files`: two different trees one path segment
> apart, and only the first is the chezmoi source. And
> `~/.local/share/chezmoi` still exists but is **not** the source — it is a
> stale June clone (HEAD `a2544e4`, a git *ancestor* of the live `8e99f58`)
> whose readings produced findings L-12, L-13 and M-21, and per Decision 4(a)
> no document may cite it as the chezmoi source; the only permitted mention
> is as the stale clone, labelled as such. The full record is in
> `docs/capabilities-provisioning.md`. Decision 4 also makes the deployed
> `~/.config` tree canonical: read a source tree to explain how a file got
> where it is, not to decide what it says.

The reason, stated in the text itself: a literal path is a reading of the day
it was taken, and `just cutover` rewrites `sourceDir`. A method survives the
cutover; a path does not.

### R3 census — `~/.local/share/chezmoi`, 2026-08-24

`grep -rn 'local/share/chezmoi' AGENTS.md docs/ prds/` → **35 files**. Only
the rows that *claim it is the source* matter; everything else names it as
the stale clone, forbids citing it, or quotes the ban, all of which
Decision 4(a) permits.

| carrier | status | owner |
|---|---|---|
| `AGENTS.md:75` (was) | **fixed by this node** | this node |
| `docs/capabilities-nushell.md:18` | **still violating** — "the chezmoi source at `~/.local/share/chezmoi/home/dot_config/nushell/`", unlabelled | **unowned**; M-21's own remit, explicitly outside this footprint |
| `docs/capabilities-nushell.md:179` | **still violating** — unlabelled mention as the tree a 345-line `finder.nu` lives in | **unowned**; same |
| `docs/capabilities-provisioning.md:24` | compliant — names it "a **stale** checkout" and states the ban | `w0-4-s2-corrections/provisioning-rerate` (`done`), guarded by its `specs/check03.sh` ±400 rule |
| `prds/02-terminal/prd.md:66` | compliant — "a stale June clone whose HEAD is a git ancestor" | `w0-2-terminal-respec` |
| `prds/05-platform/01-deploy-mechanism/managed-config/prd.md:58,65` | compliant — "**stale clone**", and a live-vs-clone comparison table | `05-platform/01/managed-config` |
| `prds/00-delivery/corrections/prd.md:226,230,246,393,470` | compliant — the finding record and Decision 4(a) itself | the orchestrator |
| 27 further files under `prds/00-delivery/corrections/**` (specs, checks, decision replacements, this node's own `prd.md` and `specs/`) | compliant — each names it as the stale clone, bans it, or is a check asserting the ban | their own nodes |

Literal chezmoi *source* paths (`/Users/feb/dev/.files`) are a separate,
non-violating class — `docs/capabilities-provisioning.md:20-22,97,142`,
`prds/05-platform/prd.md:18`, `prds/02-terminal/prd.md:65` and several specs
name it correctly as what `chezmoi source-path` reports. They are readings
that `just cutover` will move, but they are not misdirections, and each
belongs to a lane that is not this one.

### R4 — M-21's disposition (report only; the orchestrator's edit, already made)

`prds/00-delivery/corrections/prd.md:393` already reads:

> `agents-md-chezmoi-source` owns the `AGENTS.md` carrier ·
> `w0-2-terminal-respec` owns the `capabilities-terminal.md` third ·
> **`docs/capabilities-nushell.md` is still unowned**

and `:470` records the 2026-08-24 re-measurement and "**This finding stays
open until `capabilities-nushell.md` has a node.**" That is correct as
written and this lane did not touch it. The one thing it could gain is the
two-trees finding stated as its own sentence rather than inside the long
disposition paragraph — the orchestrator's call.

### R5 — the other two sections, reported and not widened

- `## Conventions` carries **no** source-path claim at all. Nothing to fix.
- `## Where things live` — the live-sources paragraph is the last paragraph
  of that section and is the one this node rewrote. The table above it has
  one imprecision, **reported and deliberately not changed**: line 59 reads
  "Rated inventory of the legacy `~/.files` repo", and `~/.files` is not a
  git repo. Same wording at line 5 ("the dotfiles that currently live in
  `~/.files`"). The word is imprecise rather than misdirecting — the material
  really is at that path — and R5 says report, do not widen.

### Two carriers of the same `.files` ambiguity in other lanes (report only)

- `install.sh:256` — a comment citing "the live parser at
  `~/.files/install.sh:128`". `~/.files/install.sh` does not exist; the file
  is `/Users/feb/dev/.files/install.sh` (11321 bytes, 2026-08-19).
- `tests/provisioning.sh:23` — "one line the live `~/.files/install.sh`
  still carries". Same wrong path, same reason.

Both are `05-platform`'s files, both outside this footprint, and both are the
`.files` ambiguity this node named rather than a new class.

### Why `verify:` cannot prove this node

`gates/tree-links.py`'s `LINK_RE` matches markdown bracket-paren links only,
so an inline-code path in backticks is never resolved — Tier A reported
`0 broken` for as long as `AGENTS.md` cited `.claude/skills/prd/README.md`, a
file gone since the mi-era retirement (still cited at `AGENTS.md:211`, on
purpose, inside the note recording that it is dead). An existence checker
would be no better: `~/.local/share/chezmoi` **exists**. The defect class is
"a path that resolves and is the wrong tree", so only a labelled-mention rule
catches it. `bash gates/tree-links.sh` is therefore the no-regression half
(box 6) and `checks/agents-chezmoi-source.sh` is what actually proves the
change.

## Closed 2026-08-24 by the orchestrator

`done`, R1–R5 and every acceptance box `[x]`. The node-local check
`checks/agents-chezmoi-source.sh` → **6 PASS / 0 FAIL, rc 0**, re-run by the
orchestrator on this transition; `gates/tree-links.sh` Tier A `checked 1034
links in 154 files, 0 broken`, unchanged from the pre-edit baseline;
`retired-phrases.sh`, `audit-findings.sh` (49 findings, 0 undisposed) and
`selftest.sh --root` (0 undeclared) all green.

**`actual: 10m` against `est: 0.75h`.** The analyst priced it at 15m of prose
plus ~30m for the counterfactual, calibrated off three same-shape measured
pairs, and it came in under even that.

**The counterfactual is the strongest form this board has landed:**

```
sha 473040dfaee8 -> a93764a5f03b     MUTATION (historical sentence back)
sha a93764a5f03b -> 473040dfaee8     REPAIR
```

The mutated sha is the pre-edit `AGENTS.md` **byte for byte**, which proves the
substitution really is the literal historical sentence and not a lookalike —
and the repair returns to the original sha. Baseline green → mutation red with
a FAIL naming `~/.local/share/chezmoi` → repair green.

**It caught the orchestrator, and that is the second time tonight a
just-landed check did.** Box 5 — "every paragraph carrying a literal chezmoi
source path also carries the date and marks it as a reading, not a constant" —
went **red** on the orchestrator's own "Current state" paragraph, which named
`~/dev/.files` undated. The sentence was rewritten to ask
`chezmoi source-path` instead of naming a path at all, which is the rule this
node exists to install. A check that only ever passes on the text it shipped
with is not a check; this one failed the next writer within minutes.

**A terminology collision the implementer reported instead of reverting**,
also the orchestrator's: the "Current state" paragraph used "legacy tree" for
the pre-rebuild chezmoi repo while this node's new paragraph uses it for
`~/.files`, the zsh-era material — two senses of the word in one section, when
the entire point of the paragraph is that those are two different trees one
path segment apart. Fixed in the orchestrator's sentence, not in the node's.

**The finding that outgrew the node**: `~/.files` is **not a git repository**
(probed twice), while the live chezmoi source is `~/dev/.files` — a name one
segment away that `AGENTS.md` never mentioned. An agent told "legacy lives in
`~/.files`", running `chezmoi source-path` and seeing `/Users/feb/dev/.files/home`,
had every reason to believe it had found the legacy tree. That is now
impossible to read that way.

**Reported, not fixed:** `install.sh:256` and `tests/provisioning.sh:23` both
cite a `~/.files/install.sh` that does not exist — the file is under
`~/dev/.files` — the same ambiguity in `05-platform`'s files. And
`docs/capabilities-nushell.md:18` and `:179` remain the last two Tier A
carriers violating Decision 4(a), still unowned; M-21's disposition in the
corrections backlog now says so explicitly rather than reading "unowned —
needs a node".
