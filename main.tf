provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "app_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "ReactNativeNotesApp"
  }

  # Optionally, use a remote-exec provisioner to install prerequisites
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y git nodejs npm"
      # Optionally, install Docker or Nginx if needed.
    ]
  }
}
