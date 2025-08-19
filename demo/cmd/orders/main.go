package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"os/signal"
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

	nc, err := nats.Connect(config.URL, nats.UserCredentials(config.CredsPath), nats.Name("orders"))
	if err != nil {
		fmt.Println("Error connecting to NATS:", err)
		os.Exit(1)
	}

	// get ORDERS consumer
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

	orders, err := queue.Consumer(ctx, "ORDERS")
	if err != nil {
		fmt.Println("Error getting consumer info:", err)
		os.Exit(1)
	}

	consumerCtx, err := orders.Consume(func(msg jetstream.Msg) {
		// simulate delay in processing
		// timer with random interval between 1 and 5 seconds
		wait := time.Duration(rand.Intn(4)+1) * time.Second
		time.Sleep(wait)

		parts := strings.Split(msg.Subject(), ".")
		orderId := parts[len(parts)-1]

		fmt.Printf("Received order: %s\n", orderId)

		// start shipment process
		err := nc.Publish("QUEUE.SHIPMENTS."+orderId, []byte("Shipped"))
		if err != nil {
			fmt.Println("Error publishing shipment:", err)
		}

		err = msg.Ack()
		if err != nil {
			fmt.Println("Error acking message:", err)
		}
	})
	if err != nil {
		fmt.Println("Error consuming:", err)
		os.Exit(1)
	}

	fmt.Printf("Consuming orders on %s\n", config.URL)

	// wait for Ctrl+C
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	<-c

	consumerCtx.Stop()
	<-consumerCtx.Closed()
}
