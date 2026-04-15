{ pkgs, ... }: {
  programs.foot = {
    enable = true;
    settings = {
      main = { term = "xterm-256color"; };
      # font = "Caskaydia Cove";
    };
  };
  # home.sessionVariables = { KITTY_SHELL_INTEGRATION = "enabled"; };
  programs.kitty = {
    enable = true;
    shellIntegration = {
      enableZshIntegration = true;
      # mode = "no-cursor";
    };
    settings = {
      linux_display_server = "x11";
      font_size = 12.25;
      font_family = "Caskaydia Cove";
      window_margin_width = 15;
      remember_window_size = "no";
      confirm_os_window_close = 0;
      shell = "${pkgs.zsh}/bin/zsh";
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
    extraConfig = let
      carbonfox = pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/kitty.conf";
        hash = "sha256-VYHlVMwMO/YN64ZH+GDJQ60DmimokmRMCXbYJh1qH6Y=";
      };
    in "include ${carbonfox}";
  };
}
