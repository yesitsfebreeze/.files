Verdict: DONE

# 04-nushell — implementer report (pass two)

Pass one built and deployed R1-R12 and wrote the spec from the run. Pass
two — this one — did not rebuild it. It ran the workflow against the
survivor, closed the two steps pass one had left standing on a hand fix or
an unfailable assertion, and re-measured every live claim rather than
inheriting it.

Two things changed in the tree. `home/.chezmoiremove` gained the four
target paths pass one had `rm`'d by hand, which is what
`check-what-apply-left-behind` asks for and what pass one substituted a
manual removal for. And the spec's `## Verify and Proof` block was
rewritten: the old one could not fail on its main negative assertion.

Everything else in the footprint is pass one's, unchanged and re-verified.

## What pass two found and fixed

**The verify block had a line that could never fail.** The pass-one block
asserted `! grep -rn '_z_no_zoxide\|…' home/dot_config/nushell/*.nu` under
`set -e`. A command whose status is inverted with `!` is exempt from
`set -e`, so that line reported nothing whatever it found — the exact shape
`run-the-verify-twice` names. Its neighbour,
`test "$(rg -c … 2>&1; echo $?)" = "1"`, graded a concatenated string that a
single match would have changed the shape of rather than a condition. Both
are now `if <cmd>; then fail; fi`, and every assertion in the block names a
post-state — no `git add`, no `git commit`, no comparison against HEAD
while the tree is deliberately dirty.

Proof the rewrite is falsifiable, not just longer: planting `_z_no_zoxide`
into `zoxide.nu` exits non-zero at that line
(`FAIL: a symbol R4-R9 deletes still appears in the nushell source`), and
planting `copymode.nu` back at its deployed path exits non-zero at its own
(`FAIL: /Users/feb/.config/nushell/copymode.nu survived the apply at its
deployed path`). Both restored. The block then runs twice with identical
output and exit 0.

**The retirement was a hand `rm`; it is now a mechanism.** Pass one
correctly found that `chezmoi apply` leaves a deployed file behind when its
source is deleted, and removed all four targets directly. That fixes one
machine. `home/.chezmoiremove` is the file the repo already carries for
this — `03-help-system` put four lines in it — and it now carries the four
this PRD deletes:

```
.config/nushell/copymode.nu
.config/television/cable/cht.toml
.config/television/cable/cht-query.toml
.config/television/cable/channels.toml
```

Proven rather than asserted: `git show HEAD:` copies of `copymode.nu` (307
bytes) and `cht.toml` (2307 bytes) were planted back at their deployed
paths, and a **scoped** `chezmoi apply ~/.config/nushell ~/.config/television`
removed both, exit 0. So `.chezmoiremove` is not skipped by a scoped apply.

`home/.chezmoiremove` is one file outside the PRD's frontmatter footprint —
see **Footprint** below.

**A trap found while proving it, now on record.** On the *second* plant,
after a successful removal, chezmoi had forgotten the entry and asked
`.config/nushell/copymode.nu has changed since chezmoi last wrote it?` —
and headless that is not a skip, it is
`could not open a new TTY: open /dev/tty: device not configured` and
**exit 1 for the whole apply**. `--force` answers it. A `.chezmoiremove`
line can therefore turn a green headless apply red on a machine where the
user had edited the file being retired. This is why the verify block
asserts each target's absence directly instead of trusting the apply's exit
code. Recorded as `[[260902-7c3a]]` and concluded, with pass one's
`[[260902-f203]]` as the second source, at
`conclusions/deleting-a-chezmoi-source-is-half-a-retirement-the-other-hal`.

**The bare-shell half of step 3 had no artifact.** Pass one proved the
config in `nu -l -c`, which is right as far as it goes, but every such
check names a config path. `probe/verify.sh` now starts bare `nu` under
`tmux new-session` — nobody hands it a path — waits 6s, sends a check,
waits 8s, captures. It grades **positively**: the success string must
appear, and the default arm fails. That matters on nu 0.115.1, which
answers an unresolved name with ``Command `x` not found`` under a
`nu::shell::external_command` banner, so a probe enumerating "unknown
command" / "executable was not found" would grade a missing definition OK.
A missing `tmux` fails the probe rather than skipping it. It asks for
`_theme_previous_file`, a name that did not exist before this change —
theme.nu carried `THEME_SLOT` A/B files — and it answers
`PROBE_OK_previous.txt`.

## Premises, re-measured against the survivor

`measure-the-premise-not-the-prd`'s own "Fails when" applies here: pass one
already acted, so each command measures the *result*. Marked accordingly.

| R | command | result |
|---|---|---|
| R1 | `rg -q 'du -sk' config.nu` | no match; icon overlay at :116-129, `-d`/`-D` at :133-149 carry the builtin's meaning — survivor, pass one |
| R2 | `rg -c 'upsert keybindings' config.nu` | `1`, one `append` of 9 records, `tv_completion` still `event: null` — survivor, pass one |
| R3 | `rg 'stood here\|removed on 20\|retired on 20\|used to' *.nu` | exit 1, no match. One survivor in the footprint `.nuon`, kept — see below |
| R4 | `rg 'wl-copy\|xclip\|_z_no_zoxide' *.nu` | no match. `which tinty` at config.nu:265 remains, inside R11's block, deliberately |
| R5 | `ls copymode.nu`, `rg '"zl"\|"zc"\|"cdi"' shell.nuon` | absent; no manual entries — survivor, pass one |
| R6 | `rg '_capsule_record\|recents.nuon' capsule.nu capsule.nuon` | exit 1, no match |
| R7 | `rg 'cht' finder.nu`, `ls television/cable/` | no cht; 15 cables, none of the three |
| R8 | `(_theme_previous_file) \| path basename` | `previous.txt`; no `THEME_SLOT` anywhere |
| R9 | `rg '_state_dir' theme.nu` | theme.nu:8 uses dirstack's; both shquote helpers absent tree-wide |
| R10 | `rg ENV_CONVERSIONS env.nu` | exit 1; `nu -n -c '$env.PATH \| describe'` → `list<string>` |
| R11 | `rg -c 'tinted-shell-scripts-file.sh' config.nu` | `1` — block untouched, as instructed |
| R12 | shasum of `guide/` + `reference/` before and after `just manual` | identical — settled, and idempotent |

Counters, written down so a recount is a check: R3's number is **ripgrep
MATCHING LINES**, dry runs included, over `home/dot_config/nushell/*.nu`
(**0**) and the two footprint `.nuon` files (**1**). Line budget:
`wc -l < config.nu` is **302**, cap 320.

## Live checks, re-run in pass two rather than inherited

Both forms of `prove-in-a-shell-that-loaded-the-config`, never `nu -c`:

- `ls -d | length` → `8`; `ls --du | first | get size` → `108,1 KiB`
- `$env.PATH | describe` → `list<string>`, config-less and config-full
- `zl`, `zc`, `cdi` → ``Command `zl` not found``, exit 1 each
- `capsule recent` → `capsule: not a directory: /Users/feb/dev/dotfiles/recent`
- bare `finder` → `finder: interactive-only — tv requires a TTY`, exit 1;
  the `--start` requirement is finder.nu:14
- three `cd`s then `z nushell` → lands on
  `/Users/feb/dev/dotfiles/home/dot_config/nushell`
- `theme toggle` twice → `base16-caroline` →
  `base16-gruvbox-dark-hard` → `base16-caroline`; the machine is left on
  the scheme it started on
- `tmux list-keys -T root` → `bind-key -T root F4 copy-mode`, from
  `tmux.conf:319`. Deleting `copymode.nu` cost nothing on that path
- `quicklist` resolves as `custom`; `_theme_bg_restore` is theme.nu:70 and
  the `else` arm at :117
- bare `nu` under tmux → `PROBE_OK_previous.txt`

The interactive picker screens (the `theme` remote, Ctrl-Q's replay) still
need a real TTY and are not proof a headless run can produce —
`manual → internals/unverified` territory, unchanged from pass one.

## Findings

- **`copymode` still has a live manual entry, and its command is gone.**
  `help/terminal.nuon:142` reads `cmd: "copymode"` and :144 tells the
  reader to type it at a host prompt; the generated `guide/copy.md:16`
  repeats it. `copymode.nu` is deleted, so that entry now documents a
  command that does not exist. `terminal.nuon` is **not** in this PRD's
  footprint — R5 says the entries leave `shell.nuon`, and this one was
  never in `shell.nuon`. Reported, not fixed. It belongs to whoever owns
  `terminal.nuon` (`07-multiplexer` / `03-help-system`).
- **The hand-written internals pages are stale by 26 lines.**
  `manual/internals/nushell-modules.md` (22 matching lines) still walks
  through `_finder_pick_channel`, `_finder_shquote`, `_z_no_zoxide` and a
  `## copymode.nu` section; `manual/internals/capsule.md` (4) still
  documents `_capsule_record` and `_capsule_shquote`. Counter: `grep -c`
  of that alternation over the two files. `internals/` is hand-written and
  `just manual` explicitly does not touch it
  (`generate-manual.mjs:12`), and the PRD's Out of scope assigns the
  manual to `03-help-system`. Reported, not fixed. `internals/unverified.md:93`
  also still carries T.4, "run `copymode` at a host prompt", which can no
  longer pass.
- **`cable/theme.toml.tmpl`** still describes the retired A/B slot pair in
  its header. Out of footprint. Carried forward from pass one, re-checked.
- **R3's one survivor is deliberate.** `help/shell.nuon:353` matches
  `used to` — "the flags that used to address either side explicitly are
  gone". Not a changelog: it is the reason `core-help ls` is the only
  route to nushell's own `ls` help, which is a trap that still bites, and
  R3's own text keeps one line for exactly that. Annotated in `prd.md` so
  the tick is honest.
- **Two acceptance boxes were corrected before dispatch and both now
  close.** The keybindings-count box (raw count was never a valid proxy;
  nushell dedupes keybindings by `name`) and the `capsule recent` error
  shape. Both were `[~]` in pass one's spec against the *original*
  wording; against the corrected wording they are `[x]`, measured. The
  original readings are kept in the spec as the record of why the boxes
  moved.
- **`chezmoi diff` shows three pending "new files" at `$HOME` root** —
  `generate-shell-init.sh`, `register-mcp.sh`, `seed-mason-registry.sh`.
  These are `run_after_*` scripts chezmoi **executes**, not files it
  deploys. Exactly the shape `apply-scoped-not-bare`'s "Fails when"
  predicts. Alarming, not a defect; nothing was scoped around them.

## Footprint

The PRD frontmatter's footprint plus **`home/.chezmoiremove`**, one file
outside it. `just board-guard 09-simplify/04-nushell home/.chezmoiremove`
returns clean — no other node holds it — and it is committed and
unmodified (`3f02c2c`, `03-help-system`), so there is no second writer. It
is not a separate change: it is the declaration that this PRD's four
deleted files are retired, and `check-what-apply-left-behind` step 3
requires a repo-carried mechanism rather than the hand `rm` pass one did.
The alternative was to ship a knowingly-incomplete retirement and report
the gap; the four additive lines cost nothing and are proven to fire.

Also written inside the PRD directory: `probe/verify.sh`, and the ticks
and annotations in `prd.md` and `specs/spec01-simplify.md`.

Health floor: the brief listed no file in this footprint under it. Nothing
moved on that account.

## Workflow simplify-a-nushell-surface-and-deploy-it

| # | atomic | outcome |
|---|--------|---------|
| 1 | `measure-the-premise-not-the-prd` | **pass**, in its "Fails when" form — pass one had already acted on every premise, so each command measures the survivor. Every R has a command and its output above, marked. R3's counter is written beside its number |
| 2 | `prove-nothing-reads-it` | **pass**. Every hit for the nine deleted names classified. Readers: none. Mentions: `.pearde/prds/**`, `docs/simplification-plan.md`, and the hand-written `manual/internals/*.md` — the last is stale documentation, reported. `chezmoi managed` confirms none of the four deleted paths is still owned |
| 3 | `prove-in-a-shell-that-loaded-the-config` | **pass**, after adding the missing bare-shell half. Both forms answer; the name asked for did not exist before this change; the probe grades the success shape positively and fails on a missing `tmux` |
| 4 | `apply-scoped-not-bare` | **pass**. `chezmoi diff` read first: only the three `run_after_*` scripts pending, which its "Fails when" predicts. `chezmoi apply ~/.config/nushell ~/.config/television`, never bare. Scoped diff now empty; the three run-scripts still pending |
| 5 | `check-what-apply-left-behind` | **pass**, after replacing pass one's hand `rm` with `.chezmoiremove`. All four absent at their deployed paths; the removal proven by planting the originals back and re-applying scoped |
| 6 | `run-the-verify-twice` | **pass**, after rewriting the block. Two runs, identical output, exit 0. Two deliberate breaks each exit non-zero at their own line |

No back-edge was taken.

### Edits

Three replacements for the workflow files, each from a failure this run's
atomics caused. I did not edit the workflow myself.

**1 — `check-what-apply-left-behind`, `## Do` step 3, replacement text.**
The step says "give the retirement a mechanism the repo carries" without
naming one, and pass one read that as satisfied by a careful hand `rm`.
Name the mechanism, because chezmoi has exactly one and it is not obvious:

> 3. Give the retirement a mechanism the repo carries. For chezmoi that is
>    `.chezmoiremove` in the source root — one target path per line,
>    relative to `$HOME`, no leading `./`. A hand `rm` fixes the machine in
>    front of you and no other. A **scoped** apply does process it; it is
>    not skipped just because the apply names paths.
> 4. Prove the mechanism fires rather than asserting it: plant the deleted
>    file's original bytes back at its deployed path
>    (`git show HEAD:<source path> > <deployed path>`), re-apply scoped,
>    and confirm it is gone.

**2 — `check-what-apply-left-behind`, a `## Fails when` the section does
not list** (it is currently empty):

> - The retired target no longer matches what the deploy tool last wrote —
>   locally edited, or re-created after a successful removal, which makes
>   the tool forget the entry. chezmoi then **prompts**
>   (`… has changed since chezmoi last wrote it?`) and headless that is not
>   a skip: `could not open a new TTY: open /dev/tty: device not
>   configured`, exit 1 for the whole apply. A green CI apply can go red on
>   one user's machine for a file being deleted. Answer it with `--force`
>   where the retirement is intended, and assert each target's absence
>   afterwards rather than trusting the apply's exit code. Measured
>   2026-09-02 on chezmoi in this repo.

**3 — `run-the-verify-twice`, `## Do` step 2, replacement text.** The step
names `! cmd` and `grep -c` but not *why* `! cmd` is exempt, which is the
part that makes the defect invisible on reading:

> 2. Read every negative assertion. Under `set -e` the shell does **not**
>    exit when a command's status is inverted with `!` — it is one of the
>    documented exemptions, alongside `if`, `while`, `&&`/`||` and
>    non-final pipeline stages — so `! grep …` reports nothing whatever it
>    finds. `grep -c`/`rg -c` exit 1 on a count of 0, so a `test "$(… ; echo
>    $?)"` around one grades a string shape, not a condition, and a single
>    match changes that shape. Write both as
>    `if cmd; then echo FAIL; exit 1; fi`.

No term was missing from the grammar.

## Numbers

- specs: 1 · boxes `[x]` 9, `[~]` 0, `[ ]` 0
- prd.md: requirements `[x]` 12/12 · acceptance `[x]` 6/6 · open 0
- verify: 2 runs, exit 0, identical output; 2 falsifiability breaks, both
  non-zero
- gates: `just board-guard-blocks` rc 0, `just board-guard` rc 0 (footprint
  and `.chezmoiremove`), `just manual` idempotent
- config.nu: 302 lines, cap 320
- knowledge: 1 source `[[260902-7c3a]]`, 1 conclusion from 2 sources
- findings out of scope: 4 (terminal.nuon `copymode` entry, internals
  staleness 26 lines, `theme.toml.tmpl`, `unverified.md` T.4)
