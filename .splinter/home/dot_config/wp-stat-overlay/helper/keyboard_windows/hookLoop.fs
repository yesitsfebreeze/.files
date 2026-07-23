// §head home/dot_config/wp-stat-overlay/helper/keyboard_windows.go:62-77 hookLoop
// §sig func hookLoop()
	runtime.LockOSThread()

	hmod, _, _ := procGetModuleHandle.Call(0)
	cb := syscall.NewCallback(hookProc)
	hook, _, _ := procSetWindowsHook.Call(uintptr(whKeyboardLL), cb, hmod, 0)
	if hook == 0 {
		return // couldn't install; keyIdleMs stays large -> wallpaper rests
	}

	var msg winMsg
	for {
		// Blocks until a message arrives; the hook callback fires on this thread.
		procGetMessageW.Call(uintptr(unsafe.Pointer(&msg)), 0, 0, 0)
	}
// §foot home/dot_config/wp-stat-overlay/helper/keyboard_windows.go hookLoop