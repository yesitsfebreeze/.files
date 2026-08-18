---
state: claimed
mode: afk
priority: 2
verify: test ! -d .splinter && test ! -f docs/build.py && test ! -f docs/index.html && test "$(git ls-files | grep -c '^\.splinter/')" = 0 && test -z "$(git grep -l 'docs/index\.html' -- . ':!.pi/prd/')"
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Remove build/codegen systems

Purpose: The `.splinter/` tree (198 tracked files: 42 skeletons + 114 fragments
+ 42 spec headers) is a codegen system whose output is already committed in
`home/` and referenced by nothing at runtime. `docs/build.py` (564 lines) is a
hand-rolled markdown→HTML renderer for one docs page. Both are dead weight that
triple the maintenance surface of the configs they generate.

## Requirements
- [x] `.splinter/` directory deleted from the working tree and git
- [x] `docs/build.py` deleted
- [x] `docs/index.html` deleted (generated artifact)
- [x] No tracked file references the codegen system (paths under `.splinter/` or the splinter build)
- [x] All generated configs in `home/` remain intact and functional (they are the source of truth now)

## Decisions
- `docs/README.md` was also deleted: it described how to open and rebuild
  `docs/index.html` using `docs/build.py`. After removing both, the README was
  stale documentation about a dead feature and referenced the splinter build
  (violating requirement 4).
- Conductor re-opened requirement 4: `home/run_after_generate-shell-init.sh.tmpl`
  line 96 said "see the README (or docs/index.html)" — a stale pointer to
  the deleted build output. The parenthetical was removed.
- `docs/concepts/*.md` were kept: they are standalone markdown content files,
  not build system components.
- The `.kern/intake/done/pi-surface-index.md` file references symbols from
  `docs/build.py` and `docs/index.html` via the "splinter" pi extension (code
  index tool). This file is gitignored (`/.kern/`) and the pi extension is
  explicitly out of scope per the node.
- `home/.chezmoidata/pi.yaml` and `home/run_after_mirror-config-to-windows.sh`
  reference the "splinter" pi extension (a different tool), which is out of
  scope per the node.
- `.pi/prd/remove-build-systems/prd.md` (this file) textually contains
  `.splinter/` and `docs/build.py` as the subject of the node — this is the
  task definition, not a runtime reference to the codegen.

## Acceptance
- [ ] `test ! -d .splinter && test ! -f docs/build.py && test ! -f docs/index.html` passes, `git ls-files | grep -c '^\.splinter/'` is 0, and no tracked file outside `.pi/prd/` references `docs/index.html` (covers requirement 4 — strengthened by conductor after the first collect missed the stale pointer).

## Out of scope
- The "splinter" pi extension referenced in mirror-config-to-windows.sh (a different tool, unrelated to the codegen)
- Regenerating any configs (the committed files are final)

## Assumptions
- The generated files in `home/` are complete and self-contained (verified in analysis: they are committed and nothing references `.splinter/` at runtime).
