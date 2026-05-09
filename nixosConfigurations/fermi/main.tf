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
  }
}

variable "dns_zone_name" {
  type = string
}

locals {
  fermi = jsondecode(file("${path.module}/node.json"))
}

resource "hcloud_zone_rrset" "main" {
  zone = var.dns_zone_name
  name = "@"
  type = "A"
  records = [{value = local.fermi.ipv4}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "mainv6" {
  zone = var.dns_zone_name
  name = "@"
  type = "AAAA"
  records = [{value = local.fermi.ipv6}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "fermi" {
  for_each = toset(concat(local.fermi.subdomains, [for sub in local.fermi.subdomains: "www.${sub}"]))
  zone = var.dns_zone_name
  name = each.key
  type = "A"
  records = [{value = local.fermi.ipv4}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "fermiv6" {
  for_each = toset(concat(local.fermi.subdomains, [for sub in local.fermi.subdomains: "www.${sub}"]))
  zone = var.dns_zone_name
  name = each.key
  type = "AAAA"
  records = [{value = local.fermi.ipv6}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "txts" {
  for_each = tomap({
    "_acme-challenge.www.searx"   = "2ELjSxsV9Ifu5sTM00waExp4WzUHj_9jkz8SckGrAWQ"
    "_acme-challenge.www.rss"     = "wYqI00an3euEN9gJQirdWgvZFgI4yipQGqc3R-igPDE"
    "_acme-challenge.www.rss"     = "SUqDIQ2eEx4Q9p_0Q05x4FvzxrIWvAwT4AeW4GqSp6M"
    "_acme-challenge.www.metrics" = "9CdEQQYxuhrB66DAAYuxTvIYBdkhoIgf87lCHf3gPAw"
    "_acme-challenge.www.grocy"   = "caRTMlhnjiAo-vE8yNk1-aonYBmicxtYaUJ7U23IzRo"
    "_acme-challenge.www.attic"   = "F_YKbpi2nDw4RJgUgFAVsUxNJENwSU4rIvKegTZSdtM"
    "_acme-challenge.www.attic"   = "B8WABdWGqVs8sHGiLpMdxj2qpLfgaKKkib825rHPyq4"
    "_acme-challenge.rss"         = "DMt2LqGinq5TJQwYgBU0SHPEeNenkOxJSiqnu5vvqdM"
    "_acme-challenge"             = "y9SosxD88o7Nc1Ey-GfaUWgLLyEzlENJDjMHfhlxSr8"
  })
  zone = var.dns_zone_name
  name = each.key
  type = "TXT"
  records = [{value = provider::hcloud::txt_record(each.value)}]
  ttl = 300
  change_protection = true
}
