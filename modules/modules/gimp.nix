{ inputs, ... }:
{
  flake-file.inputs.nix-photogimp = {
    url = "github:Libadoxon/nix-photo-gimp";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.gimp = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.nix-photogimp.packages.${pkgs.system}.default ];
      };
  };
}
