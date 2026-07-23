// §source home/dot_config/wp-stat-overlay/helper/keyboard_other.go
//go:build !windows

// keyboard_other.go — no global keyboard hook off Windows. Wallpaper Engine is
// Windows-only, so on other platforms (e.g. a Linux dev box) we just report a
// large idle time, which keeps the wallpaper in its resting look.
package main

func keyIdleMs() int64 {
// §.splinter/home/dot_config/wp-stat-overlay/helper/keyboard_other/keyIdleMs.fs
}
