# /etc/nixos/flake.nix
{
  description = "flake for NyaNix";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-25.05"; };
    home-manager = {
      # Follow corresponding `release` branch from Home Manager
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      NyaNix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            #home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vera = import ./home-manager/home.nix;
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };
    # homeConfigurations = {
    #   "vera@NyaNix" = home-manager.lib.homeManagerConfiguration {
    #     pkgs = nixpkgs.legacyPackages.x86_64-linux;
    #     extraSpecialArgs = { inherit inputs outputs; };
    #     modules = [ ./home-manager/home.nix ];
    #   };
    # };
  };
}

