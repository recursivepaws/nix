{
  den.default.homeManager = { pkgs, config, ... }: {
    home.packages = with pkgs; [ gnome-shell sassc ];
    gtk = {
      enable = true;
      theme = {
        name = "Nightfox-Dark-Carbonfox";
        package = pkgs.stdenvNoCC.mkDerivation {
          inherit (pkgs.nightfox-gtk-theme) pname version src;

          propagatedUserEnvPkgs = [ pkgs.gtk-engine-murrine ];
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
      gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
      gtk3 = {
        bookmarks =
          (map (bookmark: "file://${config.home.homeDirectory}/${bookmark}") [
            "Documents"
            "Downloads"
            "Pictures"
            "Pictures/Screenshots"
            "Music"
            "Videos"
            "Software"
          ]) ++ [
            "smb://vera@MeowStation.local/ MeowStation"
            "sftp://vera@BarkStation.local/ BarkStation"
          ];
        extraConfig = { gtk-application-prefer-dark-theme = 1; };
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
  };
}
