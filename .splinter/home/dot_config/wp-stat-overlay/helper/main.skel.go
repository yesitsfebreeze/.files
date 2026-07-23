// §source home/dot_config/wp-stat-overlay/helper/main.go
// wpstats — a tiny cross-platform helper for the Wallpaper Engine web wallpaper.
//
// WE web wallpapers run inside a Chromium sandbox that can't read global
// keyboard activity or load local files cross-origin. This helper runs on the
// host and serves, over localhost:
//   • GET /typing            — ms since the last keystroke (drives the typing look)
//   • GET /file?p=<path>     — local image/video over http
//   • GET /video?p=<path>    — local video, transcoding mp4→webm as needed
//   • GET /yt?u=<url>        — resolve a YouTube channel "/live" URL to a video id
//
// Build:  go build -o wpstats .
// Run:    ./wpstats            (listens on 127.0.0.1:8787)
//         ./wpstats -addr 127.0.0.1:9000
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

func main() {
// §.splinter/home/dot_config/wp-stat-overlay/helper/main/main.fs
}

// ytVideoIDRe pulls the first 11-char video id out of a YouTube page. On a
// channel "/live" URL the page is the live watch page, whose own videoId leads
// the HTML, so the first match is the active stream.
var ytVideoIDRe = regexp.MustCompile(`"videoId":"([A-Za-z0-9_-]{11})"`)

var ytClient = &http.Client{Timeout: 8 * time.Second}

// resolveYouTubeLive fetches a YouTube URL and returns the live video id it
// renders. Restricted to youtube hosts so it can't be used as a generic proxy.
func resolveYouTubeLive(rawurl string) (string, error) {
// §.splinter/home/dot_config/wp-stat-overlay/helper/main/resolveYouTubeLive.fs
}

// mediaType maps a file extension to a browser-friendly MIME type, so /file
// serves videos/images the wallpaper can actually play. Empty = let ServeFile
// decide.
func mediaType(p string) string {
// §.splinter/home/dot_config/wp-stat-overlay/helper/main/mediaType.fs
}
