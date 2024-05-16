{
  config,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    (final: _: {
      aria2d = final.writeShellApplication {
        name = "aria2d";
        runtimeInputs = with final; [aria2];
        text = let
          rpcDir = "${config.xdg.configHome}/aria2";
          rpcFile = "${rpcDir}/aria2d.env";
        in ''
          mkdir -p "${rpcDir}"
          dd if=/dev/urandom of=/dev/stdout bs=64 count=1 2>/dev/null | base64 | tr -d '\n=*' | xargs printf "ARIA2_RPC_TOKEN=%s" > "${rpcFile}"
          # shellcheck source=/dev/null
          source "${rpcFile}"
          aria2c --conf-path="${rpcDir}/aria2d.conf" --rpc-secret="$ARIA2_RPC_TOKEN"
        '';
      };
    })
  ];
  home.packages = with pkgs; [aria2 aria2d python312Packages.aria2p];

  my.shell = {
    aliases = [
      {
        name = "aria2p";
        # TODO: make this work across shells
        command = "aria2p --secret=$E:ARIA2_RPC_TOKEN";
        external = true;
      }
    ];
    extraEnvFiles = ["${config.xdg.configHome}/aria2/aria2d.env"];
  };

  xdg.configFile = {
    "aria2/aria2.conf".text = ''
      continue
      file-allocation=falloc
      log-level=warn
      max-connection-per-server=4
      min-split-size=5M
    '';

    "aria2/aria2d.conf".text = ''
      continue
      daemon=true
      dir=${config.home.homeDirectory}/Downloads
      file-allocation=falloc
      log-level=warn
      max-connection-per-server=4
      max-overall-download-limit=0
      min-split-size=5M
      enable-http-pipelining=true

      enable-rpc=true
      rpc-listen-all=true
    '';
  };

  systemd.user = {
    services.aria2cd = {
      Unit.Description = "aria2 Daemon";
      Service = {
        Type = "forking";
        ExecStart = "${pkgs.aria2d}/bin/aria2d";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
