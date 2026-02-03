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

  services.displayManager.gdm.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
}
