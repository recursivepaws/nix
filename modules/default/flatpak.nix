{ inputs, ... }:
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";
  den.default.nixos = {
    imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
    services.flatpak.enable = true;
  };
}
