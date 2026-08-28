#!/usr/bin/env python3
"""Census probe for waves-registry-missing-s10 R4.

The question R4 asks is NOT the one `gates/wave-status.sh --validate` answers.
Validate holds two INDEPENDENT set-coverage assertions:

  * every board `task:` id appears in some wave row's tasks cell;
  * every script under tests/ is named by some wave row's gates cell.

Neither ties a node to ITS OWN gate. A node's task can sit in wave 3 while the
script its `verify:` names is registered only in wave 5, and both assertions
stay green — the gate then arms on a wave that has nothing to do with the node.
So the census walks the pairing directly, plus the two classes validate does
cover, so the numbers are comparable.

Population: every node under prds/ whose frontmatter carries BOTH `task:` and
`state: done`. That is the population R4 names — "every `done` node with a
tests/ gate" — enumerated before the answer is known, and the nodes with no
gate at all are counted rather than filtered out, because "no gate" is the
same defect one step earlier.

Usage:
  python3 <this> [--registry gates/waves.tsv] [--board prds]
  python3 <this> --selftest      # counterfactuals: the census can go red
"""
import re
import sys
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]

SCRIPT_RE = re.compile(r'(?:tests|gates)/[A-Za-z0-9._-]+\.(?:sh|nu|py)')


def frontmatter(path):
    txt = path.read_text(encoding='utf-8', errors='replace')
    if not txt.startswith('---\n'):
        return {}
    end = txt.find('\n---', 3)
    if end < 0:
        return {}
    fm = {}
    for line in txt[4:end].split('\n'):
        m = re.match(r'^([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.*)$', line)
        if m:
            fm.setdefault(m.group(1), m.group(2).strip())
    return fm


def board(board_dir):
    """[(task, node, state, verify)] for every prd.md carrying `task:`."""
    out = []
    for p in sorted(board_dir.rglob('prd.md')):
        fm = frontmatter(p)
        if 'task' not in fm:
            continue
        node = str(p.parent.relative_to(board_dir))
        out.append((fm['task'], node, fm.get('state', ''),
                    fm.get('verify', '').strip('"').strip("'")))
    return out


def rows(registry):
    """[(wave, [tasks], gates_cell)] — comments and header dropped."""
    out = []
    for line in registry.read_text().split('\n'):
        if line.startswith('#') or not line.strip():
            continue
        f = line.split('\t')
        if len(f) < 3 or f[0] in ('wave', ''):
            continue
        out.append((f[0], f[1].split(), f[2]))
    return out


def census(registry, board_dir, verbose=True):
    R = rows(registry)
    B = board(board_dir)
    done = [b for b in B if b[2] == 'done']

    wave_of_task = {}
    for w, tasks, _ in R:
        for t in tasks:
            wave_of_task.setdefault(t, []).append(w)
    waves_naming = {}   # script basename -> [wave]
    for w, _, gates in R:
        for s in SCRIPT_RE.findall(gates):
            waves_naming.setdefault(s.split('/')[-1], []).append(w)

    no_gate, unregistered, mispaired, ok, offtree = [], [], [], [], []
    for task, node, _, verify in done:
        scripts = [s for s in SCRIPT_RE.findall(verify)]
        if not scripts:
            # A `verify:` that names a runnable script OUTSIDE tests/ and
            # gates/ is the S.10 defect with the assertion blind by
            # construction: validate's script sweep globs tests/* only, so
            # nothing can ever report it unreferenced.
            other = re.search(r'(\S+\.(?:sh|nu|py))', verify)
            if other and (REPO / other.group(1)).is_file():
                offtree.append((task, node, other.group(1)))
            else:
                no_gate.append((task, node, verify))
            continue
        tw = set(wave_of_task.get(task, []))
        for s in sorted(set(scripts)):
            base = s.split('/')[-1]
            sw = set(waves_naming.get(base, []))
            if not sw:
                unregistered.append((task, node, base))
            elif not (tw & sw):
                mispaired.append((task, node, base, sorted(tw), sorted(sw)))
            else:
                ok.append((task, node, base))

    if verbose:
        print(f'── registry census · {registry} · {board_dir}')
        print(f'   board nodes carrying `task:`      {len(B)}')
        print(f'   of those, `state: done`           {len(done)}   <- the population')
        print()
        print(f'A  done node, gate registered in its own wave row   {len(ok)}')
        print(f'B  done node, gate named by NO row (the S.10 class) {len(unregistered)}')
        for t, n, s in unregistered:
            print(f'     {t:6} {n}  ->  tests/{s}')
        print(f'C  done node, gate registered in a DIFFERENT wave   {len(mispaired)}')
        for t, n, s, tw, sw in mispaired:
            print(f'     {t:6} {n}  ->  {s}: task in wave {tw}, script in wave {sw}')
        print(f'D  done node whose gate script lives OUTSIDE tests/|gates/  {len(offtree)}')
        for t, n, s in offtree:
            print(f'     {t:6} {n}  ->  {s}')
        print(f'E  done node whose `verify:` names no script at all {len(no_gate)}')
        for t, n, v in no_gate:
            print(f'     {t:6} {n}  ->  verify: {v!r}')
    return dict(nodes=len(B), done=len(done), ok=ok, offtree=offtree,
                unregistered=unregistered, mispaired=mispaired, no_gate=no_gate)


def selftest():
    """The census must be able to report B and C. Both are planted."""
    rc = 0
    tmp = Path(tempfile.mkdtemp(prefix='census-'))
    reg = REPO / 'gates' / 'waves.tsv'
    brd = REPO / 'prds'
    print(f'      MUTATION HOST: {tmp}')

    base = census(reg, brd, verbose=False)
    print(f'baseline: B={len(base["unregistered"])} C={len(base["mispaired"])}')

    # B: drop the gates cell entry naming tests/shell-litellm.sh.
    r_b = tmp / 'waves-drop-script.tsv'
    r_b.write_text(re.sub(r'\s*\|\s*external bash tests/shell-litellm\.sh', '',
                          reg.read_text()))
    print(f'      MUTATION: {r_b} drops the gates entry naming tests/shell-litellm.sh')
    b = census(r_b, brd, verbose=False)
    hit = any(s == 'shell-litellm.sh' for _, _, s in b['unregistered'])
    print(f'{"PASS" if hit else "FAIL"}  class B is reported when a done node\'s '
          f'gate is named by no row (B={len(b["unregistered"])})')
    rc |= 0 if hit else 1

    # C: move that same entry into a different wave row. Both of validate's
    # assertions stay GREEN here — this is the case only the census sees.
    txt = reg.read_text()
    txt = re.sub(r'\s*\|\s*external bash tests/shell-litellm\.sh', '', txt)
    lines = txt.split('\n')
    for i, line in enumerate(lines):
        f = line.split('\t')
        if len(f) >= 3 and f[0] == '1':
            f[2] += ' | external bash tests/shell-litellm.sh'
            lines[i] = '\t'.join(f)
    r_c = tmp / 'waves-mispaired.tsv'
    r_c.write_text('\n'.join(lines))
    print(f'      MUTATION: {r_c} registers tests/shell-litellm.sh in wave 1, '
          f'while S.10 stays in wave 5')
    c = census(r_c, brd, verbose=False)
    hit = any(s == 'shell-litellm.sh' for _, _, s, _, _ in c['mispaired'])
    print(f'{"PASS" if hit else "FAIL"}  class C is reported when a gate is '
          f'registered in a wave its node is not in (C={len(c["mispaired"])})')
    rc |= 0 if hit else 1

    v = subprocess.run(['bash', 'gates/wave-status.sh', '--validate',
                        '--registry', str(r_c)], cwd=REPO,
                       capture_output=True, text=True)
    green = v.returncode == 0
    print(f'{"PASS" if green else "FAIL"}  and `--validate` stays GREEN on that '
          f'mispaired registry (exit {v.returncode}) — the gap this census covers')
    rc |= 0 if green else 1

    shutil.rmtree(tmp, ignore_errors=True)
    print(f'── census selftest rc={rc}')
    return rc


if __name__ == '__main__':
    args = sys.argv[1:]
    if '--selftest' in args:
        sys.exit(selftest())
    reg = REPO / 'gates' / 'waves.tsv'
    brd = REPO / 'prds'
    if '--registry' in args:
        reg = Path(args[args.index('--registry') + 1])
    if '--board' in args:
        brd = Path(args[args.index('--board') + 1])
    census(reg, brd)
