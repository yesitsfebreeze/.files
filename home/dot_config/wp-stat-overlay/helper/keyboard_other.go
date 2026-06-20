//go:build !windows

// keyboard_other.go — no global keyboard hook off Windows. Wallpaper Engine is
// Windows-only, so on other platforms (e.g. a Linux dev box) we just report a
// large idle time, which keeps the wallpaper in its resting look.
package main

func keyIdleMs() int64 {
	return 1 << 40 // ~ "forever idle"
}
