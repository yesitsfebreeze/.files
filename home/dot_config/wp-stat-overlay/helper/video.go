package main

import (
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
)

// WE's web-wallpaper Chromium ships without proprietary codecs (no H.264), so
// most .mp4 files won't play. This module serves web-ready video as-is and
// transcodes everything else to cached webm with ffmpeg, so "load an mp4" works.

var (
	transcodeMu sync.Mutex
	transcoding = map[string]bool{} // cache key -> in progress
)

func cacheDir() string {
	d := filepath.Join(os.TempDir(), "wpstats-cache")
	os.MkdirAll(d, 0o755)
	return d
}

// cacheKeyFor keys the cache on path + size + mtime, so editing/replacing the
// source file produces a fresh transcode.
func cacheKeyFor(p string) (string, error) {
	fi, err := os.Stat(p)
	if err != nil {
		return "", err
	}
	h := sha1.Sum([]byte(fmt.Sprintf("%s|%d|%d", p, fi.Size(), fi.ModTime().UnixNano())))
	return hex.EncodeToString(h[:]), nil
}

func isWebReadyVideo(ext string) bool {
	switch ext {
	case ".webm", ".ogg", ".ogv":
		return true
	}
	return false
}

// findFFmpeg locates ffmpeg on PATH or in common Windows install locations
// (scoop / chocolatey), since a GUI-launched process may have a thin PATH.
func findFFmpeg() string {
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
}

// serveVideo serves a web-playable video directly, or transcodes other formats
// to cached webm. While a transcode runs it returns 503 + Retry-After so the
// wallpaper can poll until the cached file is ready.
func serveVideo(w http.ResponseWriter, r *http.Request, p string) {
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
}

func runTranscode(ff, src, out, key string) {
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
}
