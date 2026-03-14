#!/usr/bin/env python3
"""Session sidebar TUI for WezTerm multi-agent orchestration.

Runs in a narrow rightmost pane. Displays tracked agent sessions
and lets you select, rename, add, or delete them.

Signals back to WezTerm via OSC 1337 SetUserVar:
  session_action = select:<id>
  session_action = rename:<id>:<new_name>
  session_action = add:<agent>:<name>
  session_action = delete:<id>

Usage (called by modules/sessions.lua):
    python sessions_tui.py <sessions_json_path>
"""

import sys
import os
import json
import time
import io
import base64

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

SESSIONS_PATH = sys.argv[1] if len(sys.argv) > 1 else ".sessions.json"

AGENTS = ["claude", "opencode", "aider", "copilot", "cursor", "shell", "other"]

AGENT_ICONS = {
    "claude": "◈",
    "opencode": "◆",
    "aider": "▣",
    "copilot": "◉",
    "cursor": "◎",
    "shell": "▸",
    "other": "○",
}


# ---------------------------------------------------------------------------
# OSC signal
# ---------------------------------------------------------------------------


def emit_signal(value):
    encoded = base64.b64encode(value.encode("utf-8")).decode("ascii")
    sys.stdout.write(f"\033]1337;SetUserVar=session_action={encoded}\a")
    sys.stdout.flush()


# ---------------------------------------------------------------------------
# Session persistence
# ---------------------------------------------------------------------------


def load_sessions():
    try:
        with open(SESSIONS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            return data
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        pass
    return []


def save_sessions(sessions):
    try:
        with open(SESSIONS_PATH, "w", encoding="utf-8") as f:
            json.dump(sessions, f, indent=2)
    except OSError:
        pass


def next_id(sessions):
    max_id = 0
    for s in sessions:
        sid = s.get("id", 0)
        if isinstance(sid, int) and sid > max_id:
            max_id = sid
    return max_id + 1


# ---------------------------------------------------------------------------
# Platform key reading (same pattern as theme_picker_tui.py)
# ---------------------------------------------------------------------------


def _get_key_windows():
    import msvcrt
    ch = msvcrt.getwch()
    if ch in ("\x00", "\xe0"):
        return ("special", msvcrt.getwch())
    return ("char", ch)


def _get_key_unix():
    import tty, termios
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            ch2 = sys.stdin.read(1)
            if ch2 == "[":
                ch3 = sys.stdin.read(1)
                _map = {"A": "H", "B": "P", "5": "I", "6": "Q"}
                code = _map.get(ch3)
                if ch3 in ("5", "6"):
                    sys.stdin.read(1)
                if code:
                    return ("special", code)
            return ("char", "\x1b")
        return ("char", ch)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


get_key = _get_key_windows if sys.platform == "win32" else _get_key_unix


# ---------------------------------------------------------------------------
# Terminal helpers
# ---------------------------------------------------------------------------


def term_size():
    try:
        cols, rows = os.get_terminal_size()
    except OSError:
        cols, rows = 20, 40
    return cols, rows


def write(s):
    sys.stdout.write(s)


def flush():
    sys.stdout.flush()


def clear_screen():
    write("\033[2J\033[H")


def move_to(row, col=1):
    write(f"\033[{row};{col}H")


def hide_cursor():
    write("\033[?25l")


def show_cursor():
    write("\033[?25h")


def set_fg(color):
    write(f"\033[38;5;{color}m")


def set_bg(color):
    write(f"\033[48;5;{color}m")


def bold():
    write("\033[1m")


def dim():
    write("\033[2m")


def reset():
    write("\033[0m")


def inverse():
    write("\033[7m")


# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------


def render(sessions, cursor_idx, active_id, mode="normal", input_buf="", input_label=""):
    cols, rows = term_size()
    clear_screen()

    # Header
    move_to(1)
    bold()
    set_fg(75)  # blue
    title = "Sessions"
    write(title[:cols])
    reset()

    move_to(2)
    dim()
    write("─" * cols)
    reset()

    if not sessions:
        move_to(4)
        dim()
        write("No sessions")
        reset()
        move_to(6)
        dim()
        write("[a] add")
        reset()
        flush()
        return

    # Session list
    max_display = rows - 6  # leave room for header + footer
    start = 0
    if cursor_idx >= max_display:
        start = cursor_idx - max_display + 1

    for i, s in enumerate(sessions[start:start + max_display]):
        real_idx = start + i
        row = 3 + i
        move_to(row)

        is_cursor = real_idx == cursor_idx
        is_active = s.get("id") == active_id

        icon = AGENT_ICONS.get(s.get("agent", "other"), "○")

        if is_cursor:
            inverse()

        if is_active:
            set_fg(82)  # green
            bold()
            write("▶ ")
        else:
            write("  ")

        # Icon + name (truncate to fit)
        name = s.get("name", "unnamed")
        agent = s.get("agent", "")
        line = f"{icon} {name}"
        write(line[:cols - 2])

        reset()

    # Footer
    footer_row = rows - 2
    move_to(footer_row)
    dim()
    write("─" * cols)
    reset()

    if mode == "input":
        move_to(rows - 1)
        write(f"{input_label}{input_buf}")
        show_cursor()
    elif mode == "agent_pick":
        move_to(rows - 1)
        write(f"Agent: {input_buf}")
        show_cursor()
    else:
        move_to(rows - 1)
        dim()
        # Compact help for narrow pane
        if cols < 30:
            write("↵sel r·ren a·add d·del")
        else:
            write("↵ select  r rename  a add  d del")
        reset()

    flush()


# ---------------------------------------------------------------------------
# Input mode: read a line of text
# ---------------------------------------------------------------------------


def read_input_line(sessions, cursor_idx, active_id, label, prefill=""):
    buf = list(prefill)
    while True:
        render(sessions, cursor_idx, active_id, mode="input",
               input_buf="".join(buf), input_label=label)
        kind, ch = get_key()
        if kind == "char":
            if ch == "\r" or ch == "\n":
                return "".join(buf)
            elif ch == "\x1b":  # Escape
                return None
            elif ch == "\x08" or ch == "\x7f":  # Backspace
                if buf:
                    buf.pop()
            elif ch >= " ":
                buf.append(ch)
        elif kind == "special":
            pass  # ignore arrows etc in input mode


def pick_agent(sessions, cursor_idx, active_id):
    """Let user pick an agent type by pressing a number."""
    render(sessions, cursor_idx, active_id, mode="input",
           input_buf="", input_label="Agent: ")

    cols, rows = term_size()
    for i, agent in enumerate(AGENTS):
        row = 3 + i
        if row >= rows - 2:
            break
        move_to(row)
        reset()
        write(f" {i + 1}) {AGENT_ICONS.get(agent, '○')} {agent}")
    flush()

    while True:
        kind, ch = get_key()
        if kind == "char":
            if ch == "\x1b":
                return None
            idx = ord(ch) - ord("1")
            if 0 <= idx < len(AGENTS):
                return AGENTS[idx]


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------


def main():
    sessions = load_sessions()
    cursor_idx = 0
    active_id = None
    hide_cursor()

    # Find the currently active session
    for s in sessions:
        if s.get("active"):
            active_id = s.get("id")
            break

    try:
        while True:
            render(sessions, cursor_idx, active_id)

            kind, ch = get_key()

            if kind == "special":
                if ch == "H":  # Up
                    cursor_idx = max(0, cursor_idx - 1)
                elif ch == "P":  # Down
                    cursor_idx = min(len(sessions) - 1, cursor_idx + 1)

            elif kind == "char":
                if ch == "k":  # Up (vim)
                    cursor_idx = max(0, cursor_idx - 1)
                elif ch == "j":  # Down (vim)
                    if sessions:
                        cursor_idx = min(len(sessions) - 1, cursor_idx + 1)

                elif ch == "\r" or ch == "\n":  # Enter — select session
                    if sessions and 0 <= cursor_idx < len(sessions):
                        s = sessions[cursor_idx]
                        sid = s.get("id", 0)
                        # Mark active
                        for ss in sessions:
                            ss["active"] = ss.get("id") == sid
                        active_id = sid
                        save_sessions(sessions)
                        emit_signal(f"select:{sid}")

                elif ch == "r":  # Rename
                    if sessions and 0 <= cursor_idx < len(sessions):
                        s = sessions[cursor_idx]
                        show_cursor()
                        new_name = read_input_line(
                            sessions, cursor_idx, active_id,
                            "Name: ", s.get("name", ""))
                        hide_cursor()
                        if new_name is not None and new_name.strip():
                            s["name"] = new_name.strip()
                            save_sessions(sessions)
                            emit_signal(f"rename:{s['id']}:{new_name.strip()}")

                elif ch == "a":  # Add session
                    show_cursor()
                    agent = pick_agent(sessions, cursor_idx, active_id)
                    if agent is None:
                        hide_cursor()
                        continue
                    name = read_input_line(
                        sessions, cursor_idx, active_id,
                        "Name: ", f"{agent}-{len(sessions) + 1}")
                    hide_cursor()
                    if name is not None and name.strip():
                        sid = next_id(sessions)
                        new_session = {
                            "id": sid,
                            "name": name.strip(),
                            "agent": agent,
                            "active": False,
                        }
                        sessions.append(new_session)
                        save_sessions(sessions)
                        cursor_idx = len(sessions) - 1
                        emit_signal(f"add:{agent}:{name.strip()}")

                elif ch == "d":  # Delete
                    if sessions and 0 <= cursor_idx < len(sessions):
                        s = sessions[cursor_idx]
                        if s.get("id") == active_id:
                            active_id = None
                        sid = s.get("id", 0)
                        sessions.pop(cursor_idx)
                        if cursor_idx >= len(sessions) and sessions:
                            cursor_idx = len(sessions) - 1
                        save_sessions(sessions)
                        emit_signal(f"delete:{sid}")

                elif ch == "R":  # Reload from disk
                    sessions = load_sessions()
                    if cursor_idx >= len(sessions):
                        cursor_idx = max(0, len(sessions) - 1)
                    for s in sessions:
                        if s.get("active"):
                            active_id = s.get("id")
                            break

                elif ch == "q" or ch == "\x1b":  # Quit
                    break

    finally:
        show_cursor()
        reset()
        clear_screen()
        move_to(1)


if __name__ == "__main__":
    main()
