provider "aws" {
  region = "eu-west-2"
}

#creating trusted entity
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
    type        = "Service"
    identifiers = ["ec2.amazonaws.com"]
                }
            }
}

#creating a policy
resource "aws_iam_policy" "s3_policy" {
  name   = "AmazonS3FullAccess"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

#creating a role that can be assumed by an EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "aws_capstone_EC2_S3_Full_Access"

  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

#attach the role to the policy file
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.s3_policy.arn
}

#create an instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

#attach the instance profile to the ec2 instance
resource "aws_instance" "role-test" {
  ami                  = var.ami
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = "FirstKey"

  tags = {
    Name = "capstone_ec2"
  }
}