package pkg

import (
	"fmt"
	"os"
)

type Config struct {
	URL       string
	CredsPath string
}

func ReadConfig() (*Config, error) {
	natsUrl := os.Getenv("NATS_URL")
	if natsUrl == "" {
		return nil, fmt.Errorf("NATS_URL is not set")
	}

	natsCredsPath := os.Getenv("NATS_CREDS_PATH")
	if natsCredsPath == "" {
		return nil, fmt.Errorf("NATS_CREDS_PATH is not set")
	}

	return &Config{
		URL:       natsUrl,
		CredsPath: natsCredsPath,
	}, nil
}
