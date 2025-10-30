{ pkgs, ... }: {
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-volman thunar-archive-plugin ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common = {
      default = "gtk";
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
    };
  };

  xdg.mime.defaultApplications = { "inode/directory" = "thunar.desktop"; };
  environment.sessionVariables = { QT_QPA_PLATFORMTHEME = "gnome"; };
}
