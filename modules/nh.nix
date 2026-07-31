# Exposes flake apps under the name of each host / home for building with nh.
{ den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };

  den.default.nixos =
    { ... }:
    {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          dates = "daily";
          # TODO: (https://github.com/nix-community/nh/issues/722): on nh 4.4.0 the clean
          extraArgs = "--keep 10 --keep-since 5d --no-gcroots";
        };
      };
    };
}
