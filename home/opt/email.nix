# TODO: automatic syncing with systemd-creds --user when sytemd v256 releases
{
  pkgs,
  config,
  lib,
  ...
}: let
  share = "${config.home.homeDirectory}/.local/share";
  cfg = "${config.home.homeDirectory}/.config";
  cache = "${config.home.homeDirectory}/.cache";
  gpgSigningKey = "53D588312F7FCBE9A76579164C05A0B49FD681B9";
  gpgEncryptionKey = "3D98EDD231B4337B221C92E697C4A20471616623";

  inherit (lib.strings) concatMapStringsSep;
in {
  nixpkgs.overlays = [
    (_: prev: {
      mutt-purgecache = prev.writeScriptBin "mutt-purgecache" ''
        #!${prev.stdenv.shell}
        CACHE_LIMIT=512000 #KiB

        cd "$1" 2>/dev/null
        [ $? -ne 0 ] && exit

        [ $(du -s . | cut -f1 -d$'\t') -lt $CACHE_LIMIT ] && exit
        while IFS= read -r i; do
          rm "$i"
          [ $(du -s . | cut -f1 -d$'\t') -lt $CACHE_LIMIT ] && exit
        done <<EOF
        $(find . -type f -exec ls -rt1 {} +)
        EOF
      '';
    })
  ];

  home.packages = with pkgs; [mutt-purgecache];

  sops.secrets = {
    mailbox = {};
    gmailtoken = {};
    utmailtoken = {};
  };

  accounts.email = {
    maildirBasePath = "${share}/mail";
    accounts = {
      personal = {
        address = "aftix@aftix.xyz";
        userName = "aftix@aftix.xyz";
        realName = "aftix";
        aliases = ["webmaster@aftix.xyz" "admin@aftix.xyz"];
        passwordCommand = "'${pkgs.coreutils}/bin/cat' '${config.sops.secrets."mailbox".path}'";
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

        msmtp.enable = true;

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };

        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          groups = {
            default = {
              channels = {
                personal = {
                  farPattern = ":personal-remote:";
                  nearPattern = ":personal-local:";
                  patterns = [
                    "*"
                    "!*.gpg"
                    "!*.pgp"
                    "!*.bz2"
                    "!*.xz"
                    "!*.lz"
                  ];
                };
              };
            };
          };
        };

        notmuch = {
          enable = true;
          neomutt = {
            enable = true;
            virtualMailboxes = [];
          };
        };

        neomutt = let
          extraMailboxes = [
            "archive"
            "Junk"
            "receipt"
          ];
          standardMailboxes = [
            "Inbox"
            "Drafts"
            "Sent"
            "Junk"
            "Trash"
          ];
        in {
          enable = true;
          sendMailCommand = "${pkgs.msmtp}/bin/msmtp -a personal";
          inherit extraMailboxes;
          extraConfig = let
            addMailboxes = concatMapStringsSep "\n" (mbox: "mailboxes \"+${mbox}\"") (standardMailboxes ++ extraMailboxes);
          in ''
            set hostname="aftix.xyz"
            ${addMailboxes}
          '';
        };
      };

      gmail = {
        address = "gameraftexploision@gmail.com";
        userName = "gameraftexploision@gmail.com";
        realName = "aftix";
        passwordCommand = "'${pkgs.coreutils}/bin/cat' '${config.sops.secrets."gmailtoken".path}'";
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

        msmtp.enable = true;

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };

        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          groups = {
            gmail = {
              channels = {
                default = {
                  farPattern = "gmail-remote";
                  nearPattern = "gmail-local";
                  patterns = [
                    "*"
                    "![Gmail]*"
                    "!All Mail"
                    "!Drafts"
                    "!Important"
                    "!Sent Mail"
                    "!Spam"
                    "!Trash"
                    "!Starred"
                    "!*.gpg"
                    "!*.gz"
                    "!*.pgp"
                    "*.bz2"
                    "!*.xz"
                    "*.lz"
                  ];
                };
                allmail = {
                  farPattern = "[Gmail]/All Mail";
                  nearPattern = "All Mail";
                };
                drafts = {
                  farPattern = "[Gmail]/Drafts";
                  nearPattern = "Drafts";
                };
                important = {
                  farPattern = "[Gmail]/Important";
                  nearPattern = "Important";
                };
                sent = {
                  farPattern = "[Gmail]/Sent Mail";
                  nearPattern = "Sent Mail";
                };
                spam = {
                  farPattern = "[Gmail]/Spam";
                  nearPattern = "Spam";
                };
                starred = {
                  farPattern = "[Gmail]/Starred";
                  nearPattern = "Starred";
                };
                trash = {
                  farPattern = "[Gmail]/Trash";
                  nearPattern = "Trash";
                };
              };
            };
          };

          extraConfig.account = {
            SSLType = "IMAPS";
          };
        };

        notmuch = {
          enable = true;
          neomutt = {
            enable = true;
            virtualMailboxes = [];
          };
        };

        neomutt = let
          extraMailboxes = [
            "All Mail"
            "Important"
            "Spam"
            "Starred"
            "fafsa"
            "financial"
            "financial/venmo"
            "reciept"
            "reciept/amazon"
            "reciept/apps"
            "reciept/charity"
            "reciept/school"
            "job"
            "tutoring"
          ];
          standardMailboxes = [
            "Inbox"
            "All Mail"
            "Drafts"
            "Important"
            "Sent Mail"
            "Spam"
            "Starred"
            "Trash"
          ];
        in {
          enable = true;
          sendMailCommand = "${pkgs.msmtp}/bin/msmtp -a gmail";
          inherit extraMailboxes;
          extraConfig = let
            addMailboxes = concatMapStringsSep "\n" (mbox: "mailboxes \"+${mbox}\"") (standardMailboxes ++ extraMailboxes);
          in ''
            set hostname="gmail.com"
            ${addMailboxes}
          '';
        };
      };

      utmail = {
        address = "wyatt.campbell@utexas.edu";
        userName = "wyatt.campbell@utexas.edu";
        realName = "Wyatt Campbell";
        passwordCommand = "'${pkgs.coreutils}/bin/cat' '${config.sops.secrets."utmailtoken".path}'";
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

        msmtp.enable = true;

        gpg = {
          key = "${gpgSigningKey}";
          signByDefault = true;
        };

        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          groups = {
            gmail = {
              channels = {
                default = {
                  farPattern = "";
                  nearPattern = "";
                  patterns = [
                    "*"
                    "![Gmail]*"
                    "!All Mail"
                    "!Drafts"
                    "!Important"
                    "!Sent Mail"
                    "!Spam"
                    "!Trash"
                    "!Starred"
                    "!*.gpg"
                    "!*.gz"
                    "!*.pgp"
                    "*.bz2"
                    "!*.xz"
                    "*.lz"
                  ];
                };
                allmail = {
                  farPattern = "[Gmail]/All Mail";
                  nearPattern = "All Mail";
                };
                drafts = {
                  farPattern = "[Gmail]/Drafts";
                  nearPattern = "Drafts";
                };
                important = {
                  farPattern = "[Gmail]/Important";
                  nearPattern = "Important";
                };
                sent = {
                  farPattern = "[Gmail]/Sent Mail";
                  nearPattern = "Sent Mail";
                };
                spam = {
                  farPattern = "[Gmail]/Spam";
                  nearPattern = "Spam";
                };
                starred = {
                  farPattern = "[Gmail]/Starred";
                  nearPattern = "Starred";
                };
                trash = {
                  farPattern = "[Gmail]/Trash";
                  nearPattern = "Trash";
                };
              };
            };
          };

          extraConfig.account = {
            SSLType = "IMAPS";
          };
        };

        notmuch = {
          enable = true;
          neomutt = {
            enable = true;
            virtualMailboxes = [];
          };
        };

        neomutt = let
          extraMailboxes = [
            "All Mail"
            "Important"
            "Spam"
            "Starred"
            "apartment"
            "gradguard"
            "gradlist"
            "ut"
            "ut/financial"
            "ut/orientation"
            "ut/admin"
            "ut/fall2020"
            "ut/TA"
            "ut/spring2020"
            "ut/fall2021"
            "ut/research"
            "ut/spring2022"
            "job"
            "tutoring"
            "receipt"
            "health"
            "family"
          ];
          standardMailboxes = [
            "Inbox"
            "All Mail"
            "Drafts"
            "Important"
            "Sent Mail"
            "Spam"
            "Starred"
            "Trash"
          ];
        in {
          enable = true;
          sendMailCommand = "${pkgs.msmtp}/bin/msmtp -a utmail";
          inherit extraMailboxes;
          extraConfig = let
            addMailboxes = concatMapStringsSep "\n" (mbox: "mailboxes \"+${mbox}\"") (standardMailboxes ++ extraMailboxes);
          in ''
            set hostname="gmail.com"
            ${addMailboxes}
          '';
        };
      };
    };
  };

  programs = {
    msmtp = {
      enable = true;
    };

    notmuch = {
      enable = true;

      new = {
        ignore = [];
        tags = ["unread" "inbox"];
      };
      search.excludeTags = ["deleted" "spam"];
      extraConfig = {
        database.path = "${share}/mail";
        user = {
          name = "Wyatt Campbell";
          primary_email = "aftix@aftix.xyz";
          other_email = "gameraftexploision@gmail.com,wyatt.campbell@utexas.edu";
        };
      };
    };

    neomutt = {
      enable = true;
      unmailboxes = true;
      vimKeys = true;

      sidebar = {
        enable = true;
      };

      sort = "reverse-date";

      settings = {
        mbox_type = "Maildir";

        header_cache = "${share}/neomutt/headers";
        message_cachedir = "${share}/neomutt/messages";

        beep = "no";
        send_charset = "utf-8";
        mailcap_path = "${cfg}/neomutt/mailcap";
        tmpdir = "$XDG_RUNTIME_DIR";
        sort_aux = "last-date-received";

        index_format = "\"%4C %Z %{%b %d %R} %-15.15L (%?l?%4l&%4c?) %s\"";
        sidebar_delim_chars = "\"/\"";
        sidebar_indent_string = "\"  \"";

        query_command = "\"'${pkgs.abook}/bin/abook' -C '${cfg}/abook/abookrc' --datafile '${share}/abook/addressbook' --mutt-query '%s'\"";
        nm_default_url = "notmuch://${share}/mail";
        nm_query_type = "messages";

        pgp_decode_command = "\"'${pkgs.gnupg}/bin/gpg' --status-fd=2 %?p?--pinentry-mode loopback --passphrase-fd 0? --no-verbose --quiet --batch --output - %f\"";
        pgp_verify_command = "\"'${pkgs.gnupg}/bin/gpg' --status-fd=2 --no-verbose --quiet --batch --output - --verify %s %f\"";
        pgp_decrypt_command = "\"'${pkgs.gnupg}/bin/gpg' --status-fd=2 %?p?--pinentry-mode loopback --passphrase-fd 0? --no-verbose --quiet --batch --output - --decrypt %f\"";
        pgp_sign_command = "\"'${pkgs.gnupg}/bin/gpg' %?p?--pinentry-mode loopback --passphrase-fd 0? --no-verbose --batch --quiet --output - --armor --textmode %?a?--local-user %a? --detach-sign %f\"";
        pgp_clearsign_command = "\"'${pkgs.gnupg}/bin/gpg' %?p?--pinentry-mode loopback --passphrase-fd 0? --no-verbose --batch --quiet --output - --armor --textmode %?a?--local-user %a? --clearsign %f\"";
        pgp_encrypt_only_command = "\"'${pkgs.mutt}/bin/pgpewrap' '${pkgs.gnupg}/bin/gpg' --batch --quiet --no-verbose --output - --textmode --armor --encrypt -- --recipient %r -- %f\"";
        pgp_encrypt_sign_command = "\"'${pkgs.mutt}/bin/pgpewrap' '${pkgs.gnupg}/bin/gpg' %?p?--pinentry-mode loopback --passphrase-fd 0? --batch --quiet --no-verbose --textmode --output - %?a?--local-user %a? --armor --sign --encrypt -- --recipient %r -- %f\"";
        pgp_import_command = "\"'${pkgs.gnupg}/bin/gpg' --no-verbose --import %f\"";
        pgp_export_command = "\"'${pkgs.gnupg}/bin/gpg' --no-verbose --armor --export %r\"";
        pgp_verify_key_command = "\"'${pkgs.gnupg}/bin/gpg' --verbose --batch --fingerprint --check-sigs %r\"";
        pgp_list_pubring_command = "\"'${pkgs.gnupg}/bin/gpg' --no-verbose --batch --quiet --with-colons --with-fingerprint --with-fingerprint --list-keys %r\"";
        pgp_list_secring_command = "\"'${pkgs.gnupg}/bin/gpg' --no-verbose --batch --quiet --with-colons --with-fingerprint --with-fingerprint --list-secret-keys %r\"";
        pgp_sign_as = "\"${gpgSigningKey}\"";
        pgp_good_sign = "\"^\\[GNUPG:\\] GOODSIG\"";
      };

      binds = [
        {
          key = "\\CP";
          action = "sidebar-prev";
          map = ["index" "pager"];
        }
        {
          key = "\\CN";
          action = "sidebar-next";
          map = ["index" "pager"];
        }
        {
          key = "\\CO";
          action = "sidebar-open";
          map = ["index" "pager"];
        }
        {
          key = "B";
          action = "sidebar-toggle-visible";
          map = ["index" "pager"];
        }
        {
          key = "<Tab>";
          action = "complete-query";
          map = ["editor"];
        }
        {
          key = "\\\\";
          action = "vfolder-from-query";
          map = ["index"];
        }
        {
          key = "V";
          action = "noop";
          map = ["index" "pager"];
        }
      ];

      macros = [
        {
          map = ["index" "pager"];
          key = "<f2>";
          action = "<sync-mailbox><enter-command>unmailboxes *<enter><enter-command>source '${cfg}/neomutt/gmail'<enter><change-folder>!<enter>:echo 'gmail'<enter>";
        }
        {
          map = ["index" "pager"];
          key = "<f3>";
          action = "<sync-mailbox><enter-command>unmailboxes *<enter><enter-command>source '${cfg}/neomutt/utmail'<enter><change-folder>!<enter>:echo 'ut'<enter>";
        }
        {
          map = ["index" "pager"];
          key = "<f4>";
          action = "<sync-mailbox><enter-command>unmailboxes *<enter><enter-command>source '${cfg}/neomutt/personal'<enter><change-folder>!<enter>:echo 'aftix'<enter>";
        }
        {
          map = ["index" "pager"];
          key = "c";
          action = "<change-folder>?<change-dir><home>^K=<enter>";
        }
        {
          map = ["index" "pager"];
          key = "a";
          action = "<pipe-message>'${pkgs.abook}/bin/abook' -C '${cfg}/abook/abookrc' --datafile '${share}/abook/addressbook' --add-email-quiet<return>";
        }
        {
          map = ["index" "pager"];
          key = "\\CS";
          action = "!'${pkgs.isync}/bin/mbsync' -c '${config.home.homeDirectory}/.mbsyncrc' -a<enter>";
        }
        {
          map = ["index" "pager"];
          key = "\\CI";
          action = "!'${pkgs.notmuch}/bin/notmuch' new<enter>";
        }
        {
          map = ["index" "pager"];
          key = "\\CV";
          action = "<enter-command>toggle sidebar_non_empty_mailbox_only<enter>";
        }
        {
          map = ["index" "pager"];
          key = "\\CX";
          action = "<enter-command>toggle sidebar_new_mail_only<enter>";
        }

        {
          map = ["pager"];
          key = "V";
          action = "<pipe-entry>'${pkgs.iconv}/bin/iconv' -c --to-code=UTF8 > '${cache}/neomutt/mail.html'<enter><shell-escape>xdg-open '${cache}/neomutt/mail.html'<enter>";
        }
      ];

      extraConfig = ''
        set edit_headers
        my_hdr X-Operating-System: `"${pkgs.coreutils}/bin/uname" -s`, kernel `"${pkgs.coreutils}/bin/uname" -r`
        my_hdr User-Agent: neomutt

        set header_cache_compress_method = zstd;
        set header_cache_compress_level=8

        alternative_order text/enriched text/plain text/html text
        set sleep_time=0

        set sidebar_short_path
        set sidebar_folder_indent
        sidebar_whitelist *

        set mail_check_stats
        set use_from
        set skip_quoted_offset=3

        alternates ^gameraftexploision@gmail.COM$ ^wyatt.campbell@utexas.EDU$ ^aftix@aftix.XYZ$

        # Colors
        color hdrdefault blue default
        color quoted blue white
        color signature red default
        color attachment red default
        color prompt brightmagenta default
        color message brightred default
        color error brightred default
        color indicator brightgreen magenta
        color status cyan default
        color tree black default
        color markers red default
        color search white black
        color tilde brightmagenta default
        color index blue default "~F"
        color index red default "~N|~O"
        color index yellow default "~T"
        color index_flags green default "~Q"

        set pgp_check_gpg_decrypt_status_fd
        set pgp_self_encrypt
        set crypt_use_gpgme
        set crypt_autosign
        set crypt_verify_sig
        set crypt_replysign
        set crypt_replyencrypt
        set crypt_replysignencrypted
        set crypt_opportunistic_encrypt

        crypt-hook root@aftix.xyz ${gpgSigningKey}
        crypt-hook postmaster@aftix.xyz ${gpgSigningKey}

        # Support for gzip, bzip2, xz, lzip, and pgp/gpg mailboxes
        open-hook '\.gz$' "'${pkgs.pigz}/bin/pigz' --stdout --decompress '%f' > '%t'"
        close-hook '\.gz$' "'${pkgs.pigz}/bin/pigz' --stdout '%t' > '%f'"
        append-hook '\.gz$' "'${pkgs.pigz}/bin/pigz' --stdout '%t' >> '%f'"
        open-hook '\.bz2$' "'${pkgs.pbzip2}/bin/pbzip2' --stdout --decompress '%f' > '%t'"
        close-hook '\.bz2$' "'${pkgs.pbzip2}/bin/pbzip2' --stdout '%t' > '%f'"
        append-hook '\.bz2$' "'${pkgs.pbzip2}/bin/pbzip2' --stdout '%t' >> '%f'"
        open-hook '\.xz$' "'${pkgs.xz}/bin/xz' --stdout --decompress '%f' > '%t'"
        close-hook '\.xz$' "'${pkgs.xz}/bin/xz' --stdout '%t' > '%f'"
        append-hook '\.xz$' "'${pkgs.xz}/bin/xz' --stdout '%t' >> '%f'"
        open-hook '\.lz$' "'${pkgs.lzip}/bin/lzip' --stdout --decompress '%f' > '%t'"
        close-hook '\.lz$' "'${pkgs.lzip}/bin/lzip' --stdout '%t' > '%f'"
        append-hook '\.lz$' "'${pkgs.lzip}/bin/lzip' --stdout '%t' >> '%f'"
        open-hook '\.pgp$' "'${pkgs.gnupg}/bin/gpg' --decrypt < '%f' > '%t'"
        close-hook '\.pgp$' "'${pkgs.gnupg}/bin/gpg' --encrypt --recipient ${gpgEncryptionKey} < '%t' > '%f'"
        open-hook '\.gpg$' "'${pkgs.gnupg}/bin/gpg' --decrypt < '%f' > '%t'"
        close-hook '\.gpg$' "'${pkgs.gnupg}/bin/gpg' --encrypt --recipient ${gpgEncryptionKey} < '%t' > '%f'"

        set sidebar_format="%B%?F? [%F]?%* %?N?%N/?%S"
      '';
    };

    mbsync = {
      enable = true;
    };

    abook.enable = true;
  };

  my.shell.aliases = [
    {
      name = "abook";
      command = with config.xdg; "abook -C \"${configHome}/abook/abookrc\" --datafile \"${dataHome}/abook/adressbook\"";
      external = true;
    }
    {
      name = "mbsync";
      command = "mbsync -c \"${config.home.homeDirectory}/.mbsyncrc\"";
      external = true;
    }
  ];
}
