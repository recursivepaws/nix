{ inputs, self, ... }: {
  flake.nixosConfigurations.nya =
    inputs.nixpkgs.lib.nixosSystem { modules = [ self.nixosModules.amd ]; };
  flake.nixos.nyaModule = { pkgs, ... }: { boot.loader.grub.enable = true; };
}
