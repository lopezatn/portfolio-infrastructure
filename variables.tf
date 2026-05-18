variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Domain name for the portfolio"
  type        = string
  default     = "lopezberg.dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium)$", var.instance_type))
    error_message = "Instance type must be a t2 or t3 instance (nano, micro, small, or medium)."
  }
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "github_actions_ssm_policy_arn" {
  description = "ARN of the scoped SSM policy for GitHub Actions"
  type        = string
}