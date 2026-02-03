# Portfolio Infrastructure - Terraform Configuration

This Terraform configuration creates the AWS infrastructure for the portfolio website as described in the roadmap.

## What This Creates

1. **IAM Role & Instance Profile** - Allows EC2 to communicate with Systems Manager
2. **Security Group** - Allows only HTTP (80) and HTTPS (443), NO SSH
3. **EC2 Instance** - t3.micro Ubuntu 24.04 LTS with IMDSv2 enforced
4. **Elastic IP** - Static IP address that won't change on reboot
5. **Route 53 Hosted Zone** - DNS management for your domain
6. **Route 53 A Records** - Points your domain and www subdomain to the Elastic IP

## Prerequisites

Before running this:
1. AWS CLI configured with your IAM user credentials
2. Session Manager plugin installed
3. Terraform installed (version >= 1.0)

## Setup Instructions

### Step 1: Create Your Variables File

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit it with your values (domain is already set to lopezberg.dev)
# You can leave aws_region and instance_type as defaults
```

### Step 2: Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and prepares Terraform.

### Step 3: Plan the Changes

```bash
terraform plan
```

This shows you what Terraform will create. Review it carefully. You should see:
- 1 IAM role
- 1 IAM role policy attachment
- 1 IAM instance profile
- 1 Security group
- 1 EC2 instance
- 1 Elastic IP
- 1 Route 53 hosted zone
- 2 Route 53 A records

### Step 4: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will:
- Create all the infrastructure (~2-3 minutes)
- Output important information including:
  - Instance ID
  - Elastic IP address
  - Route 53 nameservers
  - SSM connect command

### Step 5: Update Your Domain Registrar

After `terraform apply` completes, you'll see nameservers in the output. You need to:
1. Go to your domain registrar (where you bought lopezberg.dev)
2. Update the nameservers to the ones shown in the Terraform output
3. Wait for DNS propagation (can take up to 48 hours, usually much faster)

### Step 6: Connect to Your Instance

Wait 2-3 minutes after the instance is created for the SSM agent to register, then:

```bash
# Use the command from the Terraform output, or:
aws ssm start-session --target <instance-id> --region eu-central-1
```

Replace `<instance-id>` with the actual instance ID from the output.

## Key Security Features

✅ **No SSH exposed** - Port 22 is completely blocked  
✅ **SSM access only** - Connect via AWS Systems Manager  
✅ **IMDSv2 enforced** - Prevents SSRF attacks on instance metadata  
✅ **Minimal attack surface** - Only ports 80 and 443 open  
✅ **Encrypted root volume** - Data at rest encryption enabled  

## Cost Estimate

- **Free Tier (first 12 months)**: ~$0.50/month (Route 53 only)
- **After Free Tier**: ~$8/month (EC2 + Route 53)

## Useful Commands

```bash
# View current state
terraform show

# View outputs again
terraform output

# Destroy everything (careful!)
terraform destroy

# Format code
terraform fmt

# Validate configuration
terraform validate
```

## Next Steps

Once your infrastructure is running:
1. Connect via SSM
2. Install Docker (Phase 2 of your roadmap)
3. Run Nginx container
4. Configure HTTPS with Let's Encrypt

## Troubleshooting

**Can't connect via SSM?**
- Wait 2-3 minutes after instance creation
- Check IAM role is attached: `aws ec2 describe-instances --instance-ids <id>`
- Verify SSM agent status in AWS Console

**Domain not resolving?**
- Check nameservers updated at registrar
- DNS propagation can take time (use `dig lopezberg.dev` to check)
- Make sure A records were created: `aws route53 list-resource-record-sets --hosted-zone-id <zone-id>`

**Terraform errors?**
- Share the full error message
- Check AWS credentials: `aws sts get-caller-identity`
- Verify region is correct

## Important Notes

- The `.tfstate` file tracks what Terraform created - **do NOT delete it**
- Never commit `terraform.tfvars` to git (it's already gitignored)
- If you need to recreate everything, just run `terraform apply` again
- This uses **local state** - the state file is on your machine

## Interview Talking Points

This configuration demonstrates:
- **Infrastructure as Code** - Repeatable, version-controlled infrastructure
- **Security best practices** - No SSH, minimal attack surface, IMDSv2
- **Cost awareness** - Free tier eligible, under $10/month post-trial
- **Cloud fundamentals** - IAM, VPC, EC2, Route 53, security groups
- **Tradeoff decisions** - Simple architecture with explicit limitations

When discussing this in interviews, emphasize the deliberate choices and what you're NOT optimizing for (HA, DDoS protection) and how you WOULD scale it (ALB, CloudFront, auto-scaling).
