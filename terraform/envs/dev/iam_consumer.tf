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

resource "aws_iam_policy" "consumer_policy" {
  name = "${var.project}-consumer-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Kinesis read
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

      # CloudWatch logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },

      # S3 write (THIS FIXES YOUR ERROR)
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::weather-streaming-data-dev/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_attach" {
  role       = aws_iam_role.consumer.name
  policy_arn = aws_iam_policy.consumer_policy.arn
}
