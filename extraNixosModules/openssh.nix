# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  cfg = config.my.authorized_keys;
in {
  options.my.authorized_keys = mkOption {
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAKGwAhIYy+i9+9cJJUvQKLxxaBFZLMflqKU/5L+uiRs aftix@aftix.xyz"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdA7USr9YDNU319SsiuCthpmpq0xvLYPWxDnXG3wsbyrBmBn4RWwH5Ard5KPG9LqxEbOVpn8x7u0PDR1YaZXvfZ8iuK5CyMvWHZf2SLsTOuJF9qldt8ROmyGqF9+g9zZLnKccI8zLOP/cyf1Go7w4dwa4AxKu0ldT1zQWV/Msrx01eJEo0vaRJSbn6SpgczhQJE1M7e+eaJa1dkC8losTPYPl7eXzcMLMcpejIEYjY35eQPH0qw+/9yOjCABCUXew2PpOrx03/57x/rp7UHkIVLj0ZW4gKBV6/kSezBl+pB7HjFViU0y2/XofPu7oP2oz1XIXfMDmX7F9eFjpC7hddMQljnvBCtteeSjpWyhNi+9aJ6jayKJxLZIbuTGPyDksAFEpZmUIQ6Q4B9fUFrPoPAwt2UkQHXmKzH0ap6grLkJctXcADr+swPjZy2QA/1Df4ISj1ryBdwBSgY0wqAg4Sa9r/OUgmIsrFsZ/2LBtsdAHHJqG5OHtdOG2chgSDOxM= aftix@neptune"
    ];
  };

  config = {
    users.users.aftix = lib.mkIf config.my.users.aftix.enable {
      openssh.authorizedKeys.keys = cfg;
    };

    networking.firewall.allowedTCPPorts = [22];

    services = {
      fail2ban.enable = true;

      openssh = {
        enable = true;

        listenAddresses = [
          {
            addr = "0.0.0.0";
            port = 22;
          }
        ];

        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };

        extraConfig =
          /*
          ssh
          */
          ''
            ClientAliveInterval 900
            ClientAliveCountMax 0
            IgnoreRhosts yes
            HostbasedAuthentication no
            Subsystem sftp  /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO
          '';
      };
    };
  };
}
