---
state: done
priority: 40
est: 3.25h
task: P.4
mode: afk
needs:
  - 05-platform/02-package-provisioning/packages-installer
verify: ""
---

# Shell-init generation

Parent: [Provisioning epic](../prd.md) · C 3 · U 9 · source: "Shell-init
generation" in
[`capabilities-provisioning.md`](../../../docs/capabilities-provisioning.md)

Purpose: The integration files Nushell only *sources* are generated at apply
time, not shell-start time. This is what lets shell launch do zero setup work
— the requirement [`04-shell/01`](../../04-shell/01-core-config/prd.md) depends on.

## Requirements
- [x] **R1** — **Runs last.** A `run_after` script, after the package
      installer, so it can use tools installed in the same apply (re-resolving
      brew shellenv and user bins first).
      *Met 2026-08-21. Proved, not asserted: the gate's `tv` stub records
      whether the managed target `.gitconfig` exists at the moment it runs
      and records `present` (`tests/shell-init.sh --apply`). The installer
      half is asserted read-only by line index — `install.sh` runs the apply
      at line 409, after sections 1 (273) and 3 (370).*
- [x] **R2** — **Generated files.** starship → `~/.cache/starship/init.nu`;
      zoxide → `~/.zoxide.nu`; television → `~/.cache/television/init.nu`.
      **Note the inconsistency in the live layout**: two live in `~/.cache`,
      one in `$HOME`. Pick one location for all three in the rebuild and
      update the [shell epic's](../../04-shell/prd.md) invariant to match,
      rather than inheriting the split. *Met 2026-08-21 as D1:
      `~/.cache/nushell/init/{starship,zoxide,television}.nu`. The gate
      asserts both directions — the three files exist there, and none of
      `~/.zoxide.nu`, `~/.cache/starship/init.nu`,
      `~/.cache/television/init.nu` reappears. No `04-shell` edit was needed
      (I4 already reads "generated integrations in cache").*
- [x] **R3** — **Never break `source`.** Guarantee each file exists after the
      run — an empty file is a harmless no-op — so `config.nu`'s `source`
      lines cannot fail on a machine where a tool isn't installed yet.
      *Met 2026-08-21 against four scratch machines: no tool at all (three
      empty files, exit 0), a tool that exits 1 mid-line (the half line does
      not survive — the target is truncated to empty), and a tool that prints
      nothing. `nu -n -c 'source …; source …; source …; print OK'` prints
      `OK` for the all-empty case and for the stubbed case.*
- [x] **R4** — **Regenerate every apply.** These are derived artifacts; they
      are not committed and are always rewritten, so a tool upgrade's new init
      is picked up. *Met 2026-08-21. Three consecutive `chezmoi apply`s:
      the second leaves all three files byte-identical, and after deleting
      them the third regenerates all three to the same sha256. Counterfactual
      in the same run: renaming the source to `run_onchange_after_…` turns
      `--apply` red. `chezmoi managed` lists none of the three and `chezmoi
      status` names no path under `.cache`.*
- [x] **R5** — **Version-sensitive output.** The generated television init
      defines the `tv_shell_history` command the shell binds to `Alt-R`
      ([`04-shell/05`](../../04-shell/05-history/prd.md)) — so a tv upgrade that
      renames it breaks a keybinding. The gate checks the binding, not just
      the file. *Met 2026-08-21 by definition rather than by grep:
      `tests/shell-init.sh --live` sources the REAL `tv init nu` output into
      `nu` and asks `scope commands` for `tv_shell_history`, which answers
      `DEFINED` (tv 0.15.9, nu 0.114.1). The same probe with a name tv does
      not define prints nothing, so a `DEFINED` from anywhere else cannot
      pass.*

## Acceptance
- [x] After an apply, all three files exist and are non-empty on a machine
      with the tools installed. *Met 2026-08-21 twice: through a real
      isolated `chezmoi apply` with marker stubs (each file byte-equal to its
      stub's output), and with the REAL tools, which produced
      `~/.cache/nushell/init/` at 2280 / 1966 / 1809 bytes. The zoxide file
      is byte-identical to `~/.local/bin/zoxide` 0.9.9, not brew's 0.10.0 —
      D2's PATH precedence, proved on the artefact.*
- [x] On a machine missing starship, the file exists, is empty, and launching
      `nu` produces no error. *Met 2026-08-21 on the `home-bare` machine: all
      three files exist, all three are empty, the run exits 0, and
      `nu -n -c 'source …; print OK'` over the three empty files prints
      `OK`.*
- [~] `Alt-R` resolves to a defined command after a fresh apply. *Half of
      this is proved and half is not yet buildable. The command exists: the
      generated television init DEFINES `tv_shell_history` (R5 above). The
      binding does not — `04-shell/05-history` R2/R5 own `Alt-R` and are
      unbuilt, so nothing resolves it today. Closes to `[x]` when S.5 lands;
      this node deliberately owns only the command half (see
      [`specs/spec03.md`](specs/spec03.md) Out of scope).*
- [ ] Launching a shell runs no generator: timing a cold `nu` start shows no
      init-generation cost. *Not measured, deliberately: `config.nu` is
      `04-shell/01` R9's and is unbuilt, so there is no cold start to time
      yet. Structurally the generator is a chezmoi `run_after` script and is
      invoked by nothing at shell start, but the box asks for a measurement
      and none was taken.*
      *(b) — genuinely unmet: the measurement was deliberately not taken
      because `config.nu` is unbuilt. Closes when `04-shell/01` R9 lands.*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Decisions (analyst, 2026-08-21)

Recorded here because [`04-shell/01`](../../04-shell/01-core-config/prd.md)
depends on this node and its `source` lines must match. Full evidence in
[`specs/spec01.md`](specs/spec01.md).

**D1 — R2's one location is `~/.cache/nushell/init/`**, files `starship.nu`,
`zoxide.nu`, `television.nu`. The old split (`~/.cache/starship/init.nu`,
`~/.zoxide.nu`, `~/.cache/television/init.nu`) is not inherited. R2 also asked
for the shell epic's invariant to be updated to match: no edit is needed,
because [`04-shell`](../../04-shell/prd.md) I4 already reads *"generated
integrations in cache"*, and this pick is cache.

**D1a — the path is literal `$HOME/.cache/...`; `XDG_CACHE_HOME` is not
honoured.** Nushell's `source` is resolved at parse time and cannot read
`$env`, so `config.nu` cannot honour the variable even if the generator did —
and a generator that honoured it would write where the shell cannot look. One
hardcoded path on both sides cannot diverge.

**D2 — PATH precedence follows the *shell*, not the installer:**
`~/.local/bin`, `~/.cargo/bin`, then Homebrew. The generated init must
describe the binary the shell will actually launch, and
[`04-shell/01`](../../04-shell/01-core-config/prd.md) R1 defines that order.
`install.sh` ends up with the opposite precedence; the disagreement is real
and deliberate. Measured on this machine: `~/.local/bin/zoxide` 0.9.9 shadows
`/opt/homebrew/bin/zoxide` 0.10.0 and their init output differs.

**D3 — the live script's `pass`-store advisory is dropped.** R1–R5 do not
name it; it belongs to `install.sh` or to
[`04-shell/02`](../../04-shell/02-aliases-utilities/prd.md) R6.

**D4 — `run_after_`, not `run_onchange_after_`.** Measured: `run_onchange_`
runs exactly once and never again, which fails R4. The cost is that chezmoi
reports an always-run script as pending `R` on every `chezmoi status`, forever
— which breaks two assertions in `tests/deploy-skeleton.sh`. Measured, not
predicted: that gate exits 0 today and exits 1 with exactly those two FAILs
once the script is planted. [`specs/spec04.md`](specs/spec04.md) fixes it in
this same change (footprint widened by the orchestrator, 2026-08-21), rather
than leaving the tree knowingly red between two tickets.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `bash tests/shell-init.sh` →
**95 PASS / 0 FAIL**, exit 0, re-run independently; `tests/deploy-skeleton.sh`
60 PASS / 0 FAIL; `just gate 2` green. All four spec verifies green from
reproduced RED (127 / 127 / 127, and both spec04 halves at 1).
`home/run_after_generate-shell-init.sh` and `tests/shell-init.sh` created,
`gates/waves.tsv` wave 2 registered **in the same change that created the
file**.

**Both isolation failures were handled by content, not by style.**
`SHELL_INIT_BREW_PREFIXES` uses `${VAR-default}`, not `:-`, so the gate's empty
value iterates zero times and no brew is evaluated by absolute path — proved by
the artefact: `home-bare` yields three **empty** files where the live reference
script leaked 2280/1998/1809 real bytes. Every gate invocation is
`env -i HOME=… PATH=… SHELL_INIT_BREW_PREFIXES=` with `--destination` pointing
at that same `HOME`. Verified independently: the hermetic gate leaves
`~/.cache/nushell` **absent**.

`--exclude=always`, never `--exclude=scripts`, with the v2.72.0 measurement
table quoted in the comment and `05-platform` I2 quoted verbatim — the check
now matches the requirement (the script re-runs to byte-identical output)
rather than chezmoi's printing behaviour. The S4.5 drift counterfactual passes
against real output, proving the check narrowed rather than disabled.

**A live defect found by hitting it, in another node's file.** P.1's
`tests/deploy-skeleton.sh` `cz()` passes `--destination` but leaves `HOME`
ambient, so once a `run_after` script existed the gate wrote a real
`~/.cache/nushell/init/` on this machine. The implementer measured the blast
radius, **removed the directory** (absent before this work), and did not reach
into `cz()` — spec04 S4.7 protects it as P.1's. That restraint was correct and
is why the fix has its own node,
[`gate-home-isolation`](../../00-delivery/corrections/gate-home-isolation/prd.md)
(W0.9). It is the second isolation failure of the same family today: chezmoi's
flags bound where it **writes**; only `HOME` bounds what the scripts it **runs**
inherit. Neither half suffices alone.

**Two honest corrections in its own report:** spec01 D2's byte figures were
transposed — measured `0.9.9 → 1966`, `0.10.0 → 1998`, not the reverse. The
decision is unaffected and is now proved on the artefact instead: the generated
`zoxide.nu` is sha256-identical to the output of `~/.local/bin/zoxide` 0.9.9,
i.e. the binary the **shell** launches, not the installer's. And S1.4 was
rewritten so that naming the old three-way split's paths in a comment could not
defeat its own "appears nowhere in the file" check.

Boxes left short of `[x]` with reasons rather than fudged: acceptance box 3
(`Alt-R`) is `[~]` — the command half is proved against real `tv` 0.15.9 through
`nu` 0.114.1, but the binding is `04-shell/05`'s and unbuilt; box 4 (cold-start
timing) is `[ ]` because there is no `config.nu` yet to time; and spec04 S4.10 is
`[~]` because it asserts a commit this lane does not make.

Baseline unchanged: `chezmoi source-path` `/Users/feb/dev/.files/home`, config
sha `02d5d4ee`, nushell 0.114.1, nothing installed, `/Users/feb/dev/.files`
unwritten.
