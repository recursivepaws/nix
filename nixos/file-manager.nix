{ pkgs, ... }: {
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [ thunar-volman thunar-archive-plugin ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    # config = {
    #   niri = {
    #     default = [ "gtk" ];
    #     "org.freedesktop.impl.portal.FileChooser" = "gtk";
    #     "org.freedesktop.impl.portal.ScreenCast" = "gnome";
    #     "org.freedesktop.impl.portal.Secret" = "gnome";
    #   };
    #   common = {
    #     default = "gtk";
    #     "org.freedesktop.impl.portal.FileChooser" = "gtk";
    #   };
    # };
    wlr.enable = false;
    xdgOpenUsePortal = true;
  };
  xdg.mime.defaultApplications = { "inode/directory" = "thunar.desktop"; };
}
