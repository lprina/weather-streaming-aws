output "kinesis_stream_name" {
  value = aws_kinesis_stream.weather.name
}

output "kinesis_stream_arn" {
  value = aws_kinesis_stream.weather.arn
}

output "producer_role_arn" {
  value = aws_iam_role.producer.arn
}

output "consumer_role_arn" {
  value = aws_iam_role.consumer.arn
}