// §head home/dot_config/wp-stat-overlay/helper/main.go:30-111 main
// §sig func main()
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
// §foot home/dot_config/wp-stat-overlay/helper/main.go main