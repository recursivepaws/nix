{ inputs, pkgs, config, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
    ./niri
    ./gtk.nix
    ./signing.nix
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
    baobab
    seahorse
    immich-go
    google-chrome
    zoom-us
  ];

  home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
    hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
  };

  programs.zen-browser.enable = true;

  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
}
