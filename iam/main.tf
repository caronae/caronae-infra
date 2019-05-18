variable "user_content_bucket" {}
variable "backups_bucket" {}

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
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeTags"
       ],
       "Resource": "*"
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

resource "aws_iam_policy" "caronae_backups_bucket" {
  name = "CaronaeBackupsS3BucketWrite-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${var.backups_bucket}"]
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
      "Resource": ["${var.backups_bucket}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_instance.arn}"
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_user_content" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_user_content_bucket.arn}"
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_backups" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_backups_bucket.arn}"
}

resource "aws_iam_policy" "caronae_ses" {
  name = "CaronaeSESSendEmailFromNoReply-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ses:FromAddress": "no-reply@caronae.org"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "caronae_role_policy_ses" {
  role       = "${aws_iam_role.caronae_instance.name}"
  policy_arn = "${aws_iam_policy.caronae_ses.arn}"
}

resource "aws_iam_instance_profile" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  role = "${aws_iam_role.caronae_instance.name}"
}

output "instance_iam_profile" {
  value = "${aws_iam_instance_profile.caronae_instance.id}"
}
