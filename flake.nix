# /etc/nixos/flake.nix
{
  description = "flake for NyaNix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    agenix.url = "github:yaxitech/ragenix";
    claude-code.url = "github:sadjow/claude-code-nix";
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      # url = "github:nix-community/home-manager/release-25.05";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # BUG: https://github.com/NixOS/nixpkgs/issues/448456
    # terrible terrible terrible terrible terrible
    mesa-good.url =
      "github:nixos/nixpkgs?ref=599ddd2b79331c1e6153e1659bdaab65d62c4c82";
  };
  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # overlays = ;
      nixosConfigurations = {
        # modules = [ ];
        NyaNix = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self inputs pkgs-stable; };
          modules = [
            ./nixos/configuration.nix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vera = import ./home-manager/home.nix;
              home-manager.extraSpecialArgs = { inherit inputs pkgs-stable; };
            }
          ];
        };
      };
    };
}

