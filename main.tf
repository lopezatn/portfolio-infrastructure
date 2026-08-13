terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "lopezberg-terraform-state-343218214405-eu-central-1-an"
    key    = "portfolio-web/terraform.tfstate"
    region = "eu-central-1"
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

provider "github" {
  owner = var.github_owner
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

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

resource "aws_iam_role_policy" "ec2_s3_scoped" {
  name = "portfolio-ec2-s3-scoped"
  role = aws_iam_role.portfolio_ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FrontendDeployRead"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = "arn:aws:s3:::lopezberg-portfolio-deploy/dist/*"
      },
      {
        Sid    = "SSMLogsWrite"
        Effect = "Allow"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::lopezberg-portfolio-deploy/ssm-logs/*"
      },
      {
        Sid    = "FrontendDeployList"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = "arn:aws:s3:::lopezberg-portfolio-deploy"
      }
    ]
  })
}

resource "aws_iam_role" "github_actions_terraform_role" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:lopezatn/portfolio-infrastructure:*"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "github_actions_terraform_policy" {
  statement {
    sid       = "EC2"
    effect    = "Allow"
    actions   = [
      "ec2:DescribeImages", "ec2:DescribeInstances", "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceTypes", "ec2:DescribeInstanceCreditSpecifications",
      "ec2:DescribeVolumes", "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeAddresses", "ec2:DescribeAddressesAttribute", "ec2:DescribeVpcs",
      "ec2:DescribeSubnets", "ec2:DescribeNetworkInterfaces", "ec2:DescribeTags",
      "ec2:RunInstances", "ec2:StartInstances", "ec2:StopInstances", "ec2:TerminateInstances",
      "ec2:ModifyInstanceAttribute", "ec2:ModifyInstanceMetadataOptions",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress", "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:AllocateAddress", "ec2:ReleaseAddress", "ec2:AssociateAddress",
      "ec2:DisassociateAddress", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeAccountAttributes",
      "ec2:DescribeVpcAttribute"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAM"
    effect = "Allow"
    actions = [
      "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole",
      "iam:UpdateRoleDescription", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
      "iam:GetRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:ListRolePolicies", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies", "iam:PassRole",
      "iam:GetInstanceProfile", "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile", "iam:UntagInstanceProfile", "iam:ListInstanceProfilesForRole",
      "iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions", "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion", "iam:TagPolicy", "iam:UntagPolicy", "iam:ListPolicyTags"
    ]
    resources = [
      "arn:aws:iam::343218214405:role/portfolio-*",
      "arn:aws:iam::343218214405:role/github-actions-*",
      "arn:aws:iam::343218214405:instance-profile/portfolio-*",
      "arn:aws:iam::343218214405:policy/portfolio-*",
      "arn:aws:iam::343218214405:policy/github-actions-*"
    ]
  }

  statement {
    sid    = "Route53"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone", "route53:ListHostedZones", "route53:ListHostedZonesByName",
      "route53:ChangeResourceRecordSets", "route53:GetChange",
      "route53:ListResourceRecordSets", "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3StateBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
      "s3:GetBucketVersioning", "s3:GetBucketAcl", "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration", "s3:GetBucketPublicAccessBlock"
    ]
    resources = [
      "arn:aws:s3:::lopezberg-terraform-state-343218214405-eu-central-1-an",
      "arn:aws:s3:::lopezberg-terraform-state-343218214405-eu-central-1-an/*"
    ]
  }

  statement {
    sid    = "S3DeployBucket"
    effect = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketAcl", "s3:GetBucketLocation"]
    resources = [
      "arn:aws:s3:::lopezberg-portfolio-deploy",
      "arn:aws:s3:::lopezberg-portfolio-deploy/*"
    ]
  }

  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:CreatePatchBaseline", "ssm:DeletePatchBaseline", "ssm:GetPatchBaseline",
      "ssm:UpdatePatchBaseline", "ssm:RegisterPatchBaselineForPatchGroup",
      "ssm:DeregisterPatchBaselineForPatchGroup", "ssm:GetDefaultPatchBaseline",
      "ssm:DescribePatchBaselines", "ssm:CreateMaintenanceWindow", "ssm:DeleteMaintenanceWindow",
      "ssm:GetMaintenanceWindow", "ssm:UpdateMaintenanceWindow", "ssm:ListTagsForResource",
      "ssm:AddTagsToResource", "ssm:RemoveTagsFromResource",
      "ssm:RegisterTargetWithMaintenanceWindow", "ssm:DeregisterTargetFromMaintenanceWindow",
      "ssm:UpdateMaintenanceWindowTarget", "ssm:RegisterTaskWithMaintenanceWindow",
      "ssm:DeregisterTaskFromMaintenanceWindow", "ssm:GetMaintenanceWindowTask",
      "ssm:UpdateMaintenanceWindowTask", "ssm:DescribeMaintenanceWindowTargets",
      "ssm:DescribeMaintenanceWindowTasks", "ssm:DescribePatchGroups", "ssm:DescribeMaintenanceWindows"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "OIDC"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider", "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider", "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider", "iam:RemoveClientIDFromOpenIDConnectProvider"
    ]
    resources = ["arn:aws:iam::343218214405:oidc-provider/*"]
  }
}

resource "aws_iam_policy" "github_actions_terraform_policy" {
  name   = "github-actions-terraform-policy"
  policy = data.aws_iam_policy_document.github_actions_terraform_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_policy_attachment" {
  role       = aws_iam_role.github_actions_terraform_role.name
  policy_arn = aws_iam_policy.github_actions_terraform_policy.arn
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-portfolio-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:lopezatn/portfolio-frontend:*"
          }
        }
      }    
    ]
  })

  tags = {
    Name = "github-actions-portfolio-deploy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_policy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_actions_ssm_policy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = var.github_actions_ssm_policy_arn
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.portfolio_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "container_registry_policy" {
  role       = aws_iam_role.portfolio_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_instance_profile" "portfolio_profile" {
  name = "portfolio-ec2-profile"
  role = aws_iam_role.portfolio_ec2_role.name
}

resource "aws_security_group" "portfolio_web_sg" {
  name        = "portfolio-web-sg"
  description = "Allow HTTP and HTTPS inbound, all outbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Health API calls from anywhere"
  }


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

resource "aws_instance" "portfolio_web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.portfolio_profile.name
  vpc_security_group_ids = [aws_security_group.portfolio_web_sg.id]
  
  lifecycle {
    ignore_changes = [ ami ]
  }

  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
              #!/bin/bash
              snap start amazon-ssm-agent
              snap restart amazon-ssm-agent
              EOF

  tags = {
    Name = "portfolio-web-server"
    PatchGroup = "portfolio-production"
  }
}

resource "aws_eip" "portfolio_eip" {
  instance = aws_instance.portfolio_web.id
  domain   = "vpc"

  tags = {
    Name = "portfolio-eip"
  }
}

data "aws_route53_zone" "portfolio" {
  name = var.domain_name

  private_zone = false
}

resource "aws_route53_record" "portfolio_a" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.portfolio_eip.public_ip]
}

resource "aws_route53_record" "portfolio_www" {
  zone_id = data.aws_route53_zone.portfolio.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.portfolio_eip.public_ip]
}

resource "github_repository_environment" "production" {
  repository  = "portfolio-infrastructure"
  environment = "production"

  reviewers {
    users = ["83620071"]
  }
}