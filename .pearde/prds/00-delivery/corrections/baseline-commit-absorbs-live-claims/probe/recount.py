#!/usr/bin/env python3
r"""One counter over both sides of the 01-hygiene reconciliation.

Left  : .pearde/.claims/09-simplify/01-hygiene/diff  (tracked dirt at 11:26:32)
Right : git show 5dceabc                             (the baseline commit)

Counted identically on both sides: a line starting '+' and not '+++' is an
addition, '-' and not '---' a deletion.  An `awk '/^\+[^+]/'` count drops a
bare '+' (an added empty line); this does not.
"""
import subprocess, sys, os, collections

REPO = "/Users/feb/dev/dotfiles"
CLAIM = os.path.join(REPO, ".pearde/.claims/09-simplify/01-hygiene/diff")
SHA = "5dceabc"


def count(text):
    """{path: (added, removed)} — one counter, used on both sides."""
    per = collections.defaultdict(lambda: [0, 0])
    path = None
    for line in text.split("\n"):
        if line.startswith("diff --git "):
            path = line.split(" b/", 1)[-1] if " b/" in line else None
            per[path]  # register even a pure-mode change
        elif path is None:
            continue
        elif line.startswith("+++") or line.startswith("---"):
            continue
        elif line.startswith("+"):
            per[path][0] += 1
        elif line.startswith("-"):
            per[path][1] += 1
    return {k: tuple(v) for k, v in per.items() if k}


left = count(open(CLAIM, encoding="utf-8", errors="replace").read())
right = count(subprocess.run(
    ["git", "-C", REPO, "show", SHA, "--no-color", "-U3", "--no-renames"],
    capture_output=True, text=True, errors="replace").stdout)

shared = sorted(set(left) & set(right))
la = sum(left[p][0] for p in shared); lr = sum(left[p][1] for p in shared)
ra = sum(right[p][0] for p in shared); rr = sum(right[p][1] for p in shared)

print(f"files: claim {len(left)}  commit {len(right)}  shared {len(shared)}")
print(f"shared, claim  side: +{la}/-{lr}")
print(f"shared, commit side: +{ra}/-{rr}")
print(f"delta:               +{ra-la}/-{rr-lr}")
print(f"only in claim : {len(set(left)-set(right))} -> "
      f"{sorted(set(left)-set(right))}")
print(f"only in commit: {len(set(right)-set(left))} -> "
      f"{sorted(set(right)-set(left))[:40]}")

diff_files = [p for p in shared if left[p] != right[p]]
print(f"\nshared files whose counts differ: {len(diff_files)}")
for p in diff_files[:40]:
    print(f"  {p}: claim +{left[p][0]}/-{left[p][1]}  "
          f"commit +{right[p][0]}/-{right[p][1]}")
sys.exit(0)
