# Optional: generate Ansible inventory after terraform apply so you don't hand-edit IPs each time.
# Writes to var.ansible_inventory_path (default: ../ansible/inventory/hosts.ini)
resource "local_file" "ansible_inventory" {
  filename = var.ansible_inventory_path

  content = <<-EOT
[web]
${aws_instance.web.private_ip}

[monitoring]
${aws_instance.monitoring.private_ip}

[all:vars]
ansible_user=${var.ansible_user}
ansible_ssh_private_key_file=${var.ansible_private_key_path}
ansible_ssh_common_args=-o StrictHostKeyChecking=no
EOT
}
