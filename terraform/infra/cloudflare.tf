locals {
  web_fqdn        = "${var.web_subdomain}.${var.root_domain}"
  monitoring_fqdn = "${var.monitoring_subdomain}.${var.root_domain}"
}

#locals {
#  web_fqdn        = "${var.web_subdomain}.${var.cloudflare_zone}"
#  monitoring_fqdn = "${var.monitoring_subdomain}.${var.cloudflare_zone}"
#}

# Zone setting: user requested SSL/TLS "flexible"
#resource "cloudflare_zone_setting" "ssl_mode" {
#  zone_id    = var.cloudflare_zone_id
#  setting_id = "ssl"
#  value      = var.cloudflare_ssl_mode
#
#  lifecycle {
#    prevent_destroy = true
#  }
#}

# Web DNS: point web.<zone> to the Web EIP
resource "cloudflare_dns_record" "web" {
  zone_id = var.cloudflare_zone_id
  name    = var.web_subdomain
  type    = "A"
  content = aws_eip.web.public_ip
  ttl     = 1
  proxied = true
}

# Monitoring: remotely-managed Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "monitoring" {
  account_id = var.cloudflare_account_id
  name       = "${local.prefix}-monitoring-tunnel"
  config_src = "cloudflare"
}

# Token that cloudflared uses on the monitoring server
data "cloudflare_zero_trust_tunnel_cloudflared_token" "monitoring" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.monitoring.id
}

# DNS for monitoring -> tunnel
resource "cloudflare_dns_record" "monitoring" {
  zone_id = var.cloudflare_zone_id
  name    = var.monitoring_subdomain
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.monitoring.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# Tunnel config: map monitoring.<zone> -> http://localhost:3000 on the monitoring host (Grafana)
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "monitoring" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.monitoring.id

  config = {
    ingress = [
      {
        hostname = local.monitoring_fqdn
        service  = "http://localhost:3000"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

# Cloudflare Access: require login for monitoring hostname
resource "cloudflare_zero_trust_access_policy" "monitoring_allow_email" {
  account_id = var.cloudflare_account_id
  name       = "Allow monitoring by email"
  decision   = "allow"

  include = [
    {
      email = { email = var.cloudflare_email }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "monitoring" {
  account_id = var.cloudflare_account_id
  type       = "self_hosted"
  name       = "Monitoring (Grafana) - ${local.monitoring_fqdn}"
  domain     = local.monitoring_fqdn

  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.monitoring_allow_email.id
      precedence = 1
    }
  ]
}
