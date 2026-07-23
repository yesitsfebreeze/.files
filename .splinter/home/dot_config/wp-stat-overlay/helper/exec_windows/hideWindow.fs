// §head home/dot_config/wp-stat-overlay/helper/exec_windows.go:14-16 hideWindow
// §sig func hideWindow(cmd *exec.Cmd)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: createNoWindow}
// §foot home/dot_config/wp-stat-overlay/helper/exec_windows.go hideWindow