---
est: 0.5h
footprint:
  - prds/00-delivery/corrections/verify-all-empty-eval/specs/spec03.md
---
<!-- Footprint is this file itself: the census's box-checks land here; the
     census fixes nothing — every exposed runner is reported, not edited. -->

# spec03 — census every runner that reads `verify:` values (ticket R4)

`grep -rln '^verify: ""' prds --include='*.md'` prints 70 files on
2026-08-24, 33 of them spec files — the ticket's "29 were blanked" has grown. Any script that extracts a `verify:` value and
evals it holds the same *unset-means-empty* assumption the runner did.
Re-measure each candidate below, and put the census in the report — one line
per runner: extraction shape, exposed or not, and the evidence. Fix nothing
outside spec01/spec02's footprints.

## Candidates, measured 2026-08-24 — re-verify each

| runner | extraction | exposure |
|---|---|---|
| `w0-4-s2-corrections/editor/specs/verify-all.sh` | `grep -m1 '^verify: '` + eval | exposed; the seven false FAILs — fixed by spec01 |
| `w0-4-s2-corrections/backlog-closeout/specs/check01.sh:43-45` | `grep -m1 '^verify:'` + `sed 's/^verify: \`//'` + eval, no blank guard | **exposed**: `decisions/fzf/specs/spec01.md`'s first `^verify:` line is `verify: ""` (line 104); the sed matches no backtick, so it evals the string `verify: ""` → 127 — **masked**, see below |
| `w0-4-s2-corrections/backlog-closeout/specs/check02.sh:66-70` | same pattern over fzf/spec01, wallpaper-opacity/spec01, provisioning-rerate/spec03 | **exposed** via the same fzf/spec01, same mask |
| `w0-4-s2-corrections/shell/verify.sh` | none — hardcoded Python checks, reads no `verify:` value | not exposed; its repo-derivation defect is `mi-lowercase-verify-sections`'s, report only |
| `w0-4-s2-corrections/help/verify.sh` | fenced blocks under a `## verify` heading, never the `verify:` scalar | not exposed; no help spec is blanked |
| `gates/selftest.sh`, `gates/retired-phrases.sh`, `tests/nushell-*.sh`, `tests/shell-quicklist.sh` | `verify:` appears as comment, planted fixture, or nuon metadata grep — no eval | not exposed |

## The mask on check01/check02 — report, do not fix

Both scripts check "landed verify still exits 0" as

```sh
( eval "$v" ) >/dev/null 2>&1
chk "landed verify still exits 0: $(basename ...)/$(basename "$f")" $?
```

The message argument's `$(basename …)` substitutions run before `$?` is
expanded and reset it to 0, so `chk` always receives 0 — **the check cannot
fail**. Reproduced 2026-08-24: `( eval 'verify: ""' )` alone returns 127,
yet check01 prints `PASS landed verify still exits 0: fzf/spec01.md`. The
scripts' own header comment states this exact rule ("no message string below
interpolates a command substitution") and these lines violate it. Both
belong to `backlog-closeout`, a done node — a check that cannot fail in a
done node's gate is a fresh correction for the orchestrator to file, not an
edit under this node.

## Acceptance

- [x] The report carries one census line per runner in the table — six
      lines, each with extraction shape and exposed/not-exposed.
- [x] The check01/check02 `$?`-clobber is reproduced and quoted: the manual
      `eval` status (127) beside the script's PASS line.
- [x] `shell/verify.sh` is reported as not-exposed with its defect routed to
      `mi-lowercase-verify-sections`, per ticket R4.
- [x] No file outside spec01/spec02's footprints is edited — `git status`
      quoted.

## Verify and Proof

```sh
find prds gates tests -name '*.sh' | xargs grep -ln 'verify: '   # the candidate set
f=prds/00-delivery/decisions/fzf/specs/spec01.md
v="$(/usr/bin/grep -m1 '^verify:' "$f" | sed -E 's/^verify: `//; s/`$//')"
( eval "$v" ) >/dev/null 2>&1; echo "eval status: $?"            # 127
bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check01.sh \
  | grep 'landed verify'                                          # PASS lines despite 127
```
