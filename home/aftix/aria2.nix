{
  config,
  upkgs,
  nixpkgs,
  ...
}: {
  home.packages = with upkgs; [aria2 python312Packages.aria2p];

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

    "aria2/aria2d.bash" = {
      executable = true;
      text = let
        rpcDir = "${config.home.homeDirectory}/.config/aria2";
        rpcFile = "${rpcDir}/aria2d.env";
      in ''
        #!/usr/bin/env nix-shell
        #! nix-shell -i bash --pure
        #! nix-shell -p bash coreutils findutils aria2
        #! nix-shell -I nixpkgs=${nixpkgs}

        mkdir -p "${rpcDir}"
        dd if=/dev/urandom of=/dev/stdout bs=64 count=1 2>/dev/null | base64 | tr -d '\n=*' | xargs printf "ARIA2_RPC_TOKEN=%s" > "${rpcFile}"
        source "${rpcFile}"
        aria2c --conf-path="${rpcDir}/aria2d.conf" --rpc-secret="$ARIA2_RPC_TOKEN"
      '';
    };
  };

  systemd.user = {
    services.aria2cd = {
      Unit.Description = "aria2 Daemon";
      Service = {
        Type = "forking";
        ExecStart = "${config.home.homeDirectory}/.config/aria2/aria2d.bash";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
