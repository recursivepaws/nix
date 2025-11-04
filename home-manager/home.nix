{ inputs, pkgs, config, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
    ./niri
    ./gtk.nix
    # ./portal.nix
    ./kitty.nix
  ];

  home = {
    username = "vera";
    homeDirectory = "/home/vera";
    stateVersion = "25.05";
  };

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    eog
    davinci-resolve-studio
    playerctl
    wl-clipboard
    fuzzel
    steam
    chezmoi
    vlc
    telegram-desktop
    signal-desktop
    discord
    eww
  ];

  # home.file."${config.xdg.configHome}/eww".source = builtins.fetchGit {
  #   url = "https://github.com/jacbart/eww";
  #   rev = "3d74fb407236a059e8b5399dff2b6eefb4587ed1";
  #   ref = "main";
  # };

  home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
    hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
  };

  programs.zen-browser.enable = true;

  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
}
