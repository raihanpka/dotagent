package config

import "os"

type Config struct {
	Addr string
}

// Load reads the settings from the environment, with a default for each.
func Load() Config {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}
	return Config{Addr: addr}
}
