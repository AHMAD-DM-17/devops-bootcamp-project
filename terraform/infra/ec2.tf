data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data_common = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y snapd
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  private_ip             = local.web_private_ip
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  user_data                   = local.user_data_common

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.tags, { Name = "devops-web-server" })
}

resource "aws_eip" "web" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "devops-web-eip" })
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}

resource "aws_instance" "ansible" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  private_ip             = local.ansible_private_ip
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  user_data                   = local.user_data_common

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.tags, { Name = "devops-ansible-controller" })
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  private_ip             = local.monitoring_private_ip
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  user_data                   = local.user_data_common

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.tags, { Name = "devops-monitoring-server" })
}
