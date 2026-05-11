{
  lib,
  den,
  ...
}:
let
  stateVersion = "25.11";
in
{
  #den.default.nixos.system.stateVersion = "25.11";
  # den.default.homeManager.home.stateVersion = "25.11";

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # host<->user provides
  den.ctx.user.includes = [ den._.mutual-provider ];

  # Default aspects
  den.default.includes = with den.aspects; [
    spotify
    niri
    noctalia
    file-manager
    terminal
    browser
  ];

  # Allow unfree packages
  den.default.nixos =
    { pkgs, ... }:
    {
      system.stateVersion = stateVersion;
      # Set your time zone.
      time.timeZone = "America/New_York";

      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
      ];
      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      # Do i need this?
      # i18n.extraLocaleSettings = {
      #   LC_ADDRESS = "en_US.UTF-8";
      #   LC_IDENTIFICATION = "en_US.UTF-8";
      #   LC_MEASUREMENT = "en_US.UTF-8";
      #   LC_MONETARY = "en_US.UTF-8";
      #   LC_NAME = "en_US.UTF-8";
      #   LC_NUMERIC = "en_US.UTF-8";
      #   LC_PAPER = "en_US.UTF-8";
      #   LC_TELEPHONE = "en_US.UTF-8";
      #   LC_TIME = "en_US.UTF-8";
      # };

      nixpkgs.config.allowUnfree = true;

      programs = {
        nix-ld.enable = true;
        lazygit.enable = true;
        localsend.enable = true;
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-gnome3;
        };
        zsh = {
          enable = true;
          ohMyZsh = {
            enable = true;
            plugins = [
              "git"
              "fzf"
              "history"
            ];
          };
        };
        starship.enable = true;
        # _1password.enable = true;
        # _1password-gui = {
        #   enable = true;
        #   polkitPolicyOwners = [
        #     user.userName
        #   ];
        # };
        dconf.enable = true;
      };

    };

  den.default.homeManager =
    { pkgs, config, ... }:
    {
      home.stateVersion = stateVersion;
      nixpkgs.config.allowUnfree = true;

      home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
        hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
      };

      systemd.user.startServices = "sd-switch";

      programs = {
        home-manager.enable = true;
        zsh.dotDir = config.home.homeDirectory;
      };

      # Packages I consider essential for all users on all systems
      home.packages = with pkgs; [
        eog
        cameractrls
        cameractrls-gtk4
        wl-clipboard
        baobab
        gnome-disk-utility

        # TODO: remove in favor of NixVim
        chezmoi
      ];
    };
}
