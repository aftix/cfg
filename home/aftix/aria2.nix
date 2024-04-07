{
  config,
  spkgs,
  upkgs,
  ...
}: {
  home.packages = with upkgs; [aria2 python312Packages.aria2p];

  xdg.configFile."aria2/aria2.conf".text = ''
    continue
    file-allocation=falloc
    log-level=warn
    max-connection-per-server=4
    min-split-size=5M
  '';

  xdg.configFile."aria2/aria2d.conf".text = ''
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

  systemd.user = {
    services.aria2cd = {
      Unit.Description = "aria2 Daemon";
      Service = {
        Type = "forking";
        ExecStart = let
          rpcDir = "${config.home.homeDirectory}/.config/aria2";
          rpcFile = "${rpcDir}/aria2d.env";
        in ''
          "${upkgs.coreutils}/bin/mkdir" -p "${rpcDir}" ; \
          TOKEN=$("${upkgs.coreutils}/bin/dd" if=/dev/urandom of=/dev/stdout bs=64 count=1 2>/dev/null | \
            "${upkgs.coreutils}/bin/base64" | "${upkgs.coreutils}/bin/tr" -d '\n=*')" ; \
          "${upkgs.coreutils}/bin/echo" "ARIA2_RPC_TOKEN=$TOKEN" > ${rpcFile} ; \
          "${upkgs.aria2}/bin/aria2c" --conf-path=%h/.config/aria2/aria2d.conf --rpc-secret="$TOKEN"
        '';
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
