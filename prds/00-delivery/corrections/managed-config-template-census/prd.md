---
state: done
claim:
priority: 20
est: 0.75h
actual: 5m
mode: afk
needs:
  - 04-shell/09-theme-switcher
verify: "bash tests/managed-config.sh"
origin: derived
---

# managed-config's template census rejects the television theme template

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/managed-config.sh` asserts "exactly one deployed template,
dot_gitconfig.tmpl" and "no template under home/dot_config/". S.9
(theme-switcher) landed `home/dot_config/television/cable/theme.toml.tmpl`
on 2026-08-22 — templated deliberately, because television hands commands
to `$SHELL` and only an absolute `{{ .chezmoi.homeDir }}` path runs
identically under nu, bash and sh (recorded in S.9 spec03). The census
predates that template and now fails 3 checks (measured 2026-08-22, T.1's
implementer; confirmed by the orchestrator the same day). The census's
premise — templates are exceptional and each one is named — is worth
keeping; the fix is to admit the new template to the named set, not to
loosen the check.

## Requirements
- [x] **R1** — The census names `dot_config/television/cable/theme.toml.tmpl`
      as an expected template with a comment carrying S.9's absolute-path
      reason; the "no template under home/dot_config/" blanket check becomes
      the named-exception form. `TEMPLATES` sits beside `SURFACE` /
      `SURFACE_PENDING` / `HOME_TOP` in `tests/managed-config.sh`; check 6
      reads `surface: every template under home/dot_config/ is named in
      TEMPLATES`.
- [x] **R2** — The gate still fails on an UNnamed new template. `--selftest`
      plants one in a scratch copy:
      `PASS  selftest red: an unnamed home/dot_config/foo/bar.tmpl turns the
      census red`, with `mutated copy: unnamed under dot_config/ =
      dot_config/foo/bar.tmpl`.

## Acceptance
- [x] `bash tests/managed-config.sh` exits 0 with 0 FAIL — 65 PASS, 0 FAIL,
      `PASS — the managed surface is the declared surface, and the live
      chezmoi config was never touched`.
- [x] A scratch copy with a planted `home/dot_config/foo/bar.tmpl` fails the
      census. Run through `--selftest`, which reports the mutation and the
      red verdict; the full output is quoted in
      [`specs/spec01.md`](specs/spec01.md).

## Out of scope
- The wezterm-specific census clauses (they pass) and any change to the
  television template itself.
