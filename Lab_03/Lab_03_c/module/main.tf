resource "aws_iam_user" "yogi_terraform_user" {
  name = "yogi_terraform_user"
  tags = {
    name = "yogi_terraform_user"
  }
}