{ pkgs, ... }: {
  # xdg = {
  #   portal = {
  #     enable = true;
  #     xdgOpenUsePortal = true;
  #     config = {
  #       niri = {
  #         default = [ "gtk" ];
  #         "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
  #         "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
  #         "org.freedesktop.impl.portal.Secret" = [ "gnome" ];
  #       };
  #       common = {
  #         default = [ "gtk" ];
  #         "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
  #       };
  #     };
  #     extraPortals = with pkgs; [
  #       xdg-desktop-portal-gtk
  #       xdg-desktop-portal-gnome
  #     ];
  #   };
  # };
  #
  # # Ensure Qt applications use GTK file picker
  # home.sessionVariables = {
  #   QT_QPA_PLATFORMTHEME = "gtk3";
  #   GTK_USE_PORTAL = "1";
  # };
  #
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5.qtbase
    adwaita-qt
    adwaita-qt6
  ];
}

