#!/bin/bash
# Covers: the litellm model launcher — home/dot_config/nushell/litellm.nu, its
# source line at config.nu's MODULES anchor, the five executables under
# home/dot_local/bin, and home/dot_config/litellm/config.yaml.
#
# Stages:
#   --tree      the managed files as TEXT: the source line under MODULES and
#               below claude.nu, the defs litellm.nu must declare, the absence
#               of fzf (the picker is `input list --fuzzy`, per 04-shell I3),
#               and the routing invariants of config.yaml — every alias has a
#               deployment, every fallback target exists, and no secret is
#               baked in. Absence claims carry a counterfactual.
#   --hermetic  a REAL nushell parses litellm.nu with an isolated HOME and
#               stub `cll`/`llm-quota` first on PATH, proving `llm` renders
#               the catalogue and `cll <model>` forwards without a picker.
#   (no arg)    both.
#
# NO --apply STAGE: these files ride the same deploy path as claude.nu, which
# S.1's gate already proves deploys byte-identical through a real apply.
#
# SAFETY — tests/nushell-core.sh's rules, followed: /usr/bin/grep always
# (plain `grep` is ugrep here); scratch machines under this gate's own tmpdir,
# never the live ~/.config/nushell; `env -i` with an explicit PATH on every
# `nu`; nothing installed, live tree untouched.
#
# Usage: bash tests/shell-litellm.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
rc=0
PASS_N=0
FAIL_N=0
chk() {
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; PASS_N=$((PASS_N + 1))
  else echo "FAIL  $1"; FAIL_N=$((FAIL_N + 1)); rc=1; fi
}

NU_MOD="$REPO/home/dot_config/nushell/litellm.nu"
CONFIG_NU="$REPO/home/dot_config/nushell/config.nu"
YAML="$REPO/home/dot_config/litellm/config.yaml"
BIN="$REPO/home/dot_local/bin"

stage_tree() {
  echo "── tree ──"

  chk "litellm.nu exists" "$([ -f "$NU_MOD" ]; echo $?)"
  chk "config.yaml exists" "$([ -f "$YAML" ]; echo $?)"
  for f in cll litellm-env litellm-up litellm-gen-config llm-quota; do
    chk "bin/$f is managed executable" "$([ -f "$BIN/executable_$f" ]; echo $?)"
  done

  # The source line exists, sits under the MODULES anchor, and below claude.nu:
  # litellm.nu declares `cll` beside cc/cr and must not parse above them.
  local l_anchor l_claude l_litellm
  l_anchor=$($GREP -n '^# ── MODULES ──' "$CONFIG_NU" | head -1 | cut -d: -f1)
  l_claude=$($GREP -n '^source ~/.config/nushell/claude.nu$' "$CONFIG_NU" | head -1 | cut -d: -f1)
  l_litellm=$($GREP -n '^source ~/.config/nushell/litellm.nu$' "$CONFIG_NU" | head -1 | cut -d: -f1)
  chk "config.nu sources litellm.nu" "$([ -n "$l_litellm" ]; echo $?)"
  chk "source line is below the MODULES anchor" \
    "$([ -n "$l_litellm" ] && [ -n "$l_anchor" ] && [ "$l_litellm" -gt "$l_anchor" ]; echo $?)"
  chk "source line is below claude.nu" \
    "$([ -n "$l_litellm" ] && [ -n "$l_claude" ] && [ "$l_litellm" -gt "$l_claude" ]; echo $?)"

  # Counterfactual: the ordering check must FAIL on a copy with the lines swapped.
  local cf; cf=$(mktemp)
  sed 's|^source ~/.config/nushell/litellm.nu$|@@MOVED@@|' "$CONFIG_NU" \
    | sed "s|^# ── MODULES ──|source ~/.config/nushell/litellm.nu\n# ── MODULES ──|" > "$cf"
  local cf_anchor cf_litellm
  cf_anchor=$($GREP -n '^# ── MODULES ──' "$cf" | head -1 | cut -d: -f1)
  cf_litellm=$($GREP -n '^source ~/.config/nushell/litellm.nu$' "$cf" | head -1 | cut -d: -f1)
  chk "counterfactual: source above the anchor is caught" \
    "$([ "$cf_litellm" -lt "$cf_anchor" ]; echo $?)"
  rm -f "$cf"

  # The defs the module contracts to provide.
  for d in '_llm_rows' '_cll_models' 'cll' 'llm' '"llm quota"' '"llm regen"'; do
    chk "litellm.nu declares def $d" \
      "$($GREP -qE "^def (--wrapped )?$d " "$NU_MOD"; echo $?)"
  done

  # 04-shell I3, as amended 2026-08-25: fzf is the picker here, the SECOND
  # named exception to "tv owns every picker screen", recorded in
  # 00-delivery/decisions/fzf-model-picker. So the assertion is that fzf IS
  # used — and used with the flags that make it behave.
  code_has_fzf() { $GREP -vE '^[[:space:]]*#' "$1" | $GREP -qi 'fzf'; }
  chk "cll's picker is fzf" "$(code_has_fzf "$BIN/executable_cll"; echo $?)"

  # --nth=1, never 2. --with-nth re-indexes the fields, so --nth counts against
  # the TRANSFORMED line where the name is field 1; --nth=2 searched the chain
  # column and `opus` matched nothing (measured, fzf 0.74.3). This check is the
  # regression guard for exactly that.
  chk "picker searches the name column (--nth=1)" \
    "$($GREP -q -- '--nth=1' "$BIN/executable_cll"; echo $?)"
  chk "picker returns the bare key (--accept-nth=1)" \
    "$($GREP -q -- '--accept-nth=1' "$BIN/executable_cll"; echo $?)"
  chk "picker enables ANSI for the group/detail weights" \
    "$($GREP -q -- '--ansi' "$BIN/executable_cll"; echo $?)"
  chk "header rows use a re-open sentinel" \
    "$($GREP -q '__hdr__' "$BIN/executable_cll"; echo $?)"
  # Counterfactual: the --nth guard must FAIL on a copy that regresses to 2.
  local cf2; cf2=$(mktemp)
  sed 's/--nth=1/--nth=2/' "$BIN/executable_cll" > "$cf2"
  chk "counterfactual: a --nth regression is caught" \
    "$($GREP -q -- '--nth=1' "$cf2" && echo 1 || echo 0)"
  rm -f "$cf2"

  # Every row carries its own provider column: fzf drops non-matching lines, so
  # a group header cannot stay pinned above its group once a query is typed.
  # Without the column, filtering to "opus" loses which router each row is from.
  chk "picker rows carry a per-row provider column" \
    "$($GREP -q 'p:<{pwidth}' "$BIN/executable_cll"; echo $?)"

  # R13: launch with --dangerously-skip-permissions, as cc/cr do. The flag is
  # on the proxied exec and the native no-TTY fallback; the TTY branch gets it
  # from _claude_run via cc, so it needn't carry its own copy.
  chk "cll launches claude with --dangerously-skip-permissions" \
    "$($GREP -q -- '--dangerously-skip-permissions' "$BIN/executable_cll"; echo $?)"
  # Counterfactual: the flag check must FAIL on a copy that drops it. Comments
  # stripped first — the header comment names the flag, and naming it there
  # must not read as passing it.
  local cf4; cf4=$(mktemp)
  $GREP -vE '^[[:space:]]*#' "$BIN/executable_cll" \
    | sed 's/--dangerously-skip-permissions //g' > "$cf4"
  chk "counterfactual: dropping the skip-permissions flag is caught" \
    "$($GREP -q -- '--dangerously-skip-permissions' "$cf4" && echo 1 || echo 0)"
  rm -f "$cf4"

  # R4: the native hop must unset inherited proxy env, not merely not-set it —
  # launched from inside a cll session the parent exports ANTHROPIC_BASE_URL
  # and an inherited pair would route the "native" hop through the proxy.
  chk "native hop unsets inherited proxy env" \
    "$($GREP -q 'unset ANTHROPIC_BASE_URL' "$BIN/executable_cll"; echo $?)"
  # R4: on a TTY the native hop is cc's job — login picker, _claude_run launch.
  # One implementation of "launch Claude on a login", not two.
  chk "native hop delegates to cc's login machinery" \
    "$($GREP -q 'CLL_NATIVE_MODEL' "$BIN/executable_cll" && \
        $GREP -q 'source ~/.config/nushell/config.nu' "$BIN/executable_cll"; echo $?)"

  # The nushell module must NOT carry a second picker — one implementation,
  # in the script, is what keeps a stale shell from reaching an untested path.
  chk "litellm.nu holds no picker of its own" \
    "$($GREP -qE 'input list|fzf' <($GREP -vE '^[[:space:]]*#' "$NU_MOD") && echo 1 || echo 0)"

  # bash 3.2 ONLY. macOS ships /bin/bash 3.2.57 and this machine has no newer
  # one, so a bash-4 builtin is a runtime failure, not a portability nicety:
  # `mapfile` in cll's no-argument picker shipped once and died as
  # "mapfile: command not found" the first time anyone ran the picker from a
  # non-nu shell. Every construct below is bash-4-or-later.
  # Code only, for the same reason the fzf check strips comments: cll's comment
  # explains WHY mapfile is absent, and naming it there must not read as using it.
  code_has_bash4() {
    $GREP -vE '^[[:space:]]*#' "$1" \
      | $GREP -qE '(^|[^[:alnum:]_])(mapfile|readarray)[[:space:]]|declare -A|local -A|\$\{[A-Za-z_]+\^\^|\$\{[A-Za-z_]+,,'
  }
  for f in cll litellm-env litellm-up; do
    chk "bin/$f uses no bash-4 builtin" "$(code_has_bash4 "$BIN/executable_$f" && echo 1 || echo 0)"
  done
  # Counterfactual: the bash-4 check must FAIL on a copy that calls mapfile.
  local cf3; cf3=$(mktemp); cat "$BIN/executable_cll" > "$cf3"
  echo 'mapfile -t X < <(echo hi)' >> "$cf3"
  chk "counterfactual: a mapfile call is caught" "$(code_has_bash4 "$cf3" && echo 0 || echo 1)"
  rm -f "$cf3"

  # No secret may be committed: keys are read at runtime from pi's auth.json.
  chk "config.yaml bakes in no api key" \
    "$($GREP -qE 'sk-or-v1-|sk-ai-[A-Za-z0-9]|api_key: sk-' "$YAML" && echo 1 || echo 0)"
  chk "config.yaml reads keys from the environment" \
    "$($GREP -q 'os.environ/' "$YAML"; echo $?)"

  # Routing invariants: every fallback target must be a declared model_name,
  # or the router silently drops the hop at request time rather than at load.
  python3 - "$YAML" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
names = set(re.findall(r'^\s*-\s*model_name:\s*(\S+)', text, re.M))
fb = re.findall(r'^\s{4}-\s*(\S+):\s*\[([^\]]*)\]', text, re.M)
missing_src = [s for s, _ in fb if s not in names]
missing_dst = sorted({t.strip() for _, ts in fb for t in ts.split(',') if t.strip() and t.strip() not in names})
print("PASS  every fallback source is a declared model_name" if not missing_src
      else f"FAIL  fallback sources not declared: {missing_src}")
print("PASS  every fallback target is a declared model_name" if not missing_dst
      else f"FAIL  fallback targets not declared: {missing_dst}")
print(f"PASS  config declares {len(names)} routes" if names else "FAIL  no routes declared")
sys.exit(1 if (missing_src or missing_dst or not names) else 0)
PY
  chk "config.yaml routing invariants" "$?"
}

stage_hermetic() {
  echo "── hermetic ──"
  local T; T=$(mktemp -d); local H="$T/home"
  mkdir -p "$H/.config/nushell" "$T/bin"
  cp "$NU_MOD" "$H/.config/nushell/litellm.nu"

  # Stubs: cll records its argv; llm-quota answers with a fixed balance so the
  # decorated table is deterministic.
  cat > "$T/bin/cll" <<'EOF'
#!/bin/bash
if [ "$1" = "--catalog" ]; then
  echo '[{"name":"native:opus","providers":["max-plan"],"kind":"native"},{"name":"opus-5","providers":["zenmux","openrouter"],"kind":"proxy"}]'
  exit 0
fi
echo "$@" >> "$CLL_LOG"
EOF
  cat > "$T/bin/llm-quota" <<'EOF'
#!/bin/bash
echo '{"zenmux":{"remaining":42.5,"unit":"credits"},"openrouter":{"remaining":-0.22,"unit":"credits"}}'
EOF
  chmod +x "$T/bin/cll" "$T/bin/llm-quota"

  local NU; NU=$(command -v nu)
  if [ -z "$NU" ]; then echo "SKIP  nushell not installed"; rm -rf "$T"; return; fi

  local out
  out=$(/usr/bin/env -i HOME="$H" PATH="$T/bin:/usr/bin:/bin" CLL_LOG="$T/log" \
        "$NU" --no-config-file -c \
        'source ~/.config/nushell/litellm.nu; llm | to json -r' 2>&1)
  chk "module parses and llm returns rows" "$(echo "$out" | $GREP -q '"model"' ; echo $?)"
  chk "llm attributes a model to its provider chain" \
    "$(echo "$out" | $GREP -q 'zenmux → openrouter'; echo $?)"
  chk "llm carries the provider balance" "$(echo "$out" | $GREP -q '42.5'; echo $?)"
  chk "native rows are labelled as plan-served" "$(echo "$out" | $GREP -q '"plan"'; echo $?)"

  /usr/bin/env -i HOME="$H" PATH="$T/bin:/usr/bin:/bin" CLL_LOG="$T/log" \
    "$NU" --no-config-file -c \
    'source ~/.config/nushell/litellm.nu; cll opus-5 --print' >/dev/null 2>&1
  chk "cll <model> forwards to the launcher without a picker" \
    "$([ -f "$T/log" ] && $GREP -q 'opus-5 --print' "$T/log"; echo $?)"

  rm -rf "$T"
}

case "${1:-}" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *)          echo "usage: bash tests/shell-litellm.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── $PASS_N passed, $FAIL_N failed ──"
exit $rc
