# Portfolio Infrastructure - Terraform Configuration

**Purpose**
This repository contains a personal AWS infrastructure portfolio built to practice real-world DevOps and cloud operations.
The infrastructure is provisioned using Terraform and focuses on Linux-based systems, networking, security boundaries, DNS, and cost-aware design.
It represents an end-to-end setup including compute, access control, monitoring, and public exposure of services.
The goal is to build, operate, and troubleshoot infrastructure as a system, with an emphasis on reliability, observability, and automation.

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
