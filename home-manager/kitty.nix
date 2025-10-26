{ lib, pkgs, ... }: {
  programs.kitty = lib.mkForce {
    enable = true;
    extraConfig = let
      dracula = pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/Base24/base24-kitty-te/refs/heads/master/output/schemes/base24-dracula24.colorscheme";
        hash = "sha256-XvcsE5ZTTTBHOre7VLnH1jbK6u+oVnc+CdX4HgRXv+o=";
      };
    in "include ${dracula}";
    settings = {
      font_size = 12.25;
      font_family = "Caskaydia Cove";
      window_margin_width = 15;
      remember_window_size = "no";
      #include = ;
      symbol_map = let
        mappings = [
          "U+e000-U+e00a"
          "U+ea60-U+ebeb"
          "U+e0a0-U+e0c8"
          "U+e0ca"
          "U+e0cc-U+e0d7"
          "U+e200-U+e2a9"
          "U+e300-U+e3e3"
          "U+e5fa-U+e6b7"
          "U+e700-U+e8ef"
          "U+ed00-U+efc1"
          "U+f000-U+f2ff"
          "U+f000-U+f2e0"
          "U+f300-U+f381"
          "U+f400-U+f533"
          "U+f0001-U+f1af0"
        ];
      in (builtins.concatStringsSep "," mappings) + " Symbols Nerd Font Mono";
    };
    # font_size 12.25
    # font_family Caskaydia Cove
    # window_margin_width 15
    # remember_window_size no
  };
}
