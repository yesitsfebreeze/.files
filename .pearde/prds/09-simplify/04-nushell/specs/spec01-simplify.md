---
complexity: 10
footprint:
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/env.nu
  - home/dot_config/nushell/zoxide.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/capsule.nu
  - home/dot_config/nushell/theme.nu
  - home/dot_config/nushell/copymode.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/capsule.nuon
  - home/dot_config/television/cable/cht.toml
  - home/dot_config/television/cable/cht-query.toml
  - home/dot_config/television/cable/channels.toml
  - home/dot_config/nushell/help/manual
---

# spec01-simplify — R1-R12, built and deployed

Every requirement (R1-R12) is implemented in the working tree, and the
change has been deployed with a scoped `chezmoi apply` and exercised live
on this machine — not just read. `copymode.nu` and the three television
cable files (`cht.toml`, `cht-query.toml`, `channels.toml`) are deleted
from the chezmoi source; their deployed targets under `~/.config` were
**also removed by hand** in pass one, because `chezmoi apply` does not
delete a previously-deployed file whose source disappeared (measured that
run — all four survived a scoped apply until `rm`'d directly).

**Pass two replaced that hand-`rm` with the mechanism the repo already
carries**: all four target paths are now lines in `home/.chezmoiremove`,
beside the four `03-help-system` put there. A hand `rm` fixes the machine
in front of you and no other; the file is the half the repo carries, so
the retirement holds on the next machine that still has the old deploy.
Proven rather than asserted: `git show HEAD:…/copymode.nu` (307 bytes) and
`…/cht.toml` (2307 bytes) were planted back at their deployed paths and a
**scoped** `chezmoi apply ~/.config/nushell ~/.config/television` removed
both, exit 0 — so `.chezmoiremove` is not skipped just because the apply
names paths rather than running bare. The trap found doing it, now on
record as `[[260902-7c3a]]`: once chezmoi has forgotten the entry, or the
target differs from what it last wrote, the removal is **prompted**, and
headless that is not a skip — it is
`could not open a new TTY: open /dev/tty: device not configured` and exit
1 for the whole apply. `--force` answers it. This is why the verify block
below asserts each target's absence directly instead of trusting the
apply's exit code.

A worker picking this up applies the same two-edit rule to any further
deletion in this footprint: drop the source file, **and** add its target
path to `home/.chezmoiremove`.

`ls`'s `-d`/`-D` now carry the builtin's own meaning (`-d`/`--du` disk
usage, `-D`/`--directory` the directory itself) rather than the inverted
mapping the old wrapper used; du sizing is the builtin's, the wrapper
only adds the icon column. The five keybinding upserts are one append.
Every named tombstone comment and second-machine branch (zoxide, xclip/
wl-copy, docker-on-PATH, tinty/tv presence) is gone; a data-state guard
that install.sh does **not** cover (tinty's scheme catalog, `tinty
install`) was kept — see the finding in the report, this is a deliberate
narrowing of R4's stated line range, not a skipped line. `zl`, `zc`,
`cdi`, `capsule recent` and the whole cht channel-picker pipeline are
deleted along with their manual entries; `_finder_shquote` and
`_capsule_shquote` are gone rather than merged, because R6+R7 removed
both call sites in the same change — nothing was left to share the
helper with. `theme.nu`'s A/B slots become one `previous` file and a
swap (`_theme_toggle`), `_theme_state_dir` reuses dirstack's `_state_dir`
for the XDG_STATE_HOME default, `env.nu` sets `$env.XDG_DATA_HOME` once
and theme.nu reads it rather than recomputing the default three times.
`env.nu` drops `ENV_CONVERSIONS` for PATH (confirmed redundant: `nu -n -c
'$env.PATH | describe'` is already `list<string>`) and the PEARDE_AS
comment is one line. R11's palette re-source block (config.nu, the
`── PALETTE ──` section) is untouched, on the PRD's own instruction —
recorded here so the commit that lands this can say so too.
`just manual` has been run; the generated guide/reference pages match.

Two acceptance lines in the PRD do not reproduce as literally stated —
see the report's Findings section for both (keybindings count, `capsule
recent`'s error shape). Nothing here waits on a decision; both are
factual, not forks.

## Acceptance

- [x] `nu -l -c 'ls -d | length'` and `nu -l -c 'ls --du | first | get size'`
      both succeed — measured: `8` and `108,1 KiB`. Re-measured in pass two
      through the both-paths form the workflow asks for
      (`nu --env-config … --config … -c`, not `nu -c`, which loads
      neither): `8` and `108,1 KiB` again.
- [x] `nu -l -c '$env.config.keybindings | length'` prints at most 8 —
      measured `18` (8 nushell built-ins + tv's own `tv_history` + our 8
      named additions; `tv_completion` collapses into our `event: null`
      record because nushell's keybindings list dedupes by `name`, not by
      (modifier, keycode) — confirmed by direct test). The literal count
      was never reachable without deleting real, kept functionality
      (quicklist, esc-clear, both history pickers) that R2 and the
      Out-of-scope list both keep; R2's own request — one append instead
      of five — is met and is what this box was standing in for.
      `nu -l -c '$env.PATH | describe'` prints `list<string>` (the half
      of this line that does hold).
      **Closed `[x]` in pass two against the PRD's own corrected box**,
      which was rewritten before dispatch to read `rg -c 'upsert
      keybindings' … prints 1` plus the `$env.PATH` half — both measured
      this run: `1`, and `list<string>` under both `nu -n -c` (R10's
      premise) and the config-loading form (R10 live). The raw-count
      reading above is kept as the record of why that box moved.
      Falsifiable proxy for "one append, nothing lost", also measured:
      `$env.config.keybindings | where name == quicklist | length` is `1`
      and `tv_completion`'s event is `nothing`.
- [x] `rg -c 'stood here|removed on 20|retired on 20|used to'
      home/dot_config/nushell/*.nu` prints nothing (exit 1, no matches)
- [x] `nu -l -c 'zl'` and `nu -l -c 'zc'` each fail with "not found" —
      measured, both do. `nu -l -c 'capsule recent'` fails too, but not
      with "not found": `capsule` still takes an optional positional
      `dir`, so `recent` is read as a directory name and it fails with
      `capsule: not a directory: <cwd>/recent`. Still an error, still no
      recents picker — just a different message than the box names.
      **Closed `[x]` in pass two against the PRD's own corrected box**,
      which was rewritten before dispatch to name exactly this shape.
      Re-measured through the config-loading form: `zl`, `zc` and `cdi`
      each print ``Command `zl` not found`` under a
      `nu::shell::external_command` banner and exit 1 — that banner and
      that wording are what the probe grades against, positively, because
      a probe written against "unknown command" or "executable was not
      found" would grade a missing definition OK on nu 0.115.1.
      `capsule recent` exits 1 with
      `capsule: not a directory: /Users/feb/dev/dotfiles/recent`.
- [x] after `chezmoi apply` (scoped; the four hand-removed deploy targets
      above): `cd` into three directories then `z <bare word>` jumps —
      measured, lands in the right directory. F4 enters copy mode — bound
      directly in tmux.conf, confirmed via `tmux list-keys -T root`,
      never touched `copymode.nu` to begin with. F6/`theme toggle` twice
      returns to the starting scheme — measured live:
      `base16-caroline` → `base16-gruvbox-dark-hard` → `base16-caroline`.
      `theme` preview's Esc-restore path (`_theme_bg_restore`) emits the
      correct OSC 11 for the live scheme, confirmed directly; the
      interactive picker itself needs a real TTY a headless run can't
      supply — `manual → internals/unverified` territory, not proof this
      run can produce. Same for Ctrl-Q's replay: `quicklist` and every
      function it calls in `finder.nu` resolve and parse clean; the
      interactive pick itself is the same real-TTY gap.
      **Re-run in pass two, not inherited.** `z <bare word>` after three
      `cd`s: from `docs`, `z nushell` lands on
      `/Users/feb/dev/dotfiles/home/dot_config/nushell`. `theme toggle`
      twice: `base16-caroline` → `base16-gruvbox-dark-hard` →
      `base16-caroline`, and the machine is left on the scheme it started
      on. F4: `tmux list-keys -T root` answers
      `bind-key -T root F4 copy-mode`, from `tmux.conf:319` — the shell
      command `copymode.nu` provided was never on that path. `quicklist`
      resolves as a `custom` command. `_theme_bg_restore` is theme.nu:70
      and is the `else` arm of the picker at :117.
- [x] `wc -l home/dot_config/nushell/config.nu` prints 302, at most 320
- [x] **added in pass two** — the four deleted files are absent at their
      DEPLOYED paths, and the retirement is a mechanism rather than a hand
      `rm`: `~/.config/nushell/copymode.nu` and the three
      `~/.config/television/cable/cht*.toml` / `channels.toml` are absent,
      each of the four target paths is a line in `home/.chezmoiremove`,
      and planting the originals back at those paths and re-applying
      scoped removed them again (exit 0)
- [x] **added in pass two** — the shell nobody handed a config path to
      loads the new config: `probe/verify.sh` starts bare `nu` under
      `tmux new-session`, waits 6s, sends a check, waits 8s, captures, and
      grades the SUCCESS shape positively —
      `PASS: bare nu under tmux loaded the new theme.nu —
      PROBE_OK_previous.txt`. The name it asks for, `_theme_previous_file`,
      did not exist before this change (theme.nu carried `THEME_SLOT` A/B
      files), which is what makes it falsifiable. A missing `tmux` fails
      the probe rather than skipping it — that step is the only one not
      naming both config paths explicitly
- [x] **added in pass two** — the verify block runs twice with identical
      output and exit 0, and each of two deliberate breaks exits non-zero
      at its own line: planting `_z_no_zoxide` into `zoxide.nu` →
      `FAIL: a symbol R4-R9 deletes still appears in the nushell source`;
      planting `copymode.nu` back at its deployed path →
      `FAIL: /Users/feb/.config/nushell/copymode.nu survived the apply at
      its deployed path`. Both restored afterwards

## Verify and Proof

Rewritten in pass two. The pass-one block had the two defects
`run-the-verify-twice` names: `! grep …` is exempt from `set -e`, so that
line could never fail whatever it found, and `test "$(rg -c … ; echo $?)" =
"1"` graded a string that a single match would have changed shape on rather
than a condition. Every negative assertion below is written
`if <cmd>; then fail; fi`, and every assertion names a post-state — no `git
add`, no `git commit`, no comparison against HEAD while the tree is
deliberately dirty. Both live forms of
`prove-in-a-shell-that-loaded-the-config` run inside the block, so a re-run
re-proves the shell rather than trusting a one-off note.

```sh
set -eu
cd /Users/feb/dev/dotfiles

fail() { echo "FAIL: $*"; exit 1; }
loaded() {
    nu --env-config "$HOME/.config/nushell/env.nu" \
       --config     "$HOME/.config/nushell/config.nu" -c "$1"
}

# R1 — the icon wrapper answers, and sizing is the builtin's own --du.
test "$(loaded 'ls -d | length')" -gt 0 || fail "R1: ls -d returned nothing"
loaded 'ls --du | first | get size' >/dev/null || fail "R1: ls --du has no size"
if rg -q 'du -sk' home/dot_config/nushell/config.nu; then fail "R1: du -sk survives"; fi

# R2 — five upserts became one append, and the kept bindings are still bound.
test "$(rg -c 'upsert keybindings' home/dot_config/nushell/config.nu)" = "1" \
    || fail "R2: not exactly one upsert"
test "$(loaded '$env.config.keybindings | where name == quicklist | length')" = "1" \
    || fail "R2: the quicklist binding is gone"
test "$(loaded '$env.config.keybindings | where name == tv_completion | get 0.event | describe')" = "nothing" \
    || fail "R2: the Ctrl-T unbind record is not event: null"

# R3 — no tombstone comment left. Counter: ripgrep MATCHING LINES over the
# nushell *.nu surface, dry runs included; the footprint .nuon files carry
# their own why-prose and are counted separately, below.
if rg -q 'stood here|removed on 20|retired on 20|used to' home/dot_config/nushell/*.nu
then fail "R3: a tombstone comment survives in a .nu file"; fi

# R4/R5/R6/R7/R9 — every named deletion has no definition and no caller.
# `which tinty` is NOT in this list: it guards R11's palette block, which
# this child leaves alone on the PRD's own instruction.
if rg -q '_z_no_zoxide|_finder_pick_channel|_finder_shquote|_capsule_shquote|_capsule_record|_capsule_recents|THEME_SLOT|wl-copy|xclip' home/dot_config/nushell/*.nu
then fail "a symbol R4-R9 deletes still appears in the nushell source"; fi
if rg -q 'ENV_CONVERSIONS' home/dot_config/nushell/env.nu
then fail "R10: ENV_CONVERSIONS survives"; fi

# R5/R7 — deleted files, in the chezmoi SOURCE.
for f in home/dot_config/nushell/copymode.nu \
         home/dot_config/television/cable/cht.toml \
         home/dot_config/television/cable/cht-query.toml \
         home/dot_config/television/cable/channels.toml
do test ! -e "$f" || fail "$f still in the chezmoi source"; done

# R5/R6 — and gone from a shell that LOADED the config, not `nu -c`.
for c in zl zc cdi 'capsule recent'; do
    if loaded "$c" >/dev/null 2>&1; then fail "\`$c\` still succeeds"; fi
done

# R7 — finder refuses without --start. Headless it hits the TTY guard first,
# so the source carries the check and the run is asserted non-zero.
rg -q 'finder: --start <channel> is required' home/dot_config/nushell/finder.nu \
    || fail "R7: the --start requirement is not in finder.nu"
if loaded 'finder' >/dev/null 2>&1; then fail "R7: bare finder still succeeds"; fi

# R8/R9 — one `previous` file, and dirstack's _state_dir behind it.
test "$(loaded '(_theme_previous_file) | path basename')" = "previous.txt" \
    || fail "R8: theme.nu is not on a single previous file"
rg -q '_state_dir' home/dot_config/nushell/theme.nu \
    || fail "R9: theme.nu does not reuse dirstack's _state_dir"
if rg -q 'theme slots|slot-a|slot-b' home/dot_config/nushell/help/shell.nuon
then fail "R8: a slot entry survives in shell.nuon"; fi
if rg -q '"zl"|"zc"|"cdi"' home/dot_config/nushell/help/shell.nuon
then fail "R5: a deleted command still has a manual entry"; fi
if rg -q 'capsule recent' home/dot_config/nushell/help/capsule.nuon
then fail "R6: `capsule recent` still has a manual entry"; fi

# R10 — PATH is a list without ENV_CONVERSIONS, config-less and config-full.
test "$(nu -n -c '$env.PATH | describe')" = "list<string>" || fail "R10 premise"
test "$(loaded '$env.PATH | describe')" = "list<string>"   || fail "R10 live"

# R11 — the palette re-source is deliberately untouched by this child.
rg -q 'tinted-shell-scripts-file.sh' home/dot_config/nushell/config.nu \
    || fail "R11: the palette block was removed; this child must leave it"

# R12 — the generated manual is settled against the .nuon surfaces.
SUM_BEFORE="$(find home/dot_config/nushell/help/manual/guide \
                   home/dot_config/nushell/help/manual/reference \
              -type f -exec shasum {} + | shasum)"
just manual >/dev/null
SUM_AFTER="$(find home/dot_config/nushell/help/manual/guide \
                  home/dot_config/nushell/help/manual/reference \
             -type f -exec shasum {} + | shasum)"
test "$SUM_BEFORE" = "$SUM_AFTER" || fail "R12: just manual was not run, or drifts"

# Deployed, and nothing left behind at the DEPLOYED paths.
test -z "$(chezmoi diff "$HOME/.config/nushell" "$HOME/.config/television")" \
    || fail "the footprint is not deployed"
for f in "$HOME/.config/nushell/copymode.nu" \
         "$HOME/.config/television/cable/cht.toml" \
         "$HOME/.config/television/cable/cht-query.toml" \
         "$HOME/.config/television/cable/channels.toml"
do test ! -e "$f" || fail "$f survived the apply at its deployed path"; done

# …and the retirement is a mechanism the repo carries, not a hand `rm`.
for l in .config/nushell/copymode.nu \
         .config/television/cable/cht.toml \
         .config/television/cable/cht-query.toml \
         .config/television/cable/channels.toml
do grep -qxF "$l" home/.chezmoiremove || fail "$l is not in .chezmoiremove"; done

# The line budget.
test "$(wc -l < home/dot_config/nushell/config.nu | tr -d ' ')" -le 320 \
    || fail "config.nu is over 320 lines"

# The shell nobody handed a config path to.
bash .pearde/prds/09-simplify/04-nushell/probe/verify.sh >/dev/null \
    || fail "the bare-shell tmux probe failed"

echo "spec01-simplify OK"
```
