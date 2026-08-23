#!/bin/bash
# Covers: 05-platform/01-deploy-mechanism/managed-config (gantt P.5) — R2, the
# managed config surface and the one templated file it allows.
#
# Stages:
#   --gitconfig  home/dot_gitconfig.tmpl: rendered through an isolated chezmoi
#                init+apply into a scratch destination, then interrogated with
#                `git config --file` (spec01).
#   --surface    the census: home/ and home/dot_config/ hold only declared
#                entries, no settled exclusion reappears at any depth, one
#                source of truth per tool, and every deployed template is one
#                the TEMPLATES list names (spec02, amended by T.4).
#   --selftest   the counterfactual: plant an UNnamed template in a scratch
#                copy and prove the census goes red, then repair it and prove
#                it goes green. Never runs as part of --all.
#   (no arg)     --gitconfig and --surface.
#
# Assertions are content-based, never greps over the template. A grep over an
# ~78-column-wrapped file has produced false negatives repeatedly on this
# board; `git config --file <f> --get <key>` reads the PARSED value, which is
# also a free proof that the rendered file is valid git config syntax.
#
# SAFETY, in two halves, and neither is hypothetical. Doing the first and
# stopping is exactly what this file did until 2026-08-21, and it wrote the
# developer's real home on every run while reporting 0 FAIL.
#
# HALF 1 — **HOME does not isolate chezmoi.** A scratch-HOME `chezmoi init
# --force` once rewrote the real ~/.config/chezmoi/chezmoi.toml and repointed
# this machine's live source away from /Users/feb/dev/.files. It had to be
# restored by hand. So every invocation goes through `cz`, which carries
# --source, --destination, --config, --persistent-state and --cache (plus
# --config-path on `init`, which is init-only). Two mechanisms enforce that
# rather than asking:
#
#   1. Behavioural — guard_begin/guard_end (gates/lib.sh) record the live
#      config's sha256 and `chezmoi source-path` on entry and assert them
#      unchanged on exit, so a dropped flag turns the gate red on the DAMAGE.
#   2. Structural — lint_no_bare_chezmoi rejects a bare `chezmoi` in command
#      position in this file.
#
# HALF 2 — **those flags do not isolate $HOME.** They bound where chezmoi
# WRITES; they say nothing about the environment of a script chezmoi RUNS,
# which inherits the caller's $HOME. home/run_after_generate-shell-init.sh
# writes to a literal $HOME/.cache/nushell/init, so with an ambient HOME the
# `apply` below created a real ~/.cache/nushell/init/ holding 2280 / 1966 /
# 1809-byte files on every run. `cz` therefore pins HOME to the same directory
# it passes as --destination, and the real-path snapshot at the foot of this
# file asserts, before and after in the same run, that no real user path moved.
#
# The stage renders into a scratch destination and never into the real $HOME.
#
# Usage: bash tests/managed-config.sh [--gitconfig|--surface|--selftest]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one shared library. Sourced read-only; this script never writes it.
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

CHEZMOI="$(command -v chezmoi || true)"
GUARDED_CFG="${GATES_GUARD_CFG:-$HOME/.config/chezmoi/chezmoi.toml}"

# Seeded identity. Deliberately NOT the user's: the rendered user.email must
# equal this, which is only possible if the field is templated.
GATE_NAME="P5 Gate User"
GATE_MAIL="p5-gate@example.invalid"

# ── R2's declared surface. Editing one of these lists IS the decision. ──────
# SURFACE is R2's nine names, verbatim and in R2's order.
SURFACE="nushell nvim wezterm television starship.toml bat gh lazygit tinted-theming"
# Declared-pending, NOT part of R2's surface: plan.json schedules C.4 to write
# home/dot_config/capsule/recents.nuon — recents *state* rather than tool
# config, and a tenth directory under a surface R2 declares as nine. Listed
# separately so C.4 is not blocked by this gate; raised with the epic owner,
# not settled here.
SURFACE_PENDING="capsule"
# The home/ root. run_once_before_* (P.3) and run_after_* (P.4) are allowed by
# glob as well — they are chezmoi scripts, not deploy targets.
HOME_TOP=".chezmoiignore .chezmoi.toml.tmpl dot_config dot_gitconfig.tmpl"
# Settled exclusions. Each is DO NOT PORT or dropped by a recorded decision;
# this census catches them at ANY depth, which is where background.png sits.
FORBIDDEN="burrito wp-stat-overlay ponytail wallpapers background.png solo-window* dot_pi dot_assembly dot_bash_profile"
# Every deployed template, NAMED. A template is the exception this census
# exists to police, so the census does not count to one — it compares against
# this list, and editing this list IS the decision. Paths are relative to
# home/ and LC_ALL=C sorted, so the list compares directly against
# `find | LC_ALL=C sort` output. One reason per entry:
#   dot_config/television/cable/theme.toml.tmpl — S.9: television hands the
#     channel's `command` to $SHELL, and an absolute {{ .chezmoi.homeDir }}
#     path is the one form that runs identically under nu, bash and sh.
#     Recorded in prds/04-shell/09-theme-switcher/specs/spec03-tv-channel.md.
#   dot_gitconfig.tmpl — per-machine identity, {{ .name }} / {{ .email }}.
TEMPLATES="dot_config/television/cable/theme.toml.tmpl dot_gitconfig.tmpl"

# ── preamble: preconditions and the structural lint ─────────────────────────
[ -n "$CHEZMOI" ];      chk "precondition: chezmoi is on PATH" $?
[ -f "$GUARDED_CFG" ];  chk "precondition: the guarded config exists ($GUARDED_CFG)" $?
lint_no_bare_chezmoi "$SELF"; lint_rc=$?
chk "lint: no bare chezmoi in command position in $(basename "$SELF")" "$lint_rc"
if [ -z "$CHEZMOI" ] || [ ! -f "$GUARDED_CFG" ]; then exit 1; fi

# ── the real-user-path guard (SAFETY half 2, enforced) ──────────────────────
# Hashed here, asserted at the foot of the file: the same run, before and
# after. Unpin HOME in `cz` and this goes red on the damage itself.
#
# NOT $HOME/.config/nushell as a whole: that directory holds the live
# history.sqlite3-wal, which the developer's own interactive Nushell rewrites
# at any moment — observed changing mid-session with no gate running. Watching
# it makes the guard flaky for a reason no gate causes. .config/nushell/help is
# the subtree the managed tree deploys into, and it is stable.
snapshot_paths "$HOME/.cache/nushell" "$HOME/.cache/starship" \
               "$HOME/.cache/television" "$HOME/.zoxide.nu" \
               "$HOME/.config/nushell/help" "$HOME/.config/television" \
               "$HOME/.gitconfig"
SNAP_USER="$GATES_SNAP"

# Every real invocation goes through here. Five flags, every time — and HOME,
# pinned to the same directory --destination names. See SAFETY half 2 above:
# the flags bound where chezmoi writes; only HOME bounds what a run_ script
# chezmoi runs inherits. Unlike tests/deploy-skeleton.sh this file has ONE
# invocation site — it writes no PATH shim — so this is the whole pin.
cz() {
  local root="$1"; shift
  HOME="$root/dest" \
  "$CHEZMOI" \
    --source            "$root/src" \
    --destination       "$root/dest" \
    --config            "$root/chezmoi.toml" \
    --persistent-state  "$root/state.boltdb" \
    --cache             "$root/cache" \
    --no-tty "$@" < /dev/null
}

# Pre-seed [data] so promptStringOnce in home/.chezmoi.toml.tmpl never prompts
# (P.1's spec01 records why --promptDefaults and --promptString are both wrong).
seed_cfg() {
  cat > "$1" <<EOF
[data]
    name = "$GATE_NAME"
    email = "$GATE_MAIL"
EOF
}

# A copy of the working tree, not a clone: the gate tests the files as they
# are now, not as they were last committed.
copy_repo() { mkdir -p "$2"; cp -R "$REPO/." "$2/"; }

# ── the template census, once ───────────────────────────────────────────────
# tmpl_census <home-dir> walks every *.tmpl under a home/ directory and sets
# three globals:
#   TMPL_FOUND        every deployed template, relative to <home-dir>,
#                     LC_ALL=C sorted, space-separated — comparable to
#                     $TEMPLATES verbatim.
#   TMPL_UNNAMED      those $TEMPLATES does not name, at ANY depth.
#   TMPL_UNNAMED_CFG  the same, restricted to home/dot_config/.
#
# `.chezmoi*` and `run_*` are excluded because neither is a deploy target: the
# first is chezmoi metadata (P.1's .chezmoi.toml.tmpl), the second is a script
# chezmoi runs rather than a file it places (P.3's homebrew bootstrap is a
# run_once_before_install-homebrew.sh.tmpl). Without that exclusion this
# census would collide with a neighbouring lane doing its job right.
#
# Globals rather than a printed result, and this is not style: the body holds
# `case` statements, and macOS bash 3.2 mis-parses a `case` inside a command
# substitution and silently swallows the rest of the block. A function body
# parsed at top level is safe; `$(tmpl_census …)` would not have been.
tmpl_census() {
  local H="$1" e base rel
  TMPL_FOUND=""; TMPL_UNNAMED=""; TMPL_UNNAMED_CFG=""
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    base="$(basename "$e")"
    case "$base" in .chezmoi*|run_*) continue ;; esac
    rel="${e#"$H"/}"
    TMPL_FOUND="${TMPL_FOUND:+$TMPL_FOUND }$rel"
    case " $TEMPLATES " in *" $rel "*) continue ;; esac
    TMPL_UNNAMED="${TMPL_UNNAMED:+$TMPL_UNNAMED }$rel"
    case "$rel" in dot_config/*) TMPL_UNNAMED_CFG="${TMPL_UNNAMED_CFG:+$TMPL_UNNAMED_CFG }$rel" ;; esac
  done < <(find "$H" -name '*.tmpl' | LC_ALL=C sort)
}

# templates_ok <home-dir> — the two template clauses of the census as ONE
# predicate, so --selftest's counterfactual runs the same code the census
# runs rather than a paraphrase of it. The house reason for this shape is in
# gates/lib.sh beside chk_ok/chk_fail; tests/shell-television.sh and
# tests/nvim-completion.sh are the precedents.
templates_ok() {
  tmpl_census "$1"
  [ "$TMPL_FOUND" = "$TEMPLATES" ] && [ -z "$TMPL_UNNAMED_CFG" ]
}

# ── stage: --gitconfig ──────────────────────────────────────────────────────
stage_gitconfig() {
  echo "── stage --gitconfig: render the one templated file, then parse it ──"
  guard_begin "gitconfig"
  local S; S="$(mktemp -d "${TMPDIR:-/tmp}/p5-gitconfig.XXXXXX")"
  local TMPL="$REPO/home/dot_gitconfig.tmpl"

  [ -f "$TMPL" ]; chk "gitconfig: home/dot_gitconfig.tmpl exists" $?
  if [ ! -f "$TMPL" ]; then rm -rf "$S"; guard_end; return; fi

  grep -q '{{ \.name }}'  "$TMPL"; chk "gitconfig: template carries {{ .name }}" $?
  grep -q '{{ \.email }}' "$TMPL"; chk "gitconfig: template carries {{ .email }}" $?
  # The repo is published: a baked-in identity is a leak, and a hardcoded
  # value would also silently pass a render check.
  ! grep -qE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$TMPL"
  chk "gitconfig: no literal email address in the source template" $?

  copy_repo "$REPO" "$S/src"
  mkdir -p "$S/dest"
  seed_cfg "$S/chezmoi.toml"

  cz "$S" init --config-path "$S/chezmoi.toml" --force > "$S/init.log" 2>&1
  chk "gitconfig: isolated init succeeded (see $S/init.log)" $?
  cz "$S" apply --force > "$S/apply.log" 2>&1
  chk "gitconfig: isolated apply succeeded (see $S/apply.log)" $?

  local R="$S/dest/.gitconfig"
  [ -f "$R" ]; chk "gitconfig: rendered <dest>/.gitconfig exists" $?
  if [ ! -f "$R" ]; then rm -rf "$S"; guard_end; return; fi

  ! grep -q '{{' "$R"; chk "gitconfig: rendered file has no unrendered {{" $?
  git config --file "$R" --list > /dev/null 2>&1
  chk "gitconfig: rendered file parses (git config --file --list exits 0)" $?

  # The identity is templated, not constant: it must be the SEEDED value.
  local got
  got="$(git config --file "$R" --get user.name 2>/dev/null)"
  [ "$got" = "$GATE_NAME" ]; chk "gitconfig: user.name comes from template data (got: ${got:-<unset>})" $?
  got="$(git config --file "$R" --get user.email 2>/dev/null)"
  [ "$got" = "$GATE_MAIL" ]; chk "gitconfig: user.email = $GATE_MAIL (got: ${got:-<unset>})" $?

  # ── the key table: parsed values, one check per key ──────────────────────
  # delta.syntax-theme = ansi is asserted DELIBERATELY. It is the epic-wide
  # palette rule in one line: "ansi" maps tokens onto the terminal's 16 ANSI
  # slots, so delta follows whatever palette tinty applied. A named theme here
  # hardcodes a palette downstream of the terminal, which the contract forbids
  # and decisions/tinty makes load-bearing. Do not "fix" it.
  local key want have
  while IFS='|' read -r key want; do
    [ -n "$key" ] || continue
    have="$(git config --file "$R" --get "$key" 2>/dev/null)"
    [ "$have" = "$want" ]; chk "gitconfig: $key = $want (got: ${have:-<unset>})" $?
  done <<'KEYS'
init.defaultBranch|main
core.pager|delta
core.autocrlf|input
interactive.diffFilter|delta --color-only
delta.navigate|true
delta.line-numbers|true
delta.side-by-side|false
delta.syntax-theme|ansi
delta.line-numbers-minus-style|red
delta.line-numbers-plus-style|green
delta.file-style|bold
delta.hunk-header-style|blue bold
merge.conflictStyle|zdiff3
diff.colorMoved|default
diff.algorithm|histogram
pull.rebase|true
push.autoSetupRemote|true
push.default|current
fetch.prune|true
rebase.autoStash|true
rebase.autoSquash|true
column.ui|auto
branch.sort|-committerdate
alias.s|status -sb
alias.co|checkout
alias.sw|switch
alias.br|branch
alias.cm|commit -m
alias.ca|commit --amend
alias.can|commit --amend --no-edit
alias.unstage|restore --staged
alias.last|log -1 HEAD --stat
alias.undo|reset --soft HEAD~1
alias.wip|!git add -A && git commit -m 'wip'
alias.aliases|config --get-regexp ^alias\.
KEYS

  # ── the gh credential reset ──────────────────────────────────────────────
  # Each helper list must read back as exactly two values: an EMPTY one, then
  # `!gh auth git-credential`. The empty first value is load-bearing, not
  # noise: it resets the inherited helper list for these two URLs only, so the
  # system helper (osxkeychain on this host) cannot answer for github.com with
  # a token cached for another account, and gh's *active* account wins. Every
  # other host still gets osxkeychain. Asserting the two VALUES, not the two
  # words, proves the reset survived rendering.
  local want_helpers; want_helpers="$(printf '%s\n%s\n' '' '!gh auth git-credential')"
  local h
  for h in "https://github.com" "https://gist.github.com"; do
    have="$(git config --file "$R" --get-all "credential.$h.helper" 2>/dev/null)"
    [ "$have" = "$want_helpers" ]
    chk "gitconfig: credential.$h.helper is [\"\", \"!gh auth git-credential\"]" $?
  done

  # alias.lg — the --format=format:'…' string, quoting intact through both
  # chezmoi's renderer and git's own quote handling.
  local lg_want lg_have
  lg_want="log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) %C(dim white)%an%C(reset) %C(green)(%ar)%C(reset)%C(auto)%d%C(reset)%n          %s'"
  lg_have="$(git config --file "$R" --get alias.lg 2>/dev/null)"
  [ "$lg_have" = "$lg_want" ]; chk "gitconfig: alias.lg format string survives rendering intact" $?

  # ── the pi includeIf is not carried across ───────────────────────────────
  # ~/dev/_pi_extensions does not exist; the installer that created it was
  # removed from the live source by 8fe3a71; and its path targets a `git`
  # directory that is not one of R2's nine names. Nothing is deleted — the
  # included file is simply unmanaged and stops being included.
  [ -z "$(git config --file "$R" --get-regexp '^includeif\.' 2>/dev/null)" ]
  chk "gitconfig: rendered file declares no includeIf section" $?
  ! grep -q '_pi_extensions' "$R"; chk "gitconfig: rendered file never mentions _pi_extensions" $?
  [ ! -e "$REPO/home/dot_config/git" ]; chk "gitconfig: home/dot_config/git/ does not exist in the managed tree" $?

  rm -rf "$S"
  guard_end
}

# ── stage: --surface ────────────────────────────────────────────────────────
# Pure filesystem census: no chezmoi call, so no guard is needed here
# (guard_begin/guard_end bracket --gitconfig, which applies). The census is
# ONE-DIRECTIONAL by design: it asserts no UNDECLARED entry exists, never that
# every declared entry exists. Eight of R2's nine belong to tracks that have
# not landed, so a census demanding all nine would be red until the last track
# closes — noise rather than a gate.
#
# Every check compares path NAMES, exactly. No prose greps.
stage_surface() {
  echo "── stage --surface: the managed surface is the declared surface ─────"
  local H="$REPO/home"

  if [ ! -d "$H" ]; then chk "surface: home/ exists" 1; return; fi

  local e n undeclared

  # 1. home/ holds only declared entries. Catches a wholesale port of the live
  #    source's root (dot_assembly, dot_bash_profile, dot_local, dot_pi,
  #    empty_dot_hushlogin, wallpapers/).
  undeclared=""
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    case " $HOME_TOP " in *" $e "*) continue ;; esac
    case "$e" in run_once_before_*|run_after_*) continue ;; esac
    undeclared="$undeclared $e"
  done < <(find "$H" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort)
  [ -z "$undeclared" ]
  chk "surface: home/ holds only declared entries (undeclared:${undeclared:- <none>})" $?

  # 2. home/dot_config/ holds only declared tools.
  undeclared=""
  if [ -d "$H/dot_config" ]; then
    while IFS= read -r e; do
      [ -n "$e" ] || continue
      case " $SURFACE $SURFACE_PENDING " in *" $e "*) continue ;; esac
      undeclared="$undeclared $e"
    done < <(find "$H/dot_config" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort)
  fi
  [ -z "$undeclared" ]
  chk "surface: home/dot_config/ holds only declared tools (undeclared:${undeclared:- <none>})" $?

  # 3. Settled exclusions never reappear ANYWHERE under home/. Overlaps 1 and
  #    2 on purpose: those police the two levels the surface is declared at,
  #    this catches the same artefact three levels down — which is exactly
  #    where wezterm/background.png sits.
  local found="" forbidden_a=()
  # read -a, not word splitting: `solo-window*` must stay a find pattern
  # rather than being glob-expanded against the caller's cwd.
  IFS=' ' read -r -a forbidden_a <<< "$FORBIDDEN"
  for n in "${forbidden_a[@]}"; do
    if [ -n "$(find "$H" -name "$n" -print -quit 2>/dev/null)" ]; then found="$found $n"; fi
  done
  [ -z "$found" ]
  chk "surface: no DO NOT PORT / dropped artefact under home/ (found:${found:- <none>})" $?

  # 4. One source of truth: each declared name resolves to at most one path.
  local dupes="" cnt declared_a=()
  IFS=' ' read -r -a declared_a <<< "$SURFACE $SURFACE_PENDING"
  for n in "${declared_a[@]}"; do
    cnt="$(find "$H" -name "$n" | wc -l | tr -d ' ')"
    if [ "$cnt" -gt 1 ]; then dupes="$dupes $n($cnt)"; fi
  done
  [ -z "$dupes" ]
  chk "surface: each declared tool has exactly one path under home/ (dupes:${dupes:- <none>})" $?

  # 5. The deployed templates are exactly the ones TEMPLATES names — a named
  #    set, not a count. Bidirectional on purpose: both named templates exist
  #    on disk today, so a named template that DISAPPEARS is a real regression
  #    and must be red too. The walk and its exclusions live in tmpl_census.
  tmpl_census "$H"
  [ "$TMPL_FOUND" = "$TEMPLATES" ]
  chk "surface: deployed templates are exactly the TEMPLATES set (want: $TEMPLATES / got: ${TMPL_FOUND:-<none>})" $?

  # 6. Every template under home/dot_config/ is one TEMPLATES names — a
  #    per-tool config that needs template data is the exception this census
  #    polices, and it fails on the file's existence rather than waiting for a
  #    render. Deliberately NOT a per-directory allowance
  #    (`television/**.tmpl` and friends): the premise being kept is that each
  #    template is NAMED, not that some directories may template freely. The
  #    FAIL line names the offender so the next agent finds TEMPLATES from it.
  [ -z "$TMPL_UNNAMED_CFG" ]
  chk "surface: every template under home/dot_config/ is named in TEMPLATES (unnamed: ${TMPL_UNNAMED_CFG:-<none>})" $?
}

# ── stage: --selftest ───────────────────────────────────────────────────────
# The contract gates/selftest.sh defines, both halves, run against a
# scratch_tree copy under gates_tmpdir — which cleans itself up on exit. The
# real tree is never written, and no chezmoi call happens here, so no guard is
# needed. Additive: --gitconfig, --surface and the no-argument --all behave
# exactly as they did, so gates/waves.tsv (which runs this file with no
# argument) is untouched.
stage_selftest() {
  echo "── stage --selftest: the template census still has teeth ────────────"
  local T S
  T="$(gates_tmpdir)"; S="$T/managed-config"
  scratch_tree "$S" > /dev/null
  echo "      MUTATION HOST: $S (a scratch_tree copy; the real tree is never written)"

  # RED — an UNnamed template must turn the census red. This is the half that
  # proves admitting theme.toml.tmpl to TEMPLATES did not buy the pass by
  # loosening the check.
  mkdir -p "$S/home/dot_config/foo"
  printf '# planted by --selftest: a template TEMPLATES does not name\n' \
    > "$S/home/dot_config/foo/bar.tmpl"
  echo "      MUTATION: planted home/dot_config/foo/bar.tmpl in the copy"
  chk_fail "selftest red: an unnamed home/dot_config/foo/bar.tmpl turns the census red" \
    templates_ok "$S/home"
  tmpl_census "$S/home"
  echo "      mutated copy: unnamed under dot_config/ = ${TMPL_UNNAMED_CFG:-<none>}"

  # GREEN — the same copy with the mutation removed. A gate that only proves
  # it can fail has not proved it can pass.
  rm -rf "$S/home/dot_config/foo"
  echo "      MUTATION: removed the planted template again (the green counterfactual)"
  chk_ok "selftest green: the unmutated copy passes the census" \
    templates_ok "$S/home"
  tmpl_census "$S/home"
  echo "      unmutated copy: found = ${TMPL_FOUND:-<none>}"

  [ ! -e "$REPO/home/dot_config/foo" ]
  chk "selftest: the real home/dot_config/foo was never created" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --gitconfig) stage_gitconfig ;;
  --surface)   stage_surface ;;
  --selftest)  stage_selftest ;;
  --all)       stage_gitconfig; echo; stage_surface ;;
  *) echo "usage: bash tests/managed-config.sh [--gitconfig|--surface|--selftest]"; exit 2 ;;
esac

echo
GATES_SNAP="$SNAP_USER"
assert_unchanged "the gate touched no REAL user path (~/.cache/{nushell,starship,television}, ~/.zoxide.nu, ~/.config/{nushell/help,television}, ~/.gitconfig)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the managed surface is the declared surface, and the live chezmoi config was never touched"
else echo "FAIL — a check above is red"; fi
exit "$rc"
