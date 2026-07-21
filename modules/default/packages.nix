# modules/package-class.nix
{ den, lib, ... }:
let
  packageClass =
    {
      host,
      user,
      class,
      aspect-chain,
    }:
    let
      aspect = lib.head aspect-chain;
      pkgFns = aspect.packages or [ ];

      # Each item is {pkgs, lib, stdenv, ...}: { name = drv; }
      # Merge all returned attrsets into one nixpkgs overlay
      overlay =
        final: prev:
        lib.foldl (
          acc: f:
          let
            available = prev // {
              pkgs = prev;
            };
            passedArgs = lib.filterAttrs (n: _: (builtins.functionArgs f) ? ${n}) available;
          in
          acc // (f passedArgs)
        ) { } pkgFns;
    in
    lib.optionalAttrs (pkgFns != [ ]) {
      nixos.nixpkgs.overlays = [ overlay ];
      homeManager.nixpkgs.overlays = [ overlay ];
    };

in
{
  den.schema.user.includes = [ packageClass ];
}
