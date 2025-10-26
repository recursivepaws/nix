{ inputs, pkgs, config, ... }: {
  imports =
    [ inputs.zen-browser.homeModules.beta ./gtk.nix ./portal.nix ./kitty.nix ];

  home = {
    username = "vera";
    homeDirectory = "/home/vera";
    stateVersion = "25.05";
  };

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    wl-clipboard
    fuzzel
    steam
    chezmoi
    vlc
    telegram-desktop
    discord
  ];

  programs.zen-browser.enable = true;
  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
}
