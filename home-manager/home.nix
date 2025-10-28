{ inputs, pkgs, config, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
    ./niri
    # ./gtk.nix
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
    # inputs.quickshell.packages.${system}.default
    wl-clipboard
    fuzzel
    steam
    chezmoi
    vlc
    telegram-desktop
    discord
    eww
  ];

  home.file."${config.xdg.configHome}/eww".source = builtins.fetchGit {
    url = "https://github.com/jacbart/eww";
    rev = "3d74fb407236a059e8b5399dff2b6eefb4587ed1";
    ref = "main";
  };

  programs.zen-browser.enable = true;

  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
}
