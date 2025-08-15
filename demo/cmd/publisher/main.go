package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"time"

	"demo/pkg"

	"github.com/nats-io/nats.go"
)

func main() {
	config, err := pkg.ReadConfig()
	if err != nil {
		fmt.Println("Error reading config:", err)
		os.Exit(1)
	}

	nc, err := nats.Connect(config.URL, nats.UserCredentials(config.CredsPath))
	if err != nil {
		fmt.Println("Error connecting to NATS:", err)
		os.Exit(1)
	}

	fmt.Printf("Publishing on %s\n", config.URL)

	// wait for Ctrl+C
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	// timer with random interval between 1 and 5 seconds
	interval := time.Duration(rand.Intn(4)+1) * time.Second
	ticker := time.NewTicker(interval)

	orderId := 1

outer:
	for {
		select {
		case <-c:
			break outer
		case <-ticker.C:
			fmt.Printf("Publishing order %d\n", orderId)
			err := nc.Publish(fmt.Sprintf("QUEUE.ORDERS.%d", orderId), []byte{})
			if err != nil {
				fmt.Printf("Error publishing order %d: %s\n", orderId, err)
			}
			orderId++

			interval = time.Duration(rand.Intn(4)+1) * time.Second
			ticker.Reset(interval)
		}
	}

	nc.Drain()
	nc.Close()
}
