---
est: 0.75h
verify: "bash tests/managed-config.sh --surface"
---

# spec02 — the managed surface is the declared surface

Goal: turn R2's first sentence — *one source of truth per tool under
`home/dot_config/`* — from a list in a document into a census a check can
fail. The failure this prevents is concrete and likely: the obvious way to
build out `home/dot_config/` is to copy directories across from
`/Users/feb/dev/.files/home/dot_config/`, and that tree still carries
`burrito/` (`DO NOT PORT`, decided 2026-08-20), `ponytail/`, and
`wezterm/background.png` (dropped with the wallpaper pipeline by decision
5(a)). Nothing today would notice any of them arriving.

## Files

| File | State | Note |
|---|---|---|
| `tests/managed-config.sh` | extended | the `--surface` stage; [`spec01`](spec01.md) creates the file |

No other file is touched. Nothing under `home/dot_config/` is written by this
spec — every per-app directory belongs to its own track (nushell to S.x, nvim
to E.x, wezterm to T.x, help to H.x), and the surface declaration *lists*
them, it does not create them.

## Design

**The census is one-directional, and that is deliberate.** It asserts *no
undeclared entry exists*, never *every declared entry exists*. Eight of the
nine names in R2 belong to tracks that have not landed, and `tinted-theming`
is deployed-only today — it is in R2 as a forward-looking choice, because
[`decisions/tinty`](../../../../00-delivery/decisions/tinty/prd.md) made tinty
the palette owner and therefore something the rebuild manages. A census that
demanded all nine would be red until the last track closes, which makes it
noise rather than a gate.

**Two declared lists live at the top of the script, and editing one IS the
decision.** The FAIL message names the undeclared entry, so the next agent
finds the list without reading this spec:

```
SURFACE="nushell nvim wezterm television starship.toml bat gh lazygit tinted-theming"
SURFACE_PENDING="capsule"
HOME_TOP=".chezmoiignore .chezmoi.toml.tmpl dot_config dot_gitconfig.tmpl"
```

`SURFACE` is R2's nine, verbatim and in R2's order. `SURFACE_PENDING` carries
`capsule` because `plan.json` schedules C.4 to write
`home/dot_config/capsule/recents.nuon` — a tenth directory, and the one entry
that would otherwise turn this gate red through no fault of its author. It is
listed separately rather than merged into `SURFACE` because it is *not* part
of R2's surface and, on the face of it, is recents **state** rather than tool
config; flagged to the epic owner, not decided here. `HOME_TOP` is the
`home/` root, where `run_once_before_*` (P.3) and `run_after_*` (P.4) are
additionally allowed by glob — they are chezmoi scripts, not deploy targets.

Six checks:

1. **`home/` holds only declared entries.** Catches a wholesale port of the
   live source's root, which carries `dot_assembly`, `dot_bash_profile`,
   `dot_local`, `dot_pi`, `empty_dot_hushlogin` and `wallpapers/`.
2. **`home/dot_config/` holds only declared tools.**
3. **Settled exclusions never reappear anywhere under `home/`** — a name
   census over the whole subtree for `burrito`, `wp-stat-overlay`,
   `ponytail`, `wallpapers`, `background.png`, `solo-window`, `dot_pi`,
   `dot_assembly`, `dot_bash_profile`. Check 3 overlaps checks 1 and 2 on
   purpose: 1 and 2 police the two levels the surface is declared at, 3
   catches the same artefact smuggled in three levels down, which is exactly
   where `wezterm/background.png` sits.
4. **One source of truth.** Each declared name resolves to at most one path
   under `home/` — no `nvim/` in both `dot_config/` and `dot_local/share/`,
   no second `starship.toml`.
5. **Exactly one deployed template**, `dot_gitconfig.tmpl`. R2's second
   sentence. `.chezmoi*` and `run_*` are excluded from the census because
   neither is a deploy target: the first is chezmoi metadata (P.1's
   `.chezmoi.toml.tmpl`), the second is a script chezmoi runs rather than a
   file it places, and the live homebrew bootstrap P.3 ports was a
   `run_once_before_install-homebrew.sh.tmpl`. Without that exclusion this
   check would collide with a neighbouring lane doing its job correctly.
6. **No template under `home/dot_config/` at all** — a per-tool config that
   needs template data is the thing R2 forbids, and it should fail on the
   file's existence rather than waiting for a render.

Checks 1–6 are pure filesystem census: no chezmoi call, so no guard is needed
in this stage (`guard_begin`/`guard_end` bracket the `--gitconfig` stage,
which does apply). The `lint_no_bare_chezmoi` self-check in the preamble
covers the whole file either way.

**No prose greps.** Every check compares path *names*, exactly — the board
wraps prose at ~78 columns and line-oriented greps over wrapped text have
produced false negatives repeatedly. For the same reason `git diff --quiet`
and `git status --porcelain` are not used as untouched-file guards anywhere in
this node: the `.mi/prd` → `.mi/prds` rename is staged and uncommitted, so
porcelain prints ~160 lines that no gate caused.

## Acceptance

Closed 2026-08-21 by `bash tests/managed-config.sh --surface` — **9 PASS / 0
FAIL, exit 0**; both stages together, `bash tests/managed-config.sh`, are **63
PASS / 0 FAIL, exit 0**. All six census checks were made to fail on purpose in
a scratch copy (planted `dot_config/burrito/`, `wezterm/background.png`,
`nushell/config.nu.tmpl`, `dot_bash_profile`, a second `starship.toml` and a
second `nvim/`): six for six, exit 1.

- [x] `home/` contains no entry outside `{.chezmoiignore,
      .chezmoi.toml.tmpl, dot_config, dot_gitconfig.tmpl}` ∪ `{run_once_before_*,
      run_after_*}`, and the FAIL message names any that appears.
- [x] `home/dot_config/` contains no entry outside R2's nine plus the
      declared-pending `capsule`.
- [x] None of `burrito`, `wp-stat-overlay`, `ponytail`, `wallpapers`,
      `background.png`, `solo-window*`, `dot_pi`, `dot_assembly`,
      `dot_bash_profile` exists anywhere under `home/`, at any depth.
- [x] No declared tool name resolves to two paths under `home/`.
- [x] The set of `*.tmpl` files under `home/`, excluding `.chezmoi*` and
      `run_*`, is exactly `{dot_gitconfig.tmpl}`, and none of them is under
      `home/dot_config/`.
- [x] `bash tests/managed-config.sh --surface` exits 0 on the finished tree,
      and `bash tests/managed-config.sh` (both stages) exits 0.

## Proven RED

Run against the tree as it stands (2026-08-21), the prototype exits 1 on
check 5 — the surface currently has **no** deployed template, because
`dot_gitconfig.tmpl` does not exist yet:

```
PASS  surface: home/ holds only declared entries (undeclared:<none>)
PASS  surface: home/dot_config/ holds only declared tools (undeclared:<none>)
PASS  surface: no DO NOT PORT / dropped artefact under home/ (found:<none>)
PASS  surface: each declared tool has exactly one path under home/ (dupes:<none>)
FAIL: surface: exactly one deployed template, dot_gitconfig.tmpl (got: <none>)
PASS  surface: no template under home/dot_config/
```

Checks 1–4 pass today because the managed tree is still almost empty — which
is precisely why they are worth nothing until they are shown to fire. **Every
one was made to fail on purpose, in a scratch copy of the repo**, by planting
`home/dot_config/burrito/burrito.toml`,
`home/dot_config/wezterm/background.png`,
`home/dot_config/nushell/config.nu.tmpl`, `home/dot_bash_profile`, a second
`starship.toml` under `home/dot_local/share/`, and a second `nvim/`:

```
FAIL: surface: home/ holds only declared entries (undeclared: dot_bash_profile dot_local)
FAIL: surface: home/dot_config/ holds only declared tools (undeclared: burrito)
FAIL: surface: no DO NOT PORT / dropped artefact under home/ (found: burrito background.png dot_bash_profile)
FAIL: surface: each declared tool has exactly one path under home/ (dupes: nvim(2) starship.toml(2))
FAIL: surface: exactly one deployed template, dot_gitconfig.tmpl (got: dot_config/nushell/config.nu.tmpl dot_gitconfig.tmpl)
FAIL: surface: no template under home/dot_config/
```

Six for six, exit 1. Against a scratch copy carrying the drafted
`home/dot_gitconfig.tmpl` and nothing else planted, the stage is **9 PASS / 0
FAIL**, exit 0, and both stages together are **59 PASS / 0 FAIL**.

## Out of scope

- Creating or editing any file under `home/dot_config/`. The census lists;
  the tracks write.
- Asserting that a declared tool *has* landed. One-directional by design, see
  above.
- `gates/justfile` and the wave-gate runner (G.1's). This script follows P.1's
  precedent — a node gate in `tests/`, sourcing `gates/lib.sh` — and G.1 picks
  it up without either task editing the other's file.
- Whether `capsule/recents.nuon` (C.4) belongs in a *config* surface at all.
  Allowed here so C.4 is not blocked; raised with the epic, not settled here.
