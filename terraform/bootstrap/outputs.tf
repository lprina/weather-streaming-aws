output "access_key_id" {
  value = aws_iam_access_key.terraform.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.terraform.secret
  sensitive = true
}
