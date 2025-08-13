terraform {
  required_providers {
    jetstream = {
      source  = "nats-io/jetstream"
      version = "0.2.1"
    }
  }
}

provider "jetstream" {
  servers     = "tls://connect.ngs.synadia-test.com:4222"
  credentials = "./cloud.creds"
}

resource "jetstream_stream" "QUEUE_source" {
  name      = "QUEUE_source"
  subjects  = ["QUEUE.>"]
  storage   = "file"
  retention = "interest"       // or "workqueue" ?
  max_age   = 24 * 60 * 60     // 24 hours
  max_bytes = 1024 * 1024 * 10 // 10Mi
  max_msgs  = 1024             // 1 Ki

  # source from the imported stream
  source {
    name = "QUEUE"
    # TODO: get from import.sh as tf variables
    external {
      api     = "$scp.31CcDdRlPssxeBpNwpm9dnNw2pH.$JS.API"
      deliver = "$scp.31CcDdRlPssxeBpNwpm9dnNw2pH.deliver.ADFITOJFGNYPL5TAXZ2BL5VAZK7L6XBJDLDXZ3PQWFWYCYSQK4TE222K"
    }
    # subject_transform {}
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
