#!/usr/bin/env python3
"""Exercise the deployed tmux configuration on isolated stock or custom servers.

TMUX_TEST_BIN=/path/to/tmux python3 scripts/test-tmux-config.py
TMUX_TEST_HOME=/path/to/home additionally tests deployed files.
"""
import json
import os
from pathlib import Path
import pty
import select
import shutil
import subprocess
import tempfile
import termios
import time
import tty
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(os.environ.get('TMUX_TEST_HOME', ROOT / 'home'))
BINARY = Path(os.environ.get('TMUX_TEST_BIN', shutil.which('tmux'))).resolve()


class Client:
    def __init__(self, command, env):
        self.master, self.slave = pty.openpty()
        tty.setraw(self.slave)
        termios.tcsetwinsize(self.slave, (30, 120))
        self.name = os.ttyname(self.slave)
        self.output = b""
        self.process = subprocess.Popen(command, stdin=self.slave, stdout=self.slave,
                                        stderr=self.slave, env=env, preexec_fn=lambda: os.login_tty(0))
        self.pump(.1)

    def send(self, text):
        os.write(self.master, text.encode())

    def pump(self, duration=.02):
        end = time.monotonic() + duration
        while time.monotonic() < end:
            if select.select([self.master], [], [], .005)[0]:
                data = os.read(self.master, 65536)
                self.output += data
                if b'\x1b[6n' in data:
                    self.send('\x1b[1;1R')

    def close(self):
        self.process.terminate()
        os.close(self.master)
        os.close(self.slave)
        try:
            self.process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=1)


class Config(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='tmux-config-', dir='/tmp')
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        (self.bin / 'tmux').symlink_to(BINARY)
        for name in ['cockpit', 'tmux-zen', 'tmux-copy-open-link']:
            shutil.copy2(SOURCE / '.local/bin' / name, self.bin / name)
        self.conf = self.home / '.config/tmux'
        shutil.copytree(SOURCE / '.config/tmux', self.conf)
        theme = self.home / '.config/tinted-theming/tinty/theme.sh'
        theme.parent.mkdir(parents=True)
        theme.write_text('#!/bin/sh\nexit 0\n')
        theme.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_CACHE_HOME=str(self.home / '.cache'), XDG_DATA_HOME=str(self.home / '.data'),
                        TMUX=str(self.home / 'socket') + ',0,0', TERM='xterm-256color',
                        PATH=str(self.bin) + ':/opt/homebrew/bin:/usr/bin:/bin')
        self.cmd = [str(BINARY), '-S', str(self.home / 'socket')]
        self.tmux('-f', '/dev/null', 'new-session', '-d', '-s', 'check', '/bin/cat')
        self.addCleanup(lambda: subprocess.run(self.cmd + ['kill-server'], capture_output=True))
        self.tmux('source-file', str(self.conf / 'tmux.conf'))
        self.tmux('set', '-g', 'default-shell', '/bin/sh', ';', 'set', '-g', 'default-command', '/bin/cat',
                  ';', 'set', '-g', 'status-left', '#{E:@mode} #{E:@hint}',
                  ';', 'set', '-gw', 'pane-border-format', '')
        self.client = self.attach()

    def attach(self):
        c = Client(self.cmd + ['attach', '-t', 'check'], dict(self.env, TMUX=''))
        self.addCleanup(c.close)
        return c

    def tmux(self, *args):
        result = subprocess.run(self.cmd + list(args), env=self.env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    def run_script(self, name, *args, check=True):
        return subprocess.run(['/bin/bash', str(self.bin / name), *args], env=self.env,
                              check=check, capture_output=True, text=True, timeout=10)

    def state(self, fmt, client=None):
        return self.tmux('display', '-p', '-c', (client or self.client).name, '-t', 'check', fmt)

    def wait(self, predicate):
        end = time.monotonic() + 3
        while time.monotonic() < end:
            self.client.pump()
            if predicate():
                return
        self.fail('timed out waiting for tmux state')

    def table(self, name, client=None):
        self.tmux('switch-client', '-c', (client or self.client).name, '-T', name)

    def test_splits_focus_and_accept_typing(self):
        for table in ['cockpit', 'cockpit-p', 'jump']:
            for modifier in [2, 3]:
                for arrow in 'ABCD':
                    with self.subTest(table=table, modifier=modifier, arrow=arrow):
                        original = self.state('#{pane_id}')
                        self.table(table)
                        self.client.send(f'\x1b[1;{modifier}{arrow}')
                        self.wait(lambda: self.state('#{pane_id}') != original)
                        pane = self.state('#{pane_id}')
                        self.assertEqual(self.state('#{client_key_table}'), 'root')
                        self.client.send('ready-to-type\n')
                        self.wait(lambda: 'ready-to-type' in self.tmux('capture-pane', '-p', '-t', pane))
                        self.tmux('kill-pane', '-t', pane)

    def test_fast_menu_keys_and_navigation(self):
        self.client.send('\x1b[15~pj')  # F5, pane, split down, without delays
        self.wait(lambda: self.state('#{window_panes}') == '2')
        self.assertEqual(self.state('#{client_key_table}'), 'root')
        old = self.state('#{pane_id}')
        self.client.send('\x1b[15~\x1b[A')
        self.wait(lambda: self.state('#{pane_id}') != old)
        self.assertEqual(self.state('#{client_key_table}'), 'jump')
        self.client.send('\r')
        self.wait(lambda: self.state('#{client_key_table}') == 'root')

    def test_menus_are_client_local(self):
        other = self.attach()
        self.table('cockpit')
        self.client.send('p')
        self.wait(lambda: self.state('#{client_key_table}') == 'cockpit-p')
        self.table('cockpit', other)
        other.send('w'); other.pump(.05)
        self.assertIn('pane ›', self.state('#{E:@hint}'))
        self.assertIn('window ›', self.state('#{E:@hint}', other))
        self.assertEqual(self.state('#{E:@mode}'), 'COCKPIT')
        self.client.send('\x7f')
        self.wait(lambda: self.state('#{client_key_table}') == 'cockpit')
        self.client.send('?')
        self.wait(lambda: self.state('#{client_key_table}') == 'root')
        self.assertNotIn('?', self.tmux('capture-pane', '-p'))

    def test_exact_window_numbers(self):
        self.tmux('new-window', '-d', '-t', 'check:30')
        self.client.send('\x1b[15~3')
        self.wait(lambda: self.state('#{window_index}') == '3')
        self.client.send('\x1b[15~9')
        self.wait(lambda: self.state('#{window_index}') == '9')
        self.client.send('\x1b[15~3')
        self.wait(lambda: self.state('#{window_index}') == '3')
        self.assertEqual(self.state('#{session_windows}'), '4')

    def test_reload_and_bad_json(self):
        for _ in range(2):
            self.tmux('source-file', str(self.conf / 'tmux.conf'))
        self.assertEqual(self.tmux('show', '-gv', 'update-environment').splitlines().count('XDG_CONFIG_HOME'), 1)
        keys = self.tmux('list-keys', '-T', 'cockpit')
        (self.conf / 'cockpit.json').write_text('{bad json')
        self.assertNotEqual(self.run_script('cockpit', 'gen', check=False).returncode, 0)
        self.assertEqual(self.tmux('list-keys', '-T', 'cockpit'), keys)

    def test_shell_action_is_literal_and_open_entrypoint(self):
        path = self.conf / 'cockpit.json'
        menu = json.loads(path.read_text())
        menu['a'] = {'label': 'test', 'shell': 'literal $HOME `date` "quote" 90% ; text'}
        path.write_text(json.dumps(menu))
        self.run_script('cockpit', 'gen')
        self.run_script('cockpit', '--open')
        self.client.send('a')
        self.wait(lambda: menu['a']['shell'] in self.tmux('capture-pane', '-p'))
        self.assertEqual(self.state('#{client_key_table}'), 'root')

    def test_zen_split_keeps_focus(self):
        if not self.state('#{pane-border-type}'):
            self.skipTest('visual parity check requires the custom pane-frame build')
        self.run_script('tmux-zen', 'toggle')
        self.wait(lambda: self.state('#{@zen_col}') != '')
        original = self.state('#{pane_id}')
        self.client.send('\x1b[15~\x1b[1;2C')
        self.wait(lambda: self.state('#{pane_id}') != original)
        pane = self.state('#{pane_id}')
        self.wait(lambda: self.state('#{@zen_col}') != '')
        self.assertEqual(self.state('#{client_key_table}'), 'root')
        self.assertNotEqual(self.state('#{@zen_spacer}'), '1')
        self.client.send('zen-typing\n')
        self.wait(lambda: 'zen-typing' in self.tmux('capture-pane', '-p', '-t', pane))
        self.run_script('tmux-zen', 'toggle')
        self.wait(lambda: self.state('#{window_panes}') == '2')
        self.assertEqual(self.state('#{pane_id}'), pane)

    def test_popup_and_wezterm_actions(self):
        # The launcher receives the invoking client, pane, cwd and command.
        modal = self.bin / 'modal'
        modal.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/modal-args"\n')
        modal.chmod(0o755)
        pane = self.state('#{pane_id}')
        cwd = self.state('#{E:@cwd}')
        self.client.send('\x1b[15~gl')
        out = self.home / 'modal-args'
        self.wait(lambda: out.exists())
        self.assertEqual(out.read_text().splitlines(), [self.client.name, pane, cwd, 'lazygit', 'border'])
        self.assertEqual(self.state('#{client_key_table}'), 'root')
        self.client.output = b''
        self.client.send('\x1b[15~un')
        self.wait(lambda: b'\x1b]1337;SetUserVar=wez=d2luZG93\x07' in self.client.output)

    def test_native_pane_count(self):
        self.tmux('new-session', '-d', '-s', 'other', '/bin/cat')
        self.tmux('split-window', '-h', '-t', 'check')
        pane = self.state('#{pane_id}')
        count = '#{n:#{S:#{W:#{P:#{?#{E:@real-pane},x,}}}}}'
        self.assertEqual(self.state(count), '3')
        self.tmux('set', '-p', '-t', pane, '@zen_spacer', '1')
        self.assertEqual(self.state(count), '2')
        self.tmux('kill-pane', '-t', pane)
        self.assertEqual(self.state(count), '2')

    def test_lone_border_hooks(self):
        if not self.state('#{window_layout}').startswith('{'):
            self.skipTest('3.7c resolves layout hooks to another session after killing its active pane')
        self.tmux('new-session', '-d', '-s', 'other', '/bin/cat')
        self.tmux('split-window', '-h', '-t', 'check')
        pane = self.state('#{pane_id}')
        self.tmux('kill-pane', '-t', pane)
        self.wait(lambda: self.state('#{pane-border-status}') == 'off')
        self.tmux('split-window', '-h', '-t', 'check')
        self.wait(lambda: self.state('#{pane-border-status}') == 'top')


class OpenLink(unittest.TestCase):
    def test_urls_and_copy_fallback_without_character_processes(self):
        with tempfile.TemporaryDirectory(prefix='tmux-url-', dir='/tmp') as tmp:
            path = Path(tmp)
            (path / 'tmux').write_text("#!/bin/bash\nprintf '%s\\n' \"$*\" >> \"$CALLS\"\nif [[ $1 == display ]]; then printf '%s\\n%s|%s\\n' \"$LINK\" \"$CX\" \"$LINE\"; fi\n")
            (path / 'open').write_text("#!/bin/sh\nprintf '%s' \"$1\" > \"$OPENED\"\n")
            for name in ['tmux', 'open']:
                (path / name).chmod(0o755)
            cases = [
                ('https://osc.example/a|b', '', 0, 'https://osc.example/a|b'),
                ('', 'see https://example.com/a.', 8, 'https://example.com/a'),
                ('', 'https://example.com/' + 'a' * 400, 30, 'https://example.com/' + 'a' * 400),
                ('', 'ordinary text', 3, ''),
                ('', 'ordinary text', 8, ''),
                ('', '', 0, ''),
            ]
            for link, line, cx, expected in cases:
                with self.subTest(line=line[:40], link=link):
                    calls, opened = path / 'calls', path / 'opened'
                    calls.unlink(missing_ok=True); opened.unlink(missing_ok=True)
                    env = dict(os.environ, PATH=str(path) + ':/usr/bin:/bin', CALLS=str(calls),
                               OPENED=str(opened), LINK=link, LINE=line, CX=str(cx))
                    subprocess.run(['/bin/bash', str(SOURCE / '.local/bin/tmux-copy-open-link'), '%1'],
                                   env=env, check=True, timeout=5)
                    rows = [r for r in calls.read_text().splitlines() if r.startswith(('display ', 'send-keys '))]
                    self.assertEqual(len(rows), 2)
                    if expected:
                        until = time.monotonic() + 1
                        while not opened.exists() and time.monotonic() < until:
                            time.sleep(.005)
                        self.assertEqual(opened.read_text(), expected)
                        self.assertIn('-X cancel', rows[-1])
                    else:
                        self.assertFalse(opened.exists())
                        self.assertIn('copy-pipe-and-cancel', rows[-1])


if __name__ == '__main__':
    print(f'Testing {BINARY} with {SOURCE}', flush=True)
    unittest.main()
