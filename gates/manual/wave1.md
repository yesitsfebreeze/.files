# Wave 1 — interactive checklist

Automated half: `just gate 1` (the chezmoi skeleton, the deploy mechanism and
the managed config surface, all against scratch destinations).

This wave has no human-run checks, and these checklists are the canonical
enumeration of such checks — so this file is deliberately empty of boxes.
Nothing in wave 1 needs a human eye: everything it produces is a file whose
content a script can read. The file exists so the set of checklists is
complete per wave — an absent wave1.md would read as "not yet written"
rather than "deliberately empty".

If a task lands in this wave that needs a human, add its box here in the
same change — `bash gates/manual-coverage.sh` then proves every box names a
task id some board node carries as `task:` in its prd.md frontmatter.
