terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.0"
    }
  }
}
provider "aws" {
    region = var.region 
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnet_id = data.aws_subnets.default.ids[0]
}


# --- IAM Role for SSM ---
resource "aws_iam_role" "ssm" {
  name = "${var.name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ssm.name
}

# --- Security Group (HTTP Only) ---
resource "aws_security_group" "web" {
  name        = "${var.name}-sg"
  description = "Allow HTTP only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

# --- EC2 Instance ---
resource "aws_instance" "this" {
  ami                         = "ami-06297e16b71156b52"
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm.name

  # No SSH Keys: SSM access only
  key_name = null

  # Install Docker
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf update -y
    dnf install -y dnf-plugins-core
    cat >/etc/yum.repos.d/docker-ce.repo <<'REPO'
    [docker-ce-stable]
    name=Docker CE Stable - RHEL 9
    baseurl=https://download.docker.com/linux/rhel/9/$basearch/stable
    enabled=1
    gpgcheck=1
    gpgkey=https://download.docker.com/linux/rhel/gpg
    REPO
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker ec2-user || true
  EOF

  tags = { Name = var.name }
}