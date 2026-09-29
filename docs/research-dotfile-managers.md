# Deep research: is there something better than chezmoi for this structure?

Question: does any existing dotfile tool beat `dotfiles.sh` — a plain sh
script that copies real-named files over `$HOME`, runs hooks in a fixed
order, and sweeps `removed.txt` for retirements — on a single macOS
machine?

Researched 2026-09-29 via web search. Supersedes the 2026-08-20 survey
(git history, `docs/research-dotfile-managers.md` at `b002601^`), whose
chezmoi recommendation was made under constraints this repo has since
retired: multi-machine templating and no deploy script of its own.

## The short answer

No. The copy-model, real-names, no-templates niche is so small that in
2026 it contains exactly ONE dedicated tool — cattery, a brand-new
single-author project — and even that disagrees with this repo's
deliberate choices. Every tool with adoption differs structurally: it
either symlinks, mangles names, demands a mapping file, or replaces the
whole approach with Nix. The hand-rolled script remains the mainstream
answer for single-machine setups (the only real survey, Walladge 2017,
put self-written scripts + Stow at 54.5% of users).

## The candidates, against this structure

### cattery — the only tool in the niche
Source: tangled.org/aly.codes/cattery (README, 2026).

Matches: ordinary files with real names copied into `$HOME`; no templates
("does not template, interpolate, or patch"); `status`/`diff` dry-run
preview; `add` to adopt existing files; hooks run before and after
`apply`; rejects symlink farms; `--dry-run`/`--non-interactive` flags.

Differs, in ways that matter here:
- It keeps a **state database + baselines** and pauses on a locally
  modified target ("apply asks before replacing"). This repo chose the
  opposite, deliberately (docs/llms/decisions.txt, the deploy is a
  replace): the source overwrites, and a tool rewriting a config in
  place is expected to show up as tree drift, not a prompt.
- It **never deletes a target** — `forget` removes management, not
  files. The `removed.txt` retirement sweep has no equivalent.
- Maturity: single author, hosted on Tangled (not even GitHub), no
  adoption to speak of, requires Go 1.26 to build. Its own `just check`
  echo makes it feel kin, but it is one maintainer's away-ness from
  dead.

### The adopted tools — all structurally different
- **chezmoi** (~21.2k stars; chezmoi.io/comparison-table): source-state
  with mandatory name mangling (`dot_`, `executable_`) and Go templates.
  The name-mangling layer is precisely where this repo's bugs lived.
- **GNU Stow**: symlink farm. The semantic the user chose against.
- **yadm**: git wrapper with `$HOME` as the work tree — does not fit a
  repo whose root carries LLMs.txt, hooks/, docs/.
- **Dotbot** (~8k): a YAML manifest describing what a 70-line sh script
  already does, in a config language.
- **Home Manager / Nix** (~10.2k): declarative rebuilds — a different
  world; the repo's files are edited configs, not derivations.

### The 2025-26 micro-generation — none ready
Checked 2026-09-29: **dodot** (github.com/arthur-debert/dodot, PR #151's
542-line alternatives comparison is good reading): symlink model with
filename-convention actions — chezmoi's prefix trap again; created
2026-04, solo. **comtrya**: ARCHIVED, maintainer quit. **dotter** (2.0k
stars): TOML mapping + Handlebars. **dotdrop** (1.9k): YAML mapping +
Jinja2 + profiles. **dman**, **fathrs**, **deezconfigs**, **nit**,
**tupferl**: copy- or mapping-flavored, all 0-1 stars, all under a year
old. The niche is being reinvented repeatedly and nothing has landed.

## What is actually worth importing

One feature: the dry-run (`chezmoi diff`, cattery `status`). For this
repo that is ~20 lines in dotfiles.sh — compare source and target hashes,
print the delta instead of copying — not a tool adoption. Offered
separately.

## Conclusion

`dotfiles.sh` is not a placeholder waiting for a real tool to exist; on the
evidence of this search it IS the mature implementation of the copy-model
niche. Adopting any surveyed tool would reintroduce exactly one of the
layers whose removal this week's bugs traced back to — name mangling,
symlink semantics, a mapping file, or a state database — for no gain this
single-machine tree can use.