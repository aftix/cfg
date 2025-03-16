inputs: let
  inherit (inputs.nixpkgs) lib;
in
  lib.fix
  (self: {
    forEachSystem = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    # Format number of seconds in the Unix epoch as %Y%m%d%H%M%S.
    # Taken from https://github.com/nix-community/flake-compat/blob/38fd3954cf65ce6faf3d0d45cd26059e059f07ea/default.nix
    # MIT Licensed
    formatSecondsSinceEpoch = t: let
      rem = x: y: x - x / y * y;
      days = t / 86400;
      secondsInDay = rem t 86400;
      hours = secondsInDay / 3600;
      minutes = (rem secondsInDay 3600) / 60;
      seconds = rem t 60;

      # Courtesy of https://stackoverflow.com/a/32158604.
      z = days + 719468;
      era =
        (
          if z >= 0
          then z
          else z - 146096
        )
        / 146097;
      doe = z - era * 146097;
      yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
      y = yoe + era * 400;
      doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
      mp = (5 * doy + 2) / 153;
      d = doy - (153 * mp + 2) / 5 + 1;
      m =
        mp
        + (
          if mp < 10
          then 3
          else -9
        );
      y' =
        y
        + (
          if m <= 2
          then 1
          else 0
        );

      pad = s:
        if builtins.stringLength s < 2
        then "0" + s
        else s;
    in "${toString y'}${pad (toString m)}${pad (toString d)}${pad (toString hours)}${pad (toString minutes)}${pad (toString seconds)}";

    # Apply a function recursively on a directory tree
    # This is a generic version of lib.packagesFromDirectoryRecursive
    applyOnDirectoryRecursive = {
      # path of entrypoint to recurse from
      directory,
      # Function to apply
      # type: path -> anything
      toApply,
      # If a directory contains a file named exactly this, the entire directory is taken as one entry
      # This means that toApply is only called once for the entire subtree, with the argument being the
      # path to the corresponding default nix file
      defaultFilename ? "default.nix",
      # Whether or not to nest subattrsets based on the directory structure
      flatten ? false,
    }: let
      inherit (lib) concatMapAttrs pathExists;
      inherit (lib.path) append;
      inherit (lib.strings) hasSuffix removeSuffix;
      defaultPath = append directory defaultFilename;

      recursedTree =
        # if a default file exists, just apply the function directly
        if pathExists defaultPath
        then (toApply defaultPath)
        else
          concatMapAttrs (
            name: type:
            # Otherwise, for each direntry
            let
              path = append directory name;
            in
              if type == "directory"
              then {
                # recurse into directories
                ${name} = self.applyOnDirectoryRecursive {
                  inherit toApply defaultFilename flatten;
                  directory = path;
                };
              }
              else if type == "regular" && hasSuffix ".nix" name
              then {
                # Import .nix files
                ${removeSuffix ".nix" name} = toApply path;
                _recurseFlatten = true;
              }
              else if type == "regular"
              then
                # ignore non-nix files
                {}
              else
                throw ''
                  myLib.applyOnDirectoryRecursive: unsupported file type ${type} at path ${builtins.toString path}
                ''
          ) (builtins.readDir directory);

      cleanTree = name: x: (
        if name == "_recurseFlatten"
        then {}
        else if ! lib.isAttrs x
        then {${name} = x;}
        else let
          doFlatten = x._recurseFlatten or false && flatten;
          removedAttrs = lib.removeAttrs x ["_recurseFlatten"];
          fixedAttrs =
            if x ? _recurseFlatten
            then (concatMapAttrs cleanTree removedAttrs)
            else x;
        in
          if doFlatten
          then fixedAttrs
          else {${name} = fixedAttrs;}
      );
    in
      if lib.isAttrs recursedTree
      then concatMapAttrs cleanTree recursedTree
      else recursedTree;

    # Get nixpkgs modules recursively from a directory into a flat attrset
    # if a directory includes a "default.nix" then the entire directory is treated as one module
    modulesFromDirectoryRecursive = directory:
      self.applyOnDirectoryRecursive {
        inherit directory;
        toApply = path: import path;
      };

    # Get nixos configuration entrypoints recursively from a directory into a flat attrset
    # if a directory includes a "configuration.nix" then the entire directory is treated as one module
    # Note that the entry point is named "entry.nix" and should be a function
    # such as:
    #
    # {inputs, extraArgs}:
    # { ... }
    #
    # Then the output of the function will be applied to genNixosSystem
    nixosConfigurationsFromDirectoryRecursive = {
      # Entry point for nixos configuration directory tree
      directory,
      # Generated by dependencyInjects to inject inputs into the module system
      dep-injects,
      # Special args passed to lib.nixosSystem
      specialArgs ? {},
      # If home-manager is used, this is passed to the home-manager module
      extraSpecialArgs ? {},
      # extra arguments passed to the entrypoints (just like specialArgs)
      extraArgs ? {},
    }:
      self.applyOnDirectoryRecursive {
        inherit directory;
        flatten = true;
        defaultFilename = "entry.nix";
        toApply = path: let
          args = import path (extraArgs // {inherit inputs extraArgs;});
        in
          self.genNixosSystem (args
            // {
              inherit dep-injects specialArgs extraSpecialArgs;
            });
      };

    # Overlay for library functions that require access to a nixpkgs instance
    # Each file in lib-pkgs should be a function that takes an instantiated nixpkgs
    # and returns the actual lib function
    libpkgsOverlay = final: prev:
      self.applyOnDirectoryRecursive {
        directory = ./lib-pkgs;
        defaultFilename = "package.nix";
        toApply = path: import path final;
      };

    # Generates an attrset of nixpkgs modules
    # to inject flake dependencies into configurations
    dependencyInjects = {
      extraInject ? {},
      extraHmInject ? {},
    }: {
      nixos = {lib, ...}: {
        options.dep-inject = lib.mkOption {
          type = with lib.types; attrsOf unspecified;
          default = {};
        };

        config.dep-inject =
          extraInject
          // {
            inherit inputs;
          };
      };

      home-manager = {lib, ...}: {
        options = {
          dep-inject = lib.mkOption {
            type = with lib.types; attrsOf unspecified;
            default = {};
          };
        };

        config.dep-inject =
          extraHmInject
          // {
            inherit inputs;
          };
      };

      # Inject config from nixosHomeOptions into home-manager
      # Leaves a my.nixosCfg option set to the total system configuration, and
      # recursively picks out the options defined in nixosHomeOptions and injects them into the home-manager
      # configuration so those options in particular won't need a "my.nixosCfg" before the config path.
      # Downstream users should get this from the `extra` flake output and use it to generate a hm module
      # with their sysCfg injected. The nixos side is already in the default flake nixosModule, so nothing
      # extra is needed beyond that.
      nixos-home-manager = sysCfg: {
        lib,
        pkgs,
        ...
      }: let
        homeOptions = import ./nixos-home-options.nix pkgs lib;
      in {
        options.my.nixosCfg = lib.mkOption {
          description = "The NixOS configuration";
          readOnly = true;
          type = lib.types.raw;
        };

        config = let
          inherit (lib.attrsets) mapAttrsRecursiveCond hasAttrByPath getAttrFromPath;
        in
          lib.mkMerge [
            (
              mapAttrsRecursiveCond
              # Do not recurse into attrsets that are option definitions
              (attrs: !(attrs ? "_type" && attrs._type == "option"))
              (optPath: _:
                if hasAttrByPath optPath sysCfg
                then getAttrFromPath optPath sysCfg
                else null)
              homeOptions
            )
            {
              my.nixosCfg = sysCfg;
            }
          ];
      };
    };

    # Generate a NixOS configuration with common modules applied
    # Requires an entrypoint NixOS modulee
    # Will optionally add home-manager module + users
    genNixosSystem = {
      entrypoint,
      users ? {},
      extraMods ? [],
      extraHmMods ? [],
      specialArgs ? {},
      extraSpecialArgs ? {},
      extraAttrs ? {},
      dep-injects ? {},
    }:
      lib.nixosSystem (extraAttrs
        // {
          inherit specialArgs;

          modules =
            [
              # This imports host/common
              inputs.self.nixosModules.default
              inputs.self.nixosModules.nix-settings
              (dep-injects.nixos or {})
              entrypoint
            ]
            ++ extraMods
            ++ lib.optionals (users != {}) [
              ({config, ...}: {
                home-manager = {
                  useUserPackages = true;
                  inherit extraSpecialArgs users;
                  sharedModules =
                    [
                      # this imports home/common
                      inputs.self.homemanagerModules.default
                      ((dep-injects.nixos-home-manager or (cfg: {})) config)
                    ]
                    ++ extraHmMods;
                };
              })
            ];
        });
  })
