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

resource "aws_iam_policy_attachment" "roles_for_caronae_instance" {
  name       = "roles-for-caronae-instance-${terraform.workspace}"
  roles      = ["${aws_iam_role.caronae_instance.name}"]
  policy_arn = "${aws_iam_policy.caronae_instance.arn}"
}

resource "aws_iam_instance_profile" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  role = "${aws_iam_role.caronae_instance.name}"
}

output "instance_iam_profile" {
  value = "${aws_iam_instance_profile.caronae_instance.id}"
}
