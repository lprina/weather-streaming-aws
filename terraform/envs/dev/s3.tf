resource "aws_s3_bucket" "weather_data" {
  bucket = "${var.project}-data-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "weather_data" {
  bucket = aws_s3_bucket.weather_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

