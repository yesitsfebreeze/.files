---
complexity: 25
footprint:
  - tests/managed-config.sh
---

# spec02 — `dot_local` and `litellm` are declared, narrowly, and the declaration argues for itself

R1's trap is that the easy fix — add both names to the declared surface — is
how the decision gets skipped a second time. So each name is read first, and
each declaration is written with the reason it survives and a companion check
that keeps the thing the surface census was built to stop.

## `dot_local` — declared, and narrowed in the same change

`0b77a71` deploys five hand-written commands to `~/.local/bin`: `cll`,
`litellm-env`, `litellm-gen-config`, `litellm-up`, `llm-quota`.

**It belongs.** `~/.local/bin` is the only PATH-visible target this rebuild
has — `home/run_after_generate-shell-init.sh` prepends exactly that directory
(`export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"`), and
`home/dot_config/<tool>/` is on no PATH. A command the user types has one
honest place to live.

**And the argument against it is real, which is why it is narrowed.**
`dot_local` is named *by the census's own comment* as an example of the
wholesale port of the legacy source root that check 1 exists to catch — beside
`dot_assembly`, `dot_bash_profile` and `dot_pi`, which are all in `FORBIDDEN`.
Admitting the root would admit `share/`, `state/` and `lib/` with it. So
`HOME_TOP` gains `dot_local`, and a new `DOT_LOCAL_TOP="bin"` plus a check 1b
allows `bin` under it and nothing else. The wholesale port still trips.

## `litellm` — declared **pending**, not as a tenth name in R2's nine

`~/.config/litellm/` is a tool's config directory, which is exactly the shape
`05-platform/01-deploy-mechanism/managed-config` R2 describes — so it is
declared rather than moved out. But R2 enumerates **nine** names, and growing
that list is that node's decision, not this gate's. The file already has the
mechanism for precisely this: `capsule` sits in `SURFACE_PENDING` with a note
saying it is allowed and not endorsed, and raised with the epic owner. This is
the second such name and it follows the same route.

## Acceptance

- [x] `HOME_TOP` names `dot_local`, and the comment above it states the PATH
      argument, names the generator line that makes it true, and says
      explicitly that this is *not* the legacy-root port the check catches.
      — `tests/managed-config.sh:110` reads
      `HOME_TOP=".chezmoiignore .chezmoi.toml.tmpl dot_config dot_gitconfig.tmpl dot_local"`,
      and the comment above it cites the generator; the citation was checked
      against the file rather than taken on the comment's word:
      `grep -n 'local/bin' home/run_after_generate-shell-init.sh` →
      `65:export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"`.
- [x] `DOT_LOCAL_TOP` exists, names `bin` only, and a check reports every
      undeclared entry directly under `home/dot_local/`.
      — `tests/managed-config.sh:112` `DOT_LOCAL_TOP="bin"`; the check line is
      `PASS  surface: home/dot_local/ holds only declared subtrees (undeclared: <none>)`.
- [x] `SURFACE_PENDING` names `litellm`, with a comment saying it is pending
      rather than part of R2's nine, and why that is the epic's call.
      — `tests/managed-config.sh:91` `SURFACE_PENDING="capsule litellm"`, with
      the note that "growing that list is
      `05-platform/01-deploy-mechanism/managed-config`'s decision, not this
      gate's".
- [x] The `dot_local` census is a **factored predicate**, not inlined, so the
      `--selftest` stage exercises the same code the census runs.
      — `dot_local_undeclared()` at `tests/managed-config.sh:229`, called from
      `stage_surface` check 1b and from `stage_selftest`.
- [x] `--selftest` plants `home/dot_local/share/` in a `scratch_tree` copy and
      the predicate reports it; removing it again reports nothing. Both
      directions, in that order.
      — `bash tests/managed-config.sh --selftest`, EXIT=0:
      `MUTATION: planted home/dot_local/share/ in the copy` /
      `PASS  selftest red: an undeclared home/dot_local/share/ is reported (got: share)` /
      `MUTATION: removed home/dot_local/share/ again (the green counterfactual)` /
      `PASS  selftest green: the unmutated copy reports no undeclared dot_local subtree`.
- [x] `--selftest` asserts the real `home/dot_local/share` was never created.
      — `PASS  selftest: the real home/dot_local/share and litellm/plain.yaml were never created`.
- [x] `bash tests/managed-config.sh` exits 0 and every `surface:` line reads
      `<none>`. — **Green on the tree this node owns; one red in the live
      working tree belongs to another session.** Against a clean `HEAD`
      archive with this node's footprint overlaid: `EXIT=0`, 67 PASS / 0 FAIL,
      all eight `surface:` lines `<none>`, ending
      `PASS — the managed surface is the declared surface, and the live chezmoi config was never touched`.
      In the live working tree the same run is `EXIT=1` on
      `FAIL  surface: home/dot_config/ holds only declared tools (undeclared: tmux)`
      — `home/dot_config/tmux/` is untracked work in flight from the
      concurrent `dotfiles-ef` session (`prds/07-multiplexer`), outside this
      node's footprint, and is reported rather than fixed.

## Verify and Proof

```sh
bash -n tests/managed-config.sh
bash tests/managed-config.sh; echo "EXIT=$?"
bash tests/managed-config.sh 2>&1 | grep -E 'surface: home/'
bash tests/managed-config.sh --selftest; echo "EXIT=$?"
bash tests/managed-config.sh --selftest 2>&1 | grep -E 'dot_local'
```
