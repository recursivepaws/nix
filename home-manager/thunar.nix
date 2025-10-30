{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };
  home.sessionVariables = { QT_QPA_PLATFORMTHEME = "gnome"; };
}
