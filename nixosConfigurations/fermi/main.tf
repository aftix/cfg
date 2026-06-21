# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2026 aftix
# SPDX-License-Identifier: EUPL-1.2

# OpenTofu module for fermi infrastructure
# This just sets the DNS records associated with fermi

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.45"
    }

    b2 = {
      source = "Backblaze/b2"
      version = "~> 0.12"
    }
  }
}

variable "dns_zone_name" {
  type = string
}

locals {
  fermi = jsondecode(file("${path.module}/node.json"))
}

resource "b2_bucket" "fermi_restic" {
  bucket_name = "aftix-fermi-restic"
  bucket_type = "allPrivate"
}

resource "hcloud_zone_rrset" "main" {
  zone = var.dns_zone_name
  name = "@"
  type = "A"
  records = [{value = local.fermi.ipv4}]
  ttl = 600
  change_protection = false
}

resource "hcloud_zone_rrset" "mainv6" {
  zone = var.dns_zone_name
  name = "@"
  type = "AAAA"
  records = [{value = local.fermi.ipv6}]
  ttl = 600
  change_protection = false
}

resource "hcloud_zone_rrset" "fermi" {
  for_each = toset(concat(local.fermi.subdomains, [for sub in local.fermi.subdomains: "www.${sub}"]))
  zone = var.dns_zone_name
  name = each.key
  type = "A"
  records = [{value = local.fermi.ipv4}]
  ttl = 600
  change_protection = false
}

resource "hcloud_zone_rrset" "fermiv6" {
  for_each = toset(concat(local.fermi.subdomains, [for sub in local.fermi.subdomains: "www.${sub}"]))
  zone = var.dns_zone_name
  name = each.key
  type = "AAAA"
  records = [{value = local.fermi.ipv6}]
  ttl = 600
  change_protection = false
}
