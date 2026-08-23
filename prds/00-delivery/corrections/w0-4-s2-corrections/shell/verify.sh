#!/usr/bin/env bash
# verify.sh — the gate for W0.4b (`04-shell` corrections).
#
# Usage:  bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh [spec01|spec02|spec03|all]
#
# WHY THIS IS NOT A PILE OF greps. Two failure modes have already cost this
# repo a session each:
#   1. prose wraps at ~78 columns, so a phrase that reads as one string in the
#      file is split by a newline and a naive `grep -q "some phrase"` reports a
#      false negative. Every check below runs against the file with all
#      whitespace runs collapsed to one space, so a line break is invisible.
#   2. a guard pinned to one literal sentence goes stale the moment another
#      lane rewords that sentence. So the checks assert *proximity of facts*
#      ("`rcwd` may only appear near `L-3`") rather than exact wording. The
#      implementer is free to write the prose; the facts have to be there.
#
# Exit 0 = green. Any FAIL = non-zero. Reads only; never writes.
set -u
# The repo root is derived from THIS SCRIPT'S OWN LOCATION, five levels up
# (shell -> w0-4-s2-corrections -> corrections -> 00-delivery -> prds -> root).
# It used to be found by walking up from $PWD for a `.mi` directory; the mi
# retirement deleted that marker, so the walk ran to the filesystem root and
# REPO became `/` — every one of the 42 checks then died FileNotFoundError,
# reading a path under a `.mi` directory that no longer exists.
# A marker that can be deleted is not a derivation. This one cannot go stale,
# and it also makes the gate runnable from any cwd.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
export REPO
python3 - "${1:-all}" <<'PY'
import os, re, sys, pathlib

# `__file__` is "-" under `python3 -`, so the root cannot be derived in here:
# bash exports it above from ${BASH_SOURCE[0]}.
REPO = pathlib.Path(os.environ["REPO"])
PRD = REPO / "prds" / "04-shell"

_cache = {}
def norm(rel):
    """File text with every whitespace run collapsed to a single space."""
    if rel not in _cache:
        p = PRD / rel
        _cache[rel] = re.sub(r"\s+", " ", p.read_text(encoding="utf-8"))
    return _cache[rel]

def header_ok(rel):
    """The C/U/source line must be a closed quotation AND name the inventory
    it sources. Six of these lines were truncated mid-quote by the prose->board
    conversion; one (`"Quicklist" in`) lost only the inventory link, which a
    quote-balance test alone reads as fine. The target form is the one
    `09-theme-switcher` (written 2026-08-21, post-conversion) carries."""
    h = header(rel)
    q = h.count('"')
    if q < 2 or q % 2:
        return False, f"{q} quote char(s), so the source name is cut: {h[:130]}"
    if "capabilities-nushell" not in h:
        return False, f"the source is not tied to its inventory: {h[:130]}"
    return True, ""

def header(rel):
    """The `Parent:` paragraph — the C/U/source line, unwrapped."""
    t = norm(rel)
    m = re.search(r"Parent:.*?(?=Purpose:|## )", t)
    return m.group(0) if m else ""

def has(rel, needle):
    return needle in norm(rel)

def count(rel, needle):
    return norm(rel).count(needle)

def near(rel, a, b, window=300):
    """Every occurrence of `a` has `b` within `window` chars either side."""
    t = norm(rel)
    idxs = [m.start() for m in re.finditer(re.escape(a), t)]
    if not idxs:
        return False, f"`{a}` does not appear at all"
    for i in idxs:
        lo, hi = max(0, i - window), min(len(t), i + len(a) + window)
        if b not in t[lo:hi]:
            return False, f"an occurrence of `{a}` at char {i} has no `{b}` within {window} chars"
    return True, ""

def only_near(rel, a, b, window=300):
    """`a` may appear, but never outside the neighbourhood of `b`.
    Unlike near(), zero occurrences of `a` is a PASS — the fact may simply
    have been rewritten away, which is also a correct outcome."""
    t = norm(rel)
    for m in re.finditer(re.escape(a), t):
        i = m.start()
        lo, hi = max(0, i - window), min(len(t), i + len(a) + window)
        if b not in t[lo:hi]:
            return False, f"an occurrence of `{a}` at char {i} has no `{b}` within {window} chars"
    return True, ""

# ── checks ───────────────────────────────────────────────────────────────────
# Each is (id, relpath, description, callable -> (ok, detail)).

def C(cid, rel, desc, fn):
    return (cid, rel, desc, fn)

TV = "04-television/prd.md"
QL = "07-quicklist/prd.md"
CC = "01-core-config/prd.md"
ZX = "03-zoxide/prd.md"
AL = "02-aliases-utilities/prd.md"
LS = "06-listing/prd.md"
EP = "prd.md"

SPECS = {
"spec01": [
  C("TV-1", TV, "L-3: `rcwd` survives only as the named error, never as a channel",
    lambda: only_near(TV, "rcwd", "L-3")),
  C("TV-2", TV, "L-3: the decoder types `recent-dirs`, the name that exists",
    lambda: near(TV, "recent-dirs", "FileList", 250)),
  C("TV-3", TV, "L-2: the git-log decode records the channel's own output template",
    lambda: (has(TV, "L-2") and has(TV, "strip_ansi"),
             "needs both the id `L-2` and the evidence token `strip_ansi`")),
  C("TV-4", TV, "L-2: the decode is required to yield a non-empty result, not silently []",
    lambda: near(TV, "L-2", "empty", 500)),
  C("TV-5", "04-television/prd.md", "burrito is gone from the channel curation (README DO NOT PORT, 2026-08-20)",
    lambda: (count(TV, "burrito") == 0, f"{count(TV,'burrito')} occurrence(s) of `burrito` remain")),
  C("TV-6", TV, "coverage: the `nu-history` channel is named as Alt-R's dependency",
    lambda: near(TV, "nu-history", "Alt-R", 400)),
  C("TV-7", TV, "coverage: `recent-files` and `alias` channels are dispositioned",
    lambda: (has(TV, "recent-files") and has(TV, "alias"),
             "needs both `recent-files` and `alias`")),
  C("TV-8", TV, "S3: `opacity` appears only alongside the decision that settled it",
    lambda: only_near(TV, "opacity", "wallpaper-opacity", 350)),
  C("TV-9", TV, "the theme channel is routed to its owner rather than left 'on demand'",
    lambda: (has(TV, "09-theme-switcher"), "no link to ../09-theme-switcher/prd.md")),
  C("TV-10", TV, "the C/U/source header is closed and names its inventory",
    lambda: header_ok(TV)),
  C("TV-11", QL, "L-4: the quicklist premise names the bug instead of asserting the behaviour",
    lambda: near(QL, "L-4", "finder", 400)),
  C("TV-12", QL, "L-4: the single-channel-tag consequence for ctrl-r replay is recorded",
    lambda: near(QL, "L-4", "zoxide", 400)),
  C("TV-13", QL, "the C/U/source header is closed and names its inventory",
    lambda: header_ok(QL)),
],
"spec02": [
  C("CC-1", CC, "L-3: `rcwd` survives only as the named error",
    lambda: only_near(CC, "rcwd", "L-3")),
  C("CC-2", CC, "L-3: the dirstack feeds `recent-dirs`",
    lambda: (has(CC, "recent-dirs"), "the real channel name never appears")),
  C("CC-3", CC, "M-6: the folded Dirstack entry is listed as a source with its own numbers",
    lambda: ("Dirstack" in header(CC) and "U 7" in header(CC),
             f"header: {header(CC)[:160]}")),
  C("CC-4", CC, "M-6 is cited, so the correction is traceable to the backlog row",
    lambda: (has(CC, "M-6"), "the row id is not named")),
  C("CC-5", CC, "coverage: `ollama-host` probe",
    lambda: (has(CC, "ollama-host"), "not covered")),
  C("CC-6", CC, "coverage: `ENV_CONVERSIONS`",
    lambda: (has(CC, "ENV_CONVERSIONS"), "not covered")),
  C("CC-7", CC, "coverage: the `esc_clear` binding",
    lambda: (has(CC, "esc_clear"), "not covered")),
  C("CC-8", CC, "coverage: the cursor_shape / table / sync_on_enter / completions.external blocks",
    lambda: (all(has(CC, k) for k in ("cursor_shape", "sync_on_enter", "external")),
             "needs cursor_shape, sync_on_enter and the external-completion block")),
  C("CC-9", CC, "coverage: starship is named as the prompt, not only as a generated file",
    lambda: (has(CC, "STARSHIP_SHELL"), "the env var the live config sets is not covered")),
  C("CC-10", CC, "regression: R10's tinty re-assert (landed 2026-08-21) is untouched",
    lambda: (has(CC, "tinted-shell-scripts-file.sh") and has(CC, "R10"),
             "R10 or its artifact path went missing")),
  C("ZX-1", ZX, "M-5: both merged sources are listed with their own numbers",
    lambda: ("Bare-word" in header(ZX) and "C 7" in header(ZX),
             f"header: {header(ZX)[:160]}")),
  C("ZX-2", ZX, "M-8: the no-match HOME hazard is attributed to `mkcd`, not `__zoxide_z`",
    lambda: near(ZX, "HOME", "mkcd", 300)),
  C("ZX-3", ZX, "M-8 is cited, so the correction is traceable to the backlog row",
    lambda: (has(ZX, "M-8"), "the row id is not named")),
  C("ZX-4", ZX, "regression: R2's fzf exception (landed 2026-08-21) is untouched",
    lambda: (has(ZX, "zoxide query --interactive") and has(ZX, "decisions/fzf"),
             "the fzf decision text was disturbed")),
],
"spec03": [
  C("AL-1", AL, "M-7: burrito appears only under its DO NOT PORT record",
    lambda: only_near(AL, "burrito", "DO NOT PORT", 350)),
  C("AL-2", AL, "M-7: the real binary name `brr` is on the record",
    lambda: (has(AL, "brr"), "`brr` is not named, so the M-7 correction is invisible")),
  C("AL-3", AL, "M-7 is cited, so the correction is traceable to the backlog row",
    lambda: (has(AL, "M-7"), "the row id is not named")),
  C("AL-4", AL, "S3: `cdi` is stated once, at its owner, and cross-linked here",
    lambda: (count(AL, "cdi") <= 1 and (count(AL, "cdi") == 0 or "03-zoxide" in norm(AL)),
             f"{count(AL,'cdi')} occurrence(s) of `cdi`, cross-link present: {'03-zoxide' in norm(AL)}")),
  C("AL-5", AL, "no requirement number is used twice",
    lambda: (len(re.findall(r"\*\*R(\d+)", norm(AL))) == len(set(re.findall(r"\*\*R(\d+)", norm(AL)))),
             f"labels found: {re.findall(r'[*][*]R(\d+)', norm(AL))}")),
  C("AL-6", AL, "the C/U/source header is closed and names its inventory",
    lambda: header_ok(AL)),
  C("LS-1", LS, "L-1: `du -sb` appears only as the named bug",
    lambda: only_near(LS, "-sb", "L-1", 350)),
  C("LS-2", LS, "L-1: the rebuild's replacement flag is specified",
    lambda: (has(LS, "-sk"), "no replacement flag is named")),
  C("LS-3", LS, "L-1: the KiB→bytes conversion the replacement forces is specified",
    lambda: (has(LS, "1024"), "`-sk` reports KiB; the multiplier is not stated")),
  C("LS-4", LS, "L-1: the silent-stderr mechanism that hid the bug is constrained",
    lambda: near(LS, "L-1", "stderr", 500)),
  C("LS-5", LS, "the C/U/source header is closed and names its inventory",
    lambda: header_ok(LS)),
  C("EP-1", EP, "the epic no longer calls the wallpaper/opacity decision open",
    lambda: (count(EP, "still-open") == 0,
             "Out of scope still describes `wallpaper-opacity` as an open decision; "
             "it was answered 2026-08-21 (both features dropped)")),
  C("EP-1b", EP, "the wallpaper/opacity disposition carries its decision date",
    lambda: near(EP, "wallpaper-opacity", "2026-08-21", 250)),
  C("EP-2", EP, "regression: invariant I3's fzf exception is untouched",
    lambda: (has(EP, "decisions/fzf") and has(EP, "zoxide query --interactive"),
             "I3's fzf text was disturbed")),
  C("EP-3", EP, "regression: invariant I5's tinty ownership is untouched",
    lambda: (has(EP, "I5") and has(EP, "tinty apply"),
             "I5 was disturbed")),
],
}

which = sys.argv[1] if len(sys.argv) > 1 else "all"
groups = list(SPECS) if which == "all" else [which]
if which != "all" and which not in SPECS:
    print(f"unknown spec: {which} (have: {', '.join(SPECS)})")
    sys.exit(2)

fails = 0
total = 0
for g in groups:
    print(f"── {g} " + "─" * (66 - len(g)))
    for cid, rel, desc, fn in SPECS[g]:
        total += 1
        try:
            res = fn()
            ok, detail = (res if isinstance(res, tuple) else (bool(res), ""))
        except Exception as e:                      # a missing file is a FAIL, not a crash
            ok, detail = False, f"{type(e).__name__}: {e}"
        print(f"{'PASS' if ok else 'FAIL'}  {cid}  {rel}: {desc}")
        if not ok:
            fails += 1
            if detail:
                print(f"      ↳ {detail}")
print("─" * 70)
print(f"{total - fails}/{total} passed" + ("" if not fails else f"  ({fails} FAILED)"))
sys.exit(1 if fails else 0)
PY
