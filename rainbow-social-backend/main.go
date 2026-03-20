package main

import (
	"log"

	"rainbow-social-backend/cmd"
)

func main() {
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}
