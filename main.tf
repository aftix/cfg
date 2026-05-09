# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2026 aftix
# SPDX-License-Identifier: EUPL-1.2

# OpenTofu configuration for my cloud infrastructure
# NixOS is used for the node configuration, opentofu for creation
# The nodes are not immutable - they don't get remade for updates

terraform {
  # REQUIRED: AWS_ACCESS_KEY_ID and AWS_SECRET_ID environment variables
  backend "s3" {
    bucket = "aftix-opentofu"
    key = "state"
    region = "us-east-1"
    encrypt = true
    endpoints = {
      s3 = "s3.us-east-005.backblazeb2.com"
    }

    skip_requesting_account_id = true
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_region_validation = true
    skip_s3_checksum = true
    use_path_style = true
  }

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# REQUIRED: HCLOUD_TOKEN environment variable
provider "hcloud" {
}

# Resources tied to a server are split into modules
module "fermi" {
  source = "./nixosConfigurations/fermi"

  dns_zone_name = hcloud_zone.main.name
}

resource "hcloud_ssh_key" "main" {
  name = "main key"
  public_key = file("./infra/id_ed25519.pub")
}

resource "hcloud_zone" "main" {
  name = "aftix.xyz"
  mode = "primary"
  delete_protection = true
}

locals {
  fermi = {
    ipv4 = "170.130.165.174"
    ipv6 = "2a0b:7140:8:1:5054:ff:fe84:ed8c"
    subdomains = [
      "bbuddy",
      "grocy",
      "hydra",
      "identity",
      "metrics",
      "rss",
      "searx",
      "attic",
      "forge",
    ]
  }
}

resource "hcloud_zone_rrset" "soa" {
  zone = hcloud_zone.main.name
  name = "@"
  type = "SOA"
  records = [{value = "hydrogen.ns.hetzner.com. dns.hetzner.com. 0 86400 10800 3600000 3600"}]
  ttl = 3600
  change_protection = false
}

resource "hcloud_zone_rrset" "cnames" {
  for_each = toset(["0001", "0002", "0003", "0004"])
  zone = hcloud_zone.main.name
  name = "mbo${each.key}._domainkey"
  type = "CNAME"
  records = [{value = "mbo${each.key}._domainkey.mailbox.org"}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "mail" {
  zone = hcloud_zone.main.name
  name = "@"
  type = "MX"
  records = [for id in range(3): { value = "0 mxext${id + 1}.mailbox.org." }]
  ttl = 600
  change_protection = false
}

resource "hcloud_zone_rrset" "caa" {
  zone = hcloud_zone.main.name
  name = "@"
  type = "CAA"
  records = [{value = "0 issue \"letsencrypt.org\""}]
  ttl = 600
  change_protection = true
}

resource "hcloud_zone_rrset" "dmarc" {
  zone = hcloud_zone.main.name
  name = "_dmarc"
  type = "TXT"
  records = [{value = provider::hcloud::txt_record("v=DMARC1;p=reject;rua=mailto:postmaster@aftix.xyz;ruf=mailto:admin@aftix.xyz")}]
  ttl = 300
  change_protection = true
}
