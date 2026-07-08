#!/usr/bin/env python3
import json, os, re, sys

SCOPED = ("vision", "organizer", "worker")
FILE_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")
REDIR = re.compile(r"(?<![\d\->])&?\d?>>?\s*([^\s;&|<>()]+)")
TEE = re.compile(r"\btee\b([^;&|<>()]*)")
DEST_CMD = re.compile(r"\b(?:cp|mv|rsync|install|ln)\b((?:\s+[^\s;&|<>()]+)+)")
DD_OF = re.compile(r"\bdd\b[^;&|]*?\bof=([^\s;&|<>()]+)")
SED_I = re.compile(r"\bsed\s+(-[^\s;&|]*i[^\s;&|]*)((?:\s+[^\s;&|<>()]+)+)")


def _read(cwd, name):
    try:
        return open(os.path.join(cwd, ".claude", name)).read()
    except Exception:
        return None


def _scope(cwd):
    raw = _read(cwd, "scope")
    if raw is None:
        return None
    return [l.strip() for l in raw.splitlines() if l.strip()]


def _resolve(t, cwd):
    t = os.path.expanduser(t)
    return os.path.realpath(t if os.path.isabs(t) else os.path.join(cwd, t))


def _in_scope(target, prefixes):
    for p in prefixes:
        pr = os.path.realpath(os.path.expanduser(p))
        if target == pr or target.startswith(pr + os.sep):
            return True
    return False


def _keep(t, out):
    t = t.strip("'\"")
    if t and not t.startswith(("/dev/", "$", "<")):
        out.append(t)


def _bash_targets(cmd):
    out = []
    for m in REDIR.finditer(cmd):
        _keep(m.group(1), out)
    for m in TEE.finditer(cmd):
        for tok in m.group(1).split():
            if not tok.startswith("-"):
                _keep(tok, out)
    for m in DEST_CMD.finditer(cmd):
        args = [t for t in m.group(1).split() if not t.startswith("-")]
        if len(args) >= 2:
            _keep(args[-1], out)
    for m in DD_OF.finditer(cmd):
        _keep(m.group(1), out)
    for m in SED_I.finditer(cmd):
        args = [t for t in m.group(2).split() if not t.startswith("-")]
        for t in args[1:] if "e" not in m.group(1) else args:
            _keep(t, out)
    return out


def _deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason}}))
    sys.exit(0)


def main():
    try:
        ev = json.load(sys.stdin)
    except Exception:
        ev = None
    cwd = (ev or {}).get("cwd") or os.getcwd()
    # A subagent's hook events carry the SESSION's cwd, not its worktree, so the
    # role file there would wrongly scope it: the harness-provided agent_type is
    # the authority. tweak is unrestricted by design.
    if ((ev or {}).get("agent_type") or "").rsplit(":", 1)[-1] == "tweak":
        return
    role = (_read(cwd, "role") or "").strip()
    if role == "tweak" or role not in SCOPED:
        return

    try:
        if ev is None:
            _deny("VOIT write-scope: unreadable hook event for scoped role '%s'; "
                  "failing closed." % role)
        prefixes = _scope(cwd)
        if not prefixes:
            _deny("VOIT write-scope: role '%s' has no scope file; refusing to fail open. "
                  "Re-run the SessionStart role hook." % role)

        tool = ev.get("tool_name") or ""
        ti = ev.get("tool_input") or {}
        if tool in FILE_TOOLS:
            fp = ti.get("file_path") or ti.get("path") or ti.get("notebook_path")
            targets = [fp] if fp else []
        elif tool == "Bash":
            targets = _bash_targets(ti.get("command") or "")
        else:
            return

        for raw in targets:
            target = _resolve(raw, cwd)
            if not _in_scope(target, prefixes):
                _deny("VOIT write-scope: %s is outside this session's scope. Allowed: %s."
                      % (target, ", ".join(prefixes)))
    except SystemExit:
        raise
    except Exception as e:
        _deny("VOIT write-scope: guard error for scoped role '%s' (%s); failing closed."
              % (role, e.__class__.__name__))


if __name__ == "__main__":
    main()
