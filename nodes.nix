# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  fermi = builtins.fromJSON (builtins.readFile ./nixosConfigurations/fermi/node.json);
}
