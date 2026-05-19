{ den, inputs, ... }:
{
  flake-file.inputs.nixpkgs-vale.url = "github:NixOS/nixpkgs/ca16221251951e9c6261a1a2bb4f9389038d3632";

  den.aspects.hightouch = {
    homeManager =
      { pkgs, ... }:
      let
        vale = inputs.nixpkgs-vale.legacyPackages.${pkgs.system}.vale;
      in
      {
        home.packages = [ vale ];
      };
  };
}
