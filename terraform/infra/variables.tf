variable "root_domain" { type = string } # matches your secret.auto.tfvars

variable "cloudflare_account_id" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type      = string
  sensitive = true
}

variable "cloudflare_email" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_ssl_mode" {
  type    = string
  default = "flexible"
}

variable "web_subdomain" {
  type    = string
  default = "web"
}

variable "monitoring_subdomain" {
  type    = string
  default = "monitoring"
}

variable "ansible_inventory_path" {
  type    = string
  default = "../ansible/inventory/hosts.ini"
}

variable "ansible_user" {
  type    = string
  default = "ubuntu"
}

variable "ansible_private_key_path" {
  type    = string
  default = "~/.ssh/AhmadAfifKey.pem"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "yourname" {
  type    = string
  default = "ahmadafif"
}

variable "key_name" {
  type        = string
  description = "EC2 KeyPair name in AWS."
  default     = "AhmadAfifKey"
}
