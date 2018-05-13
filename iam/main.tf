variable "certificates_bucket" {}
variable "user_content_bucket" {}

data "aws_iam_policy_document" "assume_ec2_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "caronae_instance" {
  name               = "caronae-instance-${terraform.workspace}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_ec2_role.json}"
}

resource "aws_iam_policy" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
       "Effect": "Allow",
       "Action": [
          "kms:Decrypt",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
       ],
       "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "caronae_certificates_bucket_read" {
  name = "CaronaeReadCertificatesS3Bucket-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${var.certificates_bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ["${var.certificates_bucket}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "caronae_user_content_bucket" {
  name = "CaronaeUserContentS3BucketWrite-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${var.user_content_bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging"
      ],
      "Resource": ["${var.user_content_bucket}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_instance.arn}"
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_s3" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "arn:aws:iam::236688692074:policy/CaronaeWriteToS3Bucket"
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_certificates" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_certificates_bucket_read.arn}"
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_user_content" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_user_content_bucket.arn}"
}

resource "aws_iam_instance_profile" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  role = "${aws_iam_role.caronae_instance.name}"
}

output "instance_iam_profile" {
  value = "${aws_iam_instance_profile.caronae_instance.id}"
}
