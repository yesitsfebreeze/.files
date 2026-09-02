#!/usr/bin/env python3
"""The work-breakdown table check — the gate for 00-delivery/work-breakdown.

This node's deliverable is a document, so its proof has to be a check over the
document rather than a reading of it.  The tables here are a *projection* of
the board: every row restates facts that live in a node's frontmatter, and a
restated fact drifts.  This script re-derives each of those facts and fails
when the table disagrees.

  THE SPINE is the `task:` key in each node's `prds/**/prd.md` frontmatter.
  Measured 2026-08-24: 70 nodes carry one, the ids are unique, and the set is
  identical to the task set in `gates/waves.tsv`, which `gates/wave-status.sh`
  already machine-reads.  That is the authority; the tables list a subset.

  THE GRAPH IS READ, NEVER RESTATED.  Dependency edges live in each node's
  `needs:` frontmatter and nowhere else — block form only, because an inline
  `needs: [a, b]` parses as one bogus path string and `needs: []` parses as
  the literal string `"[]"` (both measured; the empty form is a bare
  `needs:`).  This script reads that graph for C5 and C7.  A `Depends on`
  column is what C4 exists to prevent: the tables carried one until
  2026-08-21, by which point all 44 of its cells disagreed with the schedule.

Two tiers, one exit code — the shape `gates/tree-links.py` set.

  Tier A — GATING.  C1, C2, C3, C4, C6, C7, and the still-raceable half of
           C5.  Every one of these is a disagreement the document itself can
           fix by being rewritten.

  Tier B — REPORTED, NEVER GATING.  The landed half of C5: a same-wave file
           collision where at least one of the two tasks is already `done`.
           Rationale, and it is deliberate.  A collision is a statement about
           two agents writing one file *at the same time*; once one of the
           pair has landed, the second necessarily edits the file serially and
           the race is history.  More to the point, the defect such a pair
           reports lives in `needs:` or in `gates/waves.tsv` — neither of
           which this node may write — so gating on it would make this
           document uncloseable by anything it is allowed to do.  Printed in
           full, with a count, so nothing is invisible: `C5 historical:`.
           A pair where BOTH tasks are still unlanded can still race, is the
           document's own business to flag, and is red.

Matching is over the WHOLE FILE TEXT, not per line.  This repo wraps markdown
at ~78 columns: a table row is one line, but the Totals prose that C6 reads
and the fenced blocks C4/C7 reject are wrapped, and a per-line walker misses
them.

`gates/waves.tsv` is READ-ONLY here — it belongs to another lane.  This script
never writes outside its own directory and its `--selftest` scratch root.
"""
import argparse
import glob
import os
import re
import shutil
import sys
import tempfile

NODE_DIR = 'prds/00-delivery/work-breakdown'
BODY = NODE_DIR + '/prd.md'
WAVES = 'gates/waves.tsv'

FM_RE = re.compile(r'\A---\n(.*?)\n---\n', re.S)
FENCE_RE = re.compile(r'^(\s{0,3})(`{3,}|~{3,})')
ROW_ID_RE = re.compile(r'\[([^\]]+)\]\(([^)\s]+)\)')
TOKEN_RE = re.compile(r'`([^`\n]+)`(\s*\(planned\))?')
BANNED_HEADER_RE = re.compile(r'depend|block|after|before', re.I)
ARROW = '→'

TASK_HEADER = ['ID', 'Task', 'Size', 'Files']

# C6 anchors: a row whose first cell is the literal fact name.  Anchored on
# text, not on position, so reordering the Totals table cannot break the read.
TOTAL_TASKS_RE = re.compile(r'^\|\s*tasks\s*\|\s*([0-9]+)\s*\|', re.M | re.I)
TOTAL_EST_RE = re.compile(r'^\|\s*total\s+`est:`[^|]*\|\s*([0-9.]+)\s*h\s*\|',
                          re.M | re.I)

# --- C5 shared registries -------------------------------------------------
# Append-only files that many tasks add one line to.  Contention here is
# resolved at the wave gate by one actor, not by this table, so they are
# excluded from collision detection.  Each keeps its reason.  They are still
# listed in the rows that touch them: excluded from C5, never from C3.
REGISTRY_GLOBS = [
    'gates/waves.tsv',                      # wave registry, append-only
    'gates/manual/wave*.md',                # manual-gate registries, ditto
    'tests/nvim-options.sh',                # the nvim census every E task appends to
    'home/dot_config/nvim/lazy-lock.json',  # lockfile, regenerated not edited
    'home/dot_config/nushell/config.nu',    # the module funnel: every Track S
                                            # task adds one `source` line.
                                            # Track S is a `needs:` chain, so
                                            # C5 would pass it anyway — this
                                            # entry records that it is by
                                            # chain, not by luck.
    'home/dot_config/nvim/init.lua',         # the editor's module funnel: every
                                            # Track E config task adds one
                                            # `require` line, exactly as
                                            # Track S does to config.nu
    'home/dot_config/nushell/help/*.nuon',  # the manual: epic invariant 4 says
                                            # the task that creates a binding
                                            # writes its own entry, so every
                                            # topic file is append-only by
                                            # design.
]


class Node:
    __slots__ = ('task', 'rel', 'est', 'state', 'needs', 'path')

    def __init__(self, task, rel, est, state, needs, path):
        self.task, self.rel, self.est = task, rel, est
        self.state, self.needs, self.path = state, needs, path


def fm_scalar(fm, key):
    m = re.search(r'^' + key + r':[ \t]*(.*?)[ \t]*$', fm, re.M)
    if not m:
        return None
    return m.group(1).strip().strip('"').strip("'")


def fm_block(fm, key):
    """Read a block-form list.  Block form only, on purpose — see the module
    docstring: the inline and `[]` forms do not parse as paths anywhere in
    this tooling, so accepting them here would hide a real defect."""
    m = re.search(r'^' + key + r':[ \t]*$\n((?:[ \t]+-[ \t]+.*\n)*)', fm + '\n',
                  re.M)
    if not m:
        return []
    out = []
    for line in m.group(1).strip('\n').split('\n'):
        line = line.strip()
        if line.startswith('- '):
            out.append(re.sub(r'\s+#.*$', '', line[2:]).strip())
    return [x for x in out if x]


def read_board(root):
    """task id -> Node, plus board-relative path -> Node for every node."""
    by_task, by_rel, bogus = {}, {}, []
    pat = os.path.join(root, 'prds', '**', 'prd.md')
    for p in sorted(glob.glob(pat, recursive=True)):
        text = open(p, encoding='utf-8').read()
        m = FM_RE.match(text)
        if not m:
            continue
        fm = m.group(1)
        rel = os.path.relpath(os.path.dirname(p), os.path.join(root, 'prds'))
        node = Node(fm_scalar(fm, 'task'), rel, fm_scalar(fm, 'est'),
                    fm_scalar(fm, 'state'), fm_block(fm, 'needs'), p)
        by_rel[rel] = node
        raw = fm_scalar(fm, 'needs')
        if raw:                     # a scalar `needs:` is not a graph
            bogus.append((rel, raw))
        if node.task:
            by_task.setdefault(node.task, []).append(node)
    return by_task, by_rel, bogus


def reach(by_rel, start):
    """Every board node transitively reachable through `needs:`."""
    seen, stack = set(), list(by_rel[start].needs) if start in by_rel else []
    while stack:
        r = stack.pop()
        if r in seen:
            continue
        seen.add(r)
        if r in by_rel:
            stack.extend(by_rel[r].needs)
    return seen


def task_deps(by_task, by_rel):
    """task -> set of task ids it transitively depends on."""
    out = {}
    for t, nodes in by_task.items():
        got = set()
        for n in nodes:
            for r in reach(by_rel, n.rel):
                if r in by_rel and by_rel[r].task:
                    got.add(by_rel[r].task)
        out[t] = got - {t}
    return out


# --- markdown ------------------------------------------------------------
def blank_fences(text):
    """Blank fenced blocks, preserving line count."""
    out, fence = [], None
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


def fenced_blocks(text):
    """Yield (line_no, block_text) for every fenced block."""
    out, fence, buf, start = [], None, [], 0
    for i, line in enumerate(text.split('\n'), 1):
        m = FENCE_RE.match(line)
        if fence is None:
            if m:
                fence, buf, start = m.group(2)[0] * 3, [], i
        else:
            if m and m.group(2)[0] * 3 == fence:
                out.append((start, '\n'.join(buf)))
                fence = None
            else:
                buf.append(line)
    return out


def cells(line):
    return [c.strip() for c in line.strip().strip('|').split('|')]


def tables(text):
    """Yield (line_no, header_cells, [(line_no, cells), ...])."""
    lines = text.split('\n')
    out, i = [], 0
    while i < len(lines):
        if lines[i].lstrip().startswith('|'):
            j = i
            while j < len(lines) and lines[j].lstrip().startswith('|'):
                j += 1
            block = lines[i:j]
            if len(block) >= 2 and re.match(r'^\|[\s:|-]+\|\s*$', block[1]):
                rows = [(i + 1 + k, cells(b)) for k, b in enumerate(block[2:],
                                                                    start=2)]
                out.append((i + 1, cells(block[0]), rows))
            i = j
        else:
            i += 1
    return out


def files_tokens(cell):
    """[(token, planned_bool)] for a Files cell."""
    return [(m.group(1).strip(), bool(m.group(2)))
            for m in TOKEN_RE.finditer(cell)]


def resolves(root, token):
    p = os.path.join(root, token)
    if os.path.exists(p):
        return True
    return bool(glob.glob(p, recursive=True))


def expand(root, token, planned):
    """The concrete file set a token names, for C5.  A planned token names
    itself: it does not exist yet, so it can only collide by name."""
    if planned:
        return {token.rstrip('/')}
    hits = glob.glob(os.path.join(root, token), recursive=True)
    if not hits:
        return {token.rstrip('/')}
    out = set()
    for h in hits:
        r = os.path.relpath(h, root)
        if os.path.isdir(h):
            for dp, _, fns in os.walk(h):
                for fn in fns:
                    out.add(os.path.relpath(os.path.join(dp, fn), root))
        else:
            out.add(r)
    return out or {token.rstrip('/')}


def is_registry(path):
    for g in REGISTRY_GLOBS:
        if path == g:
            return True
        # fnmatch-free: the globs here are one-segment wildcards
        gd, gb = os.path.split(g)
        pd, pb = os.path.split(path)
        if gd == pd and '*' in gb:
            pre, _, suf = gb.partition('*')
            if pb.startswith(pre) and pb.endswith(suf):
                return True
    return False


def read_waves(root):
    """wave -> [task ids].  Read-only: this file belongs to another lane."""
    out = {}
    p = os.path.join(root, WAVES)
    if not os.path.exists(p):
        return out
    for line in open(p, encoding='utf-8'):
        if line.startswith('#') or not line.strip():
            continue
        parts = line.rstrip('\n').split('\t')
        if len(parts) < 2 or parts[0].strip() == 'wave':
            continue
        out[parts[0].strip()] = parts[1].split()
    return out


# --- the checks ----------------------------------------------------------
def longest_chain(by_task, deps):
    """The longest `est:`-weighted chain over the task-restricted graph."""
    def hours(t):
        e = by_task[t][0].est or '0h'
        try:
            return float(e.rstrip('h'))
        except ValueError:
            return 0.0

    memo, busy = {}, set()

    def best(t):
        if t in memo:
            return memo[t]
        if t in busy:                       # cycle guard
            return (hours(t), [t])
        busy.add(t)
        top = (0.0, [])
        for d in deps.get(t, ()):
            if d not in by_task:
                continue
            cand = best(d)
            if cand[0] > top[0]:
                top = cand
        busy.discard(t)
        memo[t] = (top[0] + hours(t), top[1] + [t])
        return memo[t]

    return max((best(t) for t in by_task), key=lambda x: x[0],
               default=(0.0, []))


def check(root, verbose=True):
    """Run every check.  Returns (red_count, reported_count, lines)."""
    out, red, reported = [], 0, 0

    def bad(msg):
        nonlocal red
        red += 1
        out.append(msg)

    by_task, by_rel, bogus = read_board(root)
    deps = task_deps(by_task, by_rel)
    for rel, raw in bogus:
        bad('C0 %s: `needs: %s` is scalar, not block form — it parses as a '
            'path string and edges are lost' % (rel, raw))

    body_path = os.path.join(root, BODY)
    raw_text = open(body_path, encoding='utf-8').read()
    m = FM_RE.match(raw_text)
    text = raw_text[m.end():] if m else raw_text
    # Report FILE line numbers, not body-relative ones: a reader opens the
    # file, not the body.
    off = raw_text[:m.end()].count('\n') if m else 0
    flat = blank_fences(text)

    ids = sorted(by_task)
    id_re = re.compile(r'(?<![A-Za-z0-9.])(' +
                       '|'.join(sorted((re.escape(i) for i in ids),
                                       key=len, reverse=True)) +
                       r')(?![A-Za-z0-9])')

    task_rows = []          # (id, line, size, files_cell, task_cell, target)
    all_tables = tables(flat)
    for tline, header, rows in all_tables:
        for h in header:
            if BANNED_HEADER_RE.search(h):
                bad('C4 line %d: column header %r restates the graph — it '
                    'lives in `needs:`' % (tline + off, h))
        # A task table is any table whose first two columns are ID and Task.
        # Recognised by that prefix rather than by the exact header, so a
        # table that grew a column is parsed and reported, not skipped: the
        # `Spec` column Track P carried was invisible to a header-equality
        # test, and every P row then read as a missing row.
        is_task_table = header[:2] == TASK_HEADER[:2]
        if is_task_table and header != TASK_HEADER:
            bad('C1 line %d: task table columns are %s, want %s — one shape '
                'for every table' % (tline + off, '|'.join(header),
                                     '|'.join(TASK_HEADER)))
        for rline, cs in rows:
            own = None
            if is_task_table and cs:
                mm = ROW_ID_RE.search(cs[0])
                own = mm.group(1) if mm else cs[0]
            for c in cs:
                if ARROW in c:
                    bad('C4 line %d: table cell contains %s — no restated '
                        'edges in a cell' % (rline + off, ARROW))
                for f in id_re.findall(c):
                    if f != own:
                        bad('C4 line %d: cell names task %s, which is not '
                            'this row (%s)' % (rline + off, f, own or '-'))
            if not is_task_table:
                continue
            col = {h: i for i, h in enumerate(header)}
            if not all(k in col for k in TASK_HEADER) or len(cs) < len(header):
                bad('C1 line %d: task row does not carry %s'
                    % (rline + off, '|'.join(TASK_HEADER)))
                continue
            size, files, task_cell = (cs[col['Size']], cs[col['Files']],
                                      cs[col['Task']])
            mm = ROW_ID_RE.search(cs[col['ID']])
            if not mm:
                bad('C1 line %d: ID cell %r is not a link to its node'
                    % (rline + off, cs[col['ID']]))
                task_rows.append((cs[col['ID']], rline + off, size, files,
                                  task_cell, None))
                continue
            task_rows.append((mm.group(1), rline + off, size, files,
                              task_cell, mm.group(2)))

    for line, block in fenced_blocks(text):
        if ARROW in block:
            bad('C7 line %d: the body carries a fenced %s chain — the '
                'critical path is computed, not frozen (--critical-path)'
                % (line + off, ARROW))

    # C1 — bijection
    seen = {}
    for rid, rline, _, _, _, target in task_rows:
        if rid in seen:
            bad('C1 line %d: duplicate row for %s (first at line %d)'
                % (rline, rid, seen[rid]))
        else:
            seen[rid] = rline
        if rid not in by_task:
            bad('C1 line %d: row %s has no board node carrying that `task:`'
                % (rline, rid))
            continue
        if target:
            want = os.path.normpath(os.path.join(root, NODE_DIR, target))
            got = [os.path.normpath(n.path) for n in by_task[rid]]
            if want not in got:
                bad('C1 line %d: row %s links %s, but its node is %s'
                    % (rline, rid, target,
                       os.path.relpath(got[0], root)))
    for t in ids:
        if len(by_task[t]) > 1:
            bad('C1 board: task %s is carried by %d nodes'
                % (t, len(by_task[t])))
        if t not in seen:
            bad('C1 missing row: %s (%s)' % (t, by_task[t][0].rel))

    # C2 — Size is the node's est:, verbatim
    for rid, rline, size, _, _, _ in task_rows:
        if rid not in by_task:
            continue
        want = by_task[rid][0].est
        if size != want:
            bad('C2 line %d: %s Size is %r, `est:` is %r'
                % (rline, rid, size, want))

    # C3 — Files resolve
    row_files = {}
    for rid, rline, _, cell, _, _ in task_rows:
        toks = files_tokens(cell)
        if not toks:
            bad('C3 line %d: %s Files cell has no path token (%r)'
                % (rline, rid, cell))
            continue
        state = by_task[rid][0].state if rid in by_task else None
        keep = []
        for tok, planned in toks:
            if planned:
                if resolves(root, tok):
                    bad('C3 line %d: %s marks `%s` (planned) but it exists'
                        % (rline, rid, tok))
                elif state == 'done':
                    bad('C3 line %d: %s is done and still marks `%s` '
                        '(planned)' % (rline, rid, tok))
            elif not resolves(root, tok):
                bad('C3 line %d: %s names `%s`, which does not resolve'
                    % (rline, rid, tok))
                continue
            keep.append((tok, planned))
        row_files[rid] = keep

    # C5 — same-wave collisions
    waves = read_waves(root)
    hist = []
    for wave in sorted(waves):
        members = [t for t in waves[wave] if t in row_files]
        owners = {}
        for t in members:
            for tok, planned in row_files[t]:
                for f in expand(root, tok, planned):
                    if is_registry(f):
                        continue
                    owners.setdefault(f, set()).add(t)
        pairs = {}
        for f, ts in owners.items():
            if len(ts) < 2:
                continue
            for a in sorted(ts):
                for b in sorted(ts):
                    if a >= b:
                        continue
                    if b in deps.get(a, ()) or a in deps.get(b, ()):
                        continue
                    pairs.setdefault((a, b), []).append(f)
        for (a, b), fs in sorted(pairs.items()):
            sa = by_task[a][0].state
            sb = by_task[b][0].state
            msg = ('wave %s: %s vs %s on %s' % (wave, a, b, sorted(fs)[0]) +
                   ('' if len(fs) == 1 else ' (+%d more)' % (len(fs) - 1)))
            if sa == 'done' or sb == 'done':
                hist.append('C5 historical: %s [%s/%s]' % (msg, sa, sb))
            else:
                bad('C5 %s — both unlanded (%s/%s), so they can still race'
                    % (msg, sa, sb))

    # C6 — totals
    n_tasks, tot = len(ids), sum(
        float((by_task[t][0].est or '0h').rstrip('h')) for t in ids)
    tot = round(tot, 4)
    mt = TOTAL_TASKS_RE.search(flat)
    me = TOTAL_EST_RE.search(flat)
    if not mt:
        bad('C6: no `| tasks | <n> |` row in the body — the count anchor')
    elif int(mt.group(1)) != n_tasks:
        bad('C6: body states %s tasks, the board carries %d'
            % (mt.group(1), n_tasks))
    if not me:
        bad('C6: no ``| total `est:` … | <n>h |`` row in the body')
    elif abs(float(me.group(1)) - tot) > 1e-6:
        bad('C6: body states %sh of `est:`, the board carries %gh'
            % (me.group(1), tot))

    # C7 — the critical path, computed
    length, chain = longest_chain(by_task, deps)
    out.append('C7 critical path (%gh, %d tasks): %s'
               % (round(length, 4), len(chain), ' '.join(chain)))
    reported = len(hist)
    out.extend(hist)
    if hist:
        out.append('C5 reported %d historical collision(s) — never gating; '
                   'see the module docstring for why' % len(hist))
    out.append('summary: %d task(s), %gh of `est:`, %d red, %d reported'
               % (n_tasks, tot, red, reported))
    if verbose:
        for line in out:
            print(line)
    return red, reported, out


# --- selftest ------------------------------------------------------------
MUTATIONS = [
    ('C1', BODY, lambda t: re.sub(r'\n\| \[T\.8\][^\n]*', '', t, count=1),
     'delete the T.8 row'),
    ('C2', BODY, lambda t: re.sub(r'(\| \[T\.8\][^|]*\|[^|]*\| )2\.5h',
                                  r'\1L', t, count=1),
     'replace T.8 Size 2.5h with the letter L'),
    ('C3', BODY,
     lambda t: t.replace('`home/dot_config/wezterm/wezterm.lua`',
                         '`home/dot_config/nvim/lua/plugins/editor.lua`', 1),
     'point a Files token at a file that does not exist'),
    ('C4', BODY, lambda t: re.sub(r'(\| \[T\.8\]\([^)]*\) \| )',
                                  r'\1T.2 ' + ARROW + ' ', t, count=1),
     'restate an edge inside a table cell'),
    ('C5', BODY,
     lambda t: re.sub(r'(\| \[E\.14\]\([^)]*\) \|[^|]*\|[^|]*\| )',
                      r'\1`home/dot_config/nvim/lua/plugins/gitsigns.lua`, ',
                      t, count=1),
     'give two unlanded wave-4 tasks the same file'),
    ('C6', BODY, lambda t: re.sub(r'(\|\s*tasks\s*\|\s*)[0-9]+', r'\g<1>56',
                                  t, count=1),
     'state the old task count in Totals'),
    ('C7', BODY,
     lambda t: t.replace('## Totals',
                         '## Totals\n\n```\nW0.3 ' + ARROW + ' P.1 ' + ARROW +
                         ' S.1\n```\n', 1),
     'freeze a critical-path chain in a fence'),
]


def scratch_host(root):
    keep = os.environ.get('GATES_KEEP_TMP')
    host = keep or tempfile.mkdtemp(prefix='check-tables-')
    os.makedirs(host, exist_ok=True)
    for name in sorted(os.listdir(root)):
        if name in ('.git', '.DS_Store'):
            continue
        src, dst = os.path.join(root, name), os.path.join(host, name)
        if os.path.lexists(dst):
            continue
        if name in ('prds', 'gates'):
            shutil.copytree(src, dst, symlinks=True)
        else:
            os.symlink(os.path.abspath(src), dst)
    return host


def selftest(root):
    host = scratch_host(root)
    print('MUTATION HOST: %s' % host)
    log, ok = [], True
    originals = {}
    for cid, rel, fn, why in MUTATIONS:
        p = os.path.join(host, rel)
        before = open(p, encoding='utf-8').read()
        originals.setdefault(rel, before)
        after = fn(before)
        print('MUTATION: %s — %s (%s)' % (cid, why, rel))
        if after == before:
            print('  FAIL %s: the mutation changed nothing — it would have '
                  'proved nothing' % cid)
            ok = False
            log.append('%s no-op' % cid)
            continue
        open(p, 'w', encoding='utf-8').write(after)
        red, _, lines = check(host, verbose=False)
        hit = [l for l in lines if re.match(cid + r'[ :]', l)]
        open(p, 'w', encoding='utf-8').write(originals[rel])
        if red and hit:
            print('  went red: %s' % hit[0])
            log.append('%s red: %s' % (cid, hit[0]))
        else:
            print('  FAIL %s: %d red, %d line(s) attributed to %s'
                  % (cid, red, len(hit), cid))
            ok = False
            log.append('%s NOT red' % cid)

    red, reported, lines = check(host, verbose=False)
    print('GREEN counterfactual: %d red, %d reported' % (red, reported))
    for l in lines:
        if not l.startswith('C5 historical'):
            print('  %s' % l)
    if red:
        ok = False
        print('  FAIL: the repaired scratch copy is still red')
    log.append('green: %d red' % red)
    with open(os.path.join(host, 'mutations.log'), 'w',
              encoding='utf-8') as fh:
        fh.write('\n'.join(log) + '\n')
    print('selftest: %s' % ('OK' if ok else 'FAILED'))
    return 0 if ok else 1


def find_root(start):
    d = os.path.abspath(start)
    while True:
        if os.path.isdir(os.path.join(d, 'prds')) and \
           os.path.isfile(os.path.join(d, BODY)):
            return d
        nd = os.path.dirname(d)
        if nd == d:
            return os.path.abspath(start)
        d = nd


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--root', help='repo root (default: found from cwd)')
    ap.add_argument('--critical-path', action='store_true',
                    help='print only the computed critical path')
    ap.add_argument('--selftest', action='store_true',
                    help='induce each check against a scratch copy')
    a = ap.parse_args()
    root = a.root or find_root(os.getcwd())
    if not os.path.isfile(os.path.join(root, BODY)):
        print('not a repo root: %s' % root, file=sys.stderr)
        return 2
    if a.selftest:
        return selftest(root)
    if a.critical_path:
        by_task, by_rel, _ = read_board(root)
        length, chain = longest_chain(by_task, task_deps(by_task, by_rel))
        print('critical path: %gh over %d tasks' % (round(length, 4),
                                                    len(chain)))
        print(' '.join(chain))
        return 0
    red, _, _ = check(root)
    return 1 if red else 0


if __name__ == '__main__':
    sys.exit(main())
