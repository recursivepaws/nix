{ inputs, pkgs, ... }: {
  imports = with inputs; [ niri-flake.nixosModules.niri ];
  nixpkgs.overlays = with inputs; [ niri-flake.overlays.niri ];

  environment.systemPackages = with pkgs; [
    # xwayland-satellite
    gnome-text-editor
    gnome-system-monitor
    gnome-control-center
    gnome-tweaks
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };

  systemd.tmpfiles.rules = let username = "vera";
  in [
    "f+ /var/lib/AccountsService/users/${username} 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${username}\\n"
    "L+ /var/lib/AccountsService/icons/${username} - - - - ${
      ../assets/recursivepaws.png
    }"
  ];

  services.displayManager.gdm.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.niri = {
      default = [ "gtk" "gnome" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "xdg-desktop-portal-gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "xdg-desktop-portal-gnome" ];
    };
    extraPortals = [
      pkgs.gnome-keyring
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
