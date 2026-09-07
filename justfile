# Deploy recipes.

repo := justfile_directory()

# List the recipes.
default:
    @just --list

# Publish this repo: stage, commit, push. Git only.
# This does NOT deploy. Deploying is `chezmoi apply`; this machine is already
# handed over to this repo (`chezmoi source-path` answers it).
[doc('Stage, commit and push. Git only — does NOT deploy.')]
push message="dotfiles: update":
    git -C "{{ repo }}" add --all
    git -C "{{ repo }}" diff --cached --quiet || git -C "{{ repo }}" commit -m "{{ message }}"
    git -C "{{ repo }}" push

# Regenerate the manual's generated halves from the .nuon surfaces that
# `help` reads, so the pages and the shell cannot disagree. Writes into
# home/dot_config/nushell/help/manual/{guide,reference}; internals/ is
# hand-written and untouched.
#
# This does NOT deploy. `chezmoi apply` (or `rr`) ships it; `?` reads it.
# There is no site to serve any more — the manual is markdown, and the
# search is the `docs` television channel.
[doc('Regenerate the manual pages from the .nuon surfaces. Does NOT deploy.')]
manual:
    node "{{ repo }}/scripts/generate-manual.mjs"

# The memos gate: every memo indexed, every link resolving, every folder its
# kind, every kind declared, one claim per memo — and every index level
# regenerated from the memos, because no index is authored by hand.
[doc('Regenerate the memos indexes and run the memos gate.')]
memos-check:
    python3 "{{ repo }}/scripts/memos-check.py"
