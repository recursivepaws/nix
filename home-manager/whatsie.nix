{ pkgs, ... }:
let
  iniFormat = pkgs.formats.ini { };
  settings = {
    General = {
      firstrun_tray = false;
      notificationCombo = 0;
      widgetStyle = "kvantum-dark";
      windowTheme = "dark";
    };

    permissions = { Notifications = true; };
  };
in {
  home.packages = with pkgs; [ whatsie ];
  xdg.configFile."org.keshavnrj.ubuntu/WhatSie.conf".source =
    iniFormat.generate "whatsie-settings" settings;
}
