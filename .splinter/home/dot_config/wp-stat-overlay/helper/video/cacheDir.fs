// §head home/dot_config/wp-stat-overlay/helper/video.go:25-29 cacheDir
// §sig func cacheDir() string
	d := filepath.Join(os.TempDir(), "wpstats-cache")
	os.MkdirAll(d, 0o755)
	return d
// §foot home/dot_config/wp-stat-overlay/helper/video.go cacheDir