//go:build windows

// keyboard_windows.go — global keyboard-activity detection for the /typing
// endpoint. A WE web wallpaper can't see global key events, so the helper
// installs a low-level keyboard hook (WH_KEYBOARD_LL) and records only the
// timestamp of the most recent keystroke. It deliberately never inspects which
// key was pressed — this is activity detection for a visual effect, not a
// keylogger.
package main

import (
	"runtime"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"
)

const whKeyboardLL = 13

var (
	user32              = syscall.NewLazyDLL("user32.dll")
	procSetWindowsHook  = user32.NewProc("SetWindowsHookExW")
	procCallNextHookEx  = user32.NewProc("CallNextHookEx")
	procGetMessageW     = user32.NewProc("GetMessageW")
	kernel32            = syscall.NewLazyDLL("kernel32.dll")
	procGetModuleHandle = kernel32.NewProc("GetModuleHandleW")
)

// lastKeyMs is the unix-millis timestamp of the most recent keystroke, read by
// keyIdleMs() and written by the hook callback. Accessed atomically because the
// hook runs on its own OS thread.
var lastKeyMs int64

type winMsg struct {
	hwnd    uintptr
	message uint32
	wParam  uintptr
	lParam  uintptr
	time    uint32
	pt      struct{ x, y int32 }
}

func init() {
	atomic.StoreInt64(&lastKeyMs, time.Now().UnixMilli())
	go hookLoop()
}

func hookProc(nCode int, wParam, lParam uintptr) uintptr {
	if nCode >= 0 {
		// A key event happened. Record when — nothing about which key.
		atomic.StoreInt64(&lastKeyMs, time.Now().UnixMilli())
	}
	ret, _, _ := procCallNextHookEx.Call(0, uintptr(nCode), wParam, lParam)
	return ret
}

// hookLoop installs the low-level keyboard hook and pumps messages. WH_KEYBOARD_LL
// hooks are dispatched through the installing thread's message queue, so this
// goroutine must own its OS thread and keep a GetMessage loop alive for the
// callback to ever fire.
func hookLoop() {
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
}

// keyIdleMs returns milliseconds since the last keystroke.
func keyIdleMs() int64 {
	return time.Now().UnixMilli() - atomic.LoadInt64(&lastKeyMs)
}
