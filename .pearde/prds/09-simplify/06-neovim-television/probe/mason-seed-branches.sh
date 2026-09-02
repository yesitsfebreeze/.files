#!/usr/bin/env bash
# Probe for R7: exercises all four branches of
# home/run_after_seed-mason-registry.sh in a scratch dir, never the real
# $XDG_DATA_HOME/nvim/mason. Proves the script is automatic on a cold
# machine now that install.sh (09-simplify/07-provisioning R2) no longer
# exports MASON_SEED — the script's only gate is the registry itself.
set -eu
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)/home/run_after_seed-mason-registry.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

pass() { echo "ok   $*"; }
fail() { echo "FAIL $*"; exit 1; }

# 1: warm registry -> silent no-op, exit 0 (nvim present, registry present).
mkdir -p "$SCRATCH/warm/registries"
touch "$SCRATCH/warm/registries/x"
out="$(MASON_SEED_DATA_DIR="$SCRATCH/warm" bash "$HOOK" 2>&1)"
[ -z "$out" ] || fail "warm registry printed: $out"
pass "warm registry: silent no-op"

# 2: no nvim on PATH -> warns, exit 0.
out="$(MASON_SEED_DATA_DIR="$SCRATCH/cold-no-nvim" PATH="/usr/bin:/bin" bash "$HOOK" 2>&1)"
echo "$out" | grep -q "nvim is not on PATH" || fail "missing nvim warning: $out"
pass "no nvim on PATH: warns, exits 0"

# 3: cold + stub nvim succeeds -> seeds, logs "registry seeded".
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/nvim" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *MasonUpdate* ]]; then
  mkdir -p "$MASON_SEED_DATA_DIR/registries/github"
  echo '{}' > "$MASON_SEED_DATA_DIR/registries/github/fake.json"
fi
exit 0
EOF
chmod +x "$SCRATCH/bin/nvim"
out="$(MASON_SEED_DATA_DIR="$SCRATCH/cold-happy" PATH="$SCRATCH/bin:/usr/bin:/bin" bash "$HOOK" 2>&1)"
echo "$out" | grep -q "registry seeded" || fail "no seed confirmation: $out"
pass "cold + working nvim: seeds automatically, no switch needed"

# 4: cold + MasonUpdate fails (offline) -> warns, exit 0, re-run advice.
cat > "$SCRATCH/bin/nvim" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *MasonUpdate* ]]; then exit 1; fi
exit 0
EOF
out="$(MASON_SEED_DATA_DIR="$SCRATCH/cold-offline" PATH="$SCRATCH/bin:/usr/bin:/bin" bash "$HOOK" 2>&1)"
echo "$out" | grep -q "MasonUpdate failed" || fail "no offline warning: $out"
pass "cold + offline: warns, exits 0, tells you how to retry"

echo "PASS"
