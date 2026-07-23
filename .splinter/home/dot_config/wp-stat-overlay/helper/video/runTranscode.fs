// §head home/dot_config/wp-stat-overlay/helper/video.go:111-139 runTranscode
// §sig func runTranscode(ff, src, out, key string)
	defer func() {
		transcodeMu.Lock()
		delete(transcoding, key)
		transcodeMu.Unlock()
	}()
	tmp := out + ".part"
	// No audio (wallpaper is muted), cap to 2560px wide for speed, VP9 webm.
	cmd := exec.Command(ff, "-y", "-i", src,
		"-an",
		"-vf", "scale='min(2560,iw)':-2",
		"-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32",
		"-row-mt", "1", "-deadline", "good", "-cpu-used", "5",
		"-pix_fmt", "yuv420p",
		"-f", "webm", tmp)
	hideWindow(cmd) // no console flash on Windows
	log.Printf("transcoding %s -> %s", src, out)
	if err := cmd.Run(); err != nil {
		os.Remove(tmp)
		log.Printf("transcode failed for %s: %v", src, err)
		return
	}
	if err := os.Rename(tmp, out); err != nil {
		log.Printf("cache rename failed: %v", err)
		os.Remove(tmp)
		return
	}
	log.Printf("transcode done: %s", out)
// §foot home/dot_config/wp-stat-overlay/helper/video.go runTranscode