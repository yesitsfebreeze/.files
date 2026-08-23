#!/bin/bash
# Covers: 01-capsule/02-dev-image (task C.1) — the standing proof for
# home/dot_config/capsule/Dockerfile, the one capsule image definition.
#
# Stages:
#   --static  hermetic. Parses the Dockerfile: single definition, closed
#             toolbox (R7), dropped-toolchain guard, layer order (R6), no
#             pinned architecture, no COPY/ADD ingress. No docker, no
#             network. Five selftest mutations run on every invocation —
#             a check that cannot fail proves nothing.
#   --build   real. Requires docker CLI + running daemon + network. Builds
#             the image, runs spec01's runtime probes, and proves the R6
#             cache contract: a config-layer edit reuses every earlier
#             layer, and the same edit forced into the apt layer diverges
#             an early digest. Docker absent or the daemon unreachable is a
#             FAIL naming the assumption, never a skip — this stage green
#             must mean the image was built.
#   (no arg)  both.
#
# Usage: bash tests/dev-image.sh [--static|--build]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one shared library. Sourced read-only; this script never writes it.
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

DOCKERFILE="$REPO/home/dot_config/capsule/Dockerfile"
SCRATCH="$(gates_tmpdir)"

# R7 written LITERALLY: R2's apt names, the support set, NodeSource's nodejs.
# The toolbox changing without this line changing turns the gate red.
APT_ALLOWED="ripgrep fd-find fzf tmux neovim bat git build-essential python3 python3-pip zsh curl ca-certificates sudo openssh-client nodejs"
NPM_ALLOWED="@anthropic-ai/claude-code"
# spec01's 13-tool runtime probe. node is probed separately via --version.
PATH_TOOLS="rg fd fzf tmux nvim bat eza git cc python3 zsh claude opencode"

# ── flattening ──────────────────────────────────────────────────────────────
# One line per instruction: strip full-line comments and blanks, join
# backslash continuations, absorb heredoc bodies into their RUN line. Every
# static check parses this form, so a rule cannot be dodged by wrapping.
flatten() {
  awk '
    function flush() { if (buf != "") print buf; buf = "" }
    BEGIN { inhd = 0; hd = ""; buf = "" }
    {
      sub(/\r$/, "")
      if (inhd) { buf = buf " " $0; if ($0 == hd) inhd = 0; next }
      if (buf == "" && ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/)) next
      buf = (buf == "" ? $0 : buf " " $0)
      if (buf ~ /\\$/) { sub(/\\$/, "", buf); next }
      if (match($0, /<<-?['\''"]?[A-Za-z_][A-Za-z0-9_]*/)) {
        hd = substr($0, RSTART, RLENGTH)
        sub(/<<-?/, "", hd); gsub(/['\''"]/, "", hd)
        inhd = 1
        next
      }
      flush()
    }
    END { flush() }
  ' "$1"
}

# First line number in $1 matching ERE $2; empty when absent.
idxof() { grep -nE "$2" "$1" | head -1 | cut -d: -f1; }
# ord <label> <a> <b> — PASS when both present and a < b.
ord() {
  if [ -n "$2" ] && [ -n "$3" ] && [ "$2" -lt "$3" ]; then
    chk "$1 ($2 < $3)" 0
  else
    chk "$1 (${2:-none} < ${3:-none})" 1
  fi
}

# ── the content checks, against a FLATTENED definition ──────────────────────
# Called for the real Dockerfile and, in a subshell, for every mutated
# scratch copy. The repo-wide census lives in stage_static, not here.
static_core() {
  local flat="$1" p hits

  chk_ok "static: flattened definition is non-empty" test -s "$flat"

  # ── closed toolbox (R7): the apt set equals APT_ALLOWED exactly ──────────
  local pkgs extra="" missing=""
  pkgs="$(awk '
    /^RUN/ {
      n = split($0, seg, /&&/)
      for (i = 1; i <= n; i++) {
        if (seg[i] !~ /apt-get +install/) continue
        t = split(seg[i], w, /[ \t]+/)
        on = 0
        for (j = 1; j <= t; j++) {
          if (on && w[j] != "" && w[j] !~ /^-/) print w[j]
          if (w[j] == "install") on = 1
        }
      }
    }' "$flat" | LC_ALL=C sort -u)"
  for p in $pkgs; do
    case " $APT_ALLOWED " in *" $p "*) ;; *) extra="$extra $p" ;; esac
  done
  for p in $APT_ALLOWED; do
    printf '%s\n' "$pkgs" | grep -qx "$p" || missing="$missing $p"
  done
  if [ -z "$extra" ] && [ -z "$missing" ]; then
    chk "static: apt set equals R2 + support set + nodejs (R7)" 0
  else
    chk "static: apt set equals R2 + support set + nodejs (R7) — extra:${extra:- none} missing:${missing:- none}" 1
  fi

  # npm installs exactly the one agent.
  local npkgs
  npkgs="$(awk '
    /^RUN/ {
      n = split($0, seg, /&&/)
      for (i = 1; i <= n; i++) {
        if (seg[i] !~ /npm +install/) continue
        t = split(seg[i], w, /[ \t]+/)
        on = 0
        for (j = 1; j <= t; j++) {
          if (on && w[j] != "" && w[j] !~ /^-/) print w[j]
          if (w[j] == "install") on = 1
        }
      }
    }' "$flat" | LC_ALL=C sort -u)"
  if [ "$npkgs" = "$NPM_ALLOWED" ]; then
    chk "static: npm install -g installs exactly $NPM_ALLOWED (R7)" 0
  else
    chk "static: npm install -g installs exactly $NPM_ALLOWED (got: ${npkgs:-nothing})" 1
  fi

  # ── dropped toolchains stay dropped (PRD ## Decisions) ───────────────────
  hits="$(grep -inE 'odin|pi-oilrig|pi-coding-agent' "$flat" || true)"
  if [ -z "$hits" ]; then
    chk "static: odin / pi-oilrig / pi-coding-agent appear nowhere" 0
  else
    printf '%s\n' "$hits" | sed 's/^/      /'
    chk "static: odin / pi-oilrig / pi-coding-agent appear nowhere" 1
  fi

  # ── layer order (R6) ─────────────────────────────────────────────────────
  local i_apt i_node i_npm i_oc i_user i_zshrc i_lastrun i_userd i_wd i_cmd
  i_apt="$(idxof "$flat" '^RUN .*apt-get [^&]*install .*ripgrep')"
  i_node="$(idxof "$flat" '^RUN .*setup_lts')"
  i_npm="$(idxof "$flat" '^RUN .*npm +install')"
  i_oc="$(idxof "$flat" '^RUN .*opencode')"
  i_user="$(idxof "$flat" '^RUN .*useradd')"
  i_zshrc="$(idxof "$flat" '^RUN .*\.zshrc')"
  i_lastrun="$(grep -nE '^RUN' "$flat" | tail -1 | cut -d: -f1)"
  ord "static: apt toolbox RUN precedes the Node RUN"       "$i_apt"  "$i_node"
  ord "static: Node RUN precedes the claude-code RUN"       "$i_node" "$i_npm"
  ord "static: Node RUN precedes the opencode RUN"          "$i_node" "$i_oc"
  ord "static: claude-code RUN precedes useradd"            "$i_npm"  "$i_user"
  ord "static: opencode RUN precedes useradd"               "$i_oc"   "$i_user"
  ord "static: useradd precedes the .zshrc config layer"    "$i_user" "$i_zshrc"
  if [ -n "$i_zshrc" ] && [ "$i_zshrc" = "$i_lastrun" ]; then
    chk "static: the .zshrc config layer is the final RUN" 0
  else
    chk "static: the .zshrc config layer is the final RUN (zshrc ${i_zshrc:-none}, last RUN ${i_lastrun:-none})" 1
  fi
  i_userd="$(idxof "$flat" '^USER +dev$')"
  i_wd="$(idxof "$flat" '^WORKDIR +/workspace$')"
  i_cmd="$(idxof "$flat" '^CMD +\["sleep", *"infinity"\] *$')"
  ord "static: USER dev follows every RUN"                  "$i_lastrun" "$i_userd"
  ord "static: WORKDIR /workspace follows every RUN"        "$i_lastrun" "$i_wd"
  ord "static: CMD [\"sleep\", \"infinity\"] follows every RUN" "$i_lastrun" "$i_cmd"

  # ── no pinned architecture ───────────────────────────────────────────────
  # Split each instruction on && ; an arch token may live only in a segment
  # that derives it from uname -m. A literal in a fetch URL lands here.
  hits="$(awk '
    {
      n = split($0, seg, /&&/)
      for (i = 1; i <= n; i++) {
        low = tolower(seg[i])
        if (low ~ /x86_64|amd64|aarch64|arm64/ && low !~ /uname -m/)
          printf "%d: %s\n", NR, seg[i]
      }
    }' "$flat")"
  if [ -z "$hits" ]; then
    chk "static: no arch literal outside a 'uname -m' derivation" 0
  else
    printf '%s\n' "$hits" | sed 's/^/      /'
    chk "static: no arch literal outside a 'uname -m' derivation" 1
  fi

  # ── no ingress: nothing from the host can enter a layer (C.3 R5) ─────────
  hits="$(grep -nE '^(COPY|ADD)[ \t]' "$flat" || true)"
  if [ -z "$hits" ]; then
    chk "static: no COPY, no ADD — the build context stays empty" 0
  else
    printf '%s\n' "$hits" | sed 's/^/      /'
    chk "static: no COPY, no ADD — the build context stays empty" 1
  fi
}

# Run static_core against a mutated copy in a subshell and require it to go
# red; surface the inner FAIL lines so the violated rule is named.
cf_static() {
  local label="$1" f="$2" out st
  out="$( rc=0; static_core "$f" 2>&1; exit $rc )"; st=$?
  printf '%s\n' "$out" | grep '^FAIL' | sed 's/^/      /'
  if [ "$st" -ne 0 ]; then chk "$label" 0; else chk "$label" 1; fi
}

# ════════════════════════════════════════════════════════════════════════════
# stage --static
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage: static"

  chk_ok "static: Dockerfile exists at home/dot_config/capsule/Dockerfile" \
         test -f "$DOCKERFILE"
  [ -f "$DOCKERFILE" ] || return

  # ── single definition ────────────────────────────────────────────────────
  # Prose ABOUT the Dockerfile (the specs, this PRD tree) is excluded by
  # -name '*.md': a markdown file builds nothing.
  local found
  found="$(cd "$REPO" && find . -iname '*dockerfile*' -not -path './.git/*' \
             ! -name '*.md' | LC_ALL=C sort)"
  if [ "$found" = "./home/dot_config/capsule/Dockerfile" ]; then
    chk "static: exactly one Dockerfile in the repo, at the expected path" 0
  else
    printf '%s\n' "$found" | sed 's/^/      /'
    chk "static: exactly one Dockerfile in the repo, at the expected path" 1
  fi

  local FLAT="$SCRATCH/Dockerfile.flat"
  flatten "$DOCKERFILE" > "$FLAT"
  static_core "$FLAT"

  # ── selftests, every invocation ──────────────────────────────────────────
  echo "── stage: static selftests"
  local m d="$SCRATCH/cf"
  mkdir -p "$d"

  m="$d/extra-run"; cp "$FLAT" "$m"
  printf 'RUN apt-get install -y cowsay\n' >> "$m"
  cf_static "selftest: an appended 'RUN apt-get install -y cowsay' exits 1" "$m"

  m="$d/node-after-config"
  grep -vE '^RUN .*setup_lts' "$FLAT" > "$m"
  grep -E '^RUN .*setup_lts' "$FLAT" >> "$m"
  cf_static "selftest: the Node layer moved after the config layer exits 1" "$m"

  m="$d/arch-literal"
  sed 's/${ARCH}/x86_64/g' "$FLAT" > "$m"
  cf_static "selftest: a literal x86_64 in the eza fetch URL exits 1" "$m"

  m="$d/ingress"; cp "$FLAT" "$m"
  printf 'COPY . /tmp/ctx\n' >> "$m"
  cf_static "selftest: an inserted 'COPY . /tmp/ctx' exits 1" "$m"

  m="$d/smuggled"
  sed 's/ripgrep /ripgrep cowsay /' "$FLAT" > "$m"
  cf_static "selftest: cowsay smuggled into the apt layer exits 1, naming it" "$m"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --build
# ════════════════════════════════════════════════════════════════════════════
TAG_A=""; TAG_B=""; TAG_C=""
cleanup_images() {
  [ -n "$TAG_A" ] && docker rmi -f "$TAG_A" "$TAG_B" "$TAG_C" > /dev/null 2>&1
  return 0
}

layers_of() {
  docker image inspect --format '{{json .RootFS.Layers}}' "$1" \
    | tr -d '[]" ' | tr ',' '\n' | sed '/^$/d'
}

stage_build() {
  echo "── stage: build"

  # The assumed runtime, asserted — never skipped around. install.sh
  # provisions the docker formula; Docker Desktop is the daemon on this host.
  if ! command -v docker > /dev/null 2>&1; then
    chk "build: docker CLI on PATH — ASSUMPTION MISSING, install docker (this is a FAIL, not a skip)" 1
    return
  fi
  chk "build: docker CLI on PATH" 0
  if ! docker info > /dev/null 2>&1; then
    chk "build: docker daemon reachable — ASSUMPTION MISSING, start Docker Desktop (this is a FAIL, not a skip)" 1
    return
  fi
  chk "build: docker daemon reachable" 0

  TAG_A="capsule-gate-$$-a"; TAG_B="capsule-gate-$$-b"; TAG_C="capsule-gate-$$-c"
  # lib.sh's EXIT trap only removes GATES_TMP; replace it with one that also
  # removes the images, preserving the GATES_KEEP_TMP contract.
  if [ -n "${GATES_KEEP_TMP:-}" ]; then
    trap 'cleanup_images' EXIT
  else
    trap 'cleanup_images; rm -rf "$GATES_TMP"' EXIT
  fi

  local da="$SCRATCH/build-a" db="$SCRATCH/build-b" dc="$SCRATCH/build-c"
  mkdir -p "$da" "$db" "$dc"
  cp "$DOCKERFILE" "$da/Dockerfile"

  # ── cold build ───────────────────────────────────────────────────────────
  if docker build -t "$TAG_A" "$da" > "$SCRATCH/build-a.log" 2>&1; then
    chk "build: cold build completes without interaction" 0
  else
    tail -40 "$SCRATCH/build-a.log" | sed 's/^/      /'
    chk "build: cold build completes without interaction" 1
    return
  fi

  # ── runtime probes (spec01) ──────────────────────────────────────────────
  local out
  out="$(docker run --rm "$TAG_A" whoami 2>&1)"
  chk_ok "build: whoami prints dev (got '$out')" test "$out" = dev
  out="$(docker run --rm "$TAG_A" id -u 2>&1)"
  chk_fail "build: id -u is not 0 (got '$out')" test "$out" = 0
  chk_ok "build: sudo -n true exits 0" docker run --rm "$TAG_A" sudo -n true

  out="$(docker run --rm "$TAG_A" sh -c "
    for t in $PATH_TOOLS; do
      command -v \"\$t\" > /dev/null || { echo \"MISSING \$t\"; exit 1; }
    done
    echo TOOLS-OK" 2>&1)"
  if printf '%s\n' "$out" | grep -q '^TOOLS-OK$'; then
    chk "build: all 13 tools on \$PATH as dev ($PATH_TOOLS)" 0
  else
    printf '%s\n' "$out" | sed 's/^/      /'
    chk "build: all 13 tools on \$PATH as dev ($PATH_TOOLS)" 1
  fi

  out="$(docker run --rm "$TAG_A" node --version 2>&1)"
  local maj="${out#v}"; maj="${maj%%.*}"
  chk_ok "build: node --version major >= 22 (got '$out')" test "$maj" -ge 22

  out="$(docker run --rm "$TAG_A" zsh -ic 'echo $ZSH' 2>&1)"
  chk_ok "build: zsh -ic 'echo \$ZSH' prints /opt/oh-my-zsh" \
         sh -c "printf '%s\n' \"\$1\" | grep -q '^/opt/oh-my-zsh$'" _ "$out"
  chk_fail "build: no zsh-newuser-install prompt" \
           sh -c "printf '%s\n' \"\$1\" | grep -q 'zsh-newuser-install'" _ "$out"

  out="$(docker image inspect --format '{{.Config.WorkingDir}}' "$TAG_A")"
  chk_ok "build: inspect WorkingDir is /workspace (got '$out')" test "$out" = /workspace
  out="$(docker image inspect --format '{{.Config.User}}' "$TAG_A")"
  chk_ok "build: inspect User is dev (got '$out')" test "$out" = dev
  out="$(docker image inspect --format '{{json .Config.Cmd}}' "$TAG_A")"
  chk_ok "build: inspect Cmd is [\"sleep\",\"infinity\"] (got '$out')" \
         test "$out" = '["sleep","infinity"]'

  # ── cache: unchanged rebuild is fully CACHED ─────────────────────────────
  local id1 id2
  id1="$(docker image inspect --format '{{.Id}}' "$TAG_A")"
  docker build -t "$TAG_A" "$da" > "$SCRATCH/build-a2.log" 2>&1
  id2="$(docker image inspect --format '{{.Id}}' "$TAG_A")"
  chk_ok "cache: immediate rebuild of the unchanged definition reproduces the same image ID" \
         test "$id1" = "$id2"

  # ── cache reuse (R6): a config-layer edit reuses every toolchain layer ───
  # The RootFS ends [.. useradd, zshrc-config, WORKDIR]: WORKDIR /workspace
  # sits after USER dev (spec01's closing order) and emits its own 0B layer
  # creating the directory, which re-emits with fresh timestamps whenever
  # the layer before it rebuilds. So the R6 boundary is the last TWO layers:
  # everything before the config layer must be digest-identical.
  awk '{ print } /^plugins=\(git\)$/ { print "# cache probe" }' \
      "$da/Dockerfile" > "$db/Dockerfile"
  if docker build -t "$TAG_B" "$db" > "$SCRATCH/build-b.log" 2>&1; then
    chk "cache: rebuild with a config-layer edit completes" 0
  else
    tail -40 "$SCRATCH/build-b.log" | sed 's/^/      /'
    chk "cache: rebuild with a config-layer edit completes" 1
    return
  fi
  local la lb na nb keep pre_a pre_b cfg_a cfg_b
  la="$(layers_of "$TAG_A")"; lb="$(layers_of "$TAG_B")"
  na="$(printf '%s\n' "$la" | grep -c .)"
  nb="$(printf '%s\n' "$lb" | grep -c .)"
  chk_ok "cache: layer counts match ($na vs $nb)" test "$na" = "$nb"
  keep=$((na - 2))
  pre_a="$(printf '%s\n' "$la" | head -n "$keep")"
  pre_b="$(printf '%s\n' "$lb" | head -n "$keep")"
  cfg_a="$(printf '%s\n' "$la" | tail -2 | head -1)"
  cfg_b="$(printf '%s\n' "$lb" | tail -2 | head -1)"
  chk_ok "cache: every layer before the config layer digest-identical after the config edit (R6)" \
         test "$pre_a" = "$pre_b"
  chk_fail "cache: the config layer digest DID change (the edit took)" \
           test "$cfg_a" = "$cfg_b"

  # ── cache control: the same edit in the apt layer must diverge early ─────
  sed 's/^RUN apt-get update/RUN true \&\& apt-get update/' \
      "$da/Dockerfile" > "$dc/Dockerfile"
  if docker build -t "$TAG_C" "$dc" > "$SCRATCH/build-c.log" 2>&1; then
    chk "cache control: rebuild with an apt-layer edit completes" 0
    local pre_c
    pre_c="$(layers_of "$TAG_C" | head -n "$keep")"
    chk_fail "cache control: an apt-layer edit diverges a pre-config digest — the comparison CAN fail" \
             test "$pre_a" = "$pre_c"
  else
    tail -40 "$SCRATCH/build-c.log" | sed 's/^/      /'
    chk "cache control: rebuild with an apt-layer edit completes" 1
  fi

  # ── cleanup, and prove it ────────────────────────────────────────────────
  cleanup_images
  out="$(docker images --format '{{.Repository}}' | grep -c '^capsule-gate-' || true)"
  chk_ok "build: no capsule-gate-* image left behind (got $out)" test "$out" = 0
  out="$(docker ps -a --format '{{.Image}}' | grep -c 'capsule-gate-' || true)"
  chk_ok "build: no capsule-gate-* container left behind (got $out)" test "$out" = 0
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  local want="${1:---all}"
  snapshot_paths --deep "$REPO/prds" "$REPO/docs" "$REPO/gates" "$REPO/tests" "$REPO/home"
  ROOT_BEFORE="$(ls -A "$REPO" | LC_ALL=C sort)"

  case "$want" in
    --static)  stage_static ;;
    --build)   stage_build ;;
    --all|"")  stage_static; stage_build ;;
    *) echo "usage: bash tests/dev-image.sh [--static|--build]"; exit 2 ;;
  esac

  assert_unchanged "the gate wrote nothing outside its scratch (sha256 over prds, docs, gates, tests, home)"
  if [ "$(ls -A "$REPO" | LC_ALL=C sort)" = "$ROOT_BEFORE" ]; then
    chk "the gate added no file to the repo root" 0
  else
    chk "the gate added no file to the repo root" 1
  fi
  exit "$rc"
}

main "${1:-}"
