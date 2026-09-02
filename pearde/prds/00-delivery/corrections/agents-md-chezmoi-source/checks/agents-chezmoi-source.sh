#!/usr/bin/env bash
# agents-chezmoi-source.sh — node-local check for
# prds/00-delivery/corrections/agents-md-chezmoi-source.
#
#   bash …/checks/agents-chezmoi-source.sh [--root DIR]   check a tree
#   bash …/checks/agents-chezmoi-source.sh --selftest      counterfactual
#
# WHY THIS IS NODE-LOCAL AND NOT A WAVE GATE.  The node's `verify:` is
# `bash gates/tree-links.sh`, and it provably cannot see this defect class:
# gates/tree-links.py's LINK_RE matches markdown bracket-paren links only, so
# an inline-code path in backticks is never resolved.  The proof is on the
# record — Tier A reported `0 broken` for as long as AGENTS.md cited
# `.claude/skills/prd/README.md`, a file gone since the mi-era retirement (it
# is still cited at AGENTS.md:211, deliberately, inside the note recording
# that it is dead).  So tree-links is the NO-REGRESSION half only (box 6).
#
# AND AN EXISTENCE CHECKER WOULD BE GREEN AND USELESS.  `~/.local/share/chezmoi`
# EXISTS.  The defect class here is "a path that resolves and is the wrong
# tree" — a two-month-stale June clone (HEAD a2544e4, a git ancestor of the
# live 8e99f58) cited as the chezmoi source in the one file every agent reads
# first.  Only a LABELLED-MENTION rule catches that, which is why box 3 has
# the shape it does.  The tree-wide home for the rule is
# gates/retired-phrases.sh; it is deliberately not touched here, because its
# exemption table is asserted as SET EQUALITY and the phrase would need a
# retirement-quote exemption for all twelve legitimate citations across nine
# files — a separate node, and that file is in 20+ nodes' footprints.
#
# The ±400-character window in box 3 is reused verbatim from
# w0-4-s2-corrections/provisioning-rerate/specs/check03.sh, so the two checks
# cannot disagree about what "labelled" means.
set -u
exec python3 - "$@" <<'PY'
import hashlib, os, re, subprocess, sys, tempfile, shutil

# ── the two block texts, declared once so the counterfactual cannot drift ──
# CURRENT is what the repair puts back; HISTORICAL is the literal sentence
# this node removed, substituted back by the mutation.  A `sed`-style
# substitution that matches nothing is caught by the sha pair, not by an
# end-state grep — see prds/memos/a-counterfactual-proves-its-own-mutation.md.
HISTORICAL = """Live sources to read when specifying (never edit them as part of PRD work):
`~/.config/nushell/*.nu`, `~/.config/nvim/`, `~/.config/television/`,
`~/.config/wezterm/`, `~/.files/`, and the chezmoi source at
`~/.local/share/chezmoi`.
"""

def norm(s):
    """check03.sh's normalisation, plus markdown emphasis: the wording under
    test is bolded and italicised in places, and `**not**` must read as
    `not`."""
    return re.sub(r"\s+", " ", s.replace("`", "").replace("*", "")).strip().lower()

def sha12(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()[:12]

def paragraphs(raw):
    return re.split(r"\n[ \t]*\n", raw)


def check(root, label=""):
    """-> (rc, [lines]).  One PASS/FAIL line per box; nothing is printed."""
    out, rc = [], 0

    def chk(ok, msg):
        nonlocal rc
        out.append(("PASS  " if ok else "FAIL  ") + msg)
        if not ok:
            rc = 1

    f = os.path.join(root, "AGENTS.md")
    if not os.path.isfile(f):
        return 2, ["FAIL  AGENTS.md not found under %s" % root]
    raw = open(f, encoding="utf-8").read()
    low = norm(raw)
    paras = paragraphs(raw)

    # ── box 1 — the paragraph names the METHOD ─────────────────────────────
    live = [p for p in paras if norm(p).startswith("live sources to read when specifying")]
    ok = bool(live)
    if ok:
        i = paras.index(live[0])
        window = norm("\n\n".join(paras[i:i + 3]))
        ok = ("chezmoi source-path" in window
              and "find the chezmoi source by running chezmoi source-path" in window
              and "never by literal path" in window)
    chk(ok, "box1: the live-sources paragraph names `chezmoi source-path` as the "
            "way to find the source, and forbids the literal path")

    # ── box 2 — the historical sentence is gone ────────────────────────────
    chk("the chezmoi source at ~/.local/share/chezmoi" not in low,
        "box2: AGENTS.md no longer calls `~/.local/share/chezmoi` the chezmoi source")

    # ── box 3 — every mention of the clone is LABELLED stale (±400) ────────
    bad = []
    for m in re.finditer(re.escape("~/.local/share/chezmoi"), raw):
        if "stale" not in norm(raw[max(0, m.start() - 400): m.end() + 400]):
            bad.append(m.start())
    chk(not bad,
        "box3: every `~/.local/share/chezmoi` mention has `stale` within ±400 chars "
        "— the only permitted mention is as the stale clone, labelled as such"
        + ("" if not bad else " (unlabelled at offset(s) %s)"
           % ", ".join(str(b) for b in bad)))

    # ── box 4 — the two trees called .files are named and separated ────────
    has_dev = ("/users/feb/dev/.files" in low) or ("~/dev/.files" in low)
    chk(has_dev and "~/.files" in low
        and "~/dev/.files is not ~/.files" in low and "different trees" in low,
        "box4: both `~/.files` and `~/dev/.files` are named and said to be "
        "different trees")

    # ── box 5 — a literal source path is dated and marked as a reading ─────
    offenders = []
    for p in paras:
        n = norm(p)
        if "/users/feb/dev/.files" not in n and "~/dev/.files" not in n:
            continue
        if "2026-08-24" not in n:
            offenders.append("undated")
        elif not any(w in n for w in ("reading", "not a constant", "moves")):
            offenders.append("unmarked")
    chk(not offenders,
        "box5: every paragraph carrying a literal chezmoi source path also "
        "carries the date 2026-08-24 and marks it as a reading, not a constant"
        + ("" if not offenders else " (%s)" % ", ".join(offenders)))

    # ── box 6 — the no-regression half: tree-links Tier A, 0 broken ────────
    py = os.path.join(root, "gates", "tree-links.py")
    if not os.path.isfile(py):
        out.append("SKIP  box6: gates/tree-links.py is not under %s (scratch root)" % root)
    else:
        r = subprocess.run([sys.executable, py, "--root", root, "--tier", "a",
                            "--quiet-b"], capture_output=True, text=True)
        line = ""
        for ln in r.stdout.split("\n"):
            if "broken" in ln and "checked" in ln:
                line = ln.strip()
        chk(bool(re.search(r",\s*0 broken\b", line)),
            "box6: `tree-links.py --tier a` reports 0 broken — asserted as "
            "\"0 broken\", never as a link count, because several lanes write "
            "this tree [%s]" % (line or "no TIER A summary line"))

    if label:
        out = ["── %s" % label] + out
    return rc, out


def run_check(root):
    rc, lines = check(root)
    print("\n".join(lines))
    print("rc=%d" % rc)
    return rc


def selftest(root):
    """Red before repair, with a one-line sha pair on BOTH the mutation and
    the repair.  The real AGENTS.md is never written; its sha is printed
    before and after to prove it."""
    rc = 0
    def chk(ok, msg):
        nonlocal rc
        print(("PASS  " if ok else "FAIL  ") + msg)
        if not ok:
            rc = 1

    real = os.path.join(root, "AGENTS.md")
    real_before = sha12(real)
    print("── agents-chezmoi-source.sh --selftest ──────────────────────────────")
    print("      real AGENTS.md sha %s (never written by this selftest)" % real_before)

    tmp = tempfile.mkdtemp(prefix="agents-chezmoi-source.")
    try:
        copy = os.path.join(tmp, "AGENTS.md")
        shutil.copyfile(real, copy)
        print("      MUTATION HOST: %s (a copy; box6 SKIPs there, by design)" % tmp)

        # 0. the copy is green to start with, so the mutation means something.
        c_rc, c_lines = check(tmp)
        print("\n".join("      " + l for l in c_lines))
        chk(c_rc == 0, "baseline: the unmutated copy is GREEN")

        # 1. MUTATION — substitute the literal historical sentence back in.
        cur = open(copy, encoding="utf-8").read()
        paras = paragraphs(cur)
        live = [p for p in paras if norm(p).startswith("live sources to read when specifying")]
        before = sha12(copy)
        if live:
            i = paras.index(live[0])
            # the node replaced ONE paragraph with TWO; put the one back.
            paras[i:i + 2] = [HISTORICAL.rstrip("\n")]
            open(copy, "w", encoding="utf-8").write("\n\n".join(paras))
        after = sha12(copy)
        print("      MUTATION: the historical `and the chezmoi source at "
              "~/.local/share/chezmoi` paragraph, substituted back")
        print("      sha %s -> %s" % (before, after))
        chk(before != after,
            "mutation: the sha pair differs — the substitution really changed "
            "the copy (an equal pair is a no-op that would pass quietly)")

        # 2. RED, and the FAIL names the subject.
        m_rc, m_lines = check(copy_root := tmp)
        print("\n".join("      " + l for l in m_lines))
        chk(m_rc != 0, "red-before-repair: the mutated copy is RED")
        chk(any(l.startswith("FAIL") and "~/.local/share/chezmoi" in l for l in m_lines),
            "red-before-repair: a FAIL names `~/.local/share/chezmoi`")

        # 3. REPAIR — hashed the same way, and back to the original bytes.
        before = sha12(copy)
        shutil.copyfile(real, copy)
        after = sha12(copy)
        print("      REPAIR: the corrected paragraph pair, restored")
        print("      sha %s -> %s" % (before, after))
        chk(before != after, "repair: the sha pair differs — the repair really "
                             "changed the copy back")
        chk(after == real_before,
            "repair: the repaired copy is byte-identical to the real AGENTS.md "
            "(%s)" % after)

        # 4. GREEN again.
        g_rc, g_lines = check(copy_root)
        print("\n".join("      " + l for l in g_lines))
        chk(g_rc == 0, "green-after-repair: the repaired copy is GREEN")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        chk(not os.path.exists(tmp), "hygiene: the scratch directory is removed")

    real_after = sha12(real)
    print("      real AGENTS.md sha %s (before) -> %s (after)" % (real_before, real_after))
    chk(real_before == real_after, "hygiene: the real AGENTS.md is untouched")
    print("── selftest rc=%d ───────────────────────────────────────────────────" % rc)
    return rc


def main(argv):
    root, mode = None, "check"
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--root":
            i += 1
            root = argv[i]
        elif a == "--selftest":
            mode = "selftest"
        elif a in ("-h", "--help"):
            print(__doc__ or "usage: agents-chezmoi-source.sh [--root DIR] [--selftest]")
            return 0
        else:
            print("unknown argument: %s" % a, file=sys.stderr)
            return 2
        i += 1
    if root is None:
        root = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True).stdout.strip()
    root = os.path.abspath(root)
    return selftest(root) if mode == "selftest" else run_check(root)


sys.exit(main(sys.argv[1:]))
PY
