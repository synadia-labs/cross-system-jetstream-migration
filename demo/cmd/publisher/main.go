package main

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"time"

	"demo/pkg"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

func main() {
	ctx := context.Background()

	config, err := pkg.ReadConfig()
	if err != nil {
		fmt.Println("Error reading config:", err)
		os.Exit(1)
	}

	nc, err := nats.Connect(config.URL, nats.UserCredentials(config.CredsPath), nats.Name("publisher"))
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

	// get the latest order id from the stream
	js, err := jetstream.New(nc)
	if err != nil {
		fmt.Println("Error creating jetstream:", err)
		os.Exit(1)
	}

	queue, err := js.Stream(ctx, config.StreamName)
	if err != nil {
		fmt.Println("Error getting stream info:", err)
		os.Exit(1)
	}

	var orderId int

	msg, err := queue.GetLastMsgForSubject(ctx, "QUEUE.ORDERS.>")
	if err != nil && !errors.Is(err, jetstream.ErrMsgNotFound) {
		fmt.Println("Error getting last message for QUEUE.ORDERS.>", err)
		os.Exit(1)
	}
	if msg != nil {
		parts := strings.Split(msg.Subject, ".")
		orderId, err = strconv.Atoi(parts[len(parts)-1])
		if err != nil {
			fmt.Println("Error parsing order ID:", err)
			os.Exit(1)
		}
	}

	// Start with the next order ID
	orderId += 1

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
