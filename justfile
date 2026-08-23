# Deploy recipes. Gate recipes live in gates/justfile and are imported when
# that file exists, so this file has one writer and the gates have another.
import? 'gates/justfile'

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
