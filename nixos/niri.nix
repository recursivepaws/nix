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
}
