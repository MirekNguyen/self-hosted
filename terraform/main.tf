terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.27"
    }
  }
  required_version = ">= 1.2.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  description = "The API token for Hetzner Cloud."
  type        = string
  sensitive   = true
}

resource "hcloud_server" "dokploy" {
  name        = "dokploy"
  image       = "debian-13"
  server_type = "cx33"
  location    = "nbg1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

output "dokploy_server_ipv4" {
  description = "The IPv4 address of the server"
  value       = hcloud_server.dokploy.ipv4_address
}

output "dokploy_server_ipv6" {
  description = "The IPv6 address of the server"
  value       = hcloud_server.dokploy.ipv6_address
}
