# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2026 aftix
# SPDX-License-Identifier: EUPL-1.2

# OpenTofu module for resources needed for my pc

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

resource "b2_bucket" "hamilton_restic" {
  bucket_name = "aftix-hamilton-restic"
  bucket_type = "allPrivate"
}
