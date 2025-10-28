# This file defines overlays
{ niri, ... }: {
  nixpkgs.overlays = [ niri.overlays.niri ];
}
