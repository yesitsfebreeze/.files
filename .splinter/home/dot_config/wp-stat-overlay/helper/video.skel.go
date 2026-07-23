// §source home/dot_config/wp-stat-overlay/helper/video.go
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
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/cacheDir.fs
}

// cacheKeyFor keys the cache on path + size + mtime, so editing/replacing the
// source file produces a fresh transcode.
func cacheKeyFor(p string) (string, error) {
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/cacheKeyFor.fs
}

func isWebReadyVideo(ext string) bool {
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/isWebReadyVideo.fs
}

// findFFmpeg locates ffmpeg on PATH or in common Windows install locations
// (scoop / chocolatey), since a GUI-launched process may have a thin PATH.
func findFFmpeg() string {
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/findFFmpeg.fs
}

// serveVideo serves a web-playable video directly, or transcodes other formats
// to cached webm. While a transcode runs it returns 503 + Retry-After so the
// wallpaper can poll until the cached file is ready.
func serveVideo(w http.ResponseWriter, r *http.Request, p string) {
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/serveVideo.fs
}

func runTranscode(ff, src, out, key string) {
// §.splinter/home/dot_config/wp-stat-overlay/helper/video/runTranscode.fs
}
