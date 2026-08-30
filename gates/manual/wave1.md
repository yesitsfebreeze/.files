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

## Added 2026-08-30 — the two provisioning claims no gate on a provisioned machine can make

Both belong to [`05-platform/02-package-provisioning`](../../prds/05-platform/02-package-provisioning/prd.md).
They are registered here rather than left as open boxes because the node's
other work is finished and these are not work — they are observations that
need a machine this one is not.

- [ ] **P.2** — a FIRST `install.sh` run on a machine that has none of the
      tools. Any fresh macOS install, or a VM.
      PASS: one run, no manual step, and every tool in the required set
      resolves on `PATH` afterwards.
      FAIL: any tool missing, or the run aborting rather than warning and
      continuing. (The structural half — the set is declared once and every
      name is reached by an install path — is `bash tests/provisioning.sh`
      and is green.)
- [ ] **P.2** — the Neovim floor against a machine that really carries an
      old one. Put an `nvim` below 0.11 on `PATH`, or none at all, and run
      the script.
      PASS: `nvim` on `PATH` afterwards is 0.11 or newer.
      FAIL: the old one survives unremarked. Watch for the shadowing case
      specifically — a current Neovim installed while an older
      `/usr/local/bin/nvim` sits earlier on `PATH` is the common macOS shape,
      and the script is only supposed to WARN there, not fix it.
- [ ] **P.5** — the tmux plugins on a machine that has never had them.
      `07-multiplexer/07-persistence` made `install.sh` clone tmux-resurrect
      and tmux-continuum into `$XDG_DATA_HOME/tmux/plugins`.
      PASS: after one run, both directories exist and a fresh tmux session
      restores its layout after a reboot.
      FAIL: a clone that failed silently — the script warns and continues by
      design, so the warning is the thing to look for.
