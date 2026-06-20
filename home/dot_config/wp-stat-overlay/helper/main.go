// wpstats — a tiny cross-platform system-stats agent for the Wallpaper Engine
// "stats overlay" web wallpaper.
//
// WE web wallpapers run inside a Chromium sandbox and cannot read CPU/GPU/RAM
// directly. This helper runs on the host and serves a JSON snapshot over
// localhost; the wallpaper polls GET /stats once a second and renders it.
//
// Build:  go build -o wpstats .
// Run:    ./wpstats            (listens on 127.0.0.1:8787)
//         ./wpstats -addr 127.0.0.1:9000
//
// Cross-platform via gopsutil for CPU/RAM/net/disk/uptime/temps. GPU is
// best-effort: NVIDIA via `nvidia-smi` when present, otherwise omitted.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
)

// Stats is the JSON shape the wallpaper consumes. Fields that can't be sampled
// on a given OS are left zero / empty and the overlay hides them.
type Stats struct {
	TimeUnix int64 `json:"time"`     // server clock (unix seconds), for the overlay clock
	Uptime   uint64 `json:"uptime"`  // host uptime, seconds

	CPU     float64   `json:"cpu"`      // total CPU usage %
	CPUCore []float64 `json:"cpuCore"`  // per-core usage %

	MemUsed    uint64  `json:"memUsed"`    // bytes
	MemTotal   uint64  `json:"memTotal"`   // bytes
	MemPercent float64 `json:"memPercent"` // %

	NetUp   float64 `json:"netUp"`   // bytes/sec (sent)
	NetDown float64 `json:"netDown"` // bytes/sec (recv)

	DiskRead  float64 `json:"diskRead"`  // bytes/sec
	DiskWrite float64 `json:"diskWrite"` // bytes/sec

	GPU      *GPUStats `json:"gpu,omitempty"`      // nil when unavailable
	CPUTemp  float64   `json:"cpuTemp,omitempty"`  // °C, 0 if unknown
}

type GPUStats struct {
	Name      string  `json:"name"`
	Usage     float64 `json:"usage"`     // %
	MemUsed   uint64  `json:"memUsed"`   // bytes
	MemTotal  uint64  `json:"memTotal"`  // bytes
	Temp      float64 `json:"temp"`      // °C
}

// sampler holds the previous counters needed to turn cumulative net/disk
// byte counts into per-second rates. Guarded by mu because /stats may be hit
// concurrently.
type sampler struct {
	mu sync.Mutex

	lastTime  time.Time
	lastNet   net.IOCountersStat
	lastDisk  disk.IOCountersStat
	haveDelta bool
}

func main() {
	addr := flag.String("addr", "127.0.0.1:8787", "listen address")
	flag.Parse()

	s := &sampler{}

	mux := http.NewServeMux()
	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		// The wallpaper is loaded from a file:// (or WE) origin, so allow CORS.
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")

		st := s.sample()
		if err := json.NewEncoder(w).Encode(st); err != nil {
			log.Printf("encode: %v", err)
		}
	})
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
		w.Write([]byte("wpstats ok — try /stats, /typing, /file?p=<path>, /video?p=<path>, /yt?u=<url>\n"))
	})

	log.Printf("wpstats listening on http://%s/stats", *addr)
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

func (s *sampler) sample() Stats {
	now := time.Now()
	st := Stats{
		TimeUnix: now.Unix(),
		CPUCore:  []float64{},
	}

	// CPU total + per-core (non-blocking: percent since previous call).
	if tot, err := cpu.Percent(0, false); err == nil && len(tot) > 0 {
		st.CPU = round1(tot[0])
	}
	if per, err := cpu.Percent(0, true); err == nil {
		for _, v := range per {
			st.CPUCore = append(st.CPUCore, round1(v))
		}
	}

	// Memory.
	if vm, err := mem.VirtualMemory(); err == nil {
		st.MemUsed = vm.Used
		st.MemTotal = vm.Total
		st.MemPercent = round1(vm.UsedPercent)
	}

	// Uptime.
	if up, err := host.Uptime(); err == nil {
		st.Uptime = up
	}

	// CPU temperature (best-effort; empty on many Windows configs).
	if temps, err := host.SensorsTemperatures(); err == nil {
		st.CPUTemp = pickCPUTemp(temps)
	}

	// Net + disk: cumulative counters turned into per-second rates.
	s.mu.Lock()
	var curNet net.IOCountersStat
	if ns, err := net.IOCounters(false); err == nil && len(ns) > 0 {
		curNet = ns[0] // aggregate across interfaces
	}
	var curDisk disk.IOCountersStat
	if dm, err := disk.IOCounters(); err == nil {
		for _, d := range dm { // sum all devices
			curDisk.ReadBytes += d.ReadBytes
			curDisk.WriteBytes += d.WriteBytes
		}
	}
	if s.haveDelta {
		dt := now.Sub(s.lastTime).Seconds()
		if dt > 0 {
			st.NetUp = rate(curNet.BytesSent, s.lastNet.BytesSent, dt)
			st.NetDown = rate(curNet.BytesRecv, s.lastNet.BytesRecv, dt)
			st.DiskRead = rate(curDisk.ReadBytes, s.lastDisk.ReadBytes, dt)
			st.DiskWrite = rate(curDisk.WriteBytes, s.lastDisk.WriteBytes, dt)
		}
	}
	s.lastNet = curNet
	s.lastDisk = curDisk
	s.lastTime = now
	s.haveDelta = true
	s.mu.Unlock()

	// GPU (NVIDIA only, best-effort).
	if g := nvidiaGPU(); g != nil {
		st.GPU = g
	}

	return st
}

// pickCPUTemp returns a representative CPU temperature from the sensor list,
// preferring obvious package/core sensors and otherwise the max reading.
func pickCPUTemp(temps []host.TemperatureStat) float64 {
	var best float64
	for _, t := range temps {
		k := strings.ToLower(t.SensorKey)
		if strings.Contains(k, "package") || strings.Contains(k, "tctl") ||
			strings.Contains(k, "core") || strings.Contains(k, "cpu") {
			if t.Temperature > best {
				best = t.Temperature
			}
		}
	}
	if best == 0 { // fall back to the hottest sensor of any kind
		for _, t := range temps {
			if t.Temperature > best {
				best = t.Temperature
			}
		}
	}
	return round1(best)
}

// nvidiaGPU shells out to nvidia-smi. Returns nil if the binary is missing or
// fails, so the overlay simply hides the GPU panel on non-NVIDIA systems.
func nvidiaGPU() *GPUStats {
	cmd := exec.Command("nvidia-smi",
		"--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu",
		"--format=csv,noheader,nounits")
	hideWindow(cmd) // suppress the per-poll console flash on Windows (no-op elsewhere)
	out, err := cmd.Output()
	if err != nil {
		return nil
	}
	line := strings.TrimSpace(string(out))
	if line == "" {
		return nil
	}
	// Only the first GPU.
	if i := strings.IndexByte(line, '\n'); i >= 0 {
		line = line[:i]
	}
	f := strings.Split(line, ",")
	if len(f) < 5 {
		return nil
	}
	g := &GPUStats{Name: strings.TrimSpace(f[0])}
	g.Usage = parseF(f[1])
	g.MemUsed = uint64(parseF(f[2])) * 1024 * 1024  // nvidia-smi reports MiB
	g.MemTotal = uint64(parseF(f[3])) * 1024 * 1024
	g.Temp = parseF(f[4])
	return g
}

func parseF(s string) float64 {
	v, _ := strconv.ParseFloat(strings.TrimSpace(s), 64)
	return v
}

func rate(cur, prev uint64, dt float64) float64 {
	if cur < prev { // counter reset/wrap
		return 0
	}
	return round1(float64(cur-prev) / dt)
}

func round1(v float64) float64 {
	return float64(int64(v*10+0.5)) / 10
}
