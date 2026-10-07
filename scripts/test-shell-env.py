#!/usr/bin/env python3
"""Check the cockpit loader without reading the user's environment store."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="dotfiles-env-test-") as tmp:
    root = Path(tmp)
    (root / "env").mkdir()
    sentinel = root / "executed"
    value = f"literal spaces = 'quotes' $HOME `touch {sentinel}` $(touch {sentinel}) \\ end"
    (root / "env/vars").write_text(
        f"TEST_KEPT={value}\n1INVALID=bad\nBAD-NAME=bad\n"
        "TEST_EMPTY=\nTEST_DUP=first\nTEST_DUP=last"
    )
    env = {**os.environ, "XDG_STATE_HOME": str(root)}
    probe = (
        "import os,json; print(json.dumps([os.environ.get(k) "
        "for k in ['TEST_KEPT','TEST_EMPTY','TEST_DUP']]))"
    )
    for shell in ("bash", "zsh"):
        command = f'. {shlex.quote(str(repo / "home/.config/shell/env.sh"))}; python3 -c {shlex.quote(probe)}'
        result = subprocess.run([shell, "-c", command], env=env, capture_output=True, text=True, check=True)
        assert json.loads(result.stdout) == [value, "", "last"], shell
        assert not sentinel.exists(), "store was evaluated as shell code"
        print(f"{shell}: literal values, validation, empty values, duplicate keys and final line passed")
    fake_home = root / "home"
    fake_home.mkdir()
    for name in (".zshenv", ".bash_profile", ".bashrc"):
        (fake_home / name).write_text("# keep existing settings\n")
    for _ in range(2):
        subprocess.run(["sh", str(repo / "hooks/install-shell-env.sh")], env={**env, "HOME": str(fake_home)}, check=True)
    for name in (".zshenv", ".bash_profile", ".bashrc"):
        text = (fake_home / name).read_text()
        assert text.startswith("# keep existing settings\n")
        assert text.count('|| . "$HOME/.config/shell/env.sh"') == 1
    print("installer: preserves startup files and is idempotent")
