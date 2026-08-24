---
est: 0.75h
footprint:
  - AGENTS.md
  - prds/00-delivery/corrections/agents-md-chezmoi-source/checks
calibration: >
  Two same-shape actuals: census-verdict-discipline (same file, AGENTS.md,
  est 0.5h / actual 15m) and terminal-inventory-path-claim (same defect
  class — a path claim in a document, est 0.5h / actual 15m). The prose half
  of this node is that size. The premium is the counterfactual check, priced
  off staging-gate-vacuous-green (est 0.5h / actual 40m), the only measured
  node in the corrections set that shipped a red-before-repair mutation.
  15m prose + ~30m check = 0.75h. The board's document-node ests have run
  2-4x long (work-breakdown 2h/20m, parallelization 2h/15m), so this is
  deliberately not rounded up to 1h.
---

# spec01 — the live-sources paragraph names a method, not a stale clone

`AGENTS.md`'s "Live sources to read when specifying" paragraph (lines 55-58 as
of 2026-08-24) ends `…and the chezmoi source at ~/.local/share/chezmoi`. That
is the last unlabelled, source-claiming carrier of the stale clone in a Tier A
document, and it is in the file every agent reads before touching anything.
This spec rewrites that paragraph to name `chezmoi source-path` as the method,
disambiguates the two trees called `.files`, and ships a node-local check with
a red-before-repair counterfactual, because `gates/tree-links.sh` provably
cannot see this class.

**Measured 2026-08-24, each claim with two different probes:**

| claim | probe 1 | probe 2 |
|---|---|---|
| the live source | `chezmoi source-path` → `/Users/feb/dev/.files/home` | `chezmoi source-path ~/.config/nushell/config.nu` → `/Users/feb/dev/.files/home/dot_config/nushell/config.nu`; `chezmoi data` → `sourceDir: /Users/feb/dev/.files/home` |
| `~/.local/share/chezmoi` still exists and is still stale | HEAD `a2544e4`, committed `2026-06-20 22:07:14 +0200` — 2 months 4 days behind | `git merge-base --is-ancestor a2544e4 8e99f58` → true; live HEAD is `8e99f58`, `2026-08-19` |
| `~/.files` is a directory, not a repo | `git -C ~/.files remote -v` → `fatal: not a git repository` | `git -C ~/.files rev-parse --git-dir` → same fatal; `ls -d ~/.files/.git` → no such file |
| the two `.files` trees are distinct | `~/.files` has no `install.sh`; holds `user/.zshrc`, `deploy.disabled`, `index`, `deleted` | `/Users/feb/dev/.files` has `.chezmoiroot`, `home/`, `install.sh`, git origin `yesitsfebreeze/.files` |

## The replacement wording

Replace the current paragraph in full:

> Live sources to read when specifying (never edit them as part of PRD work):
> `~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
> `~/.config/wezterm/`, `~/.files/`, and the chezmoi source at
> `~/.local/share/chezmoi`.

with:

> Live sources to read when specifying (never edit them as part of PRD work):
> `~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
> `~/.config/wezterm/`, and the legacy tree at `~/.files/` — a plain
> directory, not a git repo (measured 2026-08-24), holding the zsh-era
> material `docs/capabilities.md` rates.
>
> **Find the chezmoi source by running `chezmoi source-path`. Never by literal
> path.** It printed `/Users/feb/dev/.files/home` on 2026-08-24 — a reading of
> that day, not a constant, because `just cutover` rewrites `sourceDir` and
> the answer moves. Two traps live in that answer. `~/dev/.files` is **not**
> `~/.files`: two different trees one path segment apart, and only the first
> is the chezmoi source. And `~/.local/share/chezmoi` still exists but is
> **not** the source — it is a stale June clone (HEAD `a2544e4`, a git
> *ancestor* of the live `8e99f58`) whose readings produced findings L-12,
> L-13 and M-21, and per Decision 4(a) no document may cite it as the chezmoi
> source; the only permitted mention is as the stale clone, labelled as such.
> The full record is in
> `docs/capabilities-provisioning.md`.
> Decision 4 also makes the deployed `~/.config` tree canonical: read a source
> tree to explain how a file got where it is, not to decide what it says.

Wrap at ~78 columns. The literal path stays, labelled as a dated reading —
that is R2's "if a literal path is worth keeping as an example, it is labelled
as one", and it is deliberate: an agent needs to recognise the answer when it
sees it, and needs to be warned off `~/.files` when it does.

## Acceptance

- [ ] `AGENTS.md` contains `chezmoi source-path`, and the live-sources
      paragraph names it as the way to find the source.
- [ ] `AGENTS.md` contains no occurrence of the normalised string
      `the chezmoi source at ~/.local/share/chezmoi`.
- [ ] Every occurrence of `~/.local/share/chezmoi` in `AGENTS.md` has `stale`
      within ±400 characters of it, normalised (backticks stripped,
      whitespace collapsed, lower-cased). The ±400 window is reused verbatim
      from `w0-4-s2-corrections/provisioning-rerate/specs/check03.sh`, so the
      two checks cannot disagree about what "labelled" means.
- [ ] `AGENTS.md` names both `~/.files` and `/Users/feb/dev/.files` (or
      `~/dev/.files`) and states they are different trees.
- [ ] Any literal chezmoi source path in `AGENTS.md` sits in the same
      paragraph as the date `2026-08-24` and a word marking it as a reading
      rather than a constant (`reading`, `not a constant`, or `moves`).
- [ ] `prds/00-delivery/corrections/agents-md-chezmoi-source/checks/agents-chezmoi-source.sh`
      exists, takes `--root <dir>` so it can be pointed at a scratch copy, and
      prints one `PASS`/`FAIL` line per box above.
- [ ] `bash …/checks/agents-chezmoi-source.sh --selftest` runs the
      counterfactual and exits 0. It must, in one run:
      print `sha <before> -> <after>` on ONE line for the mutation and assert
      the two differ; assert the mutated copy is **RED** with the FAIL naming
      `~/.local/share/chezmoi`; print the same one-line sha pair for the
      repair and assert it restores the original; and assert the repaired copy
      is GREEN. No end-state `grep` standing alone — per
      [`a-counterfactual-proves-its-own-mutation`](../../../../memos/a-counterfactual-proves-its-own-mutation.md).
- [ ] The mutation is the literal historical sentence (`and the chezmoi source
      at \`~/.local/share/chezmoi\`.`) substituted back into the scratch copy,
      so a `sed` that matches nothing is caught by the sha pair rather than
      passing quietly.
- [ ] The selftest writes only under a directory it creates and removes; the
      real `AGENTS.md` is byte-identical before and after
      (`shasum -a 256 AGENTS.md`, printed both times).
- [ ] `bash gates/tree-links.sh` Tier A is still `0 broken` **after** the edit
      — asserted as "0 broken", not as an absolute link count, because the
      tree is written by several lanes and a count is stale before it is read.

## Not in this spec

- `gates/waves.tsv` and `gates/manual/wave*.md` are the orchestrator's. A
  node-local check is not a wave gate and is **not** registered.
- `gates/retired-phrases.sh` is the tree-wide home for this rule and is left
  alone. Its exemption table is asserted as SET EQUALITY, so adding a phrase
  for `~/.local/share/chezmoi` also means adding a labelled-retirement-quote
  exemption for every legitimate citation — 12 occurrences outside this node
  on 2026-08-24, across 9 files, 8 of them in `specs/**`. That is a separate
  node with a much wider blast radius, and the file is listed in 20+ other
  nodes' footprints.
- `docs/capabilities-nushell.md:18` and `:179` — the other two live Tier A
  carriers. M-21's own remit; not this footprint.
- `AGENTS.md:5` and `:42` calling `~/.files` a "repo". Reported, not changed:
  R5 says report and do not widen, and the word is imprecise rather than
  misdirecting — the material really is at that path.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# 1. the node's own check, against the real tree
bash prds/00-delivery/corrections/agents-md-chezmoi-source/checks/agents-chezmoi-source.sh

# 2. the counterfactual — the half that proves the check can go red
bash prds/00-delivery/corrections/agents-md-chezmoi-source/checks/agents-chezmoi-source.sh --selftest

# 3. the tree is still linked; quote the TIER A line, and read "0 broken"
python3 gates/tree-links.py --tier a 2>&1 | grep -A2 '^TIER A'

# 4. the two claims the wording rests on, re-measured at implement time
chezmoi source-path
git -C /Users/feb/dev/.files log -1 --format='%h %ci' a2544e4
git -C /Users/feb/dev/.files merge-base --is-ancestor a2544e4 8e99f58 && echo ancestor
```

**`verify:` is `bash gates/tree-links.sh`, and it cannot prove boxes 1-5.**
Measured 2026-08-24: `gates/tree-links.py`'s `LINK_RE` matches only markdown
bracket-paren link syntax, and its Tier A set is `prds/**/{prd,README}.md` +
`docs/capabilities*.md` + `AGENTS.md`. Inline-code paths in backticks are
never resolved. The proof is on the record: Tier A reported `0 broken` all the
while `AGENTS.md` cited `.claude/skills/prd/README.md`, a file that has not
existed since the mi-era skills were retired. So `tree-links.sh` is the
*no-regression* half only — box 10 — and the check in box 6 is what actually
proves the mutation. **Writing it belongs to this node**: it lives inside this
node's own directory, contends with nothing, and precedent exists in
`git-diff-integrity-boxes/checks/gitdiff-boxes.py`.

A census of `AGENTS.md`'s inline code (2026-08-24, fences stripped) matched 31
distinct backticked strings containing `/` or `~`, of which 30 are path-shaped
(`- [~]` is the false positive). Nine do not resolve, and every one is
intentional: five are board-node shorthand that is also the link text of a live
markdown link (`01-capsule/01`, `03-editor/08`, `03-editor/14`, `04-shell/04`,
`decisions/shift-select-scope`), one is a template placeholder
(`<node>/prd.md`), one is named as retired (`.mi/gantt/plan.json`), one is the
non-path false positive, and one is the deliberately-named dead
`.claude/skills/prd/README.md` at line 194, inside the orchestrator's own note
recording that it is dead. **No unintentional dangling path remains in
`AGENTS.md` as of 2026-08-24.** So
a generic existence checker would be **green today and useless here** —
`~/.local/share/chezmoi` exists. The defect class is "a path that resolves and
is the wrong tree", and only a labelled-mention rule catches it. That is why
box 3 is the shape it is, and why the tree-wide version of it belongs in
`gates/retired-phrases.sh` rather than in a new existence gate.
