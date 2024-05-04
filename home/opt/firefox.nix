{
  lib,
  config,
  upkgs,
  ...
}: let
  inherit (lib) mkDefault mkIf;
in {
  home.sessionVariables = {
    MOZ_USE_XINPUT2 = mkIf (upkgs.system == "x86_64-linux") "1";
    BROWSER = mkDefault "${config.programs.firefox.finalPackage}/bin/firefox";
  };

  programs.firefox = {
    enable = true;
    package =
      if upkgs.system == "x86_64-linux"
      then (with upkgs; (wrapFirefox (firefox-unwrapped.override {pipewireSupport = true;}) {}))
      else null;

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

      bookmarks = [
      ];

      extensions = with upkgs.nur.repos.rycee.firefox-addons; [
        multi-account-containers
        clearurls
        darkreader
        privacy-badger
        privacy-possum
        pay-by-privacy
        return-youtube-dislikes
        ublock-origin
      ];

      search = {
        default = "Searx";
        force = true;

        engines = {
          Google.metadata.hidden = true;
          Bing.metadata.hidden = true;

          DuckDuckGo = {
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
          Wikipedia = {
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
          YouTube = {
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
          Amazon = {
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
          Searx = {
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
                template = "https://doc.rust-lang.org/stable/std";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
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
          Github = {
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
          Merriam-Webster = {
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
          Jisho = {
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
          Nyaa = {
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

  xdg.mimeApps.defaultApplications = config.my.lib.registerMimes [
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
