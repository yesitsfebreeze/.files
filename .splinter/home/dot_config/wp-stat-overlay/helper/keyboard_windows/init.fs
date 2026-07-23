// §head home/dot_config/wp-stat-overlay/helper/keyboard_windows.go:44-47 init
// §sig func init()
	atomic.StoreInt64(&lastKeyMs, time.Now().UnixMilli())
	go hookLoop()
// §foot home/dot_config/wp-stat-overlay/helper/keyboard_windows.go init