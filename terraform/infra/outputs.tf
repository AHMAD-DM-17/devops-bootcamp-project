output "web_eip" {
  value = aws_eip.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}

output "ansible_private_ip" {
  value = aws_instance.ansible.private_ip
}

output "monitoring_private_ip" {
  value = aws_instance.monitoring.private_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.final_project_repo.repository_url
}
