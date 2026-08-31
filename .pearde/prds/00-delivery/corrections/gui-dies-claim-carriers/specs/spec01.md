---
est: 0.5h
footprint:
  - prds/02-terminal/06-launchd-path/prd.md
  - prds/00-delivery/corrections/prd.md
  - prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md
executor: orchestrator   # all four files are another PRD's body
verify: "bash gates/tree-links.sh"
---

# spec01 — five carriers, corrected to the measured symptom

Replace five passages with the pre-resolved text below. Every one of them is
another PRD's body, so **the orchestrator makes this edit**; no implementer
may write another PRD's body.

The replacement text is final. Do not re-derive it and do not re-measure the
symptom: it is measured four times now, most recently by this analyst, and
the transcript is in **The measurement** below. What the executor runs is the
closing census in **Verify and Proof**.

Nothing else in any of the four files changes. No box changes state, no
requirement changes what it demands, no rating moves. No new markdown link
is added anywhere, so the link delta is exactly zero and the acceptance box
over it is falsifiable.

## Four became five

The PRD names four carriers. The census in **The closing census** found a
fifth, in a file already listed: `prds/02-terminal/06-launchd-path/prd.md`
carries the claim at `:30` (the Purpose, which R2 names) **and** at `:121`,
an acceptance box that promises Finder "opens a working shell rather than
dying". One file, two carriers, both contradicting R3 six lines apart.

| # | Carrier | Shape | Named by the PRD |
|---|---|---|---|
| 1 | `prds/02-terminal/06-launchd-path/prd.md:28-32` | Purpose prose | yes (R2) |
| 2 | `prds/02-terminal/06-launchd-path/prd.md:121-122` | acceptance box | **no** |
| 3 | `prds/00-delivery/corrections/prd.md:52` | table row T-10 | yes |
| 4 | `prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md:32` | requirement box R2 | yes |
| 5 | `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md:82` | acceptance box B8 | yes |

## How R4 is read, and why it has to be read that way

R4 says "No requirement, acceptance box or rating changes. Prose only." Read
literally it forbids this node's own work: **three of the five carriers sit
inside a box** — carrier 4 is `- [x] **R2**`, carrier 5 is `- [x] **B8**`,
carrier 2 is `- [~]`. R1 demands all of them state the measured symptom, so
R1 and R4 cannot both be read literally.

R4 governs the **contract**, not the characters. Under this spec:

- no box changes marker — `[x]` stays `[x]`, `[~]` stays `[~]`;
- no box changes what it demands or what would falsify it;
- no `C`/`U` number moves anywhere;
- only the sentence naming the *failure mode* is corrected.

Carrier 2 is the clearest case. Its check is "opens a working shell, and
resolves `nu`, `nvim`, `tv` and `zoxide`". That check is untouched. What
changes is the false counterfactual it names in passing.

## The measurement

Fourth independent measurement, 2026-08-23, `wezterm-mux-server` under
`env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin` with a scratch `HOME` whose only
config sets `default_prog = { "nu" }`:

```
$ wezterm cli list
WINID TABID PANEID WORKSPACE SIZE  TITLE   CWD
    0     0      0 default   80x24 wezterm

$ wezterm cli get-text --pane-id 0
Unable to spawn nu because:
No viable candidates found in PATH "/usr/bin:/bin:/usr/sbin:/sbin"
⚠️ Process "nu" in domain "local" didn't exit cleanly
Exited with code 1.
This message is shown because exit_behavior="CloseOnCleanExit"
```

The pane exists. Neither config sets `exit_behavior`, and the default
`CloseOnCleanExit` retains a pane whose process exited *un*cleanly. A pane
you cannot type into is harder to diagnose than a window that vanishes,
which is why this is a correction and not pedantry.

**What stays true and must not be swept up.** "Fatal" is accurate: `nu`
never starts, so no [`04-shell`](../../../../04-shell/prd.md) and no `help`.
`06-launchd-path:32` says "the one uncovered feature whose absence is fatal"
and keeps saying it. The rating `C 2 · U 10` does not move, for the reason
[`terminal-inventory-path-claim`](../../terminal-inventory-path-claim/prd.md)
R2 already put on the record.

## Edit 1 — `prds/02-terminal/06-launchd-path/prd.md`, lines 28-32

Replace the Purpose paragraph, which begins `Purpose: a GUI launch of
WezTerm` and ends `whose absence is fatal.`, with:

```markdown
Purpose: a GUI launch of WezTerm inherits launchd's PATH, not a shell's.
Without seeding it the config's `default_prog` cannot be resolved, and the
pane comes up holding `No viable candidates found in PATH` instead of a
shell. The window does not die — R3 carries the measurement, and the reason
it matters: a pane you cannot type into is harder to diagnose than a window
that vanishes. This is the best value ratio in
[`capabilities-terminal.md`(../../../../../../prds/00-delivery/docs/capabilities-terminal.md), and the
item finding T-10 called the one uncovered feature whose absence is fatal.
```

This is R2. The Purpose now says what R3 at `:55-67` says, in R3's own
terms, and points at it rather than restating the measurement. The
`capabilities-terminal.md` link line is copied byte-for-byte, so the file's
link count cannot move.

## Edit 2 — `prds/02-terminal/06-launchd-path/prd.md`, lines 121-122

Replace the first acceptance box, which begins `- [~] WezTerm launched from
Finder` and ends `and `zoxide`.`, with:

```markdown
- [~] WezTerm launched from Finder opens a working shell rather than a pane
      holding `No viable candidates found in PATH`, and resolves `nu`,
      `nvim`, `tv` and `zoxide`.
```

Carrier 5 of 4 — the one the filing missed. The marker stays `[~]`, and the
paragraph below the box list ("Why five boxes are `[~]` and not `[x]`") is
untouched, so its count of five still holds.

## Edit 3 — `prds/00-delivery/corrections/prd.md`, line 52

Row T-10. Table rows are exempt from the 78-column rule, so this stays one
line. Replace the trailing sentence

`and the launchd-PATH seeding without which a GUI launch dies.`

with

`and the launchd-PATH seeding without which a GUI launch never reaches nushell — measured, the pane is created and **kept**, holding \`No viable candidates found in PATH\` and then \`didn't exit cleanly\`, because neither config sets \`exit_behavior\` and the default \`CloseOnCleanExit\` retains an uncleanly-exited pane; the window does not die, and \`02-terminal/06-launchd-path\` R3 holds the measurement.`

Nothing else in the row changes: the owner cell stays
`` `w0-2-terminal-respec` R5 — **open** ``, and the nine-tab floor, grid
centering, copy mode, paste/SIGINT and `StartWindowDrag` clauses are copied
through unchanged.

**This is the highest-value edit of the five.** T-10 is `open`, and a row in
this backlog is read as a specification — the sentence above is what a future
analyst would spec the whole `02-terminal` re-spec from. Left alone, it hands
that analyst a requirement to prevent a vanishing window, and the gate it
would then write asserts the wrong observable: absence of a pane, where the
measured behaviour is a *present* pane carrying an error. That gate would go
green on a regression and red on the fix.

## Edit 4 — `w0-1-terminal-inventory/prd.md`, line 32

File: `prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md`.

Replace the last line of R2, `      and the launchd PATH seeding without
which a GUI launch dies.`, with:

```markdown
      and the launchd PATH seeding, without which a GUI launch never reaches
      nushell. The window does not die: the pane is created and kept,
      holding `No viable candidates found in PATH` and then `didn't exit
      cleanly`. Measured; `02-terminal/06-launchd-path` R3 holds it.
```

The `- [x]` marker and the four preceding lines of R2 are untouched, and R2
still demands exactly the same coverage.

## Edit 5 — `w0-2-terminal-respec/specs/spec06.md`, lines 78-84

File: `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md`.

Replace box B8, which begins `- [x] **B8 — the reason is the requirement.**`
and ends `inside the shell.`, with:

```markdown
- [x] **B8 — the reason is the requirement.** A GUI-launched WezTerm inherits
      launchd's minimal `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), which has
      no Homebrew, so the bare `nu` in `default_prog` cannot be found. The
      window does not die: the pane is created and **kept**, holding
      **"No viable candidates found in PATH"** and then `didn't exit
      cleanly`, because neither config sets `exit_behavior` and the default
      `CloseOnCleanExit` retains an uncleanly-exited pane. A pane you cannot
      type into is harder to diagnose than a window that vanishes. This only
      has to get the binary spawned; `env.nu` owns `PATH` from inside the
      shell.
```

`**"No viable candidates found in PATH"**` keeps its bold form, because
spec06's own frontmatter `verify` greps for that string. B9 and B10 below it
are untouched. **Add no markdown link here.** spec06's two existing links
(`(../../../../../../prds/00-delivery/corrections/04-shell/01-core-config/prd.md)` and `(../../../../../../prds/00-delivery/corrections/gui-dies-claim-carriers/01-appearance/prd.md)`)
are already broken from `specs/` and are part of Tier B's standing 114; a new
one would make that 115.

## The closing census

R3 asks for a grep, not an assertion, and a census that matches only the
words already known repeats the mistake in a new costume. So the census runs
on **three independent dimensions**, and a carrier has to escape all three.

**Dimension A — the death lexicon, subject-free.** Every way a document can
say something stopped existing, with no requirement that it mention WezTerm
or PATH: `die/died/dies/dying/death`, `vanish`, `disappear`, `crash`,
`exits|closes|quits immediately`, `never opens`, `fails to open|launch|start`,
`no window`, `window is gone`, `blows up`, `bails`, `falls over`,
`terminates`, `is dead`. Measured over `prds/ docs/`: **160 hits.**
Intersected with a launch-noun set on the same line —
`GUI`, `Finder`, `Spotlight`, `Dock`, `launchd`, `launch`, `window`,
`WezTerm`, `terminal`, `default_prog`, `PATH` — **60 hits**, every one triaged. All 60 are about a *pane* or a *tab* dying
(`05-tab-content-state` R6, the nine-tab floor, `07-grid-centering`'s nil
`:tab()`), which is a different and true fact, except the five carriers and
the allowlist below.

**Dimension B — the subject, verb-free.** Every mention of the topic,
whatever verb it uses: `launchd[- ]PATH`, `PATH seeding`, `GUI launch`,
`launched from (Finder|Spotlight|the Dock)`, `set_environment_variables`.
Over `prds/ docs/ home/ tests/`: **85 hits in 19 files.** This is the
dimension that catches phrasing nobody has thought of, because it keys on
what the sentence is *about* rather than on how it ends. Result: the fifteen
files that are not the five carriers or the allowlist make no outcome claim
at all — `prds/README.md:71` and `work-breakdown/prd.md:169` are index rows,
`01-appearance` and `w0-2-terminal-respec/specs/spec02.md` describe the F6
repetition, and `help-corpus-path-resolution/prd.md:201` correctly says the
fallback is the login shell.

**Dimension C — the euphemism.** An outcome claim carrying no death verb:
`is fatal`, `unusable`, `hard failure`, `nothing starts|comes up`,
`no shell starts|at all`, `cannot launch|start up`,
`never comes up|appears|starts`, `is lost`, `breaks outright`. Over
`prds/ docs/`: 30 hits, **none** a carrier. Two are deliberately kept because
they are true — `06-launchd-path:32` "absence is fatal", and
`06-launchd-path/specs/spec01-launch-environment.md:99` "without this line
the terminal never starts nushell at all", which is the `default_prog`
fallback and correct.

**The allowlist — hits that survive on purpose.** Every one of these quotes
the retired claim *as retired*, and deleting them would destroy the record of
the correction. The census asserts this exact set and nothing more:

| File | What it is |
|---|---|
| `prds/02-terminal/06-launchd-path/prd.md` (R3) | the correction itself, quoting the old wording |
| `prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md:30` | finding 1, which corrected it |
| `prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md:82,83,270` | the gate's own phrase list |
| `prds/00-delivery/corrections/terminal-inventory-path-claim/prd.md:79` and `specs/spec01.md:49,181,221,281` | the inventory correction |
| `prds/00-delivery/corrections/pwd-closure-blast-radius/prd.md:62` and `specs/spec02.md:104,113,114,125` | the census that filed this node |
| `prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md` and this spec | this node |
| `tests/wezterm-launchd-path.sh:289,292` | the live gate, which asserts the three phrases stay absent from `wezterm.lua` |
| `prds/06-help/01-content-model/specs/spec01.md:67` | unrelated — a `verify` walk "continues rather than dying on the first element" |

**What the census would still miss**, stated so the next reader does not
over-trust it:

- A claim that names neither a death verb nor the subject — "without the
  prefix the user sees nothing at all", in a file that says neither `launch`
  nor `PATH`. Dimension B is the mitigation and it is not total.
- A claim split across a line break so that neither half carries a lexicon
  term on its own. Dimension A is line-oriented on the verb, B on the
  subject, so a split claim is caught by whichever half carries a term;
  only a claim that splits **and** invents wording on both halves escapes.
- Anything outside `prds/ docs/ home/ tests/` — git history, and the live
  `~/.config/wezterm/wezterm.lua:1029-1030`, which carries the same claim and
  is read-only reference under this repo's rules. Out of scope by the PRD.
- A carrier in an image, a diagram, or a binary. None exist in this tree.

## Not this executor's files

`gates/waves.tsv` and `gates/manual/wave*.md` belong to the orchestrator, and
**neither needs an entry** — confirmed, not assumed.
`bash gates/tree-links.sh` is already row 21 of `waves.tsv` and runs for the whole W0 set, so this node's
`verify` needs no new row. `gates/manual/wave4.md` holds three `T.7` rows
(`:175`, `:191`, `:202`) and none of them asserts a dying window, so no manual
step changes. Every check this spec adds is a grep the executor runs and
quotes.

`~/.config/wezterm/wezterm.lua` is read-only reference. Do not edit it.
`home/dot_config/wezterm/wezterm.lua`, the rebuild's own copy, is already
clean and gated by `tests/wezterm-launchd-path.sh:292` — leave both alone.

`docs/capabilities-terminal.md` is out of scope: already corrected by
[`terminal-inventory-path-claim`](../../terminal-inventory-path-claim/prd.md).

## Acceptance

- [ ] **R1, all five carriers.** Each of the five passages is quoted in the
      report before and after, and each after-text contains
      `No viable candidates found in PATH`.
- [ ] **The claim is gone from the five carriers.** Over the four footprint
      files, `dies on the spot` → 0, `window dies` → 0, `launch dies` → 0,
      `rather than dying` → 0, and `dies immediately` → **1**, that one being
      06-launchd-path R3 quoting the retired wording inside its own
      correction.
- [ ] **R3, the closing census, run and quoted.** Dimension A's phrase sweep
      over `prds/ docs/ home/ tests/` returns hits only at the allowlisted
      paths above — no path outside that table, and no line in the four
      footprint files other than 06-launchd-path R3.
- [ ] **R3, dimensions B and C.** Both re-run after the edit and quoted, with
      no new outcome claim in either.
- [ ] **R2, the file no longer contradicts itself.** In
      `prds/02-terminal/06-launchd-path/prd.md`, `The window does not die`
      appears twice — once in the Purpose, once in R3 — and no line asserts
      that it does.
- [ ] **R4, the contract is untouched.** Checked against the three files as
      they stand: every box id present before is present after with the same
      marker (`grep -o '\*\*R[0-9]*\*\*'` and the box-marker counts per
      file, quoted before and after), and `grep -c '· C [0-9]'` is unchanged
      in each. The original `git diff -U0` clause cannot carry it — all three
      of `prds/02-terminal/06-launchd-path/prd.md`,
      `prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md` and
      `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md` are
      untracked (`git ls-files --error-unmatch`, 2026-08-23), so there are no `-`/`+` sides to pair
      and "no box appears only on one side" is vacuously true. Unprovable in
      retrospect: the pre-edit state was untracked, so git never held a copy
      and no `cp` aside was kept. What would have proved it: the per-file
      counts above, taken before the first write.
- [ ] **No frontmatter changed.** `shasum -a 256` of each file's leading
      `---` fence is identical before and after, all four quoted. `git diff`
      cannot carry it: none of the four files is tracked (`git ls-files --error-unmatch`, 2026-08-23),
      so a diff over the footprint is empty whatever the frontmatter did.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: those
      four fence hashes, taken before the first write.
- [ ] **The link delta is exactly zero.** Markdown-link count per footprint
      file is identical before and after. Tier A stays at `0` broken and
      Tier B stays at `114` — a moved Tier B means a link was added in
      `specs/**`, which Edit 5 forbids.
- [ ] `bash gates/tree-links.sh` exits 0, asserted as a before/after delta
      rather than an absolute count. Other lanes write this tree
      concurrently, so an absolute link count measured now is stale by the
      time it is read.
- [ ] **78 columns.** No replaced line in the three prose edits exceeds 78
      characters. Edit 3's table row is exempt.
- [ ] **Nothing outside the footprint changed.** `git status --porcelain`
      names the four files plus this node's own directory, and nothing else
      this node wrote.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
A=prds/02-terminal/06-launchd-path/prd.md
B=prds/00-delivery/corrections/prd.md
C=prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md
D=prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md

# --- baselines, BEFORE the edit ---------------------------------------------
python3 gates/tree-links.py --tier a --count-only                 # expect 0
python3 gates/tree-links.py --tier b 2>/dev/null | grep -c '^BROKEN '  # 114
for f in $A $B $C $D; do printf '%s links=' "$f"
  /usr/bin/grep -oE '\]\([^)]+\)' "$f" | wc -l; done

# --- after the edit: the claim is gone from the five carriers ---------------
for p in 'dies on the spot' 'window dies' 'launch dies' \
         'rather than dying'; do
  printf '%-22s ' "$p"; /usr/bin/grep -cF "$p" $A $B $C $D | tr '\n' ' '; echo
done                                                              # all 0
/usr/bin/grep -cF 'dies immediately' $A $B $C $D                  # A:1 B:0 C:0 D:0
/usr/bin/grep -nF 'dies immediately' $A          # the one hit is R3's quote

# --- R1: every carrier now names the measured symptom -----------------------
/usr/bin/grep -cF 'No viable candidates found in PATH' $A $B $C $D
/usr/bin/grep -nF 'The window does not die' $A                    # 2 lines
/usr/bin/grep -nF 'the window does not die' $B                    # 1 line

# --- R3, dimension A: the closing census, subject-free ---------------------
/usr/bin/grep -rInE 'window dies|launch dies|dies on the spot|dies immediately|rather than dying|the GUI (launch )?dies' \
  prds/ docs/ home/ tests/
# every hit must fall in the allowlist table above. Nothing else.

# --- R3, dimension A, wide form: death lexicon x launch nouns --------------
DEATH='die[sd]?\b|dying|death|vanish|disappear|crash|exits? immediately|closes? immediately|quits? immediately|never opens|fails? to (open|launch|start)|no window|window is gone|blows up|bails|falls over|terminates|is dead'
LAUNCH='GUI|Finder|Spotlight|Dock|launchd|launch|window|WezTerm|terminal|default_prog|PATH'
/usr/bin/grep -rInE "$DEATH" prds/ docs/ | /usr/bin/grep -InE "$LAUNCH" | wc -l
# read the list: every remaining hit is a pane or a tab dying, which is true

# --- R3, dimension B: the subject, verb-free ------------------------------
/usr/bin/grep -rlnE 'launchd[- ]PATH|PATH seeding|GUI launch|launched from (Finder|Spotlight|the Dock)|set_environment_variables' \
  prds/ docs/ home/ tests/
# read each file's hits: no outcome claim other than the corrected ones

# --- R3, dimension C: the euphemism ---------------------------------------
/usr/bin/grep -rInE 'is fatal|unusable|hard failure|nothing (starts|comes up)|no shell (starts|at all)|cannot (launch|start up)|never (comes up|appears|starts)|is lost|breaks outright' \
  prds/ docs/ | /usr/bin/grep -InE 'launch|PATH|WezTerm|GUI'
# expect only 06-launchd-path:32 "absence is fatal" and
# spec01-launch-environment.md:99 "never starts nushell at all" — both true

# --- R4: no box, requirement or rating moved ------------------------------
git diff -U0 -- $A $C $D | /usr/bin/grep -E '^[-+][[:space:]]*- \[[ x~]\]'
# every line must pair: same marker, same id, on - and on +
git diff -U0 -- $A $B $C $D | /usr/bin/grep -cE '^[-+].*· C [0-9]'   # 0

# --- no frontmatter touched ----------------------------------------------
git diff -U0 -- $A $B $C $D | /usr/bin/grep -E '^[-+(../../../../../../prds/00-delivery/corrections/gui-dies-claim-carriers/specs/state|claim|est|actual|priority|deps|mode|verify|task):'
# expect no output

# --- links: zero delta, and the gate -------------------------------------
for f in $A $B $C $D; do printf '%s links=' "$f"
  /usr/bin/grep -oE '\]\([^)]+\)' "$f" | wc -l; done   # same as the baseline
python3 gates/tree-links.py --tier a --count-only                 # still 0
python3 gates/tree-links.py --tier b 2>/dev/null | grep -c '^BROKEN '  # 114
bash gates/tree-links.sh > /dev/null; echo "tree-links exit=$?"   # 0

# --- 78 characters, table rows and link lines excepted -------------------
python3 - "$A" "$C" "$D" <<'PY'
import sys
for f in sys.argv[1:]:
    for n, l in enumerate(open(f), 1):
        l = l.rstrip("\n")
        if len(l) > 78 and not l.lstrip().startswith("|") and "(../../../../../../prds/00-delivery/corrections/gui-dies-claim-carriers/specs/" not in l:
            print(f"{f}:{n} {len(l)} chars")
print("length check done")
PY

# --- footprint ------------------------------------------------------------
git status --porcelain
```

## The residue — name it, do not fix it here

- **Nothing gates the wording in these four files.**
  `tests/wezterm-launchd-path.sh:292` keeps the three phrases out of
  `home/dot_config/wezterm/wezterm.lua` only, which is why the PRD tree
  carried the claim for three days after the comment was corrected. The
  symmetric guard is three `chk_fail` greps in that file's static stage over
  `prds/02-terminal/06-launchd-path/prd.md`. Not added here: that gate is
  `02-terminal/06-launchd-path`'s, a `done` node, and adding a check to it is
  a different contract from correcting prose.
- **`w0-2-terminal-respec/specs/spec06.md`'s frontmatter `verify` is dead.**
  It greps `.mi/prds/02-terminal/06-launchd-path/prd.md`, a path the mi-era
  retirement removed. Edit 5 keeps the string that `verify` looks for so the
  command's intent survives, but the command cannot run. Frontmatter is the
  orchestrator's and this is not that node's correction — it is a whole class,
  since every `w0-2-terminal-respec` spec carries a `.mi/`-rooted `verify`.
- **`prds/02-terminal/06-launchd-path/prd.md` has five `[~]` acceptance
  boxes** whose residue is three `T.7` rows in `gates/manual/wave4.md`. Those
  rows exist and are correct. This node changes none of them.
