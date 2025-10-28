# /etc/nixos/flake.nix
{
  description = "flake for NyaNix";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    nixpkgs-stable = { url = "github:NixOS/nixpkgs/nixos-25.05"; };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      # url = "github:nix-community/home-manager/release-25.05";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, nixpkgs-stable, home-manager, niri, ... }@inputs:
    let system = "x86_64-linux";
    in {
      # overlays = ;
      nixosConfigurations = {
        # modules = [ ];
        NyaNix = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (import ./overlays { inherit niri; })
            ./nixos/configuration.nix
            home-manager.nixosModules.home-manager
            # inputs.stylix.homeModules.stylix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vera = import ./home-manager/home.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                pkgs-stable = import nixpkgs-stable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            }
          ];
        };
      };
    };
}

