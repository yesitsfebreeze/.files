// §head home/dot_config/wp-stat-overlay/helper/video.go:72-109 serveVideo
// §sig func serveVideo(w http.ResponseWriter, r *http.Request, p string)
	ext := strings.ToLower(filepath.Ext(p))
	if isWebReadyVideo(ext) {
		if ct := mediaType(p); ct != "" {
			w.Header().Set("Content-Type", ct)
		}
		http.ServeFile(w, r, p)
		return
	}

	key, err := cacheKeyFor(p)
	if err != nil {
		http.Error(w, "source not found", http.StatusNotFound)
		return
	}
	out := filepath.Join(cacheDir(), key+".webm")
	if fi, err := os.Stat(out); err == nil && fi.Size() > 0 {
		w.Header().Set("Content-Type", "video/webm")
		http.ServeFile(w, r, out)
		return
	}

	ff := findFFmpeg()
	if ff == "" {
		http.Error(w, "ffmpeg not found — install ffmpeg, or use a webm/ogg/ogv file", http.StatusNotImplemented)
		return
	}

	transcodeMu.Lock()
	if !transcoding[key] {
		transcoding[key] = true
		go runTranscode(ff, p, out, key)
	}
	transcodeMu.Unlock()

	w.Header().Set("Retry-After", "2")
	http.Error(w, "transcoding", http.StatusServiceUnavailable)
// §foot home/dot_config/wp-stat-overlay/helper/video.go serveVideo