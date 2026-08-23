#!/usr/bin/env python3
"""The tree link check — Wave 0's half of R4, and the cause-fix for the `[~]`
stand-in box in 00-delivery/corrections/w0-3-platform-rewrite.

Two tiers, one exit code.

  Tier A — GATING.  Every prd.md and README.md under prds/, plus
           docs/capabilities*.md, plus AGENTS.md at the repo root.  These are
           the tree: a broken link here is a reader sent to a file that is
           not there.
  Tier B — REPORTED, NEVER GATING.  specs/** under board nodes.  Rationale,
           and it is deliberate: specs/** are analyst working notes with a
           lifetime of one ticket, not the tree's link health.  Printed with
           a count so nothing is invisible.

  Excluded outright — directories named scratch/: planning runs write into
  them and they are git-ignored.

Anchors are NOT validated: `#frag` is split off a path before resolving and a
pure `#frag` link is skipped.  Out of scope, on purpose.

Matching is over the WHOLE FILE TEXT, not per line.  This repo wraps markdown
at ~78 columns, so a link's [text] straddles a newline; a per-line walker
reports 0 broken while the target is gone.  That is the silent-pass class the
first stand-in walker demonstrated.  `--per-line` reproduces it, for the
comparison printed by --selftest.
"""
import argparse
import os
import re
import sys
from urllib.parse import unquote

LINK_RE = re.compile(r'\[(?P<text>[^\]]{0,400}?)\]\(\s*(?P<target>[^)\s]+)(?:\s+"[^"]*")?\s*\)', re.S)
FENCE_RE = re.compile(r'^(\s{0,3})(`{3,}|~{3,})')
SCHEME_RE = re.compile(r'^[A-Za-z][A-Za-z0-9+.\-]*:')


def strip_fences(text):
    """Blank out fenced code blocks, preserving the line count so reported
    line numbers stay true."""
    out = []
    fence = None
    for line in text.split('\n'):
        m = FENCE_RE.match(line)
        if fence is None:
            if m:
                fence = m.group(2)[0] * 3
                out.append('')
                continue
            out.append(line)
        else:
            if m and m.group(2)[0] * 3 == fence:
                fence = None
            out.append('')
    return '\n'.join(out)


def links_in(text, per_line=False):
    """Yield (line_no, target) for every markdown link."""
    if per_line:
        for i, line in enumerate(text.split('\n'), 1):
            for m in LINK_RE.finditer(line):
                yield i, m.group('target')
        return
    for m in LINK_RE.finditer(text):
        yield text.count('\n', 0, m.start()) + 1, m.group('target')


def collect(root):
    """(tier_a, tier_b) file lists, absolute paths."""
    a, b = [], []
    prds = os.path.join(root, 'prds')
    for dirpath, dirnames, filenames in os.walk(prds):
        dirnames[:] = [d for d in dirnames if d != 'scratch']
        in_specs = os.sep + 'specs' in dirpath + os.sep or os.path.basename(dirpath) == 'specs'
        for fn in filenames:
            if not fn.endswith('.md'):
                continue
            p = os.path.join(dirpath, fn)
            if in_specs:
                b.append(p)
            elif fn in ('prd.md', 'README.md'):
                a.append(p)
    docs = os.path.join(root, 'docs')
    if os.path.isdir(docs):
        for fn in sorted(os.listdir(docs)):
            if fn.startswith('capabilities') and fn.endswith('.md'):
                a.append(os.path.join(docs, fn))
    agents = os.path.join(root, 'AGENTS.md')
    if os.path.isfile(agents):
        a.append(agents)
    return sorted(set(a)), sorted(set(b))


def walk(files, root, per_line=False):
    """-> (checked, broken list of (relfile, line, target, resolved))"""
    checked = 0
    broken = []
    for path in files:
        try:
            with open(path, encoding='utf-8') as fh:
                text = fh.read()
        except OSError as exc:                      # pragma: no cover
            broken.append((os.path.relpath(path, root), 0, '<unreadable>', str(exc)))
            continue
        base = os.path.dirname(path)
        for line, target in links_in(strip_fences(text), per_line=per_line):
            if target.startswith('#') or target.startswith('//') or SCHEME_RE.match(target):
                continue
            checked += 1
            bare = unquote(target.split('#', 1)[0])
            if not bare:
                continue
            resolved = os.path.normpath(os.path.join(base, bare))
            if not os.path.exists(resolved):
                broken.append((os.path.relpath(path, root), line, target,
                               os.path.relpath(resolved, root)))
    return checked, broken


def report(name, files, root, gating, per_line=False, quiet=False):
    checked, broken = walk(files, root, per_line=per_line)
    tag = 'gating' if gating else 'not gating'
    print(f'{name} ({tag})')
    if not quiet:
        for relfile, line, target, resolved in broken:
            print(f'BROKEN {relfile}:{line} -> {target} ({resolved})')
    print(f'      checked {checked} links in {len(files)} files, {len(broken)} broken')
    return checked, broken


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument('--root', default=None, help='repo root to walk (default: this repo)')
    ap.add_argument('--per-line', action='store_true',
                    help='reproduce the broken per-line walker, for comparison')
    ap.add_argument('--tier', choices=('a', 'b', 'both'), default='both')
    ap.add_argument('--quiet-b', action='store_true', help='Tier B count only')
    ap.add_argument('--count-only', action='store_true', help='print only the Tier A broken count')
    args = ap.parse_args()

    root = os.path.abspath(args.root or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
    a, b = collect(root)

    if args.count_only:
        _, broken = walk(a, root, per_line=args.per_line)
        print(len(broken))
        return 1 if broken else 0

    print(f'tree link check — root {root}')
    print('      anchors are not validated; directories named scratch/ are never walked')
    if args.per_line:
        print('      PER-LINE matching — the historical silent-pass bug, for comparison only')

    broken_a = []
    if args.tier in ('a', 'both'):
        _, broken_a = report('TIER A', a, root, True, args.per_line)
    if args.tier in ('b', 'both'):
        report('TIER B', b, root, False, args.per_line, quiet=args.quiet_b)
    return 1 if broken_a else 0


if __name__ == '__main__':
    sys.exit(main())
