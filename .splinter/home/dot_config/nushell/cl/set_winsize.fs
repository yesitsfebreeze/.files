# §head home/dot_config/nushell/cl.py:11-17 set_winsize
# §sig def set_winsize(fd):
"""Mirror our terminal size onto the child pty so the TUI lays out right."""
    try:
        s = fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, s)
    except Exception:
        pass
# §foot home/dot_config/nushell/cl.py set_winsize