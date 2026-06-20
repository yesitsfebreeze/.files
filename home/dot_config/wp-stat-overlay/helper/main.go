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
	addr := flag.String("addr", "127.0.0.1:8787", "listen address")
	flag.Parse()

	mux := http.NewServeMux()
	// /file?p=<abs path> — serve a local media file over http so the wallpaper
	// (a file:// origin) can load images/videos that Chromium would otherwise
	// block as cross-origin local resources. http.ServeFile gives correct
	// content types and HTTP range support (so video seeking works). Bound to
	// 127.0.0.1 in main(), so only local processes can reach it.
	mux.HandleFunc("/file", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		p := r.URL.Query().Get("p")
		if p == "" {
			http.Error(w, "missing p", http.StatusBadRequest)
			return
		}
		// Set an explicit media content type by extension — Go has no built-in
		// mp4/webm mapping, so ServeFile would otherwise fall back to sniffing
		// or octet-stream and the browser would refuse to play the video.
		if ct := mediaType(p); ct != "" {
			w.Header().Set("Content-Type", ct)
		}
		http.ServeFile(w, r, p)
	})
	// /video?p=<path> — like /file, but transcodes non-web formats (mp4/…) to
	// cached webm so WE's codec-less Chromium can play them.
	mux.HandleFunc("/video", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		p := r.URL.Query().Get("p")
		if p == "" {
			http.Error(w, "missing p", http.StatusBadRequest)
			return
		}
		serveVideo(w, r, p)
	})
	// /typing reports keyboard-activity only: milliseconds since the last
	// keystroke (system-wide). The wallpaper polls this fast to fade between its
	// resting and typing looks. keyIdleMs is provided per-OS (keyboard_*.go); it
	// records that a key was pressed and when — never which key.
	mux.HandleFunc("/typing", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		if err := json.NewEncoder(w).Encode(map[string]int64{"keyIdleMs": keyIdleMs()}); err != nil {
			log.Printf("encode: %v", err)
		}
	})
	// /yt?u=<youtube url> — resolve a channel "live" URL (e.g.
	// youtube.com/@NASA/live or youtube.com/nasa/live) to the id of the video
	// currently streaming. Those URLs carry no video id, so the wallpaper can't
	// build an /embed link from them client-side; we fetch the page server-side
	// (no CORS limit here) and read the live videoId out of the HTML.
	mux.HandleFunc("/yt", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		u := r.URL.Query().Get("u")
		if u == "" {
			http.Error(w, "missing u", http.StatusBadRequest)
			return
		}
		id, err := resolveYouTubeLive(u)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		if id == "" {
			http.Error(w, "no live video found on that page", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(map[string]string{"videoId": id})
	})
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Write([]byte("wpstats ok — try /typing, /file?p=<path>, /video?p=<path>, /yt?u=<url>\n"))
	})

	log.Printf("wpstats listening on http://%s", *addr)
	srv := &http.Server{Addr: *addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	log.Fatal(srv.ListenAndServe())
}

// ytVideoIDRe pulls the first 11-char video id out of a YouTube page. On a
// channel "/live" URL the page is the live watch page, whose own videoId leads
// the HTML, so the first match is the active stream.
var ytVideoIDRe = regexp.MustCompile(`"videoId":"([A-Za-z0-9_-]{11})"`)

var ytClient = &http.Client{Timeout: 8 * time.Second}

// resolveYouTubeLive fetches a YouTube URL and returns the live video id it
// renders. Restricted to youtube hosts so it can't be used as a generic proxy.
func resolveYouTubeLive(rawurl string) (string, error) {
	pu, err := url.Parse(rawurl)
	if err != nil {
		return "", fmt.Errorf("bad url: %w", err)
	}
	host := strings.ToLower(pu.Hostname())
	if host != "youtube.com" && host != "youtu.be" && !strings.HasSuffix(host, ".youtube.com") {
		return "", fmt.Errorf("not a youtube url")
	}
	req, err := http.NewRequest(http.MethodGet, rawurl, nil)
	if err != nil {
		return "", err
	}
	// A desktop UA gets the full watch markup; the bare Go UA gets a stub.
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "+
		"AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	resp, err := ytClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20)) // 4 MB cap
	if err != nil {
		return "", err
	}
	if m := ytVideoIDRe.FindSubmatch(body); m != nil {
		return string(m[1]), nil
	}
	return "", nil
}

// mediaType maps a file extension to a browser-friendly MIME type, so /file
// serves videos/images the wallpaper can actually play. Empty = let ServeFile
// decide.
func mediaType(p string) string {
	switch strings.ToLower(filepath.Ext(p)) {
	case ".mp4", ".m4v":
		return "video/mp4"
	case ".webm":
		return "video/webm"
	case ".ogv", ".ogg":
		return "video/ogg"
	case ".mov":
		return "video/quicktime"
	case ".mkv":
		return "video/x-matroska"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	case ".webp":
		return "image/webp"
	case ".avif":
		return "image/avif"
	case ".bmp":
		return "image/bmp"
	case ".svg":
		return "image/svg+xml"
	}
	return ""
}
