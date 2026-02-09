resource "aws_lambda_function" "weather_consumer" {
  function_name = "${var.project}-weather-consumer"
  role          = aws_iam_role.consumer.arn
  runtime       = "python3.11"
  handler       = "consumer.lambda_handler"

  filename         = "../../../lambda/consumer.zip"
  source_code_hash = filebase64sha256("../../../lambda/consumer.zip")

  timeout     = 30
  memory_size = 256
}

resource "aws_lambda_event_source_mapping" "weather_mapping" {
  event_source_arn  = aws_kinesis_stream.weather.arn
  function_name     = aws_lambda_function.weather_consumer.arn
  starting_position = "LATEST"
  batch_size        = 100
}
