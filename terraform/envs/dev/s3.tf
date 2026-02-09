resource "aws_s3_bucket" "weather_data" {
  bucket        = "weather-streaming-data-dev"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "weather_data" {
  bucket = aws_s3_bucket.weather_data.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
