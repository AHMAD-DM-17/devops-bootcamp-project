data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  prefix = "devops-bootcamp"
  az     = data.aws_availability_zones.available.names[0]

  vpc_cidr            = "10.0.0.0/24"
  public_subnet_cidr  = "10.0.0.0/25"
  private_subnet_cidr = "10.0.0.128/25"

  web_private_ip        = "10.0.0.5"
  ansible_private_ip    = "10.0.0.135"
  monitoring_private_ip = "10.0.0.136"

  tags = {
    Project = "devops-bootcamp-project"
    Owner   = local.owner
  }

  owner = lower(replace(var.yourname, " ", ""))

}
