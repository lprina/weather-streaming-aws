provider "aws" {
  region = var.aws_region
}

resource "aws_iam_user" "terraform" {
  name = "terraform-admin"
}

resource "aws_iam_access_key" "terraform" {
  user = aws_iam_user.terraform.name
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
