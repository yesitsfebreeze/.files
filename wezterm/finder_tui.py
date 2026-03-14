#!/usr/bin/env python3
"""Finder TUI for WezTerm — replicates finder.nvim behavior.

Full-screen overlay with:
  - Bottom search bar spanning full width
  - Picker selection mode (type prefix to select picker)
  - Prompt mode with live filtering
  - Chainable pickers (Files → Grep, etc.)

Signals back to WezTerm via OSC 1337 SetUserVar:
  finder_action = open:<path>
  finder_action = open:<path>:<line>
  finder_action = cd:<path>
  finder_action = close

Usage (called by modules/finder.lua):
    python finder_tui.py [cwd] [initial_picker]
"""

import sys
import os
import io
import json
import base64
import subprocess
import threading
import time
import re

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ─── Args ─────────────────────────────────────────────────────────────
CWD = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
INITIAL_PICKER = sys.argv[2] if len(sys.argv) > 2 else None
CONFIG_PATH = sys.argv[3] if len(sys.argv) > 3 else None

os.chdir(CWD)

# ─── Data Types ───────────────────────────────────────────────────────

NONE = 0
FILE_LIST = 1
GREP_LIST = 2
DIR_LIST = 3

# ─── Picker definitions ──────────────────────────────────────────────

class Picker:
    name = ""
    accepts = [NONE]
    produces = FILE_LIST
    hidden = False
    min_query = 2

    def filter(self, query, items):
        """Return list of result strings."""
        return []

    def on_open(self, item, query):
        """Called when user confirms a selection. Return signal string or None."""
        return None


class FilesPicker(Picker):
    name = "Files"
    accepts = [NONE, FILE_LIST, GREP_LIST, DIR_LIST]
    produces = FILE_LIST
    min_query = 2

    def filter(self, query, items):
        if items and len(items) > 0:
            # Extract file list from grep results
            files = extract_files(items)
            return fuzzy_filter(files, query)

        # List all files
        all_files = list_files(CWD)
        if not query:
            return all_files[:500]
        return fuzzy_filter(all_files, query)

    def on_open(self, item, query):
        return f"open:{item}"


class GrepPicker(Picker):
    name = "Grep"
    accepts = [NONE, FILE_LIST, GREP_LIST, DIR_LIST]
    produces = GREP_LIST
    min_query = 2

    def filter(self, query, items):
        if not query or len(query) < 2:
            return []

        # If we have items, scope the grep
        scope_files = None
        if items and len(items) > 0:
            scope_files = extract_files(items)

        return run_grep(query, scope_files)

    def on_open(self, item, query):
        file, line, _ = parse_grep_item(item)
        if line:
            return f"open:{file}:{line}"
        return f"open:{file}"


class DirsPicker(Picker):
    name = "Dirs"
    accepts = [NONE, DIR_LIST]
    produces = DIR_LIST
    min_query = 0

    def filter(self, query, items):
        dirs = list_dirs(CWD)
        if not query:
            return dirs[:200]
        return fuzzy_filter(dirs, query)

    def on_open(self, item, query):
        return f"cd:{item}"


class ProjectsPicker(Picker):
    name = "Projects"
    accepts = [NONE]
    produces = DIR_LIST
    min_query = 0

    def filter(self, query, items):
        projects = load_projects()
        if not query:
            return projects
        return fuzzy_filter(projects, query)

    def on_open(self, item, query):
        return f"cd:{item}"


class ThemesPicker(Picker):
    name = "Themes"
    accepts = [NONE]
    produces = NONE
    hidden = False
    min_query = 0

    def __init__(self):
        self._themes = None

    def _load_themes(self):
        if self._themes is not None:
            return self._themes
        themes_file = os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            ".themes_cache.json"
        )
        if os.path.exists(themes_file):
            try:
                with open(themes_file, "r", encoding="utf-8") as f:
                    self._themes = json.load(f)
            except (json.JSONDecodeError, OSError):
                self._themes = []
        else:
            self._themes = []
        return self._themes

    def filter(self, query, items):
        themes = self._load_themes()
        if not query:
            return themes[:200]
        return fuzzy_filter(themes, query)

    def on_open(self, item, query):
        return f"theme:{item}"


# ─── Default pickers registry ───────────────────────────────────────

ALL_PICKERS = {
    "Files": FilesPicker(),
    "Grep": GrepPicker(),
    "Dirs": DirsPicker(),
    "Projects": ProjectsPicker(),
    "Themes": ThemesPicker(),
}


# ─── Utility functions ───────────────────────────────────────────────

def emit_signal(value):
    encoded = base64.b64encode(value.encode("utf-8")).decode("ascii")
    sys.stdout.write(f"\033]1337;SetUserVar=finder_action={encoded}\a")
    sys.stdout.flush()


def load_projects():
    """Load project paths from .projects.json."""
    projects_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".projects.json")
    try:
        with open(projects_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            return [p.get("path", "") for p in data if p.get("path")]
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        pass
    return []


def list_files(cwd):
    """List files using fd or rg --files or find."""
    try:
        if has_cmd("fd"):
            result = subprocess.run(
                ["fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git",
                 "--exclude", "node_modules", "--exclude", "__pycache__", "--exclude", ".venv"],
                capture_output=True, text=True, cwd=cwd, timeout=10
            )
        elif has_cmd("rg"):
            result = subprocess.run(
                ["rg", "--files", "--hidden",
                 "--glob", "!*.git*", "--glob", "!node_modules",
                 "--glob", "!__pycache__", "--glob", "!.venv"],
                capture_output=True, text=True, cwd=cwd, timeout=10
            )
        else:
            result = subprocess.run(
                ["find", ".", "-type", "f", "-not", "-path", "*/.git/*"],
                capture_output=True, text=True, cwd=cwd, timeout=10
            )
        return [l for l in result.stdout.splitlines() if l.strip()]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return []


def list_dirs(cwd):
    """List directories using fd or find."""
    try:
        if has_cmd("fd"):
            result = subprocess.run(
                ["fd", "--type", "d", "--hidden", "--follow", "--exclude", ".git",
                 "--exclude", "node_modules", "--exclude", "__pycache__"],
                capture_output=True, text=True, cwd=cwd, timeout=10
            )
        else:
            result = subprocess.run(
                ["find", ".", "-type", "d", "-not", "-path", "*/.git/*"],
                capture_output=True, text=True, cwd=cwd, timeout=10
            )
        return [l for l in result.stdout.splitlines() if l.strip()]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return []


def run_grep(query, scope_files=None):
    """Run ripgrep or grep and return results."""
    try:
        if has_cmd("rg"):
            cmd = ["rg", "--line-number", "--no-heading", "--color=never",
                   "--hidden", "--glob", "!.git", "--smart-case"]
            cmd.append(query)
            if scope_files:
                for f in scope_files[:100]:
                    cmd.append(f)
            result = subprocess.run(
                cmd, capture_output=True, text=True, cwd=CWD, timeout=15
            )
        elif has_cmd("grep"):
            cmd = ["grep", "-rn", "--color=never", "--exclude-dir=.git", "-i"]
            cmd.append(query)
            if scope_files:
                cmd.extend(scope_files[:100])
            else:
                cmd.append(".")
            result = subprocess.run(
                cmd, capture_output=True, text=True, cwd=CWD, timeout=15
            )
        else:
            return []
        lines = result.stdout.splitlines()
        return lines[:2000]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return []


_cmd_cache = {}
def has_cmd(name):
    """Check if a command is available on PATH."""
    if name in _cmd_cache:
        return _cmd_cache[name]
    from shutil import which
    _cmd_cache[name] = which(name) is not None
    return _cmd_cache[name]


def extract_files(items):
    """Extract unique file paths from grep-style items."""
    seen = set()
    files = []
    for item in items:
        f = item.split(":")[0] if ":" in item else item
        if f and f not in seen:
            seen.add(f)
            files.append(f)
    return files


def parse_grep_item(item):
    """Parse file:line:content format."""
    m = re.match(r'^([^:]+):(\d+):(.*)$', item)
    if m:
        return m.group(1), int(m.group(2)), m.group(3)
    return item, None, None


def fuzzy_filter(items, query):
    """Multi-token fuzzy filter (space-separated tokens, all must match)."""
    if not query or not query.strip():
        return items
    tokens = query.lower().split()
    result = []
    for item in items:
        lower_item = item.lower()
        if all(t in lower_item for t in tokens):
            result.append(item)
    return result


# ─── Key Reading ──────────────────────────────────────────────────────

def _get_key_windows():
    import msvcrt
    ch = msvcrt.getwch()
    if ch in ("\x00", "\xe0"):
        code = msvcrt.getwch()
        return ("special", code)
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
                _map = {"A": "H", "B": "P", "C": "M", "D": "K"}
                code = _map.get(ch3)
                if code:
                    return ("special", code)
            return ("char", "\x1b")
        return ("char", ch)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

get_key = _get_key_windows if sys.platform == "win32" else _get_key_unix


# ─── Terminal Helpers ─────────────────────────────────────────────────

def term_size():
    try:
        cols, rows = os.get_terminal_size()
    except OSError:
        cols, rows = 80, 24
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

def set_fg(r, g, b):
    write(f"\033[38;2;{r};{g};{b}m")

def set_fg256(c):
    write(f"\033[38;5;{c}m")

def set_bg256(c):
    write(f"\033[48;5;{c}m")

def bold():
    write("\033[1m")

def dim():
    write("\033[2m")

def underline():
    write("\033[4m")

def reset():
    write("\033[0m")

def inverse():
    write("\033[7m")

def erase_line():
    write("\033[2K")

def clip_text(text, max_width):
    if len(text) <= max_width:
        return text
    if max_width <= 1:
        return text[:max_width]
    return text[:max_width - 1] + "…"


# ─── State ────────────────────────────────────────────────────────────

PICKER_MODE = 1
PROMPT_MODE = 2
SEP = " > "


class FinderState:
    def __init__(self):
        self.mode = PICKER_MODE
        self.filters = []        # list of picker names in chain
        self.prompts = []        # list of query strings per filter
        self.items = []          # current result items
        self.current_type = NONE
        self.sel = 0             # selected item index (0-based)
        self.scroll_offset = 0
        self.query_buf = []      # current query being typed
        self.picks = []          # available pickers for current type
        self.filter_items_cache = {}  # cache for filter results
        self.loading = False
        self.async_results = None
        self.async_lock = threading.Lock()

    def query(self):
        return "".join(self.query_buf)

    def get_available_pickers(self):
        """Get pickers that accept the current data type."""
        valid = []
        for name, picker in sorted(ALL_PICKERS.items()):
            if not picker.hidden and self.current_type in picker.accepts:
                valid.append(name)
        return valid

    def evaluate(self):
        """Re-evaluate the filter chain."""
        items = None
        current_type = NONE

        for i, filter_name in enumerate(self.filters):
            picker = ALL_PICKERS.get(filter_name)
            if not picker:
                continue

            query = self.prompts[i] if i < len(self.prompts) else ""
            result = picker.filter(query, items)
            items = result if result else []
            current_type = picker.produces

        self.items = items or []
        self.current_type = current_type
        self.sel = 0
        self.scroll_offset = 0
        self.picks = self.get_available_pickers()


# ─── Rendering ────────────────────────────────────────────────────────

def get_unique_prefixes(names):
    """Compute unique prefix lengths for each picker name."""
    prefixes = {}
    for i, name in enumerate(names):
        length = 1
        while length <= len(name):
            prefix = name[:length].lower()
            unique = True
            for j, other in enumerate(names):
                if i != j and other[:length].lower() == prefix:
                    unique = False
                    break
            if unique:
                break
            length += 1
        prefixes[name] = length
    return prefixes


def render(state):
    cols, rows = term_size()
    clear_screen()

    # Layout: top area = results, bottom 1-2 lines = bar + separator
    bar_row = rows
    sep_row = rows - 1
    list_height = rows - 2  # above separator

    # ── Separator line ────────────────────────────────────────────
    move_to(sep_row)
    dim()
    write("─" * cols)
    reset()

    # ── Bottom bar ────────────────────────────────────────────────
    move_to(bar_row)
    erase_line()

    bar_parts = []

    # Show filter chain
    for i, name in enumerate(state.filters):
        dim()
        write(name)
        reset()
        if i < len(state.filters) - 1 or state.mode == PICKER_MODE:
            dim()
            write(SEP)
            reset()

    # Show item count
    n = len(state.items)
    if n > 0:
        active = state.sel + 1
        count_str = f" {active}/{n} "
        set_fg256(245)
        write(count_str)
        reset()

    if state.mode == PROMPT_MODE:
        # Show query with cursor
        q = state.query()
        set_fg256(255)
        bold()
        write(q)
        reset()
        write("█")

    elif state.mode == PICKER_MODE:
        # Show available pickers with highlighted prefixes
        picks = state.picks
        if not picks:
            picks = state.get_available_pickers()
        prefixes = get_unique_prefixes(picks)
        for i, name in enumerate(picks):
            plen = prefixes[name]
            set_fg256(75)   # blue for prefix
            bold()
            write(name[:plen])
            reset()
            set_fg256(248)  # gray for rest
            write(name[plen:])
            reset()
            if i < len(picks) - 1:
                write("  ")

        # If user is typing picker name
        q = state.query()
        if q:
            write("  ")
            set_fg256(255)
            bold()
            write(q)
            reset()
            write("█")

    # ── Results list ──────────────────────────────────────────────
    n = len(state.items)
    if n == 0:
        if state.loading:
            move_to(rows - 2)
            dim()
            write(" searching...")
            reset()
        elif state.mode == PROMPT_MODE and state.query():
            move_to(rows - 2)
            dim()
            write(" no results")
            reset()
    else:
        visible = min(n, list_height)
        # Ensure selected item is visible
        if state.sel < state.scroll_offset:
            state.scroll_offset = state.sel
        elif state.sel >= state.scroll_offset + visible:
            state.scroll_offset = state.sel - visible + 1

        for i in range(visible):
            idx = state.scroll_offset + i
            if idx >= n:
                break
            # Items render bottom-up (newest at bottom, closest to bar)
            row = sep_row - 1 - i + state.scroll_offset
            # Actually, render top-down in the results area
            row = 1 + i
            move_to(row)
            erase_line()

            is_sel = idx == state.sel
            item = state.items[idx]

            # Line number prefix
            num_width = len(str(n))
            num_str = f" {idx + 1:>{num_width}} "

            if is_sel:
                set_fg256(75)  # blue highlight
                bold()
                write(num_str)
            else:
                dim()
                write(num_str)
            reset()

            # Item content (handle grep format: file:line:content)
            file, line, content = parse_grep_item(item)
            available = cols - len(num_str) - 1

            if content is not None:
                # Grep format: show content + file
                file_display = os.path.basename(file) if not is_sel else file
                file_part = f" {file_display}:{line}"
                content_width = available - len(file_part)
                if content_width > 0:
                    display_content = clip_text(content.strip(), content_width)
                else:
                    display_content = ""

                if is_sel:
                    set_fg256(255)
                    bold()
                else:
                    set_fg256(252)
                # Highlight matching parts in content
                write_highlighted(display_content, state.query() if state.mode == PROMPT_MODE else "", is_sel)
                reset()

                # File part (dimmer)
                remaining = available - len(display_content)
                if remaining > 0:
                    padding = " " * max(0, remaining - len(file_part))
                    if is_sel:
                        set_fg256(75)
                    else:
                        dim()
                    write(padding + clip_text(file_part, remaining))
                reset()
            else:
                # Plain file path
                display = clip_text(item, available)
                if is_sel:
                    set_fg256(255)
                    bold()
                write_highlighted(display, state.query() if state.mode == PROMPT_MODE else "", is_sel)
                reset()

    flush()


def write_highlighted(text, query, is_sel):
    """Write text with query matches highlighted."""
    if not query or not query.strip():
        write(text)
        return

    tokens = query.lower().split()
    # Find all match positions
    lower = text.lower()
    matches = set()
    for tok in tokens:
        start = 0
        while start < len(lower):
            pos = lower.find(tok, start)
            if pos == -1:
                break
            for p in range(pos, min(pos + len(tok), len(text))):
                matches.add(p)
            start = pos + 1

    # Write character by character, toggling highlight
    in_match = False
    for i, ch in enumerate(text):
        if i in matches:
            if not in_match:
                if is_sel:
                    set_fg256(226)  # yellow on selected
                else:
                    set_fg256(75)   # blue on normal
                bold()
                in_match = True
        else:
            if in_match:
                reset()
                if is_sel:
                    set_fg256(255)
                    bold()
                else:
                    set_fg256(252)
                in_match = False
        write(ch)

    if in_match:
        reset()


# ─── Async search support ──────────────────────────────────────────

def run_search_async(state, picker, query, items):
    """Run a picker's filter in a background thread."""
    def worker():
        try:
            result = picker.filter(query, items)
        except Exception:
            result = []
        with state.async_lock:
            state.async_results = result
            state.loading = False

    state.loading = True
    state.async_results = None
    t = threading.Thread(target=worker, daemon=True)
    t.start()


# ─── Match picker from typed text ────────────────────────────────────

def match_picker(picks, typed):
    """Find which picker matches the typed text."""
    if not typed:
        return None
    typed_lower = typed.lower()
    prefixes = get_unique_prefixes(picks)

    # Exact prefix match
    for name in picks:
        plen = prefixes[name]
        if typed_lower == name[:plen].lower():
            return name

    # Partial match
    for name in picks:
        if name.lower().startswith(typed_lower):
            return name

    return None


# ─── Main loop ────────────────────────────────────────────────────────

def main():
    state = FinderState()
    state.picks = state.get_available_pickers()

    # If initial picker provided, jump straight to prompt mode
    if INITIAL_PICKER and INITIAL_PICKER in ALL_PICKERS:
        state.filters.append(INITIAL_PICKER)
        state.prompts.append("")
        state.mode = PROMPT_MODE
        state.current_type = ALL_PICKERS[INITIAL_PICKER].produces
        state.picks = state.get_available_pickers()

    hide_cursor()

    try:
        while True:
            # Check for async results
            with state.async_lock:
                if state.async_results is not None:
                    state.items = state.async_results
                    state.async_results = None
                    state.sel = 0
                    state.scroll_offset = 0

            render(state)

            kind, ch = get_key()

            if kind == "special":
                if ch == "H":  # Up
                    if state.sel > 0:
                        state.sel -= 1
                elif ch == "P":  # Down
                    if state.sel < len(state.items) - 1:
                        state.sel += 1

            elif kind == "char":
                if ch == "\x1b":  # Escape
                    if state.mode == PROMPT_MODE and state.query_buf:
                        # Clear query first
                        state.query_buf.clear()
                        # Re-evaluate with empty query
                        if state.filters:
                            idx = len(state.filters) - 1
                            state.prompts[idx] = ""
                            state.evaluate()
                    elif state.mode == PROMPT_MODE:
                        # Close finder
                        emit_signal("close")
                        break
                    else:
                        emit_signal("close")
                        break

                elif ch == "\r" or ch == "\n":  # Enter
                    if state.mode == PICKER_MODE:
                        # Try to select a picker from typed text
                        typed = state.query()
                        if typed:
                            matched = match_picker(state.picks, typed)
                            if matched:
                                state.filters.append(matched)
                                state.prompts.append("")
                                state.mode = PROMPT_MODE
                                state.query_buf.clear()
                                state.current_type = ALL_PICKERS[matched].produces
                                state.picks = state.get_available_pickers()
                        elif state.picks and len(state.picks) == 1:
                            # Only one picker available, auto-select
                            name = state.picks[0]
                            state.filters.append(name)
                            state.prompts.append("")
                            state.mode = PROMPT_MODE
                            state.query_buf.clear()
                            state.current_type = ALL_PICKERS[name].produces
                            state.picks = state.get_available_pickers()

                    elif state.mode == PROMPT_MODE:
                        # Open selected item
                        if state.items and 0 <= state.sel < len(state.items):
                            item = state.items[state.sel]
                            picker_name = state.filters[-1] if state.filters else None
                            picker = ALL_PICKERS.get(picker_name) if picker_name else None
                            query = state.query()
                            if picker and picker.on_open:
                                signal = picker.on_open(item, query)
                                if signal:
                                    emit_signal(signal)
                                    break
                            else:
                                emit_signal(f"open:{item}")
                                break

                elif ch == "\t":  # Tab — push selection forward to next picker
                    if state.mode == PROMPT_MODE and state.items:
                        # Chain: use current results as input to next picker
                        state.picks = state.get_available_pickers()
                        if state.picks:
                            state.mode = PICKER_MODE
                            state.query_buf.clear()

                    elif state.mode == PICKER_MODE:
                        # Try to select picker from typed text (like Enter)
                        typed = state.query()
                        matched = match_picker(state.picks, typed) if typed else None
                        if matched:
                            state.filters.append(matched)
                            state.prompts.append("")
                            state.mode = PROMPT_MODE
                            state.query_buf.clear()
                            state.current_type = ALL_PICKERS[matched].produces
                            state.picks = state.get_available_pickers()

                elif ch == "\x08" or ch == "\x7f":  # Backspace
                    if state.query_buf:
                        state.query_buf.pop()
                        if state.mode == PROMPT_MODE:
                            query = state.query()
                            if state.filters:
                                idx = len(state.filters) - 1
                                state.prompts[idx] = query
                            # Re-filter
                            run_filter(state)
                    elif state.mode == PROMPT_MODE:
                        # At column 0: go back in filter chain
                        if state.filters:
                            state.filters.pop()
                            if state.prompts:
                                state.prompts.pop()
                            # Restore previous type
                            if state.filters:
                                last_picker = ALL_PICKERS.get(state.filters[-1])
                                state.current_type = last_picker.produces if last_picker else NONE
                                # Restore previous query
                                prev_q = state.prompts[-1] if state.prompts else ""
                                state.query_buf = list(prev_q)
                                state.evaluate()
                            else:
                                state.current_type = NONE
                                state.items = []
                                state.mode = PICKER_MODE
                                state.query_buf.clear()
                            state.picks = state.get_available_pickers()

                elif ch == "\x0b":  # Ctrl+K  — select up
                    if state.sel > 0:
                        state.sel -= 1

                elif ch == "\x0a":  # Ctrl+J  — select down (LF)
                    if state.sel < len(state.items) - 1:
                        state.sel += 1

                elif ch >= " ":  # Normal character
                    state.query_buf.append(ch)

                    if state.mode == PICKER_MODE:
                        # Check if typed text matches a picker
                        typed = state.query()
                        matched = match_picker(state.picks, typed)
                        # Don't auto-switch yet, wait for separator/Enter/Tab

                    elif state.mode == PROMPT_MODE:
                        query = state.query()
                        if state.filters:
                            idx = len(state.filters) - 1
                            if idx < len(state.prompts):
                                state.prompts[idx] = query
                            else:
                                state.prompts.append(query)
                        # Re-filter
                        run_filter(state)

    finally:
        show_cursor()
        reset()
        clear_screen()
        move_to(1)


def run_filter(state):
    """Run the current filter chain, using async for expensive pickers."""
    if not state.filters:
        state.items = []
        return

    picker_name = state.filters[-1]
    picker = ALL_PICKERS.get(picker_name)
    if not picker:
        return

    query = state.query()
    if len(query) < picker.min_query:
        state.items = []
        state.sel = 0
        return

    # Get items from previous stage
    prev_items = None
    if len(state.filters) > 1:
        # Re-evaluate previous stages
        prev_items = None
        prev_type = NONE
        for i in range(len(state.filters) - 1):
            prev_picker = ALL_PICKERS.get(state.filters[i])
            if prev_picker:
                prev_query = state.prompts[i] if i < len(state.prompts) else ""
                prev_items = prev_picker.filter(prev_query, prev_items)
                prev_type = prev_picker.produces

    # For grep, use async
    if picker_name == "Grep":
        run_search_async(state, picker, query, prev_items)
    else:
        try:
            result = picker.filter(query, prev_items)
            state.items = result or []
            state.sel = 0
            state.scroll_offset = 0
        except Exception:
            state.items = []


if __name__ == "__main__":
    main()
