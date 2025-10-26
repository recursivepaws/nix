# /etc/nixos/flake.nix
{
  description = "flake for NyaNix";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-25.05"; };
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      overlay-nixpkgs = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          config.allowUnfreePredicate = _: true;
        };
      };
    in {
      nixosConfigurations = {
        NyaNix = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
            ./nixos/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vera = import ./home-manager/home.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit system;
              };
            }
          ];
        };
      };
    };
}

