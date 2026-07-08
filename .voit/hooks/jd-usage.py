#!/usr/bin/env python3
import json, os, re, shlex, subprocess, sys


def _script():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(root, "scripts", "jd-cache.py")


def _log(verb, target):
    try:
        subprocess.run([sys.executable, _script(), "log", verb, target],
                       capture_output=True)
    except Exception:
        pass


def _response_text(tr):
    if isinstance(tr, str):
        return tr
    if isinstance(tr, list):
        parts = []
        for block in tr:
            if isinstance(block, dict):
                parts.append(block.get("text") or block.get("content") or "")
            else:
                parts.append(str(block))
        return "\n".join(parts)
    if isinstance(tr, dict):
        return tr.get("stdout") or tr.get("output") or tr.get("text") or ""
    return ""


def _top_ref(text):
    try:
        m = re.search(r'"ref"\s*:\s*"([^"]+)"', text)
        if m:
            return m.group(1)
        for line in text.splitlines():
            line = line.strip()
            if line and not line.startswith(("{", "[", "#")) and "/" in line and " " not in line:
                return line
    except Exception:
        pass
    return None


def _parse_bash(cmd):
    try:
        parts = shlex.split(cmd)
    except Exception:
        parts = cmd.split()
    for i, p in enumerate(parts):
        if p == "jd" and i + 2 < len(parts):
            verb = parts[i + 1]
            if verb in ("get", "search"):
                return verb, parts[i + 2]
    return None


def main():
    try:
        ev = json.load(sys.stdin)
    except Exception:
        return
    try:
        tool = ev.get("tool_name") or ""
        ti = ev.get("tool_input") or {}
        tr = ev.get("tool_response")
        txt = _response_text(tr)

        if re.match(r"mcp__.*justdown.*__get$", tool):
            target = ti.get("ref") or ti.get("name") or ti.get("key") or ""
            if target:
                _log("get", target)

        elif re.match(r"mcp__.*justdown.*__search$", tool):
            ref = _top_ref(txt)
            query = ti.get("query") or ""
            _log("search", ref if ref else "?" + query)

        elif tool == "Bash":
            parsed = _parse_bash(ti.get("command") or "")
            if not parsed:
                return
            verb, arg = parsed
            if verb == "get":
                _log("get", arg)
            else:
                if not txt.strip() or "exit code: 2" in txt:
                    return
                ref = _top_ref(txt)
                _log("search", ref if ref else "?" + arg)
    except Exception:
        pass


if __name__ == "__main__":
    main()
