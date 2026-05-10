{ inputs, ... }:
{
  flake-file.inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.spotify = {
    nixos =
      { pkgs, ... }:
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
      in
      {
        imports = [ inputs.spicetify-nix.nixosModules.spicetify ];
        programs.spicetify = {
          enable = true;
          enabledExtensions = with spicePkgs.extensions; [
            adblock
            aiBandBlocker
          ];
          theme = spicePkgs.themes.bloom;
        };
      };
  };
}
