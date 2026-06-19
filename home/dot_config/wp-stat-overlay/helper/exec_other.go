//go:build !windows

package main

import "os/exec"

// No console-window concept off Windows; nothing to suppress.
func hideWindow(cmd *exec.Cmd) {}
