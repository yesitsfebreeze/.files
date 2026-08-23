#!/usr/bin/env bash
# W0.4i spec03 verify — the stale-clone corrections and the two entries
# 8fe3a71 invalidated. Content-based, whitespace-normalised throughout.
cd "$(git rev-parse --show-toplevel)" || exit 2
python3 - <<'PY'
import os, re, sys

F = "docs/capabilities-provisioning.md"
rc = 0
def fail(m):
    global rc
    print("FAIL: " + m); rc = 1

raw = open(F, encoding="utf-8").read()
lines = raw.split("\n")
def norm(s):
    return re.sub(r"\s+", " ", s.replace("`", "")).strip().lower()

heads = [(i, l[3:].strip()) for i, l in enumerate(lines) if l.startswith("## ")]
head_idx = [i for i, _ in heads]
by = {}
order = []
for n, (i, h) in enumerate(heads):
    end = head_idx[n + 1] if n + 1 < len(heads) else len(lines)
    body = "\n".join(lines[i + 1:end])
    nums = re.findall(r"(?m)^- (\d+)$", body)
    name = h
    for mk in ("DO NOT PORT", "CONSOLIDATE", "SIMPLIFY", "DEFER"):
        if name.endswith(mk):
            name = name[: -len(mk)]
    short = re.sub(r"\s*\(.*", "", name.strip()).replace("`", "").strip()
    order.append(short)
    by[short] = dict(body=norm(body), raw=body,
                     c=int(nums[-2]) if len(nums) >= 2 else None,
                     u=int(nums[-1]) if len(nums) >= 2 else None)
head_text = norm("\n".join(lines[: head_idx[0]])) if head_idx else ""

# --- nothing moves, nothing is re-rated: spec01's order is re-derived, not patched
WANT = ["Shell-init generation", "Idempotent apply + push workflow",
        "Managed config surface", "Starship prompt", "Small tool configs",
        "Tool installation", "Neovim version gating", "Published docs site",
        "wp-stat-overlay installer", "Windows config mirroring"]
if order != WANT:
    fail("spec03 moved an entry; the corrections change no C/U, so the order "
         "must still be spec01's.\n  got:  %s" % " | ".join(order))
for k, cu in {"Idempotent apply + push workflow": (3, 9), "Small tool configs": (2, 7),
              "Managed config surface": (3, 9)}.items():
    e = by.get(k)
    if e and (e["c"], e["u"]) != cu:
        fail("'%s' was re-rated to %s/%s; spec03 corrects descriptions, not ratings"
             % (k, e["c"], e["u"]))

# --- 1. the head names the live tree ----------------------------------------
if "chezmoi source at ~/.local/share/chezmoi" in head_text:
    fail("the head still calls ~/.local/share/chezmoi the chezmoi source; it is a "
         "stale June clone whose HEAD a2544e4 is an ancestor of the live 8e99f58")
for s in ["/users/feb/dev/.files", "chezmoi source-path", "stale", "clone",
          "a2544e4", "8e99f58", "ancestor"]:
    if s not in head_text:
        fail("the head does not identify the live source and the stale clone: %r" % s)
for s in ["decision 4", "canonical", "not a port target"]:
    if s not in head_text:
        fail("the head lost a phrase spec03 of docs-inventories guards: %r" % s)
# every mention of the clone anywhere must be labelled as such
for m in re.finditer(re.escape("~/.local/share/chezmoi"), raw):
    w = norm(raw[max(0, m.start() - 400): m.end() + 400])
    if "stale" not in w:
        fail("an unlabelled ~/.local/share/chezmoi mention at offset %d — the only "
             "permitted mention is as the stale clone, labelled as such" % m.start())

# --- 2. L-12 / L-13 corrected in place, tokens preserved --------------------
mc = by.get("Managed config surface")
if mc:
    for s in ["l-12", "l-13", "solo-window", "1149"]:
        if s not in mc["body"]:
            fail("Managed config surface lost a token docs-inventories' spec03 "
                 "asserts: %r — correct the record, do not delete it" % s)
    for s in ["1149 vs 1149", "715 vs 715", "221 vs 221", "byte-identical",
              "stale", "background.png"]:
        if s not in mc["body"]:
            fail("the L-12/L-13 correction is missing %r (see platform's "
                 "decision4-replacement.md, the agreed wording)" % s)
    for s in ["would destroy the config", "is not true of the files they rate",
              "339 vs 1149", "380 vs 715", "345 vs 221"]:
        if s in mc["body"]:
            fail("Managed config surface still asserts the stale clone's finding "
                 "as live: %r" % s)

# --- 3. Idempotent apply + push workflow ------------------------------------
ip = by.get("Idempotent apply + push workflow")
if ip:
    for s in ["chezmoi apply", "install.sh", "just push", "just cutover",
              "git only", "8fe3a71", "2026-08-21", "repo-skeleton", "command -v"]:
        if s not in ip["body"]:
            fail("Idempotent apply + push workflow does not describe the settled "
                 "shape: %r" % s)
    if "init from this source, apply, commit, push" in ip["body"]:
        fail("the entry still describes the pre-cutover push recipe, which "
             "repo-skeleton R5 replaced (user decision, 2026-08-21)")
    if not re.search(r"(?<![A-Za-z])rr(?![A-Za-z])", ip["raw"]):
        fail("the entry dropped `rr`, which is a live capability and not "
             "8fe3a71's to remove")

# --- 4. Small tool configs: tinty survives, its source management did not ---
st = by.get("Small tool configs")
if st:
    for s in ["tinted-theming", "tinty", "8fe3a71", "deployed", "palette",
              "decisions/tinty", "managed-config"]:
        if s not in st["body"]:
            fail("Small tool configs does not reconcile with decisions/tinty: %r" % s)
    for s in ["do not port", "dropped", "defer"]:
        if s in st["body"]:
            fail("Small tool configs reads as if tinty were excluded; "
                 "decisions/tinty kept it as palette owner: %r" % s)

# --- links -------------------------------------------------------------------
if "](../prd/" in raw:
    fail("stale ../prd/ links remain (the board lives at prds/)")
for l in re.findall(r"\]\((\.\./[^)#]*)\)", raw):
    if not os.path.exists(os.path.join("docs", l)):
        fail("broken relative link -> %s" % l)

print("OK" if rc == 0 else "")
sys.exit(rc)
PY
