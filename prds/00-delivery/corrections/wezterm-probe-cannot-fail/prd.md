---
state: done
priority: 16
est:
mode: afk
needs:
verify: "bash gates/wezterm-config-fields.sh"
origin: derived
from: 02-terminal
claim:
complexity: 25
blast-radius: low
---

# `02-terminal`'s config-field probe names a command but no predicate

Parent: [Corrections backlog](../prd.md) · net-new

**Corrected 2026-08-28, hours after filing.** This node was filed claiming the
check *cannot fail*. **That was wrong, it was my error, and the correction is
the more useful finding.** A skeptic re-ran the measurement, refuted it, and
the orchestrator reproduced the refutation on the same binary. The original
wording is kept below the line rather than deleted, because a board that
files a bad measurement and quietly rewrites it has learned nothing.

Purpose: [`02-terminal`](../../../02-terminal/prd.md)'s second acceptance line
reads

> No child names a WezTerm config field that the installed build
> (`20240203-110809-5046fc22`) rejects at config-load time — the check is a
> minimal probe config through
> `wezterm --config-file <probe> ls-fonts --list-system`.

It names a command and no predicate, and **the one obvious predicate does not
work**: `EXIT=0` comes back from a clean probe, from an unknown config key,
and from a type error alike. That is what has to be fixed.

**The measurement, corrected.** Everything turns on how the probe table is
built — which the acceptance line never says:

| probe form | unknown key `no_such_wezterm_field` | result |
|---|---|---|
| plain `return { ... }` | silently ignored | `EXIT=0`, 0 stderr bytes |
| `wezterm.config_builder()` | **rejected** | `EXIT=0`, **0 stdout lines, 351 stderr bytes** |

`config_builder()` installs a validating `__newindex` metamethod; a bare table
has none. Measured 2026-08-28 at the exact subcommand the line names: a clean
`config_builder()` probe gives `EXIT=0`, **791 stdout lines, 0 stderr bytes`;
the same probe plus one bogus key gives `EXIT=0`, **0 stdout lines**, and

```
ERROR  wezterm_gui > error converting Lua table to Config
(Config::from_dynamic: `no_such_wezterm_field` is not a valid Config field.)
```

So there are **two** working discriminators — empty stderr, and non-empty
stdout — at the command already on record. And `config_builder()` is what the
real config uses: `home/dot_config/wezterm/wezterm.lua:12` and the deployed
`~/.config/wezterm/wezterm.lua:8`. A probe that does not use it is not testing
the thing that ships.

**Why the first measurement was wrong, since that is the transferable part.**
The contract says to run a cheap claim twice with a different input. It *was*
run twice — against `ls-fonts` and `show-keys` — but both runs used the same
plain-table probe. Varying the subcommand while holding the fixture fixed is
not varying the input. The fixture was the variable that mattered, and it was
the one held constant.

## Requirements
- [x] **R1** — Rewrite `02-terminal`'s second acceptance line so it names a
      **predicate**, not just a command. The mechanism closest to the record
      and known to work: keep
      `wezterm --config-file <probe> ls-fonts --list-system`, build the probe
      with `wezterm.config_builder()` — because that is what ships — and
      assert **empty stderr**, or equivalently non-empty stdout. State the
      exit code is not usable, because that is the trap the line fell into.
- [x] **R2** — The replacement is **proven to bite**: introduce the violation,
      watch the check fail, quote both runs. `G.1`'s rule — a gate is proven
      by its own red — and the rule this node's own first draft broke.
- [x] **R3** — **Withdrawn 2026-08-28.** It said to write "this build does not
      reject unknown config keys" into the epic as a standing constraint. That
      claim is false and would have put a measurement error into `02-terminal`
      in the epic's own voice, permanently, for every future author. The
      constraint worth recording is the true one, and it belongs with R1: a
      probe must use `config_builder()` or it validates nothing, and `EXIT=0`
      never discriminates.
- [x] **R4** — Run the corrected check over the nineteen `config.*` fields the
      epic's children name and record the verdict, so `02-terminal`'s
      acceptance closes on evidence. The fields are expected clean — a plain
      probe carrying all nineteen loaded without error — but that was measured
      with the fixture now known to be blind, so it does not count and must be
      redone under `config_builder()`.

## Acceptance
- [x] The replacement check fails on an introduced violation and passes
      without it, both quoted, with the probe's construction shown.
- [x] `02-terminal`'s acceptance line names that check, and the epic can close
      on it.
- [x] The `config_builder()`-vs-bare-table distinction is written where a
      WezTerm author will meet it — it is the whole difference between a probe
      that validates and one that does not.

## Out of scope
- The other three `02-terminal` acceptance lines. Measured 2026-08-28: the
  three-place child count and the no-hardcoded-hex rule pass; the child-header
  rating line has its own open question, recorded in the epic.
- Changing any `config.*` field the children name. This is about the method.

---

## Superseded — the original filing, kept as the record

Filed 2026-08-28 claiming the check "cannot fail on the thing it names", on a
probe measurement showing an unknown key ignored at `EXIT=0` with empty stderr
at both `ls-fonts` and `show-keys`. **Refuted the same day.** That probe used
a plain `return { ... }` table, which installs no validating metamethod, and
the conclusion was drawn from a fixture that could not have shown rejection
whatever the build did. The finding it was built on — that the exit code
discriminates nothing — survives, and is now R1's.
