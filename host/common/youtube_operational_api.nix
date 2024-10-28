{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.youtube-operational-api;

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.attrsets) mapAttrsToList optionalAttrs;

  mkConfigValue = x:
    if builtins.isString x
    then "'${x}'"
    else if builtins.isPath x
    then "'${builtins.toString x}'"
    else if builtins.isBool x
    then
      (
        if x
        then "True"
        else "False"
      )
    else if builtins.isList x
    then "[${lib.strings.concatStringsSep " " (builtins.map mkConfigValue x)}]"
    else if builtins.isInt x
    then "${builtins.toString x}"
    else "'${builtins.toString x}'";
  mkConfigDefine = name: x: "define('${name}', ${mkConfigValue x});";
  mkConfig = attrs: ''
    <?php
    ${lib.strings.concatLines (mapAttrsToList mkConfigDefine attrs)}
    ?>
  '';

  defaultSettings = {
    SERVER_NAME = "localhost";
    GOOGLE_ABUSE_EXEMPTION = "";
    MULTIPLE_IDS_ENABLED = true;
    HTTPS_PROXY_ADDRESS = "";
    HTTPS_PROXY_PORT = 80;
    HTTPS_PROXY_USERNAME = "";
    HTTPS_PROXY_PASSWORD = "";
    RESTRICT_USAGE_TO_KEY = "";
    ADD_KEY_FORCE_SECRET = "";
    ADD_KEY_TO_INSTANCES = [];
  };
  settings = defaultSettings // (optionalAttrs (cfg.settings != null) cfg.settings) // {KEYS_FILE = "/keys.txt";};

  cfgPackage =
    pkgs.runCommandWith {
      name = "youtube-operational-api-configured";
      stdenv = pkgs.stdenvNoCC;
      runLocal = true;
      derivationArgs.overrideConfig = pkgs.writeText "youtubeapi-configuration.php" (mkConfig settings);
    } ''
      mkdir -p $out/var/www/html
      cp -vr "${cfg.package}/"* $out/var/www/html/
      rm $out/var/www/html/configuration.php
      cp $overrideConfig $out/var/www/html/configuration.php
    '';

  baseImage = pkgs.dockerTools.pullImage {
    imageName = "php";
    imageDigest = "sha256:1e6b2955c2b2e3f1113c682d08441037b84462158c601d3b606190bfb14e5456";
    finalImageName = "php";
    finalImageTag = "apache";
    sha256 = "09ddjl6g1yjd3vgsmqjqf976wnf06iijlswv8j5cz4w5b3s3yc62";
  };

  imageName = "youtubeapi";
  imageTag = "latest";
  imageScript = pkgs.dockerTools.streamLayeredImage {
    fromImage = baseImage;
    name = imageName;
    tag = imageTag;

    contents = [cfgPackage];

    fakeRootCommands = ''
      a2enmod rewrite
      sed -ri -e 'N;N;N;s/(<Directory \/var\/www\/>\n)(.*\n)(.*)AllowOverride None/\1\2\3AllowOverride All/;p;d;' ./etc/apache2/apache2.conf
    '';
    enableFakechroot = true;

    config = {
      Cmd = ["sh" "-c" "apachectl -D FOREGROUND"];
      WorkingDir = "/";
      Volumes = {"/logs" = {};};
    };
  };
in {
  options.services.youtube-operational-api = {
    enable = mkEnableOption "Youtube operational API";
    package = mkPackageOption pkgs "youtube-operational-api" {};

    settings = mkOption {
      default = null;
      description = "Settings for the configuration.php file.";
      type = with lib.types; nullOr attrs;
    };

    keysFile = mkOption {
      default = "/dev/null";
      description = "File containing API keys for youtube.";
      type = lib.types.str;
    };

    port = mkOption {
      default = 9575;
      description = "Port to listen on for docker container";
      type = lib.types.ints.positive;
    };
  };

  config = lib.mkIf cfg.enable {
    security.apparmor.enable = true;

    virtualisation = {
      podman = {
        enable = true;
        dockerSocket.enable = true;
      };

      oci-containers = {
        backend = "podman";
        containers.youtubeapi = {
          image = "${imageName}:${imageTag}";
          imageStream = imageScript;
          volumes = [
            "${cfg.keysFile}:/keys.txt:ro"
          ];
          ports = [
            "${builtins.toString cfg.port}:80"
          ];
        };
      };
    };
  };
}
