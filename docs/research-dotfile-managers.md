# Deep research: dotfile distribution programs

Question: which dotfile distribution/deployment programs are actually the most common
and most used, how do they work, and which fits `~/.files`?

Researched 2026-08-20 via web search. Star counts are the figures published on
`dotfiles.github.io/utilities` as of this search; treat them as an ordering signal,
not precise telemetry.

---

## 1. The adoption picture

There is no clean usage telemetry for dotfile managers, so adoption has to be triangulated
from three imperfect signals.

**GitHub stars (proxy for mindshare):**

| Tool | Stars | Model |
|---|---|---|
| chezmoi | ~21,200 | Go binary, source-of-truth copy + templating |
| Mackup | ~15,300 | Python, app-settings sync (Dropbox/git) |
| Nix Home Manager | ~10,200 | Declarative Nix modules |
| Dotbot | ~8,000 | Python, YAML-declared symlinks |
| yadm | ~6,400 | Bash wrapper over a bare git repo |
| GNU Stow | n/a (Savannah, not GitHub) | Perl symlink farm manager |

**Distro packaging (proxy for install base):** GNU Stow is in essentially every distro's
repos, ships in Homebrew, and predates the whole category (it is a GNU package from the
1990s built for `/usr/local`, adopted for dotfiles later). Its star count is ~0 because it
is not primarily a GitHub project — it is almost certainly the most *installed* tool here.

**Surveys:** the only real one (Walladge, 2017) found self-written scripts + Stow together
at 54.5%, with a large "None / by hand" contingent. The single most common dotfile
"manager" in the wild is still a hand-rolled shell script — which is exactly what
`deploy.disabled` is.

**Conclusion on "most common":** GNU Stow by install base and lowest common denominator,
chezmoi by mindshare and by what people migrating *to* something now pick, custom scripts
by raw headcount. The bare-git-repo trick (popularised by Atlassian's tutorial) is the most
common *no-tool* method.

---

## 2. The five real contenders

### GNU Stow — the minimal standard
- **Model:** `stow nvim` symlinks `~/.files/nvim/.config/nvim` → `~/.config/nvim`. Package
  directories mirror the target tree. Nothing else happens.
- **Strengths:** zero config, zero lock-in, one command, packaged everywhere, trivially
  auditable, selective (install only the packages a machine needs).
- **Weaknesses:** no templating (can't have a work git email and a personal one), no
  conditionals, no secrets story, tools that don't follow symlinks break, "tree folding"
  surprises when a directory is half-managed, and you must run stow/unstow explicitly.
- **Verdict:** the correct choice when configs are identical across machines.

### chezmoi — the feature-complete default
- **Model:** the repo is a *source state* (`dot_zshrc`, `dot_config/`), and `chezmoi apply`
  renders it into `$HOME` as real files, not symlinks. Go templates decide per-OS/per-host
  content from one file.
- **Strengths:** first-class Go templating, native age/gpg encryption so secrets can live in
  a public repo, real Windows support, per-host config, `run_once_` scripts for bootstrap,
  `chezmoi diff` before applying, single static binary with no runtime deps, excellent docs,
  very active maintenance. One-line provisioning is a headline feature:
  `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:you/dotfiles.git`,
  plus a built-in `chezmoi docker` path and `chezmoi archive | ssh host -- tar -xf -` for
  machines where you don't want to install anything.
- **Weaknesses:** steepest learning curve of the non-Nix options; Go template whitespace
  (`{{- }}`) and terse expansion errors bite beginners; the copy model means editing a file
  in `$HOME` (or an app rewriting its own config) silently diverges until you `chezmoi add`
  it; **the first `apply` is destructive** over hand-edited dotfiles; losing your age key
  loses every encrypted file.
- **Verdict:** the default recommendation in 2026 for multi-machine, multi-OS setups.

### yadm — git muscle memory, nothing new to learn
- **Model:** a Bash wrapper around a bare repo at `~/.local/share/yadm/repo.git` with
  `$HOME` as the work tree. `yadm add/commit/push` are just git.
- **Strengths:** no new mental model, no symlinks and no copies (files are tracked in place),
  alternate files by suffix (`gitconfig##os.Darwin`, scored by condition count), transparent
  encryption of a declared file list, `yadm bootstrap` runs `~/.config/yadm/bootstrap`.
- **Weaknesses:** Bash-only (weak/absent Windows support), templating is thinner than
  chezmoi's, everything lives in `$HOME` so `.gitignore` discipline matters, and the whole
  home directory being a work tree makes accidental `add -A` dangerous.
- **Verdict:** best fit for people who think in git and stay on Unix.

### Dotbot — declarative bootstrap for a hand-rolled repo
- **Model:** a `install.conf.yaml` listing `link:`, `create:`, `shell:` directives; vendored
  as a git submodule so `./install` works on a clean machine with only Python.
- **Strengths:** the honest upgrade path from a custom script — you keep your repo layout and
  replace the loop with a declarative, idempotent spec. Handles ordered shell steps well.
- **Weaknesses:** still symlinks, no templating or secrets, submodule vendoring is fiddly,
  Python dependency.
- **Verdict:** minimum-diff replacement for a bespoke deploy script.

### Nix Home Manager — reproducibility, at a price
- **Model:** declare the *whole* user environment (packages + config files) in Nix; generations
  are atomic and rollback-able.
- **Strengths:** genuinely reproducible, manages programs and their configs together, atomic
  rollback, works with NixOS and standalone.
- **Weaknesses:** Nix the language is the real cost; debugging is painful; uninstalling Nix is a
  multi-step sudo ritual, versus deleting a repo. The commonly reported failure mode is
  over-Nixing: paying the complexity for reproducibility you don't need. A frequent compromise
  is Nix for *packages*, chezmoi for *dotfiles*.
- **Verdict:** worth it only if you want reproducible environments, not just synced configs.

### Honourable mentions
- **Bare git repo** (`git --git-dir=$HOME/.dotfiles --work-tree=$HOME`): no tool, no symlinks;
  what yadm automates. Popular via the Atlassian tutorial; fiddly to bootstrap and easy to
  mis-fire on `status` without `showUntrackedFiles=no`.
- **Mackup:** syncs *known application* settings rather than a repo you author; overlaps with
  but doesn't replace the above; historically brittle against macOS sandboxing changes.
- **rcm, homeshick, vcsh+mr, dotdrop, lnk:** live but niche; pick one only for a specific
  feature (dotdrop's profiles/templating, vcsh's many-repos-one-home model).

---

## 3. Decision matrix

| | Stow | chezmoi | yadm | Dotbot | Home Manager |
|---|---|---|---|---|---|
| Install model | symlink | copy/render | in-place git | symlink | nix generation |
| Per-OS / per-host variants | ✗ | ✓ templates | ✓ `##os.` alternates | ~ shell hooks | ✓ |
| Secrets/encryption | ✗ | ✓ age/gpg | ✓ | ✗ | ~ external |
| Windows | ✗ | ✓ | ✗ | ~ | ✗ |
| Bootstrap scripts | ✗ | ✓ `run_once_` | ✓ | ✓ | ✓ |
| One-line container/remote install | ✗ | ✓ | ~ | ~ | ✗ |
| Runtime dependency | perl | none (static) | bash+git | python | nix |
| Learning curve | 1/10 | 6/10 | 3/10 | 3/10 | 9/10 |

---

## 4. Fit against this repo

`~/.files` today: an `index` file of `source:dest` pairs, a `deleted` list, and
`deploy.disabled` symlinking `user/<source>` → `$HOME/<dest>`. Around it sit constraints most
generic advice ignores:

1. **Three platforms.** The WezTerm Lua already branches on Windows/macOS/Linux, and
   `theme.lua` picks a different font name per OS. Stow and yadm cannot serve Windows.
2. **A container fleet.** `setup-user.sh` clones a dotfiles repo into every capsule container;
   the standalone `dockerfile` bakes another copy. That is exactly the
   `init --apply` one-liner use case, and chezmoi's `run_once_` scripts subsume
   `setup-user.sh`'s idempotency hand-rolling.
3. **A "Linux-only" constraint encoded as a comment.** `.zshrc` carries
   `# This config is distributed via Docker (Linux) — do not add macOS-specific plugins`.
   That is a templating requirement written as a warning: with chezmoi it becomes
   `{{ if eq .chezmoi.os "darwin" }}`, and the macOS-only bits (brew paths, `open .`) can come
   back safely.
4. **Real secrets already in play.** ssh keys, `.gitconfig`, git credentials, Claude and
   OpenCode auth are mounted into containers by `docker.lua`. Nothing is encrypted at rest in
   the repo — an age-encrypted `private_` file is the native answer.
5. **Deletion tracking.** The custom `deleted` file exists because symlink deployers leak stale
   links. chezmoi handles this with `.chezmoiremove`; yadm/stow do not.

**Recommendation: chezmoi**, and it is not close given constraints 1–4. Stow is the better
tool in the abstract — simpler, no lock-in — but it fails the Windows requirement outright and
the per-OS shell config requirement forces exactly the kind of duplication this repo is
already suffering. yadm loses on Windows alone. Dotbot is only a marginal upgrade over
`deploy.disabled` and adds a Python dependency to containers that currently need none.

**Counter-argument to weigh honestly:** the current script is ~60 lines, understood, and works.
chezmoi's copy model changes the daily loop (`chezmoi edit` / `chezmoi apply`, not "edit the
file in place"), which is the most-reported source of friction. If the Windows machine is
hypothetical rather than real, staying put is defensible.

### Migration sketch, if it goes ahead
1. `chezmoi init` on a scratch machine, `chezmoi add` each entry in `index`
   (`.zshrc`, `.config/WezTerm`, `.config/nvim`, `.config/opencode`, `.config/karabiner`).
2. Karabiner is macOS-only → `.chezmoiignore` it under `{{ if ne .chezmoi.os "darwin" }}`.
   The 80KB `karabiner.json` and the wallpaper directory are both candidates for
   `.chezmoiexternal` or exclusion, since they bloat every container clone.
3. Fold the "Linux-safe" comment into real conditionals in `dot_zshrc.tmpl`.
4. Replace `setup-user.sh`'s dotfiles clone with the `get.chezmoi.io … init --apply` one-liner;
   keep the ssh/permission fixups as a `run_once_` script.
5. Encrypt anything currently mounted-not-committed that would be better versioned.
6. Delete `index`, `deleted`, and `deploy.disabled` only after one full capsule rebuild passes.

---

## Sources
- https://dotfiles.github.io/utilities/
- https://www.chezmoi.io/comparison-table/
- https://www.chezmoi.io/why-use-chezmoi/
- https://www.chezmoi.io/user-guide/machines/containers-and-vms/
- https://www.chezmoi.io/reference/commands/docker/
- https://yadm.io/docs/alternates
- https://yadm.io/docs/bootstrap
- https://www.atlassian.com/git/tutorials/dotfiles
- https://www.swalladge.net/archives/2017/08/07/dotfiles-config-survey/
- https://briandetering.net/2026/06/25/best-dotfile-managers-2026/
- https://gbergatto.github.io/posts/tools-managing-dotfiles/
- https://spondicious.com/blog/stoworchezmoi/
- https://www.rousette.org.uk/archives/a-tour-around-chezmoi/
- https://jade.fyi/blog/use-nix-less/
- https://gvolpe.com/blog/home-manager-dotfiles-management/
- https://biggo.com/news/202412191324_dotfile-management-tools-comparison
- https://news.ycombinator.com/item?id=41453264
- https://rezachegini.com/2025/10/14/installing-and-using-chezmoi-in-a-dev-container/
- https://recca0120.github.io/en/2026/04/13/chezmoi-dotfiles-management/
