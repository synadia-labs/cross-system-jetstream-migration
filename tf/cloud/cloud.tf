terraform {
  required_providers {
    jetstream = {
      source  = "nats-io/jetstream"
      version = "0.2.1"
    }
  }
}

provider "jetstream" {
  servers     = "tls://connect.ngs.global"
  credentials = "./cloud.creds"
}

resource "jetstream_stream" "QUEUE_source" {
  name      = "QUEUE_source"
  storage   = "file"
  retention = "limits"         // TODO: "interest"
  max_age   = 24 * 60 * 60     // 24 hours
  max_bytes = 1024 * 1024 * 10 // 10Mi
  max_msgs  = 1024             // 1 Ki

  source {
    name = "QUEUE"
    external {
      api = "$JS.leaf.API"
    }
  }
}

resource "jetstream_consumer" "ORDERS_cloud" {
  stream_id      = jetstream_stream.QUEUE_source.id
  durable_name   = "ORDERS"
  description    = "Processes new orders"
  deliver_all    = true
  filter_subject = "QUEUE.ORDERS.>"
  max_batch      = 1000
}

resource "jetstream_consumer" "SHIPMENTS_cloud" {
  stream_id      = jetstream_stream.QUEUE_source.id
  durable_name   = "SHIPMENTS"
  description    = "Processes shipments after orders are processed"
  deliver_all    = true
  filter_subject = "QUEUE.SHIPMENTS.>"
  max_batch      = 1000
}
