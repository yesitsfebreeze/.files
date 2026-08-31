---
est: 0.75h
footprint:
  - home/dot_config/nushell/capsule.nu
---

# spec01 — `capsule recent`, the picker over the recents store

Add the recents picker to `capsule.nu` as one more subcommand of the one CLI:
`capsule recent` prunes the store, opens a television ad-hoc channel over it,
and hands the pick straight back to `capsule`. R1 (recording) already landed
with C.2 — `_capsule_record` writes `~/.cache/capsule/recents.nuon` at step 11
of `capsule`, deduplicated, capped at 20, most recent first. Nothing about
recording changes here. This spec is R2, R3 and R4 only.

## Design

Three helpers next to `_capsule_record` (before `def capsule`), one subcommand
after `def "capsule clean"`. Parse order matters: `tests/capsule-lifecycle.sh`
asserts C.2's ten defs in relative order, and new defs interleaved between
them keep that true.

**Two file-wide constraints, both enforced by C.2's gate over this same
file.** `c3_ok` greps `capsule.nu` for the word `cd` (`grep -cwE`, comments
included) and for the string `just ` and requires zero of each. New code and
new comments must contain neither word. A comment is not exempt.

### The helpers

```nu
# ── the recents picker (01-capsule/04, task C.4) ────────────────────────────
#
# THE PICKER IS A TELEVISION AD-HOC CHANNEL, NOT A HAND-ROLLED TUI. 04-shell's
# invariant I3 gives every picker screen to tv and names exactly one exception
# (fzf behind `zi`), so a second hand-rolled picker would be a new decision.
# Ad-hoc (`^tv --source-command …`, no channel argument) rather than a cable
# file, because a cable file would put a capsule surface inside
# ~/.config/television, which 04-shell/04 owns.
#
# EVERY TV CALL GOES THROUGH `^tv`, for the same reason every docker call goes
# through `^docker`: a PATH shim can then observe it, so
# tests/capsule-recents.sh drives the real picker path against a recording
# shim and never needs a terminal.

# _capsule_recents_read (R4): the store, pruned on read. A directory that no
# longer exists is dropped AND the pruned list is written back, so a dead
# entry leaves the picker for good instead of being filtered on every open.
# The write-back is non-fatal, like _capsule_record's: a store that cannot be
# rewritten must still be pickable.
def _capsule_recents_read [] {
    let f = (_capsule_recents)
    if not ($f | path exists) { return [] }
    let stored = (try { open $f } catch { [] })
    let live = ($stored | where {|d| ($d | path type) == "dir" })
    if $live != $stored {
        try { $live | save -f $f } catch {
            print -e "capsule: could not prune the recents store (non-fatal)"
        }
    }
    $live
}

# _capsule_shquote: POSIX single-quote one path for the source command tv
# runs through sh — everything inside '' is literal, and an embedded quote is
# closed, escaped and reopened. A LOCAL helper and not finder.nu's: this file
# parses standalone under `nu -n` and the gate sources it directly, so no def
# here may belong to another module.
def _capsule_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

# _capsule_recents_pick (R2, R3): the picker screen. Returns the chosen
# directory, or "" when the pick was aborted.
#
# The flag set, every flag load-bearing, measured against television 0.15.9 on
# 2026-08-23:
#   --input-header "Recent"  is R3's mode feedback, and the picker surface is
#       its host because the WezTerm status bar is clock-only and
#       set_left_status is never called (finding C-5). tv defaults this title
#       to the channel name, which for an ad-hoc channel says nothing.
#   --no-sort  keeps the source order, and the source order IS the recency
#       order (R1: most recent first). Without it tv reorders by match
#       quality and the newest entry is no longer on top.
#   --keybindings 'enter="confirm_selection"'  confirms the pick whatever
#       ~/.config/television/config.toml binds — that file belongs to
#       04-shell/04, and an ad-hoc channel has no prototype of its own to
#       carry the binding. The grammar is key="action" and tv validates it
#       eagerly: the inverse config-file form `confirm_selection = "enter"`
#       exits 1 with `Error parsing CLI arguments`, so a typo is loud rather
#       than silent.
#   --no-preview  a list of directories has nothing to preview.
def _capsule_recents_pick [dirs: list] {
    let src = $"printf '%s\\n' ($dirs | each {|d| _capsule_shquote $d } | str join ' ')"
    let raw = (try {
        ^tv --source-command $src --input-header "Recent" --no-sort --no-preview --keybindings 'enter="confirm_selection"'
    } catch { "" })
    $raw | lines | where {|l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}
```

### The subcommand

```nu
# capsule recent (R2): pick a recently mounted directory and mount it. The
# pick funnels straight back into `capsule`, so there is exactly one mount
# path (the epic's one-entry-path acceptance) and this def knows nothing
# about images, names or containers.
#
# THE TTY GUARD IS $nu.is-interactive, and it fails FIRST. tv has no headless
# mode: run without a terminal it aborts with "television had a problem and
# crashed" and writes a crash report (measured 0.15.9, 2026-08-23), so the
# clean error has to come before the call. Ctrl+Shift+O reaches this def
# through `nu --execute`, where $nu.is-interactive is TRUE — measured on
# nushell 0.114.1, 2026-08-23; it is false under `-c`, which is why the
# hermetic gate drives the helpers rather than this def.
def "capsule recent" [] {
    if not $nu.is-interactive {
        error make {msg: "capsule recent: interactive-only — tv needs a TTY"}
    }
    if (which tv | is-empty) {
        error make {msg: "capsule recent: `tv` (television) is not installed — the picker needs it"}
    }
    let dirs = (_capsule_recents_read)
    if ($dirs | is-empty) {
        print "capsule recent: no recent workspaces yet — mount one with `capsule`"
        return
    }
    let picked = (_capsule_recents_pick $dirs)
    if ($picked | is-empty) { return }
    capsule $picked
}
```

### Out of this spec

- The store's format, cap, dedup and write site. C.2 landed them.
- A `--tab` flag. The new-tab variant is a WezTerm spawn (spec02), so the
  shell side has one code path and no idea which key called it.
- Help entries. `06-help/01-content-model/coverage` R4 owns the capsule CLI
  surface, the recents picker named explicitly.

## Acceptance

- [x] `capsule.nu` parses standalone: `nu -n -c "source …/capsule.nu"` under
      an isolated `HOME` exits 0.
- [x] `_capsule_recents_read` over a store of three directories, one of them
      deleted, returns the two live ones in stored order and rewrites the
      file on disk to those two.
- [x] `_capsule_recents_read` with no store file returns an empty list and
      creates no file.
- [x] `_capsule_recents_pick` against a recording `tv` shim first on PATH
      logs exactly one invocation carrying `--input-header Recent`,
      `--no-sort`, `--no-preview` and `--keybindings enter="confirm_selection"`,
      and returns the line the shim printed.
- [x] Running the source command the shim recorded through `sh -c` emits the
      directories one per line, in the store's order, and a directory whose
      name contains a space and a single quote comes back byte-identical.
- [x] `capsule recent` under `nu -c` (non-interactive) exits non-zero with
      `interactive-only`, and the `tv` shim log is empty — the guard fires
      before the call.
- [x] `/usr/bin/grep -cwE 'cd' capsule.nu` and `grep -cF 'just ' capsule.nu`
      are both 0, and `bash tests/capsule-lifecycle.sh --tree` still passes —
      C.2's checks over this file are not disturbed.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
CAP=home/dot_config/nushell/capsule.nu
M=$(mktemp -d); mkdir -p "$M/home/.cache/capsule" "$M/bin" "$M/a" "$M/b"
printf '["%s", "%s", "%s"]' "$M/a" "$M/gone" "$M/b" > "$M/home/.cache/capsule/recents.nuon"
cat > "$M/bin/tv" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$TVLOG"
sh -c "$2" | sed -n 2p
SH
chmod +x "$M/bin/tv"

# parse + prune + pick, all under an isolated HOME and a shim-only PATH
/usr/bin/env -i HOME="$M/home" PATH="$M/bin:/opt/homebrew/bin:/usr/bin:/bin" \
  TVLOG="$M/tv.log" nu -n --no-history \
  -c "source $PWD/$CAP; print (_capsule_recents_read); print (_capsule_recents_pick (_capsule_recents_read))"
echo "--- store after prune:"; cat "$M/home/.cache/capsule/recents.nuon"
echo "--- tv argv:"; cat "$M/tv.log"

# The guard fires before tv.
#
# `capsule recent` is EXPECTED to exit non-zero here — that is the assertion.
# The runner executes these blocks under `set -e -o pipefail` (reproduced
# 2026-08-29: the same block is rc 0 under plain bash and rc 1 under
# `bash -e -o pipefail`, which is what `pearde collect` reported), so the
# expected failure has to be caught rather than left to abort the block. An
# `if` that fails when the command SUCCEEDS is the honest shape: it says the
# guard not firing is the defect.
: > "$M/tv.log"
if /usr/bin/env -i HOME="$M/home" PATH="$M/bin:/opt/homebrew/bin:/usr/bin:/bin" \
     TVLOG="$M/tv.log" nu -n --no-history \
     -c "source $PWD/$CAP; capsule recent" > "$M/guard.out" 2>&1
then
  echo "GUARD DID NOT FIRE — capsule recent succeeded without a TTY"; false
fi
head -3 "$M/guard.out"
echo "--- tv argv after the guard (must be empty):"; cat "$M/tv.log"
test ! -s "$M/tv.log"

# C.2's file-wide constraints and its own gate.
#
# Each count is wrapped in `test`, and that is not decoration. `grep -c`
# EXITS 1 WHEN THE COUNT IS ZERO — which is the correct answer for all three —
# so the block used to end on a non-zero status while every assertion in it
# held, and `pearde collect` refused the node on it (measured 2026-08-29).
# The exit code was reporting "grep found nothing", not "the check failed".
# Wrapped, the printed number stays visible and the STATUS says what the block
# actually decided.
# `|| true` on every count: the assignment and the substitution INHERIT the
# pipeline's status under `set -e`, and grep exits 1 on the zero we want.
cd_n="$(/usr/bin/grep -cwE 'cd' "$CAP" || true)"
just_n="$(/usr/bin/grep -cF 'just ' "$CAP" || true)"
fail_n="$(bash tests/capsule-lifecycle.sh --tree | /usr/bin/grep -c '^FAIL' || true)"
echo "cd count:   $cd_n"
echo "just count: $just_n"
echo "FAIL count: $fail_n"
test "$cd_n" = 0 && test "$just_n" = 0 && test "$fail_n" = 0
```
