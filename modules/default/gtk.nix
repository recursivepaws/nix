{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-removed-pkgs.url = "github:NixOS/nixpkgs/f205b5574fd0cb7da5b702a2da51507b7f4fdd1b";

  den.default.homeManager =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # nightfox-gtk-theme and gtk-engine-murrine were removed from nixpkgs (unmaintained GTK2).
      oldPkgs = inputs.nixpkgs-removed-pkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    let
      localDirs = [
        "Documents"
        "Downloads"
        "Pictures"
        "Pictures/Screenshots"
        "Music"
        "Videos"
        "Software"
      ];
    in
    {
      home.packages = with pkgs; [
        gnome-shell
        sassc
      ];

      # Ensure the existence of the local dirs used for bookmarks
      systemd.user.tmpfiles.rules = map (dir: "d %h/${dir} 0755 - - -") localDirs;

      gtk = {
        enable = true;
        theme = {
          name = "Nightfox-Dark-Carbonfox";
          package = pkgs.stdenvNoCC.mkDerivation {
            inherit (oldPkgs.nightfox-gtk-theme) pname version src;

            propagatedUserEnvPkgs = [ oldPkgs.gtk-engine-murrine ];
            nativeBuildInputs = [ pkgs.sassc ];
            buildInputs = [ pkgs.gnome-themes-extra ];

            dontBuild = true;

            postPatch = ''
              patchShebangs themes/install.sh
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/themes
              cd themes
              ./install.sh -n Nightfox --tweaks carbonfox macos -d "$out/share/themes"
              runHook postInstall
            '';
          };
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        gtk4.theme = config.gtk.theme;
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
        gtk3 = {
          bookmarks = (map (dir: "file://${config.home.homeDirectory}/${dir}") localDirs) ++ [
            "smb://vera@MeowStation.local/ MeowStation"
            "sftp://vera@BarkStation.local/ BarkStation"
          ];
          extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
        };
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          # gtk-theme = "Nightfox-Dark-Carbonfox";
          # icon-theme = "Papirus-Dark";
          # cursor-theme = "Bibata-Modern-Ice";
          # cursor-size = 24;
        };
      };
    };
}
