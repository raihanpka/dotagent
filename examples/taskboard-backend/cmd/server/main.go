package main

import (
	"log"

	"github.com/raihanpka/taskboard/internal/app"
	"github.com/raihanpka/taskboard/internal/config"
)

func main() {
	cfg := config.Load()
	if err := app.New().Run(cfg.Addr); err != nil {
		log.Fatal(err)
	}
}
