provider "aws" {
  region = "us-east-1"
}

# Get Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Security Group
resource "aws_security_group" "dokploy" {
  name = "dokploy-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "dokploy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name              = "tf-key"
  vpc_security_group_ids = [aws_security_group.dokploy.id]
  user_data              = file("user-data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "dokploy-server"
  }
}

# Elastic IP
resource "aws_eip" "dokploy" {
  domain   = "vpc"
  instance = aws_instance.dokploy.id
}

output "ip" {
  value = aws_eip.dokploy.public_ip
}

output "url" {
  value = "http://${aws_eip.dokploy.public_ip}:3000"
}

output "ssh" {
  value = "ssh -i tf-key.pem ubuntu@${aws_eip.dokploy.public_ip}"
}

output "harobr" {
  value = "Username: admin, Password: Harbor12345"
}