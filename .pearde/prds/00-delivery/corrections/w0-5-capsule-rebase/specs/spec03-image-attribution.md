# spec03 — attribute the image's shell layer correctly (C-4) and restore two truncated source lines

Fixes C-4 in `02-dev-image`: `devzsh` bakes in no zsh (`CMD ["bash"]`), no
oh-my-zsh, and no Claude Code, so the interactive layer comes from the
capsule image definition, not from the standalone toolbox the purpose
currently credits. Also restores the `Parent:` source lists that commit
`8ecbbe4` truncated mid-quote in `02-dev-image` and
`03-credential-propagation` — the same damage class `w0-4-s2-corrections/capsule`
repaired in `01-container-lifecycle` and handed on as "still unowned".
Covers W0.5 R4.

**Est:** 0.5h

**Footprint:** `prds/01-capsule/02-dev-image/prd.md`,
`prds/01-capsule/03-credential-propagation/prd.md`

Never edit the frontmatter (`---` block). Do not edit
`docs/capabilities.md` — it is user-authored and its corrections need the
author's confirmation.

## Edits

### `prds/01-capsule/02-dev-image/prd.md`

1. Replace the truncated `Parent:` line
   (`… · sources: "Standalone dev`) with:

   > Parent: [Capsule epic](../prd.md) · C 7 · U 8 · sources: "Standalone
   > dev container image" (C 7 / U 8 — dominant), the image half of
   > "Capsule" (CONSOLIDATE, C 9 / U 9)

   Ratings read from `docs/capabilities.md`; this is restoration, not
   re-rating.

2. Replace the Purpose paragraph with:

   > Purpose: Exactly one image definition for capsule containers, merging
   > the two legacy images: the standalone `devzsh`-style toolbox and the
   > capsule image. The interactive layer is the capsule image's alone —
   > `devzsh` bakes in no zsh (`CMD ["bash"]`), no oh-my-zsh, and no
   > Claude Code (finding C-4) — so R1 and R4 are specified from the
   > capsule image definition, not ported from `devzsh`. Ubuntu LTS base,
   > unprivileged `dev` user, `/workspace` as workdir.

### `prds/01-capsule/03-credential-propagation/prd.md`

3. Replace the truncated `Parent:` line (`… · source: "Credential`) with:

   > Parent: [Capsule epic](../prd.md) · C 8 · U 8 · source: "Credential
   > propagation into containers" (C 8 / U 8)

## Acceptance

- [x] `02-dev-image`'s `Parent:` line lists both sources with their own
      C/U numbers and the dominant marked; header numbers still C 7 · U 8.
      Verify 2026-08-22: `PASS 02: sources restored`, `PASS 02: capsule
      source listed`, `PASS 02: truncation gone`.
- [x] `02-dev-image`'s purpose attributes zsh, oh-my-zsh and Claude Code
      to the capsule image and cites C-4 with `CMD ["bash"]` as the
      evidence. Verify 2026-08-22: `PASS 02: C-4 attribution`.
- [x] `03-credential-propagation`'s `Parent:` line names its full source
      entry with C 8 / U 8; header numbers unchanged. Verify 2026-08-22:
      `PASS 03: source restored`, `PASS 03: truncation gone`.
- [x] Frontmatter unchanged in both files; `docs/capabilities.md`
      untouched by this node. Verify 2026-08-22: `PASS inventory entries
      intact`; both `---` blocks printed and well-formed.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
a=prds/01-capsule/02-dev-image/prd.md
b=prds/01-capsule/03-credential-propagation/prd.md
fail=0; chk(){ if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }
chk "02: sources restored"      "grep -qF 'Standalone' $a && grep -qF 'container image\" (C 7 / U 8' $a"
chk "02: capsule source listed" "grep -qF '\"Capsule\" (CONSOLIDATE, C 9 / U 9)' $a"
chk "02: truncation gone"       "! grep -q 'sources: \"Standalone dev *$' $a"
chk "02: C-4 attribution"       "grep -q 'C-4' $a && grep -qF 'CMD [\"bash\"]' $a"
chk "03: source restored"       "grep -qF 'source: \"Credential propagation into containers\" (C 8 / U 8)' $b"
chk "03: truncation gone"       "! grep -q 'source: \"Credential *$' $b"
chk "inventory entries intact"  "grep -qF 'Docker dev containers from the terminal  CONSOLIDATE' docs/capabilities.md && grep -qF '## Standalone dev container image' docs/capabilities.md"
exit $fail
```
