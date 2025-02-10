#  AWS Provider

provider "aws" {
  region = "us-east-1"
}

# To Create VPC 

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "DEMo-VPC"
  }
}

# To Create VPC & attach to vpc

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "DEMO-IGW"
  }
}

# To create public subnet

resource "aws_subnet" "public-subnet" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "DEMO-subnet-pub"
  }
}

# To create public Route Table

resource "aws_route_table" "Public-RTC" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-RTC"
  }
}

# Subnet Association

resource "aws_route_table_association" "public-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.Public-RTC.id
}

# To create a security group

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DEMO-SG"
  }
}

# To create Key-Pair

resource "aws_key_pair" "tf-key-pair" {
  key_name   = "demo"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair"
}

# To create EC2 instance

resource "aws_instance" "ec2-web" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = "t2.medium"
  availability_zone           = "us-east-1a"
  key_name                    = "tf-key-pair"
  vpc_security_group_ids      = ["${aws_security_group.allow_tls.id}"]
  subnet_id                   = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  # user_data                   = file("cloud-init.sh")

  root_block_device {
    volume_size = "50"
    volume_type = "io1"
    iops        = "300"

  }

  #user_data = file("demo.yaml")

  tags = {
    Name = "demo-cluster"
  }
}
resource "null_resource" "null-res-01" {

  connection {
    type        = "ssh"
    host        = aws_instance.ec2-web.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.rsa.private_key_pem
  }



  provisioner "remote-exec" {
    inline = [
      "demo status --wait",
      file("demo.sh"),
      "sudo apt-get update",
      "sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts",
      "sudo helm repo add stable https://charts.helm.sh/stable",
      "sudo helm repo update",
      "sudo microk8s helm install prometheus prometheus-community/kube-prometheus-stack",
      "sudo microk8s helm repo add openverso https://gradiant.github.io/openverso-charts/",
      "sudo microk8s helm repo update",
      "sudo wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update && sudo apt install terraform",
      "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
      "sudo echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \https://pkg.jenkins.io/debian-stable binary/ | sudo tee \/etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install jenkins",
 

    ]
  }

  depends_on = [aws_instance.ec2-web]

}



