# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, pkgs, config, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    inputs.zen-browser.homeModules.beta
    # inputs.nix-colors.homeManagerModule
    # inputs.stylix.homeModules.stylix
    # # inputs.ignis.homeManagerModules
    # # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./gtk.nix
    ./portal.nix
    ./kitty.nix
    # (import ./colors.nix {
    #   basix = inputs.basix;
    #   inherit pkgs;
    #   inherit config;
    # })
  ];

  # stylix.enable = true;
  # stylix.base16Scheme =
  #   "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  # stylix.image = pkgs.fetchurl {
  #   url =
  #     "https://www.pixelstalk.net/wp-content/uploads/2016/05/Epic-Anime-Awesome-Wallpapers.jpg";
  #   hash = "sha256-enQo3wqhgf0FEPHj2coOCvo7DuZv+x5rL/WIo4qPI50=";
  # };
  # stylix.polarity = "dark";
  # stylix.targets.kitty.enable = true;
  /* nixpkgs = {
       # You can add overlays here
       overlays = [
         # If you want to use overlays exported from other flakes:
         # neovim-nightly-overlay.overlays.default

         # Or define it inline, for example:
         # (final: prev: {
         #   hi = final.hello.overrideAttrs (oldAttrs: {
         #     patches = [ ./change-hello-to-hi.patch ];
         #   });
         # })
       ];
       # Configure your nixpkgs instance
       config = {
         # Disable if you don't want unfree packages
         allowUnfree = true;
         # Workaround for https://github.com/nix-community/home-manager/issues/2942
         allowUnfreePredicate = _: true;
       };
     };
  */

  # TODO: Set your username
  home = {
    username = "vera";
    homeDirectory = "/home/vera";
    stateVersion = "25.05";
  };

  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    # inputs.ignis.packages.${pkgs.stdenv.hostPlatform.system}.ignis
    wl-clipboard
    fuzzel
    steam
    chezmoi
    vlc
    telegram-desktop
    discord
  ];

  /* programs.ignis = {
       enable = true;
       addToPythonEnv = true;
       services = {
         bluetooth.enable = true;
         recorder.enable = true;
         audio.enable = true;
         network.enable = true;
       };
       sass = {
         enable = true;
         useDartSass = true;
       };
     };
  */

  programs.zen-browser.enable = true;
  # programs.git.enable = true;
  # # programs.neovim.enable = true;
  # # programs.obs-studio.enable = true;
  # # programs.zsh.enable = true;
  # # programs.starship.enable = true;
  # # programs.zoxide.enable = true;
  # #programs.obs-studio.enableVirtualCamera = true;
  # # Nicely reload system units when changing configs
  #
  # programs.fzf = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
  # };
  #
  # systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion

  programs.home-manager.enable = true;
}
