#!/usr/bin/env python3
"""check-waves.py — the proof that `parallelization/prd.md` still matches the
board.  This node's deliverable is a document; a document whose only proof is
a human reading it is unproven.

WHAT IT DOES NOT DO.  It states no wave membership and keeps no list of
tasks, paths or exceptions.  Every fact it checks is re-derived from the
board on each run:

  * task -> node comes from the `task:` key in each `prds/**/prd.md`
    frontmatter, the same resolution `gates/wave-status.sh` uses;
  * the wave rows come from `gates/waves.tsv`, which belongs to another lane
    and is READ-ONLY here;
  * the dependency graph comes from `needs:` and nowhere else;
  * the shared-registry exemptions are PARSED OUT OF THE DOCUMENT's own
    table, so the document cannot claim an exemption the check does not
    honour, or honour one the document does not claim.

There is no A3.  The spec for this check carried one — "no stale exception
row" — and it was deleted along with the exception table it policed.  A rule
derived from `needs:` has no rows to go stale, so the assertion has nothing
left to assert.  The numbering keeps the gap on purpose: the ids are cited
from `prd.md`, and renumbering would silently repoint them.

THE ORDERING RULE, DERIVED.  Two writers on one exclusive-content path are
legal iff one of them TRANSITIVELY depends on the other through `needs:`.
That replaces the three-row exception table the document used to carry.  A
declared table rots: the version deleted on 2026-08-24 named a file that no
longer existed, and named three of another file's four writers — so a
path-keyed whitelist licensed the fourth against all three.  The closure
flags exactly that pair.  Direct edges are not enough: ordering through an
intermediate is still ordering, and a direct-edge test reports ordered pairs
as races.

THE PARSER IS THE POINT.  `.claude/skills/pearde/view/plan.py`'s `parse_prd`
handles BLOCK lists only.  An inline `footprint: [a, b]` is stored as the
scalar string `"[a, b]"` and becomes one bogus path that overlaps nothing;
`footprint: []` becomes the literal one-element path `"[]"`; an inline
`needs: [a, b]` fails lookup with `no such PRD, ignored`.  That blindness is
half of what this node exists to expose, so this check parses BOTH forms.
Reusing the planner's parser would inherit the bug and report green.

TWO TIERS, ONE EXIT CODE — the shape `check-tables.py` set.

  Tier A — GATING.  A2 (live-vs-live collision), A4, A5, A6, A7, A8.  Every
           one of these is a disagreement the document itself can fix by
           being rewritten.

  Tier B — REPORTED, NEVER GATING.  A1 (delegated registry integrity) and
           the landed half of A2.  Rationale, and it is deliberate: those
           defects live in `gates/waves.tsv` or in another node's `needs:`,
           neither of which this node may write, so gating on them would
           make this document uncloseable by anything it is allowed to do.
           Printed in full, with counts, so nothing is invisible.

Tables in the document are recognised by their header PREFIX, not by header
equality.  A table that grows a column must still be parsed and reported, not
silently skipped — an extra column made five rows invisible to a sibling
check that tested equality.

Nothing under `gates/` is written, and this script declares no `--selftest`
handler inside `gates/`: `gates/waves.tsv` is held by another lane, and a
`gates/*.sh --selftest` would be pulled into the `gates/selftest.sh`
contract, which a check that reads the live board cannot honour.

  python3 prds/00-delivery/parallelization/check-waves.py [--root DIR]
  python3 prds/00-delivery/parallelization/check-waves.py --census
  python3 prds/00-delivery/parallelization/check-waves.py --selftest
"""
import argparse
import fnmatch
import glob
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

NODE_DIR = 'prds/00-delivery/parallelization'
BODY = NODE_DIR + '/prd.md'
WAVES = 'gates/waves.tsv'
SETTINGS = 'prds/settings.md'
PLAN = '.claude/skills/pearde/view/plan.py'
VALIDATE = 'gates/wave-status.sh'

# ── ratchets ──────────────────────────────────────────────────────────────
# Each is a count that may FALL but never RISE.  A ratchet, not a gate: the
# violations predate this node and fixing them means editing other nodes'
# frontmatter, which is not in this footprint.  When a count falls the script
# prints the lower number and says to lower the constant; it never lowers it
# itself, because a self-adjusting baseline is not a baseline.
MEASURED = '2026-08-24'
BASE_DEPS_KEY = 0        # nodes carrying `deps:`, a key the planner never reads
BASE_INLINE = 0          # prd.md/spec files using an inline `[...]` list.
                         # Lowered 2 -> 0 on 2026-08-24 by the orchestrator,
                         # on this check's own instruction: the two remaining
                         # cases were `footprint: []` in done nodes' specs and
                         # were converted to the bare form. A ratchet left at 2
                         # when reality is 0 lets two regressions in silently.
BASE_NO_FOOTPRINT = 52   # registry tasks with no readable footprint (of 70)

FM_RE = re.compile(r'\A---\n(.*?)\n---\n', re.S)
# A task id, as the document's own membership ban defines it.
TASK_ID_RE = re.compile(r'(?<![A-Za-z0-9.])(W0\.\d\w*|[PSETCHDG]\.\d+\w*)'
                        r'(?![A-Za-z0-9])')
REGISTRY_HEADER = ['pattern', 'writers']
ADVERSARIAL_HEADER = ['task', 'node']


# ── frontmatter: BOTH list forms ─────────────────────────────────────────
def fm_of(text):
    m = FM_RE.match(text)
    return m.group(1) if m else ''


def fm_scalar(fm, key):
    m = re.search(r'^' + key + r':[ \t]*(.*?)[ \t]*$', fm, re.M)
    if not m:
        return None
    v = re.sub(r'\s+#.*$', '', m.group(1)).strip().strip('"').strip("'")
    return v or None


def clean(v):
    return re.sub(r'\s+#.*$', '', v).strip().strip('"').strip("'").rstrip('/')


def fm_list(fm, key):
    """Block form AND inline form, comments and quotes stripped.  The planner
    reads only the first; this check reads both, on purpose."""
    m = re.search(r'^' + key + r':[ \t]*$\n((?:[ \t]+-[ \t]+.*\n)*)',
                  fm + '\n', re.M)
    if m and m.group(1).strip():
        out = []
        for line in m.group(1).strip('\n').split('\n'):
            line = line.strip()
            if line.startswith('- '):
                v = clean(line[2:])
                if v:
                    out.append(v)
        return out
    m = re.search(r'^' + key + r':[ \t]*\[(.*?)\][ \t]*(?:#.*)?$', fm, re.M)
    if m:
        return [clean(x) for x in m.group(1).split(',') if clean(x)]
    return []


def has_inline_list(fm):
    return bool(re.search(r'^(?:needs|footprint):[ \t]*\[', fm, re.M))


class Node:
    __slots__ = ('task', 'rel', 'state', 'needs', 'feet', 'path')

    def __init__(self, task, rel, state, needs, feet, path):
        self.task, self.rel, self.state = task, rel, state
        self.needs, self.feet, self.path = needs, feet, path


def read_board(root):
    """rel -> Node, task -> [rel], and the two input censuses."""
    by_rel, by_task = {}, {}
    deps_key, inline = [], []
    for p in sorted(glob.glob(os.path.join(root, 'prds', '**', 'prd.md'),
                              recursive=True)):
        text = open(p, encoding='utf-8').read()
        if not FM_RE.match(text):
            continue
        fm = fm_of(text)
        rel = os.path.relpath(os.path.dirname(p), os.path.join(root, 'prds'))
        feet = set(fm_list(fm, 'footprint'))
        if has_inline_list(fm):
            inline.append(os.path.relpath(p, root))
        sdir = os.path.join(os.path.dirname(p), 'specs')
        for s in sorted(glob.glob(os.path.join(sdir, '*.md'))):
            sfm = fm_of(open(s, encoding='utf-8').read())
            feet |= set(fm_list(sfm, 'footprint'))
            if has_inline_list(sfm):
                inline.append(os.path.relpath(s, root))
        state = fm_scalar(fm, 'state')
        node = Node(fm_scalar(fm, 'task'), rel, state,
                    fm_list(fm, 'needs'), feet, p)
        by_rel[rel] = node
        if node.task:
            by_task.setdefault(node.task, []).append(rel)
        if fm_list(fm, 'deps') or fm_scalar(fm, 'deps'):
            if state != 'done':
                deps_key.append(rel)
    return by_rel, by_task, deps_key, sorted(set(inline))


def closure(by_rel, rel):
    """Every node transitively reachable through `needs:` — the closure, not
    the direct edge: ordering through an intermediate is still ordering."""
    seen, stack = set(), list(by_rel[rel].needs) if rel in by_rel else []
    while stack:
        r = stack.pop()
        if r in seen:
            continue
        seen.add(r)
        if r in by_rel:
            stack.extend(by_rel[r].needs)
    return seen


def task_closure(by_rel, by_task):
    out = {}
    for t, rels in by_task.items():
        got = set()
        for r in rels:
            for x in closure(by_rel, r):
                if x in by_rel and by_rel[x].task:
                    got.add(by_rel[x].task)
        out[t] = got - {t}
    return out


def feet_of(by_rel, by_task, t):
    s = set()
    for r in by_task.get(t, ()):
        s |= by_rel[r].feet
    return s


def state_of(by_rel, by_task, t):
    rels = by_task.get(t, ())
    return by_rel[rels[0]].state if rels else None


def overlap(a, b):
    """Matches the planner's `overlap`: equality or prefix-with-separator."""
    return a == b or a.startswith(b + '/') or b.startswith(a + '/')


def read_waves(root):
    """wave -> [task ids].  READ-ONLY: this file belongs to another lane."""
    out, p = {}, os.path.join(root, WAVES)
    if not os.path.isfile(p):
        return out
    for line in open(p, encoding='utf-8'):
        if line.startswith('#') or not line.strip():
            continue
        parts = line.rstrip('\n').split('\t')
        if len(parts) < 2 or parts[0].strip() in ('wave', ''):
            continue
        out[parts[0].strip()] = parts[1].split()
    return out


# ── the document ─────────────────────────────────────────────────────────
def cells(line):
    return [c.strip() for c in line.strip().strip('|').split('|')]


def tables(text):
    """(line_no, header_cells, [(line_no, cells)]) for every pipe table."""
    lines, out, i = text.split('\n'), [], 0
    while i < len(lines):
        if lines[i].lstrip().startswith('|'):
            j = i
            while j < len(lines) and lines[j].lstrip().startswith('|'):
                j += 1
            block = lines[i:j]
            if len(block) >= 2 and re.match(r'^\s*\|[\s:|-]+\|\s*$', block[1]):
                rows = [(i + 1 + k, cells(b))
                        for k, b in enumerate(block[2:], start=2)]
                out.append((i + 1, cells(block[0]), rows))
            i = j
        else:
            i += 1
    return out


def header_is(header, want):
    """PREFIX match, lowercased.  A table that grew a column is still that
    table; an equality test would skip it and report its rows as missing."""
    return [h.lower() for h in header[:len(want)]] == want


def unfence(text):
    """Blank fenced blocks, preserving line numbers."""
    out, fence = [], None
    for line in text.split('\n'):
        m = re.match(r'^(\s{0,3})(`{3,}|~{3,})', line)
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


def read_doc(root):
    """(registry patterns, adversarial (task, node) pairs, body text, offset,
    the line span the adversarial table occupies)."""
    p = os.path.join(root, BODY)
    raw = open(p, encoding='utf-8').read()
    m = FM_RE.match(raw)
    text, off = (raw[m.end():], raw[:m.end()].count('\n')) if m else (raw, 0)
    flat = unfence(text)
    pats, adv, adv_lines = [], [], set()
    for tline, header, rows in tables(flat):
        if header_is(header, REGISTRY_HEADER):
            for _, cs in rows:
                v = cs[0].strip().strip('`')
                if v:
                    pats.append(v)
        elif header_is(header, ADVERSARIAL_HEADER):
            for rline, cs in rows:
                adv_lines.add(rline)
                node = None
                mm = re.search(r'\[`([^`]+)`\]', cs[1])
                if mm:
                    node = mm.group(1)
                adv.append((cs[0].strip().strip('`'), node, rline))
    return pats, adv, flat, off, adv_lines


# ── the checks ───────────────────────────────────────────────────────────
class Report:
    def __init__(self):
        self.red, self.notes, self.lines = 0, 0, []

    def ok(self, aid, msg):
        self.lines.append('PASS %-3s %s' % (aid, msg))

    def fail(self, aid, msg):
        self.red += 1
        self.lines.append('FAIL %-3s %s' % (aid, msg))

    def note(self, aid, msg):
        self.notes += 1
        self.lines.append('     %-3s %s' % (aid, msg))

    def report(self, aid, msg):
        self.lines.append('RPT  %-3s %s' % (aid, msg))


def plan_output(root):
    p = os.path.join(root, PLAN)
    if not os.path.isfile(p):
        return None
    try:
        r = subprocess.run([sys.executable, PLAN, 'plan'], cwd=root,
                           capture_output=True, text=True, timeout=180)
    except Exception:
        return None
    return r.stdout


def check(root, rep=None):
    rep = rep or Report()
    by_rel, by_task, deps_key, inline = read_board(root)
    tdeps = task_closure(by_rel, by_task)
    waves = read_waves(root)
    pats, adv, flat, off, adv_lines = read_doc(root)
    reg_tasks = [t for w in sorted(waves) for t in waves[w]]

    def is_registry(path):
        return any(path == g or fnmatch.fnmatch(path, g) for g in pats)

    # A1 — registry integrity, DELEGATED and REPORTED (Tier B).
    vp = os.path.join(root, VALIDATE)
    if not os.path.isfile(vp):
        rep.fail('A1', 'no %s to delegate registry integrity to' % VALIDATE)
    else:
        r = subprocess.run(['bash', VALIDATE, '--validate'], cwd=root,
                           capture_output=True, text=True)
        bad = [l.strip() for l in r.stdout.splitlines()
               if l.strip().startswith('FAIL')]
        if r.returncode == 0:
            rep.ok('A1', '`%s --validate` exits 0 — membership is proven '
                         'there, not restated here' % VALIDATE)
        else:
            rep.report('A1', '`%s --validate` exits %d, %d FAIL line(s) — '
                             'REPORTED, never gating: that file belongs to '
                             'another lane' % (VALIDATE, r.returncode,
                                               len(bad)))
            for l in bad:
                rep.report('A1', '  %s' % l)

    # A2 — the ordering rule.  Every un-ordered pair of writers on an
    # exclusive-content path.  Live-vs-live is red; a landed side is
    # reported, because the fix lives in `needs:` or in the registry.
    wave_of = {t: w for w in waves for t in waves[w]}
    writers = {}
    for t in set(reg_tasks):
        for f in feet_of(by_rel, by_task, t):
            writers.setdefault(f, set()).add(t)
    seen_pairs, red_pairs, hist = set(), [], []
    for f, ts in writers.items():
        if is_registry(f):
            continue
        for a in sorted(ts):
            for b in sorted(ts):
                if a >= b:
                    continue
                if b in tdeps.get(a, ()) or a in tdeps.get(b, ()):
                    continue
                paths = sorted({x for x in feet_of(by_rel, by_task, a)
                                for y in feet_of(by_rel, by_task, b)
                                if overlap(x, y) and not is_registry(x)})
                key = (a, b)
                if key in seen_pairs:
                    continue
                seen_pairs.add(key)
                sa = state_of(by_rel, by_task, a)
                sb = state_of(by_rel, by_task, b)
                na = by_task[a][0]
                nb = by_task[b][0]
                same = wave_of.get(a) == wave_of.get(b)
                msg = ('%s (%s, %s, wave %s) vs %s (%s, %s, wave %s) on %s'
                       % (a, na, sa, wave_of.get(a), b, nb, sb,
                          wave_of.get(b), ' '.join(paths)))
                if sa != 'done' and sb != 'done' and same:
                    red_pairs.append(msg)
                else:
                    hist.append(msg)
    if red_pairs:
        for m in red_pairs:
            rep.fail('A2', 'un-ordered same-wave writers, both unlanded: %s'
                     % m)
    else:
        rep.ok('A2', 'no live-vs-live un-ordered writer pair on an '
                     'exclusive-content path (%d pair(s) checked)'
               % len(seen_pairs))
    if hist:
        rep.report('A2', '%d un-ordered writer pair(s) with a landed side or '
                         'a wave boundary between them — REPORTED, never '
                         'gating: the fix is in `needs:`' % len(hist))
        for m in hist:
            rep.report('A2', '  %s' % m)

    # A4 — every claimed registry pattern has more than one writer.
    if not pats:
        rep.fail('A4', 'the document declares no shared-registry pattern '
                       'table — the exemption list is the check\'s input')
    else:
        thin = []
        for g in pats:
            n = sum(len(ts) for f, ts in writers.items()
                    if f == g or fnmatch.fnmatch(f, g))
            if n < 2:
                thin.append('%s has %d writer(s)' % (g, n))
        if thin:
            rep.fail('A4', 'unused registry exemption(s) — a hole waiting '
                           'for a genuine clash: %s' % '; '.join(thin))
        else:
            rep.ok('A4', 'all %d registry pattern(s) have >1 measured writer'
                   % len(pats))

    # A5 — the cap agrees.
    sp = os.path.join(root, SETTINGS)
    want = fm_scalar(fm_of(open(sp, encoding='utf-8').read()), 'workers') \
        if os.path.isfile(sp) else None
    out = plan_output(root)
    got = None
    if out:
        mm = re.search(r'workers=(\d+)', out)
        got = mm.group(1) if mm else None
    if want is None:
        rep.fail('A5', 'no `workers:` in %s' % SETTINGS)
    elif got is None:
        rep.fail('A5', '`plan` printed no `workers=` to compare %s against'
                 % SETTINGS)
    elif want != got:
        rep.fail('A5', '%s says workers: %s, `plan` says workers=%s'
                 % (SETTINGS, want, got))
    else:
        rep.ok('A5', 'cap agrees: %s workers: %s == `plan` workers=%s'
               % (SETTINGS, want, got))

    # A6 — the document copies no wave membership.
    stray = []
    for i, line in enumerate(flat.split('\n'), 1):
        if i in adv_lines:
            continue
        for mm in TASK_ID_RE.finditer(line):
            stray.append((i + off, mm.group(1)))
    if stray:
        rep.fail('A6', 'task id(s) outside the adversarial-verify table — '
                       'membership belongs to %s: %s'
                 % (WAVES, ', '.join('line %d: %s' % s for s in stray[:8])))
    else:
        rep.ok('A6', 'no task id outside the adversarial-verify table')

    # A7 — the adversarial-verify nodes resolve, and there are exactly three.
    if len(adv) != 3:
        rep.fail('A7', 'the adversarial-verify table names %d task(s), want '
                       '3 — `gates/manual-coverage.sh` reads this list'
                 % len(adv))
    missing = [(t, n) for t, n, _ in adv
               if not n or not os.path.isfile(
                   os.path.join(root, 'prds', n, 'prd.md'))]
    bad_id = [(t, n) for t, n, _ in adv if t not in by_task]
    if missing:
        rep.fail('A7', 'adversarial entry names no resolvable node: %s'
                 % ', '.join('%s -> %s' % (t, n) for t, n in missing))
    if bad_id:
        rep.fail('A7', 'adversarial task id carried by no board node: %s'
                 % ', '.join(t for t, _ in bad_id))
    if len(adv) == 3 and not missing and not bad_id:
        rep.ok('A7', 'three adversarial-verify tasks, each resolving: %s'
               % ', '.join('%s=%s (%s)'
                           % (t, n, state_of(by_rel, by_task, t))
                           for t, n, _ in adv))

    # A8 — the readable-input ratchet.
    nofp = [t for t in sorted(set(reg_tasks))
            if not feet_of(by_rel, by_task, t)]
    for label, got_n, base in (
            ('undone nodes carrying `deps:`, a key the planner never reads',
             len(deps_key), BASE_DEPS_KEY),
            ('files using an inline `[...]` needs:/footprint:',
             len(inline), BASE_INLINE),
            ('registry tasks with no readable footprint',
             len(nofp), BASE_NO_FOOTPRINT)):
        if got_n > base:
            rep.fail('A8', '%s: %d, baseline %d (measured %s) — the ratchet '
                           'only turns down' % (label, got_n, base, MEASURED))
        elif got_n < base:
            rep.note('A8', '%s: %d, below the %s baseline of %d — lower the '
                           'constant in this script' % (label, got_n,
                                                        MEASURED, base))
        else:
            rep.ok('A8', '%s: %d, at the %s baseline' % (label, got_n,
                                                         MEASURED))
    return rep, dict(by_rel=by_rel, by_task=by_task, waves=waves,
                     writers=writers, nofp=nofp, deps_key=deps_key,
                     inline=inline, pats=pats, plan=out)


# ── census ───────────────────────────────────────────────────────────────
def census(root):
    rep, d = check(root, Report())
    writers, pats = d['writers'], d['pats']
    print('== writers per declared path (descending) ==')
    for f, ts in sorted(writers.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        if len(ts) < 2:
            continue
        kind = 'registry' if any(f == g or fnmatch.fnmatch(f, g)
                                 for g in pats) else 'exclusive'
        print('  %2d  %-9s %s' % (len(ts), kind, f))
    print('\n== registered tasks with no readable footprint (%d) =='
          % len(d['nofp']))
    print('  ' + ' '.join(d['nofp']))
    print('\n== input census ==')
    print('  undone nodes carrying `deps:`   %d' % len(d['deps_key']))
    print('  files with an inline [...] list %d' % len(d['inline']))
    for f in d['inline']:
        print('    %s' % f)
    print('\n== plan waves: min(members, workers) ==')
    out = d['plan'] or ''
    mm = re.search(r'workers=(\d+)', out)
    workers = int(mm.group(1)) if mm else 0
    for m in re.finditer(r'^wave (\d+) — (\d+) in parallel', out, re.M):
        n = int(m.group(2))
        print('  wave %-3s members %-4d workers %d -> %d agent(s)'
              % (m.group(1), n, workers, min(n, workers) if workers else n))
    print('\n== un-ordered writer pairs ==')
    for l in rep.lines:
        if l.startswith('RPT  A2') or l.startswith('FAIL A2'):
            print('  ' + l.strip())
    return 0


# ── selftest ─────────────────────────────────────────────────────────────
# Every path --selftest mutates inside its scratch copy.  A change to one of
# these in the REAL tree is this script's fault and is red; a change anywhere
# else is another lane's own work and is reported.
SELFTEST_WRITES = [
    'prds/zz-scratch-*/*',
    'prds/settings.md',
    'prds/00-delivery/parallelization/prd.md',
    'gates/waves.tsv',
]

NEW_NODE_FM = ('---\nstate: open\ntask: %s\nkind: feature\nneeds:\n'
               'footprint:\n  - %s\nverify: ""\n---\n\n# scratch %s\n')
NEW_NODE_INLINE = ('---\nstate: open\ntask: %s\nkind: feature\nneeds:\n'
                   'footprint: [%s]\nverify: ""\n---\n\n# scratch %s\n')
CLASH = 'home/dot_config/nvim/lua/config/keymaps.lua'


def tree_files(root):
    """rel -> sha256, over prds/ and the wave registry. Per-file, so a
    failed byte-identity assertion can NAME what moved instead of printing a
    hash nobody can act on."""
    out = {}
    for base in ('prds', WAVES):
        p = os.path.join(root, base)
        files = []
        if os.path.isdir(p):
            for dp, _, fns in os.walk(p):
                for fn in fns:
                    files.append(os.path.join(dp, fn))
        elif os.path.isfile(p):
            files = [p]
        for f in sorted(files):
            with open(f, 'rb') as fh:
                out[os.path.relpath(f, root)] = hashlib.sha256(
                    fh.read()).hexdigest()
    return out


def tree_hash(root, files=None):
    h = hashlib.sha256()
    for rel, digest in sorted((files or tree_files(root)).items()):
        h.update(rel.encode())
        h.update(digest.encode())
    return h.hexdigest()


def scratch(root):
    """A scratch board: prds/ and gates/ copied, everything else symlinked."""
    host = tempfile.mkdtemp(prefix='check-waves-')
    for name in sorted(os.listdir(root)):
        if name in ('.git', '.DS_Store'):
            continue
        src, dst = os.path.join(root, name), os.path.join(host, name)
        if name in ('prds', 'gates'):
            shutil.copytree(src, dst, symlinks=True)
        else:
            os.symlink(os.path.abspath(src), dst)
    return host


def plant(host, task, path, inline=False):
    d = os.path.join(host, 'prds', 'zz-scratch-' + task.replace('.', '-'))
    os.makedirs(d, exist_ok=True)
    tpl = NEW_NODE_INLINE if inline else NEW_NODE_FM
    open(os.path.join(d, 'prd.md'), 'w', encoding='utf-8').write(
        tpl % (task, path, task))
    return d


def add_wave_row(host, tasks):
    p = os.path.join(host, WAVES)
    with open(p, 'a', encoding='utf-8') as fh:
        fh.write('9\t%s\t\n' % ' '.join(tasks))


def patch_body(host, fn):
    p = os.path.join(host, BODY)
    t = open(p, encoding='utf-8').read()
    n = fn(t)
    changed = n != t
    open(p, 'w', encoding='utf-8').write(n)
    return changed


def aid_lines(rep, aid):
    return [l for l in rep.lines
            if l.startswith('FAIL') and l.split()[1] == aid]


def selftest(root):
    before = tree_files(root)
    ok = True

    def case(name, aid, build, want_red=True):
        nonlocal ok
        host = scratch(root)
        h0 = tree_hash(host)
        print('MUTATION HOST: %s' % host)
        print('MUTATION: %s — %s' % (aid, name))
        build(host)
        h1 = tree_hash(host)
        if h1 == h0:
            print('  FAIL: the mutation changed nothing — it would have '
                  'proved nothing')
            ok = False
            shutil.rmtree(host, ignore_errors=True)
            return
        rep, _ = check(host, Report())
        hits = aid_lines(rep, aid)
        if want_red and hits:
            print('  went red: %s' % hits[0].strip())
        elif want_red:
            print('  FAIL: %d red, none attributed to %s' % (rep.red, aid))
            for l in rep.lines:
                if l.startswith('FAIL'):
                    print('    %s' % l.strip())
            ok = False
        elif hits:
            print('  FAIL: expected green on %s, got: %s' % (aid,
                                                             hits[0].strip()))
            ok = False
        else:
            print('  stayed green on %s (%d red overall)' % (aid, rep.red))
        shutil.rmtree(host, ignore_errors=True)

    # Baseline: the real board and registry pass.
    host = scratch(root)
    print('MUTATION HOST: %s' % host)
    print('MUTATION: -- — baseline, no mutation (green counterfactual)')
    rep, _ = check(host, Report())
    print('  %d red, %d reported line(s)' % (rep.red, sum(
        1 for l in rep.lines if l.startswith('RPT'))))
    if rep.red:
        ok = False
        for l in rep.lines:
            if l.startswith('FAIL'):
                print('    %s' % l.strip())
        print('  FAIL: the unmutated scratch copy is red')
    shutil.rmtree(host, ignore_errors=True)

    def pair(inline=False):
        def build(host):
            plant(host, 'Z.1', CLASH)
            plant(host, 'Z.2', CLASH, inline=inline)
            add_wave_row(host, ['Z.1', 'Z.2'])
        return build

    case('two live tasks, one wave, one exclusive path, block footprint',
         'A2', pair())
    case('the same pair with the second footprint in INLINE form — the '
         'planner would see no overlap at all', 'A2', pair(inline=True))

    def ordered(host):
        pair()(host)
        d = os.path.join(host, 'prds', 'zz-scratch-Z-2', 'prd.md')
        t = open(d, encoding='utf-8').read()
        open(d, 'w', encoding='utf-8').write(
            t.replace('needs:\n', 'needs:\n  - zz-scratch-Z-1\n'))
    case('the same pair, ordered by `needs:` — the derived rule licenses it, '
         'no exception row needed', 'A2', ordered, want_red=False)

    def transitive(host):
        pair()(host)
        plant(host, 'Z.3', 'home/dot_config/zz-mid.nu')
        for name, need in (('zz-scratch-Z-2', 'zz-scratch-Z-3'),
                           ('zz-scratch-Z-3', 'zz-scratch-Z-1')):
            p = os.path.join(host, 'prds', name, 'prd.md')
            t = open(p, encoding='utf-8').read()
            open(p, 'w', encoding='utf-8').write(
                t.replace('needs:\n', 'needs:\n  - %s\n' % need))
    case('the same pair ordered THROUGH an intermediate — the closure sees '
         'it, a direct-edge test would not', 'A2', transitive, want_red=False)

    case('a registry pattern with no writer on the board', 'A4',
         lambda h: patch_body(h, lambda t: t.replace(
             '| `gates/waves.tsv` |',
             '| `gates/zz-no-such-registry.tsv` | 0 |\n| `gates/waves.tsv` |',
             1)))
    def drop_workers(host):
        # Editing the value alone proves nothing: `plan` reads the same file,
        # so it would report the new number and the two would still agree.
        # The failure A5 exists for is the document naming a cap source that
        # does not carry the key, while `plan` quietly falls back to a
        # default.
        p = os.path.join(host, SETTINGS)
        t = open(p, encoding='utf-8').read()
        assert re.search(r'^workers:', t, re.M), 'fixture has no workers:'
        open(p, 'w', encoding='utf-8').write(
            re.sub(r'^workers:.*\n', '', t, count=1, flags=re.M))
    case('prds/settings.md no longer carries `workers:`, the cap source the '
         'document names', 'A5', drop_workers)
    case('a wave-membership row appended to the document', 'A6',
         lambda h: patch_body(h, lambda t: t + '\n| wave | tasks |\n|---|'
                                               '---|\n| 3 | S.1 E.3 T.2 |\n'))

    def drop_adversarial(host):
        # The row is indented inside a list item; anchor on the leading
        # whitespace, not on a bare newline.
        changed = patch_body(host, lambda t: re.sub(
            r'\n[ \t]*\|[ \t]*S\.4[ \t]*\|[^\n]*', '', t, count=1))
        assert changed, 'the adversarial row pattern matched nothing'
    case('one adversarial row removed from the document', 'A7',
         drop_adversarial)
    case('one scratch node carrying a non-empty `deps:`', 'A8',
         lambda h: open(os.path.join(plant(h, 'Z.9', 'home/zz-deps.nu'),
                                     'prd.md'), 'a',
                        encoding='utf-8').write('') or patch_deps(h))

    after = tree_files(root)
    moved = ([('+', k) for k in sorted(set(after) - set(before))] +
             [('-', k) for k in sorted(set(before) - set(after))] +
             [('~', k) for k in sorted(set(before) & set(after))
              if before[k] != after[k]])
    # A moved path is this selftest's fault only if the selftest writes that
    # path in scratch.  Anything else is a CONCURRENT LANE editing a file it
    # owns — measured while writing this: another implementer saved a spec
    # mid-run.  Gating on that would make the assertion fail on someone
    # else's correct work, so it is reported instead, in full.
    mine, theirs = [], []
    for sign, k in moved:
        (mine if any(fnmatch.fnmatch(k, g) for g in SELFTEST_WRITES)
         else theirs).append('%s %s' % (sign, k))
    if theirs:
        print('concurrent lane(s) touched %d file(s) during the run — '
              'REPORTED, not this selftest\'s writes:' % len(theirs))
        for m in theirs[:20]:
            print('  %s' % m)
    if mine:
        print('FAIL: --selftest wrote a path it only ever mutates in scratch')
        for m in mine[:20]:
            print('  %s' % m)
        ok = False
    else:
        print('the real prds/ and %s carry none of this selftest\'s writes '
              '(%d files scanned, sha256 %s)'
              % (WAVES, len(before), tree_hash(root, before)[:12]))
    print('selftest: %s' % ('OK' if ok else 'FAILED'))
    return 0 if ok else 1


def patch_deps(host):
    p = os.path.join(host, 'prds', 'zz-scratch-Z-9', 'prd.md')
    t = open(p, encoding='utf-8').read()
    open(p, 'w', encoding='utf-8').write(
        t.replace('needs:\n', 'needs:\ndeps:\n  - 00-delivery\n'))


def find_root(start):
    d = os.path.abspath(start)
    while True:
        if os.path.isfile(os.path.join(d, BODY)):
            return d
        nd = os.path.dirname(d)
        if nd == d:
            return os.path.abspath(start)
        d = nd


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--root', help='repo root (default: found from cwd)')
    ap.add_argument('--census', action='store_true',
                    help='print the derived data and exit 0')
    ap.add_argument('--selftest', action='store_true',
                    help='induce each assertion against a scratch board')
    a = ap.parse_args()
    root = a.root or find_root(os.getcwd())
    if not os.path.isfile(os.path.join(root, BODY)):
        print('not a repo root: %s' % root, file=sys.stderr)
        return 2
    if a.selftest:
        return selftest(root)
    if a.census:
        return census(root)
    rep, _ = check(root, Report())
    for l in rep.lines:
        print(l)
    print('summary: %d red, %d note(s)' % (rep.red, rep.notes))
    return 1 if rep.red else 0


if __name__ == '__main__':
    sys.exit(main())
