provider "aws" {
  region = var.aws_region
}

########################
# S3 (Data Lake)
########################

resource "aws_s3_bucket" "weather" {
  bucket = "weather-streaming-${var.account_id}"
}

########################
# Kinesis Stream
########################

resource "aws_kinesis_stream" "weather" {
  name             = "weather-stream"
  shard_count      = 1
  retention_period = 24
}

########################
# IAM for Lambda
########################

resource "aws_iam_role" "lambda" {
  name = "weather-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.weather.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.weather.arn
      }
    ]
  })
}

########################
# Lambda Consumer
########################

resource "aws_lambda_function" "consumer" {
  function_name = "weather-consumer"
  role          = aws_iam_role.lambda.arn
  handler       = "consumer.lambda_handler"
  runtime       = "python3.11"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      BUCKET = aws_s3_bucket.weather.bucket
    }
  }
}

########################
# Kinesis → Lambda mapping
########################

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.weather.arn
  function_name     = aws_lambda_function.consumer.arn
  starting_position = "LATEST"
}
