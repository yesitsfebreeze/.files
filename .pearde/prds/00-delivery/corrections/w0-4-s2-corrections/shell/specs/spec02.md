# spec02 — core-config + zoxide corrections

Ticket: W0.4b (`00-delivery/corrections/w0-4-s2-corrections/shell`)
Covers ticket requirements **R1** (L-3, core-config half), **R6** (the shell
coverage gaps), and backlog **M-5**, **M-6**, **M-8** — three "my factual
errors" rows that land in these two files and in no other lane's footprint.

Est: **0.4h**

## Files touched (no other spec in this ticket writes them)

- `.mi/prds/04-shell/01-core-config/prd.md`
- `.mi/prds/04-shell/03-zoxide/prd.md`

## Goal

Close the shell epic's two rating errors, the one mis-attributed hazard, and
the six live behaviours that no PRD and no inventory covers — so that
`04-shell/01` describes the `env.nu`/`config.nu` that exists rather than a
subset of it.

## Do not disturb (landed 2026-08-21, earlier today)

- `01-core-config` **R10** and its `## Decisions` section — the tinty palette
  re-assert, written by `decisions/tinty`. The verify guard **CC-10** fails if
  R10 or its artifact path goes missing.
- `03-zoxide` **R2** — the fzf exception, written by `decisions/fzf`. Guard
  **ZX-4** fails if `zoxide query --interactive` or the `decisions/fzf` link
  goes missing. R2 is the one place the exception is stated at node level;
  epic invariant **I3** is its counterpart and belongs to spec03's file.

## The live facts, measured 2026-08-21

| What | Evidence |
|---|---|
| `rcwd` is not a channel | `cable/recent-dirs.toml` exists, no `rcwd.toml` does; `finder.nu:54` types the name anyway |
| PATH list conversion | `env.nu:4-13` `$env.ENV_CONVERSIONS` for `PATH` and `Path` — **required because the config overrides nushell's stock `env.nu`**, and without it `$env.PATH` is a string, so every `prepend`/`append` in R1 silently does the wrong thing |
| the prompt is starship | `env.nu:44` `$env.STARSHIP_SHELL = "nu"`; `config.nu:412` sources `~/.cache/starship/init.nu`. R5 already leans on starship's *two-line* prompt for the OSC-133 reason, so the file depends on a fact it never states |
| ollama endpoint probe | `env.nu:82-87` — runs `^ollama-host` through `complete` on every interactive start, sets `$env.OLLAMA_HOST` only on exit 0, guarded on `is-terminal --stdout` so `nu -c` callers skip the spawn |
| `esc_clear` | `config.nu:620-632` — Escape closes an open menu first, else clears the line (`event: { edit: clear }`), in `[emacs vi_insert]` |
| the four unspecified config blocks | `config.nu:6-8` `cursor_shape: { emacs: block }` (**the terminal owns the blink**, cf. the `BlinkingBlock` in T-2), `config.nu:10-14` `table: { mode: rounded, index_mode: auto, header_on_separator: true }`, `config.nu:17` `history.sync_on_enter: true`, `config.nu:28-31` `completions.external: { enable: true, max_results: 100 }` |
| the HOME hazard is `mkcd`'s | `~/.zoxide.nu:39-40` — a no-match `zoxide query` returns `""`; `config.nu:274-275` — `mkcd` reads an empty arg as "no argument" and targets `$env.HOME`; the `cd $path` at `~/.zoxide.nu:43` is what carries it in |
| and it also poisons the recents log | `config.nu:441` logs `$env.PWD` when PWD moved — and PWD *did* move, to HOME. The same mechanism is the first finding in `home/dot_config/nushell/help/use-review.nuon`'s header, filed against `03-zoxide`'s acceptance |

## What to write

### `01-core-config/prd.md`

1. **R8 — L-3.** The dirstack feeds the **`recent-dirs`** channel. Keep the
   bug in one clause with its id: the decoder typed `rcwd`, a name no cable
   file has, so recent-dir picks were never decoded as paths. Cross-link
   `04-television` R2 rather than restating the decode — that requirement is
   spec01's and owns the typing.
2. **M-6 — the folded source.** The header claims a single source. This node
   also absorbed the separate **"Dirstack — directory recency"** entry
   (C 3 / U 7) — R7 and R8 are that entry, not "Core shell config". Per the
   working contract, a merged PRD carries the dominant entry's rating and
   lists every source with its own numbers: `C 3 · U 9 · sources: "Core shell
   config" (C 3 / U 9, dominant) + "Dirstack — directory recency" (C 3 / U 7)`
   in `capabilities-nushell.md`. Cite **M-6**.
   *The row half of M-6 ("without … giving it a table row") is already
   discharged: the epic's `## Children` table was deliberately deleted —
   membership is by existence — so there is no table to add a row to. Say so
   in the same clause instead of inventing a table.*
3. **R2 — `ENV_CONVERSIONS`.** Add it with its reason: overriding the stock
   `env.nu` costs the PATH string↔list conversion, and R1's `prepend`/
   `append`/`uniq` only work because it is restored. This is a prerequisite
   of R1, not a decoration.
4. **R2 — `STARSHIP_SHELL`** and, in one clause, that starship is the prompt
   (sourced from the generated init named in R9). R5 already cites the
   two-line prompt as the OSC-133 reason; this is the fact that reason rests
   on.
5. **R2 — the `ollama-host` probe.** Interactive-only, `complete`-guarded,
   sets `OLLAMA_HOST` only on success — and it is one external spawn on every
   interactive start, which is the thing to weigh against R9's zero-work
   startup. Record the cost with the capability.
6. **R3 — the four config blocks.** `cursor_shape` (block; the *terminal*
   supplies the blink — do not restate the terminal's own setting), `table`
   (rounded, auto index, header on separator), `history.sync_on_enter`
   (belongs beside R4's store settings), and `completions.external`
   (enable + `max_results: 100`, which is what makes external-command
   completion work at all).
7. **A new box for `esc_clear`.** Escape closes an open menu first and
   otherwise clears the line. It is a keybinding, so it also owes a `help`
   entry — `06-help/01`'s content model already lists `esc_clear` among the
   bindings it expects to find, so leaving it unspecified here is a gap on
   both sides.
8. **L-2 is a no-op in this file, and that is worth one line.** The backlog's
   L-2 Owner cell names `04-shell/01-core-config` as well as `04-television`,
   but this PRD contains no git-log, no decoder and no commit handling — the
   whole of L-2 lands in `04-television` R2 (spec01). Record the finding so
   the empty result is evidence rather than an oversight.

### `03-zoxide/prd.md`

9. **M-5 — the header.** The rating now reads `C 4 · U 9`, which is the
   dominant entry, but the source list still names one entry. This node
   merges **"Zoxide navigation suite"** (C 4 / U 9, dominant — the wrappers,
   R1–R4) and **"Bare-word zoxide fallback"** (C 7 / U 8 — R5–R7). List both
   with their own numbers and link the inventory. Cite **M-5**.
10. **R6 — M-8.** The hazard is **`mkcd`**, not `__zoxide_z`: a no-match
    `zoxide query` returns the empty string, and `mkcd` reads an empty
    argument as "no argument" and goes `$env.HOME`. Keep the requirement
    (query `zoxide query --exclude $PWD` directly) — it is right — but
    attribute the reason correctly, because the wrong attribution sends the
    fix to the wrong file. Cite **M-8**.
11. **Acceptance — the same mechanism, one layer up.** The box "failed
    `z nomatch` leaves PWD alone and logs nothing" is correct as a
    requirement and **false as a description of the live config**: PWD moves
    to HOME and HOME is logged to the recents (`config.nu:441`). This is the
    first finding in `use-review.nuon`'s header, filed against this node and
    on no live-bug list. Record it here with the M-8 clause, so the box is
    read as work to prove and not as behaviour to preserve.

## Acceptance

- [ ] **CC-1** `rcwd` appears in `01-core-config/prd.md` only inside the
      clause naming live bug **L-3**.
- [ ] **CC-2** the dirstack requirement names `recent-dirs`.
- [ ] **CC-3** the header lists the Dirstack source with its own numbers
      (`U 7`).
- [ ] **CC-4** **M-6** is cited, so the edit is traceable to the backlog row.
- [ ] **CC-5** the `ollama-host` probe is covered.
- [ ] **CC-6** `ENV_CONVERSIONS` is covered.
- [ ] **CC-7** the `esc_clear` binding is covered.
- [ ] **CC-8** `cursor_shape`, `sync_on_enter` and the external-completion
      block are covered.
- [ ] **CC-9** `STARSHIP_SHELL` is covered.
- [ ] **CC-10** *(guard, green now — must stay green)* R10 and its
      tinted-shell artifact path are untouched.
- [ ] **ZX-1** the zoxide header lists the bare-word fallback source with its
      own numbers (`C 7`).
- [ ] **ZX-2** every mention of `HOME` sits with `mkcd`, the mechanism that
      causes it.
- [ ] **ZX-3** **M-8** is cited.
- [ ] **ZX-4** *(guard, green now — must stay green)* R2's fzf exception and
      its `decisions/fzf` link are untouched.

## verify

```
bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec02
```

**Proved RED on 2026-08-21** against the current tree: `2/14 passed (12
FAILED)`. The two passes are CC-10 and ZX-4, which are regression guards on
today's landings — they are green by design and a FAIL there means the
implementer damaged another lane's work.
