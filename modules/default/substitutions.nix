{
  den.default.nixos =
    { ... }:
    {
      nix.settings = {
        substituters = [
          # "https://cache.nixos.org"
          # "https://nix-community.cachix.org"
          "https://jake0x539.cachix.org"
        ];
        trusted-public-keys = [
          # "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSp=8="
          "jake0x539.cachix.org-1:WqPqua70tU6xqb+e91lc35VeTkF2ANdC9ZaPtmqCM9o="
        ];
      };
    };
}
