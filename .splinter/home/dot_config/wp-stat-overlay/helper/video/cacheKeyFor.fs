// §head home/dot_config/wp-stat-overlay/helper/video.go:33-40 cacheKeyFor
// §sig func cacheKeyFor(p string) (string, error)
	fi, err := os.Stat(p)
	if err != nil {
		return "", err
	}
	h := sha1.Sum([]byte(fmt.Sprintf("%s|%d|%d", p, fi.Size(), fi.ModTime().UnixNano())))
	return hex.EncodeToString(h[:]), nil
// §foot home/dot_config/wp-stat-overlay/helper/video.go cacheKeyFor