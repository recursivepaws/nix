{
  den.default.nixos =
    { ... }:
    {
      nix.settings = {
        substituters = [
          "https://jake0x539.cachix.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "jake0x539.cachix.org-1:WqPqua70tU6xqb+e91lc35VeTkF2ANdC9ZaPtmqCM9o="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
