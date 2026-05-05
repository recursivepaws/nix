{
  den.default.nixos =
    { ... }:
    {
      nix.settings = {
        substituters = [ "https://jake0x539.cachix.org" ];
        trusted-public-keys = [
          "jake0x539.cachix.org-1:WqPqua70tU6xqb+e91lc35VeTkF2ANdC9ZaPtmqCM9o="
        ];
      };
    };
}
