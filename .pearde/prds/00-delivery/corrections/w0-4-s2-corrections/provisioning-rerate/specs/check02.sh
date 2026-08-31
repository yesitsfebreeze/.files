#!/usr/bin/env bash
# W0.4i spec02 verify — R4's supersession record and the routing note.
# Content-based and whitespace-normalised throughout.
cd "$(git rev-parse --show-toplevel)" || exit 2
python3 - <<'PY'
import os, re, sys

D = "prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate"
F = os.path.join(D, "prd.md")
rc = 0
def fail(m):
    global rc
    print("FAIL: " + m); rc = 1

raw = open(F, encoding="utf-8").read()
lines = raw.split("\n")
def norm(s):
    return re.sub(r"\s+", " ", s.replace("`", "")).strip().lower()

# the section
idx = [i for i, l in enumerate(lines) if l.strip() == "## Superseded guard"]
if not idx:
    fail("no '## Superseded guard' section — the precedent (odin-toolchain, "
         "tinty) is that a stale guard is superseded on the record, with a reason")
    sec = ""
else:
    i = idx[0]
    nxt = [j for j in range(i + 1, len(lines)) if lines[j].startswith("## ")]
    sec = norm("\n".join(lines[i + 1: nxt[0] if nxt else len(lines)]))

if sec:
    for s in ["docs-inventories", "spec03", "w0.4a", "w0.4i",
              "declarative package set", "homebrew bootstrap", "package installer",
              "tool installation", "superseded", "orchestrator",
              "docs/capabilities-provisioning.md", "specs/check01.sh",
              "odin-toolchain", "tinty", "2026-08-21"]:
        if s not in sec:
            fail("the Superseded guard section does not say %r" % s)
    # it must name each of the three assertions concretely, not just gesture
    for s in ["12", "10"]:
        if s not in sec:
            fail("the section does not state the entry-count assertion (%s -> %s)"
                 % ("12", "10"))
            break
    if "ratio" not in sec and "order" not in sec:
        fail("the section does not name spec03's order assertion")
    if "8 / 9" not in sec and "8/9" not in sec:
        fail("the section does not name spec03's C/U assertion on Package installer")
    # one coordinated pass, not two: spec03's corrections are named here too,
    # together with the fact that they were written to add no new red assertion
    for s in ["spec03", "l-13", "tinted-theming", "just cutover",
              "~/.local/share/chezmoi"]:
        if s not in sec:
            fail("the record does not cover the whole coordinated pass — "
                 "spec03's corrections are missing: %r" % s)
    if "three" not in sec:
        fail("the record does not state how many of spec03's assertions go stale "
             "(three, and only three)")
    if "preserv" not in sec and "kept" not in sec and "in place" not in sec:
        fail("the record does not say the L-12/L-13/solo-window/1149 tokens were "
             "deliberately preserved so no further assertion goes red")
    # it must be explicit that this node may not edit the other ticket
    if not any(k in sec for k in ("files list", "footprint", "may not edit",
                                  "does not own")):
        fail("the section does not say why the record is routed rather than written "
             "(W0.4i's files list is one file)")
    if "route" not in sec:
        fail("the section does not route the record to the orchestrator")
    # and it must forbid the wrong repair
    if "do not" not in sec:
        fail("the section does not forbid 'fixing' the inventory back to make the "
             "dead guard green — the failure mode odin-toolchain warned about")

# dead precedent links in R4
for l in re.findall(r"\]\((\.\.[^)#]*)\)", raw):
    if not os.path.exists(os.path.join(D, l)):
        fail("broken relative link -> %s" % l)

print("OK" if rc == 0 else "")
sys.exit(rc)
PY
