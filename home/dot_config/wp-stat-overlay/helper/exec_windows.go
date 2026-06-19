//go:build windows

package main

import (
	"os/exec"
	"syscall"
)

// CREATE_NO_WINDOW — child process gets no console, so shelling out to
// nvidia-smi from this windowsgui (console-less) exe doesn't flash a terminal.
const createNoWindow = 0x08000000

func hideWindow(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: createNoWindow}
}
