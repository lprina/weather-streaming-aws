variable "project" {
  type    = string
  default = "weather-streaming"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_az" {
  description = "Availability zone for public subnet"
  type        = string
  default     = "us-east-1a"
}