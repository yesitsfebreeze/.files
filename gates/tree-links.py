#!/usr/bin/env python3
"""The tree link check — Wave 0's half of R4, and the cause-fix for the `[~]`
stand-in box in 00-delivery/corrections/w0-3-platform-rewrite.

ONE GATING SET.  Every prd.md and README.md under prds/, every specs/** file
under a board node, docs/capabilities*.md, and AGENTS.md at the repo root.  A
broken link anywhere in that set fails the gate.

  Excluded outright — directories named scratch/: planning runs write into
  them and they are git-ignored.

The two tiers, and why they are gone (2026-08-24)
-------------------------------------------------
Until 2026-08-24 this script ran two tiers: Tier A gated, Tier B (specs/**,
plus the generated .mi/gantt/*.md, plan.md and delivery-gantt.md) was printed
and never gated.  The split was deliberate and recorded — the rationale is in
prds/00-delivery/verification-gates/specs/spec02.md, and it named two classes:

  (1) a generated file's broken link is the generator's bug and no lane may
      hand-edit it; and
  (2) specs/** are "working notes with a lifetime of one ticket", not the
      tree's link health.

Both reasons have expired, measured 2026-08-24:

  (1) is empty — the mi planning machinery is retired and collect() gathers no
      generated file at all.
  (2) is contradicted — 19 markdown links in Tier A prd.md/README.md bodies
      point *into* specs/**, AGENTS.md directs every agent to read a node's
      spec before implementing, and all 19 nodes that carried the 119 broken
      Tier B links are `done`, so their specs are a permanent record and not a
      one-ticket note.  A permanently-advisory tier is a check that cannot
      fail, which this board has ruled against.

Neither original reason named a link that *cannot resolve*.  One such class
does exist, and it is the only exemption (2026-08-24):

  target-file-vantage — a spec's "What to write" section quotes markup that
  will be written *into another file*.  Those relative links resolve from the
  target file's directory, not from the spec's, so repairing them from the
  spec's vantage would falsify the instruction.  A line

      <!-- tree-links: target-file-vantage — <reason> -->

  exempts every link from its own line to the next line beginning with '## ',
  or EOF.  Three constraints keep it from becoming an off-switch for the
  tree's own gate:

    * the reason text is MANDATORY (>= 10 non-space characters after the em
      dash) — a constraint carries its reason in this repo;
    * the marker is honoured ONLY in files under a specs/ directory; in a
      prd.md, a README.md, AGENTS.md or docs/ it is a HARD ERROR;
    * exempted links are COUNTED and printed, never invisible.

Anchors are NOT validated: `#frag` is split off a path before resolving and a
pure `#frag` link is skipped.  A target of nothing but dots — `(...)`, the
elided citation this repo writes in prose — is not a path and is skipped the
same way.  Out of scope, on purpose.

Matching is over the WHOLE FILE TEXT, not per line.  This repo wraps markdown
at ~78 columns, so a link's [text] straddles a newline; a per-line walker
reports 0 broken while the target is gone.  That is the silent-pass class the
first stand-in walker demonstrated.  `--per-line` reproduces it, for the
comparison printed by --selftest.

Fenced code blocks are blanked before matching, and so are inline code spans:
a spec that quotes a link inside backticks is discussing a link, not making
one.  Both strippers preserve the line count so reported line numbers stay
true.  Measured 2026-08-24: code-span stripping removed 8 links from the
specs/** corpus and 0 from the prd.md/README.md corpus.
"""
import argparse
import os
import re
import sys
from urllib.parse import unquote

LINK_RE = re.compile(r'\[(?P<text>[^\]]{0,400}?)\]\(\s*(?P<target>[^)\s]+)(?:\s+"[^"]*")?\s*\)', re.S)
FENCE_RE = re.compile(r'^(\s{0,3})(`{3,}|~{3,})')
SCHEME_RE = re.compile(r'^[A-Za-z][A-Za-z0-9+.\-]*:')
DOTS_ONLY_RE = re.compile(r'^\.+$')
BACKTICK_RUN_RE = re.compile(r'`+')
BLANK_LINE_RE = re.compile(r'\n[ \t]*\n')
# Any tree-links directive.  Parsed loosely on purpose: an unknown name or a
# missing reason must be reported, not silently ignored.
DIRECTIVE_RE = re.compile(r'<!--\s*tree-links:\s*(?P<name>[A-Za-z0-9_-]+)(?P<rest>.*?)-->', re.S)
HEADING_RE = re.compile(r'^## ', re.M)
MIN_REASON_CHARS = 10


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


def strip_code_spans(text):
    """Blank out inline code spans, preserving both the line count and every
    character offset so reported line numbers stay true.

    Pairing follows CommonMark and NOT a naive regex, and the difference is
    load-bearing: a backtick run only closes a run of the SAME length, and a
    run that never finds its match is literal text.  Measured 2026-08-24, a
    regex that let a run of one close a run of two mispaired every span after
    the lone ``…`` in prds/04-shell/01-core-config/prd.md and blanked three
    live Tier A links out of existence.  The blank-line guard is the second
    half: a code span cannot cross a paragraph break, so an opener whose only
    same-length partner is past a blank line stays literal instead of
    swallowing the rest of the file.
    """
    runs = [(m.start(), m.end()) for m in BACKTICK_RUN_RE.finditer(text)]
    out = list(text)
    i = 0
    while i < len(runs):
        start, open_end = runs[i]
        n = open_end - start
        j = i + 1
        while j < len(runs) and (runs[j][1] - runs[j][0]) != n:
            j += 1
        if j >= len(runs) or BLANK_LINE_RE.search(text, open_end, runs[j][0]):
            i += 1
            continue
        for k in range(start, runs[j][1]):
            if out[k] != '\n':
                out[k] = ' '
        i = j + 1
    return ''.join(out)


def line_of(text, pos):
    return text.count('\n', 0, pos) + 1


def directives(text, relfile, in_specs):
    """-> (exempt_ranges, errors).

    exempt_ranges is a list of (first_line, last_line) inclusive; errors is a
    list of (relfile, line, message)."""
    ranges, errors = [], []
    for m in DIRECTIVE_RE.finditer(text):
        line = line_of(text, m.start())
        name = m.group('name')
        if name != 'target-file-vantage':
            errors.append((relfile, line, f'unknown tree-links directive "{name}"'))
            continue
        rest = m.group('rest').lstrip()
        if rest.startswith('—'):
            reason = rest[1:]
        elif rest.startswith('--'):
            reason = rest[2:]
        else:
            errors.append((relfile, line,
                           'target-file-vantage marker has no "— <reason>"; '
                           'the reason text is mandatory'))
            continue
        if len(re.sub(r'\s', '', reason)) < MIN_REASON_CHARS:
            errors.append((relfile, line,
                           'target-file-vantage marker reason is shorter than '
                           f'{MIN_REASON_CHARS} non-space characters; a silent '
                           'escape hatch is not allowed'))
            continue
        if not in_specs:
            errors.append((relfile, line,
                           'target-file-vantage marker outside specs/ — the '
                           'marker is honoured only in a node spec, never in a '
                           'prd.md, README.md or docs page'))
            continue
        nxt = HEADING_RE.search(text, m.end())
        end = line_of(text, nxt.start()) - 1 if nxt else text.count('\n') + 1
        ranges.append((line, end))
    return ranges, errors


def links_in(text, per_line=False):
    """Yield (line_no, target) for every markdown link."""
    if per_line:
        for i, line in enumerate(text.split('\n'), 1):
            for m in LINK_RE.finditer(line):
                yield i, m.group('target')
        return
    for m in LINK_RE.finditer(text):
        yield line_of(text, m.start()), m.group('target')


def is_specs(path, root):
    rel = os.path.relpath(path, root)
    return 'specs' in rel.split(os.sep)[:-1]


def collect(root):
    """(tier_a, tier_b) file lists, absolute paths.  Both are gated; the split
    survives only as a reporting filter (--tier)."""
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
    """-> (checked, broken, exempt_links, exempt_files, errors)

    broken is a list of (relfile, line, target, resolved); errors is a list of
    (relfile, line, message) — a malformed or misplaced directive."""
    checked = 0
    broken = []
    errors = []
    exempt_links = 0
    exempt_files = 0
    for path in files:
        relfile = os.path.relpath(path, root)
        try:
            with open(path, encoding='utf-8') as fh:
                text = fh.read()
        except OSError as exc:                      # pragma: no cover
            broken.append((relfile, 0, '<unreadable>', str(exc)))
            continue
        text = strip_code_spans(strip_fences(text))
        ranges, errs = directives(text, relfile, is_specs(path, root))
        errors.extend(errs)
        base = os.path.dirname(path)
        file_exempt = 0
        for line, target in links_in(text, per_line=per_line):
            if any(lo <= line <= hi for lo, hi in ranges):
                file_exempt += 1
                continue
            if (target.startswith('#') or target.startswith('//')
                    or SCHEME_RE.match(target) or DOTS_ONLY_RE.match(target)):
                continue
            checked += 1
            bare = unquote(target.split('#', 1)[0])
            if not bare:
                continue
            resolved = os.path.normpath(os.path.join(base, bare))
            if not os.path.exists(resolved):
                broken.append((relfile, line, target,
                               os.path.relpath(resolved, root)))
        exempt_links += file_exempt
        if file_exempt:
            exempt_files += 1
    return checked, broken, exempt_links, exempt_files, errors


def report(name, files, root, per_line=False, quiet=False):
    checked, broken, ex_links, ex_files, errors = walk(files, root, per_line=per_line)
    print(f'{name} (gating)')
    if not quiet:
        for relfile, line, target, resolved in broken:
            print(f'BROKEN {relfile}:{line} -> {target} ({resolved})')
    for relfile, line, msg in errors:
        print(f'ERROR {relfile}:{line} -> {msg}')
    print(f'      checked {checked} links in {len(files)} files, {len(broken)} broken')
    print(f'      exempt {ex_links} links in {ex_files} files (target-file-vantage)')
    if errors:
        print(f'      {len(errors)} directive errors')
    return broken, errors


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument('--root', default=None, help='repo root to walk (default: this repo)')
    ap.add_argument('--per-line', action='store_true',
                    help='reproduce the broken per-line walker, for comparison')
    ap.add_argument('--tier', choices=('a', 'b', 'both'), default='both',
                    help='reporting filter only — every tier gates since 2026-08-24')
    ap.add_argument('--quiet-b', action='store_true', help='specs/** count only')
    ap.add_argument('--count-only', action='store_true',
                    help='print only the broken count for the selected tier')
    args = ap.parse_args()

    root = os.path.abspath(args.root or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
    a, b = collect(root)

    if args.count_only:
        files = a if args.tier == 'a' else b if args.tier == 'b' else a + b
        _, broken, _, _, errors = walk(files, root, per_line=args.per_line)
        print(len(broken))
        return 1 if broken or errors else 0

    print(f'tree link check — root {root}')
    print('      anchors are not validated; directories named scratch/ are never walked')
    print('      one gating set since 2026-08-24; --tier is a reporting filter only')
    if args.per_line:
        print('      PER-LINE matching — the historical silent-pass bug, for comparison only')

    broken, errors = [], []
    if args.tier == 'both':
        broken, errors = report('TREE', a + b, root, args.per_line)
    elif args.tier == 'a':
        broken, errors = report('TIER A', a, root, args.per_line)
    else:
        broken, errors = report('TIER B', b, root, args.per_line, quiet=args.quiet_b)
    return 1 if broken or errors else 0


if __name__ == '__main__':
    sys.exit(main())
