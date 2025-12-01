# This file defines overlays
{ inputs, ... }: {
  nixpkgs.overlays = [ inputs.niri-flake.overlays.niri ];
  # programs.niri = {
  #   enable = true;
  #   package = pkgs.niri;
  # };
}
