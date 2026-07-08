#!/usr/bin/env python3
import sys, os, json, subprocess

_COLORS = {
    'black': 30, 'red': 31, 'green': 32, 'yellow': 33,
    'blue': 34, 'magenta': 35, 'cyan': 36, 'white': 37,
    'gray': 90, 'grey': 90,
    'bright_red': 91, 'bright_green': 92, 'bright_yellow': 93,
    'bright_blue': 94, 'bright_magenta': 95, 'bright_cyan': 96, 'bright_white': 97,
}
_STYLES = {'bold': 1, 'dim': 2, 'italic': 3, 'underline': 4}

def _paint(text, color=None, style=None):
    if 'NO_COLOR' in os.environ or not text:
        return text
    codes = []
    if style:
        names = [style] if isinstance(style, str) else style
        codes.extend(_STYLES[s] for s in names if s in _STYLES)
    if color and color in _COLORS:
        codes.append(_COLORS[color])
    if not codes:
        return text
    return '\x1b[{}m{}\x1b[0m'.format(';'.join(str(c) for c in codes), text)

def _toplevel():
    r = subprocess.run(['git', 'rev-parse', '--show-toplevel'],
                       capture_output=True, text=True)
    return r.stdout.strip() if not r.returncode else None

def _load_config(top):
    plugin_default = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), '..', 'statusline.json')
    for path in [os.path.join(top, '.claude', 'statusline.json'),
                 os.path.join(top, '.voit', 'statusline.json'),
                 plugin_default]:
        try:
            with open(path) as f:
                return json.load(f)
        except Exception:
            pass
    return None

def _run_cmd(cmd, cwd, env):
    try:
        r = subprocess.run(['sh', '-c', cmd], cwd=cwd, env=env,
                           capture_output=True, text=True, timeout=2,
                           stdin=subprocess.DEVNULL)
        if r.returncode != 0:
            return None
        v = r.stdout.strip()
        return v if v else None
    except Exception:
        return None

def _render_slot(slot, cwd, env):
    text = slot.get('text', '')
    cmds = slot.get('cmd', {})
    vals = {}
    for name, cmd in cmds.items():
        v = _run_cmd(cmd, cwd, env)
        if v is None:
            return None
        vals[name] = v
    try:
        rendered = text.format(**vals)
    except Exception:
        return None
    return _paint(rendered, slot.get('color'), slot.get('style'))

def _lines(cfg):
    if isinstance(cfg, list):
        return cfg, {}
    if isinstance(cfg.get('lines'), list):
        return cfg['lines'], cfg
    return [cfg], {}

def _render_line(line, defaults, cwd, env):
    if isinstance(line, list):
        slots, opts = line, {}
    else:
        slots, opts = line.get('slots', []), line
    sep = _paint(opts.get('sep', defaults.get('sep', ' | ')),
                 opts.get('sep_color', defaults.get('sep_color')),
                 opts.get('sep_style', defaults.get('sep_style')))
    parts = [s for s in (_render_slot(slot, cwd, env) for slot in slots)
             if s is not None]
    return sep.join(parts) if parts else None

def main():
    try:
        raw = sys.stdin.buffer.read().decode('utf-8', errors='replace').strip() if not sys.stdin.isatty() else ''
    except Exception:
        raw = ''
    session_json = raw or '{}'
    try:
        sys.stdin = open(os.devnull)
    except Exception:
        pass
    env = dict(os.environ)
    env['CLAUDE_STATUSLINE_JSON'] = session_json
    env['VOIT_ROOT'] = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    try:
        top = _toplevel()
        if not top:
            return
        cfg = _load_config(top)
        if not cfg:
            return
        lines, defaults = _lines(cfg)
        out = [r for r in (_render_line(line, defaults, top, env) for line in lines)
               if r is not None]
        if out:
            print('\n'.join(out))
    except Exception:
        pass

if __name__ == "__main__":
    main()
