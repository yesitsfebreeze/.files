# spec01 — the television + quicklist corrections

Ticket: W0.4b (`00-delivery/corrections/w0-4-s2-corrections/shell`)
Covers ticket requirements **R1** (L-3, television half), **R2** (L-4),
**R5** (burrito channel), **R6** (television coverage gaps), **R7** (L-2),
plus backlog **M-9** and the S3 opacity contradiction, both of which land in
these two files and in no other lane's footprint.

Est: **0.5h**

## Files touched (no other spec in this ticket writes them)

- `.mi/prds/04-shell/04-television/prd.md`
- `.mi/prds/04-shell/07-quicklist/prd.md`

## Goal

Make the two finder PRDs describe the channels and the decoder that actually
exist. Four of the twelve live bugs route here, and every one of them is the
same class of failure: a decoder or a premise that names something the
configuration does not have, failing silently because the code path returns an
empty list instead of an error.

## The live facts, measured 2026-08-21 (do not re-derive; do cite)

| What | Evidence |
|---|---|
| The recent-dirs channel | `~/.config/television/cable/recent-dirs.toml` exists; there is no `rcwd.toml` anywhere in `cable/` |
| The decoder types a name nothing has | `~/.config/nushell/finder.nu:54` — `"files" \| "dirs" \| "rcwd" => "FileList"`; the docstring at `finder.nu:22` repeats it |
| So recent-dir picks fall to `Any` | `finder.nu:58` `_ => "Any"`, and `_finder_decode`'s `_` arm returns raw strings — no `path expand`, no existence filter |
| `recent-files` is untyped for the same reason | no arm names it; `capabilities-nushell.md` records this alongside L-3 |
| git-log already extracts the hash | `cable/git-log.toml` — `output = "{strip_ansi\|split: :1}"`, index 1 of the `--graph` line |
| the decoder extracts it a second time | `finder.nu:140-142` splits that bare hash on `" "` and reads `get -o 1`, which is empty |
| and the guard then eats the row | `finder.nu:145` `where { \|r\| $r.hash =~ '^[0-9a-f]{7,}$' }` — every row fails, the result is `[]` |
| the empty result is invisible | `_finder_open` (`finder.nu:160`) returns on an empty list, so commit → `git show` has simply never run and never complained |
| finder never logs a pick | `_recents_add` is defined and exported in `finder.nu:200` and called **zero** times in that file; the only call sites are `config.nu:436,441,447,516`, all four tagged `"zoxide"` |
| Alt-R runs a channel no PRD names | `config.nu:557-562` binds `alt+r` → `tv_shell_history`; `~/.cache/television/init.nu:23` runs `tv nu-history`; `cable/nu-history.toml` is a local override of tv's builtin because the builtin cold-starts a full nushell and assumes plaintext history while ours is sqlite |
| three channels hijack enter, not one | `text.toml:23` `enter = "actions:edit"`, `zoxide.toml:15` `enter = "actions:cd"` (spawns a nested shell), `recent-files.toml:18` `enter = "actions:edit"` |
| `text.toml` is ours, not stock | it carries a local `output = "{strip_ansi\|split:\::..2}"` and a two-entry source list (Default / Hidden) |
| the f5 collision | `burrito-sessions.toml:25` and `cht.toml:42` both declare `shortcut = "f5"`; dropping burrito dissolves it |

`tests/live-bugs.sh` pins L-1..L-4 against exactly these files and is green.
**Nothing written here may contradict it** — in particular, do not write that
the channel emits the full log line. It emits a bare hash, and that is the
premise of the fix.

## What to write

### `04-television/prd.md`

1. **R2 (typed decode) — L-3.** Type `recent-dirs`, the channel that exists,
   and add `recent-files` (untyped live for the same reason). Carry the bug
   in one clause with its id: `rcwd` is a name no cable file ever had, so
   recent-dir picks fell through to `Any` and came back as raw strings
   instead of expanded, existence-checked paths. Keep `rcwd` in the text
   **only** inside that clause — it must never again read as a channel name.
2. **R2 (typed decode) — L-2.** The `Commits` decode reads the field the
   channel actually emits: `git-log.toml`'s `output` template has already
   reduced the entry to a bare hash, so the decoder takes the emitted value
   whole rather than splitting it again. Record all four parts of the why,
   because they are the expensive half:
   - the extraction belongs to the channel, which also uses it for its
     preview and its three actions — a second extraction in the decoder is
     the duplication that rotted;
   - the `^[0-9a-f]{7,}$` guard is **kept**, but as a validity filter that
     now passes rather than one that eats every row;
   - `subject` cannot come from a bare hash. Either drop it from the produced
     shape (nothing consumes it: R3 opens a commit with `git show $hash`, and
     `07-quicklist` R3 does the same) or have the channel's display template
     supply the label — but the record must say which, not leave `{hash,
     subject}` asserting a field that cannot be filled;
   - **a decode that yields an empty list where the picker showed rows is a
     failure, not a no-op.** This is what hid the bug for the life of the
     config, and the requirement has to forbid it, otherwise the identical
     silent-empty failure returns the next time a template changes.
3. **R1 — M-9.** Three channels hijack enter, not one: `text` and
   `recent-files` bind `actions:edit`, `zoxide` binds `actions:cd` (which
   spawns a nested shell). And `text.toml` is a **local override**, not the
   stock channel — the requirement currently says "stock", which sends a
   future reader looking upstream for a file we wrote. The un-hijack applies
   to all three.
4. **R4 — the opacity contradiction (S3).** Drop `opacity` from the
   dispatch-to-its-own-runner parenthetical. `decisions/wallpaper-opacity`
   (2026-08-21) put the opacity picker out of the minimal base; a PRD that
   both specs the channel and defers it is the exact contradiction the S3
   item names. Where `opacity` still appears, it appears next to that
   decision link.
5. **R5 — the channel set.** Remove `burrito-sessions` (README `DO NOT PORT`,
   decided 2026-08-20; note in one clause that its removal dissolves the
   `cht.sh` / `burrito-sessions` `shortcut = "f5"` collision, so no rekey is
   needed). Add the channels the sweep found uncovered:
   - **`nu-history` — keep, and say that `Alt-R` depends on it**
     (`05-history` R2 binds the key; this epic owns the channel). Carry the
     reason the local override exists: tv's builtin cold-starts a full
     nushell per keypress and reads plaintext history, while ours is sqlite.
   - **`recent-files`** — keep, decoded as a FileList (see 1).
   - **`alias`**, **`cht` / `cht-query`** — name them and their disposition;
     `cht`→`cht-query` is a two-step pipe (`ctrl-p` carries the language into
     the query channel), which is why R2 types `cht-query` and not `cht`.
   - **`channels`** — the remote's own channel, overridden per-call by
     `--source-command`; it is why the set is browsable at all.
   - the non-cable assets: `bg-preview.sh` is **not ported** (it belongs to
     the wallpaper pipeline dropped by `decisions/wallpaper-opacity`);
     `theme-preview.sh` belongs to
     [`09-theme-switcher`](../../../../../04-shell/09-theme-switcher/prd.md),
     referenced, not owned here.
   - **the `theme` channel moves out of "migrate only on demand".**
     `09-theme-switcher` R3 requires a tv-backed scheme picker and points at
     this node; leaving `theme` on the on-demand list contradicts a node
     created today. Link it rather than restating its scope.
6. **Header.** `source: "Television finder` is truncated mid-quote by the
   prose→board conversion. Close it — `"Television finder stack"` (C 8 / U 9)
   — and link `capabilities-nushell.md`, matching the form
   `09-theme-switcher` uses.

### `07-quicklist/prd.md`

7. **Purpose — L-4.** The premise ("everything you pick or jump to lands in
   one recency log") is a description of a thing that does not happen.
   Rewrite it as the rebuild's intent and record the live state with its id:
   `_recents_add` lives in `finder.nu` and `finder` never calls it; the four
   live call sites are the three zoxide wrappers and the bare-word fallback,
   all tagged channel `zoxide`.
8. **R2 — where the fix goes.** Logging happens **inside `finder`, where the
   channel name is already in hand**, so the entry carries the channel that
   produced it. That is the difference between a log that can be replayed and
   one that cannot.
9. **R3 / Acceptance — the replay path is unproven upstream.** Because every
   live entry is tagged `zoxide`, the `ctrl-r` "replay the originating
   channel in its cwd" path has never run for any other channel. The
   acceptance box that replays a `text` (grep) entry is therefore new
   behaviour to build and prove, not a port to preserve — say so, so nobody
   marks it `[x]` off a live demo that cannot exist.
10. **Header.** Close `source: "Quicklist" in` and link the inventory.

## Acceptance

- [ ] **TV-1** `rcwd` appears in `04-television/prd.md` only inside the
      clause that names it as live bug **L-3**.
- [ ] **TV-2** the typed-decode requirement types `recent-dirs` as a
      `FileList`.
- [ ] **TV-3** the git-log correction names **L-2** and cites the channel's
      own `strip_ansi` output template as the evidence.
- [ ] **TV-4** the L-2 text forbids a silent empty decode.
- [ ] **TV-5** no occurrence of `burrito` remains in `04-television/prd.md`.
- [ ] **TV-6** `nu-history` is named together with `Alt-R`.
- [ ] **TV-7** `recent-files` and `alias` are dispositioned.
- [ ] **TV-8** every mention of `opacity` sits with the
      `wallpaper-opacity` decision that settled it.
- [ ] **TV-9** the theme channel is routed to `09-theme-switcher`.
- [ ] **TV-10** the C/U/source header is a closed quotation naming
      `capabilities-nushell.md`.
- [ ] **TV-11** `07-quicklist/prd.md` names **L-4** next to `finder`.
- [ ] **TV-12** it records that every live entry carries channel `zoxide`,
      which is what makes replay unreachable.
- [ ] **TV-13** its header is a closed quotation naming the inventory.

## verify

```
bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh spec01
```

**Proved RED on 2026-08-21** against the current tree: `0/13 passed (13
FAILED)`. TV-13 is worth noting — `07-quicklist`'s header quotes *are*
balanced (`source: "Quicklist" in`), so a quote-balance test alone reads it as
fine; it is the dangling `in` with no inventory behind it that gives the
truncation away, which is why the check requires the link too.

The checks read the file with every whitespace run collapsed to one space, so
a phrase broken across the ~78-column wrap still matches; and they assert
*proximity of facts* (`rcwd` only near `L-3`) rather than literal sentences,
so a sibling lane rewording a line cannot make them stale.

## Spent assertion

**TV-8 is red and stays red.** As of 2026-08-23 this spec's gate runs
`12/13`: every check passes except

```
FAIL  TV-8  04-television/prd.md: S3: `opacity` appears only alongside the decision that settled it
      ↳ an occurrence of `opacity` at char 10464 has no `wallpaper-opacity` within 350 chars
```

The cause is a single occurrence at
`prds/04-shell/04-television/prd.md:199`, inside the section
`### Added 2026-08-23 by the orchestrator — a vacuous assertion in this gate`,
added by the orchestrator two days after this node closed. Its sentence reads
*"It is the same defect class as the `T.4` `opacity` box and R10's
`get_current_working_directory`"* — a citation of a **box named `opacity`**,
not of an opacity feature. The requirement TV-8 exists to guard (no opacity
picker is specced in `04-television`) still holds; the guard's subject — the
token anywhere in the file — is wider than what it means to check, which is
the same over-breadth that section is itself about.

TV-8 is therefore left exactly as written. Narrowing its predicate so this
node reads green would be proof manufactured to fit, and the occurrence that
trips it is already on the record at the line that causes it.
