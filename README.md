# Portfolio Infrastructure – Terraform Configuration

## Purpose
This repository contains a personal AWS infrastructure portfolio built to practice real-world DevOps and cloud operations.  
The infrastructure is provisioned using Terraform and focuses on Linux-based systems, networking, security boundaries, DNS, and cost-aware design.  
It represents an end-to-end setup including compute, access control, monitoring, and public exposure of services.  
The goal is to build, operate, and troubleshoot infrastructure as a system, with an emphasis on reliability, observability, and automation.

## Architecture Overview
- AWS VPC hosting a Linux-based EC2 instance  
- Public access provided through an Elastic IP and DNS records in Route 53  
- Network access controlled via security groups with minimal exposed ports  
- Instance access managed through AWS Systems Manager (SSM) and IAM roles  
- Logs and metrics collected via Amazon CloudWatch  

## Provisioned AWS Resources
- IAM role and instance profile  
- Security group with controlled ingress and egress  
- EC2 instance running a Linux-based environment  
- Elastic IP for stable public access  
- Route 53 hosted zone  
- Route 53 A records  

## Key Characteristics
This configuration demonstrates:

- **Infrastructure as Code**  
  Repeatable, version-controlled infrastructure using Terraform  

- **Security considerations**  
  Minimal attack surface, IAM-based access, IMDSv2  

- **Cost awareness**  
  Free-tier eligible design, under approximately $10/month post-trial  

- **Cloud fundamentals**  
  IAM, EC2, VPC, Route 53, security groups  

- **Tradeoff decisions**  
  Simple architecture with explicit limitations, favoring clarity over complexity  

## Next Improvements
- Integrate CI/CD for controlled infrastructure changes  
- Expand monitoring with additional metrics and alarms  
- Introduce private subnets and tighter network segmentation  
- Improve hardening and operational documentation  
