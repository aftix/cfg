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

  systemd.user.services.aria2cd = {
    Unit.Description = "aria2 Daemon";
    Service = {
      Type = "forking";
      EnvironmentFile = "%h/.config/aria2/aria2d.env";
      ExecStart = ''
        ${upkgs.aria2}/bin/aria2c --conf-path=%h/.config/aria2/aria2d.conf --rpc-secret="''${ARIA2_RPC_TOKEN}"'';
    };
    Install.WantedBy = ["default.target"];
  };

  # Make random rpc token for daemon
  home.activation = {
    generateAriaRPC = ''
      mkdir -p .config/aria2
      dd if=/dev/urandom of=/dev/stdout bs=64 count=1 2>/dev/null |\
      base64 | tr -d '\n=*' | xargs printf "ARIA2_RPC_TOKEN=%s" > .config/aria2/aria2d.env

      "${spkgs.systemd}/bin/systemctl" --user restart aria2cd 2>dev/null >/dev/null || true
    '';
  };
}