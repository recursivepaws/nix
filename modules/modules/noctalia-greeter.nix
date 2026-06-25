{ inputs, ... }:
{
  flake-file.inputs.noctalia-greeter = {
    url = "github:noctalia-dev/noctalia-greeter";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia-greeter = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.noctalia-greeter.nixosModules.default ];

        programs.noctalia-greeter = {
          enable = true;
          package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
          greeter-args = "--session Niri";
          settings = {
            cursor = {
              theme = "Bibata-Modern-Ice";
              size = 24;
              path = "${pkgs.bibata-cursors}/share/icons:/run/current-system/sw/share/icons";
            };
            keyboard = {
              layout = "us";
            };
          };
        };

        # The greeter scans /run/current-system/sw/share/wayland-sessions, which is
        # not populated by default. Linking it surfaces niri.desktop for discovery.
        environment.pathsToLink = [ "/share/wayland-sessions" ];

        security.pam.services.greetd.enableGnomeKeyring = true;
      };
  };
}
