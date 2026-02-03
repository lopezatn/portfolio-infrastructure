output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.portfolio_web.id
}

output "elastic_ip" {
  description = "Elastic IP address assigned to the instance"
  value       = aws_eip.portfolio_eip.public_ip
}

output "domain_name" {
  description = "Domain name configured in Route 53"
  value       = var.domain_name
}

output "nameservers" {
  description = "Route 53 nameservers (update these at your domain registrar)"
  value       = data.aws_route53_zone.portfolio.name_servers
}

output "ssm_connect_command" {
  description = "Command to connect to the instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.portfolio_web.id} --region ${var.aws_region}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.portfolio_web_sg.id
}
