resource "aws_kinesis_stream" "weather" {
  name             = "${var.project}-weather-stream"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  tags = {
    Project = var.project
    Service = "weather-streaming"
  }
}
