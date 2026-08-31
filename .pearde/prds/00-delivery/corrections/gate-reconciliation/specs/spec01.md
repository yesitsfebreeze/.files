# spec01 — R1: re-express the optional-import assertion as a scratch probe

Covers **R1** and R1's half of **R3**. Est 30m.

## Goal

`tests/deploy-skeleton.sh:212-213` proves the root justfile's
`import? 'gates/justfile'` is genuinely optional — a fresh clone with no
`gates/` must still work. It proved it by asserting `gates/justfile` is
**absent**. `verification-gates` (G.1) then created that file, correctly, so
the assertion now fails on another node's success and can never run again.

The property is still worth checking. Re-express it against a scratch copy of
the justfile with `gates/` removed, and add the negative half that the old
form never had: with the same `gates/` absent, a **non-optional** `import`
must go red. That is R3 satisfied in-line — the goalpost moved rather than
being deleted, and the new form is strictly stronger, because the old one
only ever asserted that a file was missing.

## Files touched

- `tests/deploy-skeleton.sh` — lines 212-213 only, inside `stage_push()`.
  Line 211 (`import? 'gates/justfile'` is present in the root justfile) stays
  exactly as it is; it is the companion assertion and still passes.

Touch nothing else in that file. Do not touch `install.sh` or
`tests/provisioning.sh` — another agent owns both right now.

## Design, already proven

Prototyped end to end in a scratch dir on 2026-08-21. No chezmoi, no git, no
network — `just --list` does not evaluate recipe bodies, so `justfile_directory()`
and the `repo :=` assignment are irrelevant to the probe:

| probe | result |
|---|---|
| copy of the root justfile, `import?`, no `gates/` beside it | `just -f … --list` exit **0** |
| same copy with `import?` rewritten to `import`, no `gates/` | exit **1** |
| `import?` copy with a `gates/justfile` restored beside it | the imported recipe appears in `--list` |

Sketch — mirror the file's existing local-variable and `chk` style:

    # The import must stay OPTIONAL: a fresh clone with no gates/ has to work.
    # G.1 created gates/justfile, so this can no longer be checked in place;
    # it is checked against a copy with gates/ removed. The negative half is
    # what makes it a check rather than a formality.
    local IP; IP="$(mktemp -d "${TMPDIR:-/tmp}/p1-import.XXXXXX")"
    mkdir -p "$IP/optional" "$IP/required"
    cp "$REPO/justfile" "$IP/optional/justfile"
    sed "s/^import? 'gates\/justfile'/import 'gates\/justfile'/" \
        "$REPO/justfile" > "$IP/required/justfile"
    grep -q "import? 'gates/justfile'" "$IP/optional/justfile"
    chk "push: optional import — the probe copy still carries the import? line" $?
    [ ! -e "$IP/optional/gates" ] && "$JUST" -f "$IP/optional/justfile" --list >/dev/null 2>&1
    chk "push: optional import — just --list exits 0 with gates/ removed" $?
    ! "$JUST" -f "$IP/required/justfile" --list >/dev/null 2>&1
    chk "push: NEGATIVE — a non-optional import goes red with gates/ removed" $?
    mkdir -p "$IP/optional/gates"
    printf 'importprobe:\n    @echo ok\n' > "$IP/optional/gates/justfile"
    "$JUST" -f "$IP/optional/justfile" --list 2>&1 | grep -q importprobe
    chk "push: control — the optional import does import when gates/justfile is present" $?
    rm -rf "$IP"

The `import? line is still present` assertion matters: without it the probe
could be run against a copy whose import was stripped, and pass for the wrong
reason. Same lesson as `gates/selftest.sh`'s "a claimed mutation is not a made
one".

## Boxes

- [x] Lines 212-213 no longer assert `[ ! -e "$REPO/gates/justfile" ]` against
      the real repo; line 211 is unchanged.
- [x] The probe copies the **real** root justfile — it does not inline a
      hand-written one, so a change to the real import seam is caught.
- [x] `push: optional import — the probe copy still carries the import? line`
      PASSes.
- [x] `push: optional import — just --list exits 0 with gates/ removed`
      PASSes.
- [x] `push: NEGATIVE — a non-optional import goes red with gates/ removed`
      PASSes. This is R3 for R1: the check discriminates.
- [x] `push: control — the optional import does import when gates/justfile is
      present` PASSes.
- [x] The scratch dir is removed on the way out, and nothing is written
      inside `$REPO`.
- [x] No `chezmoi` call is added — the file's structural lint fails a bare
      `chezmoi` in command position, and this probe needs none.
- [x] `bash tests/deploy-skeleton.sh` exits 0 (all three stages).

## Verify

    bash tests/deploy-skeleton.sh --push > /tmp/w08-s1.log 2>&1 && \
      [ "$(grep -cE '^PASS  push: (optional import|NEGATIVE|control)' /tmp/w08-s1.log)" -eq 4 ]

**Proved RED 2026-08-21** before speccing: stage exit `1`, new-label PASS
count `0` of 3.

## Safety

The probe touches no chezmoi state. After implementing, confirm
`chezmoi source-path` still prints `/Users/feb/dev/.files/home` and that the
stage's own `guard[push] sha256 out` line still reads
`02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1`.
