---
est: 1.25h
verify: "bash tests/provisioning.sh --nvim"
---

# spec03 — the Neovim floor, recorded once

Goal: R6. The editor config needs Neovim ≥ 0.11 — native `vim.lsp.enable` and
blink.cmp, neither of which exists below it — and distro packages ship older
builds. `install.sh` must detect what is on the machine, install the official
release tarball when it is missing or too old, and **assert the floor again at
the end of the run**. The version itself is written down in exactly one place
so [`03-editor`](../../../../03-editor/prd.md) can reference it instead of
restating a number that will drift.

## Files

| File | State | Note |
|---|---|---|
| `install.sh` | extend | the floor constant, the detect/override block, the closing assertion |
| `tests/provisioning.sh` | extend | the `--nvim` stage; created in [`spec01`](spec01.md) |

## Design

### One place for the floor

```bash
# The Neovim floor. 03-editor's config needs native vim.lsp.enable and
# blink.cmp, both 0.11+. THIS CONSTANT IS THE RECORD (05-platform/02 R6):
# other documents cite install.sh:NVIM_MIN_MINOR rather than repeating "0.11".
NVIM_MIN_MINOR=11
```

Declared near the top with the other constants, used by both the override
block and the closing assertion, and interpolated into every message
(`"below the 0.$NVIM_MIN_MINOR floor"`) so no message can disagree with it.

The gate enforces the "one place" part: the string `0.11` and the bare token
`11` may appear in `install.sh` **only** on the `NVIM_MIN_MINOR=` line.

### Detection, fixed

```bash
nvim_minor=0
if have nvim; then
  nvim_minor="$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9]*\)\.\([0-9]*\).*/\1 \2/p')"   # NOT-MUTATING
  case "$nvim_minor" in
    "0 "*) nvim_minor="${nvim_minor#0 }" ;;   # 0.x — the minor is the floor
    ""|*[!0-9\ ]*) nvim_minor=0 ;;            # unparseable — treat as absent
    *) nvim_minor=99 ;;                       # major >= 1 — above any 0.x floor
  esac
fi
```

Two defects of the live parser this replaces, both checked against
`/Users/feb/dev/.files/install.sh:128`:

- Its regex is `^NVIM v0\.\([0-9]*\)` — **anchored to major version 0**. A
  Neovim 1.x prints `NVIM v1.0.0`, matches nothing, yields the empty string,
  is caught by the `-z` guard, and is therefore treated as *below the floor*:
  the script would download an older release tarball over a newer editor.
  Today the live machine runs `NVIM v0.12.4` so the bug is dormant, which is
  exactly why it will not be noticed when it stops being.
- Its result is fed straight to `[ "$nvim_minor" -lt 11 ]`. A non-numeric
  value makes `[` fail with `integer expression expected` and the `if` reads
  as *false* — a silent skip. The `case` normalisation above makes every path
  end in a number.

### Override, and where it applies

The release override stays as the live script has it — the tarball into
`$HOME/.local/opt/neovim`, symlinked to `$HOME/.local/bin/nvim`, with the
`rm -rf` of the old tree *inside* the download-succeeded branch (that part of
the live script is correct; do not "simplify" it out) — but it is reached on
**both** platforms now, gated on the version rather than on the OS:

- macOS: brew has already installed a current `neovim` in §1, so the check
  normally passes and the block is skipped. It is not skipped *because* the
  OS is Darwin.
- Linux: the distro package is usually below the floor, so the block runs.

The live script gates the whole check on `[ "$OS" != "Darwin" ]`, which is
why the floor is never asserted on the supported platform at all. R6 says
"macOS gets a current one from brew" — that is a statement about which rung
supplies it, not a licence to skip the check.

### The closing assertion

After the install sections and **before** `chezmoi apply`:

```bash
if ! have nvim; then
  warn "neovim: still not on PATH after install — 03-editor's config will not load"
elif [ "$(nvim_minor_now)" -lt "$NVIM_MIN_MINOR" ]; then   # NOT-MUTATING
  warn "neovim: $(command -v nvim) is below the 0.$NVIM_MIN_MINOR floor — an older nvim is shadowing the installed one on PATH"
fi
```

This is what makes the parent's acceptance box true as written ("the run
leaves a `nvim` on `PATH` at 0.11 or newer"). Installing a current Neovim and
having an older one earlier on `PATH` is the common macOS shape — a
`/usr/local/bin/nvim` from an old manual install ahead of `/opt/homebrew/bin`
— and nothing in the live script would say a word about it. It warns rather
than aborts, per R5.

## The gate, stage `--nvim`

Same harness as [`spec01`](spec01.md): `INSTALL_DRY_RUN=1`, scratch `HOME` and
`PATH`, the `REAL-INVOCATION` poison assertion, the live-config guard in and
out. The scratch bin's `nvim` stub answers `--version` from an env var and
exits 66 for anything else, so a real editor is never launched.

| Stub reports | Expected |
|---|---|
| absent (`bin-fresh`) | override taken; message names `0.11` |
| `NVIM v0.9.5` | override taken |
| `NVIM v0.11.0` | override **not** taken |
| `NVIM v0.12.4` | override not taken |
| `NVIM v1.0.0` | override **not** taken — the live-parser bug |
| `NVIM banana` | override taken (unparseable ⇒ treated as absent), run exits 0 |

Plus, on both `Darwin` and `Linux` from the `uname` stub, with the stub at
`0.9.5`: the override is taken **on both** — the check is not OS-gated.

And the closing assertion: with the stub at `0.9.5` and the override forced
to fail (`INSTALL_DRY_FAIL` on the release install), the run still exits 0
and emits a `!!` line containing `below the 0.11 floor`.

## Acceptance

Ran green 2026-08-21: `bash tests/provisioning.sh --nvim` — exit 0, 42 PASS /
0 FAIL, `REAL-INVOCATION` absent from all ten runs of the stage.

- [x] `install.sh` declares `NVIM_MIN_MINOR=11` exactly once, and neither the
      literal `0.11` nor a bare `11` appears anywhere else in the file —
      messages interpolate the constant. (R6's "record the floor in one
      place")
- [x] With no `nvim` present, the run takes the release override and its log
      line names `0.11`, interpolated from the constant.
- [x] `NVIM v0.9.5` takes the override; `NVIM v0.11.0` and `NVIM v0.12.4` do
      not.
- [x] `NVIM v1.0.0` does **not** take the override. (The live parser at
      `/Users/feb/dev/.files/install.sh:128` does — its regex is anchored to
      `v0.`)
- [x] `NVIM banana` takes the override and the run exits 0 with no
      `integer expression expected` anywhere in the transcript.
- [x] With the stub at `0.9.5`, the override is taken with `uname -s`
      reporting **Darwin** as well as **Linux** — the floor is not OS-gated.
- [x] With the override forced to fail, the run exits 0 and emits a `!!` line
      containing `below the 0.11 floor`. (R5 + the closing assertion)
- [x] No `REAL-INVOCATION` in any run; the live chezmoi config sha256 and
      `chezmoi source-path` unchanged in and out of the stage.
- [x] `bash tests/provisioning.sh --nvim` exits 0, and exits non-zero with
      `NVIM_MIN_MINOR` changed to `9` on a scratch copy.

## Proven RED

- `tests/provisioning.sh` does not exist; the literal `verify:` exits **127**
  (2026-08-21).
- The live `/Users/feb/dev/.files/install.sh` fails three of these boxes by
  construction, read off the file: the floor literal `11` is a bare number at
  line 129 with no constant (box 1); the whole block is inside `if [ "$OS" !=
  "Darwin" ]` at line 107 (box 6); and the parser at line 128 is anchored to
  `^NVIM v0\.` (box 4). There is no closing assertion anywhere in the file
  (box 7).
- Live machine reads `NVIM v0.12.4`, which the live parser resolves to `12` —
  above the floor. The bugs are dormant, not absent.

Proven GREEN in scratch: the [`spec01`](spec01.md) prototype carried the
constant, the `case` normalisation and an OS-independent check.
`GATE_NVIM_MINOR=9` took the override and printed `neovim below the 0.11
floor (found minor '9')`; the default `0.12.4` stub did not; a fresh machine
with no `nvim` took it with `found minor '0'`. `REAL-INVOCATION` absent
throughout.

## Out of scope

- Editing `03-editor` to cite `install.sh:NVIM_MIN_MINOR`. R6 asks for the
  floor to be recorded once and referenced; this spec creates the record, and
  the reference lands in another node's file. Flagged for the orchestrator.
- Pinning a Neovim version. The floor is a minimum, not a pin: brew's current
  release is what macOS gets.
- Anything the other two specs own.
