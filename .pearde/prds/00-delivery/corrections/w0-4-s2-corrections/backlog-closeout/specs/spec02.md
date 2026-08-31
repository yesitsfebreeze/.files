verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check02.sh`

# spec02 — rewrite open decision 4's reasoning (R5)

**Goal.** Decision 4's conclusion stands; its reasoning does not. The audit of
2026-08-20 measured `~/.local/share/chezmoi` — a two-months-stale June clone
whose HEAD `a2544e4` is a git *ancestor* of the live chezmoi source at
`/Users/feb/dev/.files` — so 4(a) ("the chezmoi source is **abandoned**, not a
port target") is false and 4(b)'s 345-line `finder.nu` exists only in the
clone. The replacement text was drafted by W0.4f's analyst and approved by the
user; it is on disk. This node is the writer, because W0.4f owns no file in
the backlog.

**Files touched — one, body only.**
- `.mi/prds/00-delivery/corrections/prd.md` — numbered item 4 only.

**Source text, to be transcribed rather than re-derived:**
[`../platform/decision4-replacement.md`](../../platform/decision4-replacement.md).

**RED baseline, measured before writing this spec:** `bash check02.sh` →
**26 FAIL**, exit 1.

## What changes and what must not

Replace **four** things inside item 4 and nothing else:

1. the measurement paragraph beginning "Raised by `w0-6-live-bugs`:",
2. clause **(a)**,
3. clause **(b)**,
4. the bullet "- L-12 stands as written: …".

Transcribe the replacement document's middle section (between its two `---`
rules) verbatim. Its own header states the same scope, so the two agree.

**Byte-unchanged, and each pinned by a landed verify or by this spec:**

| kept | why |
|---|---|
| the heading `4. **Deployed or source — which artifact do the inventories rate?**` | `decisions/fzf` spec01 anchors item 4 on `^4\. \*\*Deployed` |
| `**Decided 2026-08-21 (user): the deployed `~/.config` tree is canonical.**` | pinned by `decisions/fzf` spec01 **and** `decisions/wallpaper-opacity` spec01 |
| clause **(c)** in full, including "The ~810-line delta is not pushed back." | the replacement document says (c) stands |
| the closing sentence "Every inventory in `.mi/docs/` rates the deployed artifact. Where one was written against the source, that is a correction, not a difference of opinion." | same |

The stale figures **339 vs 1149** and the phrase "the chezmoi source is
**abandoned**" must be gone from item 4. `provisioning-rerate` deliberately
preserved `1149` elsewhere as `1149 vs 1149`; that is in
`capabilities-provisioning.md`, a different file, and is not touched here.

## The second consequence, added as a new clause (d)

The replacement document's closing section says the backlog "should carry the
fact so nothing else is written against it". Add it as clause **(d)** at the
end of item 4:

```
   - (d) **Commit `8fe3a71` (2026-08-19) deleted the machinery three PRDs and
     three inventory entries were written from** — `home/.chezmoidata/packages.yaml`
     (214 lines), `home/run_onchange_install-packages.sh.tmpl` (486 lines),
     `home/run_once_before_install-homebrew.sh.tmpl` and `home/.chezmoiignore`,
     replaced by a flat 233-line `install.sh` at the repo root; 2490 deletions
     in all. Inside `05-platform` this is discharged by
     `w0-4-s2-corrections/platform` and
     [`provisioning-rerate`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/w0-4-s2-corrections/provisioning-rerate/prd.md).
     It is recorded here so nothing else is specced against a deleted
     capability.
```

Check the two relative links resolve from `corrections/prd.md` before
finishing — Tier A link health is a gating repo gate and this file sits in it.

## Boxes

- [x] Item 4 keeps its heading, its dated user answer, clause (c) in full and
      its closing sentence — all byte-unchanged.
- [x] "the chezmoi source is **abandoned**, not a port target", "is **not
      ported**" and "L-12 stands as written" are gone from item 4, as is
      "339 vs 1149".
- [x] The measurement paragraph now says it was a reading error, names
      `chezmoi source-path` → `/Users/feb/dev/.files/home`, the stale checkout,
      `a2544e4`, `8e99f58`, "git **ancestor**", byte-identity, and "one
      directory further out than the audit thought".
- [x] Clause (a) says the live source is **not** abandoned and bans citing
      `~/.local/share/chezmoi` as the chezmoi source again.
- [x] Clause (b) says there is no 345-line source `finder.nu` and keeps L-5
      standing on its own evidence.
- [x] The L-12 bullet reads "corrected, not confirmed", says five of six were
      artefacts of the stale clone, and names `background.png` as the one real
      file, dropped by decision 5(a).
- [x] A new clause (d) names `8fe3a71`, `install.sh`, `packages.yaml`,
      `run_onchange` and 2490 deletions.
- [x] `tests/live-bugs.sh` 159 PASS / 0 FAIL with 40 `table:` and 50 `routing:`
      assertions; `gates/audit-findings.sh` exit 0; Tier A broken links 0.
- [ ] `decisions/fzf` spec01, `decisions/wallpaper-opacity` spec01 and
      `provisioning-rerate` spec03 all still exit 0, run from their own
      `verify:` fields.
      **Left open:** `wallpaper-opacity` and `provisioning-rerate` exit 0;
      `decisions/fzf` spec01 exits 1 on its item-2 guard, red already at the
      RED baseline. See spec01's note.
- [x] `chezmoi source-path` still prints `/Users/feb/dev/.files/home`, and no
      write reached `/Users/feb/dev/.files`.
