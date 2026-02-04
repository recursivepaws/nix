{ pkgs, config, ... }: {
  imports = [
    ./niri
    ./gtk.nix
    ./signing.nix
    ./terminal.nix
    ./noctalia.nix
    ./whatsie.nix
  ];

  home = {
    username = "vera";
    homeDirectory = "/home/vera";
    stateVersion = "25.05";
  };

  programs = { home-manager.enable = true; };

  home.packages = with pkgs; [
    eog
    handbrake
    avidemux
    manim
    cameractrls
    playerctl
    wl-clipboard
    fuzzel
    spotifyd
    chezmoi
    telegram-desktop
    signal-desktop
    discord
    baobab
    seahorse
    immich-go
    google-chrome
    zoom-us
    trezor-suite
  ];

  home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
    hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
  };

  systemd.user.startServices = "sd-switch";
}
