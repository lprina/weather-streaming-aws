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
