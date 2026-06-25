{ inputs, ... }:
{
  flake-file.inputs.noctalia-greeter = {
    url = "github:noctalia-dev/noctalia-greeter";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.noctalia =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        let
          # Same Oxocarbon colorscheme the shell pins in noctalia.nix.
          oxocarbon = builtins.fromJSON (
            builtins.readFile (
              pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/79829c121516de5ffcb5ab62f6dc178c8534a34a/Oxocarbon/Oxocarbon.json";
                hash = "sha256-/MyJJcQhxFSf8oku6DZmbqA2SZmoQru8e/IMo9vSZ7c=";
              }
            )
          );
          d = oxocarbon.dark;
          appearanceJson = (pkgs.formats.json { }).generate "noctalia-greeter-appearance.json" {
            version = 1;
            theme_mode = "dark";
            corner_radius_scale = 1.0;
            palette = {
              primary = d.mPrimary;
              on_primary = d.mOnPrimary;
              secondary = d.mSecondary;
              on_secondary = d.mOnSecondary;
              tertiary = d.mTertiary;
              on_tertiary = d.mOnTertiary;
              error = d.mError;
              on_error = d.mOnError;
              surface = d.mSurface;
              on_surface = d.mOnSurface;
              surface_variant = d.mSurfaceVariant;
              on_surface_variant = d.mOnSurfaceVariant;
              outline = d.mOutline;
              shadow = d.mShadow;
              hover = d.mHover;
              on_hover = d.mOnHover;
            };
          };
        in
        {
          imports = [ inputs.noctalia-greeter.nixosModules.default ];

          programs.noctalia-greeter = {
            enable = true;
            package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
            greeter-args = "--session Niri";
            settings = {
              appearance.scheme = "Synced";
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

          # Greeter reads the avatar from AccountsService, not ~/.face.
          services.accounts-daemon.enable = true;

          systemd.tmpfiles.rules = [
            "L+ /var/lib/noctalia-greeter/appearance.json - - - - ${appearanceJson}"
            "f+ /var/lib/AccountsService/users/${user.userName} 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${user.userName}\\n"
            "L+ /var/lib/AccountsService/icons/${user.userName} - - - - ${user.profilePicture}"
          ];

          # The greeter scans /run/current-system/sw/share/wayland-sessions
          # Not populated by default.
          # Linking it surfaces niri.desktop for discovery.
          environment.pathsToLink = [ "/share/wayland-sessions" ];

          security.pam.services.greetd.enableGnomeKeyring = true;
        };
    };
}
