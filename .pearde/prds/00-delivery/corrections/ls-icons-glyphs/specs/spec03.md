---
spec: 03
node: 00-delivery/corrections/ls-icons-glyphs
covers: R3
complexity: 25
footprint:
  - tests/shell-listing.sh
verify: "bash tests/shell-listing.sh"
---

# spec03 — harden the icon checks: real content, not column existence

Delivers R3. Depends on spec01 landing first — both new checks assert
against spec01's actual output. Does not depend on spec02.

`tests/shell-listing.sh` currently has exactly one icon-related check, H1
(`stage --hermetic`, ~line 499), and it only asserts the column *exists* in
the right position (`icon,name,type,size,modified`) — it would pass
unchanged whether every glyph is a real codepoint or every glyph is `""`,
which is exactly how the empty map shipped silently for as long as it did.
**Do not touch H1** — it is cited by exact number elsewhere
(`prds/04-shell/06-listing/specs/spec01-ls-shadow.md:90`, a different node's
already-`done` spec) and still checks something real, the column shape. Add
two new checks instead, one per stage, each with the negative control this
file's header promises ("Each claim carries a counterfactual").

## T6 (`stage_tree`, after T5) — no `LS_ICONS` value is empty

Text-only: fires even on a machine with no vendored `nvim-web-devicons` to
check byte content against (that's H11, below). This is the actual
regression this whole correction exists to catch — the map going empty with
zero parse error and zero diff anyone noticed for the entirety of the live
repo's history.

Add a helper near the other `_ok` functions (beside `du_ok`, `autolist_ok`):

```sh
# LS_ICONS carries no empty glyph value. Correction for
# prds/00-delivery/corrections/ls-icons-glyphs — this is the exact
# regression it exists to catch (an empty map with no parse error, no diff
# anyone caught). Text-only: does not need the vendored nvim-web-devicons
# present, unlike H11 below.
icons_nonempty_ok() {
  local f="$1"
  "$PYTHON" - "$f" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'const LS_ICONS = \{(.*?)\n\}', src, re.S)
if not m:
    sys.exit(1)
kv = re.findall(r'(?:"([\w]+)"|(\b[a-zA-Z_][\w]*))\s*:\s*"([^"]*)"', m.group(1))
if not kv:
    sys.exit(1)
sys.exit(1 if any(v == "" for _, _, v in kv) else 0)
PY
}
```

Add to `stage_tree`, after the existing T5 block (before the closing `}` at
line ~480):

```sh
  # T6 — no LS_ICONS value is empty. Correction for
  # prds/00-delivery/corrections/ls-icons-glyphs: this is the exact
  # regression the correction exists to catch.
  chk_ok "tree: T6 no LS_ICONS value is empty" icons_nonempty_ok "$CONFIG_NU"
  local CF6="$SCRATCH/cf-empty-icon.nu"
  "$PYTHON" -c "
import re
src = open('$CONFIG_NU', encoding='utf-8').read()
new_src = re.sub(r'(rs:\s*)\"[^\"]*\"', r'\1\"\"', src, count=1)
open('$CF6', 'w', encoding='utf-8').write(new_src)
"
  chk_fail "tree: T6 counterfactual one-blanked-glyph (rs) FAILS the icons check" icons_nonempty_ok "$CF6"
```

Verified by the analyst on this tree, 2026-08-25, against both the current
(still-empty) `config.nu` and a copy patched per spec01: the check fails on
today's file (all 82 values reported empty) and passes on the patched copy;
blanking one key (`rs`) on the patched copy fails again, exactly as a
counterfactual should.

## H11 (`stage_hermetic`, after H10) — real glyph content, cross-checked live

Asserts actual byte content against this repo's own pinned `nvim-web-
devicons`, read fresh off this machine — never a glyph hand-typed into this
test file. Gated: a missing live clone is a `PROBE-ERROR` (`ASSUMPTION
MISSING`), the same convention `tests/nvim-colorscheme.sh` and
`tests/nvim-completion.sh` already use for this exact dependency, never a
silent skip.

Add near the top of the file, with the other path vars (after
`DIRSTACK_NU`):

```sh
DEVICONS_LOCK="$REPO/home/dot_config/nvim/lazy-lock.json"
DEVICONS_LIVE="$HOME/.local/share/nvim/lazy/nvim-web-devicons/lua"
```

Add a helper beside `f_lock`-style checks (or inline, matching this file's
existing `_ok` convention):

```sh
# lazy-lock.json parses and pins nvim-web-devicons at a 40-hex commit —
# same shape as the check tests/nvim-colorscheme.sh runs for tinted-nvim.
devicons_pin_ok() {
  "$PYTHON" - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("nvim-web-devicons")
if not isinstance(e, dict):
    sys.exit(1)
sys.exit(0 if re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "") or "") else 1)
PY
}
```

Add a standalone checker script (write it to `$SCRATCH` at run time, or
inline as a heredoc — the point is it runs as ONE process so a glyph byte
never round-trips through bash string interpolation):

```sh
cat > "$SCRATCH/check_h11.py" <<'PY'
import json, re, sys

def load_expected(d):
    ext = open(f"{d}/nvim-web-devicons/default/icons_by_file_extension.lua", encoding="utf-8").read()
    md = re.search(r'\["md"\]\s*=\s*\{\s*icon\s*=\s*"([^"]*)"', ext).group(1)
    default_src = open(f"{d}/nvim-web-devicons.lua", encoding="utf-8").read()
    default = re.search(r'local default_icon = \{\s*icon = "([^"]*)"', default_src).group(1)
    return md, default

out_path, devicons_dir = sys.argv[1], sys.argv[2]
rows = json.load(open(out_path, encoding="utf-8"))
by_name = {r["name"].split("/")[-1]: r for r in rows}
md_glyph, default_glyph = load_expected(devicons_dir)

checks = [
    ("canary42.md", md_glyph, "md extension glyph"),
    (".hid7", default_glyph, "generic default glyph (no extension)"),
    ("big", "", "dir: no vendored folder glyph exists"),
    ("node_modules", "", "dir: no vendored folder glyph exists"),
]
ok = True
for name, expected, why in checks:
    row = by_name.get(name)
    got = row.get("icon") if row else "<absent>"
    if got != expected:
        print(f"FAIL {name}: got {got!r} expected {expected!r} ({why})")
        ok = False
sys.exit(0 if ok else 1)
PY
```

Add to `stage_hermetic`, after the existing H10 block (before the closing
`}` at line ~635) — reuses the `$M` machine H1–H10 already built:

```sh
  # H11 — real glyph content, cross-checked against this repo's own pinned
  # nvim-web-devicons vendored on THIS machine, never a value hand-typed
  # into this test. Correction for
  # prds/00-delivery/corrections/ls-icons-glyphs.
  if [ ! -d "$DEVICONS_LIVE" ]; then
    echo "PROBE-ERROR: $DEVICONS_LIVE is absent — ASSUMPTION MISSING, the check source is the live nvim-web-devicons clone" >&2
    exit 127
  fi
  chk_ok "hermetic: H11 precondition: lazy-lock.json pins nvim-web-devicons at 40 hex chars" \
         devicons_pin_ok "$DEVICONS_LOCK"

  nu_c "$M" 'ls -a ~/fix | select name icon type | to json -r' > "$SCRATCH/h11_out.json"
  if "$PYTHON" "$SCRATCH/check_h11.py" "$SCRATCH/h11_out.json" "$DEVICONS_LIVE"; then
    chk "hermetic: H11 canary42.md/.hid7/dir icons match nvim-web-devicons byte-for-byte" 0
  else
    chk "hermetic: H11 canary42.md/.hid7/dir icons match nvim-web-devicons byte-for-byte" 1
    "$PYTHON" "$SCRATCH/check_h11.py" "$SCRATCH/h11_out.json" "$DEVICONS_LIVE" 2>&1 | sed 's/^/      /'
  fi
```

`~/fix` here is the SAME fixture `mk_machine` already builds for H1/H2 —
`canary42.md` (an extension the map covers), `.hid7` (no extension, so the
generic fallback), `big` and `node_modules` (dirs, still unmarked). No new
fixture files needed.

Verified by the analyst on this tree, 2026-08-25, with both the positive
and negative control that make this a real counterfactual, not just a
happy-path assertion:

- **Positive** — against a copy of `config.nu` patched per spec01: prints
  `OK` for all four rows, exits 0.
- **Negative** — against the current, still-empty `config.nu`: fails
  exactly the two file rows (`canary42.md` and `.hid7`, both got `''`
  instead of a real glyph) and correctly passes the two dir rows (already
  `''` by design, unaffected by spec01). This is the proof the check
  actually distinguishes "real glyph" from "empty string" rather than just
  exercising the code path.

## Out of scope

- H1 itself — column-existence check, cited by number elsewhere, untouched.
- Any check on extensions other than `md` and the no-extension fallback;
  the fixture doesn't have more, and adding fixture files is not part of
  this spec's footprint (`tests/shell-listing.sh` only — no new files under
  `home/dot_config/nushell/`).
- `tests/nushell-core.sh` — a different gate, not this node's.

## Acceptance

- [ ] `icons_nonempty_ok` added; T6 added to `stage_tree` with its
      counterfactual; both run and their output quoted in the report.
- [ ] `devicons_pin_ok`, `DEVICONS_LOCK`, `DEVICONS_LIVE`, and H11 added to
      `stage_hermetic`; PROBE-ERROR path confirmed to exist (read the code,
      does not need to be exercised — this machine has the live clone).
- [ ] `bash tests/shell-listing.sh` exits 0 with T6 and H11 both passing
      against the post-spec01 `config.nu`.
- [ ] Reverting spec01's `config.nu` change locally (e.g. `git stash` just
      that file) makes both T6 and H11 FAIL — run this once to prove the
      checks bite, then restore the file. Quote both failures in the
      report.
- [ ] `bash tests/nushell-core.sh` still exits 0 (this spec does not touch
      it, but confirm no cross-contamination from the new `$SCRATCH` files).

## Verify and Proof

Historical. This block ran `tests/shell-listing.sh` in three modes plus a
negative control that stashed `config.nu` to prove T6/H11 caught the
regression, and it passed when this node closed. **`tests/` was deleted on
2026-08-31** — see
[the memo](../../../../memos/tests-and-gates-retire-a-dev-setup-is-not-a-product.md)
— so every command in it now names a script that does not exist, and the
block is unrunnable rather than merely unrun. Per AGENTS.md a verify that
pointed into `tests/` reads `""`, the contract's value for *unproven*.

Rewritten 2026-09-02 by the orchestrator, on
[`baseline-commit-absorbs-live-claims`](../../baseline-commit-absorbs-live-claims/prd.md)'s
transition: the stash pair was the last live thing here and the second
member of that node's censused class — a `git` mutation inside a
`## Verify and Proof` block, which bypasses `collect`'s cross-claim refusal
and can leave a dirty tree behind on a failed run. Removing it closes the
class; nothing about this node's own result changes, and its boxes stay
closed on the evidence they were closed against.
