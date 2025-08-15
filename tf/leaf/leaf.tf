terraform {
  required_providers {
    jetstream = {
      source  = "nats-io/jetstream"
      version = "0.2.1"
    }
  }
}

provider "jetstream" {
  servers     = "nats://localhost:4223"
  credentials = "../../.leaf/creds/leaf/A/leaf.creds"
}

# config copied from local.tf > QUEUE
resource "jetstream_stream" "QUEUE" {
  name         = "QUEUE"
  subjects     = ["QUEUE.>"]
  storage      = "file"
  retention    = "limits"         # must use "limits" so we can mirror into NGS
  max_age      = 24 * 60 * 60     // 24 hours
  max_bytes    = 1024 * 1024 * 10 // 10Mi
  max_msgs     = 1024             // 1 Ki
  allow_direct = true
}
