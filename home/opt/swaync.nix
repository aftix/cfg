{...}: {
  services.swaync = {
    enable = true;

    settings = {
      timeout-low = 30;
      timeout = 60;
      widgets = [
        "inhibitors"
        "title"
        "dnd"
        "volume"
        "mpris"
        "notifications"
      ];
    };
  };
}
