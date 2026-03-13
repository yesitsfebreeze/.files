#!/usr/bin/env python3
"""WezTerm theme picker TUI — runs in a split pane with live preview.

Updates globals.lua on each cursor movement so WezTerm hot-reloads
the theme across all panes instantly.

Usage:
    python theme_picker_tui.py <themes_file> <globals_path> <current_theme>
"""

import sys
import os
import re
import time

# ---------------------------------------------------------------------------
# globals.lua updater
# ---------------------------------------------------------------------------

def update_theme(globals_path, theme):
    """Rewrite the color_scheme value in globals.lua."""
    try:
        with open(globals_path, "r", encoding="utf-8") as f:
            content = f.read()
        updated = re.sub(
            r'(color_scheme\s*=\s*)"[^"]*"',
            lambda m: m.group(1) + '"' + theme.replace("\\", "\\\\") + '"',
            content,
        )
        with open(globals_path, "w", encoding="utf-8") as f:
            f.write(updated)
    except Exception:
        pass  # never break the picker on write failure


# ---------------------------------------------------------------------------
# Fuzzy scoring
# ---------------------------------------------------------------------------

def fuzzy_score(query, item):
    """Return (matched: bool, score: int)."""
    if not query:
        return True, 0
    q, s = query.lower(), item.lower()
    qi, score, prev = 0, 0, -2
    for i, c in enumerate(s):
        if qi < len(q) and c == q[qi]:
            score += 1
            if i == prev + 1:
                score += 3          # consecutive bonus
            if i == 0 or s[i - 1] in " -_":
                score += 5          # word-boundary bonus
            prev = i
            qi += 1
    return qi == len(q), score


# ---------------------------------------------------------------------------
# Platform key-reading helpers
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
                _map = {"A": "H", "B": "P", "5": "I", "6": "Q", "H": "G", "F": "O"}
                code = _map.get(ch3)
                if ch3 in ("5", "6"):
                    sys.stdin.read(1)  # consume trailing ~
                if code:
                    return ("special", code)
            return ("char", "\x1b")
        return ("char", ch)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


get_key = _get_key_windows if sys.platform == "win32" else _get_key_unix


# ---------------------------------------------------------------------------
# Enable ANSI / VT processing on Windows
# ---------------------------------------------------------------------------

def _enable_vt():
    if sys.platform != "win32":
        return
    import ctypes
    k32 = ctypes.windll.kernel32
    h = k32.GetStdHandle(-11)  # STD_OUTPUT_HANDLE
    m = ctypes.c_ulong()
    k32.GetConsoleMode(h, ctypes.byref(m))
    k32.SetConsoleMode(h, m.value | 0x0004)  # ENABLE_VIRTUAL_TERMINAL_PROCESSING


# ---------------------------------------------------------------------------
# Main picker
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 4:
        print("Usage: theme_picker_tui.py <themes_file> <globals_path> <current_theme>")
        sys.exit(1)

    themes_file = sys.argv[1]
    globals_path = sys.argv[2]
    original = sys.argv[3]

    with open(themes_file, "r", encoding="utf-8") as f:
        all_themes = [l.strip() for l in f if l.strip()]

    if not all_themes:
        print("No themes loaded.")
        sys.exit(1)

    _enable_vt()

    query = ""
    cursor = 0
    scroll = 0
    filtered = all_themes[:]
    last_applied = ""

    # -- helpers ----------------------------------------------------------

    def refilter():
        nonlocal filtered, cursor, scroll
        if not query:
            filtered = all_themes[:]
        else:
            scored = [
                (sc, t)
                for t in all_themes
                for m, sc in [fuzzy_score(query, t)]
                if m
            ]
            scored.sort(key=lambda x: -x[0])
            filtered = [t for _, t in scored]
        cursor = min(cursor, max(0, len(filtered) - 1))
        scroll = min(scroll, max(0, cursor))

    def apply():
        nonlocal last_applied
        if filtered and 0 <= cursor < len(filtered):
            t = filtered[cursor]
            if t != last_applied:
                update_theme(globals_path, t)
                last_applied = t

    def render():
        nonlocal scroll
        try:
            cols, rows = os.get_terminal_size()
        except Exception:
            cols, rows = 80, 24

        hdr = 3
        vis = max(1, rows - hdr - 1)

        if cursor < scroll:
            scroll = cursor
        elif cursor >= scroll + vis:
            scroll = cursor - vis + 1

        buf = ["\033[2J\033[H"]
        buf.append(
            f"\033[1;36m\U0001f3a8  Theme Picker\033[0m "
            f"\033[90m({len(filtered)}/{len(all_themes)})\033[0m\n"
        )
        buf.append(f"\033[33m\u276f\033[0m {query}\033[7m \033[0m\n")
        buf.append(f"\033[90m{'─' * min(cols, 60)}\033[0m\n")

        end = min(len(filtered), scroll + vis)
        for i in range(scroll, end):
            name = filtered[i]
            if len(name) > cols - 6:
                name = name[: cols - 9] + "…"
            marker = " ◂" if filtered[i] == original else ""
            if i == cursor:
                buf.append(f"\033[1;7m ▸ {name}{marker} \033[0m\n")
            else:
                buf.append(f"   {name}\033[90m{marker}\033[0m\n")

        status = (
            "\033[90m ↑↓ navigate  │  type to filter  │"
            "  Enter select  │  Esc cancel\033[0m"
        )
        buf.append(f"\033[{rows};1H{status}")

        sys.stdout.write("".join(buf))
        sys.stdout.flush()

    # -- main loop --------------------------------------------------------

    sys.stdout.write("\033[?1049h")  # switch to alternate screen buffer
    sys.stdout.write("\033[?25l")   # hide cursor
    sys.stdout.flush()

    try:
        refilter()
        render()
        apply()

        while True:
            kt, kv = get_key()

            if kt == "char":
                if kv == "\x1b":                          # Esc → revert
                    update_theme(globals_path, original)
                    return
                if kv == "\r":                             # Enter → confirm
                    return
                if kv in ("\x08", "\x7f"):                 # Backspace
                    if query:
                        query = query[:-1]
                        refilter()
                elif kv == "\x15":                         # Ctrl+U → clear
                    query = ""
                    cursor = 0
                    refilter()
                elif kv == "\x17":                         # Ctrl+W → delete word
                    query = query.rsplit(" ", 1)[0] if " " in query else ""
                    refilter()
                elif kv.isprintable():
                    query += kv
                    cursor = 0
                    refilter()

            elif kt == "special":
                n = max(0, len(filtered) - 1)
                if kv == "H":                              # Up
                    cursor = max(0, cursor - 1)
                elif kv == "P":                            # Down
                    cursor = min(n, cursor + 1)
                elif kv == "I":                            # Page Up
                    cursor = max(0, cursor - 15)
                elif kv == "Q":                            # Page Down
                    cursor = min(n, cursor + 15)
                elif kv == "G":                            # Home
                    cursor = 0
                elif kv == "O":                            # End
                    cursor = n

            render()
            apply()

    finally:
        sys.stdout.write("\033[?25h")    # restore cursor
        sys.stdout.write("\033[?1049l")  # restore main screen buffer
        sys.stdout.flush()


if __name__ == "__main__":
    main()
