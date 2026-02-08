##################
# Kinesis Stream
##################

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

##################
# IAM Role – Producer
##################

resource "aws_iam_role" "producer" {
  name = "${var.project}-producer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "producer_kinesis" {
  name = "${var.project}-producer-kinesis-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ]
      Resource = aws_kinesis_stream.weather.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "producer_attach" {
  role       = aws_iam_role.producer.name
  policy_arn = aws_iam_policy.producer_kinesis.arn
}

##################
# IAM Role – Lambda Consumer
##################

resource "aws_iam_role" "consumer" {
  name = "${var.project}-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "consumer_kinesis" {
  name = "${var.project}-consumer-kinesis-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.weather.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_attach" {
  role       = aws_iam_role.consumer.name
  policy_arn = aws_iam_policy.consumer_kinesis.arn
}

##################
# Lambda Consumer
##################

resource "aws_lambda_function" "weather_consumer" {
  function_name = "${var.project}-weather-consumer"
  role          = aws_iam_role.consumer.arn
  runtime       = "python3.11"
  handler       = "consumer.lambda_handler"

  filename         = "../../../lambda/consumer.zip"
  source_code_hash = filebase64sha256("../../../lambda/consumer.zip")

  timeout      = 30
  memory_size = 256
}

##################
# Kinesis → Lambda
##################

resource "aws_lambda_event_source_mapping" "weather_mapping" {
  event_source_arn  = aws_kinesis_stream.weather.arn
  function_name     = aws_lambda_function.weather_consumer.arn
  starting_position = "LATEST"
  batch_size        = 100
}

