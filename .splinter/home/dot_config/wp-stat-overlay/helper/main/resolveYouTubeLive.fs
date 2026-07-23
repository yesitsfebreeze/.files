// §head home/dot_config/wp-stat-overlay/helper/main.go:122-152 resolveYouTubeLive
// §sig func resolveYouTubeLive(rawurl string) (string, error)
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
// §foot home/dot_config/wp-stat-overlay/helper/main.go resolveYouTubeLive