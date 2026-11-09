{ inputs, ... }:
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";
  den.default.nixos =
    { lib, host, ... }:
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
      services.flatpak = lib.mkIf host.desktop {
        enable = true;
        packages = [
          "com.fastmail.Fastmail"
        ];
      };
    };
}
