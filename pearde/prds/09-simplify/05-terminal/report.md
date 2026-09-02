Verdict: BLOCKED

# 09-simplify/05-terminal — implementer

R1 is built and closed: `tmux.conf` is **278 lines, 138 comment against 140
non-comment**, from 535/379/156. Every code line is byte-identical to what
the analyst left — `diff` over the comment-stripped file is empty, 102 lines
both sides — so the cut moved no behaviour, and both key probes agree.

15 of 17 spec boxes are ticked. Two walls stop the last four, and neither is
something I can pass without a decision that is not mine.

**Wall 1 — `copy.md`'s "widen" sentence is generated from a file no spec
names.** spec02's fourth box wants `manual/guide/copy.md` free of "widen".
The line survives at `copy.md:7` and it is *generated*: its source is
`home/dot_config/nushell/help/tasks.nuon:50`, the `copy` task's `intro`,
which is in **no spec's footprint and not in the PRD's footprint either**.
Editing `copy.md` directly cannot work — spec02's own third box requires
`just manual` to leave no diff, so the generator would put the sentence
straight back. The same sentence is stale twice over: it also says the text
"travels out as OSC 52", which R5 deleted.

> The question: may `home/dot_config/nushell/help/tasks.nuon` be added to
> this PRD's footprint? It is a one-line edit to that `intro`. I have not
> made it.

**Wall 2 — three boxes are colour and mouse, and no harness renders either.**
`F6 retints two attached windows and a pane opened after the toggle`,
`drag-select then pbpaste`, and `a fresh WezTerm window attaches to main,
shift-click opens a URL`. I proved everything mechanical underneath them (see
below) but the assertions themselves are things a person sees. They need one
minute at the desk.

The deploy is done and live, so that minute is available now: `chezmoi apply`
ran scoped, `~/.config/tmux/tmux.conf` `cmp`s clean against source, and
`tmux source ~/.config/tmux/tmux.conf` returned 0 on the running `main`
session (4 windows, attached).

## What I built, and what it measures

| | before | after |
|---|---|---|
| `tmux.conf` total | 535 | **278** (box: at most 280) |
| comment / non-comment | 379 / 156 | **138 / 140** (box: comment below non-comment) |
| code lines | 102 | 102, byte-identical |
| `list-keys -T jump` | 27 | 27 |

Every essay is now one line naming the trap and pointing at
`manual/internals/tmux.md`. **14 distinct section names are cited and all 14
resolve** to a real header in that file — checked by flattening the wrapped
comment lines first, because eight of the pointers wrap and a naive
line-by-line grep misses them. Nothing that recorded a measurement was
dropped: every TRAP in the old file survives as a TRAP in the new one, and
the three blocks R1 exempts (`@cwd`, the copy sink, the dimming pair) keep
their notes rather than becoming bare pointers — compressed, not deleted,
because the manual holds each one's long form verbatim and 1:1.

The one comment I rewrote rather than shortened is R3's, for the reason in
the analyst's finding — see **Two mistakes still in `prd.md`** below.

## The key half, proved on a real attached client

`probe/keys-verify.py` is new, and it is the reason spec03's third box is
ticked rather than deferred to the desk with the others. Same shape as
`f3-verify.py`: `pty.fork()` a client, write the real escape bytes, and read
the result out of **tmux's own state** (`display-message -p "#{…}"`) rather
than off the screen. Two runs, identical output, exit 0 both times:

```
keys — F5 / F6 / F4 on an attached client (tty /dev/ttys011)
  ok   a client is really attached   /dev/ttys011
  ok   F5 arms the jump table
  ok   F5 2 lands on window 2   window_index=2
  ok   F5 1 goes back to window 1   window_index=1
  ok   F5 Right splits the window   1 -> 2
  ok     the split inherited the cwd   pane_start_path=/tmp/keyprobe-cwd
  ok   F5 a selects pane 1   pane_index=1
  ok   F5 b selects pane 2   pane_index=2
  ok   F5 Escape returns to the root table
  ok   F4 enters copy mode
  ok     q leaves it
  ok   F6 dispatches its run-shell
  ok   the pane-letter border chip is still the format   #[align=right]…
  ok     and the border is shown on a split window   panes=2 pane-border-status=top
KEYS OK
```

`f3-verify.py` also passes twice against the cut file, exit 0 both times, so
the comment cut moved no binding.

What that leaves for the desk is narrow and worth naming precisely: F6
**dispatches** — proven — and what is unproven is only whether the colours
change, which a pty has no renderer for.

## Two mistakes still in `prd.md`

Both were flagged by the analyst and both are still in the requirement text.
I built to the specs and did not edit either sentence.

1. **R3 says "`v`, `V` and `viw` are the built-ins". Two of three are wrong.**
   Re-measured on a loaded server this pass: `v` is `rectangle-toggle`,
   `Space` is `begin-selection`, and tmux has no `viw` at all. So the `c`
   cycle's deletion leaves **no keyboard word-select** — `w`/`b` move by word
   but taking one needs `Space` plus a motion, and the one-key way to take a
   word is the mouse double-click. The R3 sentence in the PRD is unchanged.
   The *comment* I wrote into `tmux.conf` says what is true, marked TRAP for
   the next reader, and `terminal.nuon`'s F4 and `copymode` entries now
   describe the keys the server actually binds.

2. **spec03's third box says "F4 then an arrow splits".** F4 is copy-mode;
   it is **F5** that arms the table the arrows live in. I read it as F5 and
   the probe drives F5 — F4 is separately covered (it enters copy mode, `q`
   leaves).

R4-vs-R5 on the ssh host: the analyst's third finding stands and I confirmed
the resolution in the file — one unconditional `set -g @host ''` plus a
single-armed `if-shell` on `SSH_CONNECTION`. Both requirements are satisfied
as written; the contradiction is only in the prose.

## A defect outside my scope

`manual/internals/tmux.md:401` still carries a whole section, **"The cycle's
anchor, and why it is an option"**, documenting the `c` widen cycle and its
`@copy-cycle` option — machinery R3 deleted. `internals/` is hand-written, so
`just manual` will never touch it, and it is in no footprint on this board.
Reported, not fixed. It belongs with Wall 1's decision: both are the same
cut's documentation tail.

Separately, `CLAUDE.md` tells agents that "`help --check` reports it
undocumented". There is no `--check` flag on `help` — `nu -c 'help --check'`
fails with `unknown_flag`, with the repo's own config loaded. The live gate
is `just board-guard-blocks` (which runs `board-guard.py requirements`).
`CLAUDE.md` is in no footprint; not touched.

## Health floor

`home/dot_local/bin/executable_tv-all` (28, longest, branching) is in the
PRD's footprint but in **no spec's**. Its requirement R7 is done and verified,
and nothing this pass writes it. Nothing moved, because touching it would be
a refactor outside the spec's scope with no box asking for it. It sits at 499
lines against the 500 box, so it has no headroom either — worth its own node
rather than a drive-by.

## Verify and Proof — every block run twice

**spec01** — exit 0, identical output both runs. Falsifiability checked: five
`# pad` lines appended to a copy makes `test "$(wc -l < $f)" -le 280` exit 1
at that line, so the assertion grades a condition rather than a shape.

**spec02** — three of four. `terminal.nuon` is clean of `widen|widening|each
further .c.`; a loaded server binds no `c` in `copy-mode-vi`; `just manual`
exits 0 and a second run leaves `diff -r` empty against a snapshot of the
first. Fourth box is Wall 1.

**spec03** — four of seven. `tv-all` 499 at most 500; `chezmoi apply
--dry-run` then `apply`, scoped to the five paths, both exit 0 and `cmp` is
clean on `tmux.conf`, `tv-all` and `wezterm.lua`; F3/Escape/query via
`f3-verify.py`; F5/F4 via `keys-verify.py`. Three boxes are Wall 2.

**Repo gate** — `just board-guard 09-simplify/05-terminal "<my four paths>"`
exits 0, and `just board-guard-blocks` exits 0.

`R10`'s remaining half: `config.nu`'s re-assert block is out and the
four-line reason is in its place (`config.nu:252`). The mechanical half of
its claim holds — `tmux-colors.sh`'s `osc_push` targets `#{client_tty}`, and
every pane of a client shares that one tty, so the palette is terminal-wide
rather than per-shell and a new pane inherits it with no shell doing
anything. The half I cannot answer is whether the pane *looks* right, which
is Wall 2's F6 box. R10 is left unticked for that reason.

## Workflow prove-a-key-binding-on-a-real-client

First run of this workflow. `runs: 0` before this.

| # | atomic | outcome | note |
|---|--------|---------|------|
| 1 | `measure-the-premise-not-the-prd` | **pass** | Hit its own first `Fails when` immediately: every premise had already been acted on by the analyst, so the commands measured the survivor. Recorded the counter beside each number (`wc -l`, `grep -cE '^\s*#'` vs `grep -cvE`, `list-keys -T jump \| wc -l`) — which mattered, because comment/non-comment counts blank lines as non-comment and two honest counters differ by 39 on that alone. |
| 2 | `drive-the-surface-on-a-real-client` | **pass, after one failure the atomic does not warn about** | See Edits. Cost one full probe run reading as five broken key bindings. |
| 3 | `bisect-which-command-expands-the-format` | **not entered** | The `-e` defect it exists for was found and fixed by the analyst's pass; `f3-verify.py` re-proves the fix end to end from the config file, which is step 4's Done-when, so there was no expander left to name. No back-edge taken. |
| 4 | `respell-the-proven-fix-in-the-config-file` | **pass by carry** | The `{}`-block spelling is in `tmux.conf` and dispatches when loaded with `-f`, twice. No new candidate needed respelling this pass. |
| 5 | `carry-the-why-across-the-rewrite` | **pass, with a gap** | Its step 3 (grep the rewritten file for each constraint's phrase) is the weaker check; what actually caught something was greping the *manual* for every section the new file names — one pointer was abbreviated to "is the scheme" against a real header of "is the whole scheme". See Edits. |
| 6 | `run-the-verify-twice` | **pass, and it earned its place** | Its step 2 named a live defect: spec03's block asserts `! grep -nE 'base24\|…'` under `set -e`, which reports nothing whatever it finds. Rewritten as a conditional it *does* fail — on two comment lines. See Edits. |

### Edits

**`drive-the-surface-on-a-real-client` — add to `## Fails when`:**

> - The probe writes the wrong escape sequence for a function key above F4,
>   and every assertion after it fails silently, reading exactly like a
>   broken binding on a correct config. **F1-F4 are SS3 (`\x1bOP`, `\x1bOQ`,
>   `\x1bOR`, `\x1bOS`) and the run STOPS there — there is no `\x1bOT`.** F5
>   and up are CSI tilde forms: F5 `\x1b[15~`, F6 `\x1b[17~`, F7 `\x1b[18~`.
>   Measured 2026-09-02: `\x1bOT` for F5 produced five FAILs against a config
>   that was right. Assert the side effect of the *first* key —
>   `display-message -p "#{client_key_table}"` changed — before trusting any
>   later assertion in the same run.

**`drive-the-surface-on-a-real-client` — add to `## Do`, after step 3:**

> 4. Prefer tmux's own state to a touched file where the binding changes
>    state rather than running a command: `display-message -p "#{window_index}"`,
>    `"#{pane_index}"`, `"#{pane_in_mode}"`, `"#{client_key_table}"`. A file
>    only reports *that* something ran; these report *what it did*, and they
>    need no stub on `PATH`. Read a window option with `show-options -wv`,
>    not `-gwv`, when a hook sets it per window — the global is still the
>    default and grades nothing. (That mis-read cost one run here.)

**`carry-the-why-across-the-rewrite` — replace `## Do` step 3:**

> 3. Grep the rewritten file for each constraint's distinguishing phrase.
>    Then, if the cut replaced essays with pointers, extract every section
>    name the new file cites and check each one exists in the target
>    document — flattening wrapped comment lines first, or every pointer that
>    wraps is invisible to the grep. A pointer abbreviated in the rewrite
>    ("is the scheme" for "is the whole scheme") is a dead link that no
>    line-count box will ever catch.

**`carry-the-why-across-the-rewrite` — add to `## Fails when`:**

> - The constraint is recorded as *removed* — the form this atomic asks for —
>   and a spec's verify block greps for the very word the record has to use.
>   Here, "a hand-rolled `c` cycle that widened the selection … was retired"
>   is exactly the line the atomic wants and exactly what `! grep -nE
>   'widen'` forbids. Rephrase the record in the past tense without the
>   forbidden token before concluding the record must go; do not delete it.

**`run-the-verify-twice` — add to `## Fails when`:**

> - The block's negative assertions are `! grep`, so the run is green and
>   graded nothing. Rewriting them as `if cmd; then echo FAIL; exit 1; fi`
>   is the fix the Do step names — but expect the rewrite to fail on
>   *comments*, not code, when the same change was supposed to leave a line
>   saying the mechanism was removed. Scope the grep to code
>   (`grep -vE '^\s*#' <file> | grep -E …`) or the two atomics contradict
>   each other.

### Spec verify blocks that need the same fix

Not edited by me — reported, per the contract.

- `spec02.md` and `spec03.md` both use `! grep …` under `set -eu`. Neither
  can fail. Each should be `if grep …; then echo FAIL; exit 1; fi`.
- `spec03.md`'s `! grep -nE 'base24|display-panes-|@scheme|colors\.lua'
  executable_tmux-colors.sh` fails once made real, on two **comment** lines:
  `:2` names the input format the script genuinely reads ("the active tinty
  base16/base24 scheme"), and `:50` is the one-line record that the base24
  brights were removed. Scoped to code it passes cleanly — I ran
  `grep -vE '^\s*#' <file> | grep -nE '…'` and it returns nothing.

## Grammar

No word I needed was missing from `grammar.py show`.

## Knowledge written back

`[[260902-aeff]]` — "Function-key escape sequences: SS3 stops at F4, F5 and
up are CSI tilde", with the measurement and the probe-design rule it implies.

## Footprint touched

```
home/dot_config/tmux/tmux.conf                              rewritten, 535 → 278
home/dot_config/nushell/help/terminal.nuon                  3 entries rewritten
home/dot_config/nushell/help/manual/guide/copy.md           regenerated
.pearde/prds/09-simplify/05-terminal/probe/keys-verify.py   new
.pearde/prds/09-simplify/05-terminal/{prd,report}.md, specs/ boxes
```

`manual/guide/containers.md` and `manual/reference/containers.md` also carry a
`just manual` diff — they were **already modified in the tree before this
pass** (another node's `.nuon` edit) and `just manual` regenerates every page.
Not mine; left alone. `AGENTS.md` and the untracked `.pearde/workflows/*.md`
untouched. Nothing committed.
