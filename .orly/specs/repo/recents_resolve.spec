require: checks.recents_resolve.exit equals 0

A Ctrl-Q recent picked as a relative path (fd, rg) opens the file under the directory it was picked in, not under the shell's current directory.
