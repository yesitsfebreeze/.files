// §head home/dot_config/wp-stat-overlay/helper/keyboard_windows.go:49-56 hookProc
// §sig func hookProc(nCode int, wParam, lParam uintptr) uintptr
	if nCode >= 0 {
		// A key event happened. Record when — nothing about which key.
		atomic.StoreInt64(&lastKeyMs, time.Now().UnixMilli())
	}
	ret, _, _ := procCallNextHookEx.Call(0, uintptr(nCode), wParam, lParam)
	return ret
// §foot home/dot_config/wp-stat-overlay/helper/keyboard_windows.go hookProc