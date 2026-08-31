# Deploy recipes. The gate recipes this file used to import were deleted on
# 2026-08-31 along with tests/ and gates/ — see
# prds/memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md

repo := justfile_directory()

# List the recipes.
default:
    @just --list

# Publish this repo: stage, commit, push. Git only.
# This does NOT deploy and does NOT change which repo this machine is
# deployed from. Deploying is `chezmoi apply`; changing ownership is
# `just cutover`, and nothing else in this file does it.
[doc('Stage, commit and push. Git only — does NOT deploy or change ownership.')]
push message="dotfiles: update":
    git -C "{{ repo }}" add --all
    git -C "{{ repo }}" diff --cached --quiet || git -C "{{ repo }}" commit -m "{{ message }}"
    git -C "{{ repo }}" push

# DANGER, one-time and deliberate: hand this machine over to this repo.
# `chezmoi init --source` rewrites sourceDir in ~/.config/chezmoi/chezmoi.toml,
# so from here on `chezmoi apply`, `chezmoi update` and `rr` deploy from HERE
# and no longer from wherever they pointed before. Files the old source
# managed are not deleted, they simply stop being managed. Until the managed
# tree is complete this leaves the machine deployed from a repo that carries
# almost none of it. Type this on purpose.
[doc('DANGER: hands this machine over to this repo. One-time, deliberate.')]
cutover:
    chezmoi init --source "{{ repo }}" --force
    chezmoi apply --force

# Serve the manual at http://localhost:3000. Regenerates from the .nuon
# surfaces first, so it always matches what `help` prints in the shell.
[doc('Serve the searchable manual on :3000.')]
docs:
    cd "{{ repo }}/docs-site" && npm run dev

# Regenerate the manual pages from the .nuon surfaces without serving.
[doc('Regenerate the manual pages from the .nuon surfaces.')]
docs-generate:
    cd "{{ repo }}/docs-site" && npm run generate
