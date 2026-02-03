terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Portfolio"
      ManagedBy   = "Terraform"
      Environment = "Production"
    }
  }
}

# Data source to get the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 to use Systems Manager
resource "aws_iam_role" "portfolio_ec2_role" {
  name = "portfolio-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "portfolio-ec2-role"
  }
}

# Attach AWS managed policy for Systems Manager
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.portfolio_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach the role to EC2
resource "aws_iam_instance_profile" "portfolio_profile" {
  name = "portfolio-ec2-profile"
  role = aws_iam_role.portfolio_ec2_role.name
}

# Security Group - Only HTTP and HTTPS, NO SSH
resource "aws_security_group" "portfolio_web_sg" {
  name        = "portfolio-web-sg"
  description = "Allow HTTP and HTTPS inbound, all outbound"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "portfolio-web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "portfolio_web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.portfolio_profile.name
  vpc_security_group_ids = [aws_security_group.portfolio_web_sg.id]

  # Enable public IP in default VPC
  associate_public_ip_address = true

  # Enforce IMDSv2 for security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1 # Prevents SSRF attacks by limiting hops
    instance_metadata_tags      = "enabled"
  }

  # Root volume configuration
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # User data to ensure SSM agent is running (it should be by default on Ubuntu 24.04)
  user_data = <<-EOF
              #!/bin/bash
              # Ensure SSM agent is running
              snap start amazon-ssm-agent
              snap restart amazon-ssm-agent
              EOF

  tags = {
    Name = "portfolio-web-server"
  }
}

# Elastic IP
resource "aws_eip" "portfolio_eip" {
  instance = aws_instance.portfolio_web.id
  domain   = "vpc"

  tags = {
    Name = "portfolio-eip"
  }
}

# Route 53 Hosted Zone (only create if it doesn't exist)
# If you already have a hosted zone, you can import it or use data source
data "aws_route53_zone" "portfolio" {
  name = var.domain_name

  private_zone = false
}

# Route 53 A Record pointing to Elastic IP
resource "aws_route53_record" "portfolio_a" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.portfolio_eip.public_ip]
}

# Route 53 A Record for www subdomain
resource "aws_route53_record" "portfolio_www" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.portfolio_eip.public_ip]
}
