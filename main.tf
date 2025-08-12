terraform {
  required_providers {
    jetstream = {
      source  = "nats-io/jetstream"
      version = "0.2.1"
    }
  }
}

provider "jetstream" {
  servers = "nats://localhost:4222"
}

resource "jetstream_stream" "QUEUE" {
  name      = "QUEUE"
  subjects  = ["QUEUE.>"]
  storage   = "file"
  retention = "interest"       // or "workqueue" ?
  max_age   = 24 * 60 * 60     // 24 hours
  max_bytes = 1024 * 1024 * 10 // 10Mi
  max_msgs  = 1024             // 1 Ki
}

resource "jetstream_consumer" "ORDERS" {
  stream_id      = jetstream_stream.QUEUE.id
  durable_name   = "ORDERS"
  description    = "Processes new orders"
  deliver_all    = true
  filter_subject = "QUEUE.ORDERS.>"
}

resource "jetstream_consumer" "SHIPMENTS" {
  stream_id      = jetstream_stream.QUEUE.id
  durable_name   = "SHIPMENTS"
  description    = "Processes shipments after orders are processed"
  deliver_all    = true
  filter_subject = "QUEUE.SHIPMENTS.>"
}
