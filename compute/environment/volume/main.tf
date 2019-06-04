variable "availability_zone" {
}

variable "environment" {
}

data "template_file" "data_volume_name" {
  template = terraform.workspace == "default" ? "caronae-${var.environment}-data" : "caronae-${terraform.workspace}-${var.environment}-data"
}

resource "aws_ebs_volume" "caronae_data" {
  availability_zone = var.availability_zone
  size              = 1

  tags = {
    Name        = data.template_file.data_volume_name.rendered
    Environment = var.environment
    Workspace   = terraform.workspace
  }
}

output "data_volume" {
  value = aws_ebs_volume.caronae_data.id
}
