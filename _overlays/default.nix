# This file defines overlays
{ inputs, ... }: {
  nixpkgs.overlays =
    [ inputs.niri-flake.overlays.niri inputs.claude-code.overlays.default ];
}
