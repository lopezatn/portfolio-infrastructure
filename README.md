# Portfolio Infrastructure - Terraform Configuration

This Terraform configuration creates the AWS infrastructure for the portfolio website.

## What This Creates

1. **IAM Role & Instance Profile**
2. **Security Group**
3. **EC2 Instance**
4. **Elastic IP**
5. **Route 53 Hosted Zone**
6. **Route 53 A Records**

This configuration demonstrates:
- **Infrastructure as Code** - Repeatable, version-controlled infrastructure
- **Security best practices** - No SSH, minimal attack surface, IMDSv2
- **Cost awareness** - Free tier eligible, under $10/month post-trial
- **Cloud fundamentals** - IAM, VPC, EC2, Route 53, security groups
- **Tradeoff decisions** - Simple architecture with explicit limitations
