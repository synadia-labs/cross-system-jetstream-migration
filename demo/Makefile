.PHONY: orders shipments publisher clean all help

# Default target
all: build-orders build-shipments build-publisher

# Environment variables
NATS_URL ?= nats://localhost:4222
NATS_CREDS_PATH ?= 

# Build targets
build-orders:
	@go build -o orders cmd/orders/main.go

build-shipments:
	@go build -o shipments cmd/shipments/main.go

build-publisher:
	@go build -o publisher cmd/publisher/main.go

# Run targets
orders: build-orders
	@NATS_URL=$(NATS_URL) NATS_CREDS_PATH=$(NATS_CREDS_PATH) ./orders

shipments: build-shipments
	@NATS_URL=$(NATS_URL) NATS_CREDS_PATH=$(NATS_CREDS_PATH) ./shipments

publisher: build-publisher
	@NATS_URL=$(NATS_URL) NATS_CREDS_PATH=$(NATS_CREDS_PATH) ./publisher

# Utility targets
clean:
	@echo "Cleaning binaries..."
	@rm -f orders shipments publisher

help:
	@echo "Available targets:"
	@echo "  all         - Build all services"
	@echo "  orders      - Build and run orders service"
	@echo "  shipments   - Build and run shipments service"
	@echo "  publisher   - Build and run publisher service"
	@echo "  clean       - Remove built binaries"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  NATS_URL         - NATS server URL (default: nats://localhost:4222)"
	@echo "  NATS_CREDS_PATH  - Path to NATS credentials file"
