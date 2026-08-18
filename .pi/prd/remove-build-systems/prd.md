---
state: claimed
mode: afk
priority: 2
verify: test ! -d .splinter && test ! -f docs/build.py && test ! -f docs/index.html && test "$(git ls-files | grep -c '^\.splinter/')" = 0
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Remove build/codegen systems

Purpose: The `.splinter/` tree (198 tracked files: 42 skeletons + 114 fragments
+ 42 spec headers) is a codegen system whose output is already committed in
`home/` and referenced by nothing at runtime. `docs/build.py` (564 lines) is a
hand-rolled markdown→HTML renderer for one docs page. Both are dead weight that
triple the maintenance surface of the configs they generate.

## Requirements
- [ ] `.splinter/` directory deleted from the working tree and git
- [ ] `docs/build.py` deleted
- [ ] `docs/index.html` deleted (generated artifact)
- [ ] No tracked file references the codegen system (paths under `.splinter/` or the splinter build)
- [ ] All generated configs in `home/` remain intact and functional (they are the source of truth now)

## Acceptance
- [ ] `test ! -d .splinter && test ! -f docs/build.py && test ! -f docs/index.html` passes and `git ls-files | grep -c '^\.splinter/'` is 0.

## Out of scope
- The "splinter" pi extension referenced in mirror-config-to-windows.sh (a different tool, unrelated to the codegen)
- Regenerating any configs (the committed files are final)

## Assumptions
- The generated files in `home/` are complete and self-contained (verified in analysis: they are committed and nothing references `.splinter/` at runtime).
