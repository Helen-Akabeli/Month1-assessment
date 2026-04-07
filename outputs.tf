output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.techcorp_vpc.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.techcorp_alb.dns_name
}

output "load_balancer_url" {
  description = "Full HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.techcorp_alb.dns_name}"
}

output "web_server_private_ips" {
  description = "Private IPs of web servers — use these to SSH into them from the bastion"
  value       = aws_instance.webs[*].private_ip
}

output "db_server_private_ip" {
  description = "Private IP of the DB server — use this to SSH into it from the bastion"
  value       = aws_instance.db.private_ip
}