{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf mkMerge;
  inherit (lib.strings) hasSuffix escapeShellArg;
in {
  home = {
    activation.linkLibrewolfCfg = let
      firefoxDir =
        if pkgs.hostPlatform.isDarwin
        then "${config.home.homeDirectory}/Library/Application Support/Firefox"
        else "${config.home.homeDirectory}/.mozilla/firefox";
      librewolfDir =
        if pkgs.hostPlatform.isDarwin
        then "${config.home.homeDirectory}/Library/Application Support/librewolf"
        else "${config.home.homeDirectory}/.librewolf";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ln ''${VERBOSE_ARG} -sf ${escapeShellArg firefoxDir} ${escapeShellArg librewolfDir}
      '';

    packages = lib.lists.optionals (config.programs.firefox.package != null) [
      (pkgs.runCommandLocal "firefox-alias" {
          nativeBuildInputs = [pkgs.makeBinaryWrapper];
        } ''
          mkdir -p "$out/bin"
          makeBinaryWrapper "${config.programs.firefox.finalPackage}/bin/librewolf" "$out/bin/firefox"
        '')
    ];

    sessionVariables = mkMerge [
      (mkIf (hasSuffix "-linux" pkgs.system) {
        MOZ_USE_XINPUT2 = "1";
      })

      (mkIf (config.programs.firefox.package != null) {BROWSER = mkDefault "${config.programs.firefox.finalPackage}/bin/librewolf";})
    ];
  };

  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;

    policies = {
      DontCheckDefaultBrowser = true;
      DefaultDownloadDirectory = "\${home}/Downloads";
      DisablePocket = true;
      DisplaybookmarksToolbar = "newtab";
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      EncryptedMediaExtension.Enabled = true;
      FirefoxSuggest = {
        WebSuggestions = true;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      HardwareAcceleration = true;
      OfferToSaveLogins = true;
      PDFjs = {
        Enabled = true;
        EnablePermissions = false;
      };
      PopupBlocking.Default = true;
      PrintingEnabled = true;
      PromptForDownloadLocation = true;
      SearchSuggestEnabled = true;
      ShowHomeButton = false;
    };

    profiles."aftix" = {
      id = 0;
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        multi-account-containers
        clearurls
        darkreader
        keepassxc-browser
        privacy-badger
        privacy-possum
        pay-by-privacy
        sponsorblock
        return-youtube-dislikes
        ublock-origin
      ];

      search = {
        default = "Searx";
        force = true;

        engines = {
          google.metadata.hidden = true;
          bing.metadata.hidden = true;

          duckduckgo = {
            urls = [
              {
                template = "https://duckduckgo.com";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@ddg" "ddg" "@duckduckgo"];
          };
          wikipedia = {
            urls = [
              {
                template = "https://en.wikipedia.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                  {
                    name = "title";
                    value = "Special:Search";
                  }
                  {
                    name = "fulltext";
                    value = "1";
                  }
                  {
                    name = "ns0";
                    value = "1";
                  }
                ];
              }
            ];
            definedAliases = ["wiki" "@wiki" "@wikipedia"];
          };
          "ArchLinux Wiki" = {
            urls = [
              {
                template = "https://wiki.archlinux.org/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                  {
                    name = "title";
                    value = "Special:Search";
                  }
                ];
              }
            ];
            definedAliases = ["aw" "@aw" "@archwiki"];
          };
          youtube = {
            urls = [
              {
                template = "https://www.youtube.com/results";
                params = [
                  {
                    name = "search_query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["yt" "@yt" "@youtube"];
          };
          amazon = {
            urls = [
              {
                template = "https://www.amazon.com/s";
                params = [
                  {
                    name = "k";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["amzn" "@amzn" "@amazon"];
          };
          searx = {
            urls = [
              {
                template = "https://searx.aftix.xyz/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["sx" "@sx" "@searx"];
          };
          "std - Rust" = {
            urls = [
              {
                template = "https://std.rs/{searchTerms}";
                params = [];
              }
            ];
            definedAliases = ["rstd" "@rstd" "@ruststd"];
          };
          "Docs.rs" = {
            urls = [
              {
                template = "https://docs.rs/releases/search";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["rdoc" "@rdoc" "@rustdocs"];
          };
          "Crates.io" = {
            urls = [
              {
                template = "https://crates.io/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["rust" "@rust" "@cargo" "@crates"];
          };
          github = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                  {
                    name = "type";
                    value = "repositories";
                  }
                ];
              }
            ];
            definedAliases = ["gh" "@gh" "@github"];
          };
          merriam-webster = {
            urls = [
              {
                template = "https://www.merriam-webster.com/dictionary/{searchTerms}";
              }
            ];
            definedAliases = [
              "dict"
              "@dict"
              "@merriamwebster"
            ];
          };
          jisho = {
            urls = [
              {
                template = "https://jisho.org/search";
                params = [
                  {
                    name = "keyword";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["jp" "@jp" "@jisho"];
          };
          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                  {
                    name = "title";
                    value = "Special%3ASearch";
                  }
                ];
              }
            ];
            definedAliases = ["nixw" "@nixw" "@nixwiki"];
          };
          "NixOS Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "type";
                    value = "packages";
                  }
                ];
              }
            ];
            definedAliases = ["nix" "@nix"];
          };
          "NixOS Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "type";
                    value = "packages";
                  }
                ];
              }
            ];
            definedAliases = ["nixo" "@nixo" "@nixoptions"];
          };
          "noogle.dev" = {
            urls = [
              {
                template = "https://noogle.dev/q";
                params = [
                  {
                    name = "term";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["ng" "@noogle"];
          };
          "Home Manager Options" = {
            urls = [
              {
                template = "https://home-manager-options.extranix.com";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["nixh" "@nixh" "@homemanager"];
          };
          nyaa = {
            urls = [
              {
                template = "https://nyaa.si";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                  {
                    name = "f";
                    value = "0";
                  }
                  {
                    name = "c";
                    value = "1_2";
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };

  xdg.mimeApps.defaultApplications = pkgs.aftixLib.registerMimes [
    {
      application = "firefox";
      mimetypes = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/ftp"
        "image/svg+xml"
      ];
    }
  ];
}
