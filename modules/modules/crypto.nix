{
  den.aspects.crypto = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ trezor-suite ];
      };
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ tor-browser ];
        services = {
          trezord.enable = true;
          tor = {
            enable = true;
            openFirewall = true;
          };
        };
      };
  };
}
