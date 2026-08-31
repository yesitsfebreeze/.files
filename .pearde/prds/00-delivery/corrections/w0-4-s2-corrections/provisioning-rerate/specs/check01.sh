#!/usr/bin/env bash
# W0.4i spec01 verify — the provisioning inventory fold.
# Every assertion is content-based and whitespace-normalised: the file wraps
# at ~78 columns and straddling phrases have produced false negatives.
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

# --- parse entries -----------------------------------------------------------
heads = [(i, l[3:].strip()) for i, l in enumerate(lines) if l.startswith("## ")]
head_idx = [i for i, _ in heads]
entries = []
for n, (i, h) in enumerate(heads):
    end = head_idx[n + 1] if n + 1 < len(heads) else len(lines)
    body = "\n".join(lines[i + 1:end])
    nums = re.findall(r"(?m)^- (\d+)$", body)
    name = h
    for mk in ("DO NOT PORT", "CONSOLIDATE", "SIMPLIFY", "DEFER"):
        if name.endswith(mk):
            name = name[: -len(mk)]
    name = name.strip()
    short = re.sub(r"\s*\(.*", "", name).replace("`", "").strip()
    c, u = (int(nums[-2]), int(nums[-1])) if len(nums) >= 2 else (None, None)
    entries.append(dict(head=h, name=name.replace("`", ""), short=short,
                        c=c, u=u, body=norm(body), raw_head=lines[i]))

head_text = norm("\n".join(lines[: head_idx[0]])) if head_idx else ""
by = {e["short"]: e for e in entries}

# --- A. structure ------------------------------------------------------------
WANT = ["Shell-init generation", "Idempotent apply + push workflow",
        "Managed config surface", "Starship prompt", "Small tool configs",
        "Tool installation", "Neovim version gating", "Published docs site",
        "wp-stat-overlay installer", "Windows config mirroring"]
got = [e["short"] for e in entries]
if len(entries) != 10:
    fail("entry count is %d, want 10 (12 minus the three folded, plus one)" % len(entries))
if got != WANT:
    fail("entry order is not the post-fold order.\n  got:  %s\n  want: %s"
         % (" | ".join(got), " | ".join(WANT)))
for gone in ("Declarative package set", "Homebrew bootstrap", "Package installer"):
    if any(e["short"] == gone for e in entries):
        fail("'%s' is still a separate entry; it folds into Tool installation" % gone)
prev = None
for e in entries:
    if e["c"] is None:
        fail("'%s' has no C/U pair" % e["short"]); continue
    r = e["u"] - e["c"]
    if prev is not None and r > prev:
        fail("ratio rise: '%s' (%d) sits below (%d)" % (e["short"], r, prev))
    prev = r

# --- B. ratings --------------------------------------------------------------
RATED = {"Shell-init generation": (3, 9), "Idempotent apply + push workflow": (3, 9),
         "Managed config surface": (3, 9), "Starship prompt": (2, 8),
         "Small tool configs": (2, 7), "Tool installation": (4, 9),
         "Neovim version gating": (4, 8), "Published docs site": (4, 4),
         "wp-stat-overlay installer": (4, 3), "Windows config mirroring": (3, 1)}
for k, (c, u) in RATED.items():
    e = by.get(k)
    if not e:
        fail("entry '%s' is missing" % k)
    elif (e["c"], e["u"]) != (c, u):
        fail("'%s' is rated %s/%s, want %d/%d" % (k, e["c"], e["u"], c, u))

# --- C/D/E. the folded entry -------------------------------------------------
if "## Tool installation (install.sh)" not in lines:
    fail("no line reads exactly '## Tool installation (install.sh)' — "
         "05-platform/02-package-provisioning cites that literal string")
ti = by.get("Tool installation")
if ti:
    for s in ["install.sh", "233", "command -v", "latest_tag", "fetch_release",
              "~/.local/bin", "brew", "apt", "cargo", "npm", "batcat",
              "package-manager batch install", "github", "release",
              "dev/.files", "re-run", "warn"]:
        if s not in ti["body"]:
            fail("Tool installation entry does not describe what install.sh does: %r" % s)
    for s in ["8fe3a71", "2026-08-19", "2490", "packages.yaml", "run_onchange",
              "run_once_before", "559", "sha256", "deleted", "restore"]:
        if s not in ti["body"]:
            fail("Tool installation entry does not record the deletion (R3): %r" % s)
    for s in ["declarative package set", "homebrew bootstrap", "package installer",
              "c 8 / u 9", "c 2 / u 9", "c 2 / u 8", "c 8", "c 4", "2026-08-21"]:
        if s not in ti["body"]:
            fail("Tool installation entry does not name its three sources with "
                 "their own numbers, per the contract's merged-entry rule: %r" % s)
    if "burrito" not in ti["body"] or "do not port" not in ti["body"]:
        fail("Tool installation entry names install.sh's git build without flagging "
             "burrito as DO NOT PORT — a reader would restore it")

# --- F. Neovim version gating stays its own entry, pointed at install.sh -----
nv = by.get("Neovim version gating")
if nv:
    for s in ["install.sh", "nvim --version", "0.11", "~/.local", "linux only",
              "nvim-lspconfig", "0.11.3", "blink.cmp"]:
        if s not in nv["body"]:
            fail("Neovim version gating entry lost or never gained: %r" % s)
    for s in ["run_onchange", "run_once_before", ".tmpl"]:
        if s in nv["body"]:
            fail("Neovim version gating still points at deleted machinery: %r" % s)

# --- G/H. preservation guards + the burrito bullet's truth repair ------------
mc = by.get("Managed config surface")
if mc:
    for s in ["burrito", "do not port", "2026-08-20", "packages.yaml",
              "l-12", "l-13", "solo-window", "1149"]:
        if s not in mc["body"]:
            fail("Managed config surface lost a record spec03 guards: %r" % s)
    if "television, burrito" in mc["body"] or "burrito, starship" in mc["body"]:
        fail("burrito is back inside the list of configs the surface takes over")
    if "both verified live 2026-08-21" in mc["body"]:
        fail("the burrito bullet still claims the packages.yaml cargo_git entry is "
             "live; 8fe3a71 deleted .chezmoidata/ — verified 2026-08-21")
    if "8fe3a71" not in mc["body"] or "install.sh" not in mc["body"]:
        fail("the burrito bullet does not say 8fe3a71 removed the packages.yaml "
             "entry and install.sh now builds burrito instead")
for s in ["decision 4", "canonical", "not a port target"]:
    if s not in head_text:
        fail("the head's canonicality note was disturbed: %r" % s)

# --- links -------------------------------------------------------------------
if "](../prd/" in raw:
    fail("stale ../prd/ links remain (the board lives at prds/)")
for l in re.findall(r"\]\((\.\./[^)#]*)\)", raw):
    if not os.path.exists(os.path.join("docs", l)):
        fail("broken relative link -> %s" % l)

# --- I. R5: every 05-platform source citation resolves to a heading ----------
inv_names = [e["name"] for e in entries]
def resolves(cit):
    c = norm(cit)
    return any(c == norm(n) or norm(n).startswith(c + " (") for n in inv_names)
for root, _, files in os.walk("prds/05-platform"):
    for fn in files:
        if fn != "prd.md":
            continue
        p = os.path.join(root, fn)
        t = open(p, encoding="utf-8").read()
        m = re.search(r"(?ms)^Parent:.*?(?=\n\n)", t)
        if not m:
            continue
        blk = re.sub(r"\s+", " ", m.group(0))
        if "capabilities-provisioning.md" not in blk:
            continue
        for gone in ("Declarative package set", "Homebrew bootstrap", "Package installer"):
            if gone in blk:
                fail("%s still cites the folded entry '%s'" % (p, gone))
        for cit in re.findall(r'"([^"]+)"', blk):
            if not resolves(cit):
                fail("%s cites source %r, which matches no ## heading in %s"
                     % (p, cit, F))
        if p.endswith("02-package-provisioning/prd.md"):
            for s in ("tool installation (install.sh)", "c4 u9", "c 4 · u 9"):
                if s not in norm(blk):
                    fail("02-package-provisioning's Parent line lost %r" % s)

print("OK" if rc == 0 else "")
sys.exit(rc)
PY
