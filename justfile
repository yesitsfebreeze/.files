# Deploy recipes. The gate recipes this file used to import were deleted on
# 2026-08-31 along with tests/ and gates/ — see
# prds/memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md

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

# Name the paths a commit lands, never the tree. On 2026-09-02 a requirement
# written "commit the current working tree" swept up a node another worker
# held; see
# .pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/.
# Read-only: this stages nothing.
[doc('Refuse a path another node holds under a live claim. Read-only.')]
board-guard prd="-" paths="":
    python3 "{{ repo }}/scripts/board-guard.py" held --self "{{ prd }}" {{ paths }}

# Every spec's `## Verify and Proof` block asserts the post-state; none of
# them acts on the repo. Read-only.
[doc('Refuse a spec whose Verify block stages or commits. Read-only.')]
board-guard-blocks:
    python3 "{{ repo }}/scripts/board-guard.py" verify-blocks
    python3 "{{ repo }}/scripts/board-guard.py" requirements

# The memos gate: every memo indexed, every link resolving, every folder its
# kind, every kind declared, one claim per memo — and every index level
# regenerated from the memos, because no index is authored by hand.
[doc('Regenerate the memos indexes and run the memos gate.')]
memos-check:
    python3 "{{ repo }}/scripts/memos-check.py"
