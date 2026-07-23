// §source home/dot_config/wp-stat-overlay/helper/exec_other.go
//go:build !windows

package main

import "os/exec"

// No console-window concept off Windows; nothing to suppress.
func hideWindow(cmd *exec.Cmd) {
// §.splinter/home/dot_config/wp-stat-overlay/helper/exec_other/hideWindow.fs
}
