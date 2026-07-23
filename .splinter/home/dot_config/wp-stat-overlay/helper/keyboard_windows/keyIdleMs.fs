// §head home/dot_config/wp-stat-overlay/helper/keyboard_windows.go:80-82 keyIdleMs
// §sig func keyIdleMs() int64
	return time.Now().UnixMilli() - atomic.LoadInt64(&lastKeyMs)
// §foot home/dot_config/wp-stat-overlay/helper/keyboard_windows.go keyIdleMs