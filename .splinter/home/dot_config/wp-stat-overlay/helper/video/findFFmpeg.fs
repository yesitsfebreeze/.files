// §head home/dot_config/wp-stat-overlay/helper/video.go:52-67 findFFmpeg
// §sig func findFFmpeg() string
	if p, err := exec.LookPath("ffmpeg"); err == nil {
		return p
	}
	var cands []string
	if home, err := os.UserHomeDir(); err == nil {
		cands = append(cands, filepath.Join(home, "scoop", "shims", "ffmpeg.exe"))
	}
	cands = append(cands, `C:\ProgramData\chocolatey\bin\ffmpeg.exe`, `C:\ffmpeg\bin\ffmpeg.exe`)
	for _, c := range cands {
		if _, err := os.Stat(c); err == nil {
			return c
		}
	}
	return ""
// §foot home/dot_config/wp-stat-overlay/helper/video.go findFFmpeg