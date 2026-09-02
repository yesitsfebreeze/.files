---
complexity: 10
footprint:
  - home/run_after_generate-shell-init.sh
  - home/run_after_register-mcp.sh
  - home/dot_config/capsule/Dockerfile
---

# spec02 — the apply-time scripts lose their prose and keep their traps

Three files carried more commentary than code, and most of it cited tests and
gates deleted on 2026-08-31. Each keeps the constraints that are load-bearing
and loses the rest; the long reasons move to `internals/provisioning.md`
(spec03), where they are searchable.

**Already stands** (built and verified 2026-09-02):

- `run_after_generate-shell-init.sh`: 112 → 35 lines. The
  `SHELL_INIT_BREW_PREFIXES` seam is gone — it existed only to isolate a gate
  that no longer exists — and brew is now the plain
  `eval "$(/opt/homebrew/bin/brew shellenv)"`. `gen_init`'s tmp-and-`mv` is
  kept verbatim, and so is the three-line TRAP header.
- `run_after_register-mcp.sh`: 65 → 29 lines, keeping only the `~/.claude.json`
  vs `settings.json` finding. Points 2 to 4 of its old header move to the
  internals page.
- `capsule/Dockerfile`: the two `tests/dev-image.sh` citations are gone; the
  layer-order rule and the no-`COPY`/`ADD` rule stay, because both are
  contracts the file itself must honour.

**The proof that mattered.** The rewritten shell-init script was run directly
and its three outputs came out at 2280, 1966 and 1809 bytes — byte-identical
in size to what the 112-line original produced minutes earlier. That is the
evidence the 77 deleted lines were commentary and seam, not behaviour.

**The one behaviour that is not merely commentary**: `MASON_SEED` is gone from
`install.sh` per R2, and `run_after_seed-mason-registry.sh` reads it as its own
early-exit guard. That script therefore now has no caller. It is out of this
PRD's scope — `06-neovim-television` owns it — and is called out in the report
rather than fixed here.

## Acceptance

- [x] `run_after_generate-shell-init.sh` is at most 40 lines, parses, and names
      no `SHELL_INIT_BREW_PREFIXES` — `wc -l` 35, `bash -n` exits 0, and the
      verify's negated `rg` over the four files matches nothing
- [x] running it leaves three non-empty files in `~/.cache/nushell/init/` —
      `ok three non-empty init files`; `ls -l` 2026-09-02 gives
      `starship.nu 2280`, `zoxide.nu 1966`, `television.nu 1809`, the same
      three sizes the 112-line original produced
- [x] with one of the three tools failing, it still exits 0, that tool's file
      is empty, and the other two are intact — `shell-init-missing-tool.sh`
      exits 0: `PASS: exit 0, zoxide.nu empty, other two intact`
      (`starship.nu 2280`, `television.nu 1809`, `zoxide.nu 0`)
- [x] `run_after_register-mcp.sh` still records that the destination is
      `~/.claude.json`, not `settings.json` — `:4` and `:8` name it;
      `ok the ~/.claude.json finding survives`
- [x] the Dockerfile still records the empty-build-context rule and cites no
      test or gate — `:8` `No COPY/ADD: the build context stays empty`;
      `ok the empty-build-context rule survives` and the negated `rg` is clean

## Verify and Proof

```sh
bash .pearde/prds/09-simplify/07-provisioning/probe/verify.sh
bash .pearde/prds/09-simplify/07-provisioning/probe/shell-init-missing-tool.sh \
     home/run_after_generate-shell-init.sh
```

The second builds a scratch `HOME` at run time and puts a `zoxide` that exits
1 first on PATH. It does **not** try a clean PATH: the script evaluates
`/opt/homebrew/bin/brew shellenv` by absolute path, and that shellenv prepends
the real prefix back over any scratch PATH — the exact defeat the deleted
`SHELL_INIT_BREW_PREFIXES` seam was built for. A shim first on PATH is the
only isolation that holds, and `$HOME/.local/bin` is first by the script's own
design.
