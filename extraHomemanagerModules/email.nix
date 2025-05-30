# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2025 aftix
# SPDX-License-Identifier: EUPL-1.2
{
  config,
  pkgs,
  lib,
  ...
}: let
  share = "${config.home.homeDirectory}/.local/share";
  gpgSigningKey = "53D588312F7FCBE9A76579164C05A0B49FD681B9";
in {
  accounts.email = {
    maildirBasePath = "${share}/mail";
    accounts = {
      personal = {
        address = "aftix@aftix.xyz";
        userName = "aftix@aftix.xyz";
        realName = "aftix";
        aliases = ["webmaster@aftix.xyz" "admin@aftix.xyz"];
        maildir.path = "personal";
        primary = true;
        imap = {
          host = lib.mkForce "imap.mailbox.org";
          tls = {
            enable = true;
            useStartTls = true;
          };
        };
        smtp = {
          host = "smtp.mailbox.org";
          port = 587;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };

        msmtp = {
          enable = true;
          extraConfig = {
            auth = "on";
            passwordeval = "cat ${lib.strings.escapeShellArg config.sops.secrets.mailbox.path}";
          };
        };

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };
      };

      gmail = {
        address = "gameraftexploision@gmail.com";
        userName = "gameraftexploision@gmail.com";
        realName = "aftix";
        folders.sent = "Sent Mail";
        flavor = "gmail.com";
        maildir.path = "gmail";
        imap = {
          host = lib.mkForce "imap.gmail.com";
          port = lib.mkForce 993;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };
        smtp = {
          host = "smtp.gmail.com";
          port = 587;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };

        msmtp = {
          enable = true;
          extraConfig = {
            auth = "on";
            passwordeval = "cat ${lib.strings.escapeShellArg config.sops.secrets.gmailtoken.path}";
          };
        };

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };
      };

      utmail = {
        address = "wyatt.campbell@utexas.edu";
        userName = "wyatt.campbell@utexas.edu";
        realName = "Wyatt Campbell";
        folders.sent = "Sent Mail";
        flavor = "gmail.com";
        maildir.path = "utmail";
        imap = {
          host = lib.mkForce "imap.gmail.com";
          port = lib.mkForce 993;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };
        smtp = {
          host = "smtp.gmail.com";
          port = 587;
          tls = {
            enable = true;
            useStartTls = true;
          };
        };

        msmtp = {
          enable = true;
          extraConfig = {
            auth = "on";
            passwordeval = "cat ${lib.strings.escapeShellArg config.sops.secrets.utmailtoken.path}";
          };
        };

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };
      };
    };
  };

  programs = {
    msmtp.enable = true;

    git.extraConfig.sendemail = {
      from = let email = config.accounts.email.accounts.personal; in "${email.realName} <${email.address}>";
      sendmailCmd = "${config.programs.msmtp.package}/bin/msmtp --account=personal";
    };

    thunderbird = {
      enable = true;
      profiles.aftix = {
        isDefault = true;
        withExternalGnupg = true;
      };
    };
  };

  sops.secrets = {
    mailbox = {};
    gmailtoken = {};
    utmailtoken = {};
  };

  xdg.mimeApps.defaultApplications = pkgs.aftixLib.registerMimes [
    {
      application = "thunderbird";
      mimetypes = [
        "x-scheme-handler/mailto"
      ];
    }
  ];
}
