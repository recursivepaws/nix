{ inputs, pkgs, config, ... }: {
  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox-Material-Dark";
      package =
        inputs.nixpkgs.outputs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pkgs.gruvbox-material-gtk-theme;
    };
    cursorTheme = {
      name = "Capitaine Cursors (Gruvbox)";
      package =
        inputs.nixpkgs.outputs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.capitaine-cursors-themed;
    };
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package =
        inputs.nixpkgs.outputs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.gruvbox-plus-icons;
    };
  };

  home.sessionVariables.GTK_THEME = "Gruvbox-Material-Dark";
}
