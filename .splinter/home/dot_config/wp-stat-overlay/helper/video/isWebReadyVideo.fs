// §head home/dot_config/wp-stat-overlay/helper/video.go:42-48 isWebReadyVideo
// §sig func isWebReadyVideo(ext string) bool
	switch ext {
	case ".webm", ".ogg", ".ogv":
		return true
	}
	return false
// §foot home/dot_config/wp-stat-overlay/helper/video.go isWebReadyVideo