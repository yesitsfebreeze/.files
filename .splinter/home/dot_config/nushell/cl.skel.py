# §source home/dot_config/nushell/cl.py
#!/usr/bin/env python3
# cl.py — launch claude and auto-submit the goal + loop messages, then hand the
# terminal back to you.
#
# claude runs in-place under a pty (no tmux/zellij, no detached session, no
# attach), so its TUI renders correctly everywhere, including inside burrito.
# A background thread types the two seed messages and then control is yours.
import os, sys, pty, time, select, termios, tty, fcntl, signal, threading


def set_winsize(fd):
    
# §.splinter/home/dot_config/nushell/cl/set_winsize.fs



def main():
    
# §.splinter/home/dot_config/nushell/cl/main.fs



if __name__ == "__main__":
    main()
